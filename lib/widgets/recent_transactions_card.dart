import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/transaction_item.dart';

/// Khối "Giao dịch gần đây" chuẩn phong cách MB Bank
class RecentTransactionsCard extends StatelessWidget {
  final List<TransactionItem> transactions;
  final bool isBalanceHidden;
  final VoidCallback? onViewAllTap;

  const RecentTransactionsCard({
    super.key,
    required this.transactions,
    required this.isBalanceHidden,
    this.onViewAllTap,
  });

  @override
  Widget build(BuildContext context) {
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
          // Tiêu đề & Xem tất cả >
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Giao dịch gần đây',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              InkWell(
                onTap: onViewAllTap,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    'Xem tất cả >',
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

          const SizedBox(height: 12),

          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.iconBackgroundGray,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        color: AppColors.textMuted,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Chưa có giao dịch gần đây',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: transactions.length,
              separatorBuilder: (context, index) => const Divider(
                height: 18,
                thickness: 0.8,
                color: AppColors.borderGray,
              ),
              itemBuilder: (context, index) {
                final item = transactions[index];
                return _TransactionRow(
                  item: item,
                  isBalanceHidden: isBalanceHidden,
                );
              },
            ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final TransactionItem item;
  final bool isBalanceHidden;

  const _TransactionRow({
    required this.item,
    required this.isBalanceHidden,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Bên trái: Ô vuông bo góc (42x42) nền xám nhạt (#F1F5F9)
        // Icon mũi tên chéo màu Xanh biển (#1D4ED8)
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.iconBackgroundGray,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            item.isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
            size: 20,
            color: AppColors.secondaryBlue,
          ),
        ),

        const SizedBox(width: 12),

        // Ở giữa: Nội dung chi tiết & dòng phụ
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                item.subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Bên phải: Số tiền (+/- ... VND) in đậm màu đen/xám đậm & Ngày tháng
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.formatTransaction(
                item.amount,
                isIncome: item.isIncome,
                isHidden: isBalanceHidden,
              ),
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.dateText,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
