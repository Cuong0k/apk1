import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _keySubToken = 'sub_token_v2';
  static const _keySettings = 'vpn_settings';
  static const _keyAutoSelect = 'vpn_auto_select';
  static const _keySelectedUri = 'vpn_selected_uri';

  // Token stored in Android Keystore / iOS Keychain (hardware-backed encryption)
  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> saveSubToken(String subToken) async {
    await _secure.write(key: _keySubToken, value: subToken);
    // Remove any old plaintext token
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sub_token');
  }

  static Future<String?> getSubToken() async {
    // Try secure storage first
    final secure = await _secure.read(key: _keySubToken);
    if (secure != null) return secure;
    // Migrate old obfuscated token if exists
    final prefs = await SharedPreferences.getInstance();
    final old = prefs.getString('sub_token');
    if (old != null) {
      final decoded = _deobfuscate(old);
      if (decoded != null) {
        await saveSubToken(decoded); // migrate to secure
        return decoded;
      }
    }
    return null;
  }

  // Legacy deobfuscation for migration
  static String? _deobfuscate(String stored) {
    try {
      final idx = stored.indexOf('.');
      if (idx < 0) return null;
      return utf8.decode(base64.decode(stored.substring(idx + 1)));
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getAuthData() async => null;

  static Future<void> clearAuth() async {
    await _secure.delete(key: _keySubToken);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sub_token');
    await prefs.remove('auth_data');
    await prefs.remove('auth_email');
  }

  static Future<void> saveVpnMode({required bool autoSelect, String? selectedUri}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoSelect, autoSelect);
    if (selectedUri != null) {
      await prefs.setString(_keySelectedUri, selectedUri);
    } else {
      await prefs.remove(_keySelectedUri);
    }
  }

  static Future<({bool autoSelect, String? selectedUri})> getVpnMode() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      autoSelect: prefs.getBool(_keyAutoSelect) ?? false,
      selectedUri: prefs.getString(_keySelectedUri),
    );
  }

  static Future<Map<String, dynamic>> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySettings);
    if (raw == null) return _defaultSettings();
    try {
      final saved = Map<String, dynamic>.from(jsonDecode(raw));
      final defaults = _defaultSettings();
      for (final key in defaults.keys) {
        saved.putIfAbsent(key, () => defaults[key]);
      }
      return saved;
    } catch (_) {
      return _defaultSettings();
    }
  }

  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySettings, jsonEncode(settings));
  }

  static Map<String, dynamic> _defaultSettings() => {
    'mtu': 1350,
    'udp_enabled': true,
    'ipv6_enabled': true,
    'domain_bypass': true,
    'dns_primary': '1.1.1.1',
    'dns_secondary': '8.8.8.8',
    'tcp_fast_open': true,
    'allow_insecure': false,
    'dns_hijack': true,
    'sniffing': true,
    'routing_mode': 'global',
    'log_level': 'error',
    'silent_auto_select': false,
  };
}
