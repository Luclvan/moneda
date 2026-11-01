import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../services/moneda_service.dart';
import '../widgets/mb_feedback.dart';
import 'receive_money_screen.dart';

/// Màn hình Chi tiết thu nhập (chuẩn phong cách MB Bank)
class IncomeDetailScreen extends StatefulWidget {
  const IncomeDetailScreen({super.key});

  @override
  State<IncomeDetailScreen> createState() => _IncomeDetailScreenState();
}

class _IncomeDetailScreenState extends State<IncomeDetailScreen> {
  final MonedaService _monedaService = MonedaService();

  late DateTime _fromDate;
  late DateTime _toDate;

  bool _isLoading = true;
  List<Map<String, dynamic>> _incomes = [];

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    // Mặc định từ ngày 01 của tháng hiện tại đến ngày cuối tháng
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = DateTime(now.year, now.month + 1, 0);

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _monedaService.getIncomes(
        fromDate: _fromDate,
        toDate: _toDate,
      );

      if (!mounted) return;
      setState(() {
        _incomes = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
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

  void _navigateToReceiveMoney() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReceiveMoneyScreen(),
      ),
    );
    if (result == true || mounted) {
      _loadData();
    }
  }

  // Nhóm danh sách giao dịch theo ngày (dd/MM/yyyy)
  Map<String, List<Map<String, dynamic>>> _groupIncomesByDate() {
    final Map<String, List<Map<String, dynamic>>> map = {};
    for (final inc in _incomes) {
      final dateRaw = inc['transaction_date'];
      final date = dateRaw != null
          ? DateTime.tryParse(dateRaw.toString())?.toLocal() ?? DateTime.now()
          : DateTime.now();
      final key = DateFormat('dd/MM/yyyy').format(date);
      if (!map.containsKey(key)) {
        map[key] = [];
      }
      map[key]!.add(inc);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    // Tính tổng thu nhập trong khoảng truy vấn
    double totalIncome = 0;
    for (final inc in _incomes) {
      totalIncome += (inc['amount'] as num?)?.toDouble() ?? 0.0;
    }

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
          'Chi tiết thu nhập',
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
              // KHỐI 1: THẺ TỔNG THU NHẬP ĐẦU TRANG
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
                          const Text(
                            'Tổng thu nhập trong tháng',
                            style: TextStyle(
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
                              '+${CurrencyFormatter.format(totalIncome)}',
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Nút hình viên thuốc "Nhận tiền"
                    ElevatedButton.icon(
                      onPressed: _navigateToReceiveMoney,
                      icon: const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 16,
                        color: AppColors.white,
                      ),
                      label: const Text(
                        'Nhận tiền',
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

              const SizedBox(height: 16),

              // KHỐI 2: CARD TRUY VẤN GIAO DỊCH
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

              // KHỐI 3: DANH SÁCH LỊCH SỬ THU NHẬP GOM NHÓM THEO NGÀY
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                )
              else if (_incomes.isEmpty)
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
                        'Không có giao dịch thu nhập nào trong khoảng thời gian này',
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
                _buildGroupedIncomeList(),
            ],
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

  Widget _buildGroupedIncomeList() {
    final groups = _groupIncomesByDate();

    return Column(
      children: groups.entries.map((entry) {
        final dateKey = entry.key;
        final list = entry.value;

        // Tính tổng tiền thu của ngày đó
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
                      '${list.length} giao dịch (+${CurrencyFormatter.format(dayTotal)})',
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
                  final income = list[index];
                  final sourceName = income['source_name'] ?? 'Khoản thu';
                  final targetJar = income['target_jar'] as String?;
                  final amount = (income['amount'] as num?)?.toDouble() ?? 0.0;

                  final dateRaw = income['transaction_date'];
                  final date = dateRaw != null
                      ? DateTime.tryParse(dateRaw.toString())?.toLocal() ?? DateTime.now()
                      : DateTime.now();
                  final timeStr = DateFormat('HH:mm').format(date);

                  String jarText;
                  if (targetJar == null || targetJar == 'ALL' || targetJar.isEmpty) {
                    jarText = 'Phân bổ 3 hũ • $timeStr';
                  } else {
                    jarText = 'Hũ $targetJar • $timeStr';
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        // Ô vuông bo góc 40x40 nền #F1F5F9, icon mũi tên chéo xuống
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.iconBackgroundGray,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.south_west_rounded,
                            color: AppColors.secondaryBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Ở giữa: TIỀN VÀO, source_name, Hũ & Giờ
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TIỀN VÀO',
                                style: TextStyle(
                                  color: AppColors.secondaryBlue,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                sourceName,
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

                        // Bên phải: Số tiền & Icon thùng rác
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '+${CurrencyFormatter.format(amount)}',
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () => _handleDeleteIncome(income),
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

