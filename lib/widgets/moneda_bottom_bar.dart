import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Thanh Bottom Navigation Bar 5 nút chuẩn phong cách MB Bank:
/// 1. Trang chủ (Icons.home)
/// 2. Báo cáo (Icons.bar_chart_rounded)
/// 3. Thanh toán (Nút nổi bật ở giữa: ô vuông trắng 50x50, icon Icons.grid_view_rounded màu #1E40AF)
/// 4. Nhận tiền (Icons.download_rounded)
/// 5. Mục tiêu (Icons.track_changes_rounded)
class MonedaBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final VoidCallback? onReportTap;
  final VoidCallback? onPaymentTap;
  final VoidCallback? onReceiveTap;
  final VoidCallback? onGoalsTap;

  const MonedaBottomBar({
    super.key,
    this.currentIndex = 0,
    this.onTap,
    this.onReportTap,
    this.onPaymentTap,
    this.onReceiveTap,
    this.onGoalsTap,
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
              // 1. Nút Trang chủ
              Expanded(
                child: _BottomNavItem(
                  icon: Icons.home,
                  label: 'Trang chủ',
                  isSelected: currentIndex == 0,
                  onTap: () => onTap?.call(0),
                ),
              ),

              // 2. Nút Báo cáo
              Expanded(
                child: _BottomNavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Báo cáo',
                  isSelected: currentIndex == 1,
                  onTap: () {
                    onTap?.call(1);
                    onReportTap?.call();
                  },
                ),
              ),

              // 3. Nút Thanh toán ở giữa (Nổi bật - khung vuông trắng 50x50 nhô cao)
              Expanded(
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(0, -10),
                    child: GestureDetector(
                      onTap: () {
                        onTap?.call(2);
                        onPaymentTap?.call();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x2E000000), // ~18% black
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.grid_view_rounded,
                              size: 26,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Thanh toán',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 4. Nút Nhận tiền
              Expanded(
                child: _BottomNavItem(
                  icon: Icons.download_rounded,
                  label: 'Nhận tiền',
                  isSelected: currentIndex == 3,
                  onTap: () {
                    onTap?.call(3);
                    onReceiveTap?.call();
                  },
                ),
              ),

              // 5. Nút Mục tiêu
              Expanded(
                child: _BottomNavItem(
                  icon: Icons.track_changes_rounded,
                  label: 'Mục tiêu',
                  isSelected: currentIndex == 4,
                  onTap: () {
                    onTap?.call(4);
                    onGoalsTap?.call();
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
    final color =
        isSelected ? AppColors.white : const Color(0xBFFFFFFF); // 75% white

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: color,
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
