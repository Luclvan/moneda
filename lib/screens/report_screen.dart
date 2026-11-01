import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/monthly_report.dart';
import '../services/moneda_service.dart';
import '../widgets/moneda_bottom_bar.dart';
import 'payment_screen.dart';
import 'receive_money_screen.dart';
import 'saving_goals_screen.dart';

/// Màn hình Báo cáo & Sao kê (Kịch bản 6: Budget Worksheet 3 tầng có Accordion)
class ReportScreen extends StatefulWidget {
  final int? initialMonth;
  final int? initialYear;

  const ReportScreen({
    super.key,
    this.initialMonth,
    this.initialYear,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final MonedaService _monedaService = MonedaService();

  late int _selectedMonth;
  late int _selectedYear;

  bool _isLoading = true;
  MonthlyReportData? _reportData;

  // Hũ đang chọn để xem chi tiết danh mục ở Tầng 3 ('NEED', 'WANT', 'SAVE')
  String _selectedJarType = 'NEED';

  // Tập hợp các danh mục đang xổ dọc (Accordion expanded)
  final Set<String> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = widget.initialMonth ?? now.month;
    _selectedYear = widget.initialYear ?? now.year;

    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _monedaService.getMonthlyReport(
        month: _selectedMonth,
        year: _selectedYear,
      );

      if (!mounted) return;
      setState(() {
        _reportData = data;
        _isLoading = false;

        // Mặc định tự động mở danh mục đầu tiên nếu danh mục mở chưa có
        final currentJarExpenses =
            data.jars[_selectedJarType]?.expenses ?? const [];
        if (currentJarExpenses.isNotEmpty && _expandedCategories.isEmpty) {
          final firstCat = (currentJarExpenses.first['category'] as String?)?.trim();
          if (firstCat != null && firstCat.isNotEmpty) {
            _expandedCategories.add(firstCat);
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading monthly report: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showMonthYearPicker() async {
    int tempMonth = _selectedMonth;
    int tempYear = _selectedYear;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: AppColors.primaryBlue,
                      size: 28,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        tempYear--;
                      });
                    },
                  ),
                  Text(
                    'Năm $tempYear',
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primaryBlue,
                      size: 28,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        tempYear++;
                      });
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: 320,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 12,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final monthNumber = index + 1;
                    final isSelected =
                        tempMonth == monthNumber && tempYear == _selectedYear;

                    return InkWell(
                      onTap: () {
                        setDialogState(() {
                          tempMonth = monthNumber;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryBlue
                              : AppColors.backgroundGray,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryBlue
                                : AppColors.borderGray,
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Tháng $monthNumber',
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.white
                                : AppColors.textDark,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text(
                    'Hủy',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Xác nhận',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      setState(() {
        _selectedMonth = tempMonth;
        _selectedYear = tempYear;
      });
      _loadReport();
    }
  }

  Future<void> _handleDeleteExpense(Map<String, dynamic> expense) async {
    final title = expense['title'] ?? 'Khoản chi tiêu';
    final amount = (expense['amount'] as num?)?.toDouble() ?? 0.0;
    final jarType = (expense['jar_type'] as String? ?? 'NEED').toUpperCase();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Xác nhận xóa chi tiêu',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Bạn có chắc chắn muốn xóa giao dịch "$title" với số tiền ${CurrencyFormatter.format(amount)}?\nSố tiền sẽ được hoàn trả lại vào hũ $jarType.',
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Hủy',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Xóa',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _monedaService.deleteExpense(expense);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đã xóa giao dịch và hoàn trả tiền vào hũ thành công.',
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
        _loadReport();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa chi tiêu: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _navigateToPayment() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(initialJarType: _selectedJarType),
      ),
    );
    if (mounted) {
      _loadReport();
    }
  }

  void _navigateToReceiveMoney() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ReceiveMoneyScreen(initialTargetJar: _selectedJarType),
      ),
    );
    if (mounted) {
      _loadReport();
    }
  }

  void _navigateToSavingGoals() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SavingGoalsScreen(),
      ),
    );
    if (mounted) {
      _loadReport();
    }
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('ăn') ||
        cat.contains('uống') ||
        cat.contains('cà phê') ||
        cat.contains('thực phẩm')) {
      return Icons.restaurant_rounded;
    }
    if (cat.contains('tạp hoá') ||
        cat.contains('siêu thị') ||
        cat.contains('chợ')) {
      return Icons.local_grocery_store_rounded;
    }
    if (cat.contains('di chuyển') ||
        cat.contains('xăng') ||
        cat.contains('xe') ||
        cat.contains('grab') ||
        cat.contains('taxi')) {
      return Icons.directions_car_rounded;
    }
    if (cat.contains('hóa đơn') ||
        cat.contains('điện') ||
        cat.contains('nước') ||
        cat.contains('tiện ích') ||
        cat.contains('internet') ||
        cat.contains('4g') ||
        cat.contains('topup')) {
      return Icons.receipt_long_rounded;
    }
    if (cat.contains('mua sắm') ||
        cat.contains('quần áo') ||
        cat.contains('shopee') ||
        cat.contains('lazada') ||
        cat.contains('tiki')) {
      return Icons.shopping_bag_rounded;
    }
    if (cat.contains('giải trí') ||
        cat.contains('phim') ||
        cat.contains('game') ||
        cat.contains('du lịch')) {
      return Icons.movie_rounded;
    }
    if (cat.contains('sức khỏe') ||
        cat.contains('thuốc') ||
        cat.contains('khám') ||
        cat.contains('bệnh')) {
      return Icons.medical_services_rounded;
    }
    if (cat.contains('học') ||
        cat.contains('sách') ||
        cat.contains('giáo dục')) {
      return Icons.school_rounded;
    }
    return Icons.category_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final report = _reportData ??
        MonthlyReportData(
          month: _selectedMonth,
          year: _selectedYear,
          monthlyIncome: 0.0,
          jars: {},
          allExpenses: const [],
        );

    final selectedJarReport = report.jars[_selectedJarType] ??
        JarReport(
          jarType: _selectedJarType,
          ratio: _selectedJarType == 'NEED'
              ? 50
              : (_selectedJarType == 'WANT' ? 30 : 20),
          targetAmount: 0,
          actualAmount: 0,
          actualPercent: 0,
          expenses: const [],
        );

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      // Top AppBar nền trắng
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primaryBlue,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Báo cáo & Sao kê',
          style: TextStyle(
            color: AppColors.primaryBlue,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.home_rounded,
              color: AppColors.primaryBlue,
              size: 24,
            ),
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
          ),
          const SizedBox(width: 4),
        ],
      ),

      // Thanh Bottom Bar 5 nút cố định ở đáy (Tab Báo cáo index 1 active)
      bottomNavigationBar: MonedaBottomBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          }
        },
        onPaymentTap: _navigateToPayment,
        onReceiveTap: _navigateToReceiveMoney,
        onGoalsTap: _navigateToSavingGoals,
      ),

      body: RefreshIndicator(
        color: AppColors.primaryBlue,
        backgroundColor: AppColors.white,
        onRefresh: _loadReport,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TẦNG 1: HÀNG NGANG ĐẦU TRANG (2 THẺ CÙNG 1 ROW)
              Row(
                children: [
                  // Thẻ bên trái: Thu nhập tháng
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.borderGray,
                          width: 1,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thu nhập tháng',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              CurrencyFormatter.format(report.monthlyIncome),
                              style: const TextStyle(
                                color: AppColors.primaryBlue,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Thẻ bên phải: Thời gian (chọn Tháng/Năm)
                  Expanded(
                    child: InkWell(
                      onTap: _showMonthYearPicker,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.borderGray,
                            width: 1,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Thời gian',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      size: 15,
                                      color: AppColors.secondaryBlue,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Tháng $_selectedMonth/$_selectedYear',
                                      style: const TextStyle(
                                        color: AppColors.textDark,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const Icon(
                                  Icons.arrow_drop_down_rounded,
                                  size: 20,
                                  color: AppColors.textMuted,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // TẦNG 2: KHỐI NGÂN SÁCH MỤC TIÊU VS THỰC TẾ (3 THẺ HŨ TỐI GIẢN)
              const Text(
                'Ngân sách Mục tiêu vs Thực tế',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Chạm vào hũ để xem chi tiết danh mục bên dưới',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 12),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                )
              else ...[
                _buildJarCard(
                  jarType: 'NEED',
                  bulletColor: AppColors.primaryBlue,
                  report: report.needReport,
                ),
                const SizedBox(height: 10),
                _buildJarCard(
                  jarType: 'WANT',
                  bulletColor: AppColors.lightBlue,
                  report: report.wantReport,
                ),
                const SizedBox(height: 10),
                _buildJarCard(
                  jarType: 'SAVE',
                  bulletColor: AppColors.saveGray,
                  report: report.saveReport,
                ),
              ],

              const SizedBox(height: 24),

              // TẦNG 3: DANH SÁCH CATEGORY & HIỆU ỨNG XỔ DỌC ACCORDION
              Text(
                'Chi tiết chi tiêu: Hũ $_selectedJarType (${selectedJarReport.ratio}%)',
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Tổng chi tiêu: ${CurrencyFormatter.format(selectedJarReport.actualAmount)}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 12),

              _buildCategoryAccordionList(selectedJarReport.expenses),
            ],
          ),
        ),
      ),
    );
  }

  /// Xây dựng Thẻ hũ tối giản ở Tầng 2
  Widget _buildJarCard({
    required String jarType,
    required Color bulletColor,
    required JarReport report,
  }) {
    final isSelected = _selectedJarType == jarType;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedJarType = jarType;
          _expandedCategories.clear();

          // Tự động mở danh mục đầu tiên của hũ mới chọn nếu có
          if (report.expenses.isNotEmpty) {
            final firstCat = (report.expenses.first['category'] as String?)?.trim();
            if (firstCat != null && firstCat.isNotEmpty) {
              _expandedCategories.add(firstCat);
            }
          }
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.borderGray,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hàng 1: Chấm tròn màu + Tên hũ (không ghi % cạnh tên hũ) + Badge nếu đang chọn
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: bulletColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Hũ $jarType',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF), // blue-50
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFBFDBFE), // blue-200
                        width: 0.8,
                      ),
                    ),
                    child: const Text(
                      'Đang xem chi tiết',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Hàng 2: Số tiền thực tế in đậm / Số tiền mục tiêu màu xám (Bên trái)
            // và % Thực tế / % Mục tiêu màu xanh đậm #1E40AF (Bên phải)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: CurrencyFormatter.format(report.actualAmount)
                              .replaceAll(' VND', ''),
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const TextSpan(
                          text: ' / ',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextSpan(
                          text: CurrencyFormatter.format(report.targetAmount),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${report.actualPercent.toStringAsFixed(2)}% / ${report.ratio.toStringAsFixed(2)}%',
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Hàng 3: Thanh tiến trình ngang (cố định 1 màu xanh biển đậm #1E40AF)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: report.progress,
                minHeight: 6,
                backgroundColor: AppColors.borderGray,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Gom nhóm danh sách Category và xây dựng Accordion ở Tầng 3
  Widget _buildCategoryAccordionList(List<Map<String, dynamic>> expenses) {
    if (expenses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderGray,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 40,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 10),
            Text(
              'Không có khoản chi tiêu nào cho Hũ $_selectedJarType trong Tháng $_selectedMonth/$_selectedYear',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Gom nhóm các khoản chi theo category
    final Map<String, List<Map<String, dynamic>>> categoryMap = {};
    for (final exp in expenses) {
      final cat = (exp['category'] as String?)?.trim();
      final category = (cat != null && cat.isNotEmpty) ? cat : 'Khác';
      if (!categoryMap.containsKey(category)) {
        categoryMap[category] = [];
      }
      categoryMap[category]!.add(exp);
    }

    return Column(
      children: categoryMap.entries.map((entry) {
        final category = entry.key;
        final list = entry.value;

        // Tính tổng tiền category
        double categoryTotal = 0;
        for (final item in list) {
          categoryTotal += (item['amount'] as num?)?.toDouble() ?? 0.0;
        }

        final isExpanded = _expandedCategories.contains(category);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isExpanded ? AppColors.disabledBlue : AppColors.borderGray,
              width: isExpanded ? 1.2 : 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header Category: chạm vào để xổ dọc (Accordion)
              InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedCategories.remove(category);
                    } else {
                      _expandedCategories.add(category);
                    }
                  });
                },
                borderRadius: isExpanded
                    ? const BorderRadius.vertical(top: Radius.circular(16))
                    : BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // Ô icon 40x40 nền #F1F5F9, icon màu #1D4ED8
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.iconBackgroundGray,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getCategoryIcon(category),
                          color: AppColors.secondaryBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Tên category + số lượng khoản chi
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category,
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${list.length} khoản chi',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Tổng tiền category + Icon mũi tên lên/xuống
                      Text(
                        '-${CurrencyFormatter.format(categoryTotal)}',
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textMuted,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),

              // Danh sách xổ dọc (Accordion) bên dưới dòng Category
              if (isExpanded) ...[
                const Divider(
                  height: 1,
                  thickness: 0.8,
                  color: AppColors.borderGray,
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    thickness: 0.6,
                    color: AppColors.borderGray,
                    indent: 14,
                    endIndent: 14,
                  ),
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final title = (item['title'] as String?)?.isNotEmpty == true
                        ? item['title'] as String
                        : category;
                    final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
                    final dateRaw = item['transaction_date'];
                    final date = dateRaw != null
                        ? DateTime.tryParse(dateRaw.toString())?.toLocal() ??
                            DateTime.now()
                        : DateTime.now();
                    final dateTimeStr =
                        DateFormat('dd/MM/yyyy • HH:mm').format(date);

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          // Bên trái: title và ngày giờ
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: AppColors.textDark,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dateTimeStr,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Bên phải: số tiền đỏ và icon thùng rác
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '-${CurrencyFormatter.format(amount)}',
                                style: const TextStyle(
                                  color: AppColors.errorRed,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => _handleDeleteExpense(item),
                                borderRadius: BorderRadius.circular(8),
                                child: const Padding(
                                  padding: EdgeInsets.all(4.0),
                                  child: Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppColors.saveGray,
                                    size: 19,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

