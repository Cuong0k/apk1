import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const _keySubUrl = 'auth_sub_url';

  static Future<String?> getSubUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySubUrl);
  }

  static Future<void> saveSubUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySubUrl, url);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySubUrl);
  }

  // Convert a token or URL into a Clash Meta subscription URL.
  static String toClashUrl(String input) {
    input = input.trim();
    if (input.startsWith('http://') || input.startsWith('https://')) {
      // Already a URL — ensure flag=meta is set for Clash YAML format
      final uri = Uri.tryParse(input);
      if (uri == null) return input;
      final params = Map<String, String>.from(uri.queryParameters);
      if (!params.containsKey('flag') || params['flag'] == 'v2rayn') {
        params['flag'] = 'meta';
      }
      return uri.replace(queryParameters: params).toString();
    }
    // Treat as a token — construct VPNStore subscription URL
    const base = 'https://client-user.jiangsuhk.com/api/v1/client/subscribe';
    return '$base?token=$input&flag=meta';
  }
}
