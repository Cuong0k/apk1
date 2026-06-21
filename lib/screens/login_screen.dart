import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) return;
    await context.read<AuthProvider>().login(email, pass);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.shield_rounded, size: 72, color: AppTheme.accent),
              const SizedBox(height: 16),
              const Text(
                'VPNStore',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Đăng nhập để tiếp tục',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 40),

              if (auth.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.disconnected.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    auth.error!.replaceAll('Exception: ', ''),
                    style: const TextStyle(color: AppTheme.disconnected, fontSize: 13),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Email',
                  hintStyle: TextStyle(color: Colors.white38),
                  prefixIcon: Icon(Icons.email_outlined, color: Colors.white38),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Mật khẩu',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.white38),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white38,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: auth.isLoading ? null : _login,
                child: auth.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Đăng nhập'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
