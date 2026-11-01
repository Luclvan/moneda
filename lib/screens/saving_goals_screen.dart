import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/app_settings.dart';
import '../models/jar.dart';
import '../models/saving_goal.dart';
import '../services/moneda_service.dart';
import '../widgets/moneda_bottom_bar.dart';
import 'payment_screen.dart';
import 'receive_money_screen.dart';
import 'report_screen.dart';

/// Màn hình Mục tiêu tiết kiệm (Kịch bản 7)
class SavingGoalsScreen extends StatefulWidget {
  const SavingGoalsScreen({super.key});

  @override
  State<SavingGoalsScreen> createState() => _SavingGoalsScreenState();
}

class _SavingGoalsScreenState extends State<SavingGoalsScreen> {
  final MonedaService _monedaService = MonedaService();

  bool _isLoading = true;
  AppSettings? _settings;
  Map<String, Jar> _jars = {};
  List<SavingGoal> _goals = [];

  double get _saveBalance => _jars['SAVE']?.balance ?? 0.0;
  int get _saveRatio => _settings?.saveRatio ?? 20;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _monedaService.getAppSettings(),
        _monedaService.getJars(),
        _monedaService.getSavingGoals(),
      ]);

      if (!mounted) return;

      final rawGoals = results[2] as List<Map<String, dynamic>>;
      setState(() {
        _settings = results[0] as AppSettings;
        _jars = results[1] as Map<String, Jar>;
        _goals = rawGoals.map((json) => SavingGoal.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading saving goals data: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Mở Modal Thêm hoặc Sửa mục tiêu tiết kiệm
  Future<void> _openAddOrEditGoalModal({SavingGoal? goal}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _AddOrEditGoalDialog(
          goal: goal,
          onSave: (goalName, targetAmount, deadline) async {
            await _monedaService.createOrUpdateSavingGoal(
              id: goal?.id,
              goalName: goalName,
              targetAmount: targetAmount,
              deadline: deadline,
            );
          },
        );
      },
    );

    if (result == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            goal == null
                ? 'Đã tạo mục tiêu tiết kiệm mới thành công!'
                : 'Đã cập nhật mục tiêu "${goal.goalName}" thành công!',
          ),
          backgroundColor: AppColors.successGreen,
        ),
      );
      _loadData();
    }
  }

  /// Mở Modal Chuyển tiền từ Hũ Save vào Mục tiêu
  Future<void> _openTransferToGoalModal({SavingGoal? preSelectedGoal}) async {
    if (_goals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng tạo ít nhất 1 mục tiêu trước khi chuyển tiền!'),
          backgroundColor: AppColors.primaryBlue,
        ),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _TransferToGoalDialog(
          goals: _goals,
          saveBalance: _saveBalance,
          saveRatio: _saveRatio,
          initialGoal: preSelectedGoal,
          onTransfer: (goalId, goalName, amount) async {
            await _monedaService.transferSaveToGoal(
              goalId: goalId,
              goalName: goalName,
              amount: amount,
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      final amount = result['amount'] as double;
      final goalName = result['goalName'] as String;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã chuyển thành công ${CurrencyFormatter.format(amount)} vào mục tiêu "$goalName"!',
          ),
          backgroundColor: AppColors.successGreen,
          duration: const Duration(seconds: 3),
        ),
      );
      _loadData();
    }
  }

  /// Xác nhận xóa mục tiêu
  Future<void> _handleDeleteGoal(SavingGoal goal) async {
    final hasSavings = goal.currentAmount > 0;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Xác nhận xóa mục tiêu',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            hasSavings
                ? 'Mục tiêu "${goal.goalName}" đang có ${CurrencyFormatter.format(goal.currentAmount)} đã tích lũy.\nKhi xóa, toàn bộ số tiền này sẽ được hoàn lại vào Hũ SAVE. Bạn có chắc chắn muốn xóa?'
                : 'Bạn có chắc chắn muốn xóa mục tiêu "${goal.goalName}"?',
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
        await _monedaService.deleteSavingGoal(goal.toJson());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              hasSavings
                  ? 'Đã xóa mục tiêu và hoàn trả ${CurrencyFormatter.format(goal.currentAmount)} vào Hũ SAVE thành công.'
                  : 'Đã xóa mục tiêu "${goal.goalName}" thành công.',
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
        _loadData();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa mục tiêu: $e'),
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
        builder: (context) => const PaymentScreen(initialJarType: 'SAVE'),
      ),
    );
    if (mounted) {
      _loadData();
    }
  }

  void _navigateToReceiveMoney() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const ReceiveMoneyScreen(initialTargetJar: 'SAVE'),
      ),
    );
    if (mounted) {
      _loadData();
    }
  }

  void _navigateToReport() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReportScreen(),
      ),
    );
    if (mounted) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Mục tiêu tiết kiệm',
          style: TextStyle(
            color: AppColors.primaryBlue,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_rounded,
              color: AppColors.primaryBlue,
              size: 28,
            ),
            onPressed: () => _openAddOrEditGoalModal(),
            tooltip: 'Thêm mục tiêu',
          ),
          const SizedBox(width: 4),
        ],
      ),

      // Thanh Bottom Bar 5 nút cố định ở đáy (Tab Mục tiêu index 4 active)
      bottomNavigationBar: MonedaBottomBar(
        currentIndex: 4,
        onTap: (index) {
          if (index == 0) {
            Navigator.popUntil(context, (r) => r.isFirst);
          }
        },
        onReportTap: _navigateToReport,
        onPaymentTap: _navigateToPayment,
        onReceiveTap: _navigateToReceiveMoney,
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
              // KHỐI 1: THẺ NGUỒN TÍCH LŨY: HŨ SAVE (GỌN TRÊN 1 THẺ NGANG)
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
                    // Ô vuông 44x44 icon heo đất
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.iconBackgroundGray,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.savings_rounded,
                        color: AppColors.secondaryBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Tên nguồn tích lũy & số dư khả dụng
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nguồn tích lũy: HŨ SAVE ($_saveRatio%)',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              CurrencyFormatter.format(_saveBalance),
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Nút viên thuốc màu xanh biển đậm "↓ Chuyển vào mục tiêu"
                    ElevatedButton(
                      onPressed: () => _openTransferToGoalModal(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_downward_rounded,
                            size: 14,
                            color: AppColors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Chuyển vào mục tiêu',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // KHỐI 2: TIÊU ĐỀ DANH SÁCH & DANH SÁCH CÁC THẺ MỤC TIÊU
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Danh sách mục tiêu',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_goals.length} mục tiêu đang thực hiện',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => _openAddOrEditGoalModal(),
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Text(
                        '+ Thêm mới',
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

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                )
              else if (_goals.isEmpty)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.borderGray,
                      width: 1,
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.track_changes_outlined,
                        size: 44,
                        color: AppColors.textMuted,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Chưa có mục tiêu tiết kiệm nào',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Hãy bấm "+ Thêm mới" để bắt đầu tích lũy cho ước mơ của bạn.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _goals.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final goal = _goals[index];
                    return _buildGoalCard(goal);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Thẻ hiển thị một mục tiêu tiết kiệm
  Widget _buildGoalCard(SavingGoal goal) {
    return Container(
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
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hàng 1: Tên mục tiêu + Hạn chót (nếu có)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  goal.goalName,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (goal.formattedDeadline != null) ...[
                const SizedBox(width: 8),
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
                  child: Text(
                    'Hạn: ${goal.formattedDeadline}',
                    style: const TextStyle(
                      color: AppColors.secondaryBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 10),

          // Hàng 2: Số tiền đã tích lũy / Số tiền mục tiêu (Bên trái)
          // & Phần trăm hoàn thành (Bên phải)
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
                        text: CurrencyFormatter.format(goal.currentAmount)
                            .replaceAll(' VND', ''),
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 15,
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
                        text: CurrencyFormatter.format(goal.targetAmount),
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
                '${goal.progressPercent}%',
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Hàng 3: Thanh tiến trình ngang cố định màu #1E40AF
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 6,
              backgroundColor: AppColors.borderGray,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryBlue,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Hàng 4: 3 nút nhỏ căn phải (Nạp thêm, Sửa, Xóa)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Nút 1: Nạp thêm
              OutlinedButton.icon(
                onPressed: () =>
                    _openTransferToGoalModal(preSelectedGoal: goal),
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  size: 14,
                  color: AppColors.secondaryBlue,
                ),
                label: const Text(
                  'Nạp thêm',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryBlue,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFF6FF),
                  side: const BorderSide(
                    color: Color(0xFFBFDBFE),
                    width: 0.8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Nút 2: Sửa
              OutlinedButton.icon(
                onPressed: () => _openAddOrEditGoalModal(goal: goal),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 14,
                  color: AppColors.textDark,
                ),
                label: const Text(
                  'Sửa',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.white,
                  side: const BorderSide(
                    color: AppColors.borderGray,
                    width: 0.8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Nút 3: Xóa
              OutlinedButton.icon(
                onPressed: () => _handleDeleteGoal(goal),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 14,
                  color: AppColors.errorRed,
                ),
                label: const Text(
                  'Xóa',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.errorRed,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.white,
                  side: const BorderSide(
                    color: Color(0xFFFECACA),
                    width: 0.8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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

/// Modal Thêm / Sửa mục tiêu tiết kiệm
class _AddOrEditGoalDialog extends StatefulWidget {
  final SavingGoal? goal;
  final Future<void> Function(
    String goalName,
    double targetAmount,
    DateTime? deadline,
  ) onSave;

  const _AddOrEditGoalDialog({
    this.goal,
    required this.onSave,
  });

  @override
  State<_AddOrEditGoalDialog> createState() => _AddOrEditGoalDialogState();
}

class _AddOrEditGoalDialogState extends State<_AddOrEditGoalDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  DateTime? _selectedDeadline;
  bool _isSaving = false;

  bool get _isEdit => widget.goal != null;

  double get _targetAmount =>
      CurrencyFormatter.parseRawAmount(_amountController.text);

  bool get _canSubmit {
    return _nameController.text.trim().isNotEmpty && _targetAmount > 0;
  }

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _nameController.text = widget.goal!.goalName;
      _amountController.text =
          CurrencyFormatter.format(widget.goal!.targetAmount);
      _selectedDeadline = widget.goal!.deadline;
    }

    _nameController.addListener(() => setState(() {}));
    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? now.add(const Duration(days: 90)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 10)),
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

    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_canSubmit || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSave(
        _nameController.text.trim(),
        _targetAmount,
        _selectedDeadline,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi lưu mục tiêu: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEdit ? 'Sửa mục tiêu' : 'Thêm mục tiêu tiết kiệm',
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textMuted,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Trường 1: Tên mục tiêu
            const Text(
              'Tên mục tiêu *',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Ví dụ: Mua MacBook Pro, Quỹ khẩn cấp...',
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13.5,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                filled: true,
                fillColor: AppColors.backgroundGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderGray),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderGray),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primaryBlue,
                    width: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Trường 2: Số tiền mục tiêu
            const Text(
              'Số tiền mục tiêu *',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                hintText: '0 VND',
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                filled: true,
                fillColor: AppColors.backgroundGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderGray),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderGray),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primaryBlue,
                    width: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Trường 3: Ngày dự kiến hoàn thành
            const Text(
              'Ngày dự kiến hoàn thành (Hạn chót)',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDeadline,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGray,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderGray),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: AppColors.secondaryBlue,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedDeadline != null
                            ? DateFormat('dd/MM/yyyy')
                                .format(_selectedDeadline!)
                            : 'Chọn ngày (Không bắt buộc)',
                        style: TextStyle(
                          color: _selectedDeadline != null
                              ? AppColors.textDark
                              : AppColors.textMuted,
                          fontSize: 13.5,
                          fontWeight: _selectedDeadline != null
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (_selectedDeadline != null)
                      InkWell(
                        onTap: () {
                          setState(() {
                            _selectedDeadline = null;
                          });
                        },
                        child: const Icon(
                          Icons.clear_rounded,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 2 Nút bấm đáy: Hủy & Lưu
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      side: const BorderSide(color: AppColors.primaryBlue),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _canSubmit && !_isSaving ? _handleSave : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      disabledBackgroundColor: AppColors.disabledBlue,
                      foregroundColor: AppColors.white,
                      disabledForegroundColor: AppColors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Text(
                            'Lưu mục tiêu',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal Chuyển tiền vào mục tiêu tiết kiệm
class _TransferToGoalDialog extends StatefulWidget {
  final List<SavingGoal> goals;
  final double saveBalance;
  final int saveRatio;
  final SavingGoal? initialGoal;
  final Future<void> Function(int goalId, String goalName, double amount)
      onTransfer;

  const _TransferToGoalDialog({
    required this.goals,
    required this.saveBalance,
    required this.saveRatio,
    this.initialGoal,
    required this.onTransfer,
  });

  @override
  State<_TransferToGoalDialog> createState() => _TransferToGoalDialogState();
}

class _TransferToGoalDialogState extends State<_TransferToGoalDialog> {
  final TextEditingController _amountController = TextEditingController();

  SavingGoal? _selectedGoal;
  bool _isSubmitting = false;

  double get _amount =>
      CurrencyFormatter.parseRawAmount(_amountController.text);

  bool get _isExceeded => _amount > widget.saveBalance;

  bool get _canSubmit {
    return _selectedGoal != null &&
        _amount > 0 &&
        !_isExceeded &&
        widget.saveBalance > 0;
  }

  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.initialGoal ??
        (widget.goals.isNotEmpty ? widget.goals.first : null);
    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  /// Mở Modal Bottom Sheet chọn mục tiêu nhận tiền
  Future<void> _showSelectGoalBottomSheet() async {
    final picked = await showModalBottomSheet<SavingGoal>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Chọn mục tiêu nhận tiền',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.borderGray),
                ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.goals.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: AppColors.borderGray),
                  itemBuilder: (context, index) {
                    final item = widget.goals[index];
                    final isChecked = item.id == _selectedGoal?.id;

                    return ListTile(
                      onTap: () => Navigator.pop(sheetContext, item),
                      leading: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isChecked
                                ? AppColors.primaryBlue
                                : AppColors.saveGray,
                            width: isChecked ? 6 : 1.5,
                          ),
                        ),
                      ),
                      title: Text(
                        item.goalName,
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 14.5,
                          fontWeight:
                              isChecked ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Đã tích lũy: ${CurrencyFormatter.format(item.currentAmount)} / ${CurrencyFormatter.format(item.targetAmount)} (${item.progressPercent}%)',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      trailing: isChecked
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primaryBlue,
                              size: 20,
                            )
                          : null,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedGoal = picked;
      });
    }
  }

  void _applyQuickAmount(double amount) {
    final finalAmount = amount > widget.saveBalance ? widget.saveBalance : amount;
    _amountController.text = CurrencyFormatter.format(finalAmount);
  }

  Future<void> _handleSubmit() async {
    if (!_canSubmit || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onTransfer(
        _selectedGoal!.id,
        _selectedGoal!.goalName,
        _amount,
      );
      if (!mounted) return;
      Navigator.pop(context, {
        'amount': _amount,
        'goalName': _selectedGoal!.goalName,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi chuyển tiền: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chuyển tiền vào mục tiêu',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textMuted,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Trường 1: Nguồn tiền trích (Cố định Hũ SAVE)
            const Text(
              'Nguồn tiền trích',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundGray,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderGray),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderGray),
                    ),
                    child: const Icon(
                      Icons.savings_rounded,
                      color: AppColors.secondaryBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'HŨ SAVE (${widget.saveRatio}%)',
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.borderGray,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Cố định',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Số dư khả dụng: ${CurrencyFormatter.format(widget.saveBalance)}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Trường 2: Mục tiêu nhận tiền
            const Text(
              'Mục tiêu nhận tiền',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _showSelectGoalBottomSheet,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.borderGray,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.track_changes_rounded,
                        color: AppColors.primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedGoal?.goalName ?? 'Chưa chọn mục tiêu',
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
                            _selectedGoal != null
                                ? 'Đã tích lũy: ${CurrencyFormatter.format(_selectedGoal!.currentAmount)} / ${CurrencyFormatter.format(_selectedGoal!.targetAmount)}'
                                : 'Nhấp để chọn mục tiêu',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Trường 3: Số tiền nạp
            const Text(
              'Số tiền nạp',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                hintText: '0 VND',
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                filled: true,
                fillColor: AppColors.backgroundGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderGray),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderGray),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primaryBlue,
                    width: 1.5,
                  ),
                ),
              ),
            ),

            // Các nút gợi ý số tiền nhanh
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickAmountChip('50k', 50000),
                  const SizedBox(width: 6),
                  _buildQuickAmountChip('100k', 100000),
                  const SizedBox(width: 6),
                  _buildQuickAmountChip('200k', 200000),
                  const SizedBox(width: 6),
                  _buildQuickAmountChip('500k', 500000),
                  const SizedBox(width: 6),
                  ActionChip(
                    label: const Text(
                      'Tất cả số dư Save',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: const Color(0xFFEFF6FF),
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                    onPressed: () => _applyQuickAmount(widget.saveBalance),
                  ),
                ],
              ),
            ),

            // Cảnh báo nếu số tiền vượt quá số dư Hũ Save
            if (_isExceeded) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.errorRed,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Số dư trong Hũ SAVE không đủ (Khả dụng: ${CurrencyFormatter.format(widget.saveBalance)})',
                      style: const TextStyle(
                        color: AppColors.errorRed,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // 2 Nút bấm đáy: Đóng & Xác nhận chuyển
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textDark,
                      side: const BorderSide(color: AppColors.borderGray),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Đóng',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _canSubmit && !_isSubmitting ? _handleSubmit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      disabledBackgroundColor: AppColors.disabledBlue,
                      foregroundColor: AppColors.white,
                      disabledForegroundColor: AppColors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Text(
                            'Xác nhận chuyển',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAmountChip(String label, double amount) {
    return ActionChip(
      label: Text(
        '+$label',
        style: const TextStyle(
          fontSize: 11.5,
          color: AppColors.textDark,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: AppColors.backgroundGray,
      side: const BorderSide(color: AppColors.borderGray),
      padding: EdgeInsets.zero,
      onPressed: () => _applyQuickAmount(amount),
    );
  }
}
