import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Thanh Bottom Navigation Bar chuẩn phong cách MB Bank
class MonedaBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final VoidCallback? onPaymentTap;
  final VoidCallback? onReceiveTap;

  const MonedaBottomBar({
    super.key,
    this.currentIndex = 0,
    this.onTap,
    this.onPaymentTap,
    this.onReceiveTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: SizedBox(
          height: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Nút Trang chủ (Bên trái)
              Expanded(
                child: _BottomNavItem(
                  icon: Icons.home_rounded,
                  label: 'Trang chủ',
                  isSelected: currentIndex == 0,
                  onTap: () => onTap?.call(0),
                ),
              ),

              // 2. Nút Thanh toán ở giữa (Nổi bật - khung vuông trắng nhô cao)
              Expanded(
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(0, -12),
                    child: GestureDetector(
                      onTap: () {
                        onTap?.call(1);
                        onPaymentTap?.call();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x2E000000), // ~18% black
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 28,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Thanh toán',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Nút Nhận tiền (Bên phải)
              Expanded(
                child: _BottomNavItem(
                  icon: Icons.move_to_inbox_rounded,
                  label: 'Nhận tiền',
                  isSelected: currentIndex == 2,
                  onTap: () {
                    onTap?.call(2);
                    onReceiveTap?.call();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.white : const Color(0xBFFFFFFF); // 75% white

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
