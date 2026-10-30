import 'package:intl/intl.dart';

/// Đại diện cho một giao dịch hiển thị trên Trang chủ (tổng hợp từ incomes hoặc expenses)
class TransactionItem {
  final String id;
  final bool isIncome;
  final String title;
  final String jarType;
  final double amount;
  final DateTime transactionDate;
  final String? note;

  TransactionItem({
    required this.id,
    required this.isIncome,
    required this.title,
    required this.jarType,
    required this.amount,
    required this.transactionDate,
    this.note,
  });

  factory TransactionItem.fromIncome(Map<String, dynamic> json) {
    final targetJar = json['target_jar'] as String?;
    final date = json['transaction_date'] != null
        ? DateTime.tryParse(json['transaction_date'].toString()) ?? DateTime.now()
        : DateTime.now();

    return TransactionItem(
      id: 'income_${json['id']}',
      isIncome: true,
      title: (json['source_name'] as String?)?.isNotEmpty == true
          ? json['source_name'] as String
          : 'Khoản thu nhập',
      jarType: targetJar ?? 'ALL',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      transactionDate: date,
      note: json['note'] as String?,
    );
  }

  factory TransactionItem.fromExpense(Map<String, dynamic> json) {
    final jarType = (json['jar_type'] as String?)?.toUpperCase() ?? 'NEED';
    final date = json['transaction_date'] != null
        ? DateTime.tryParse(json['transaction_date'].toString()) ?? DateTime.now()
        : DateTime.now();

    final title = (json['title'] as String?)?.isNotEmpty == true
        ? json['title'] as String
        : ((json['category'] as String?)?.isNotEmpty == true
            ? json['category'] as String
            : 'Khoản chi tiêu');

    return TransactionItem(
      id: 'expense_${json['id']}',
      isIncome: false,
      title: title,
      jarType: jarType,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      transactionDate: date,
    );
  }

  /// Dòng phụ: "Phân bổ 3 hũ • 14:30" hoặc "Hũ NEED • 14:30"
  String get subtitle {
    final timeStr = DateFormat('HH:mm').format(transactionDate.toLocal());
    if (isIncome) {
      if (jarType == 'ALL' || jarType.isEmpty) {
        return 'Phân bổ 3 hũ • $timeStr';
      }
      return 'Hũ $jarType • $timeStr';
    } else {
      return 'Hũ $jarType • $timeStr';
    }
  }

  /// Ngày tháng hiển thị dạng: 30/10/2026
  String get dateText {
    return DateFormat('dd/MM/yyyy').format(transactionDate.toLocal());
  }
}

