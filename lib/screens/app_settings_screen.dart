import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/app_settings.dart';
import '../models/jar.dart';
import '../services/biometric_service.dart';
import '../services/moneda_service.dart';
import '../utils/moneda_validator.dart';
import '../widgets/mb_feedback.dart';
import '../widgets/settings_modal.dart';

/// Màn hình Cài đặt Moneda chuẩn phong cách MB Bank
class AppSettingsScreen extends StatefulWidget {
  final MonedaService? monedaService;
  final BiometricService? biometricService;

  const AppSettingsScreen({
    super.key,
    this.monedaService,
    this.biometricService,
  });

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  late final MonedaService _service;
  late final BiometricService _biometricService;

  bool _isBiometricEnabled = false;
  bool _isLoading = true;

  AppSettings? _settings;
  Map<String, Jar> _jars = {};

  @override
  void initState() {
    super.initState();
    _service = widget.monedaService ?? MonedaService();
    _biometricService = widget.biometricService ?? BiometricService();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    try {
      final bioEnabled = await _biometricService.isBiometricEnabled();
      if (_service.hasHomeCache) {
        _settings = AppSettings.fromJson(MonedaService.cachedSettings!);
        _jars = {
          for (var e in MonedaService.cachedJars!)
            (e['jar_type'] as String).toUpperCase(): Jar.fromJson(e)
        };
      }
      if (!mounted) return;
      setState(() {
        _isBiometricEnabled = bioEnabled;
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

  String get _currentUsername {
    final cached = MonedaService.cachedUserProfile?['username'] as String?;
    if (cached != null && cached.isNotEmpty) return cached;
    return MonedaService.lastLoginUsername ?? 'user';
  }

  Future<void> _onBiometricToggle(bool value) async {
    if (value) {
      // 1. Kiểm tra thiết bị có hỗ trợ không
      final available = await _biometricService.isBiometricAvailable();
      if (!available) {
        if (!mounted) return;
        showMbTopToast(
          context,
          'Thiết bị hoặc trình duyệt hiện tại không hỗ trợ Face ID / Vân tay',
        );
        setState(() => _isBiometricEnabled = false);
        return;
      }

      // 2. Lấy mật khẩu từ session hoặc yêu cầu nhập
      final savedPassword = MonedaService.lastLoginPassword;
      if (savedPassword != null && savedPassword.isNotEmpty) {
        final success = await _biometricService.enableBiometric(
          username: _currentUsername,
          password: savedPassword,
        );
        if (!mounted) return;
        if (success) {
          setState(() => _isBiometricEnabled = true);
          showMbTopToast(context, 'Đã bật đăng nhập bằng Face ID / Vân tay');
        } else {
          setState(() => _isBiometricEnabled = false);
        }
      } else {
        // Chưa có mật khẩu trong session -> hiển thị Dialog yêu cầu nhập mật khẩu
        _showConfirmPasswordDialog();
      }
    } else {
      await _biometricService.disableBiometric();
      if (!mounted) return;
      setState(() => _isBiometricEnabled = false);
      showMbTopToast(context, 'Đã tắt đăng nhập bằng Face ID / Vân tay');
    }
  }

  void _showConfirmPasswordDialog() {
    final passwordController = TextEditingController();
    bool obscure = true;
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
              'Xác nhận mật khẩu',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vui lòng nhập mật khẩu tài khoản để kích hoạt đăng nhập nhanh bằng Face ID / Vân tay:',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: passwordController,
                  obscureText: obscure,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu hiện tại',
                    hintText: 'Nhập mật khẩu',
                    errorText: localError,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () => setDialogState(() => obscure = !obscure),
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
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _isBiometricEnabled = false);
                },
                child: const Text(
                  'Hủy',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final enteredPass = passwordController.text;
                  if (enteredPass.isEmpty) {
                    setDialogState(
                      () => localError = 'Vui lòng nhập mật khẩu',
                    );
                    return;
                  }

                  Navigator.pop(ctx);
                  final success = await _biometricService.enableBiometric(
                    username: _currentUsername,
                    password: enteredPass,
                  );

                  if (!mounted) return;
                  if (success) {
                    MonedaService.lastLoginPassword = enteredPass;
                    setState(() => _isBiometricEnabled = true);
                    showMbTopToast(
                      context,
                      'Đã bật đăng nhập bằng Face ID / Vân tay',
                    );
                  } else {
                    setState(() => _isBiometricEnabled = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Kích hoạt',
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

                    // Nếu đang bật biometric thì cập nhật luôn bio_password
                    if (_isBiometricEnabled) {
                      await _biometricService.enableBiometric(
                        username: _currentUsername,
                        password: newPass,
                      );
                    }

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
          const Divider(color: Color(0xFFF1F5F9), height: 1),

          // 2. Đăng nhập bằng Face ID / Vân tay
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.face_unlock_outlined,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Đăng nhập bằng Face ID / Vân tay',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Switch(
                  value: _isBiometricEnabled,
                  onChanged: _onBiometricToggle,
                  activeThumbColor: AppColors.primaryBlue,
                  activeTrackColor: AppColors.primaryBlue.withValues(alpha: 0.35),
                ),
              ],
            ),
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
