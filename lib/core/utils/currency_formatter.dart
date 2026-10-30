import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat('#,###', 'en_US');

  /// Định dạng số tiền sang dạng "3,480,832 VND"
  static String format(num amount, {bool isHidden = false}) {
    if (isHidden) {
      return '***,*** VND';
    }
    final formatted = _formatter.format(amount.round());
    return '$formatted VND';
  }

  /// Định dạng số tiền giao dịch kèm dấu + hoặc -
  /// Ví dụ: "+1,000,000 VND" hoặc "-10,000 VND"
  static String formatTransaction(num amount, {required bool isIncome, bool isHidden = false}) {
    if (isHidden) {
      return '***,*** VND';
    }
    final prefix = isIncome ? '+' : '-';
    final formatted = _formatter.format(amount.abs().round());
    return '$prefix$formatted VND';
  }
}

