import 'package:dio/dio.dart';

class ApiService {
  static const _baseUrl = 'https://vpnstore.pro.vn';

  static Dio _dio(String? token) {
    final dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        if (token != null) 'Authorization': token,
        'Content-Type': 'application/json',
      },
    ));
    return dio;
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio(null).post('/api/v1/passport/auth/login', data: {
      'email': email,
      'password': password,
    });
    if (res.data['data'] == null) {
      throw Exception(res.data['message'] ?? 'Đăng nhập thất bại');
    }
    return Map<String, dynamic>.from(res.data['data']);
  }

  static Future<Map<String, dynamic>> getUserInfo(String token) async {
    final res = await _dio(token).get('/api/v1/user/info');
    if (res.data['data'] == null) {
      throw Exception('Không lấy được thông tin người dùng');
    }
    return Map<String, dynamic>.from(res.data['data']);
  }

  static Future<String> getSubscription(String token) async {
    final res = await _dio(token).get(
      '/api/v1/client/subscribe',
      queryParameters: {'flag': 'v2rayn'},
    );
    return res.data.toString();
  }
}
