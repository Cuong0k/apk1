import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/server.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/clash_config_builder.dart';
import '../services/clash_api.dart';

const _vpnChannel   = MethodChannel('com.vpnstore.app/vpn');
const _clashChannel = MethodChannel('com.vpnstore.app/clash');

enum VpnState { disconnected, connecting, connected }

class VpnProvider extends ChangeNotifier {
  VpnState _state = VpnState.disconnected;
  List<Server> _servers = [];
  Server? _selected;       // currently active server (null = auto)
  bool _initialized = false;
  Map<String, dynamic> _settings = {};
  String? _error;
  bool _autoSelect = false;
  bool _userDisconnecting = false;
  bool _connecting = false;
  String? _savedSelectedUri;
  DateTime? _lastUpdated;
  DateTime? _lastConnectTime;
  int _reconnectAttempts = 0;

  // Traffic from Clash engine (bytes/s)
  int _uploadSpeed   = 0;
  int _downloadSpeed = 0;

  Timer? _statusTimer;  // polls isRunning every 2s
  Timer? _trafficTimer; // polls traffic every 1s

  // ── Public API ───────────────────────────────────────────────────────────

  VpnState get state       => _state;
  List<Server> get servers => _servers;
  Server? get selected     => _selected;
  bool get isConnected     => _state == VpnState.connected;
  Map<String, dynamic> get settings => _settings;
  String? get error        => _error;
  bool get autoSelect      => _autoSelect;
  DateTime? get lastUpdated => _lastUpdated;
  String get routingMode   => _settings['routing_mode'] ?? 'global';

  String get totalSpeedStr {
    final total = _uploadSpeed + _downloadSpeed;
    if (total == 0) return '';
    return _formatBps(total.toDouble());
  }

  // ── Init ─────────────────────────────────────────────────────────────────

  VpnProvider() {
    _init();
  }

  Future<void> _init() async {
    _settings = await StorageService.getSettings();
    final mode = await StorageService.getVpnMode();
    _autoSelect = mode.autoSelect;
    _savedSelectedUri = mode.selectedUri;
    _initialized = true;
    _vpnChannel.setMethodCallHandler(_handlePlatformCall);
    notifyListeners();
  }

  // Nhận sự kiện từ Android (Quick Settings tile, network change)
  Future<dynamic> _handlePlatformCall(MethodCall call) async {
    switch (call.method) {
      case 'toggleVpn':
        await toggleVpn();
        break;
      case 'networkAvailable':
        if (_autoSelect && _state == VpnState.disconnected && !_userDisconnecting) {
          _reconnectAttempts = 0;
          Future.delayed(const Duration(seconds: 1), () {
            if (_state == VpnState.disconnected && _autoSelect) {
              _selected = null;
              connect();
            }
          });
        }
        break;
      case 'networkLost':
        break;
    }
  }

  // ── Status polling ────────────────────────────────────────────────────────

  void _startPolling() {
    _statusTimer?.cancel();
    _trafficTimer?.cancel();

    // Poll whether ClashVpnService is still running (2s interval)
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final running = await _clashChannel.invokeMethod<bool>('isRunning') ?? false;
      final prevState = _state;
      if (running) {
        _state = VpnState.connected;
        _lastConnectTime ??= DateTime.now();
        _reconnectAttempts = 0;
      } else if (_state != VpnState.disconnected) {
        // Unexpected disconnect
        _state = VpnState.disconnected;
        if (_autoSelect && !_userDisconnecting) {
          _scheduleReconnect();
        }
      }
      if (_state != prevState) notifyListeners();
    });

    // Poll traffic every 1 second
    _trafficTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_state != VpnState.connected) return;
      try {
        final t = await _clashChannel.invokeMethod<Map>('getTraffic');
        if (t != null) {
          _uploadSpeed   = (t['up']   as int? ?? 0);
          _downloadSpeed = (t['down'] as int? ?? 0);
          notifyListeners();
        }
      } catch (_) {}
    });
  }

  void _stopPolling() {
    _statusTimer?.cancel();
    _trafficTimer?.cancel();
    _statusTimer = null;
    _trafficTimer = null;
    _uploadSpeed = _downloadSpeed = 0;
  }

  // ── Reconnect logic ───────────────────────────────────────────────────────

  void _scheduleReconnect() {
    _reconnectAttempts++;
    if (_reconnectAttempts > 3) return;
    Future.delayed(Duration(seconds: 3 * _reconnectAttempts), () {
      if (_state == VpnState.disconnected && _autoSelect) {
        _selected = null;
        connect();
      }
    });
  }

  // ── Server loading ────────────────────────────────────────────────────────

  Future<void> loadServers(String subToken, {String? authData}) async {
    try {
      final sub = await ApiService.getSubscription(subToken, authData: authData);
      _servers = Server.parseSubscription(sub);
      if (_savedSelectedUri != null && !_autoSelect) {
        _selected = _servers.firstWhere(
          (s) => s.rawUri == _savedSelectedUri,
          orElse: () => _servers.first,
        );
      } else if (_selected == null && !_autoSelect && _servers.isNotEmpty) {
        _selected = _servers.first;
      }
      _lastUpdated = DateTime.now();
      notifyListeners();
    } catch (_) {}
  }

  // ── Server selection ──────────────────────────────────────────────────────

  void selectServer(Server server) {
    _autoSelect = false;
    _selected = server;
    _savedSelectedUri = server.rawUri;
    StorageService.saveVpnMode(autoSelect: false, selectedUri: server.rawUri);
    notifyListeners();

    if (_state == VpnState.connected) {
      // Instant switch via REST API — no VPN restart needed
      _switchProxyNow(server.name);
    } else {
      connect();
    }
  }

  void setAutoSelect() {
    _autoSelect = true;
    _selected = null;
    _savedSelectedUri = null;
    StorageService.saveVpnMode(autoSelect: true, selectedUri: null);
    notifyListeners();

    if (_state == VpnState.connected) {
      _switchProxyNow('Auto');
    } else {
      connect();
    }
  }

  /// Switch proxy group without restarting VPN — instant via Clash REST API.
  Future<void> _switchProxyNow(String proxyName) async {
    final ok = await ClashApi.selectProxy('PROXY', proxyName);
    if (!ok) {
      // REST not ready yet — restart VPN with new selection
      await _restartVpn();
    } else if (_autoSelect) {
      // Let Clash's url-test group determine the best server, then reflect in UI
      _refreshSelectedFromClash();
    }
  }

  Future<void> _restartVpn() async {
    _userDisconnecting = true;
    _connecting = false;
    _state = VpnState.connecting;
    notifyListeners();
    try {
      await _clashChannel.invokeMethod('stop');
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 300));
    await connect();
    Future.delayed(const Duration(seconds: 3), () {
      _userDisconnecting = false;
    });
  }

  Future<void> _refreshSelectedFromClash() async {
    await Future.delayed(const Duration(seconds: 5));
    try {
      final proxies = await ClashApi.getProxies();
      final auto = proxies?['Auto'] as Map?;
      final nowName = auto?['now'] as String?;
      if (nowName != null && nowName.isNotEmpty) {
        _selected = _servers.firstWhere(
          (s) => s.name == nowName,
          orElse: () => _selected ?? _servers.first,
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  // ── Routing mode ──────────────────────────────────────────────────────────

  Future<void> setRoutingMode(String mode) async {
    if (_settings['routing_mode'] == mode) return;
    _settings['routing_mode'] = mode;
    await StorageService.saveSettings(_settings);
    notifyListeners();

    if (_state == VpnState.connected) {
      // Try fast patch first, fall back to restart
      final ok = await ClashApi.setMode(_clashModeStr(mode)).then((_) => true).catchError((_) => false);
      if (!ok) await _restartVpn();
    }
  }

  String _clashModeStr(String mode) => switch (mode) {
        'direct' => 'direct',
        'rules'  => 'rule',
        _        => 'global',
      };

  // ── VPN control ───────────────────────────────────────────────────────────

  Future<void> toggleVpn() async {
    if (!_initialized) return;
    if (_state == VpnState.connected || _state == VpnState.connecting) {
      await disconnect();
    } else {
      await connect();
    }
  }

  Future<void> connect() async {
    if (!_initialized) return;
    if (!_autoSelect && _selected == null) return;
    if (_servers.isEmpty) return;
    if (_connecting) return;
    _connecting = true;
    _error = null;

    try {
      // If auto-select and no current selection, ping to pick best for initial config selection
      if (_autoSelect && _selected == null) {
        _state = VpnState.connecting;
        notifyListeners();
        await _pingAndPickBest();
      }

      // Request VPN permission
      final granted = await _clashChannel.invokeMethod<bool>('requestPermission') ?? false;
      if (!granted) return;

      _state = VpnState.connecting;
      notifyListeners();

      final homeDir = await _clashChannel.invokeMethod<String>('getFilesDir') ?? '/data/data/com.vpnstore.app/files';
      final clashHome = '$homeDir/clash';

      final yaml = ClashConfigBuilder.build(_servers, _settings, routingMode);
      await _clashChannel.invokeMethod('start', {'config': yaml, 'homeDir': clashHome});

      // Wait for Clash REST API to be ready (max 10s)
      await ClashApi.waitReady(maxWaitMs: 10000);

      // Select the right proxy group after startup
      if (_autoSelect) {
        await ClashApi.selectProxy('PROXY', 'Auto');
        _refreshSelectedFromClash();
      } else if (_selected != null) {
        await ClashApi.selectProxy('PROXY', _selected!.name);
      }

      _startPolling();
      // State will be set to connected by the poller
    } catch (e) {
      _error = e.toString();
      _state = VpnState.disconnected;
      notifyListeners();
    } finally {
      _connecting = false;
    }
  }

  Future<void> disconnect() async {
    _userDisconnecting = true;
    _stopPolling();
    _state = VpnState.disconnected;
    notifyListeners();
    try {
      await _clashChannel.invokeMethod('stop');
    } catch (_) {}
    _lastConnectTime = null;
    Future.delayed(const Duration(milliseconds: 500), () => _userDisconnecting = false);
  }

  // ── Auto-select ping ──────────────────────────────────────────────────────

  Future<void> _pingAndPickBest() async {
    final results = await Future.wait(
      _servers.map((s) async => (server: s, ping: await _pingDirect(s))),
    );
    Server? best;
    int bestPing = 99999;
    for (final r in results) {
      if (r.ping > 0 && r.ping < bestPing) {
        bestPing = r.ping;
        best = r.server;
      }
    }
    _selected = best ?? (_servers.isNotEmpty ? _servers.first : null);
    notifyListeners();
  }

  // ── Ping ─────────────────────────────────────────────────────────────────

  Future<String> _resolveHost(String host, {int timeoutSec = 3}) async {
    try {
      final addrs = await InternetAddress.lookup(host).timeout(Duration(seconds: timeoutSec));
      if (addrs.isNotEmpty) return addrs.first.address;
    } catch (_) {}
    return host;
  }

  Future<int> _pingDirect(Server server) async {
    final ip = await _resolveHost(server.host, timeoutSec: 2);
    final start = DateTime.now().millisecondsSinceEpoch;
    try {
      final socket = await Socket.connect(ip, server.port, timeout: const Duration(seconds: 2));
      final ms = DateTime.now().millisecondsSinceEpoch - start;
      socket.destroy();
      server.ping = ms;
      notifyListeners();
      return ms;
    } catch (_) {
      server.ping = -1;
      notifyListeners();
      return -1;
    }
  }

  /// Public ping — used from server list UI (5s timeout).
  /// When connected, uses Clash's REST delay test for more realistic results.
  Future<int> pingServer(Server server) async {
    if (_state == VpnState.connected) {
      final ms = await ClashApi.testDelay(server.name, timeoutMs: 5000);
      if (ms > 0) {
        server.ping = ms;
        notifyListeners();
        return ms;
      }
    }
    // Fallback: direct TCP socket
    final ip = await _resolveHost(server.host, timeoutSec: 3);
    final start = DateTime.now().millisecondsSinceEpoch;
    try {
      final socket = await Socket.connect(ip, server.port, timeout: const Duration(seconds: 5));
      final ms = DateTime.now().millisecondsSinceEpoch - start;
      socket.destroy();
      server.ping = ms;
      notifyListeners();
      return ms;
    } catch (_) {
      server.ping = -1;
      notifyListeners();
      return -1;
    }
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  Future<void> updateSettings(Map<String, dynamic> s) async {
    _settings = s;
    await StorageService.saveSettings(s);
    notifyListeners();
  }

  // ── Speed helpers ─────────────────────────────────────────────────────────

  String _formatBps(double bps) {
    if (bps >= 1073741824) return '${(bps / 1073741824).toStringAsFixed(1)} GB/s';
    if (bps >= 1048576)    return '${(bps / 1048576).toStringAsFixed(1)} MB/s';
    if (bps >= 1024)       return '${(bps / 1024).toStringAsFixed(0)} KB/s';
    return '${bps.toStringAsFixed(0)} B/s';
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
