import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/app_settings.dart';
import '../models/jar.dart';
import '../services/moneda_service.dart';
import '../utils/moneda_validator.dart';
import '../widgets/mb_feedback.dart';
import '../widgets/settings_modal.dart';

/// Màn hình Cài đặt Moneda hiện đại & tối giản
class AppSettingsScreen extends StatefulWidget {
  final MonedaService? monedaService;

  const AppSettingsScreen({
    super.key,
    this.monedaService,
  });

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  late final MonedaService _service;

  bool _isLoading = true;

  AppSettings? _settings;
  Map<String, Jar> _jars = {};

  @override
  void initState() {
    super.initState();
    _service = widget.monedaService ?? MonedaService();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    try {
      if (_service.hasHomeCache) {
        _settings = AppSettings.fromJson(MonedaService.cachedSettings!);
        _jars = {
          for (var e in MonedaService.cachedJars!)
            (e['jar_type'] as String).toUpperCase(): Jar.fromJson(e)
        };
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      // Load fresh settings in background
      final freshSettings = await _service.getAppSettings();
      final freshJars = await _service.getJars();
      if (!mounted) return;
      setState(() {
        _settings = freshSettings;
        _jars = freshJars;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openChangePasswordDialog() {
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? localError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Đổi mật khẩu',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: newPassController,
                    obscureText: obscureNew,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu mới',
                      hintText: 'Tối thiểu 6 ký tự',
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        onPressed: () =>
                            setDialogState(() => obscureNew = !obscureNew),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.borderGray),
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
                  TextField(
                    controller: confirmPassController,
                    obscureText: obscureConfirm,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Xác nhận mật khẩu mới',
                      hintText: 'Nhập lại mật khẩu mới',
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        onPressed: () => setDialogState(
                          () => obscureConfirm = !obscureConfirm,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.borderGray),
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
                  if (localError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      localError!,
                      style: const TextStyle(
                        color: AppColors.errorRed,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Hủy',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newPass = newPassController.text;
                  final confirmPass = confirmPassController.text;

                  final passErr = MonedaValidator.validatePassword(newPass);
                  if (passErr != null) {
                    setDialogState(() => localError = passErr);
                    return;
                  }

                  final matchErr = MonedaValidator.validateConfirmPassword(
                    newPass,
                    confirmPass,
                  );
                  if (matchErr != null) {
                    setDialogState(() => localError = matchErr);
                    return;
                  }

                  Navigator.pop(ctx);
                  try {
                    await _service.updatePassword(newPass);
                    MonedaService.lastLoginPassword = newPass;

                    if (!mounted) return;
                    showMbTopToast(context, 'Đã đổi mật khẩu thành công');
                  } catch (e) {
                    if (!mounted) return;
                    showMbTopToast(
                      context,
                      MonedaService.formatAuthErrorMessage(e),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Cập nhật',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openUtilitiesModal(int initialTab) async {
    final settings = _settings ?? await _service.getAppSettings();
    final jars = _jars.isNotEmpty ? _jars : await _service.getJars();
    if (!mounted) return;

    final result = await SettingsModal.show(
      context,
      settings: settings,
      jars: jars,
      initialTabIndex: initialTab,
    );

    if (result == true && mounted) {
      _loadInitialState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundGray,
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
          'Cài đặt',
          style: TextStyle(
            color: AppColors.primaryBlue,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.home_outlined,
              color: AppColors.primaryBlue,
              size: 24,
            ),
            onPressed: () =>
                Navigator.popUntil(context, (route) => route.isFirst),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==========================================
                  // NHÓM 1: Bảo mật
                  // ==========================================
                  const Text(
                    'Bảo mật',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSecurityCard(),
                  const SizedBox(height: 24),

                  // ==========================================
                  // NHÓM 2: Tiện ích ngân sách
                  // ==========================================
                  const Text(
                    'Tiện ích ngân sách',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBudgetUtilitiesCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. Đổi mật khẩu
          _buildActionTile(
            icon: Icons.lock_reset_rounded,
            title: 'Đổi mật khẩu',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 22,
            ),
            onTap: _openChangePasswordDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetUtilitiesCard() {
    final needRatio = _settings?.needRatio ?? 50;
    final wantRatio = _settings?.wantRatio ?? 30;
    final saveRatio = _settings?.saveRatio ?? 20;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. Cài đặt tỷ lệ 3 hũ
          _buildActionTile(
            icon: Icons.tune_rounded,
            title: 'Cài đặt tỷ lệ 3 hũ ($needRatio/$wantRatio/$saveRatio)',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 22,
            ),
            onTap: () => _openUtilitiesModal(0),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 1),

          // 2. Chuyển tiền nội bộ giữa các hũ
          _buildActionTile(
            icon: Icons.swap_vert_rounded,
            title: 'Chuyển tiền nội bộ giữa các hũ',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 22,
            ),
            onTap: () => _openUtilitiesModal(1),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
