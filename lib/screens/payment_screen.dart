import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/app_settings.dart';
import '../models/jar.dart';
import '../services/moneda_service.dart';

/// Màn hình Thanh toán chi tiêu (chuẩn phong cách MB Bank)
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final MonedaService _monedaService = MonedaService();

  // Mặc định chọn hũ NEED
  String _selectedJarType = 'NEED';

  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  final FocusNode _amountFocusNode = FocusNode();

  AppSettings? _settings;
  Map<String, Jar> _jars = {};
  List<String> _categorySuggestions = [];
  List<String> _titleSuggestions = [];

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showCategoryDropdown = false;
  bool _showTitleDropdown = false;

  double get _currentAmount =>
      CurrencyFormatter.parseRawAmount(_amountController.text);

  double get _currentJarBalance =>
      _jars[_selectedJarType]?.balance ?? 0.0;

  bool get _isExceedingBalance {
    return _currentAmount > 0 && _currentAmount > _currentJarBalance;
  }

  bool get _canSubmit {
    return _categoryController.text.trim().isNotEmpty &&
        _currentAmount > 0 &&
        _titleController.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _categoryController.addListener(() => setState(() {}));
    _amountController.addListener(() => setState(() {}));
    _titleController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    _titleController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        _monedaService.getAppSettings(),
        _monedaService.getJars(),
        _monedaService.getExpenseCategorySuggestions(),
        _monedaService.getExpenseTitleSuggestions(),
      ]);

      if (!mounted) return;
      setState(() {
        _settings = results[0] as AppSettings;
        _jars = results[1] as Map<String, Jar>;
        _categorySuggestions = results[2] as List<String>;
        _titleSuggestions = results[3] as List<String>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openJarSelectorBottomSheet() {
    final needRatio = _settings?.needRatio ?? 50;
    final wantRatio = _settings?.wantRatio ?? 30;
    final saveRatio = _settings?.saveRatio ?? 20;

    final needBalance = _jars['NEED']?.balance ?? 0.0;
    final wantBalance = _jars['WANT']?.balance ?? 0.0;
    final saveBalance = _jars['SAVE']?.balance ?? 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chọn nguồn chi tiêu',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const Divider(color: AppColors.borderGray, height: 16),
              const SizedBox(height: 8),

              // Option 1: NEED
              _buildJarRadioOption(
                value: 'NEED',
                title: 'Hũ NEED ($needRatio%)',
                subtitle:
                    'Số dư: ${CurrencyFormatter.format(needBalance)}',
                isSelected: _selectedJarType == 'NEED',
                onTap: () {
                  setState(() => _selectedJarType = 'NEED');
                  Navigator.pop(context);
                },
              ),

              // Option 2: WANT
              _buildJarRadioOption(
                value: 'WANT',
                title: 'Hũ WANT ($wantRatio%)',
                subtitle:
                    'Số dư: ${CurrencyFormatter.format(wantBalance)}',
                isSelected: _selectedJarType == 'WANT',
                onTap: () {
                  setState(() => _selectedJarType = 'WANT');
                  Navigator.pop(context);
                },
              ),

              // Option 3: SAVE
              _buildJarRadioOption(
                value: 'SAVE',
                title: 'Hũ SAVE ($saveRatio%)',
                subtitle:
                    'Số dư: ${CurrencyFormatter.format(saveBalance)}',
                isSelected: _selectedJarType == 'SAVE',
                onTap: () {
                  setState(() => _selectedJarType = 'SAVE');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJarRadioOption({
    required String value,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primaryBlue : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 14.5,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
    );
  }

  Future<void> _handleSubmit() async {
    if (!_canSubmit || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    final amount = _currentAmount;
    final category = _categoryController.text.trim();
    final title = _titleController.text.trim();
    final jarType = _selectedJarType;

    try {
      await _monedaService.addExpense(
        jarType: jarType,
        category: category,
        amount: amount,
        title: title,
      );

      if (!mounted) return;
      _showSuccessDialog(
        amount: amount,
        jarType: jarType,
        category: category,
        title: title,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi thanh toán: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSuccessDialog({
    required double amount,
    required String jarType,
    required String category,
    required String title,
  }) {
    final dateStr = DateFormat('dd/MM/yyyy • HH:mm').format(DateTime.now());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dấu tích xanh
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.successGreen,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 14),

                const Text(
                  'Thanh toán thành công',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),

                // Số tiền trừ
                Text(
                  '-${CurrencyFormatter.format(amount)}',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 20),

                // Chi tiết giao dịch
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGray,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.borderGray,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildReceiptRow('Loại giao dịch', 'Chi tiêu'),
                      const Divider(color: AppColors.borderGray, height: 16),
                      _buildReceiptRow('Hũ tài khoản', 'Hũ $jarType'),
                      const Divider(color: AppColors.borderGray, height: 16),
                      _buildReceiptRow('Danh mục', category),
                      const Divider(color: AppColors.borderGray, height: 16),
                      _buildReceiptRow('Nội dung', title),
                      const Divider(color: AppColors.borderGray, height: 16),
                      _buildReceiptRow('Thời gian', dateStr),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Nút Về trang chủ
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext); // Đóng dialog
                      Navigator.pop(context, true); // Về trang chủ với flag reload
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Về trang chủ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12.5,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }

    final needRatio = _settings?.needRatio ?? 50;
    final wantRatio = _settings?.wantRatio ?? 30;
    final saveRatio = _settings?.saveRatio ?? 20;

    int currentRatio = needRatio;
    if (_selectedJarType == 'WANT') currentRatio = wantRatio;
    if (_selectedJarType == 'SAVE') currentRatio = saveRatio;

    // Lọc gợi ý Danh mục
    final catQuery = _categoryController.text.trim().toLowerCase();
    final filteredCategories = catQuery.isEmpty
        ? _categorySuggestions
        : _categorySuggestions
            .where((item) => item.toLowerCase().contains(catQuery))
            .toList();

    // Lọc gợi ý Nội dung
    final titleQuery = _titleController.text.trim().toLowerCase();
    final filteredTitles = titleQuery.isEmpty
        ? _titleSuggestions
        : _titleSuggestions
            .where((item) => item.toLowerCase().contains(titleQuery))
            .toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      // Top Bar nền trắng
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
          'Thanh toán chi tiêu',
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
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
        ],
      ),

      // Thanh 2 nút cố định ở đáy màn hình
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(
            top: BorderSide(
              color: AppColors.borderGray,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Nút Quay lại
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      side: const BorderSide(
                        color: AppColors.primaryBlue,
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Quay lại',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Nút Tiếp tục (ràng buộc trạng thái)
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _canSubmit && !_isSubmitting
                        ? _handleSubmit
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      disabledBackgroundColor: AppColors.disabledBlue,
                      foregroundColor: AppColors.white,
                      disabledForegroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Text(
                            'Tiếp tục',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TRƯỜNG 1: NGUỒN CHI TIÊU
            const Text(
              'Nguồn chi tiêu',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),

            InkWell(
              onTap: _openJarSelectorBottomSheet,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.borderGray,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HŨ $_selectedJarType ($currentRatio%)',
                            style: const TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Số dư: ${CurrencyFormatter.format(_currentJarBalance)}',
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primaryBlue,
                      size: 26,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // TRƯỜNG 2: DANH MỤC CHI TIÊU
            const Text(
              'Danh mục chi tiêu',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.borderGray,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _categoryController,
                decoration: InputDecoration(
                  hintText: 'Chọn hoặc nhập danh mục (VD: Ăn uống, Mua sắm...)',
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_categoryController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Icons.cancel_rounded,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                          onPressed: () {
                            _categoryController.clear();
                          },
                        ),
                      IconButton(
                        icon: Icon(
                          _showCategoryDropdown
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.primaryBlue,
                          size: 24,
                        ),
                        onPressed: () {
                          setState(() {
                            _showCategoryDropdown = !_showCategoryDropdown;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Dropdown gợi ý Danh mục chi tiêu
            if (_showCategoryDropdown && filteredCategories.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(vertical: 6),
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
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: filteredCategories.map((cat) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _categoryController.text = cat;
                          _showCategoryDropdown = false;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.category_outlined,
                              size: 18,
                              color: AppColors.secondaryBlue,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                cat,
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 20),

            // TRƯỜNG 3: SỐ TIỀN
            const Text(
              'Số tiền',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isExceedingBalance
                      ? AppColors.errorRed
                      : AppColors.borderGray,
                  width: _isExceedingBalance ? 1.5 : 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TextField(
                    controller: _amountController,
                    focusNode: _amountFocusNode,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [CurrencyInputFormatter()],
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: const InputDecoration(
                      hintText: '0 VND',
                      hintStyle: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                  if (_amountController.text.isNotEmpty)
                    Positioned(
                      right: 0,
                      child: IconButton(
                        icon: const Icon(
                          Icons.cancel_rounded,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        onPressed: () {
                          _amountController.clear();
                        },
                      ),
                    ),
                ],
              ),
            ),

            // Dòng cảnh báo nếu số tiền vượt quá số dư hiện có trong hũ
            if (_isExceedingBalance)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.errorRed,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Số dư trong Hũ $_selectedJarType không đủ (${CurrencyFormatter.format(_currentJarBalance)})',
                        style: const TextStyle(
                          color: AppColors.errorRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // TRƯỜNG 4: NỘI DUNG CHI TIẾT
            const Text(
              'Nội dung chi tiết',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.borderGray,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'VD: Cơm trưa, Nạp 4G Viettel, Xăng xe...',
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_titleController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Icons.cancel_rounded,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                          onPressed: () {
                            _titleController.clear();
                          },
                        ),
                      IconButton(
                        icon: Icon(
                          _showTitleDropdown
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.primaryBlue,
                          size: 24,
                        ),
                        onPressed: () {
                          setState(() {
                            _showTitleDropdown = !_showTitleDropdown;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Dropdown gợi ý Nội dung chi tiết
            if (_showTitleDropdown && filteredTitles.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(vertical: 6),
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
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: filteredTitles.map((title) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _titleController.text = title;
                          _showTitleDropdown = false;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.history_rounded,
                              size: 18,
                              color: AppColors.secondaryBlue,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

