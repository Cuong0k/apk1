import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import '../models/server.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/xray_config_builder.dart';

const _nativeProtocols = {'vless', 'vmess', 'trojan', 'ss'};
const _vpnChannel = MethodChannel('com.vpnstore.app/vpn');

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
  DateTime? _lastConnectTime;
  int _reconnectAttempts = 0;
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

        if (_state == VpnState.connected) {
          _lastConnectTime = DateTime.now();
          _reconnectAttempts = 0;
        }

        // Drop từ CONNECTED → DISCONNECTED bất ngờ: reconnect ngay
        if (_autoSelect &&
            prevState == VpnState.connected &&
            _state == VpnState.disconnected &&
            !_userDisconnecting) {
          _reconnectAttempts = 0;
          _scheduleReconnect();
        }

        // Kết nối thất bại (CONNECTING → DISCONNECTED): retry với backoff, tối đa 3 lần
        if (_autoSelect &&
            prevState == VpnState.connecting &&
            _state == VpnState.disconnected &&
            !_userDisconnecting &&
            _reconnectAttempts < 3) {
          _scheduleReconnect();
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
    _vpnChannel.setMethodCallHandler(_handlePlatformCall);
    notifyListeners();
  }

  // Nhận lệnh từ Android: toggle từ Quick Settings tile, phát hiện thay đổi mạng
  Future<dynamic> _handlePlatformCall(MethodCall call) async {
    switch (call.method) {
      case 'toggleVpn':
        await toggleVpn();
        break;
      case 'networkAvailable':
        // Mạng trở lại (4G↔WiFi switch) — nếu VPN đang ngắt và auto-select bật, kết nối lại
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
        // VPN sẽ tự ngắt → auto-reconnect xử lý
        break;
    }
  }

  void _scheduleReconnect() {
    _reconnectAttempts++;
    final delay = Duration(seconds: 3 * _reconnectAttempts); // backoff: 3s → 6s → 9s
    Future.delayed(delay, () {
      if (_state == VpnState.disconnected && _autoSelect) {
        _selected = null; // force re-ping
        connect();
      }
    });
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

      // Không switch nếu vừa kết nối trong 5 phút qua (tránh switch ngay sau connect)
      final sinceConnect = _lastConnectTime != null
          ? DateTime.now().difference(_lastConnectTime!)
          : const Duration(days: 1);
      if (sinceConnect.inMinutes < 5) return;

      // Chuyển nếu server khác nhanh hơn ≥100ms — threshold cao hơn để tránh switch do jitter mạng
      if (best != null &&
          best.rawUri != (_selected?.rawUri ?? '') &&
          bestPing < currentPing - 100) {
        _selected = best;
        notifyListeners();
        await _fastSwitch(); // stop → start ngay, không delay
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
    _autoSelect = false;
    _selected = server;
    _savedSelectedUri = server.rawUri;
    StorageService.saveVpnMode(autoSelect: false, selectedUri: server.rawUri);
    notifyListeners();
    if (_state == VpnState.connected || _state == VpnState.connecting) {
      _fastSwitch();
    } else {
      connect();
    }
  }

  void setAutoSelect() {
    _autoSelect = true;
    _selected = null; // force re-ping khi connect
    _savedSelectedUri = null;
    StorageService.saveVpnMode(autoSelect: true, selectedUri: null);
    notifyListeners();
    if (_state == VpnState.connected || _state == VpnState.connecting) {
      _fastSwitch();
    } else {
      connect();
    }
  }

  // Stop → Start ngay lập tức, không delay — nhanh nhất có thể
  Future<void> _fastSwitch() async {
    _userDisconnecting = true;
    _state = VpnState.connecting;
    notifyListeners();
    try {
      await _v2ray.stopV2Ray();
    } catch (_) {}
    await connect();
    // Giữ flag 3s cho đến khi VPN kịp chuyển sang CONNECTED.
    // Bug cũ: 200ms quá ngắn → nếu VPN fail trong cửa sổ đó thì
    // onStatusChanged thấy _userDisconnecting=true → bỏ qua reconnect → stuck.
    // Sau 3s nếu vẫn ngắt (connect() thất bại hoặc timeout) → thử lại ngay.
    Future.delayed(const Duration(seconds: 3), () {
      _userDisconnecting = false;
      if (_state == VpnState.disconnected) {
        _reconnectAttempts = 0;
        connect(); // auto: re-ping chọn server; manual: thử lại cùng server
      }
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
        remark: _autoSelect
            ? (_settings['silent_auto_select'] == true ? 'VPN Store' : 'Auto - ${_selected!.name}')
            : _selected!.name,
        config: config,
        blockedApps: ['com.vpnstore.app'], // app tự bypass VPN → ping đo trực tiếp, không qua tunnel
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
    Future.delayed(const Duration(milliseconds: 200), () => _userDisconnecting = false);
  }

  // ── Ping ─────────────────────────────────────────────────────────────────

  // Resolve hostname → IP trước khi đo để loại DNS khỏi ping (giống ShadowClash)
  Future<String> _resolveHost(String host, {int timeoutSec = 3}) async {
    try {
      final addrs = await InternetAddress.lookup(host)
          .timeout(Duration(seconds: timeoutSec));
      if (addrs.isNotEmpty) return addrs.first.address;
    } catch (_) {}
    return host; // fallback: dùng hostname nếu resolve thất bại
  }

  // Ping nhanh 2s dùng khi chọn server tự động (song song)
  Future<int> _pingDirect(Server server) async {
    final ip = await _resolveHost(server.host, timeoutSec: 2);
    final start = DateTime.now().millisecondsSinceEpoch;
    try {
      final socket = await Socket.connect(ip, server.port,
          timeout: const Duration(seconds: 2));
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

  // Ping 5s dùng từ UI (bấm ping thủ công)
  Future<int> pingServer(Server server) async {
    final ip = await _resolveHost(server.host, timeoutSec: 3);
    final start = DateTime.now().millisecondsSinceEpoch;
    try {
      final socket = await Socket.connect(ip, server.port,
          timeout: const Duration(seconds: 5));
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
