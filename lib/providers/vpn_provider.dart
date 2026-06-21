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
  DateTime? _lastUpdated;

  VpnState get state => _state;
  List<Server> get servers => _servers;
  Server? get selected => _selected;
  V2RayStatus? get status => _status;
  bool get isConnected => _state == VpnState.connected;
  Map<String, dynamic> get settings => _settings;
  String? get error => _error;
  bool get autoSelect => _autoSelect;
  DateTime? get lastUpdated => _lastUpdated;

  VpnProvider() {
    _v2ray = FlutterV2ray(
      onStatusChanged: (status) {
        _status = status;
        _state = switch (status.state) {
          'CONNECTED'  => VpnState.connected,
          'CONNECTING' => VpnState.connecting,
          _            => VpnState.disconnected,
        };
        notifyListeners();
      },
    );
    _init();
  }

  Future<void> _init() async {
    _settings = await StorageService.getSettings();
    await _v2ray.initializeV2Ray(
      notificationIconResourceType: 'mipmap',
      notificationIconResourceName: 'ic_launcher',
    );
    _initialized = true;
    notifyListeners();
  }

  Future<void> loadServers(String subToken, {String? authData}) async {
    try {
      final sub = await ApiService.getSubscription(subToken, authData: authData);
      _servers = Server.parseSubscription(sub);
      if (_servers.isNotEmpty && _selected == null && !_autoSelect) {
        _selected = _servers.first;
      }
      _lastUpdated = DateTime.now();
      notifyListeners();
    } catch (_) {}
  }

  // Select a specific server — if VPN is on, reconnect with new server
  void selectServer(Server server) {
    final wasConnected = _state == VpnState.connected;
    _autoSelect = false;
    _selected = server;
    notifyListeners();
    if (wasConnected) _reconnect();
  }

  // Enable auto-select mode — actual ping happens synchronously inside connect()
  void setAutoSelect() {
    final wasConnected = _state == VpnState.connected;
    _autoSelect = true;
    _selected = null;
    notifyListeners();
    if (wasConnected) _reconnect();
  }

  Future<void> _reconnect() async {
    await disconnect();
    await Future.delayed(const Duration(milliseconds: 800));
    await connect();
  }

  Future<void> _pingAndPickBest() async {
    Server? best;
    int bestPing = 99999;
    for (final s in _servers) {
      final p = await pingServer(s);
      if (p > 0 && p < bestPing) {
        bestPing = p;
        best = s;
      }
    }
    // If all timed out, fall back to first server
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

    // Auto-select: ping all servers FIRST then pick best
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
    await _v2ray.stopV2Ray();
    _state = VpnState.disconnected;
    notifyListeners();
  }

  Future<int> pingServer(Server server) async {
    final start = DateTime.now().millisecondsSinceEpoch;
    try {
      final socket = await Socket.connect(
        server.host,
        server.port,
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

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    _settings = settings;
    await StorageService.saveSettings(settings);
    notifyListeners();
  }
}
