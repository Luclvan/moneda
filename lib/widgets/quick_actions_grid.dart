import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Khối 4 nút chức năng nhanh (Thanh toán, Nhận tiền, Thu nhập, Chi tiêu)
class QuickActionsGrid extends StatelessWidget {
  final VoidCallback? onPaymentTap;
  final VoidCallback? onReceiveTap;
  final VoidCallback? onIncomeTap;
  final VoidCallback? onExpenseTap;

  const QuickActionsGrid({
    super.key,
    this.onPaymentTap,
    this.onReceiveTap,
    this.onIncomeTap,
    this.onExpenseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ActionButton(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Thanh toán',
            onTap: onPaymentTap,
          ),
          _ActionButton(
            icon: Icons.move_to_inbox_rounded,
            label: 'Nhận tiền',
            onTap: onReceiveTap,
          ),
          _ActionButton(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Thu nhập',
            onTap: onIncomeTap,
          ),
          _ActionButton(
            icon: Icons.shopping_bag_outlined,
            label: 'Chi tiêu',
            onTap: onExpenseTap,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
