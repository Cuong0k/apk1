import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class StorageService {
  static const _keyAuthData = 'auth_data';
  static const _keySubToken = 'sub_token';
  static const _keyEmail    = 'auth_email';
  static const _keySettings = 'vpn_settings';

  static String _obfuscate(String value) {
    final bytes = utf8.encode(value + 'vpnstore_salt_2026');
    final hash = sha256.convert(bytes).toString().substring(0, 16);
    return '$hash.${base64.encode(utf8.encode(value))}';
  }

  static String? _deobfuscate(String stored) {
    try {
      final idx = stored.indexOf('.');
      if (idx < 0) return null;
      return utf8.decode(base64.decode(stored.substring(idx + 1)));
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveAuth(String authData, String subToken, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAuthData, _obfuscate(authData));
    await prefs.setString(_keySubToken, _obfuscate(subToken));
    await prefs.setString(_keyEmail, email);
  }

  static Future<String?> getAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_keyAuthData);
    return s != null ? _deobfuscate(s) : null;
  }

  static Future<String?> getSubToken() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_keySubToken);
    return s != null ? _deobfuscate(s) : null;
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAuthData);
    await prefs.remove(_keySubToken);
    await prefs.remove(_keyEmail);
  }

  static Future<Map<String, dynamic>> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySettings);
    if (raw == null) return _defaultSettings();
    try {
      final saved = Map<String, dynamic>.from(jsonDecode(raw));
      // Merge with defaults so new keys are always present
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
    'dns_primary': '8.8.8.8',
    'dns_secondary': '1.1.1.1',
    'tcp_fast_open': true,
    'allow_insecure': false,
    'dns_hijack': true,
    'sniffing': true,
    'routing_mode': 'global',
    'log_level': 'error',
  };
}
