import 'package:dio/dio.dart';

/// Clash Meta REST API client (external-controller at 127.0.0.1:9091).
/// Provides proxy switching, latency testing, and config patching.
class ClashApi {
  static const _base = 'http://127.0.0.1:9091';

  static final _dio = Dio(BaseOptions(
    baseUrl: _base,
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 5),
    headers: {'Content-Type': 'application/json'},
  ));

  // ── Proxy management ──────────────────────────────────────────────────

  /// Get all proxy groups and their current selection / URL-test latency.
  /// Returns null if REST API not yet ready.
  static Future<Map<String, dynamic>?> getProxies() async {
    try {
      final r = await _dio.get('/proxies');
      return Map<String, dynamic>.from(r.data['proxies'] as Map? ?? {});
    } catch (_) {
      return null;
    }
  }

  /// Switch the active proxy in [group] to [proxy].
  /// Example: selectProxy('PROXY', 'Server1') or selectProxy('PROXY', 'Auto')
  static Future<bool> selectProxy(String group, String proxy) async {
    try {
      await _dio.put(
        '/proxies/${Uri.encodeComponent(group)}',
        data: {'name': proxy},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Test latency for a single proxy. Returns ms or -1 on failure.
  static Future<int> testDelay(String proxyName, {int timeoutMs = 5000}) async {
    try {
      final r = await _dio.get(
        '/proxies/${Uri.encodeComponent(proxyName)}/delay',
        queryParameters: {
          'url': 'http://cp.cloudflare.com/generate_204',
          'timeout': timeoutMs,
        },
        options: Options(receiveTimeout: Duration(milliseconds: timeoutMs + 2000)),
      );
      return r.data['delay'] as int? ?? -1;
    } catch (_) {
      return -1;
    }
  }

  // ── Config ────────────────────────────────────────────────────────────

  /// Patch running config — change mode without restarting (global/rule/direct).
  static Future<void> setMode(String mode) async {
    try {
      await _dio.patch('/configs', data: {'mode': mode});
    } catch (_) {}
  }

  /// Returns the current Clash config as a map, or null on failure.
  static Future<Map<String, dynamic>?> getConfig() async {
    try {
      final r = await _dio.get('/configs');
      return Map<String, dynamic>.from(r.data as Map? ?? {});
    } catch (_) {
      return null;
    }
  }

  // ── Health ────────────────────────────────────────────────────────────

  /// Returns true if the Clash API is reachable.
  static Future<bool> isReady() async {
    try {
      await _dio.get('/version',
          options: Options(
            connectTimeout: const Duration(seconds: 1),
            receiveTimeout: const Duration(seconds: 1),
          ));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Wait for Clash REST API to become available (up to [maxWaitMs] ms).
  static Future<bool> waitReady({int maxWaitMs = 8000}) async {
    final deadline = DateTime.now().add(Duration(milliseconds: maxWaitMs));
    while (DateTime.now().isBefore(deadline)) {
      if (await isReady()) return true;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return false;
  }
}
