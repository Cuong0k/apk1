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
  late Map<String, dynamic> _s;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _s = Map.from(context.read<VpnProvider>().settings);
        _loaded = true;
      });
    });
  }

  void _save() {
    context.read<VpnProvider>().updateSettings(_s);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu — có hiệu lực khi kết nối lại'),
        backgroundColor: AppTheme.connected,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Lưu', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          _Header('Kết nối'),
          Card(
            child: Column(
              children: [
                _Switch(icon: Icons.speed_outlined,
                  title: 'Hỗ trợ UDP', sub: 'Cần cho game, DNS, cuộc gọi video',
                  value: _s['udp_enabled'] ?? true,
                  onChange: (v) => setState(() => _s['udp_enabled'] = v)),
                _Div(),
                _Switch(icon: Icons.network_check_outlined,
                  title: 'Hỗ trợ IPv6', sub: 'Cho phép lưu lượng IPv6 qua VPN',
                  value: _s['ipv6_enabled'] ?? true,
                  onChange: (v) => setState(() => _s['ipv6_enabled'] = v)),
                _Div(),
                _Switch(icon: Icons.lan_outlined,
                  title: 'Bỏ qua mạng LAN', sub: 'Truy cập nội bộ không qua VPN',
                  value: _s['domain_bypass'] ?? true,
                  onChange: (v) => setState(() => _s['domain_bypass'] = v)),
                _Div(),
                _Switch(icon: Icons.notifications_off_outlined,
                  title: 'Im lặng khi tự chọn máy chủ',
                  sub: 'Ẩn tên máy chủ trên thông báo VPN',
                  value: _s['silent_auto_select'] ?? false,
                  onChange: (v) => setState(() => _s['silent_auto_select'] = v)),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _Header('Định tuyến'),
          Card(
            child: _Dropdown(
              icon: Icons.alt_route_outlined,
              title: 'Chế độ định tuyến',
              sub: (_s['routing_mode'] ?? 'global') == 'global'
                  ? 'Tất cả lưu lượng qua VPN'
                  : 'Bỏ qua VN/LAN, proxy phần còn lại',
              value: _s['routing_mode'] ?? 'global',
              options: const [
                _Opt('global', 'Toàn cầu'),
                _Opt('rules', 'Quy tắc (Bypass VN)'),
              ],
              onChange: (v) => setState(() => _s['routing_mode'] = v),
            ),
          ),

          const SizedBox(height: 16),
          _Header('DNS'),
          Card(
            child: Column(
              children: [
                _Switch(icon: Icons.dns_outlined,
                  title: 'Chặn bắt DNS', sub: 'Định tuyến DNS qua VPN, tránh rò rỉ',
                  value: _s['dns_hijack'] ?? true,
                  onChange: (v) => setState(() => _s['dns_hijack'] = v)),
                _Div(),
                _TextField(icon: Icons.looks_one_outlined,
                  title: 'DNS chính',
                  value: _s['dns_primary'] ?? '1.1.1.1',
                  onChange: (v) => setState(() => _s['dns_primary'] = v)),
                _Div(),
                _TextField(icon: Icons.looks_two_outlined,
                  title: 'DNS phụ',
                  value: _s['dns_secondary'] ?? '8.8.8.8',
                  onChange: (v) => setState(() => _s['dns_secondary'] = v)),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _Header('Tối ưu TCP'),
          Card(
            child: Column(
              children: [
                _Switch(icon: Icons.flash_on_outlined,
                  title: 'TCP Fast Open', sub: 'Giảm độ trễ kết nối TCP',
                  value: _s['tcp_fast_open'] ?? true,
                  onChange: (v) => setState(() => _s['tcp_fast_open'] = v)),
                _Div(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tune_outlined, color: AppTheme.accent, size: 22),
                          const SizedBox(width: 12),
                          Text('MTU', style: TextStyle(color: context.c1, fontSize: 14)),
                          const Spacer(),
                          Text('${_s['mtu'] ?? 1350}',
                            style: const TextStyle(color: AppTheme.accent, fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Slider(
                        value: (_s['mtu'] ?? 1350).toDouble(),
                        min: 576, max: 1500, divisions: 92,
                        activeColor: AppTheme.accent,
                        onChanged: (v) => setState(() => _s['mtu'] = v.round()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _Header('Nâng cao'),
          Card(
            child: Column(
              children: [
                _Switch(icon: Icons.manage_search_outlined,
                  title: 'Sniffing (Tìm tiến trình)',
                  sub: 'Phát hiện giao thức và domain tự động',
                  value: _s['sniffing'] ?? true,
                  onChange: (v) => setState(() => _s['sniffing'] = v)),
                _Div(),
                _Dropdown(
                  icon: Icons.terminal_outlined,
                  title: 'Mức nhật ký', sub: 'Mức độ chi tiết của log xray',
                  value: _s['log_level'] ?? 'error',
                  options: const [
                    _Opt('none', 'Tắt'),
                    _Opt('error', 'Lỗi (khuyến nghị)'),
                    _Opt('warning', 'Cảnh báo'),
                    _Opt('info', 'Thông tin'),
                    _Opt('debug', 'Debug'),
                  ],
                  onChange: (v) => setState(() => _s['log_level'] = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _Header('Bảo mật'),
          Card(
            child: _Switch(icon: Icons.security_outlined,
              title: 'Bỏ qua xác minh TLS', sub: 'Chỉ bật khi dùng cert tự ký',
              value: _s['allow_insecure'] ?? false,
              onChange: (v) => setState(() => _s['allow_insecure'] = v)),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
    child: Text(text, style: const TextStyle(color: AppTheme.accent, fontSize: 13, fontWeight: FontWeight.w600)),
  );
}

class _Div extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, indent: 50, color: context.c4);
}

class _Switch extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  final bool value;
  final ValueChanged<bool> onChange;
  const _Switch({required this.icon, required this.title, required this.sub, required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) => SwitchListTile(
    secondary: Icon(icon, color: AppTheme.accent, size: 22),
    title: Text(title, style: TextStyle(color: context.c1, fontSize: 14)),
    subtitle: Text(sub, style: TextStyle(color: context.c3, fontSize: 12)),
    value: value,
    onChanged: onChange,
    activeColor: AppTheme.accent,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  );
}

class _TextField extends StatelessWidget {
  final IconData icon;
  final String title, value;
  final ValueChanged<String> onChange;
  const _TextField({required this.icon, required this.title, required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppTheme.accent, size: 22),
    title: Text(title, style: TextStyle(color: context.c1, fontSize: 14)),
    trailing: SizedBox(
      width: 120,
      child: TextFormField(
        initialValue: value,
        textAlign: TextAlign.end,
        style: const TextStyle(color: AppTheme.accent, fontSize: 14),
        decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
        onChanged: onChange,
      ),
    ),
  );
}

class _Opt {
  final String value, label;
  const _Opt(this.value, this.label);
}

class _Dropdown extends StatelessWidget {
  final IconData icon;
  final String title, sub, value;
  final List<_Opt> options;
  final ValueChanged<String> onChange;
  const _Dropdown({required this.icon, required this.title, required this.sub, required this.value, required this.options, required this.onChange});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppTheme.accent, size: 22),
    title: Text(title, style: TextStyle(color: context.c1, fontSize: 14)),
    subtitle: Text(sub, style: TextStyle(color: context.c3, fontSize: 12)),
    trailing: DropdownButton<String>(
      value: value,
      dropdownColor: context.cardBg,
      style: TextStyle(color: AppTheme.accent, fontSize: 13),
      underline: const SizedBox(),
      items: options.map((o) => DropdownMenuItem(value: o.value, child: Text(o.label))).toList(),
      onChanged: (v) { if (v != null) onChange(v); },
    ),
  );
}
