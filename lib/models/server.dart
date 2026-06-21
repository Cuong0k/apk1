import 'dart:convert';

class Server {
  final String name;
  final String host;
  final int port;
  final String uuid;
  final String protocol;
  final String rawUri;
  final Map<String, String> params;
  int ping;

  Server({
    required this.name,
    required this.host,
    required this.port,
    required this.uuid,
    required this.protocol,
    required this.rawUri,
    this.params = const {},
    this.ping = -1,
  });

  static List<Server> parseSubscription(String content) {
    final List<Server> servers = [];
    try {
      String decoded;
      try {
        decoded = utf8.decode(base64.decode(base64.normalize(
          content.replaceAll('\n', '').replaceAll('\r', ''),
        )));
      } catch (_) {
        decoded = content;
      }
      for (final line in decoded.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        final server = _parseUri(trimmed);
        if (server != null) servers.add(server);
      }
    } catch (_) {}
    return servers;
  }

  static Server? _parseUri(String uri) {
    try {
      if (uri.startsWith('vless://'))     return _parseVless(uri);
      if (uri.startsWith('vmess://'))     return _parseVmess(uri);
      if (uri.startsWith('trojan://'))    return _parseTrojan(uri);
      if (uri.startsWith('ss://'))        return _parseSS(uri);
      if (uri.startsWith('tuic://'))      return _parseTuic(uri);
      if (uri.startsWith('hy2://') || uri.startsWith('hysteria2://')) return _parseHy2(uri);
      if (uri.startsWith('anytls://'))    return _parseAnyTLS(uri);
    } catch (_) {}
    return null;
  }

  // VLESS: vless://UUID@HOST:PORT?type=tcp&security=reality&...#NAME
  static Server? _parseVless(String uri) {
    final u = Uri.tryParse(uri.replaceFirst('vless://', 'https://'));
    if (u == null) return null;
    final params = Map<String, String>.from(u.queryParameters);
    return Server(
      name: Uri.decodeComponent(u.fragment.isNotEmpty ? u.fragment : 'VLESS'),
      host: u.host,
      port: u.port,
      uuid: Uri.decodeComponent(u.userInfo),
      protocol: 'vless',
      rawUri: uri,
      params: params,
    );
  }

  // VMess: vmess://BASE64_JSON
  static Server? _parseVmess(String uri) {
    try {
      final raw = uri.replaceFirst('vmess://', '');
      final json = jsonDecode(utf8.decode(base64.decode(base64.normalize(raw)))) as Map<String, dynamic>;
      final params = <String, String>{
        'network': json['net']?.toString() ?? 'tcp',
        'security': json['tls']?.toString() == 'tls' ? 'tls' : 'none',
        'sni': json['sni']?.toString() ?? json['host']?.toString() ?? '',
        'path': json['path']?.toString() ?? '/',
        'host': json['host']?.toString() ?? '',
        'alterId': json['aid']?.toString() ?? '0',
        'cipher': json['scy']?.toString() ?? 'auto',
        if (json['alpn'] != null) 'alpn': json['alpn'].toString(),
        if (json['serviceName'] != null) 'serviceName': json['serviceName'].toString(),
      };
      return Server(
        name: json['ps']?.toString() ?? 'VMess',
        host: json['add']?.toString() ?? '',
        port: int.tryParse(json['port'].toString()) ?? 443,
        uuid: json['id']?.toString() ?? '',
        protocol: 'vmess',
        rawUri: uri,
        params: params,
      );
    } catch (_) {
      return null;
    }
  }

  // Trojan: trojan://PASSWORD@HOST:PORT?sni=SNI#NAME
  static Server? _parseTrojan(String uri) {
    final u = Uri.tryParse(uri.replaceFirst('trojan://', 'https://'));
    if (u == null) return null;
    return Server(
      name: Uri.decodeComponent(u.fragment.isNotEmpty ? u.fragment : 'Trojan'),
      host: u.host,
      port: u.port,
      uuid: Uri.decodeComponent(u.userInfo),
      protocol: 'trojan',
      rawUri: uri,
      params: Map<String, String>.from(u.queryParameters),
    );
  }

  // Shadowsocks: ss://BASE64(method:pass)@HOST:PORT#NAME  or  ss://BASE64#NAME
  static Server? _parseSS(String uri) {
    try {
      final withoutScheme = uri.replaceFirst('ss://', '');
      final hashIdx = withoutScheme.indexOf('#');
      final name = hashIdx >= 0
          ? Uri.decodeComponent(withoutScheme.substring(hashIdx + 1))
          : 'Shadowsocks';
      final body = hashIdx >= 0 ? withoutScheme.substring(0, hashIdx) : withoutScheme;

      String method = 'aes-128-gcm';
      String password = '';
      String host = '';
      int port = 443;

      if (body.contains('@')) {
        final atIdx = body.lastIndexOf('@');
        final userPart = body.substring(0, atIdx);
        final hostPart = body.substring(atIdx + 1);

        final hostPort = hostPart.split(':');
        host = hostPort[0];
        port = int.tryParse(hostPort.length > 1 ? hostPort[1] : '443') ?? 443;

        String decoded;
        try {
          decoded = utf8.decode(base64.decode(base64.normalize(userPart)));
        } catch (_) {
          decoded = Uri.decodeComponent(userPart);
        }
        final colonIdx = decoded.indexOf(':');
        if (colonIdx >= 0) {
          method = decoded.substring(0, colonIdx);
          password = decoded.substring(colonIdx + 1);
        }
      } else {
        final decoded = utf8.decode(base64.decode(base64.normalize(body)));
        final colonIdx = decoded.indexOf(':');
        final atIdx = decoded.lastIndexOf('@');
        if (atIdx >= 0) {
          final userPart = decoded.substring(0, atIdx);
          final hostPart = decoded.substring(atIdx + 1);
          final methodColon = userPart.indexOf(':');
          method = methodColon >= 0 ? userPart.substring(0, methodColon) : userPart;
          password = methodColon >= 0 ? userPart.substring(methodColon + 1) : '';
          final hp = hostPart.split(':');
          host = hp[0];
          port = int.tryParse(hp.length > 1 ? hp[1] : '443') ?? 443;
        }
      }

      return Server(
        name: name,
        host: host,
        port: port,
        uuid: '$method:$password',
        protocol: 'ss',
        rawUri: uri,
        params: {'method': method, 'password': password},
      );
    } catch (_) {
      return null;
    }
  }

  // TUIC: tuic://UUID:PASSWORD@HOST:PORT?sni=SNI&...#NAME
  static Server? _parseTuic(String uri) {
    final u = Uri.tryParse(uri.replaceFirst('tuic://', 'https://'));
    if (u == null) return null;
    final userInfo = u.userInfo.split(':');
    final params = Map<String, String>.from(u.queryParameters);
    params['tuic_password'] = userInfo.length > 1 ? userInfo.sublist(1).join(':') : '';
    return Server(
      name: Uri.decodeComponent(u.fragment.isNotEmpty ? u.fragment : 'TUIC'),
      host: u.host,
      port: u.port,
      uuid: userInfo[0],
      protocol: 'tuic',
      rawUri: uri,
      params: params,
    );
  }

  // Hysteria2: hy2://PASSWORD@HOST:PORT?sni=SNI#NAME
  static Server? _parseHy2(String uri) {
    final cleaned = uri.replaceFirst('hysteria2://', 'https://').replaceFirst('hy2://', 'https://');
    final u = Uri.tryParse(cleaned);
    if (u == null) return null;
    return Server(
      name: Uri.decodeComponent(u.fragment.isNotEmpty ? u.fragment : 'Hysteria2'),
      host: u.host,
      port: u.port,
      uuid: Uri.decodeComponent(u.userInfo),
      protocol: 'hy2',
      rawUri: uri,
      params: Map<String, String>.from(u.queryParameters),
    );
  }

  // AnyTLS: anytls://PASSWORD@HOST:PORT?sni=SNI&...#NAME
  static Server? _parseAnyTLS(String uri) {
    final u = Uri.tryParse(uri.replaceFirst('anytls://', 'https://'));
    if (u == null) return null;
    return Server(
      name: Uri.decodeComponent(u.fragment.isNotEmpty ? u.fragment : 'AnyTLS'),
      host: u.host,
      port: u.port,
      uuid: Uri.decodeComponent(u.userInfo),
      protocol: 'anytls',
      rawUri: uri,
      params: Map<String, String>.from(u.queryParameters),
    );
  }
}
