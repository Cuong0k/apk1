import 'package:flutter/material.dart';
import '../models/user_info.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

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
    // Strategy 1: custom /user-info endpoint (token → real DB data)
    try {
      final info = await ApiService.getUserInfoByToken(token);
      _user = UserInfo.fromJson({...info, 'token': token, 'auth_data': token});
      if (save) await StorageService.saveSubToken(token);
      return;
    } catch (_) {}

    // Strategy 2: fetch subscription → valid content = account is active
    try {
      final result = await ApiService.getSubscriptionWithInfo(token);
      final valid = result.content.isNotEmpty &&
                    result.content != 'null' &&
                    result.content.length > 10;
      if (valid) {
        final base = result.userInfo ?? {};
        _user = UserInfo.fromJson({
          'token': token,
          'auth_data': token,
          'email': base['email'] ?? '',
          'transfer_enable': base['transfer_enable'] ?? 0,
          'u': base['u'] ?? 0,
          'd': base['d'] ?? 0,
          'expired_at': base['expired_at'],
          'plan': {'name': 'VPNStore'},
          'plan_id': 1,
        });
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

  // Accept any URL — token validity is validated by _loadUser
  bool _isValidDomain(String input) => true;

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
