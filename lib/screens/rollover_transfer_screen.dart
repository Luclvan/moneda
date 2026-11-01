import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/jar.dart';
import '../services/moneda_service.dart';
import '../widgets/mb_feedback.dart';

/// Màn hình Kết chuyển sang Hũ Save (chuẩn MB Bank Style)
class RolloverTransferScreen extends StatefulWidget {
  const RolloverTransferScreen({super.key});

  @override
  State<RolloverTransferScreen> createState() => _RolloverTransferScreenState();
}

class _RolloverTransferScreenState extends State<RolloverTransferScreen> {
  final MonedaService _monedaService = MonedaService();

  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, Jar> _jars = {};

  bool _includeNeed = true;
  bool _includeWant = true;

  double get _needBalance => _jars['NEED']?.balance ?? 0.0;
  double get _wantBalance => _jars['WANT']?.balance ?? 0.0;

  bool get _canSelectNeed => _needBalance > 0;
  bool get _canSelectWant => _wantBalance > 0;

  int get _eligibleCount => (_canSelectNeed ? 1 : 0) + (_canSelectWant ? 1 : 0);
  int get _selectedCount =>
      (_includeNeed && _canSelectNeed ? 1 : 0) +
      (_includeWant && _canSelectWant ? 1 : 0);

  bool? get _allSelected {
    if (_eligibleCount == 0) return false;
    if (_selectedCount == _eligibleCount) return true;
    if (_selectedCount == 0) return false;
    return null; // tristate: chỉ chọn 1 trong 2
  }

  double get _totalToTransfer {
    double total = 0.0;
    if (_includeNeed && _canSelectNeed) total += _needBalance;
    if (_includeWant && _canSelectWant) total += _wantBalance;
    return total;
  }

  bool get _canSubmit =>
      _totalToTransfer > 0 &&
      ((_includeNeed && _canSelectNeed) || (_includeWant && _canSelectWant));

  @override
  void initState() {
    super.initState();
    if (_monedaService.hasHomeCache) {
      _jars = {
        for (var e in MonedaService.cachedJars!)
          (e['jar_type'] as String).toUpperCase(): Jar.fromJson(e)
      };
      _includeNeed = _canSelectNeed;
      _includeWant = _canSelectWant;
      _isLoading = false;
    }
    _loadJars();
  }

  Future<void> _loadJars() async {
    try {
      final jars = await _monedaService.getJars();
      if (!mounted) return;
      setState(() {
        _jars = jars;
        _includeNeed = _canSelectNeed;
        _includeWant = _canSelectWant;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleSelectAll() {
    if (_eligibleCount == 0) return;
    final current = _allSelected;
    setState(() {
      if (current == true) {
        _includeNeed = false;
        _includeWant = false;
      } else {
        if (_canSelectNeed) _includeNeed = true;
        if (_canSelectWant) _includeWant = true;
      }
    });
  }

  Future<void> _handleTransfer() async {
    if (!_canSubmit || _isSubmitting) return;

    final confirm = await showMbDeleteConfirmDialog(
      context: context,
      title: 'Xác nhận chuyển sang Save',
      message:
          'Toàn bộ số dư ${CurrencyFormatter.format(_totalToTransfer)} từ hũ đã chọn sẽ được chuyển sang Hũ SAVE và đưa số dư hũ đã chọn về 0 VND.',
      confirmText: 'Chuyển sang Save',
    );

    if (confirm != true) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _monedaService.transferSurplusToSave(
        includeNeed: _includeNeed && _canSelectNeed,
        includeWant: _includeWant && _canSelectWant,
      );

      if (!mounted) return;
      showMbTopToast(context, 'Đã chuyển tiền dư sang Hũ SAVE thành công');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      showMbTopToast(context, 'Lỗi khi chuyển tiền: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
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
          'Kết chuyển sang Hũ Save',
          style: TextStyle(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Khối tiêu đề câu hỏi
                  const Text(
                    'Bạn có muốn chuyển hết tiền dư của hũ nào sang Save?',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Chọn các hũ bạn muốn gom toàn bộ số dư hiện tại chuyển sang Hũ SAVE (Tiết kiệm).',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Checkbox tổng: Chọn tất cả các hũ
                  InkWell(
                    onTap: _eligibleCount > 0 ? _toggleSelectAll : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Row(
                        children: [
                          Checkbox(
                            tristate: true,
                            value: _allSelected,
                            onChanged: _eligibleCount > 0
                                ? (_) => _toggleSelectAll()
                                : null,
                            activeColor: AppColors.primaryBlue,
                            checkColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            side: const BorderSide(
                              color: AppColors.borderGray,
                              width: 1.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Chọn tất cả các hũ',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Thẻ Hũ NEED
                  _buildJarCard(
                    jarName: 'Hũ NEED (Thiết yếu)',
                    balance: _needBalance,
                    isSelected: _includeNeed && _canSelectNeed,
                    isEnabled: _canSelectNeed,
                    onTap: () {
                      if (_canSelectNeed) {
                        setState(() {
                          _includeNeed = !_includeNeed;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  // Thẻ Hũ WANT
                  _buildJarCard(
                    jarName: 'Hũ WANT (Mong muốn)',
                    balance: _wantBalance,
                    isSelected: _includeWant && _canSelectWant,
                    isEnabled: _canSelectWant,
                    onTap: () {
                      if (_canSelectWant) {
                        setState(() {
                          _includeWant = !_includeWant;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  // Thẻ thông tin tổng kết số tiền chuyển
                  if (_canSubmit)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFBFDBFE),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tổng tiền sẽ chuyển sang Hũ SAVE:',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  CurrencyFormatter.format(_totalToTransfer),
                                  style: const TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canSubmit && !_isSubmitting ? _handleTransfer : null,
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
                      'Chuyển sang Save',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJarCard({
    required String jarName,
    required double balance,
    required bool isSelected,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    final cardContent = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppColors.primaryBlue : AppColors.borderGray,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            onChanged: isEnabled ? (_) => onTap() : null,
            activeColor: AppColors.primaryBlue,
            checkColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            side: BorderSide(
              color: isSelected ? AppColors.primaryBlue : AppColors.borderGray,
              width: 1.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jarName,
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Số dư hiện tại: ${CurrencyFormatter.format(balance)}',
                  style: TextStyle(
                    color: balance > 0
                        ? (isSelected
                            ? AppColors.primaryBlue
                            : AppColors.textDark)
                        : AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!isEnabled) {
      return Opacity(
        opacity: 0.5,
        child: cardContent,
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: cardContent,
    );
  }
}

