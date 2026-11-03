import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../screens/app_settings_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/user_profile_screen.dart';
import '../services/moneda_service.dart';
import 'mb_feedback.dart';

/// Menu ngăn kéo trượt từ bên phải sang (chuẩn phong cách MB Bank)
class MbMenuDrawer extends StatefulWidget {
  final VoidCallback? onOpenUtilities;
  final VoidCallback? onProfileUpdated;
  final MonedaService? monedaService;

  const MbMenuDrawer({
    super.key,
    this.onOpenUtilities,
    this.onProfileUpdated,
    this.monedaService,
  });

  @override
  State<MbMenuDrawer> createState() => _MbMenuDrawerState();
}

class _MbMenuDrawerState extends State<MbMenuDrawer> {
  MonedaService get _service => widget.monedaService ?? MonedaService();

  String get _displayName {
    final name = MonedaService.cachedUserProfile?['full_name'] as String?;
    if (name != null && name.trim().isNotEmpty) {
      return name.trim().toUpperCase();
    }
    final user = MonedaService.cachedUserProfile?['username'] as String?;
    if (user != null && user.trim().isNotEmpty) {
      return user.trim().toUpperCase();
    }
    final lastUser = MonedaService.lastLoginUsername;
    if (lastUser != null && lastUser.trim().isNotEmpty) {
      return lastUser.trim().toUpperCase();
    }
    return 'NGƯỜI DÙNG';
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showMbDeleteConfirmDialog(
      context: context,
      title: 'Đăng xuất tài khoản',
      message: 'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản hiện tại không?',
      confirmText: 'Đăng xuất',
    );

    if (confirmed == true) {
      await _service.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  void _navigateToUserProfile() {
    Navigator.pop(context); // Đóng menu ngăn kéo
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(monedaService: _service),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {});
        widget.onProfileUpdated?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Drawer(
      width: screenWidth * 0.85,
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          children: [
            // ==========================================
            // 1. Nút icon X ở góc trên bên phải
            // ==========================================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF64748B),
                    size: 26,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // ==========================================
            // 2. Khối thông tin người dùng ở đầu Menu
            // ==========================================
            InkWell(
              onTap: _navigateToUserProfile,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    // Avatar tròn 56x56 với icon khiên nhỏ
                    Stack(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEFF6FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.person_rounded,
                              color: AppColors.primaryBlue,
                              size: 32,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified_user_rounded,
                              color: Color(0xFF64748B),
                              size: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // Họ tên người dùng & link Hồ sơ người dùng >
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayName,
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Text(
                                'Hồ sơ người dùng',
                                style: TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.primaryBlue,
                                size: 18,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ==========================================
            // 3. Đường phân cách ngang dày 6px
            // ==========================================
            const Divider(
              color: Color(0xFFF1F5F9),
              thickness: 6,
              height: 24,
            ),

            // ==========================================
            // 4. Danh sách các mục ở giữa
            // ==========================================
            // Mục 1: Tiện ích
            _buildMenuItem(
              icon: Icons.dashboard_customize_outlined,
              title: 'Tiện ích',
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8),
                size: 22,
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onOpenUtilities?.call();
              },
            ),

            // Mục 2: Cài đặt (kèm badge NEW)
            _buildMenuItem(
              icon: Icons.hexagon_outlined,
              title: 'Cài đặt',
              badge: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.errorRed,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8),
                size: 22,
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AppSettingsScreen(monedaService: _service),
                  ),
                );
              },
            ),

            // Mục 3: Hội viên Moneda
            _buildMenuItem(
              icon: Icons.workspace_premium_outlined,
              title: 'Hội viên Moneda',
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFBFDBFE),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'Basic',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onTap: () {
                showMbTopToast(
                  context,
                  'Bạn đang sử dụng gói hội viên Moneda Basic miễn phí',
                );
              },
            ),

            // ==========================================
            // 5. Khu vực cố định ở dưới đáy Menu
            // ==========================================
            const Spacer(),

            const Divider(color: Color(0xFFF1F5F9), height: 1),

            // Ngôn ngữ
            _buildMenuItem(
              icon: Icons.language,
              title: 'Ngôn ngữ',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Tiếng Việt',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDA251D), // Màu đỏ cờ Việt Nam
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.star,
                        color: Color(0xFFFFEB3B),
                        size: 10,
                      ),
                    ),
                  ),
                ],
              ),
              onTap: () {
                showMbTopToast(context, 'Ứng dụng đang hỗ trợ Tiếng Việt');
              },
            ),

            // Đăng xuất
            _buildMenuItem(
              icon: Icons.logout_rounded,
              title: 'Đăng xuất',
              titleColor: AppColors.errorRed,
              iconColor: AppColors.errorRed,
              onTap: _handleSignOut,
            ),

            const SizedBox(height: 8),

            // Dòng phiên bản ở đáy
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'v1.0.0',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Phiên bản mới nhất',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    Color? iconColor,
    Color? titleColor,
    Widget? badge,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? AppColors.primaryBlue,
              size: 22,
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                color: titleColor ?? AppColors.textDark,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              badge,
            ],
            const Spacer(),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
