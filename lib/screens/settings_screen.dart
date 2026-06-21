import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vpn_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Map<String, dynamic> _settings;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _settings = Map.from(context.read<VpnProvider>().settings);
        _loaded = true;
      });
    });
  }

  void _save() {
    context.read<VpnProvider>().updateSettings(_settings);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu cài đặt'),
        backgroundColor: AppTheme.connected,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Lưu', style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader('Tối ưu kết nối TCP/VPN'),
          Card(
            child: Column(
              children: [
                _SwitchTile(
                  title: 'Bỏ qua mạng LAN',
                  subtitle: 'Truy cập mạng nội bộ không qua VPN',
                  icon: Icons.lan_outlined,
                  value: _settings['domain_bypass'] ?? true,
                  onChanged: (v) => setState(() => _settings['domain_bypass'] = v),
                ),
                _Divider(),
                _SwitchTile(
                  title: 'Hỗ trợ UDP',
                  subtitle: 'Cần cho game và cuộc gọi video',
                  icon: Icons.speed_outlined,
                  value: _settings['udp_enabled'] ?? true,
                  onChanged: (v) => setState(() => _settings['udp_enabled'] = v),
                ),
                _Divider(),
                _SwitchTile(
                  title: 'TCP Fast Open',
                  subtitle: 'Giảm độ trễ TCP khi kết nối',
                  icon: Icons.flash_on_outlined,
                  value: _settings['tcp_fast_open'] ?? false,
                  onChanged: (v) => setState(() => _settings['tcp_fast_open'] = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _SectionHeader('Bảo mật'),
          Card(
            child: Column(
              children: [
                _SwitchTile(
                  title: 'Bỏ qua xác minh TLS',
                  subtitle: 'Chỉ bật khi dùng cert tự ký',
                  icon: Icons.security_outlined,
                  value: _settings['allow_insecure'] ?? false,
                  onChanged: (v) => setState(() => _settings['allow_insecure'] = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _SectionHeader('DNS'),
          Card(
            child: Column(
              children: [
                _TextTile(
                  title: 'DNS chính',
                  value: _settings['dns_primary'] ?? '1.1.1.1',
                  onChanged: (v) => setState(() => _settings['dns_primary'] = v),
                ),
                _Divider(),
                _TextTile(
                  title: 'DNS phụ',
                  value: _settings['dns_secondary'] ?? '8.8.8.8',
                  onChanged: (v) => setState(() => _settings['dns_secondary'] = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _SectionHeader('Mạng'),
          Card(
            child: _SliderTile(
              title: 'MTU',
              subtitle: 'Tối ưu kích thước gói tin (${_settings['mtu'] ?? 1350})',
              value: (_settings['mtu'] ?? 1350).toDouble(),
              min: 576,
              max: 1500,
              divisions: 92,
              onChanged: (v) => setState(() => _settings['mtu'] = v.round()),
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            '⚠ Thay đổi cài đặt có hiệu lực sau khi kết nối lại VPN.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
    child: Text(
      text,
      style: const TextStyle(color: AppTheme.accent, fontSize: 13, fontWeight: FontWeight.w600),
    ),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 56, color: Colors.white12);
}

class _SwitchTile extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SwitchListTile(
    title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
    subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
    secondary: Icon(icon, color: AppTheme.accent, size: 22),
    value: value,
    onChanged: onChanged,
    activeColor: AppTheme.accent,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  );
}

class _TextTile extends StatelessWidget {
  final String title, value;
  final ValueChanged<String> onChanged;

  const _TextTile({required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
    trailing: SizedBox(
      width: 120,
      child: TextFormField(
        initialValue: value,
        textAlign: TextAlign.end,
        style: const TextStyle(color: AppTheme.accent, fontSize: 14),
        decoration: const InputDecoration(
          isDense: true,
          filled: false,
          border: InputBorder.none,
        ),
        onChanged: onChanged,
      ),
    ),
  );
}

class _SliderTile extends StatelessWidget {
  final String title, subtitle;
  final double value, min, max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
        Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: AppTheme.accent,
          onChanged: onChanged,
        ),
      ],
    ),
  );
}
