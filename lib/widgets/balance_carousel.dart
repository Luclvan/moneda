import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/app_settings.dart';
import '../models/jar.dart';

/// Thẻ số dư trượt ngang và Avatar người dùng (phong cách MB Bank)
class BalanceCarousel extends StatefulWidget {
  final AppSettings settings;
  final Map<String, Jar> jars;
  final bool isBalanceHidden;
  final VoidCallback onToggleHideBalance;
  final ValueChanged<String>? onJarTap;

  const BalanceCarousel({
    super.key,
    required this.settings,
    required this.jars,
    required this.isBalanceHidden,
    required this.onToggleHideBalance,
    this.onJarTap,
  });

  @override
  State<BalanceCarousel> createState() => _BalanceCarouselState();
}

class _BalanceCarouselState extends State<BalanceCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final needJar = widget.jars['NEED'] ?? Jar(jarType: 'NEED', balance: 0);
    final wantJar = widget.jars['WANT'] ?? Jar(jarType: 'WANT', balance: 0);
    final saveJar = widget.jars['SAVE'] ?? Jar(jarType: 'SAVE', balance: 0);

    // 4 thẻ dữ liệu
    final cardsData = [
      _CardModel(
        title: 'Tổng số dư VND >',
        amount: settings.totalBalance,
        badgeText:
            'QUY TẮC 3 HŨ [${settings.needRatio} - ${settings.wantRatio} - ${settings.saveRatio}]',
        jarType: 'ALL',
      ),
      _CardModel(
        title: 'Hũ NEED (${settings.needRatio}%) >',
        amount: needJar.balance,
        badgeText: 'NHU CẦU THIẾT YẾU [CẦN THIẾT]',
        jarType: 'NEED',
      ),
      _CardModel(
        title: 'Hũ WANT (${settings.wantRatio}%) >',
        amount: wantJar.balance,
        badgeText: 'MONG MUỐN CÁ NHÂN [GIẢI TRÍ]',
        jarType: 'WANT',
      ),
      _CardModel(
        title: 'Hũ SAVE (${settings.saveRatio}%) >',
        amount: saveJar.balance,
        badgeText: 'TIẾT KIỆM & ĐẦU TƯ [TÍCH LŨY]',
        jarType: 'SAVE',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cột trái: Avatar và Nhãn 👍 Basic
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 38,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  // Tích xanh nhỏ ở góc trên trái
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.successGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryBlue,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 11,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
                child: const Text(
                  '👍 Basic',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // Cột phải: PageView 4 thẻ trượt ngang + Dot Indicator
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 118,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: cardsData.length,
                    itemBuilder: (context, index) {
                      final card = cardsData[index];
                      return _buildBalanceCard(card);
                    },
                  ),
                ),
                const SizedBox(height: 10),
                // Dot indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(cardsData.length, (index) {
                    final isSelected = _currentPage == index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 5,
                      width: isSelected ? 18 : 6,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.white
                            : AppColors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(_CardModel card) {
    final isNegative = card.amount < 0;
    final formattedAmount = CurrencyFormatter.format(
      card.amount,
      isHidden: widget.isBalanceHidden,
    );

    return InkWell(
      onTap: () => widget.onJarTap?.call(card.jarType),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.cardDarkOverlay,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Tiêu đề & Icon con mắt
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  card.title,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                InkWell(
                  onTap: widget.onToggleHideBalance,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Icon(
                      widget.isBalanceHidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.white.withValues(alpha: 0.9),
                      size: 19,
                    ),
                  ),
                ),
              ],
            ),

            // Số tiền
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formattedAmount,
                style: TextStyle(
                  color: isNegative ? AppColors.errorRed : AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),

            // Nhãn dưới
            Text(
              card.badgeText,
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.8),
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardModel {
  final String title;
  final double amount;
  final String badgeText;
  final String jarType;

  _CardModel({
    required this.title,
    required this.amount,
    required this.badgeText,
    required this.jarType,
  });
}
