import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

const _kSubBase = 'https://client-user.jiangsuhk.com';
const _kValidHost = 'client-user.jiangsuhk.com';

String _subUrl(String token) =>
    '$_kSubBase/api/v1/client/subscribe?token=$token&flag=clash';

// Extract the raw token from whatever the user pasted (URL or plain text)
String _extractToken(String raw) {
  if (raw.startsWith('http')) {
    final uri = Uri.tryParse(raw);
    return uri?.queryParameters['token'] ?? '';
  }
  return raw.trim();
}

// ─── Token validation helpers ─────────────────────────────────────────────────

/// Returns false only on a clear auth error (401/403/404).
/// Returns true on network errors so we don't force-logout on bad connectivity.
Future<bool> validateStoredToken() async {
  final token = await preferences.getVpnToken();
  if (token == null || token.isEmpty) return false;
  try {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    final req = await client.getUrl(Uri.parse(_subUrl(token)));
    req.headers.set('User-Agent', 'clash.meta');
    final res = await req.close();
    await res.drain<void>();
    client.close();
    if (res.statusCode == 401 || res.statusCode == 403 || res.statusCode == 404) {
      return false;
    }
    return true;
  } catch (_) {
    return true; // network error → don't force logout
  }
}

/// Clears token and shows token login screen.
Future<void> redirectToTokenLogin() async {
  await preferences.setVpnToken('');
  final ctx = globalState.navigatorKey.currentContext;
  if (ctx == null || !ctx.mounted) return;
  await Navigator.of(ctx).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const TokenLoginPage(),
    ),
  );
}

// ─── Token login page ─────────────────────────────────────────────────────────

class TokenLoginPage extends StatefulWidget {
  const TokenLoginPage({super.key});

  @override
  State<TokenLoginPage> createState() => _TokenLoginPageState();
}

class _TokenLoginPageState extends State<TokenLoginPage> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _scanQr() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _QrScanPage()),
    );
    if (result == null || result.isEmpty) return;
    // Always extract token — never trust a foreign server URL
    _ctrl.text = _extractToken(result);
  }

  Future<void> _confirm() async {
    final raw = _ctrl.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = 'Vui lòng nhập token');
      return;
    }
    // Only accept plain tokens; reject full URLs from other servers
    final token = _extractToken(raw);
    if (token.isEmpty) {
      setState(() => _error = 'Token không hợp lệ');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    // ALWAYS validate against client-user.jiangsuhk.com, never other servers
    final subUrl = _subUrl(token);

    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 12);
      final req = await client.getUrl(Uri.parse(subUrl));
      req.headers.set('User-Agent', 'clash.meta');
      final res = await req.close();
      client.close();

      if (res.statusCode == 401 ||
          res.statusCode == 403 ||
          res.statusCode == 404) {
        setState(() {
          _loading = false;
          _error = 'Token không hợp lệ hoặc chưa được kích hoạt';
        });
        return;
      }
      if (res.statusCode != 200) {
        setState(() {
          _loading = false;
          _error = 'Lỗi máy chủ (${res.statusCode}). Thử lại sau.';
        });
        return;
      }

      await preferences.setVpnToken(token);

      final container = globalState.container;
      try {
        final profile = await Profile.normal(url: subUrl).update();
        container.read(profilesActionProvider.notifier).putProfile(profile);
      } catch (_) {
        // Profile update failed (bad YAML?), but token is saved — user can refresh later
      }

      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'Không thể kết nối. Kiểm tra mạng và thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Icon(Icons.vpn_key_rounded, size: 72, color: scheme.primary),
                const SizedBox(height: 24),
                Text(
                  'Kích hoạt VPN Store',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nhập token kích hoạt hoặc quét mã QR để sử dụng ứng dụng',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _ctrl,
                  decoration: InputDecoration(
                    labelText: 'Token kích hoạt',
                    hintText: 'Nhập token của bạn...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.token_outlined),
                    errorText: _error,
                  ),
                  onSubmitted: (_) => _confirm(),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _scanQr,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Quét mã QR'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _loading ? null : _confirm,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Xác nhận', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Inline QR scanner ────────────────────────────────────────────────────────

class _QrScanPage extends StatefulWidget {
  const _QrScanPage();

  @override
  State<_QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<_QrScanPage> {
  final MobileScannerController _ctrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  StreamSubscription<Object?>? _sub;
  bool _popped = false;

  @override
  void initState() {
    super.initState();
    _sub = _ctrl.barcodes.listen(_onBarcode);
    unawaited(_ctrl.start());
  }

  void _onBarcode(BarcodeCapture capture) {
    if (_popped) return;
    final raw = capture.barcodes.firstOrNull?.rawValue ?? '';
    if (raw.isNotEmpty) {
      _popped = true;
      Navigator.of(context).pop(raw);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final xFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (xFile == null) return;
    final tmpCtrl = MobileScannerController();
    try {
      final capture = await tmpCtrl.analyzeImage(
        xFile.path,
        formats: [BarcodeFormat.qrCode],
      );
      final raw = capture?.barcodes.firstOrNull?.rawValue ?? '';
      if (raw.isNotEmpty && mounted) Navigator.of(context).pop(raw);
    } finally {
      tmpCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Quét mã QR', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library, color: Colors.white),
            tooltip: 'Chọn từ thư viện',
            onPressed: _pickFromGallery,
          ),
        ],
      ),
      body: MobileScanner(controller: _ctrl),
    );
  }
}
