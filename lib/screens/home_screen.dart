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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final vpn = context.watch<VpnProvider>();
    final user = auth.user;

    final stateColor = vpn.isConnected ? AppTheme.connected : AppTheme.disconnected;
    final stateLabel = switch (vpn.state) {
      VpnState.connected => 'Đã kết nối',
      VpnState.connecting => 'Đang kết nối...',
      VpnState.disconnected => 'Chưa kết nối',
    };

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
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
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
                      onTap: vpn.state == VpnState.connecting ? null : vpn.toggleVpn,
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
                            : Icon(
                                Icons.power_settings_new_rounded,
                                size: 56,
                                color: stateColor,
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      stateLabel,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: stateColor,
                      ),
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

              // Server selector
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ServerListScreen()),
                ),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.dns_outlined, color: AppTheme.accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            vpn.selected?.name ?? 'Chọn máy chủ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white38),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Cập nhật VPN
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.sync, size: 16, color: AppTheme.accent),
                  label: const Text('Cập nhật VPN', style: TextStyle(color: AppTheme.accent)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.accent, width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () async {
                    final wasConnected = vpn.isConnected;
                    if (wasConnected) await vpn.disconnect();
                    await _load();
                    if (wasConnected && vpn.servers.isNotEmpty) await vpn.connect();
                  },
                ),
              ),

              const SizedBox(height: 16),

              // User info
              if (user != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow(label: 'Tài khoản', value: user.email),
                        const Divider(color: Colors.white12, height: 20),
                        _InfoRow(label: 'Gói dịch vụ', value: user.planName ?? 'Chưa kích hoạt'),
                        const Divider(color: Colors.white12, height: 20),
                        _InfoRow(label: 'Hết hạn', value: user.expiredDate),
                        const Divider(color: Colors.white12, height: 20),
                        _InfoRow(
                          label: 'Dữ liệu',
                          value: '${user.usedGB.toStringAsFixed(2)} / ${user.totalGB.toStringAsFixed(2)} GB',
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: user.usedPercent,
                            backgroundColor: Colors.white12,
                            color: user.usedPercent > 0.9
                                ? AppTheme.disconnected
                                : AppTheme.accent,
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _SpeedBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _SpeedBadge({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(color: color, fontSize: 13)),
      ],
    );
  }
}
