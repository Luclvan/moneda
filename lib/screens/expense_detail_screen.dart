import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/app_settings.dart';
import '../models/jar.dart';
import '../services/moneda_service.dart';
import '../widgets/mb_feedback.dart';
import 'payment_screen.dart';

/// Màn hình Chi tiết chi tiêu (chuẩn phong cách MB Bank)
class ExpenseDetailScreen extends StatefulWidget {
  final String initialJarFilter;

  const ExpenseDetailScreen({
    super.key,
    this.initialJarFilter = 'ALL',
  });

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  final MonedaService _monedaService = MonedaService();

  late String _selectedJarFilter;
  late DateTime _fromDate;
  late DateTime _toDate;

  bool _isLoading = true;
  AppSettings? _settings;
  Map<String, Jar> _jars = {};
  List<Map<String, dynamic>> _expenses = [];

  @override
  void initState() {
    super.initState();
    _selectedJarFilter = widget.initialJarFilter;

    final now = DateTime.now();
    // Mặc định từ ngày 01 của tháng hiện tại đến ngày cuối tháng
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = DateTime(now.year, now.month + 1, 0);

    if (_monedaService.hasHomeCache) {
      _settings = AppSettings.fromJson(MonedaService.cachedSettings!);
      _jars = {
        for (var e in MonedaService.cachedJars!)
          (e['jar_type'] as String).toUpperCase(): Jar.fromJson(e)
      };
      _isLoading = false;
    }

    _loadData();
  }

  Future<void> _loadData() async {
    if (_settings == null && _expenses.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _monedaService.getAppSettings(),
        _monedaService.getJars(),
        _monedaService.getExpenses(
          jarType: _selectedJarFilter,
          fromDate: _fromDate,
          toDate: _toDate,
        ),
      ]);

      if (!mounted) return;
      setState(() {
        _settings = results[0] as AppSettings;
        _jars = results[1] as Map<String, Jar>;
        _expenses = results[2] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onPillFilterChanged(String filter) {
    if (_selectedJarFilter == filter) return;
    setState(() {
      _selectedJarFilter = filter;
    });
    _loadData();
  }

  Future<void> _selectFromDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: AppColors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _fromDate) {
      setState(() {
        _fromDate = picked;
      });
    }
  }

  Future<void> _selectToDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: AppColors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _toDate) {
      setState(() {
        _toDate = picked;
      });
    }
  }

  Future<void> _handleDeleteExpense(Map<String, dynamic> expense) async {
    final confirm = await showMbDeleteConfirmDialog(
      context: context,
      title: 'Xoá giao dịch hiện tại',
      message:
          'Khi xoá, số tiền của giao dịch này sẽ được tự động hoàn trả / thu hồi chính xác ở các hũ liên quan.',
      confirmText: 'Xoá giao dịch',
    );

    if (confirm == true) {
      try {
        await _monedaService.deleteExpense(expense);
        if (!mounted) return;
        showMbTopToast(context, 'Đã xoá giao dịch thành công');
        _loadData();
      } catch (e) {
        if (!mounted) return;
        showMbTopToast(context, 'Lỗi khi xóa chi tiêu: $e');
      }
    }
  }

  void _navigateToPayment() async {
    final targetJar =
        _selectedJarFilter != 'ALL' ? _selectedJarFilter : null;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(initialJarType: targetJar),
      ),
    );
    if (mounted) {
      _loadData();
    }
  }

  // Nhóm danh sách giao dịch theo ngày (dd/MM/yyyy)
  Map<String, List<Map<String, dynamic>>> _groupExpensesByDate() {
    final Map<String, List<Map<String, dynamic>>> map = {};
    for (final exp in _expenses) {
      final dateRaw = exp['transaction_date'];
      final date = dateRaw != null
          ? DateTime.tryParse(dateRaw.toString())?.toLocal() ?? DateTime.now()
          : DateTime.now();
      final key = DateFormat('dd/MM/yyyy').format(date);
      if (!map.containsKey(key)) {
        map[key] = [];
      }
      map[key]!.add(exp);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    // Tính toán số dư hiển thị ở Khối 1
    double currentBalance = 0.0;
    String balanceTitle = 'Tổng số tiền khả dụng';

    if (_selectedJarFilter == 'ALL') {
      currentBalance = _settings?.totalBalance ?? 0.0;
      balanceTitle = 'Tổng số tiền khả dụng';
    } else {
      currentBalance = _jars[_selectedJarFilter]?.balance ?? 0.0;
      balanceTitle = 'Số dư Hũ $_selectedJarFilter';
    }

    final isNegative = currentBalance < 0;

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
          onPressed: () => Navigator.pop(context, true),
        ),
        centerTitle: true,
        title: const Text(
          'Chi tiết chi tiêu',
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

      body: RefreshIndicator(
        color: AppColors.primaryBlue,
        backgroundColor: AppColors.white,
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KHỐI 1: THẺ SỐ DƯ ĐẦU TRANG
              Container(
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            balanceTitle,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              CurrencyFormatter.format(currentBalance),
                              style: TextStyle(
                                color: isNegative
                                    ? AppColors.errorRed
                                    : AppColors.textDark,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Nút hình viên thuốc "Thanh toán"
                    ElevatedButton.icon(
                      onPressed: _navigateToPayment,
                      icon: const Icon(
                        Icons.credit_card_rounded,
                        size: 16,
                        color: AppColors.white,
                      ),
                      label: const Text(
                        'Thanh toán',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // KHỐI 2: HÀNG 4 NÚT LỌC DẠNG VIÊN THUỐC (PILL TABS)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPillTab(label: 'Tất cả', filter: 'ALL'),
                    const SizedBox(width: 8),
                    _buildPillTab(label: 'Hũ Need', filter: 'NEED'),
                    const SizedBox(width: 8),
                    _buildPillTab(label: 'Hũ Want', filter: 'WANT'),
                    const SizedBox(width: 8),
                    _buildPillTab(label: 'Hũ Save', filter: 'SAVE'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // KHỐI 3: CARD TRUY VẤN GIAO DỊCH
              Container(
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
                    const Text(
                      'Truy vấn giao dịch',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2 ô Từ ngày - Đến ngày
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateBox(
                            label: 'Từ ngày',
                            date: _fromDate,
                            onTap: _selectFromDate,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildDateBox(
                            label: 'Đến ngày',
                            date: _toDate,
                            onTap: _selectToDate,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Nút Truy vấn lớn
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _loadData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Truy vấn',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Dòng chú thích nhỏ
                    const Center(
                      child: Text(
                        'Hệ thống hỗ trợ truy vấn lịch sử giao dịch trong vòng 1 năm kể từ ngày hiện tại',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // KHỐI 4: DANH SÁCH LỊCH SỬ GIAO DỊCH GOM NHÓM THEO NGÀY
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                )
              else if (_expenses.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.borderGray,
                      width: 1,
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 44,
                        color: AppColors.textMuted,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Không có giao dịch chi tiêu nào trong khoảng thời gian này',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                _buildGroupedExpenseList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillTab({required String label, required String filter}) {
    final isSelected = _selectedJarFilter == filter;

    return InkWell(
      onTap: () => _onPillFilterChanged(filter),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.borderGray,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.textDark,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDateBox({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(date),
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.secondaryBlue,
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedExpenseList() {
    final groups = _groupExpensesByDate();

    return Column(
      children: groups.entries.map((entry) {
        final dateKey = entry.key;
        final list = entry.value;

        // Tính tổng tiền chi của ngày đó
        double dayTotal = 0;
        for (final item in list) {
          dayTotal += (item['amount'] as num?)?.toDouble() ?? 0.0;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
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
            children: [
              // Header của ngày
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: AppColors.backgroundGray,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.borderGray,
                      width: 0.8,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateKey,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${list.length} giao dịch (-${CurrencyFormatter.format(dayTotal)})',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Danh sách giao dịch trong ngày
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: list.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  thickness: 0.8,
                  color: AppColors.borderGray,
                ),
                itemBuilder: (context, index) {
                  final expense = list[index];
                  final title = expense['title'] ?? 'Chi tiêu';
                  final category = expense['category'] ?? 'Khác';
                  final jarType = (expense['jar_type'] as String? ?? 'NEED').toUpperCase();
                  final amount = (expense['amount'] as num?)?.toDouble() ?? 0.0;

                  final dateRaw = expense['transaction_date'];
                  final date = dateRaw != null
                      ? DateTime.tryParse(dateRaw.toString())?.toLocal() ?? DateTime.now()
                      : DateTime.now();
                  final timeStr = DateFormat('HH:mm').format(date);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        // Ô vuông bo góc 40x40 nền #F1F5F9, icon mũi tên chéo lên
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.iconBackgroundGray,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.north_east_rounded,
                            color: AppColors.secondaryBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Ở giữa: TIỀN RA • Danh mục, title, Hũ & Giờ
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TIỀN RA • $category',
                                style: const TextStyle(
                                  color: AppColors.secondaryBlue,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                title,
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
                                'Hũ $jarType • $timeStr',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Bên phải: Số tiền & Icon thùng rác
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '-${CurrencyFormatter.format(amount)}',
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () => _handleDeleteExpense(expense),
                              borderRadius: BorderRadius.circular(8),
                              child: const Padding(
                                padding: EdgeInsets.all(3.0),
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
          ),
        );
      }).toList(),
    );
  }
}

