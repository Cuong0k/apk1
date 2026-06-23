import 'package:fl_clash/auth/auth_storage.dart';
import 'package:fl_clash/models/models.dart';
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
    final token = _ctrl.text.trim();
    if (token.isEmpty) {
      setState(() => _error = 'Vui lòng nhập mã định danh');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final clashUrl = AuthStorage.toClashUrl(token);
      // Download and validate subscription before entering app
      final profile = await Profile.normal(url: clashUrl, label: 'VPN Store').update();
      ref.read(profilesActionProvider.notifier).putProfile(profile);
      await AuthStorage.saveSubUrl(clashUrl);
      if (mounted) widget.onLoginSuccess();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _useGuest() async {
    await AuthStorage.setGuestMode();
    if (mounted) widget.onLoginSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6BAED6),
              Color(0xFF3A80D2),
              Color(0xFF72B8E8),
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 4,
                shadowColor: Colors.black26,
                color: const Color(0xFFF7F7F7),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Kết nối',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3E72),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'với panel để sử dụng',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Token input field
                      TextField(
                        controller: _ctrl,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Mã định danh trang web',
                          hintStyle: const TextStyle(
                            color: Colors.black38,
                            fontSize: 15,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFDDDDDD)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFCCCCCC)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFF3A80D2),
                              width: 1.5,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Help link
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Mã định danh trang web là gì?'),
                              content: const Text(
                                'Đây là token đăng ký dịch vụ VPN của bạn. '
                                'Bạn có thể lấy mã này từ trang quản lý tài khoản '
                                'hoặc email đăng ký dịch vụ.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Đã hiểu'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text(
                          'Mã định danh trang web là gì?',
                          style: TextStyle(
                            color: Color(0xFF2B6CC4),
                            fontSize: 13,
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Continue button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2B6CC4),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                const Color(0xFF2B6CC4).withOpacity(0.6),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
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
                                  'Tiếp tục',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Guest mode
                      TextButton(
                        onPressed: _loading ? null : _useGuest,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2B6CC4),
                        ),
                        child: const Text(
                          'Dùng chế độ khách',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
