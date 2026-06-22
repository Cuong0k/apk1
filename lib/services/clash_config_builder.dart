import '../models/server.dart';

/// Builds a Clash Meta YAML config from a list of servers.
/// Uses external-controller on 127.0.0.1:9091 for REST-based proxy switching.
class ClashConfigBuilder {
  static const _controllerPort = 9091;

  static String build(
    List<Server> servers,
    Map<String, dynamic> settings,
    String routingMode,
  ) {
    final dns1 = settings['dns_primary']   ?? '1.1.1.1';
    final dns2 = settings['dns_secondary'] ?? '8.8.8.8';
    final allowInsecure = settings['allow_insecure'] == true;

    // Deduplicate server names — Clash Meta panics on duplicate proxy names
    final seen = <String>{};
    final uniqueServers = servers.where((s) {
      if (seen.contains(s.name)) return false;
      seen.add(s.name);
      return true;
    }).toList();

    final buf = StringBuffer();

    // ── Global ────────────────────────────────────────────────────────────
    buf.writeln('mixed-port: 7890');
    buf.writeln('allow-lan: false');
    buf.writeln('mode: ${_clashMode(routingMode)}');
    buf.writeln('log-level: warning');
    buf.writeln('external-controller: 127.0.0.1:$_controllerPort');
    buf.writeln('secret: ""');
    buf.writeln('');

    // ── DNS ───────────────────────────────────────────────────────────────
    buf.writeln('dns:');
    buf.writeln('  enable: true');
    if (routingMode != 'direct') {
      buf.writeln('  enhanced-mode: fake-ip');
      buf.writeln('  fake-ip-range: 198.18.0.1/16');
      buf.writeln('  fake-ip-filter:');
      buf.writeln('    - "*.lan"');
      buf.writeln('    - localhost.ptlogin2.qq.com');
    } else {
      buf.writeln('  enhanced-mode: normal');
    }
    buf.writeln('  nameserver:');
    buf.writeln('    - $dns1');
    buf.writeln('    - $dns2');
    buf.writeln('');

    // ── Proxies ───────────────────────────────────────────────────────────
    buf.writeln('proxies:');
    for (final s in uniqueServers) {
      final entry = _proxyEntry(s, allowInsecure);
      if (entry != null) buf.write(entry);
    }
    buf.writeln('');

    // ── Proxy groups ──────────────────────────────────────────────────────
    final names = uniqueServers
        .where((s) => _supportsProtocol(s.protocol))
        .map((s) => _q(s.name))
        .join(', ');

    // Clash Meta panics if url-test / fallback groups have an empty proxies list.
    // When there are no supported servers, use DIRECT as the only member so the
    // groups are always valid (they'll just pass traffic through directly).
    final safeNames = names.isEmpty ? '"DIRECT"' : names;

    buf.writeln('proxy-groups:');

    // URL-test (auto-select — Clash picks lowest latency)
    buf.writeln('  - name: "Auto"');
    buf.writeln('    type: url-test');
    buf.writeln('    proxies: [$safeNames]');
    buf.writeln('    url: "http://cp.cloudflare.com/generate_204"');
    buf.writeln('    interval: 300');
    buf.writeln('    tolerance: 50');
    buf.writeln('');

    // Fallback
    buf.writeln('  - name: "Fallback"');
    buf.writeln('    type: fallback');
    buf.writeln('    proxies: [$safeNames]');
    buf.writeln('    url: "http://cp.cloudflare.com/generate_204"');
    buf.writeln('    interval: 120');
    buf.writeln('');

    // Manual select
    buf.writeln('  - name: "Manual"');
    buf.writeln('    type: select');
    buf.writeln('    proxies: [$safeNames]');
    buf.writeln('');

    // Top-level PROXY group — Flutter switches between Auto / Fallback / Manual / individual
    final proxyList = names.isEmpty ? '"Auto", "Fallback", "Manual", "DIRECT"'
        : '"Auto", "Fallback", "Manual", $names, "DIRECT"';
    buf.writeln('  - name: "PROXY"');
    buf.writeln('    type: select');
    buf.writeln('    proxies: [$proxyList]');
    buf.writeln('');

    // ── Rules ─────────────────────────────────────────────────────────────
    buf.writeln('rules:');
    if (routingMode == 'direct') {
      buf.writeln('  - MATCH,DIRECT');
    } else if (routingMode == 'global') {
      buf.writeln('  - MATCH,PROXY');
    } else {
      // rules mode: social media → proxy, private networks + VN CIDRs → direct
      // Avoid GEOIP/GEOSITE rules — they require geoip.dat/geosite.dat database
      // files that are not bundled with the app and would crash Clash on startup.
      for (final d in _socialDomains) {
        buf.writeln('  - DOMAIN-SUFFIX,$d,PROXY');
      }
      // Private & LAN networks
      buf.writeln('  - IP-CIDR,192.168.0.0/16,DIRECT');
      buf.writeln('  - IP-CIDR,10.0.0.0/8,DIRECT');
      buf.writeln('  - IP-CIDR,172.16.0.0/12,DIRECT');
      buf.writeln('  - IP-CIDR,127.0.0.0/8,DIRECT');
      // Common Vietnamese ISP CIDRs (no geo database needed)
      for (final cidr in _vnCidrs) {
        buf.writeln('  - IP-CIDR,$cidr,DIRECT');
      }
      buf.writeln('  - MATCH,PROXY');
    }

    return buf.toString();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String _clashMode(String mode) => switch (mode) {
        'direct' => 'direct',
        'rules'  => 'rule',
        _        => 'global',
      };

  static bool _supportsProtocol(String p) =>
      const {'vless', 'vmess', 'trojan', 'ss', 'tuic', 'hy2'}.contains(p);

  // Quote a YAML string value — escapes backslash and double-quote characters.
  static String _q(String s) => '"${s.replaceAll('\\', '\\\\').replaceAll('"', '\\"')}"';

  // Returns YAML block for one proxy, or null if unsupported.
  static String? _proxyEntry(Server s, bool allowInsecure) {
    if (!_supportsProtocol(s.protocol)) return null;
    return switch (s.protocol) {
      'vless'  => _vless(s, allowInsecure),
      'vmess'  => _vmess(s, allowInsecure),
      'trojan' => _trojan(s, allowInsecure),
      'ss'     => _ss(s),
      'tuic'   => _tuic(s, allowInsecure),
      'hy2'    => _hy2(s, allowInsecure),
      _        => null,
    };
  }

  // ── VLESS ─────────────────────────────────────────────────────────────
  static String _vless(Server s, bool ai) {
    final p = s.params;
    final net  = p['type'] ?? p['network'] ?? 'tcp';
    final sec  = p['security'] ?? 'none';
    final flow = p['flow'] ?? '';
    final b = StringBuffer();
    b.writeln('  - name: ${_q(s.name)}');
    b.writeln('    type: vless');
    b.writeln('    server: ${s.host}');
    b.writeln('    port: ${s.port}');
    b.writeln('    uuid: ${s.uuid}');
    b.writeln('    network: $net');
    if (flow.isNotEmpty) b.writeln('    flow: $flow');
    if (sec == 'tls' || sec == 'reality') {
      b.writeln('    tls: true');
      if (ai || (p['allowInsecure'] == '1')) b.writeln('    skip-cert-verify: true');
      final sni = p['sni'] ?? p['host'] ?? s.host;
      if (sni.isNotEmpty) b.writeln('    servername: $sni');
      if (p['fp'] != null) b.writeln('    client-fingerprint: ${p['fp']}');
    }
    if (sec == 'reality') {
      b.writeln('    reality-opts:');
      b.writeln('      public-key: ${p['pbk'] ?? ''}');
      if (p['sid'] != null) b.writeln('      short-id: ${p['sid']}');
    }
    _appendNetworkOpts(b, net, p, s);
    return b.toString();
  }

  // ── VMess ─────────────────────────────────────────────────────────────
  static String _vmess(Server s, bool ai) {
    final p = s.params;
    final net = p['network'] ?? 'tcp';
    final sec = p['security'] ?? 'none';
    final b = StringBuffer();
    b.writeln('  - name: ${_q(s.name)}');
    b.writeln('    type: vmess');
    b.writeln('    server: ${s.host}');
    b.writeln('    port: ${s.port}');
    b.writeln('    uuid: ${s.uuid}');
    b.writeln('    alterId: ${int.tryParse(p['alterId'] ?? '0') ?? 0}');
    b.writeln('    cipher: ${p['cipher'] ?? 'auto'}');
    b.writeln('    network: $net');
    if (sec == 'tls') {
      b.writeln('    tls: true');
      if (ai || (p['allowInsecure'] == '1')) b.writeln('    skip-cert-verify: true');
      final sni = p['sni'] ?? p['host'] ?? s.host;
      if (sni.isNotEmpty) b.writeln('    servername: $sni');
    }
    _appendNetworkOpts(b, net, p, s);
    return b.toString();
  }

  // ── Trojan ────────────────────────────────────────────────────────────
  static String _trojan(Server s, bool ai) {
    final p = s.params;
    final net = p['type'] ?? p['network'] ?? 'tcp';
    final b = StringBuffer();
    b.writeln('  - name: ${_q(s.name)}');
    b.writeln('    type: trojan');
    b.writeln('    server: ${s.host}');
    b.writeln('    port: ${s.port}');
    b.writeln('    password: ${_q(s.uuid)}');
    b.writeln('    network: $net');
    if (ai || (p['allowInsecure'] == '1')) b.writeln('    skip-cert-verify: true');
    final sni = p['sni'] ?? p['host'] ?? s.host;
    if (sni.isNotEmpty) b.writeln('    sni: $sni');
    _appendNetworkOpts(b, net, p, s);
    return b.toString();
  }

  // ── Shadowsocks ───────────────────────────────────────────────────────
  static String _ss(Server s) {
    final p = s.params;
    final password = p['password'] ?? s.uuid.split(':').lastOrNull ?? s.uuid;
    final b = StringBuffer();
    b.writeln('  - name: ${_q(s.name)}');
    b.writeln('    type: ss');
    b.writeln('    server: ${s.host}');
    b.writeln('    port: ${s.port}');
    b.writeln('    cipher: ${p['method'] ?? 'aes-256-gcm'}');
    b.writeln('    password: "$password"');
    return b.toString();
  }

  // ── TUIC v5 ──────────────────────────────────────────────────────────
  static String _tuic(Server s, bool ai) {
    final p = s.params;
    final b = StringBuffer();
    b.writeln('  - name: ${_q(s.name)}');
    b.writeln('    type: tuic');
    b.writeln('    server: ${s.host}');
    b.writeln('    port: ${s.port}');
    b.writeln('    uuid: ${s.uuid}');
    b.writeln('    password: "${p['tuic_password'] ?? ''}"');
    b.writeln('    congestion-controller: ${p['congestion_control'] ?? 'bbr'}');
    b.writeln('    udp-relay-mode: ${p['udp_relay_mode'] ?? 'native'}');
    b.writeln('    alpn: [${(p['alpn'] ?? 'h3').split(',').map((a) => '"$a"').join(', ')}]');
    if (ai || (p['allowInsecure'] == '1')) b.writeln('    skip-cert-verify: true');
    final sni = p['sni'] ?? s.host;
    b.writeln('    sni: ${_q(sni)}');
    return b.toString();
  }

  // ── Hysteria2 ─────────────────────────────────────────────────────────
  static String _hy2(Server s, bool ai) {
    final p = s.params;
    final b = StringBuffer();
    b.writeln('  - name: ${_q(s.name)}');
    b.writeln('    type: hysteria2');
    b.writeln('    server: ${s.host}');
    b.writeln('    port: ${s.port}');
    b.writeln('    password: ${_q(s.uuid)}');
    if (ai || (p['insecure'] == '1')) b.writeln('    skip-cert-verify: true');
    final sni = p['sni'] ?? s.host;
    b.writeln('    sni: ${_q(sni)}');
    if (p['obfs'] != null) {
      b.writeln('    obfs: ${p['obfs']}');
      if (p['obfs-password'] != null) b.writeln('    obfs-password: ${_q(p['obfs-password']!)}');
    }
    return b.toString();
  }

  // ── Network transport options (WS / gRPC / HTTP/2) ───────────────────
  static void _appendNetworkOpts(StringBuffer b, String net, Map<String, String> p, Server s) {
    switch (net) {
      case 'ws':
        b.writeln('    ws-opts:');
        b.writeln('      path: "${p['path'] ?? '/'}"');
        final host = p['host'];
        if (host != null && host.isNotEmpty) {
          b.writeln('      headers:');
          b.writeln('        Host: $host');
        }
        break;
      case 'grpc':
        b.writeln('    grpc-opts:');
        b.writeln('      grpc-service-name: "${p['serviceName'] ?? 'GunService'}"');
        break;
      case 'h2':
      case 'http':
        b.writeln('    h2-opts:');
        b.writeln('      path: "${p['path'] ?? '/'}"');
        final h2host = p['host'];
        if (h2host != null) b.writeln('      host: [$h2host]');
        break;
    }
  }

  // Social media domains that should always go through proxy in rules mode
  static const _socialDomains = [
    'youtube.com', 'googlevideo.com', 'ytimg.com', 'yt3.ggpht.com',
    'facebook.com', 'fbcdn.net', 'fb.com',
    'instagram.com', 'cdninstagram.com',
    'tiktok.com', 'tiktokcdn.com', 'tiktokv.com', 'ttwstatic.com', 'musical.ly',
    'twitter.com', 'twimg.com', 'x.com',
    'telegram.org', 't.me',
  ];

  // Major Vietnamese ISP IP ranges — replaces GEOIP,VN rule to avoid needing geoip.dat
  static const _vnCidrs = [
    // Viettel
    '14.160.0.0/11', '14.224.0.0/11', '27.64.0.0/11', '42.112.0.0/13',
    '58.186.0.0/15', '113.160.0.0/11', '116.96.0.0/11', '123.16.0.0/13',
    '125.232.0.0/13', '171.224.0.0/12', '203.210.128.0/19',
    // VNPT
    '113.172.0.0/14', '118.68.0.0/14', '118.70.0.0/15', '123.24.0.0/14',
    '125.212.0.0/15', '203.162.0.0/19',
    // FPT Telecom
    '27.72.0.0/13', '103.7.56.0/22', '117.0.0.0/11',
    // CMC / other VN
    '103.1.208.0/21', '103.9.76.0/22',
  ];
}
