import 'dart:convert';
import '../models/server.dart';

/// Builds a full xray-core JSON config from a parsed Server object.
class XrayConfigBuilder {
  static String build(Server server, Map<String, dynamic> settings) {
    final config = _baseConfig(settings);
    config['outbounds'] = [
      _buildOutbound(server, settings),
      {'protocol': 'freedom', 'tag': 'direct'},
      {'protocol': 'blackhole', 'tag': 'block'},
    ];
    return jsonEncode(config);
  }

  // ---- Base config ----

  static Map<String, dynamic> _baseConfig(Map<String, dynamic> s) {
    final dns1         = s['dns_primary']   ?? '8.8.8.8';
    final dns2         = s['dns_secondary'] ?? '1.1.1.1';
    final bypassLan    = s['domain_bypass'] ?? true;
    final udp          = s['udp_enabled']   ?? true;
    final ipv6         = s['ipv6_enabled']  ?? true;
    final sniffing     = s['sniffing']      ?? true;
    final logLevel     = s['log_level']     ?? 'error';
    final routingMode  = s['routing_mode']  ?? 'global';

    final bool useFakeDns = routingMode != 'direct';

    final routingRules = <Map<String, dynamic>>[];
    if (routingMode == 'direct') {
      // Trực tiếp: mọi lưu lượng bypass proxy, không qua VPN server
      routingRules.add({'type': 'field', 'network': 'tcp,udp', 'outboundTag': 'direct'});
    } else {
      if (bypassLan || routingMode == 'rules') {
        routingRules.add({'type': 'field', 'ip': ['geoip:private'], 'outboundTag': 'direct'});
      }
      if (routingMode == 'rules') {
        // Mạng xã hội & video: luôn qua proxy, kể cả khi CDN có IP VN.
        // Đặt trước geoip:vn để không bị bypass nhầm.
        routingRules.add({'type': 'field', 'domain': [
          'domain:youtube.com',    'domain:googlevideo.com', 'domain:ytimg.com',
          'domain:facebook.com',   'domain:fbcdn.net',       'domain:fb.com',
          'domain:instagram.com',  'domain:cdninstagram.com',
          'domain:tiktok.com',     'domain:tiktokcdn.com',   'domain:tiktokv.com',
          'domain:ttwstatic.com',  'domain:musical.ly',
          'domain:twitter.com',    'domain:twimg.com',       'domain:x.com',
          'domain:telegram.org',   'domain:t.me',
        ], 'outboundTag': 'proxy'});
        routingRules.add({'type': 'field', 'ip': ['geoip:vn'], 'outboundTag': 'direct'});
        routingRules.add({'type': 'field', 'domain': ['geosite:vn'], 'outboundTag': 'direct'});
      }
    }

    return {
      'log': {'loglevel': logLevel == 'none' ? 'none' : logLevel},
      // FakeDNS chỉ khi không phải Trực tiếp (direct mode dùng DNS thật)
      if (useFakeDns) 'fakedns': [
        {'ipPool': '198.18.0.0/15', 'poolSize': 65535},
      ],
      'dns': {
        // Hardcode IP của DoH servers → tránh circular DNS khi giải địa chỉ DoH server
        'hosts': {
          'cloudflare-dns.com': '1.1.1.1',
          'dns.cloudflare.com': '1.1.1.1',
          'dns.google': '8.8.8.8',
          'dns.google.com': '8.8.8.8',
          'one.one.one.one': '1.1.1.1',
        },
        'servers': useFakeDns
            ? ['fakedns', 'https+local://cloudflare-dns.com/dns-query', dns1, dns2, 'localhost']
            : [dns1, dns2, 'localhost'],
        'queryStrategy': ipv6 ? 'UseIP' : 'UseIPv4',
      },
      'inbounds': [
        {
          'tag': 'socks',
          'port': 10808,
          'listen': '127.0.0.1',
          'protocol': 'socks',
          'settings': {'auth': 'noauth', 'udp': udp, 'userLevel': 8},
          'sniffing': {
            'enabled': sniffing,
            'destOverride': useFakeDns
                ? ['http', 'tls', 'quic', 'fakedns']
                : ['http', 'tls', 'quic'],
            'metadataOnly': false,
          },
        },
        {
          'tag': 'http',
          'port': 10809,
          'listen': '127.0.0.1',
          'protocol': 'http',
          'settings': {'userLevel': 8},
        },
      ],
      'outbounds': [],
      'policy': {
        'levels': {
          '8': {
            'connIdle': 300,
            'downlinkOnly': 1,
            'handshake': 4,
            'uplinkOnly': 1,
          },
        },
        'system': {
          'statsOutboundDownlink': true,
          'statsOutboundUplink': true,
        },
      },
      'stats': {},
      'routing': {
        'domainStrategy': (routingMode == 'global' || routingMode == 'direct') ? 'AsIs' : 'IPIfNonMatch',
        'rules': routingRules,
      },
      'transport': {},
    };
  }

  // ---- Dispatch by protocol ----

  static Map<String, dynamic> _buildOutbound(Server s, Map<String, dynamic> settings) {
    return switch (s.protocol) {
      'vless'  => _vless(s, settings),
      'vmess'  => _vmess(s, settings),
      'trojan' => _trojan(s, settings),
      'ss'     => _shadowsocks(s),
      'tuic'   => _tuic(s, settings),
      'hy2'    => _hysteria2(s, settings),
      'anytls' => _anytls(s, settings),
      _        => {'protocol': 'freedom'},
    };
  }

  // ---- VLESS ----
  // Handles: TCP, WS, gRPC, HTTP/2, QUIC + security: none, tls, reality

  static Map<String, dynamic> _vless(Server s, Map<String, dynamic> settings) {
    final p = s.params;
    final security = p['security'] ?? 'none';
    final network  = p['type'] ?? p['network'] ?? 'tcp';
    final flow     = p['flow'] ?? '';

    return {
      'tag': 'proxy',
      'protocol': 'vless',
      'settings': {
        'vnext': [
          {
            'address': s.host,
            'port': s.port,
            'users': [
              {
                'id': s.uuid,
                'encryption': p['encryption'] ?? 'none',
                if (flow.isNotEmpty) 'flow': flow,
              }
            ],
          }
        ],
      },
      'streamSettings': _streamSettings(s, network, security, p, settings),
    };
  }

  // ---- VMess ----

  static Map<String, dynamic> _vmess(Server s, Map<String, dynamic> settings) {
    final p = s.params;
    final security = p['security'] ?? 'none';
    final network  = p['network'] ?? 'tcp';

    return {
      'tag': 'proxy',
      'protocol': 'vmess',
      'mux': {'enabled': true, 'concurrency': 8},
      'settings': {
        'vnext': [
          {
            'address': s.host,
            'port': s.port,
            'users': [
              {
                'id': s.uuid,
                'alterId': int.tryParse(p['alterId'] ?? '0') ?? 0,
                'security': p['cipher'] ?? 'auto',
              }
            ],
          }
        ],
      },
      'streamSettings': _streamSettings(s, network, security, p, settings),
    };
  }

  // ---- Trojan ----

  static Map<String, dynamic> _trojan(Server s, Map<String, dynamic> settings) {
    final p = s.params;
    final network  = p['type'] ?? p['network'] ?? 'tcp';
    final security = p['security'] ?? 'tls';

    return {
      'tag': 'proxy',
      'protocol': 'trojan',
      'settings': {
        'servers': [
          {
            'address': s.host,
            'port': s.port,
            'password': s.uuid,
          }
        ],
      },
      'streamSettings': _streamSettings(s, network, security, p, settings),
    };
  }

  // ---- Shadowsocks ----

  static Map<String, dynamic> _shadowsocks(Server s) {
    final method   = s.params['method']   ?? 'aes-256-gcm';
    final password = s.params['password'] ?? s.uuid.split(':').lastOrNull ?? s.uuid;

    return {
      'tag': 'proxy',
      'protocol': 'shadowsocks',
      'settings': {
        'servers': [
          {
            'address': s.host,
            'port': s.port,
            'method': method,
            'password': password,
            'uot': true,
          }
        ],
      },
    };
  }

  // ---- TUIC ----

  static Map<String, dynamic> _tuic(Server s, Map<String, dynamic> settings) {
    final p = s.params;
    final allowInsecure = settings['allow_insecure'] == true || p['allowInsecure'] == '1';

    return {
      'tag': 'proxy',
      'protocol': 'tuic',
      'settings': {
        'server': s.host,
        'port': s.port,
        'uuid': s.uuid,
        'password': p['tuic_password'] ?? '',
        'congestionController': p['congestion_control'] ?? 'bbr',
        'udpRelayMode': p['udp_relay_mode'] ?? 'native',
        'zeroRttHandshake': false,
        'heartbeat': '10s',
      },
      'streamSettings': {
        'network': 'tcp',
        'security': 'tls',
        'tlsSettings': {
          'serverName': p['sni'] ?? s.host,
          'allowInsecure': allowInsecure,
          'alpn': (p['alpn'] ?? 'h3').split(','),
        },
      },
    };
  }

  // ---- Hysteria2 ----

  static Map<String, dynamic> _hysteria2(Server s, Map<String, dynamic> settings) {
    final p = s.params;
    final allowInsecure = settings['allow_insecure'] == true || p['insecure'] == '1';

    return {
      'tag': 'proxy',
      'protocol': 'hysteria2',
      'settings': {
        'server': s.host,
        'port': s.port,
        'password': s.uuid,
        if (p['obfs'] != null) 'obfs': {
          'type': p['obfs'],
          'password': p['obfs-password'] ?? '',
        },
      },
      'streamSettings': {
        'network': 'tcp',
        'security': 'tls',
        'tlsSettings': {
          'serverName': p['sni'] ?? s.host,
          'allowInsecure': allowInsecure,
          'alpn': ['h3'],
          'fingerprint': p['fp'] ?? 'chrome',
        },
      },
    };
  }

  // ---- AnyTLS ----

  static Map<String, dynamic> _anytls(Server s, Map<String, dynamic> settings) {
    final p = s.params;
    final allowInsecure = settings['allow_insecure'] == true || p['insecure'] == '1' || p['allowInsecure'] == '1';

    return {
      'tag': 'proxy',
      'protocol': 'anytls',
      'settings': {
        'server': s.host,
        'port': s.port,
        'password': s.uuid,
        if (p['padding_scheme'] != null) 'paddingScheme': p['padding_scheme'],
      },
      'streamSettings': {
        'network': 'tcp',
        'security': 'tls',
        'tlsSettings': {
          'serverName': p['sni'] ?? s.host,
          'allowInsecure': allowInsecure,
          if (p['fp'] != null) 'fingerprint': p['fp'],
          if (p['alpn'] != null) 'alpn': p['alpn']!.split(','),
        },
      },
    };
  }

  // ---- Stream settings (shared by VLESS/VMess/Trojan) ----

  static Map<String, dynamic> _streamSettings(
    Server s,
    String network,
    String security,
    Map<String, String> p,
    Map<String, dynamic> settings,
  ) {
    final allowInsecure = settings['allow_insecure'] == true || p['allowInsecure'] == '1';
    final result = <String, dynamic>{'network': network, 'security': security};

    // TCP optimization — applies to all TCP-based transports
    if (network == 'tcp' || network == 'ws' || network == 'h2' || network == 'http' || network == 'grpc') {
      result['sockopt'] = {
        'tcpFastOpen': true,
        'tcpNoDelay': true,
        'tcpKeepAliveInterval': 15,
        'tcpKeepAliveIdle': 30,
      };
    }

    // TLS
    if (security == 'tls') {
      result['tlsSettings'] = {
        'serverName': p['sni'] ?? p['host'] ?? s.host,
        'allowInsecure': allowInsecure,
        if (p['fp'] != null) 'fingerprint': p['fp'],
        if (p['alpn'] != null) 'alpn': p['alpn']!.split(','),
      };
    }

    // Reality
    if (security == 'reality') {
      result['realitySettings'] = {
        'serverName': p['sni'] ?? s.host,
        'fingerprint': p['fp'] ?? 'chrome',
        'publicKey': p['pbk'] ?? '',
        'shortId': p['sid'] ?? '',
        'spiderX': p['spx'] ?? '',
      };
    }

    // Network-specific settings
    switch (network) {
      case 'ws':
        result['wsSettings'] = {
          'path': p['path'] ?? '/',
          'headers': {
            if (p['host'] != null) 'Host': p['host'],
          },
        };
        break;

      case 'grpc':
        result['grpcSettings'] = {
          'serviceName': p['serviceName'] ?? p['mode'] ?? 'GunService',
          'multiMode': p['mode'] == 'multi',
        };
        break;

      case 'h2':
      case 'http':
        result['httpSettings'] = {
          'path': p['path'] ?? '/',
          'host': [p['host'] ?? s.host],
          'method': 'PUT',
        };
        break;

      case 'quic':
        result['quicSettings'] = {
          'security': p['quicSecurity'] ?? 'none',
          'key': p['key'] ?? '',
          'header': {'type': p['headerType'] ?? 'none'},
        };
        break;

      case 'tcp':
        if (p['headerType'] == 'http') {
          result['tcpSettings'] = {
            'header': {
              'type': 'http',
              'request': {
                'path': [p['path'] ?? '/'],
                'headers': {
                  'Host': [p['host'] ?? s.host],
                },
              },
            },
          };
        }
        break;
    }

    return result;
  }
}
