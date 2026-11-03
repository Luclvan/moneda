import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/moneda_service.dart';
import '../utils/moneda_validator.dart';
import '../widgets/mb_feedback.dart';
import 'app_settings_screen.dart';

/// Màn hình Hồ sơ người dùng
class UserProfileScreen extends StatefulWidget {
  final MonedaService? monedaService;

  const UserProfileScreen({
    super.key,
    this.monedaService,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late final MonedaService _service;
  bool _isLoading = true;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _service = widget.monedaService ?? MonedaService();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (MonedaService.cachedUserProfile != null) {
      setState(() {
        _profile = MonedaService.cachedUserProfile;
        _isLoading = false;
      });
    }

    try {
      final res = await _service.getUserProfile();
      if (!mounted) return;
      setState(() {
        _profile = res ?? MonedaService.cachedUserProfile;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  String get _displayName {
    final name = _profile?['full_name'] as String?;
    if (name != null && name.trim().isNotEmpty) {
      return name.trim();
    }
    final user = _profile?['username'] as String?;
    if (user != null && user.trim().isNotEmpty) {
      return user.trim();
    }
    return MonedaService.lastLoginUsername ?? 'NGƯỜI DÙNG';
  }

  String get _username {
    final user = _profile?['username'] as String?;
    if (user != null && user.trim().isNotEmpty) {
      return user.trim();
    }
    return MonedaService.lastLoginUsername ?? 'user';
  }

  void _openEditFullNameDialog() {
    final controller = TextEditingController(text: _displayName);
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
              'Đổi họ và tên hiển thị',
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
                TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Họ và tên mới',
                    hintText: 'Nhập họ và tên hiển thị',
                    errorText: localError,
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
                  onChanged: (val) {
                    if (localError != null) {
                      setDialogState(() => localError = null);
                    }
                  },
                ),
              ],
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
                  final newName = controller.text.trim();
                  final err = MonedaValidator.validateFullName(newName);
                  if (err != null) {
                    setDialogState(() => localError = err);
                    return;
                  }

                  Navigator.pop(ctx);
                  try {
                    await _service.updateFullName(newName);
                    if (!mounted) return;
                    setState(() {
                      _profile?['full_name'] = newName;
                    });
                    showMbTopToast(context, 'Đã cập nhật họ và tên');
                  } catch (e) {
                    if (!mounted) return;
                    showMbTopToast(context, 'Lỗi cập nhật: $e');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Lưu thay đổi',
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
          'Hồ sơ người dùng',
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
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
              child: Column(
                children: [
                  // ==========================================
                  // KHỐI 1: Card lớn chứa Avatar đè mép trên
                  // ==========================================
                  _buildHeaderCard(),
                  const SizedBox(height: 20),

                  // ==========================================
                  // KHỐI 2: Danh sách tùy chọn
                  // ==========================================
                  _buildOptionsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Thẻ Card trắng
        Container(
          margin: const EdgeInsets.only(top: 44),
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderGray, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Họ và tên in hoa đậm
              Text(
                _displayName.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),

              // User ID
              Text(
                'User ID: $_username',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),

              // 2 ô thẻ nhỏ nằm ngang
              Row(
                children: [
                  // Ô trái: Tăng cường bảo vệ
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AppSettingsScreen(monedaService: _service),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundGray,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.borderGray,
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.shield_rounded,
                              color: Color(0xFF64748B),
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tăng cường bảo vệ',
                                style: TextStyle(
                                  color: AppColors.textDark,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Ô phải: Gói hội viên Basic
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundGray,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.borderGray,
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.workspace_premium_outlined,
                            color: AppColors.primaryBlue,
                            size: 22,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gói hội viên Moneda',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Basic',
                                  style: TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Avatar tròn lớn (88x88) nằm đè một nửa lên mép trên
        Positioned(
          top: 0,
          child: Stack(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.person_rounded,
                    color: AppColors.primaryBlue,
                    size: 50,
                  ),
                ),
              ),

              // Nút tròn nhỏ có icon cây bút ở góc dưới phải Avatar
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _openEditFullNameDialog,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.borderGray,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.edit_outlined,
                        color: AppColors.primaryBlue,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGray, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Mục 1: Đổi họ và tên hiển thị
          _buildOptionTile(
            icon: Icons.badge_outlined,
            title: 'Đổi họ và tên hiển thị',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 22,
            ),
            onTap: _openEditFullNameDialog,
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 1),

          // Mục 2: Tên đăng nhập (User ID)
          _buildOptionTile(
            icon: Icons.alternate_email_rounded,
            title: 'Tên đăng nhập (User ID)',
            trailing: Text(
              _username,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: null,
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 1),

          // Mục 3: Đổi mật khẩu
          _buildOptionTile(
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

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
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
