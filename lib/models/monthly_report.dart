/// Dữ liệu thống kê báo cáo theo từng hũ trong tháng
class JarReport {
  final String jarType;
  final int ratio;
  final double targetPercent;
  final double targetAmount;
  final double actualAmount;
  final double actualPercent;
  final List<Map<String, dynamic>> expenses;

  JarReport({
    required this.jarType,
    required this.ratio,
    double? targetPercent,
    required this.targetAmount,
    required this.actualAmount,
    required this.actualPercent,
    required this.expenses,
  }) : targetPercent = targetPercent ?? ratio.toDouble();

  /// Tỷ lệ hoàn thành so với mục tiêu (0.0 đến 1.0+)
  double get progress {
    if (targetAmount > 0) {
      return (actualAmount / targetAmount).clamp(0.0, 1.0);
    }
    return actualAmount > 0 ? 1.0 : 0.0;
  }
}

/// Dữ liệu báo cáo tổng thể cho toàn bộ tháng được chọn
class MonthlyReportData {
  final int month;
  final int year;
  final double monthlyIncome;
  final Map<String, JarReport> jars;
  final List<Map<String, dynamic>> allExpenses;

  MonthlyReportData({
    required this.month,
    required this.year,
    required this.monthlyIncome,
    required this.jars,
    required this.allExpenses,
  });

  JarReport get needReport =>
      jars['NEED'] ??
      JarReport(
        jarType: 'NEED',
        ratio: 50,
        targetPercent: 0,
        targetAmount: 0,
        actualAmount: 0,
        actualPercent: 0,
        expenses: const [],
      );

  JarReport get wantReport =>
      jars['WANT'] ??
      JarReport(
        jarType: 'WANT',
        ratio: 30,
        targetPercent: 0,
        targetAmount: 0,
        actualAmount: 0,
        actualPercent: 0,
        expenses: const [],
      );

  JarReport get saveReport =>
      jars['SAVE'] ??
      JarReport(
        jarType: 'SAVE',
        ratio: 20,
        targetPercent: 0,
        targetAmount: 0,
        actualAmount: 0,
        actualPercent: 0,
        expenses: const [],
      );
}
