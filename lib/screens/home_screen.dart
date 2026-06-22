import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/vpn_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'server_list_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _apkUrl = 'https://client-user.jiangsuhk.com/app/update/vpnstore.apk';
  static const _updateChannel = MethodChannel('com.vpnstore.app/update');

  int _tab = 0;
  bool _updating = false;
  bool _downloadingApp = false;
  double? _downloadProgress;
  String? _downloadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final vpn = context.read<VpnProvider>();
    await auth.refreshUser();
    if (auth.user != null) {
      await vpn.loadServers(auth.user!.token, authData: auth.user!.authData);
    }
  }

  Future<void> _downloadAndInstall() async {
    setState(() { _downloadingApp = true; _downloadProgress = 0; _downloadError = null; });
    try {
      final cacheDir = await _updateChannel.invokeMethod<String>('getCacheDir');
      final savePath = '$cacheDir/vpnstore_update.apk';
      await Dio().download(
        _apkUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) setState(() => _downloadProgress = received / total);
        },
      );
      if (mounted) await _updateChannel.invokeMethod('installApk', {'path': savePath});
    } catch (e) {
      if (mounted) setState(() => _downloadError = 'Lỗi: $e');
    } finally {
      if (mounted) setState(() { _downloadingApp = false; _downloadProgress = null; });
    }
  }

  Future<void> _onUpdate() async {
    setState(() => _updating = true);
    await _load();
    if (!mounted) return;
    setState(() => _updating = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cập nhật thành công'),
        backgroundColor: AppTheme.connected,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthProvider>();
    final vpn   = context.watch<VpnProvider>();
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('VPN Store', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(theme.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => context.read<ThemeProvider>().toggle(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              if (vpn.isConnected) await vpn.disconnect();
              await auth.logout();
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _buildDashboard(auth, vpn),
          _buildTools(auth, vpn, theme),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Bảng điều khiển',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build_outlined),
            activeIcon: Icon(Icons.build),
            label: 'Công cụ',
          ),
        ],
      ),
    );
  }

  // ─── Tab 0: Dashboard ─────────────────────────────────────────────────────

  Widget _buildDashboard(AuthProvider auth, VpnProvider vpn) {
    final user       = auth.user;
    final stateColor = vpn.isConnected ? AppTheme.connected : AppTheme.disconnected;
    final stateLabel = switch (vpn.state) {
      VpnState.connected    => 'Đã kết nối',
      VpnState.connecting   => 'Đang kết nối...',
      VpnState.disconnected => 'Chưa kết nối',
    };

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Data usage card ──
            if (user != null)
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.data_usage_outlined, size: 16, color: context.c3),
                          const SizedBox(width: 6),
                          Text(
                            '${user.usedGB.toStringAsFixed(2)} / ${user.totalGB.toStringAsFixed(2)} GB',
                            style: TextStyle(color: context.c1, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          Icon(Icons.calendar_today_outlined, size: 14, color: context.c3),
                          const SizedBox(width: 4),
                          Text(user.expiredDate, style: TextStyle(color: context.c2, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: user.usedPercent,
                          backgroundColor: context.c4,
                          color: user.usedPercent > 0.9 ? AppTheme.disconnected : AppTheme.accent,
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Warning ──
            if (user != null && !user.isActive)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.disconnected.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.disconnected.withOpacity(0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppTheme.disconnected, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tài khoản của bạn đã hết hạn hoặc chưa kích hoạt',
                        style: TextStyle(color: AppTheme.disconnected, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // ── VPN button ──
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: stateColor.withOpacity(0.3), width: 1.5),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: (vpn.state == VpnState.connecting || (user != null && !user.isActive))
                        ? null
                        : vpn.toggleVpn,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: stateColor.withOpacity(0.15),
                        border: Border.all(color: stateColor, width: 3),
                      ),
                      child: vpn.state == VpnState.connecting
                          ? const Center(child: CircularProgressIndicator())
                          : Icon(Icons.power_settings_new_rounded, size: 56, color: stateColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(stateLabel, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: stateColor)),
                  if (vpn.isConnected && vpn.totalSpeedStr.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.speed_rounded, size: 16, color: context.c2),
                        const SizedBox(width: 6),
                        Text(vpn.totalSpeedStr,
                            style: TextStyle(color: context.c1, fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Routing mode: Quy tắc / Toàn cầu / Trực tiếp ──
            _RoutingBar(vpn: vpn),

            const SizedBox(height: 8),

            // ── Server selector + refresh ──
            Card(
              child: Column(
                children: [
                  InkWell(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    onTap: () {
                      if (user != null && !user.isActive) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Tài khoản chưa kích hoạt hoặc đã hết hạn'),
                          backgroundColor: AppTheme.disconnected,
                        ));
                        return;
                      }
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ServerListScreen()));
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.dns_outlined, color: AppTheme.accent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vpn.autoSelect ? 'Tự động (Tốt nhất)' : (vpn.selected?.name ?? 'Chọn máy chủ'),
                                  style: TextStyle(color: context.c1, fontSize: 15, fontWeight: FontWeight.w500),
                                ),
                                if (vpn.autoSelect && vpn.selected != null)
                                  Text('→ ${vpn.selected!.name}', style: TextStyle(color: context.c3, fontSize: 12)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: context.c3),
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1, color: context.c4),
                  InkWell(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                    onTap: _updating ? null : _onUpdate,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          _updating
                              ? const SizedBox(width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent))
                              : const Icon(Icons.sync, color: AppTheme.accent, size: 20),
                          const SizedBox(width: 12),
                          Text('Cập nhật VPN', style: TextStyle(color: context.c1, fontSize: 14)),
                          const Spacer(),
                          if (vpn.lastUpdated != null)
                            Text(_fmtTime(vpn.lastUpdated!), style: TextStyle(color: context.c3, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tab 1: Tools ─────────────────────────────────────────────────────────

  Widget _buildTools(AuthProvider auth, VpnProvider vpn, ThemeProvider theme) {
    final user = auth.user;

    return ListView(
      children: [
        // ── Thêm ──
        const _ToolSectionHeader('Thêm'),
        _ToolTile(
          icon: Icons.network_check_outlined,
          title: 'Kiểm tra độ trễ',
          subtitle: 'Ping và so sánh tất cả máy chủ',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServerListScreen())),
        ),
        Divider(height: 1, indent: 56, color: context.c4),
        _ToolTile(
          icon: Icons.system_update_alt_outlined,
          title: 'Cập nhật ứng dụng',
          subtitle: _downloadingApp && _downloadProgress != null
              ? 'Đang tải... ${(_downloadProgress! * 100).toStringAsFixed(0)}%'
              : 'Tải phiên bản mới nhất',
          trailing: _downloadingApp
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent))
              : null,
          onTap: _downloadingApp ? null : _downloadAndInstall,
        ),
        if (_downloadError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 0, 16, 8),
            child: Text(_downloadError!, style: const TextStyle(color: AppTheme.disconnected, fontSize: 12)),
          ),

        // ── Cài đặt ──
        const _ToolSectionHeader('Cài đặt'),
        _ToolTile(
          icon: Icons.palette_outlined,
          title: 'Giao diện',
          subtitle: theme.isDark ? 'Đặt chế độ tối' : 'Đặt chế độ sáng',
          onTap: () => context.read<ThemeProvider>().toggle(),
        ),
        Divider(height: 1, indent: 56, color: context.c4),
        _ToolTile(
          icon: Icons.alt_route_outlined,
          title: 'Chế độ định tuyến',
          subtitle: switch (vpn.routingMode) {
            'rules'  => 'Quy tắc — bypass VN, proxy phần còn lại',
            'direct' => 'Trực tiếp — không qua VPN',
            _        => 'Toàn cầu — tất cả qua VPN',
          },
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
        Divider(height: 1, indent: 56, color: context.c4),
        _ToolTile(
          icon: Icons.tune_outlined,
          title: 'Cấu hình nâng cao',
          subtitle: 'DNS, TCP, sniffing, log...',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),

        // ── Tài khoản ──
        if (user != null) ...[
          const _ToolSectionHeader('Tài khoản'),
          if (user.id != null) ...[
            _ToolTile(icon: Icons.badge_outlined, title: 'ID', subtitle: '#${user.id}'),
            Divider(height: 1, indent: 56, color: context.c4),
          ],
          _ToolTile(
            icon: Icons.card_membership_outlined,
            title: 'Gói dịch vụ',
            subtitle: user.planName ?? 'Chưa kích hoạt',
          ),
          Divider(height: 1, indent: 56, color: context.c4),
          _ToolTile(
            icon: Icons.calendar_today_outlined,
            title: 'Hết hạn',
            subtitle: user.expiredDate,
          ),
        ],

        const SizedBox(height: 32),
      ],
    );
  }

  String _fmtTime(DateTime dt) {
    final h  = dt.hour.toString().padLeft(2, '0');
    final m  = dt.minute.toString().padLeft(2, '0');
    final d  = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    return '$h:$m $d/$mo';
  }
}

// ─── Routing mode bar ─────────────────────────────────────────────────────────

class _RoutingBar extends StatelessWidget {
  final VpnProvider vpn;
  const _RoutingBar({required this.vpn});

  static const _modes = [
    ('rules',  'Quy tắc',   Icons.alt_route_outlined),
    ('global', 'Toàn cầu',  Icons.public_outlined),
    ('direct', 'Trực tiếp', Icons.sync_disabled_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final current = vpn.routingMode;
    return Row(
      children: _modes.map((m) {
        final isActive = current == m.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => vpn.setRoutingMode(m.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.accent.withOpacity(0.12) : context.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? AppTheme.accent : context.c4,
                  width: isActive ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(m.$3, color: isActive ? AppTheme.accent : context.c3, size: 18),
                  const SizedBox(height: 4),
                  Text(
                    m.$2,
                    style: TextStyle(
                      color: isActive ? AppTheme.accent : context.c2,
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Tools helper widgets ─────────────────────────────────────────────────────

class _ToolSectionHeader extends StatelessWidget {
  final String text;
  const _ToolSectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
    child: Text(
      text,
      style: TextStyle(
        color: context.c3,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
  );
}

class _ToolTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ToolTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    leading: Icon(icon, color: context.iconColor, size: 22),
    title: Text(title, style: TextStyle(color: context.c1, fontSize: 14)),
    subtitle: Text(subtitle, style: TextStyle(color: context.c3, fontSize: 12)),
    trailing: trailing ?? (onTap != null
        ? Icon(Icons.chevron_right, color: context.c4, size: 20)
        : null),
    onTap: onTap,
  );
}
