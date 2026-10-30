/// Model cho bảng app_settings
class AppSettings {
  final int id;
  final double totalBalance;
  final int needRatio;
  final int wantRatio;
  final int saveRatio;
  final String? lastRolloverMonth;

  AppSettings({
    required this.id,
    required this.totalBalance,
    required this.needRatio,
    required this.wantRatio,
    required this.saveRatio,
    this.lastRolloverMonth,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 1,
      totalBalance: (json['total_balance'] as num?)?.toDouble() ?? 0.0,
      needRatio: (json['need_ratio'] as num?)?.toInt() ?? 50,
      wantRatio: (json['want_ratio'] as num?)?.toInt() ?? 30,
      saveRatio: (json['save_ratio'] as num?)?.toInt() ?? 20,
      lastRolloverMonth: json['last_rollover_month'] as String?,
    );
  }

  AppSettings copyWith({
    int? id,
    double? totalBalance,
    int? needRatio,
    int? wantRatio,
    int? saveRatio,
    String? lastRolloverMonth,
  }) {
    return AppSettings(
      id: id ?? this.id,
      totalBalance: totalBalance ?? this.totalBalance,
      needRatio: needRatio ?? this.needRatio,
      wantRatio: wantRatio ?? this.wantRatio,
      saveRatio: saveRatio ?? this.saveRatio,
      lastRolloverMonth: lastRolloverMonth ?? this.lastRolloverMonth,
    );
  }
}

