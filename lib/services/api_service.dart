import 'package:dio/dio.dart';

class ApiService {
  static const _baseUrl = 'https://client-user.jiangsuhk.com';

  static Dio _dio({String? token, bool formEncoded = false}) {
    return Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': formEncoded
            ? 'application/x-www-form-urlencoded'
            : 'application/json',
        'User-Agent': 'Mozilla/5.0 VPNStore/1.0',
        'Origin': _baseUrl,
        'Referer': '$_baseUrl/',
        if (token != null) 'Authorization': token,
      },
      validateStatus: (status) => status != null && status < 500,
    ));
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    // Thử JSON
    final r1 = await _dio().post(
      '/api/v1/passport/auth/login',
      data: {'email': email, 'password': password},
    );
    if (r1.statusCode == 200) return _parseData(r1.data);

    // Thử form-urlencoded nếu thất bại
    final r2 = await _dio(formEncoded: true).post(
      '/api/v1/passport/auth/login',
      data: 'email=${Uri.encodeComponent(email)}&password=${Uri.encodeComponent(password)}',
    );
    if (r2.statusCode == 200) return _parseData(r2.data);

    // Trả về lỗi thân thiện theo status code
    throw Exception(_statusMessage(r2.statusCode, r2.data));
  }

  static Future<Map<String, dynamic>> getUserInfo(String token) async {
    try {
      final res = await _dio(token: token).get('/api/v1/user/info');
      if (res.statusCode == 200) return _parseData(res.data);
      throw Exception(_statusMessage(res.statusCode, res.data));
    } on DioException catch (e) {
      throw Exception(_dioMessage(e));
    }
  }

  // subToken: plain token dùng làm query param (?token=xxx)
  // authData: JWT Bearer token dùng trong header
  static Future<String> getSubscription(String subToken, {String? authData}) async {
    try {
      final res = await _dio(token: authData).get(
        '/api/v1/client/subscribe',
        queryParameters: {'token': subToken, 'flag': 'v2rayn'},
      );
      return res.data.toString();
    } on DioException catch (e) {
      throw Exception(_dioMessage(e));
    }
  }

  static Map<String, dynamic> _parseData(dynamic body) {
    if (body is Map) {
      if (body['data'] != null) return Map<String, dynamic>.from(body['data'] as Map);
      throw Exception(body['message']?.toString() ?? 'Lỗi từ server');
    }
    throw Exception('Dữ liệu không hợp lệ');
  }

  static String _statusMessage(int? code, dynamic body) {
    // Thử lấy message từ body
    if (body is Map && body['message'] != null) return body['message'].toString();
    return switch (code) {
      400 => 'Thông tin đăng nhập không hợp lệ',
      401 => 'Không có quyền truy cập',
      403 => 'Email hoặc mật khẩu không đúng',
      404 => 'Không tìm thấy tài nguyên',
      422 => 'Dữ liệu không hợp lệ',
      429 => 'Quá nhiều yêu cầu, thử lại sau',
      _   => 'Lỗi server ($code)',
    };
  }

  static String _dioMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Kết nối timeout, kiểm tra mạng';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Không thể kết nối tới server';
    }
    return _statusMessage(e.response?.statusCode, e.response?.data);
  }
}
