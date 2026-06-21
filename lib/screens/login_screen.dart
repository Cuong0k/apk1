import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'qr_scan_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final url = _ctrl.text.trim();
    if (url.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AuthProvider>().addSubscription(url);
      if (mounted) {
        final auth = context.read<AuthProvider>();
        if (auth.error != null) setState(() => _error = auth.error);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _scanQr() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScanScreen()),
    );
    if (result != null && mounted) {
      _ctrl.text = result;
      await _submit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              const Text(
                'VPNStore',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accent,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Dán link subscription hoặc quét mã QR\nđể bắt đầu sử dụng',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.c2, fontSize: 14, height: 1.5),
              ),

              const Spacer(flex: 2),

              // URL input
              TextField(
                controller: _ctrl,
                style: TextStyle(color: context.c1, fontSize: 14),
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Dán link subscription tại đây...',
                  hintStyle: TextStyle(color: context.c3, fontSize: 14),
                  filled: true,
                  fillColor: context.inputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear, color: context.c3, size: 18),
                    onPressed: () { _ctrl.clear(); setState(() => _error = null); },
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.disconnected.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.disconnected.withOpacity(0.3)),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppTheme.disconnected, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // QR scan
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.qr_code_scanner_outlined),
                  label: const Text('Quét mã QR'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accent,
                    side: const BorderSide(color: AppTheme.accent),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _loading ? null : _scanQr,
                ),
              ),

              const SizedBox(height: 10),

              // Confirm
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Xác nhận',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),

              const SizedBox(height: 20),
              Text(
                'Chỉ chấp nhận link từ dịch vụ VPNStore',
                style: TextStyle(color: context.c4, fontSize: 12),
                textAlign: TextAlign.center,
              ),

              // Dark/Light toggle on login screen
              const SizedBox(height: 8),
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: context.c3,
                  size: 20,
                ),
                onPressed: () => context.read<ThemeProvider>().toggle(),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
