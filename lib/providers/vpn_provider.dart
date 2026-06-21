import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import '../models/server.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/xray_config_builder.dart';

// Protocols natively supported by flutter_v2ray URL parser
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

  VpnState get state => _state;
  List<Server> get servers => _servers;
  Server? get selected => _selected;
  V2RayStatus? get status => _status;
  bool get isConnected => _state == VpnState.connected;
  Map<String, dynamic> get settings => _settings;
  String? get error => _error;

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
      if (_servers.isNotEmpty && _selected == null) {
        _selected = _servers.first;
      }
      notifyListeners();
    } catch (_) {}
  }

  void selectServer(Server server) {
    _selected = server;
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
    if (_selected == null) return;
    _error = null;

    final permission = await _v2ray.requestPermission();
    if (!permission) return;

    _state = VpnState.connecting;
    notifyListeners();

    try {
      final String config;
      if (_nativeProtocols.contains(_selected!.protocol)) {
        // Dùng flutter_v2ray URL parser cho VLESS/VMess/Trojan/SS
        final v2rayUrl = V2RayURL.parseURL(_selected!.rawUri);
        config = v2rayUrl.getFullConfiguration(
          proxyOnly: false,
          bypassLan: _settings['domain_bypass'] ?? true,
        );
      } else {
        // Dùng custom builder cho TUIC/Hysteria2/AnyTLS
        config = XrayConfigBuilder.build(_selected!, _settings);
      }
      await _v2ray.startV2Ray(
        remark: _selected!.name,
        config: config,
        blockedApps: null,
        bypassSubnets: null,
        proxyOnly: false,
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

  /// TCP ping — đo độ trễ kết nối tới server (không cần VPN đang chạy)
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
