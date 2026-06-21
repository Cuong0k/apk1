import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/vpn_provider.dart';
import '../theme/app_theme.dart';
import 'server_list_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  bool _updating = false;

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
    final auth = context.watch<AuthProvider>();
    final vpn = context.watch<VpnProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('VPNStore'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
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
          _buildDashboard(vpn),
          _buildTools(auth),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        backgroundColor: AppTheme.card,
        selectedItemColor: AppTheme.accent,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
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

  // ─── Tab 0: Dashboard ───────────────────────────────────────────────────────

  Widget _buildDashboard(VpnProvider vpn) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
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
            // ── Data info compact card ──
            if (user != null)
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.data_usage_outlined, size: 16, color: Colors.white38),
                          const SizedBox(width: 6),
                          Text(
                            '${user.usedGB.toStringAsFixed(2)} / ${user.totalGB.toStringAsFixed(2)} GB',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.white38),
                          const SizedBox(width: 4),
                          Text(
                            user.expiredDate,
                            style: const TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: user.usedPercent,
                          backgroundColor: Colors.white12,
                          color: user.usedPercent > 0.9 ? AppTheme.disconnected : AppTheme.accent,
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Cảnh báo tài khoản không hợp lệ ──
            if (user != null && !user.isActive)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.disconnected.withOpacity(0.12),
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

            // VPN Toggle
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppTheme.card,
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
                      width: 120,
                      height: 120,
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
                  Text(
                    stateLabel,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: stateColor),
                  ),
                  if (vpn.isConnected && vpn.status != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SpeedBadge(
                          icon: Icons.arrow_upward,
                          value: vpn.status!.uploadSpeed.toString(),
                          color: Colors.greenAccent,
                        ),
                        const SizedBox(width: 16),
                        _SpeedBadge(
                          icon: Icons.arrow_downward,
                          value: vpn.status!.downloadSpeed.toString(),
                          color: AppTheme.accent,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Server selector + Update button card
            Card(
              child: Column(
                children: [
                  // Server selector row
                  InkWell(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    onTap: () {
                      if (user != null && !user.isActive) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tài khoản chưa kích hoạt hoặc đã hết hạn'),
                            backgroundColor: AppTheme.disconnected,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ServerListScreen()),
                      );
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
                                  vpn.autoSelect
                                      ? 'Tự động (Tốt nhất)'
                                      : (vpn.selected?.name ?? 'Chọn máy chủ'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (vpn.autoSelect && vpn.selected != null)
                                  Text(
                                    '→ ${vpn.selected!.name}',
                                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.white38),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 1, color: Colors.white12),

                  // Update button row
                  InkWell(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                    onTap: _updating ? null : _onUpdate,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          _updating
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
                                )
                              : const Icon(Icons.sync, color: AppTheme.accent, size: 20),
                          const SizedBox(width: 12),
                          const Text(
                            'Cập nhật VPN',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          const Spacer(),
                          if (vpn.lastUpdated != null)
                            Text(
                              _fmtTime(vpn.lastUpdated!),
                              style: const TextStyle(color: Colors.white38, fontSize: 12),
                            ),
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

  // ─── Tab 1: Tools ───────────────────────────────────────────────────────────

  Widget _buildTools(AuthProvider auth) {
    final user = auth.user;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Thông tin tài khoản'),
          Card(
            child: Column(
              children: [
                if (user.id != null)
                  _InfoRow(label: 'ID', value: '#${user.id}', icon: Icons.badge_outlined),
                if (user.id != null)
                  const Divider(height: 1, color: Colors.white12),
                _InfoRow(
                  label: 'Gói dịch vụ',
                  value: user.planName ?? 'Chưa kích hoạt',
                  icon: Icons.card_membership_outlined,
                  valueColor: user.planName != null ? AppTheme.accent : Colors.white38,
                ),
                const Divider(height: 1, color: Colors.white12),
                _InfoRow(
                  label: 'Hết hạn',
                  value: user.expiredDate,
                  icon: Icons.calendar_today_outlined,
                ),
              ],
            ),
          ),

        ],
      ),
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

// ─── Shared widgets ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
    child: Text(
      text,
      style: const TextStyle(color: AppTheme.accent, fontSize: 13, fontWeight: FontWeight.w600),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.icon, this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon!, color: Colors.white38, size: 18),
          const SizedBox(width: 10),
        ],
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

class _SpeedBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _SpeedBadge({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Text(value, style: TextStyle(color: color, fontSize: 13)),
    ],
  );
}
