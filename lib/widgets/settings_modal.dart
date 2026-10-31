import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/app_settings.dart';
import '../models/jar.dart';
import '../services/moneda_service.dart';

/// Modal Cài đặt Moneda (chuẩn phong cách MB Bank)
class SettingsModal extends StatefulWidget {
  final AppSettings settings;
  final Map<String, Jar> jars;
  final int initialTabIndex;

  const SettingsModal({
    super.key,
    required this.settings,
    required this.jars,
    this.initialTabIndex = 0,
  });

  /// Hàm tiện ích mở modal
  static Future<bool?> show(
    BuildContext context, {
    required AppSettings settings,
    required Map<String, Jar> jars,
    int initialTabIndex = 0,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => SettingsModal(
        settings: settings,
        jars: jars,
        initialTabIndex: initialTabIndex,
      ),
    );
  }

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  final MonedaService _monedaService = MonedaService();

  late int _currentTab;

  // State cho Tab 1: Cài đặt tỷ lệ 3 hũ
  late double _needRatio;
  late double _wantRatio;
  late double _saveRatio;
  bool _isSavingRatios = false;

  // State cho Tab 2: Chuyển tiền nội bộ
  String _fromJar = 'NEED';
  String _toJar = 'WANT';
  final TextEditingController _transferAmountController =
      TextEditingController();
  bool _isTransferring = false;

  int get _totalRatio =>
      (_needRatio + _wantRatio + _saveRatio).round();

  bool get _isRatioValid => _totalRatio == 100;

  double get _transferAmount =>
      CurrencyFormatter.parseRawAmount(_transferAmountController.text);

  double get _fromJarBalance =>
      widget.jars[_fromJar]?.balance ?? 0.0;

  bool get _canTransfer {
    return _fromJar != _toJar && _transferAmount > 0;
  }

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTabIndex;
    _needRatio = widget.settings.needRatio.toDouble();
    _wantRatio = widget.settings.wantRatio.toDouble();
    _saveRatio = widget.settings.saveRatio.toDouble();

    _transferAmountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _transferAmountController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveRatios() async {
    if (!_isRatioValid || _isSavingRatios) return;

    setState(() {
      _isSavingRatios = true;
    });

    try {
      await _monedaService.updateJarRatios(
        needRatio: _needRatio.round(),
        wantRatio: _wantRatio.round(),
        saveRatio: _saveRatio.round(),
      );

      if (!mounted) return;
      Navigator.pop(context, true); // Đóng modal và reload dữ liệu
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi cập nhật tỷ lệ: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingRatios = false;
        });
      }
    }
  }

  Future<void> _handleTransfer() async {
    if (!_canTransfer || _isTransferring) return;

    setState(() {
      _isTransferring = true;
    });

    try {
      await _monedaService.transferBetweenJars(
        fromJar: _fromJar,
        toJar: _toJar,
        amount: _transferAmount,
      );

      if (!mounted) return;
      Navigator.pop(context, true); // Đóng modal và reload dữ liệu
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi chuyển tiền nội bộ: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTransferring = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Tiêu đề + Nút X đóng
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cài đặt Moneda',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                      size: 22,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Thanh Tab chuyển đổi (2 Tabs)
              Row(
                children: [
                  Expanded(
                    child: _buildTabItem(
                      index: 0,
                      title: 'Cài đặt tỷ lệ 3 hũ',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTabItem(
                      index: 1,
                      title: 'Chuyển tiền nội bộ',
                    ),
                  ),
                ],
              ),

              const Divider(color: AppColors.borderGray, height: 20),

              // Nội dung của Tab được chọn
              Flexible(
                child: SingleChildScrollView(
                  child: _currentTab == 0
                      ? _buildTabRatiosContent()
                      : _buildTabTransferContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({required int index, required String title}) {
    final isSelected = _currentTab == index;

    return InkWell(
      onTap: () {
        setState(() {
          _currentTab = index;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primaryBlue
                      : AppColors.textMuted,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 2.5,
              width: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryBlue
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: CÀI ĐẶT TỶ LỆ 3 HŨ
  // ==========================================
  Widget _buildTabRatiosContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tổng tỷ lệ của 3 hũ bắt buộc phải bằng đúng 100%.',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 14),

        // 1. Slider Hũ Need
        _buildRatioSlider(
          name: 'Hũ Need (Thiết yếu)',
          ratio: _needRatio,
          color: AppColors.primaryBlue,
          onChanged: (val) {
            setState(() {
              _needRatio = val;
            });
          },
        ),
        const SizedBox(height: 10),

        // 2. Slider Hũ Want
        _buildRatioSlider(
          name: 'Hũ Want (Mong muốn)',
          ratio: _wantRatio,
          color: AppColors.lightBlue,
          onChanged: (val) {
            setState(() {
              _wantRatio = val;
            });
          },
        ),
        const SizedBox(height: 10),

        // 3. Slider Hũ Save
        _buildRatioSlider(
          name: 'Hũ Save (Tiết kiệm)',
          ratio: _saveRatio,
          color: AppColors.saveGray,
          onChanged: (val) {
            setState(() {
              _saveRatio = val;
            });
          },
        ),
        const SizedBox(height: 14),

        // Khung hiển thị Tổng tỷ lệ
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundGray,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isRatioValid
                  ? AppColors.borderGray
                  : AppColors.errorRed.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng tỷ lệ:',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _isRatioValid
                    ? '100% (Hợp lệ)'
                    : '$_totalRatio% (Chưa bằng 100%)',
                style: TextStyle(
                  color: _isRatioValid
                      ? AppColors.primaryBlue
                      : AppColors.errorRed,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Hàng 2 nút ở đáy Modal
        Row(
          children: [
            // Nút Mặc định 50/30/20
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _needRatio = 50;
                      _wantRatio = 30;
                      _saveRatio = 20;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(
                      color: AppColors.primaryBlue,
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Mặc định 50/30/20',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Nút Lưu tỷ lệ
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: _isRatioValid && !_isSavingRatios
                      ? _handleSaveRatios
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    disabledBackgroundColor: AppColors.disabledBlue,
                    foregroundColor: AppColors.white,
                    disabledForegroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: _isSavingRatios
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Lưu tỷ lệ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatioSlider({
    required String name,
    required double ratio,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dòng tiêu đề + chấm màu + %
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${ratio.round()}%',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),

        // Slider thanh trượt ngang
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: color,
            inactiveTrackColor: AppColors.borderGray,
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.15),
          ),
          child: Slider(
            value: ratio,
            min: 0,
            max: 100,
            divisions: 20, // Mỗi nấc 5%
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: CHUYỂN TIỀN NỘI BỘ
  // ==========================================
  Widget _buildTabTransferContent() {
    final fromBalance = _fromJarBalance;
    final isExceeding = _transferAmount > 0 && _transferAmount > fromBalance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Điều chuyển tiền giữa các hũ mà không làm thay đổi Tổng số dư.',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 14),

        // 1. Chọn Từ hũ
        const Text(
          'Từ hũ',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        _buildJarDropdown(
          selectedJar: _fromJar,
          onChanged: (val) {
            if (val != null) setState(() => _fromJar = val);
          },
        ),

        const SizedBox(height: 12),

        // 2. Chọn Sang hũ
        const Text(
          'Sang hũ',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        _buildJarDropdown(
          selectedJar: _toJar,
          onChanged: (val) {
            if (val != null) setState(() => _toJar = val);
          },
        ),

        if (_fromJar == _toJar)
          const Padding(
            padding: EdgeInsets.only(top: 4, left: 2),
            child: Text(
              'Hũ chuyển và hũ nhận phải khác nhau',
              style: TextStyle(
                color: AppColors.errorRed,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        const SizedBox(height: 14),

        // 3. Ô nhập Số tiền chuyển
        const Text(
          'Số tiền chuyển',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isExceeding ? AppColors.errorRed : AppColors.borderGray,
              width: isExceeding ? 1.5 : 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              TextField(
                controller: _transferAmountController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [CurrencyInputFormatter()],
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
                decoration: const InputDecoration(
                  hintText: '0 VND',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                ),
              ),
              if (_transferAmountController.text.isNotEmpty)
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: const Icon(
                      Icons.cancel_rounded,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                    onPressed: () {
                      _transferAmountController.clear();
                    },
                  ),
                ),
            ],
          ),
        ),

        if (isExceeding)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2),
            child: Text(
              'Số dư trong Hũ $_fromJar không đủ (${CurrencyFormatter.format(fromBalance)})',
              style: const TextStyle(
                color: AppColors.errorRed,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        const SizedBox(height: 20),

        // Nút Xác nhận chuyển
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed:
                _canTransfer && !_isTransferring ? _handleTransfer : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              disabledBackgroundColor: AppColors.disabledBlue,
              foregroundColor: AppColors.white,
              disabledForegroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: _isTransferring
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : const Text(
                    'Xác nhận chuyển',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildJarDropdown({
    required String selectedJar,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderGray,
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedJar,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.primaryBlue,
          ),
          items: const ['NEED', 'WANT', 'SAVE'].map((type) {
            final balance = widget.jars[type]?.balance ?? 0.0;
            return DropdownMenuItem<String>(
              value: type,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hũ $type',
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(balance),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
