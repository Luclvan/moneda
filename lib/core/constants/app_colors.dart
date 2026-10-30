import 'package:flutter/material.dart';

/// Bảng màu chuẩn phong cách MB Bank đơn sắc & hiện đại
class AppColors {
  AppColors._();

  // MB Bank Signature Blues
  /// Màu nền Banner, Bottom Bar, nút chính (#1E40AF)
  static const Color primaryBlue = Color(0xFF1E40AF);

  /// Màu tất cả các icon chức năng (#1D4ED8)
  static const Color secondaryBlue = Color(0xFF1D4ED8);

  /// Màu thanh tiến trình hũ Want (#60A5FA)
  static const Color lightBlue = Color(0xFF60A5FA);

  // Background & Borders
  /// Màu nền trang (#F8FAFC)
  static const Color backgroundGray = Color(0xFFF8FAFC);

  /// Màu nền ô icon giao dịch (#F1F5F9)
  static const Color iconBackgroundGray = Color(0xFFF1F5F9);

  /// Viền mảnh 1px cho các thẻ và nút (#E2E8F0)
  static const Color borderGray = Color(0xFFE2E8F0);

  /// Màu thanh tiến trình hũ Save (#94A3B8)
  static const Color saveGray = Color(0xFF94A3B8);

  // Typography
  /// Màu chữ tiêu đề, số tiền chính (#0F172A)
  static const Color textDark = Color(0xFF0F172A);

  /// Màu chữ phụ, ghi chú (#64748B)
  static const Color textMuted = Color(0xFF64748B);

  // Utility Colors
  /// Màu trắng tinh (#FFFFFF)
  static const Color white = Color(0xFFFFFFFF);

  /// Màu báo động hoặc số dư âm (#DC2626)
  static const Color errorRed = Color(0xFFDC2626);

  /// Màu xanh lá thông báo/tích xanh (#16A34A)
  static const Color successGreen = Color(0xFF16A34A);

  /// Nền thẻ số dư xanh đen bán trong suốt
  static const Color cardDarkOverlay = Color(0x590F172A); // ~35% opacity
}

