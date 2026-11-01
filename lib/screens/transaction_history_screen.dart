import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/app_settings.dart';
import '../models/jar.dart';
import '../services/moneda_service.dart';
import '../widgets/mb_feedback.dart';
import 'payment_screen.dart';
import 'receive_money_screen.dart';

/// Mục giao dịch trong lịch sử (kết hợp cả Thu nhập và Chi tiêu)
class _HistoryEntry {
  final bool isIncome;
  final String id;
  final String title;
  final String jarType;
  final String? category;
  final double amount;
  final DateTime date;
  final Map<String, dynamic> raw;

  _HistoryEntry({
    required this.isIncome,
    required this.id,
    required this.title,
    required this.jarType,
    this.category,
    required this.amount,
    required this.date,
    required this.raw,
  });
}

/// Màn hình Lịch sử giao dịch tổng hợp (chuẩn phong cách MB Bank)
/// Gom toàn bộ Thu nhập và Chi tiêu với 5 Tab lọc linh hoạt:
/// 'ALL', 'INCOME', 'NEED', 'WANT', 'SAVE'
class TransactionHistoryScreen extends StatefulWidget {
  final String initialTab;

  const TransactionHistoryScreen({
    super.key,
    this.initialTab = 'ALL',
  });

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final MonedaService _monedaService = MonedaService();

  late String _selectedTab;
  late DateTime _fromDate;
  late DateTime _toDate;

  bool _isLoading = true;
  AppSettings? _settings;
  Map<String, Jar> _jars = {};
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _incomes = [];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab.toUpperCase();

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
    if (_settings == null && _expenses.isEmpty && _incomes.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _monedaService.getAppSettings(),
        _monedaService.getJars(),
        _monedaService.getExpenses(
          jarType: null,
          fromDate: _fromDate,
          toDate: _toDate,
        ),
        _monedaService.getIncomes(
          fromDate: _fromDate,
          toDate: _toDate,
        ),
      ]);

      if (!mounted) return;
      setState(() {
        _settings = results[0] as AppSettings;
        _jars = results[1] as Map<String, Jar>;
        _expenses = results[2] as List<Map<String, dynamic>>;
        _incomes = results[3] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading transaction history: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onPillTabChanged(String tab) {
    if (_selectedTab == tab) return;
    setState(() {
      _selectedTab = tab;
    });
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

  Future<void> _handleDeleteIncome(Map<String, dynamic> income) async {
    final confirm = await showMbDeleteConfirmDialog(
      context: context,
      title: 'Xoá giao dịch hiện tại',
      message:
          'Khi xoá, số tiền của giao dịch này sẽ được tự động hoàn trả / thu hồi chính xác ở các hũ liên quan.',
      confirmText: 'Xoá giao dịch',
    );

    if (confirm == true) {
      try {
        await _monedaService.deleteIncome(income);
        if (!mounted) return;
        showMbTopToast(context, 'Đã xoá giao dịch thành công');
        _loadData();
      } catch (e) {
        if (!mounted) return;
        final errorMsg = e.toString();
        if (errorMsg.contains('đã được chi tiêu')) {
          showMbTopToast(
            context,
            'Không thể xóa khoản thu nhập này vì số tiền trong hũ đã được chi tiêu!',
          );
        } else {
          showMbTopToast(context, 'Lỗi khi xóa thu nhập: $e');
        }
      }
    }
  }

  void _navigateToPayment() async {
    final targetJar = (_selectedTab == 'NEED' ||
            _selectedTab == 'WANT' ||
            _selectedTab == 'SAVE')
        ? _selectedTab
        : null;
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

  void _navigateToReceiveMoney() async {
    final targetJar = (_selectedTab == 'NEED' ||
            _selectedTab == 'WANT' ||
            _selectedTab == 'SAVE')
        ? _selectedTab
        : 'ALL_SPLIT';
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ReceiveMoneyScreen(initialTargetJar: targetJar),
      ),
    );
    if (mounted) {
      _loadData();
    }
  }

  /// Lọc và gom nhóm các giao dịch theo tab hiện tại
  List<_HistoryEntry> _getFilteredEntries() {
    final List<_HistoryEntry> entries = [];

    // 1. Thêm Incomes nếu chọn ALL hoặc INCOME
    if (_selectedTab == 'ALL' || _selectedTab == 'INCOME') {
      for (final inc in _incomes) {
        final id = 'income_${inc['id']}';
        final sourceName = (inc['source_name'] as String?)?.isNotEmpty == true
            ? inc['source_name'] as String
            : 'Khoản thu nhập';
        final targetJar = (inc['target_jar'] as String?) ?? 'ALL';
        final amount = (inc['amount'] as num?)?.toDouble() ?? 0.0;
        final dateRaw = inc['transaction_date'];
        final date = dateRaw != null
            ? DateTime.tryParse(dateRaw.toString())?.toLocal() ?? DateTime.now()
            : DateTime.now();

        entries.add(
          _HistoryEntry(
            isIncome: true,
            id: id,
            title: sourceName,
            jarType: targetJar,
            amount: amount,
            date: date,
            raw: inc,
          ),
        );
      }
    }

    // 2. Thêm Expenses nếu chọn ALL hoặc hũ cụ thể NEED / WANT / SAVE
    if (_selectedTab == 'ALL' ||
        _selectedTab == 'NEED' ||
        _selectedTab == 'WANT' ||
        _selectedTab == 'SAVE') {
      for (final exp in _expenses) {
        final jarType =
            (exp['jar_type'] as String? ?? 'NEED').toUpperCase();
        if (_selectedTab != 'ALL' && _selectedTab != jarType) {
          continue;
        }

        final id = 'expense_${exp['id']}';
        final title = (exp['title'] as String?)?.isNotEmpty == true
            ? exp['title'] as String
            : ((exp['category'] as String?)?.isNotEmpty == true
                ? exp['category'] as String
                : 'Khoản chi tiêu');
        final category = exp['category'] as String? ?? 'Khác';
        final amount = (exp['amount'] as num?)?.toDouble() ?? 0.0;
        final dateRaw = exp['transaction_date'];
        final date = dateRaw != null
            ? DateTime.tryParse(dateRaw.toString())?.toLocal() ?? DateTime.now()
            : DateTime.now();

        entries.add(
          _HistoryEntry(
            isIncome: false,
            id: id,
            title: title,
            jarType: jarType,
            category: category,
            amount: amount,
            date: date,
            raw: exp,
          ),
        );
      }
    }

    // Sắp xếp giảm dần theo thời gian
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  /// Nhóm danh sách giao dịch theo ngày (dd/MM/yyyy)
  Map<String, List<_HistoryEntry>> _groupEntriesByDate(
      List<_HistoryEntry> entries) {
    final Map<String, List<_HistoryEntry>> map = {};
    for (final item in entries) {
      final key = DateFormat('dd/MM/yyyy').format(item.date);
      if (!map.containsKey(key)) {
        map[key] = [];
      }
      map[key]!.add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    // Tính toán số dư và tiêu đề Khối 1 theo Tab
    double displayBalance = 0.0;
    String balanceTitle = 'Tổng số tiền khả dụng';

    if (_selectedTab == 'ALL') {
      displayBalance = _settings?.totalBalance ?? 0.0;
      balanceTitle = 'Tổng số tiền khả dụng';
    } else if (_selectedTab == 'INCOME') {
      balanceTitle = 'Tổng thu nhập trong kỳ';
      for (final inc in _incomes) {
        displayBalance += (inc['amount'] as num?)?.toDouble() ?? 0.0;
      }
    } else {
      balanceTitle = 'Số dư Hũ $_selectedTab';
      displayBalance = _jars[_selectedTab]?.balance ?? 0.0;
    }

    final isNegative = displayBalance < 0;
    final isIncomeTab = _selectedTab == 'INCOME';
    final filteredEntries = _getFilteredEntries();

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
          'Lịch sử giao dịch',
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
              // KHỐI 1: THẺ SỐ DƯ TỔNG QUAN
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
                              CurrencyFormatter.format(displayBalance),
                              style: TextStyle(
                                color: isNegative
                                    ? AppColors.errorRed
                                    : (isIncomeTab
                                        ? AppColors.successGreen
                                        : AppColors.textDark),
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 2 Nút dạng viên thuốc: Thanh toán & Nhận tiền
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Nút Thanh toán (màu #1E40AF)
                        ElevatedButton.icon(
                          onPressed: _navigateToPayment,
                          icon: const Icon(
                            Icons.credit_card_rounded,
                            size: 14,
                            color: AppColors.white,
                          ),
                          label: const Text(
                            'Thanh toán',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Nút Nhận tiền (nền trắng viền xanh)
                        OutlinedButton.icon(
                          onPressed: _navigateToReceiveMoney,
                          icon: const Icon(
                            Icons.attach_money_rounded,
                            size: 14,
                            color: AppColors.primaryBlue,
                          ),
                          label: const Text(
                            'Nhận tiền',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.white,
                            side: const BorderSide(
                              color: AppColors.primaryBlue,
                              width: 1.2,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // KHỐI 2: HÀNG 5 NÚT LỌC DẠNG VIÊN THUỐC (PILL TABS)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPillTab(label: 'Tất cả', tab: 'ALL'),
                    const SizedBox(width: 8),
                    _buildPillTab(label: 'Thu nhập', tab: 'INCOME'),
                    const SizedBox(width: 8),
                    _buildPillTab(label: 'Hũ Need', tab: 'NEED'),
                    const SizedBox(width: 8),
                    _buildPillTab(label: 'Hũ Want', tab: 'WANT'),
                    const SizedBox(width: 8),
                    _buildPillTab(label: 'Hũ Save', tab: 'SAVE'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // KHỐI 3: THẺ TRUY VẤN KHOẢNG THỜI GIAN
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

              // KHỐI 4: DANH SÁCH GIAO DỊCH NHÓM THEO NGÀY
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                )
              else if (filteredEntries.isEmpty)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
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
                        'Không có giao dịch nào trong khoảng thời gian này',
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
                _buildGroupedTransactionList(filteredEntries),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillTab({required String label, required String tab}) {
    final isSelected = _selectedTab == tab;

    return InkWell(
      onTap: () => _onPillTabChanged(tab),
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

  Widget _buildGroupedTransactionList(List<_HistoryEntry> entries) {
    final groups = _groupEntriesByDate(entries);

    return Column(
      children: groups.entries.map((entry) {
        final dateKey = entry.key;
        final list = entry.value;

        // Tính tổng tiền thu và chi trong ngày
        double dayIncome = 0;
        double dayExpense = 0;
        for (final item in list) {
          if (item.isIncome) {
            dayIncome += item.amount;
          } else {
            dayExpense += item.amount;
          }
        }

        String summaryText = '${list.length} giao dịch';
        if (dayIncome > 0 && dayExpense > 0) {
          summaryText =
              '${list.length} GD (+${CurrencyFormatter.format(dayIncome)} / -${CurrencyFormatter.format(dayExpense)})';
        } else if (dayIncome > 0) {
          summaryText =
              '${list.length} GD (+${CurrencyFormatter.format(dayIncome)})';
        } else if (dayExpense > 0) {
          summaryText =
              '${list.length} GD (-${CurrencyFormatter.format(dayExpense)})';
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    Flexible(
                      child: Text(
                        summaryText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
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
                  final item = list[index];
                  final timeStr = DateFormat('HH:mm').format(item.date);

                  if (item.isIncome) {
                    // Giao dịch THU NHẬP
                    final targetJar = item.jarType;
                    String jarText;
                    if (targetJar == 'ALL' || targetJar.isEmpty) {
                      jarText = 'Phân bổ 3 hũ • $timeStr';
                    } else {
                      jarText = 'Hũ $targetJar • $timeStr';
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          // Icon tải xuống / mũi tên xuống màu xanh lá
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.iconBackgroundGray,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.south_west_rounded,
                              color: AppColors.successGreen,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Ở giữa: TIỀN VÀO • Thu nhập, tiêu đề, hũ & giờ
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'TIỀN VÀO • Thu nhập',
                                  style: TextStyle(
                                    color: AppColors.successGreen,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
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
                                const SizedBox(height: 2),
                                Text(
                                  jarText,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Bên phải: Số tiền màu xanh lá & Icon Thùng rác
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '+${CurrencyFormatter.format(item.amount)}',
                                style: const TextStyle(
                                  color: AppColors.successGreen,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () => _handleDeleteIncome(item.raw),
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
                  } else {
                    // Giao dịch CHI TIÊU
                    final category = item.category ?? 'Khác';

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          // Icon mũi tên lên màu xanh MB Bank
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

                          // Ở giữa: TIỀN RA • Category, tiêu đề, hũ & giờ
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
                                  item.title,
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
                                  'Hũ ${item.jarType} • $timeStr',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Bên phải: Số tiền âm màu đỏ & Icon Thùng rác
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '-${CurrencyFormatter.format(item.amount)}',
                                style: const TextStyle(
                                  color: AppColors.errorRed,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () => _handleDeleteExpense(item.raw),
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
                  }
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

