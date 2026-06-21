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
  final Set<String> _pinging = {};

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final vpn = context.read<VpnProvider>();
    if (auth.user != null) {
      await vpn.loadServers(auth.user!.token);
    }
    setState(() => _loading = false);
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
              itemCount: vpn.servers.length,
              itemBuilder: (context, index) {
                final server = vpn.servers[index];
                final isSelected = vpn.selected?.rawUri == server.rawUri;
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _protocolColor(server.protocol).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          server.protocol.toUpperCase().substring(0, 2),
                          style: TextStyle(
                            color: _protocolColor(server.protocol),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      server.name,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${server.host}:${server.port}',
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    trailing: GestureDetector(
                      onTap: isPinging ? null : () => _ping(server),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _pingColor(server.ping).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: isPinging
                            ? const SizedBox(
                                width: 14,
                                height: 14,
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

  Color _pingColor(int ping) {
    if (ping == -1) return Colors.white38;
    if (ping < 100) return AppTheme.connected;
    if (ping < 250) return Colors.orange;
    return AppTheme.disconnected;
  }

  Color _protocolColor(String protocol) {
    return switch (protocol) {
      'vless' => AppTheme.accent,
      'vmess' => Colors.purple,
      'trojan' => Colors.orange,
      'ss' => Colors.green,
      _ => Colors.white38,
    };
  }
}
