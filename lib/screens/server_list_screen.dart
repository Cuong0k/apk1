import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/vpn_provider.dart';
import '../models/server.dart';
import '../theme/app_theme.dart';

class ServerListScreen extends StatefulWidget {
  const ServerListScreen({super.key});

  @override
  State<ServerListScreen> createState() => _ServerListScreenState();
}

class _ServerListScreenState extends State<ServerListScreen> {
  bool _loading = false;
  bool _pingingAll = false;
  final Set<String> _pinging = {};

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final vpn = context.read<VpnProvider>();
    if (auth.user != null) {
      await vpn.loadServers(auth.user!.token, authData: auth.user!.authData);
    }
    setState(() => _loading = false);
  }

  Future<void> _pingAll() async {
    setState(() => _pingingAll = true);
    final vpn = context.read<VpnProvider>();
    for (final server in vpn.servers) {
      setState(() => _pinging.add(server.rawUri));
      await vpn.pingServer(server);
      setState(() => _pinging.remove(server.rawUri));
    }
    setState(() => _pingingAll = false);
  }

  Future<void> _ping(Server server) async {
    setState(() => _pinging.add(server.rawUri));
    await context.read<VpnProvider>().pingServer(server);
    setState(() => _pinging.remove(server.rawUri));
  }

  @override
  Widget build(BuildContext context) {
    final vpn = context.watch<VpnProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách máy chủ'),
        actions: [
          if (_pingingAll)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.network_ping, color: AppTheme.accent),
              tooltip: 'Ping tất cả',
              onPressed: vpn.servers.isEmpty ? null : _pingAll,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _refresh,
          ),
        ],
      ),
      body: vpn.servers.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.dns_outlined, size: 48, color: Colors.white24),
                  const SizedBox(height: 12),
                  const Text('Chưa có máy chủ', style: TextStyle(color: Colors.white54)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _refresh, child: const Text('Tải lại')),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              // +1 for the Auto option at index 0
              itemCount: vpn.servers.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _buildAutoCard(vpn);

                final server = vpn.servers[index - 1];
                final isSelected = !vpn.autoSelect && vpn.selected?.rawUri == server.rawUri;
                final isPinging = _pinging.contains(server.rawUri);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isSelected
                        ? const BorderSide(color: AppTheme.accent, width: 1.5)
                        : BorderSide.none,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: _ProtocolBadge(protocol: server.protocol),
                    title: Text(
                      server.name,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: GestureDetector(
                      onTap: (isPinging || _pingingAll) ? null : () => _ping(server),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _pingColor(server.ping).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: isPinging
                            ? const SizedBox(
                                width: 14, height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                server.ping == -1 ? 'Ping' : '${server.ping}ms',
                                style: TextStyle(
                                  color: _pingColor(server.ping),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    onTap: () {
                      vpn.selectServer(server);
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildAutoCard(VpnProvider vpn) {
    final isActive = vpn.autoSelect;
    return Card(
      margin: const EdgeInsets.only(bottom: 4, top: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive
            ? const BorderSide(color: AppTheme.accent, width: 1.5)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppTheme.accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.auto_awesome, color: AppTheme.accent, size: 20),
        ),
        title: const Text(
          'Tự động',
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          isActive && vpn.selected != null
              ? '→ ${vpn.selected!.name}'
              : 'Chọn máy chủ tốt nhất',
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        trailing: isActive
            ? const Icon(Icons.check_circle, color: AppTheme.accent)
            : const Icon(Icons.chevron_right, color: Colors.white24),
        onTap: () {
          vpn.setAutoSelect();
          Navigator.pop(context);
        },
      ),
    );
  }

  Color _pingColor(int ping) {
    if (ping == -1) return Colors.white38;
    if (ping < 100) return AppTheme.connected;
    if (ping < 300) return Colors.orange;
    return AppTheme.disconnected;
  }
}

class _ProtocolBadge extends StatelessWidget {
  final String protocol;
  const _ProtocolBadge({required this.protocol});

  @override
  Widget build(BuildContext context) {
    final color = switch (protocol) {
      'vless'  => AppTheme.accent,
      'vmess'  => Colors.purple,
      'trojan' => Colors.orange,
      'ss'     => Colors.green,
      'tuic'   => Colors.blue,
      'hy2'    => Colors.pink,
      'anytls' => Colors.teal,
      _        => Colors.white38,
    };
    final label = protocol.length >= 2 ? protocol.toUpperCase().substring(0, 2) : protocol.toUpperCase();
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
