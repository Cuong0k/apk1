import 'package:fl_clash/auth/auth_storage.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/pages/scan.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginPage extends ConsumerStatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final input = _ctrl.text.trim();
    if (input.isEmpty) {
      setState(() => _error = 'Vui lòng nhập link hoặc token');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final clashUrl = AuthStorage.toClashUrl(input);

      // Register the profile — FlClash will fetch it on first use
      final profile = Profile.normal(url: clashUrl, label: 'VPN Store');
      ref.read(profilesActionProvider.notifier).putProfile(profile);

      await AuthStorage.saveSubUrl(clashUrl);
      if (mounted) widget.onLoginSuccess();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _scanQr() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScanPage()),
    );
    if (result != null && mounted) {
      _ctrl.text = result;
      await _submit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              Icon(Icons.security_rounded, size: 72, color: cs.primary),
              const SizedBox(height: 16),
              Text(
                'VPN Store',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Dán link subscription hoặc quét mã QR\nđể bắt đầu sử dụng',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 2),

              // Input
              TextField(
                controller: _ctrl,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Dán link subscription hoặc token...',
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.primary, width: 1.5),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear, color: cs.onSurfaceVariant, size: 18),
                    onPressed: () { _ctrl.clear(); setState(() => _error = null); },
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: cs.onErrorContainer, fontSize: 13),
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
                    foregroundColor: cs.primary,
                    side: BorderSide(color: cs.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _loading ? null : _scanQr,
                ),
              ),

              const SizedBox(height: 10),

              // Confirm
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Xác nhận',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),
              Text(
                'Chỉ chấp nhận link từ dịch vụ VPN Store',
                style: TextStyle(color: cs.outline, fontSize: 12),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
