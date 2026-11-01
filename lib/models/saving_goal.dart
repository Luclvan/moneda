import 'package:intl/intl.dart';

/// Đại diện cho một mục tiêu tiết kiệm trong bảng saving_goals
class SavingGoal {
  final int id;
  final String goalName;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final DateTime createdAt;

  SavingGoal({
    required this.id,
    required this.goalName,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.deadline,
    required this.createdAt,
  });

  factory SavingGoal.fromJson(Map<String, dynamic> json) {
    final deadlineRaw = json['deadline'];
    final createdAtRaw = json['created_at'];

    return SavingGoal(
      id: json['id'] as int,
      goalName: json['goal_name'] as String? ?? 'Mục tiêu',
      targetAmount: (json['target_amount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0.0,
      deadline: deadlineRaw != null
          ? DateTime.tryParse(deadlineRaw.toString())?.toLocal()
          : null,
      createdAt: createdAtRaw != null
          ? DateTime.tryParse(createdAtRaw.toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goal_name': goalName,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'deadline': deadline?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Tỷ lệ hoàn thành mục tiêu (0.0 đến 1.0)
  double get progress {
    if (targetAmount <= 0) return 0.0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  /// Phần trăm hoàn thành làm tròn nguyên (VD: 17%, 100%)
  int get progressPercent => (progress * 100).round();

  /// Định dạng hạn chót dd/MM/yyyy
  String? get formattedDeadline {
    if (deadline == null) return null;
    return DateFormat('dd/MM/yyyy').format(deadline!);
  }

  /// Kiểm tra đã hoàn thành mục tiêu hay chưa
  bool get isCompleted => currentAmount >= targetAmount && targetAmount > 0;
}

