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
    final authData = await StorageService.getAuthData();
    final subToken = await StorageService.getSubToken();
    if (authData != null && subToken != null) {
      try {
        final info = await ApiService.getUserInfo(authData);
        _user = UserInfo.fromJson({...info, 'token': subToken, 'auth_data': authData});
      } catch (_) {
        await StorageService.clearAuth();
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _error = null;
    _isLoading = true;
    notifyListeners();
    try {
      final data = await ApiService.login(email, password);
      final authData = data['auth_data'] as String? ?? data['token'] as String;
      final subToken = data['token'] as String? ?? authData;
      await StorageService.saveAuth(authData, subToken, email);
      final info = await ApiService.getUserInfo(authData);
      _user = UserInfo.fromJson({...info, 'token': subToken, 'auth_data': authData});
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    if (_user == null) return;
    try {
      final info = await ApiService.getUserInfo(_user!.authData);
      _user = UserInfo.fromJson({...info, 'token': _user!.token, 'auth_data': _user!.authData});
      notifyListeners();
    } catch (_) {}
  }

  Future<void> logout() async {
    await StorageService.clearAuth();
    _user = null;
    notifyListeners();
  }
}
