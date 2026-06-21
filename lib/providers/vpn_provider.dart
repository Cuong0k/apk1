import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import '../models/server.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/xray_config_builder.dart';

const _nativeProtocols = {'vless', 'vmess', 'trojan', 'ss'};

enum VpnState { disconnected, connecting, connected }

class VpnProvider extends ChangeNotifier {
  late final FlutterV2ray _v2ray;

  VpnState _state = VpnState.disconnected;
  List<Server> _servers = [];
  Server? _selected;
  V2RayStatus? _status;
  bool _initialized = false;
  Map<String, dynamic> _settings = {};
  String? _error;
  bool _autoSelect = false;
  bool _userDisconnecting = false;
  bool _checking = false;
  String? _savedSelectedUri;
  DateTime? _lastUpdated;
  Timer? _pingTimer;

  VpnState get state => _state;
  List<Server> get servers => _servers;
  Server? get selected => _selected;
  V2RayStatus? get status => _status;
  bool get isConnected => _state == VpnState.connected;
  Map<String, dynamic> get settings => _settings;
  String? get error => _error;
  bool get autoSelect => _autoSelect;
  DateTime? get lastUpdated => _lastUpdated;

  String get totalSpeedStr {
    if (_status == null) return '';
    final up   = _parseSpeedBps(_status!.uploadSpeed.toString());
    final down = _parseSpeedBps(_status!.downloadSpeed.toString());
    return _formatBps(up + down);
  }

  VpnProvider() {
    _v2ray = FlutterV2ray(
      onStatusChanged: (status) {
        final prevState = _state;
        _status = status;
        _state = switch (status.state) {
          'CONNECTED'  => VpnState.connected,
          'CONNECTING' => VpnState.connecting,
          _            => VpnState.disconnected,
        };
        // Khi kết nối bị drop bất ngờ (không phải user bấm ngắt):
        // → đợi 3s → ping lại tất cả server → kết nối server tốt nhất
        if (_autoSelect &&
            prevState == VpnState.connected &&
            _state == VpnState.disconnected &&
            !_userDisconnecting) {
          Future.delayed(const Duration(seconds: 3), () {
            if (_state == VpnState.disconnected && _autoSelect) {
              _selected = null; // force re-ping on reconnect
              connect();
            }
          });
        }
        notifyListeners();
      },
    );
    _init();
  }

  Future<void> _init() async {
    _settings = await StorageService.getSettings();
    final mode = await StorageService.getVpnMode();
    _autoSelect = mode.autoSelect;
    _savedSelectedUri = mode.selectedUri;
    await _v2ray.initializeV2Ray(
      notificationIconResourceType: 'mipmap',
      notificationIconResourceName: 'ic_launcher',
    );
    _initialized = true;
    _startPingMonitor();
    notifyListeners();
  }

  // ── Background ping monitor (chạy cả khi app nền, vì có foreground VPN service) ──

  void _startPingMonitor() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (_autoSelect && _state == VpnState.connected && _servers.length > 1 && !_checking) {
        _checkAndSwitch();
      }
    });
  }

  Future<void> _checkAndSwitch() async {
    if (_checking) return;
    _checking = true;
    try {
      // Ping song song tất cả server (2s timeout)
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

      final currentPing = (_selected?.ping == null || _selected!.ping <= 0)
          ? 99999
          : _selected!.ping;

      // Chuyển nếu server khác nhanh hơn ≥50ms
      if (best != null &&
          best.rawUri != (_selected?.rawUri ?? '') &&
          bestPing < currentPing - 50) {
        _selected = best;
        notifyListeners();
        // Reconnect trực tiếp tới server đã chọn (không re-ping)
        _userDisconnecting = true;
        await _v2ray.stopV2Ray();
        _state = VpnState.disconnected;
        notifyListeners();
        Future.delayed(const Duration(milliseconds: 300), () {
          _userDisconnecting = false;
          connect();
        });
      }
    } finally {
      _checking = false;
    }
  }

  // ── Server loading ───────────────────────────────────────────────────────

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

  // ── Server selection ─────────────────────────────────────────────────────

  void selectServer(Server server) {
    final wasConnected = _state == VpnState.connected;
    _autoSelect = false;
    _selected = server;
    _savedSelectedUri = server.rawUri;
    StorageService.saveVpnMode(autoSelect: false, selectedUri: server.rawUri);
    notifyListeners();
    if (wasConnected) _reconnectTo(server);
  }

  void setAutoSelect() {
    final wasConnected = _state == VpnState.connected;
    _autoSelect = true;
    _selected = null; // force re-ping
    _savedSelectedUri = null;
    StorageService.saveVpnMode(autoSelect: true, selectedUri: null);
    notifyListeners();
    if (wasConnected) {
      _userDisconnecting = true;
      _v2ray.stopV2Ray().then((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _userDisconnecting = false;
          connect();
        });
      });
    }
  }

  // Chuyển sang server cụ thể không cần re-ping (dùng khi user chọn thủ công)
  Future<void> _reconnectTo(Server server) async {
    _userDisconnecting = true;
    await _v2ray.stopV2Ray();
    _state = VpnState.disconnected;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 300), () {
      _userDisconnecting = false;
      connect();
    });
  }

  // ── VPN control ──────────────────────────────────────────────────────────

  // Ping tất cả server song song, chọn server ping thấp nhất
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

  Future<void> toggleVpn() async {
    if (!_initialized) return;
    if (_state == VpnState.connected || _state == VpnState.connecting) {
      await disconnect();
    } else {
      await connect();
    }
  }

  Future<void> connect() async {
    if (!_autoSelect && _selected == null) return;
    if (_autoSelect && _servers.isEmpty) return;
    _error = null;

    // Auto-select: chỉ ping khi chưa có server được chọn
    if (_autoSelect && _selected == null) {
      _state = VpnState.connecting;
      notifyListeners();
      await _pingAndPickBest();
      if (_selected == null) {
        _error = 'Không tìm được máy chủ khả dụng';
        _state = VpnState.disconnected;
        notifyListeners();
        return;
      }
    }

    final permission = await _v2ray.requestPermission();
    if (!permission) return;

    _state = VpnState.connecting;
    notifyListeners();

    try {
      final String config;
      if (_nativeProtocols.contains(_selected!.protocol)) {
        config = FlutterV2ray.parseFromURL(_selected!.rawUri).getFullConfiguration();
      } else {
        config = XrayConfigBuilder.build(_selected!, _settings);
      }
      await _v2ray.startV2Ray(
        remark: _autoSelect ? 'Auto - ${_selected!.name}' : _selected!.name,
        config: config,
        blockedApps: null,
        bypassSubnets: null,
      );
    } catch (e) {
      _error = e.toString();
      _state = VpnState.disconnected;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    _userDisconnecting = true;
    await _v2ray.stopV2Ray();
    _state = VpnState.disconnected;
    notifyListeners();
    // Giữ flag 300ms để tránh race condition với onStatusChanged
    Future.delayed(const Duration(milliseconds: 300), () => _userDisconnecting = false);
  }

  // ── Ping ─────────────────────────────────────────────────────────────────

  // Ping nhanh 2s dùng khi chọn server tự động (song song)
  Future<int> _pingDirect(Server server) async {
    final start = DateTime.now().millisecondsSinceEpoch;
    try {
      final socket = await Socket.connect(
        server.host, server.port,
        timeout: const Duration(seconds: 2),
      );
      final delay = DateTime.now().millisecondsSinceEpoch - start;
      socket.destroy();
      server.ping = delay;
      notifyListeners();
      return delay;
    } catch (_) {
      server.ping = -1;
      notifyListeners();
      return -1;
    }
  }

  // Ping 5s dùng từ UI (bấm ping thủ công)
  Future<int> pingServer(Server server) async {
    final start = DateTime.now().millisecondsSinceEpoch;
    try {
      final socket = await Socket.connect(
        server.host, server.port,
        timeout: const Duration(seconds: 5),
      );
      final delay = DateTime.now().millisecondsSinceEpoch - start;
      socket.destroy();
      server.ping = delay;
      notifyListeners();
      return delay;
    } catch (_) {
      server.ping = -1;
      notifyListeners();
      return -1;
    }
  }

  // ── Settings ─────────────────────────────────────────────────────────────

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    _settings = settings;
    await StorageService.saveSettings(settings);
    notifyListeners();
  }

  // ── Speed helpers ─────────────────────────────────────────────────────────

  double _parseSpeedBps(String s) {
    final t = s.trim();
    final plain = double.tryParse(t);
    if (plain != null) return plain;
    final parts = t.split(RegExp(r'\s+'));
    if (parts.length < 2) return 0;
    final num = double.tryParse(parts[0]) ?? 0;
    final unit = parts[1].toLowerCase();
    if (unit.startsWith('gb')) return num * 1073741824;
    if (unit.startsWith('mb')) return num * 1048576;
    if (unit.startsWith('kb')) return num * 1024;
    return num;
  }

  String _formatBps(double bps) {
    if (bps >= 1073741824) return '${(bps / 1073741824).toStringAsFixed(1)} GB/s';
    if (bps >= 1048576)    return '${(bps / 1048576).toStringAsFixed(1)} MB/s';
    if (bps >= 1024)       return '${(bps / 1024).toStringAsFixed(0)} KB/s';
    return '${bps.toStringAsFixed(0)} B/s';
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    super.dispose();
  }
}
