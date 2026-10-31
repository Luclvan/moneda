import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/app_settings.dart';
import '../models/jar.dart';
import '../models/transaction_item.dart';
import '../services/moneda_service.dart';
import '../widgets/balance_carousel.dart';
import '../widgets/jars_allocation_card.dart';
import '../widgets/moneda_bottom_bar.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/recent_transactions_card.dart';
import '../widgets/rollover_alert_banner.dart';
import '../widgets/settings_modal.dart';
import 'expense_detail_screen.dart';
import 'income_detail_screen.dart';
import 'payment_screen.dart';
import 'receive_money_screen.dart';

/// Màn hình Trang chủ (Home Dashboard) chuẩn phong cách MB Bank
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MonedaService _monedaService = MonedaService();

  bool _isLoading = true;
  bool _isRolloverLoading = false;
  bool _isRolloverDismissed = false;
  String? _errorMessage;

  // Trạng thái ẩn/hiện số dư (mặc định hiện số dư)
  bool _isBalanceHidden = false;

  // Dữ liệu từ Supabase
  AppSettings? _settings;
  Map<String, Jar> _jars = {};
  List<TransactionItem> _recentTransactions = [];

  // Tab index cho Bottom Bar
  int _bottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      if (!mounted) return;
      setState(() {
        _errorMessage = null;
      });

      final data = await _monedaService.getDashboardData();

      if (!mounted) return;
      setState(() {
        _settings = data.settings;
        _jars = data.jars;
        _recentTransactions = data.recentTransactions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể tải dữ liệu: $e';
        _isLoading = false;
      });
    }
  }

  /// Xử lý quyết toán đầu tháng
  Future<void> _handleRollover({required bool transferToSave}) async {
    if (!transferToSave) {
      // Giữ nguyên số tiền ở từng hũ và giữ lại thông báo để chuyển sau
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã giữ lại số dư từng hũ. Bạn có thể chuyển sang Save bất cứ lúc nào trong tháng.',
          ),
          backgroundColor: AppColors.primaryBlue,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isRolloverLoading = true;
    });

    try {
      await _monedaService.executeMonthlyRollover();
      await _loadDashboardData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã chuyển toàn bộ số dư thặng dư sang hũ Save thành công!',
          ),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi quyết toán: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRolloverLoading = false;
        });
      }
    }
  }

  void _onPlaceholderAction(String title) {
    debugPrint('Tapped action: $title');
  }

  Future<void> _openSettingsModal({int initialTab = 0}) async {
    if (_settings == null) return;
    final result = await SettingsModal.show(
      context,
      settings: _settings!,
      jars: _jars,
      initialTabIndex: initialTab,
    );
    if (result == true && mounted) {
      _loadDashboardData();
    }
  }

  Future<void> _navigateToReceiveMoney() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const ReceiveMoneyScreen(),
      ),
    );
    if (result == true || mounted) {
      _loadDashboardData();
    }
  }

  Future<void> _navigateToPayment() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const PaymentScreen(),
      ),
    );
    if (result == true || mounted) {
      _loadDashboardData();
    }
  }

  Future<void> _navigateToExpenseDetail({String initialJarFilter = 'ALL'}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ExpenseDetailScreen(initialJarFilter: initialJarFilter),
      ),
    );
    if (mounted) {
      _loadDashboardData();
    }
  }

  Future<void> _navigateToIncomeDetail() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const IncomeDetailScreen(),
      ),
    );
    if (mounted) {
      _loadDashboardData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      // A. Top AppBar màu xanh biển đậm (#1E40AF)
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            const Text(
              'MONEDA',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: const Color(0x33000000),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.22),
                  width: 0.6,
                ),
              ),
              child: const Text(
                'MB STYLE',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          _buildCircleButton(
            icon: Icons.notifications_none_rounded,
            onTap: () => _onPlaceholderAction('Thông báo'),
          ),
          const SizedBox(width: 8),
          _buildCircleButton(
            icon: Icons.menu_rounded,
            onTap: () => _openSettingsModal(initialTab: 0),
          ),
          const SizedBox(width: 16),
        ],
      ),

      // F. Thanh Bottom Navigation Bar cố định ở đáy
      bottomNavigationBar: MonedaBottomBar(
        currentIndex: _bottomNavIndex,
        onTap: (index) {
          setState(() {
            _bottomNavIndex = index;
          });
        },
        onPaymentTap: _navigateToPayment,
        onReceiveTap: _navigateToReceiveMoney,
      ),

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryBlue,
        ),
      );
    }

    if (_errorMessage != null && _settings == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.errorRed,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDashboardData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final settings = _settings ??
        AppSettings(
          id: 1,
          totalBalance: 0,
          needRatio: 50,
          wantRatio: 30,
          saveRatio: 20,
        );

    final dashboardData = HomeDashboardData(
      settings: settings,
      jars: _jars,
      recentTransactions: _recentTransactions,
    );

    return RefreshIndicator(
      color: AppColors.primaryBlue,
      backgroundColor: AppColors.white,
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // B. Khu vực Banner xanh biển chứa Avatar & Thẻ số dư trượt ngang
            Container(
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Banner nhắc nhở quyết toán đầu tháng (nếu cần)
                  if (dashboardData.needsRolloverReminder &&
                      !_isRolloverDismissed)
                    RolloverAlertBanner(
                      onTransferToSave: () =>
                          _handleRollover(transferToSave: true),
                      onKeepJars: () => _handleRollover(transferToSave: false),
                      onDismiss: () {
                        setState(() {
                          _isRolloverDismissed = true;
                        });
                      },
                      isLoading: _isRolloverLoading,
                    ),

                  // Avatar & Thẻ số dư PageView trượt ngang
                  BalanceCarousel(
                    settings: settings,
                    jars: _jars,
                    isBalanceHidden: _isBalanceHidden,
                    onToggleHideBalance: () {
                      setState(() {
                        _isBalanceHidden = !_isBalanceHidden;
                      });
                    },
                    onJarTap: (jarType) =>
                        _navigateToExpenseDetail(initialJarFilter: jarType),
                  ),
                ],
              ),
            ),

            // C. Khối 4 Nút chức năng nhanh (cách 16px bên dưới banner xanh)
            QuickActionsGrid(
              onPaymentTap: _navigateToPayment,
              onReceiveTap: _navigateToReceiveMoney,
              onIncomeTap: _navigateToIncomeDetail,
              onExpenseTap: () =>
                  _navigateToExpenseDetail(initialJarFilter: 'ALL'),
            ),

            // D. Khối "Tỷ lệ phân bổ 3 hũ"
            JarsAllocationCard(
              settings: settings,
              jars: _jars,
              isBalanceHidden: _isBalanceHidden,
              onCustomizeTap: () => _openSettingsModal(initialTab: 0),
              onJarTap: (jarType) =>
                  _navigateToExpenseDetail(initialJarFilter: jarType),
            ),

            // E. Khối "Giao dịch gần đây"
            RecentTransactionsCard(
              transactions: _recentTransactions,
              isBalanceHidden: _isBalanceHidden,
              onViewAllTap: () =>
                  _navigateToExpenseDetail(initialJarFilter: 'ALL'),
            ),

            // Khoảng đệm 110px ở đáy để nội dung không bị thanh Bottom Bar che khuất
            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.25),
            width: 0.8,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: AppColors.white,
        ),
      ),
    );
  }
}
