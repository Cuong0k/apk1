import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class StorageService {
  static const _keyToken = 'auth_token';
  static const _keyEmail = 'auth_email';
  static const _keySettings = 'vpn_settings';

  static String _obfuscate(String value) {
    final bytes = utf8.encode(value + 'vpnstore_salt_2026');
    final hash = sha256.convert(bytes).toString().substring(0, 16);
    final encoded = base64.encode(utf8.encode(value));
    return '$hash.$encoded';
  }

  static String? _deobfuscate(String stored) {
    try {
      final parts = stored.split('.');
      if (parts.length < 2) return null;
      return utf8.decode(base64.decode(parts.sublist(1).join('.')));
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveAuth(String token, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, _obfuscate(token));
    await prefs.setString(_keyEmail, email);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_keyToken);
    if (stored == null) return null;
    return _deobfuscate(stored);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
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
    'china_bypass': false,
    'dns_primary': '1.1.1.1',
    'dns_secondary': '8.8.8.8',
    'tcp_fast_open': false,
    'allow_insecure': false,
  };
}
