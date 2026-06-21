import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class StorageService {
  static const _keyAuthData = 'auth_data';   // JWT Bearer token cho API
  static const _keySubToken = 'sub_token';   // plain token cho subscription URL
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
      return Map<String, dynamic>.from(jsonDecode(raw));
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
    'domain_bypass': true,
    'dns_primary': '1.1.1.1',
    'dns_secondary': '8.8.8.8',
    'tcp_fast_open': false,
    'allow_insecure': false,
  };
}
