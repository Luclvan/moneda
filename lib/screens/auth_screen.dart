import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
import '../services/moneda_service.dart';
import '../utils/moneda_validator.dart';
import 'home_screen.dart';
import 'register_screen.dart';

/// Màn hình Đăng nhập Moneda (hỗ trợ Đăng nhập Lần đầu & Đăng nhập Lần 2+)
class AuthScreen extends StatefulWidget {
  final MonedaService? monedaService;
  final bool? forceFirstTime;

  const AuthScreen({
    super.key,
    this.monedaService,
    this.forceFirstTime,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _usernameTouched = false;
  bool _passwordTouched = false;

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _serverErrorMessage;

  // Quản lý trạng thái: Trạng thái B (Lần 2+) hoặc Trạng thái A (Lần đầu)
  bool _isReturningUser = false;
  Map<String, String>? _savedUser;

  MonedaService get _service => widget.monedaService ?? MonedaService();

  @override
  void initState() {
    super.initState();
    _loadSavedUser();

    _usernameFocus.addListener(() {
      if (!_usernameFocus.hasFocus && !_usernameTouched) {
        setState(() => _usernameTouched = true);
      }
    });

    _passwordFocus.addListener(() {
      if (!_passwordFocus.hasFocus && !_passwordTouched) {
        setState(() => _passwordTouched = true);
      }
    });
  }

  Future<void> _loadSavedUser() async {
    final user = await _service.getLastLoggedInUser();
    if (!mounted) return;

    setState(() {
      _savedUser = user;
      final effectiveUsername = user?['username'];
      if (user != null && widget.forceFirstTime != true) {
        _isReturningUser = true;
        _usernameController.text = effectiveUsername ?? '';
      } else {
        _isReturningUser = false;
        if (effectiveUsername != null && effectiveUsername.isNotEmpty) {
          _usernameController.text = effectiveUsername;
        }
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  String? get _usernameError => _usernameTouched
      ? MonedaValidator.validateUsername(_usernameController.text)
      : null;

  String? get _passwordError => _passwordTouched
      ? MonedaValidator.validatePassword(_passwordController.text)
      : null;

  bool get _isLoginValid {
    if (_isReturningUser) {
      return MonedaValidator.validatePassword(_passwordController.text) ==
          null;
    } else {
      return MonedaValidator.validateLogin(
            username: _usernameController.text,
            password: _passwordController.text,
          ) ==
          null;
    }
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _usernameTouched = true;
      _passwordTouched = true;
    });

    if (!_isLoginValid || _isLoading) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _serverErrorMessage = null;
    });

    try {
      final username = _usernameController.text.trim().toLowerCase();
      final password = _passwordController.text;

      await _service.signIn(
        username: username,
        password: password,
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _serverErrorMessage = MonedaService.formatAuthErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  void _showUsernameRuleInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.primaryBlue),
            SizedBox(width: 8),
            Text(
              'Quy tắc đặt User ID',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• Tối thiểu 3 ký tự.',
              style: TextStyle(color: AppColors.textDark, fontSize: 13.5),
            ),
            SizedBox(height: 6),
            Text(
              '• Chỉ gồm chữ cái không dấu, số, dấu chấm (.) và gạch dưới (_).',
              style: TextStyle(color: AppColors.textDark, fontSize: 13.5),
            ),
            SizedBox(height: 6),
            Text(
              '• Không chứa khoảng trắng hoặc ký tự đặc biệt.',
              style: TextStyle(color: AppColors.textDark, fontSize: 13.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Đã hiểu',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: AppColors.primaryBlue),
            SizedBox(width: 8),
            Text(
              'Quên mật khẩu?',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: const Text(
          'Để bảo mật tài khoản 3 hũ của bạn, vui lòng liên hệ quản trị viên Moneda hoặc sử dụng email đã đăng ký để được hỗ trợ cấp lại mật khẩu mới.',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 13.5,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Đóng',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundGray,
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              // Header trên cùng màu xanh biển #1E40AF có logo MONEDA ở góc trên trái
              _buildTopHeader(topPadding),

              // Card trắng chính ở giữa bo góc 24px
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: _buildMainAuthCard(),
              ),

              // Chân trang ngoài Card
              const Text(
                'Phiên bản v1.0.0   Phiên bản mới nhất',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(double topPadding) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, topPadding + 16, 24, 28),
      decoration: const BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'MONEDA',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainAuthCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderGray, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isReturningUser)
            _buildReturningUserCardContent()
          else
            _buildFirstTimeCardContent(),
        ],
      ),
    );
  }

  // ==========================================
  // TRẠNG THÁI A: ĐĂNG NHẬP LẦN ĐẦU
  // ==========================================
  Widget _buildFirstTimeCardContent() {
    final hasUsernameError = _usernameError != null;
    final hasPasswordError = _passwordError != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Nút quay lại tài khoản đã lưu (nếu trước đó có tài khoản)
        if (_savedUser != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: () {
                setState(() {
                  _isReturningUser = true;
                  _usernameController.text = _savedUser!['username'] ?? '';
                  _serverErrorMessage = null;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.primaryBlue,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Quay lại (${_savedUser!['username']})',
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Tiêu đề lớn
        const Text(
          'Chào mừng bạn đến với Moneda',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 20),

        // Cảnh báo lỗi từ server
        if (_serverErrorMessage != null) ...[
          _buildServerAlert(_serverErrorMessage!),
          const SizedBox(height: 16),
        ],

        // Trường 1: Tên đăng nhập
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasUsernameError
                      ? AppColors.errorRed
                      : AppColors.borderGray,
                  width: hasUsernameError ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _usernameController,
                      focusNode: _usernameFocus,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
                      ],
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Tên đăng nhập',
                        hintText: 'Nhập tên đăng nhập',
                        hintStyle: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                        labelStyle: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _usernameTouched = true;
                          _serverErrorMessage = null;
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.textMuted,
                      size: 19,
                    ),
                    onPressed: _showUsernameRuleInfo,
                  ),
                ],
              ),
            ),
            if (hasUsernameError) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  _usernameError!,
                  style: const TextStyle(
                    color: AppColors.errorRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Trường 2: Mật khẩu
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasPasswordError
                      ? AppColors.errorRed
                      : AppColors.borderGray,
                  width: hasPasswordError ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      obscureText: _obscurePassword,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu',
                        hintText: 'Nhập mật khẩu',
                        hintStyle: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                        labelStyle: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _passwordTouched = true;
                          _serverErrorMessage = null;
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ],
              ),
            ),
            if (hasPasswordError) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  _passwordError!,
                  style: const TextStyle(
                    color: AppColors.errorRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Hàng liên kết điều hướng: Tạo tài khoản | Quên mật khẩu?
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 8,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RegisterScreen(monedaService: _service),
                  ),
                );
              },
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Tạo tài khoản',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: _showForgotPasswordInfo,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Quên mật khẩu?',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Nút chính ở đáy Card: Đăng nhập
        _buildSubmitButton(),
      ],
    );
  }

  // ==========================================
  // TRẠNG THÁI B: ĐĂNG NHẬP LẦN 2 TRỞ ĐI
  // ==========================================
  Widget _buildReturningUserCardContent() {
    final fullName = _savedUser?['full_name'] ??
        _savedUser?['username'] ??
        _usernameController.text;
    final hasPasswordError = _passwordError != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Icon chiếc khiên bảo mật
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '@${_savedUser?['username'] ?? _usernameController.text}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Dòng chữ nhỏ "Xin chào," + Họ tên người dùng lớn
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Xin chào,',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              fullName,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        const SizedBox(height: 22),

        // Cảnh báo lỗi từ server nếu có
        if (_serverErrorMessage != null) ...[
          _buildServerAlert(_serverErrorMessage!),
          const SizedBox(height: 16),
        ],

        // Duy nhất 1 ô nhập Mật khẩu
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasPasswordError
                      ? AppColors.errorRed
                      : AppColors.borderGray,
                  width: hasPasswordError ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      obscureText: _obscurePassword,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu',
                        hintText: 'Nhập mật khẩu',
                        hintStyle: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                        labelStyle: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _passwordTouched = true;
                          _serverErrorMessage = null;
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ],
              ),
            ),
            if (hasPasswordError) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  _passwordError!,
                  style: const TextStyle(
                    color: AppColors.errorRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Hàng nút chữ: Tài khoản khác | Quên mật khẩu?
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 8,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _isReturningUser = false;
                  _passwordController.clear();
                  _serverErrorMessage = null;
                });
              },
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Tài khoản khác',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: _showForgotPasswordInfo,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Quên mật khẩu?',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Nút chính ở đáy Card: Đăng nhập
        _buildSubmitButton(),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = _isLoginValid && !_isLoading;

    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canSubmit ? _handleSignIn : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          disabledBackgroundColor: AppColors.disabledBlue,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Đăng nhập',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _buildServerAlert(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.errorRed,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.errorRed,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
