import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../core/config/supabase_config.dart';
import '../models/app_settings.dart';
import '../models/jar.dart';
import '../models/transaction_item.dart';

/// Dữ liệu tổng hợp cho Màn hình Trang chủ
class HomeDashboardData {
  final AppSettings settings;
  final Map<String, Jar> jars;
  final List<TransactionItem> recentTransactions;

  HomeDashboardData({
    required this.settings,
    required this.jars,
    required this.recentTransactions,
  });

  Jar get needJar => jars['NEED'] ?? Jar(jarType: 'NEED', balance: 0);
  Jar get wantJar => jars['WANT'] ?? Jar(jarType: 'WANT', balance: 0);
  Jar get saveJar => jars['SAVE'] ?? Jar(jarType: 'SAVE', balance: 0);

  /// Kiểm tra có cần hiển thị banner nhắc nhở quyết toán đầu tháng không
  bool get needsRolloverReminder {
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    final lastMonth = settings.lastRolloverMonth;

    // Đã sang tháng mới và chưa quyết toán
    final isNewMonth = lastMonth == null || lastMonth != currentMonth;
    final hasSurplus = needJar.balance > 0 || wantJar.balance > 0;

    return isNewMonth && hasSurplus;
  }
}

/// Service tương tác với Supabase cho ứng dụng Moneda
class MonedaService {
  final _client = SupabaseConfig.client;

  /// Lấy thông tin app_settings (id = 1)
  Future<AppSettings> getAppSettings() async {
    try {
      final response = await _client
          .from('app_settings')
          .select('*')
          .eq('id', 1)
          .maybeSingle();

      if (response != null) {
        return AppSettings.fromJson(response);
      }

      // Fallback mặc định nếu chưa có bản ghi id=1
      return AppSettings(
        id: 1,
        totalBalance: 0,
        needRatio: 50,
        wantRatio: 30,
        saveRatio: 20,
        lastRolloverMonth: DateFormat('yyyy-MM').format(DateTime.now()),
      );
    } catch (e) {
      debugPrint('Error fetching app_settings: $e');
      rethrow;
    }
  }

  /// Lấy danh sách 3 hũ từ bảng jars
  Future<Map<String, Jar>> getJars() async {
    try {
      final List<dynamic> response = await _client.from('jars').select('*');

      final jarsMap = <String, Jar>{
        'NEED': Jar(jarType: 'NEED', balance: 0),
        'WANT': Jar(jarType: 'WANT', balance: 0),
        'SAVE': Jar(jarType: 'SAVE', balance: 0),
      };

      for (final item in response) {
        final jar = Jar.fromJson(item as Map<String, dynamic>);
        jarsMap[jar.jarType] = jar;
      }

      return jarsMap;
    } catch (e) {
      debugPrint('Error fetching jars: $e');
      rethrow;
    }
  }

  /// Lấy 10 giao dịch gần đây nhất (kết hợp từ incomes và expenses)
  Future<List<TransactionItem>> getRecentTransactions({int limit = 10}) async {
    try {
      final incomesFuture = _client
          .from('incomes')
          .select('*')
          .order('transaction_date', ascending: false)
          .limit(limit);

      final expensesFuture = _client
          .from('expenses')
          .select('*')
          .order('transaction_date', ascending: false)
          .limit(limit);

      final results = await Future.wait([incomesFuture, expensesFuture]);

      final incomeRows = results[0] as List<dynamic>;
      final expenseRows = results[1] as List<dynamic>;

      final List<TransactionItem> list = [];

      for (final item in incomeRows) {
        list.add(TransactionItem.fromIncome(item as Map<String, dynamic>));
      }

      for (final item in expenseRows) {
        list.add(TransactionItem.fromExpense(item as Map<String, dynamic>));
      }

      // Sắp xếp giảm dần theo thời gian giao dịch
      list.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

      if (list.length > limit) {
        return list.sublist(0, limit);
      }

      return list;
    } catch (e) {
      debugPrint('Error fetching recent transactions: $e');
      return [];
    }
  }

  /// Tải toàn bộ dữ liệu cho Trang chủ
  Future<HomeDashboardData> getDashboardData() async {
    final results = await Future.wait([
      getAppSettings(),
      getJars(),
      getRecentTransactions(limit: 10),
    ]);

    return HomeDashboardData(
      settings: results[0] as AppSettings,
      jars: results[1] as Map<String, Jar>,
      recentTransactions: results[2] as List<TransactionItem>,
    );
  }

  /// Xử lý quyết toán đầu tháng (Rollover)
  /// - transferToSave: true -> chuyển số dư dương của NEED & WANT sang SAVE, reset NEED & WANT về 0
  /// - transferToSave: false -> giữ lại từng hũ, chỉ cập nhật last_rollover_month thành tháng hiện tại
  Future<void> executeRollover({required bool transferToSave}) async {
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    final nowIso = DateTime.now().toIso8601String();

    try {
      if (transferToSave) {
        // Lấy lại số dư hiện tại để tính toán chính xác
        final jars = await getJars();
        final needBalance = jars['NEED']?.balance ?? 0.0;
        final wantBalance = jars['WANT']?.balance ?? 0.0;
        final saveBalance = jars['SAVE']?.balance ?? 0.0;

        double surplusToTransfer = 0;

        if (needBalance > 0) {
          surplusToTransfer += needBalance;
          await _client.from('jars').update({
            'balance': 0.0,
            'updated_at': nowIso,
          }).eq('jar_type', 'NEED');
        }

        if (wantBalance > 0) {
          surplusToTransfer += wantBalance;
          await _client.from('jars').update({
            'balance': 0.0,
            'updated_at': nowIso,
          }).eq('jar_type', 'WANT');
        }

        if (surplusToTransfer > 0) {
          final newSaveBalance = saveBalance + surplusToTransfer;
          await _client.from('jars').update({
            'balance': newSaveBalance,
            'updated_at': nowIso,
          }).eq('jar_type', 'SAVE');
        }
      }

      // Cập nhật last_rollover_month thành tháng hiện tại
      await _client.from('app_settings').update({
        'last_rollover_month': currentMonth,
      }).eq('id', 1);
    } catch (e) {
      debugPrint('Error executing rollover: $e');
      rethrow;
    }
  }
}

