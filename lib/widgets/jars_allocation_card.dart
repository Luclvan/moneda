import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/app_settings.dart';
import '../models/jar.dart';

/// Khối hiển thị "Tỷ lệ phân bổ 3 hũ"
class JarsAllocationCard extends StatelessWidget {
  final AppSettings settings;
  final Map<String, Jar> jars;
  final bool isBalanceHidden;
  final VoidCallback? onCustomizeTap;
  final ValueChanged<String>? onJarTap;

  const JarsAllocationCard({
    super.key,
    required this.settings,
    required this.jars,
    required this.isBalanceHidden,
    this.onCustomizeTap,
    this.onJarTap,
  });

  @override
  Widget build(BuildContext context) {
    final needRatio = settings.needRatio;
    final wantRatio = settings.wantRatio;
    final saveRatio = settings.saveRatio;

    final needJar = jars['NEED'] ?? Jar(jarType: 'NEED', balance: 0);
    final wantJar = jars['WANT'] ?? Jar(jarType: 'WANT', balance: 0);
    final saveJar = jars['SAVE'] ?? Jar(jarType: 'SAVE', balance: 0);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
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
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề & Nút "Tùy chỉnh"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tỷ lệ phân bổ 3 hũ',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Mục tiêu tài chính cá nhân',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onCustomizeTap,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text(
                    'Tùy chỉnh',
                    style: TextStyle(
                      color: AppColors.secondaryBlue,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Thanh tiến trình phân bổ 3 đoạn bo tròn
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  // Đoạn 1: Need (Xanh biển đậm)
                  Flexible(
                    flex: needRatio > 0 ? needRatio : 1,
                    child: Container(color: AppColors.primaryBlue),
                  ),
                  const SizedBox(width: 2),
                  // Đoạn 2: Want (Xanh biển nhạt)
                  Flexible(
                    flex: wantRatio > 0 ? wantRatio : 1,
                    child: Container(color: AppColors.lightBlue),
                  ),
                  const SizedBox(width: 2),
                  // Đoạn 3: Save (Xám)
                  Flexible(
                    flex: saveRatio > 0 ? saveRatio : 1,
                    child: Container(color: AppColors.saveGray),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 3 Thẻ nhỏ xếp ngang
          Row(
            children: [
              Expanded(
                child: _JarMiniCard(
                  name: 'Need',
                  ratio: needRatio,
                  dotColor: AppColors.primaryBlue,
                  balance: needJar.balance,
                  description: 'Thiết yếu',
                  isBalanceHidden: isBalanceHidden,
                  onTap: () => onJarTap?.call('NEED'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _JarMiniCard(
                  name: 'Want',
                  ratio: wantRatio,
                  dotColor: AppColors.lightBlue,
                  balance: wantJar.balance,
                  description: 'Mong muốn',
                  isBalanceHidden: isBalanceHidden,
                  onTap: () => onJarTap?.call('WANT'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _JarMiniCard(
                  name: 'Save',
                  ratio: saveRatio,
                  dotColor: AppColors.saveGray,
                  balance: saveJar.balance,
                  description: 'Tiết kiệm',
                  isBalanceHidden: isBalanceHidden,
                  onTap: () => onJarTap?.call('SAVE'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _JarMiniCard extends StatelessWidget {
  final String name;
  final int ratio;
  final Color dotColor;
  final double balance;
  final String description;
  final bool isBalanceHidden;
  final VoidCallback? onTap;

  const _JarMiniCard({
    required this.name,
    required this.ratio,
    required this.dotColor,
    required this.balance,
    required this.description,
    required this.isBalanceHidden,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = balance < 0;
    final formattedBalance = CurrencyFormatter.format(
      balance,
      isHidden: isBalanceHidden,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.borderGray,
            width: 1,
          ),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dòng 1: Chấm tròn + Tên hũ + %
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '$name $ratio%',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Dòng 2: Số tiền còn lại
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formattedBalance,
              style: TextStyle(
                color: isNegative ? AppColors.errorRed : AppColors.textDark,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Dòng 3: Mô tả ngắn
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    ),
    );
  }
}
