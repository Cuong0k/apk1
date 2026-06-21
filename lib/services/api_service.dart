import 'package:dio/dio.dart';

class ApiService {
  static const _baseUrl = 'https://client-user.jiangsuhk.com';

  static Dio _dio({String? token, bool formData = false}) {
    final dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': formData
            ? 'application/x-www-form-urlencoded'
            : 'application/json',
        'User-Agent': 'VPNStore/1.0 (Android)',
        'Origin': _baseUrl,
        'Referer': '$_baseUrl/',
        if (token != null) 'Authorization': token,
      },
    ));
    return dio;
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    // Thử JSON trước, nếu 403 thử form-urlencoded
    try {
      final res = await _dio().post(
        '/api/v1/passport/auth/login',
        data: {'email': email, 'password': password},
      );
      return _parseData(res.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 422) {
        // Thử lại với form-urlencoded
        final res = await _dio(formData: true).post(
          '/api/v1/passport/auth/login',
          data: 'email=${Uri.encodeComponent(email)}&password=${Uri.encodeComponent(password)}',
        );
        return _parseData(res.data);
      }
      _throwFriendly(e);
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getUserInfo(String token) async {
    final res = await _dio(token: token).get('/api/v1/user/info');
    return _parseData(res.data);
  }

  static Future<String> getSubscription(String token) async {
    final res = await _dio(token: token).get(
      '/api/v1/client/subscribe',
      queryParameters: {'flag': 'v2rayn'},
    );
    return res.data.toString();
  }

  static Map<String, dynamic> _parseData(dynamic body) {
    if (body is Map) {
      final data = body['data'];
      if (data != null) return Map<String, dynamic>.from(data as Map);
      final msg = body['message']?.toString() ?? 'Lỗi không xác định';
      throw Exception(msg);
    }
    throw Exception('Phản hồi không hợp lệ từ server');
  }

  static void _throwFriendly(DioException e) {
    final code = e.response?.statusCode;
    if (code == 403) throw Exception('Email hoặc mật khẩu không đúng');
    if (code == 401) throw Exception('Phiên đăng nhập hết hạn');
    if (code == 429) throw Exception('Quá nhiều yêu cầu, thử lại sau');
    if (code == 500) throw Exception('Lỗi server, thử lại sau');
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      throw Exception('Kết nối timeout, kiểm tra mạng');
    }
    throw Exception('Không thể kết nối tới server');
  }
}
