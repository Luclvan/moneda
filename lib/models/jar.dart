/// Model cho bảng jars (NEED, WANT, SAVE)
class Jar {
  final String jarType;
  final double balance;
  final DateTime? updatedAt;

  Jar({
    required this.jarType,
    required this.balance,
    this.updatedAt,
  });

  factory Jar.fromJson(Map<String, dynamic> json) {
    return Jar(
      jarType: (json['jar_type'] as String? ?? 'NEED').toUpperCase(),
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Jar copyWith({
    String? jarType,
    double? balance,
    DateTime? updatedAt,
  }) {
    return Jar(
      jarType: jarType ?? this.jarType,
      balance: balance ?? this.balance,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayName {
    switch (jarType) {
      case 'NEED':
        return 'Need';
      case 'WANT':
        return 'Want';
      case 'SAVE':
        return 'Save';
      default:
        return jarType;
    }
  }

  String get subtitle {
    switch (jarType) {
      case 'NEED':
        return 'Thiết yếu';
      case 'WANT':
        return 'Mong muốn';
      case 'SAVE':
        return 'Tiết kiệm';
      default:
        return '';
    }
  }
}

