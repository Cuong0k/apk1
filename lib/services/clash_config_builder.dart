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
    if (routingMode == 'rules') {
      buf.writeln('  nameserver-policy:');
      buf.writeln('    "geosite:geolocation-cn": [$dns1, $dns2]');
    }
    buf.writeln('');

    // ── Proxies ───────────────────────────────────────────────────────────
    buf.writeln('proxies:');
    for (final s in servers) {
      final entry = _proxyEntry(s, allowInsecure);
      if (entry != null) buf.write(entry);
    }
    buf.writeln('');

    // ── Proxy groups ──────────────────────────────────────────────────────
    final names = servers
        .where((s) => _supportsProtocol(s.protocol))
        .map((s) => _q(s.name))
        .join(', ');

    buf.writeln('proxy-groups:');

    // URL-test (auto-select — Clash picks lowest latency)
    buf.writeln('  - name: "Auto"');
    buf.writeln('    type: url-test');
    buf.writeln('    proxies: [$names]');
    buf.writeln('    url: "http://cp.cloudflare.com/generate_204"');
    buf.writeln('    interval: 300');
    buf.writeln('    tolerance: 50');
    buf.writeln('');

    // Fallback
    buf.writeln('  - name: "Fallback"');
    buf.writeln('    type: fallback');
    buf.writeln('    proxies: [$names]');
    buf.writeln('    url: "http://cp.cloudflare.com/generate_204"');
    buf.writeln('    interval: 120');
    buf.writeln('');

    // Manual select
    buf.writeln('  - name: "Manual"');
    buf.writeln('    type: select');
    buf.writeln('    proxies: [$names]');
    buf.writeln('');

    // Top-level PROXY group — Flutter switches between Auto / Fallback / Manual / individual
    buf.writeln('  - name: "PROXY"');
    buf.writeln('    type: select');
    buf.writeln('    proxies: ["Auto", "Fallback", "Manual", $names, "DIRECT"]');
    buf.writeln('');

    // ── Rules ─────────────────────────────────────────────────────────────
    buf.writeln('rules:');
    if (routingMode == 'direct') {
      buf.writeln('  - MATCH,DIRECT');
    } else if (routingMode == 'global') {
      buf.writeln('  - MATCH,PROXY');
    } else {
      // rules mode: social media → proxy first, then VN bypass
      for (final d in _socialDomains) {
        buf.writeln('  - DOMAIN-SUFFIX,$d,PROXY');
      }
      buf.writeln('  - GEOIP,VN,DIRECT,no-resolve');
      buf.writeln('  - GEOSITE,VN,DIRECT');
      buf.writeln('  - GEOIP,private,DIRECT,no-resolve');
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

  static String _q(String s) => '"${s.replaceAll('"', '\\"')}"';

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
    b.writeln('    password: ${s.uuid}');
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
    b.writeln('    sni: $sni');
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
    b.writeln('    password: ${s.uuid}');
    if (ai || (p['insecure'] == '1')) b.writeln('    skip-cert-verify: true');
    final sni = p['sni'] ?? s.host;
    b.writeln('    sni: $sni');
    if (p['obfs'] != null) {
      b.writeln('    obfs: ${p['obfs']}');
      if (p['obfs-password'] != null) b.writeln('    obfs-password: ${p['obfs-password']}');
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
}
