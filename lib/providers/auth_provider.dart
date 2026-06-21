import 'package:flutter/material.dart';
import '../models/user_info.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

const _allowedHost = 'client-user.jiangsuhk.com';

class AuthProvider extends ChangeNotifier {
  UserInfo? _user;
  bool _isLoading = true;
  String? _error;

  UserInfo? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final subToken = await StorageService.getSubToken();
    if (subToken != null) {
      await _loadUser(subToken, save: false);
    }
    _isLoading = false;
    notifyListeners();
  }

  // Add subscription from URL or raw token
  Future<void> addSubscription(String rawInput) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      final token = _extractToken(rawInput.trim());
      if (token == null) throw Exception('Không tìm thấy token trong link');

      if (!_isValidDomain(rawInput.trim())) {
        throw Exception('Link không thuộc dịch vụ VPNStore');
      }

      await _loadUser(token, save: true);
      if (_user == null) {
        throw Exception('Token không hợp lệ hoặc không có dữ liệu');
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUser(String token, {required bool save}) async {
    // Strategy 1: call /user/info with token as Authorization header
    try {
      final info = await ApiService.getUserInfo(token);
      _user = UserInfo.fromJson({...info, 'token': token, 'auth_data': token});
      if (save) await StorageService.saveSubToken(token);
      return;
    } catch (_) {}

    // Strategy 2: fetch subscription and parse subscription-userinfo header
    try {
      final result = await ApiService.getSubscriptionWithInfo(token);
      if (result.content.isNotEmpty && result.content != 'null') {
        final infoMap = result.userInfo ?? {'token': token, 'auth_data': token, 'email': ''};
        _user = UserInfo.fromJson({...infoMap, 'token': token, 'auth_data': token});
        if (save) await StorageService.saveSubToken(token);
      }
    } catch (_) {}
  }

  Future<void> refreshUser() async {
    if (_user == null) return;
    await _loadUser(_user!.token, save: false);
  }

  Future<void> logout() async {
    await StorageService.clearAuth();
    _user = null;
    notifyListeners();
  }

  // URL must be from our domain
  bool _isValidDomain(String input) {
    try {
      final uri = Uri.parse(input);
      // If it looks like a URL, must match our domain
      if (uri.hasScheme) return uri.host == _allowedHost;
      // If no scheme (raw token), allow it
      return true;
    } catch (_) {
      return true; // Not a URL → treat as raw token
    }
  }

  // Extract token= query param, or treat whole string as token
  String? _extractToken(String input) {
    try {
      final uri = Uri.parse(input);
      if (uri.queryParameters.containsKey('token')) {
        return uri.queryParameters['token'];
      }
    } catch (_) {}
    // Fallback: if no spaces and reasonable length, treat as raw token
    if (!input.contains(' ') && input.length > 8 && !input.startsWith('http')) {
      return input;
    }
    return null;
  }
}
