import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

const _kSubBase = 'https://client-user.jiangsuhk.com';

String _subUrl(String token) =>
    '$_kSubBase/api/v1/client/subscribe?token=$token&flag=clash';

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
    if (result.startsWith('http')) {
      final uri = Uri.tryParse(result);
      _ctrl.text = uri?.queryParameters['token'] ?? result;
    } else {
      _ctrl.text = result;
    }
  }

  Future<void> _confirm() async {
    final raw = _ctrl.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = 'Vui lòng nhập token');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final subUrl = raw.startsWith('http') ? raw : _subUrl(raw);

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

      await preferences.setVpnToken(raw);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Quét mã QR', style: TextStyle(color: Colors.white)),
      ),
      body: MobileScanner(controller: _ctrl),
    );
  }
}
