import 'package:flutter/services.dart';
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
  static String formatTransaction(num amount,
      {required bool isIncome, bool isHidden = false}) {
    if (isHidden) {
      return '***,*** VND';
    }
    final prefix = isIncome ? '+' : '-';
    final formatted = _formatter.format(amount.abs().round());
    return '$prefix$formatted VND';
  }

  /// Trích xuất giá trị số từ chuỗi nhập liệu (VD: "3,000,000 VND" -> 3000000.0)
  static double parseRawAmount(String text) {
    final digits = text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return 0.0;
    return double.tryParse(digits) ?? 0.0;
  }
}

/// Formatter tự động thêm dấu phẩy và " VND" khi người dùng nhập số
class CurrencyInputFormatter extends TextInputFormatter {
  static final NumberFormat _formatter = NumberFormat('#,###', 'en_US');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final number = int.tryParse(digits) ?? 0;
    final formattedNumber = _formatter.format(number);
    final newText = '$formattedNumber VND';

    // Đặt con trỏ ngay sau phần số, trước khoảng trắng và chữ VND
    final cursorOffset = formattedNumber.length;

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursorOffset),
    );
  }
}
