import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const _keySubUrl = 'auth_sub_url';
  static const _keyGuestMode = 'auth_guest_mode';

  static Future<String?> getSubUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySubUrl);
  }

  static Future<void> saveSubUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySubUrl, url);
    await prefs.setBool(_keyGuestMode, false);
  }

  static Future<bool> isGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyGuestMode) ?? false;
  }

  static Future<void> setGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyGuestMode, true);
  }

  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySubUrl) != null ||
        (prefs.getBool(_keyGuestMode) ?? false);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySubUrl);
    await prefs.remove(_keyGuestMode);
  }

  // Convert a token or URL into a Clash Meta subscription URL.
  static String toClashUrl(String input) {
    input = input.trim();
    if (input.startsWith('http://') || input.startsWith('https://')) {
      final uri = Uri.tryParse(input);
      if (uri == null) return input;
      final params = Map<String, String>.from(uri.queryParameters);
      if (!params.containsKey('flag') || params['flag'] == 'v2rayn') {
        params['flag'] = 'clash';
      }
      return uri.replace(queryParameters: params).toString();
    }
    // Treat as a token
    const base = 'https://client-user.jiangsuhk.com/api/v1/client/subscribe';
    return '$base?token=$input&flag=clash';
  }
}
