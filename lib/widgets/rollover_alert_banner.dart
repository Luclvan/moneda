import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Banner nhắc nhở quyết toán đầu tháng chuẩn MB Bank Style
class RolloverAlertBanner extends StatelessWidget {
  final VoidCallback onTransferToSave;
  final VoidCallback onKeepJars;
  final VoidCallback? onDismiss;
  final bool isLoading;

  const RolloverAlertBanner({
    super.key,
    required this.onTransferToSave,
    required this.onKeepJars,
    this.onDismiss,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x4D0F172A), // Color(0xFF0F172A) ~30%
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dòng trên: Icon đồng hồ + Dòng text + Nút x đóng
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon đồng hồ / thông báo nhỏ
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  color: AppColors.white,
                  size: 15,
                ),
              ),
              const SizedBox(width: 10),

              // Dòng chữ thông báo có chữ Save gạch chân in đậm
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12.5,
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                    ),
                    children: [
                      const TextSpan(
                        text:
                            'Đã sang tháng mới, số tiền dư bạn có muốn chuyển sang ',
                      ),
                      TextSpan(
                        text: 'Save',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.white,
                          decorationThickness: 1.5,
                          color: AppColors.white,
                        ),
                      ),
                      const TextSpan(
                        text: ' hay giữ lại từng hũ?',
                      ),
                    ],
                  ),
                ),
              ),

              // Nút x nhỏ góc phải
              if (onDismiss != null)
                InkWell(
                  onTap: onDismiss,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Icon(
                      Icons.close_rounded,
                      color: AppColors.white.withValues(alpha: 0.7),
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Dòng dưới: 2 nút nhỏ Chuyển sang Save và Giữ lại
          if (isLoading)
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              ),
            )
          else
            Row(
              children: [
                // 1. Nút Chuyển sang Save: Nền Trắng (#FFFFFF), chữ Xanh (#1E40AF), bo góc 8px
                ElevatedButton(
                  onPressed: onTransferToSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.primaryBlue,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Chuyển sang Save',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 2. Nút Giữ lại: Nền trong suốt, viền trắng mảnh, chữ trắng, bo góc 8px
                OutlinedButton(
                  onPressed: onKeepJars,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    side: BorderSide(
                      color: AppColors.white.withValues(alpha: 0.6),
                      width: 1,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Giữ lại',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
