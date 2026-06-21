import 'package:dio/dio.dart';

class ApiService {
  static const _baseUrl = 'https://client-user.jiangsuhk.com';

  static Dio _dio({String? token}) {
    return Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0 VPNStore/1.0',
        'Origin': _baseUrl,
        'Referer': '$_baseUrl/',
        if (token != null) 'Authorization': token,
      },
      validateStatus: (status) => status != null && status < 500,
    ));
  }

  // Get user info by subscription token via custom endpoint
  static Future<Map<String, dynamic>> getUserInfoByToken(String token) async {
    try {
      final res = await _dio().get('/user-info', queryParameters: {'token': token});
      if (res.statusCode == 200) return _parseData(res.data);
      throw Exception(_statusMessage(res.statusCode, res.data));
    } on DioException catch (e) {
      throw Exception(_dioMessage(e));
    }
  }

  // Try to get user info using a token (works if panel accepts sub token as auth)
  static Future<Map<String, dynamic>> getUserInfo(String token) async {
    try {
      final res = await _dio(token: token).get('/api/v1/user/info');
      if (res.statusCode == 200) return _parseData(res.data);
      throw Exception(_statusMessage(res.statusCode, res.data));
    } on DioException catch (e) {
      throw Exception(_dioMessage(e));
    }
  }

  // Fetch subscription content and parse subscription-userinfo header
  static Future<({String content, Map<String, dynamic>? userInfo})>
      getSubscriptionWithInfo(String subToken) async {
    try {
      final res = await _dio().get(
        '/api/v1/client/subscribe',
        queryParameters: {'token': subToken, 'flag': 'v2rayn'},
      );
      final content = res.data.toString();
      final headerStr = res.headers.value('subscription-userinfo');
      final userInfo = headerStr != null ? _parseSubHeader(headerStr, subToken) : null;
      return (content: content, userInfo: userInfo);
    } on DioException catch (e) {
      throw Exception(_dioMessage(e));
    }
  }

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

  // Parse "upload=xxx; download=xxx; total=xxx; expire=unix" header
  static Map<String, dynamic> _parseSubHeader(String header, String token) {
    final info = <String, dynamic>{};
    for (final part in header.split(';')) {
      final kv = part.trim().split('=');
      if (kv.length == 2) info[kv[0].trim()] = int.tryParse(kv[1].trim()) ?? 0;
    }
    return {
      'u': info['upload'] ?? 0,
      'd': info['download'] ?? 0,
      'transfer_enable': info['total'] ?? 0,
      'expired_at': info['expire'],
      'token': token,
      'auth_data': token,
      'email': '',
    };
  }

  static Map<String, dynamic> _parseData(dynamic body) {
    if (body is Map) {
      if (body['data'] != null) return Map<String, dynamic>.from(body['data'] as Map);
      throw Exception(body['message']?.toString() ?? 'Lỗi từ server');
    }
    throw Exception('Dữ liệu không hợp lệ');
  }

  static String _statusMessage(int? code, dynamic body) {
    if (body is Map && body['message'] != null) return body['message'].toString();
    return switch (code) {
      400 => 'Token không hợp lệ',
      401 => 'Token đã hết hạn hoặc sai',
      403 => 'Không có quyền truy cập',
      404 => 'Không tìm thấy tài nguyên',
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
