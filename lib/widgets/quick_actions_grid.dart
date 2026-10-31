import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Khối 4 nút chức năng nhanh chuẩn MB Bank:
/// 1. Thanh toán (credit_card)
/// 2. Nhận tiền (attach_money)
/// 3. Chuyển tiền (swap_vert)
/// 4. Lịch sử giao dịch (access_time)
class QuickActionsGrid extends StatelessWidget {
  final VoidCallback? onPaymentTap;
  final VoidCallback? onReceiveTap;
  final VoidCallback? onTransferTap;
  final VoidCallback? onHistoryTap;

  // Giữ lại alias cũ nếu có caller gọi
  final VoidCallback? onIncomeTap;
  final VoidCallback? onExpenseTap;

  const QuickActionsGrid({
    super.key,
    this.onPaymentTap,
    this.onReceiveTap,
    this.onTransferTap,
    this.onHistoryTap,
    this.onIncomeTap,
    this.onExpenseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.borderGray,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Thanh toán
          Expanded(
            child: _ActionButton(
              icon: Icons.credit_card_rounded,
              label: 'Thanh toán',
              onTap: onPaymentTap,
            ),
          ),
          // 2. Nhận tiền
          Expanded(
            child: _ActionButton(
              icon: Icons.attach_money_rounded,
              label: 'Nhận tiền',
              onTap: onReceiveTap ?? onIncomeTap,
            ),
          ),
          // 3. Chuyển tiền
          Expanded(
            child: _ActionButton(
              icon: Icons.swap_vert_rounded,
              label: 'Chuyển tiền',
              onTap: onTransferTap,
            ),
          ),
          // 4. Lịch sử giao dịch
          Expanded(
            child: _ActionButton(
              icon: Icons.access_time_rounded,
              label: 'Lịch sử GD',
              fullLabel: 'Lịch sử giao dịch',
              onTap: onHistoryTap ?? onExpenseTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? fullLabel;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.fullLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Khung vuông bo góc 48x48, viền xám 1px
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.borderGray,
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: 24,
                color: AppColors.secondaryBlue, // Bắt buộc đồng nhất màu #1D4ED8
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
