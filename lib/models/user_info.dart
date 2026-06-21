class UserInfo {
  final int? id;
  final String email;
  final int transferEnable;
  final int upload;
  final int download;
  final int? expiredAt;
  final String token;
  final String authData;
  final String? planName;

  UserInfo({
    this.id,
    required this.email,
    required this.transferEnable,
    required this.upload,
    required this.download,
    this.expiredAt,
    required this.token,
    required this.authData,
    this.planName,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: (json['id'] as num?)?.toInt(),
      email: json['email']?.toString() ?? '',
      transferEnable: (json['transfer_enable'] as num?)?.toInt() ?? 0,
      upload: (json['u'] as num?)?.toInt() ?? 0,
      download: (json['d'] as num?)?.toInt() ?? 0,
      expiredAt: (json['expired_at'] as num?)?.toInt(),
      token: json['token']?.toString() ?? '',
      authData: json['auth_data']?.toString() ?? json['token']?.toString() ?? '',
      planName: json['plan']?['name']?.toString() ??
                (json['plan_id'] != null && json['plan_id'] != 0 ? 'Gói VIP' : null),
    );
  }

  bool get isActive {
    if (planName == null) return false;
    if (expiredAt == null) return true; // Vĩnh viễn
    return expiredAt! > DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  double get usedGB => (upload + download) / 1073741824;
  double get totalGB => transferEnable / 1073741824;
  double get usedPercent => totalGB > 0 ? (usedGB / totalGB).clamp(0.0, 1.0) : 0;

  String get expiredDate {
    if (expiredAt == null) return 'Vĩnh viễn';
    final dt = DateTime.fromMillisecondsSinceEpoch(expiredAt! * 1000);
    return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
  }
}
