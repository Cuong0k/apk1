import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import '../models/server.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/xray_config_builder.dart';

enum VpnState { disconnected, connecting, connected }

class VpnProvider extends ChangeNotifier {
  final FlutterV2ray _v2ray = FlutterV2ray(onStatusChanged: (_) {});

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
    _init();
  }

  Future<void> _init() async {
    _settings = await StorageService.getSettings();
    await _v2ray.initializeV2Ray(
      notificationIconResourceType: 'mipmap',
      notificationIconResourceName: 'ic_launcher',
    );
    _initialized = true;

    _v2ray.v2RayStatusStream.listen((status) {
      _status = status;
      _state = switch (status.state) {
        'CONNECTED'    => VpnState.connected,
        'CONNECTING'   => VpnState.connecting,
        _              => VpnState.disconnected,
      };
      notifyListeners();
    });
  }

  Future<void> loadServers(String token) async {
    try {
      final sub = await ApiService.getSubscription(token);
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

    final permission = await FlutterV2ray.requestPermission();
    if (!permission) return;

    _state = VpnState.connecting;
    notifyListeners();

    try {
      final config = XrayConfigBuilder.build(_selected!, _settings);
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

  /// Ping a server by running xray in proxy-only mode and measuring latency.
  Future<int> pingServer(Server server) async {
    try {
      final config = XrayConfigBuilder.build(server, _settings);
      final delay = await FlutterV2ray.getServerDelay(config: config);
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
