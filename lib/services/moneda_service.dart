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

  /// Lấy danh sách tên các nguồn thu nhập không trùng lặp
  Future<List<String>> getIncomeSourceSuggestions() async {
    final defaultSources = [
      'Tiền lương',
      'Thưởng KPI dự án',
      'Tiền làm thêm Freelance',
      'Gia đình hỗ trợ',
    ];

    try {
      final sourcesFuture = _client
          .from('income_sources')
          .select('source_name')
          .eq('is_deleted', false);

      final incomesFuture = _client
          .from('incomes')
          .select('source_name')
          .order('transaction_date', ascending: false)
          .limit(30);

      final results = await Future.wait([sourcesFuture, incomesFuture]);
      final sourcesList = results[0] as List<dynamic>;
      final incomesList = results[1] as List<dynamic>;

      final Set<String> uniqueSources = {};

      for (final item in sourcesList) {
        final name = (item['source_name'] as String?)?.trim();
        if (name != null && name.isNotEmpty) {
          uniqueSources.add(name);
        }
      }

      for (final item in incomesList) {
        final name = (item['source_name'] as String?)?.trim();
        if (name != null && name.isNotEmpty) {
          uniqueSources.add(name);
        }
      }

      for (final item in defaultSources) {
        uniqueSources.add(item);
      }

      return uniqueSources.toList();
    } catch (e) {
      debugPrint('Error fetching income source suggestions: $e');
      return defaultSources;
    }
  }

  /// Trả về danh sách Danh mục chi tiêu
  Future<List<String>> getExpenseCategorySuggestions() async {
    final defaultCategories = [
      'Ăn uống',
      'Di chuyển',
      'Hóa đơn & Tiện ích',
      'Mua sắm',
      'Giải trí',
      'Khác',
    ];

    try {
      final response = await _client
          .from('expenses')
          .select('category')
          .order('transaction_date', ascending: false)
          .limit(30);

      final Set<String> uniqueCategories = Set.from(defaultCategories);

      for (final item in response as List<dynamic>) {
        final cat = (item['category'] as String?)?.trim();
        if (cat != null && cat.isNotEmpty) {
          uniqueCategories.add(cat);
        }
      }

      return uniqueCategories.toList();
    } catch (e) {
      debugPrint('Error fetching expense categories: $e');
      return defaultCategories;
    }
  }

  /// Lấy danh sách title (Nội dung chi tiết) từng nhập trong expenses để gợi ý nhanh
  Future<List<String>> getExpenseTitleSuggestions() async {
    final defaultTitles = [
      'Cơm trưa văn phòng',
      'Cà phê sáng',
      'Nạp 4G Viettel Topup',
      'Siêu thị đồ gia dụng',
      'Xăng xe đi lại',
      'Tiền điện nước',
    ];

    try {
      final response = await _client
          .from('expenses')
          .select('title')
          .order('transaction_date', ascending: false)
          .limit(30);

      final Set<String> uniqueTitles = {};

      for (final item in response as List<dynamic>) {
        final title = (item['title'] as String?)?.trim();
        if (title != null && title.isNotEmpty) {
          uniqueTitles.add(title);
        }
      }

      for (final def in defaultTitles) {
        uniqueTitles.add(def);
      }

      return uniqueTitles.toList();
    } catch (e) {
      debugPrint('Error fetching expense titles: $e');
      return defaultTitles;
    }
  }

  /// Thêm giao dịch Nhận tiền vào hũ
  /// - targetJar == 'ALL_SPLIT' hoặc 'ALL': phân bổ tự động vào 3 hũ theo tỷ lệ
  /// - targetJar == 'NEED' | 'WANT' | 'SAVE': 100% vào hũ được chọn
  Future<void> addIncome({
    required String targetJar,
    required String sourceName,
    required double amount,
  }) async {
    try {
      final settings = await getAppSettings();
      final jars = await getJars();
      final nowIso = DateTime.now().toIso8601String();

      double allocatedNeed = 0.0;
      double allocatedWant = 0.0;
      double allocatedSave = 0.0;

      final isAllSplit = targetJar == 'ALL_SPLIT' || targetJar == 'ALL';

      if (isAllSplit) {
        allocatedNeed =
            (amount * (settings.needRatio / 100.0)).roundToDouble();
        allocatedWant =
            (amount * (settings.wantRatio / 100.0)).roundToDouble();
        allocatedSave = amount - allocatedNeed - allocatedWant;

        // Cập nhật số dư 3 hũ
        final newNeed = (jars['NEED']?.balance ?? 0) + allocatedNeed;
        final newWant = (jars['WANT']?.balance ?? 0) + allocatedWant;
        final newSave = (jars['SAVE']?.balance ?? 0) + allocatedSave;

        await Future.wait([
          _client.from('jars').update({
            'balance': newNeed,
            'updated_at': nowIso,
          }).eq('jar_type', 'NEED'),
          _client.from('jars').update({
            'balance': newWant,
            'updated_at': nowIso,
          }).eq('jar_type', 'WANT'),
          _client.from('jars').update({
            'balance': newSave,
            'updated_at': nowIso,
          }).eq('jar_type', 'SAVE'),
        ]);
      } else {
        final cleanJar = targetJar.toUpperCase();
        if (cleanJar == 'NEED') allocatedNeed = amount;
        if (cleanJar == 'WANT') allocatedWant = amount;
        if (cleanJar == 'SAVE') allocatedSave = amount;

        final currentBalance = jars[cleanJar]?.balance ?? 0.0;
        await _client.from('jars').update({
          'balance': currentBalance + amount,
          'updated_at': nowIso,
        }).eq('jar_type', cleanJar);
      }

      // Lưu bản ghi vào bảng incomes
      await _client.from('incomes').insert({
        'source_name': sourceName,
        'amount': amount,
        'target_jar': isAllSplit ? 'ALL' : targetJar.toUpperCase(),
        'allocated_need': allocatedNeed,
        'allocated_want': allocatedWant,
        'allocated_save': allocatedSave,
        'transaction_date': nowIso,
      });

      // Cập nhật total_balance trong app_settings
      await _client.from('app_settings').update({
        'total_balance': settings.totalBalance + amount,
      }).eq('id', 1);
    } catch (e) {
      debugPrint('Error adding income: $e');
      rethrow;
    }
  }

  /// Thêm giao dịch Thanh toán chi tiêu từ một hũ
  Future<void> addExpense({
    required String jarType,
    required String category,
    required double amount,
    required String title,
  }) async {
    try {
      final cleanJar = jarType.toUpperCase();
      final settings = await getAppSettings();
      final jars = await getJars();
      final nowIso = DateTime.now().toIso8601String();

      // Lưu bản ghi vào bảng expenses
      await _client.from('expenses').insert({
        'jar_type': cleanJar,
        'category': category,
        'amount': amount,
        'title': title,
        'transaction_date': nowIso,
      });

      // Trừ số dư trong hũ được chọn (cho phép âm)
      final currentJarBalance = jars[cleanJar]?.balance ?? 0.0;
      await _client.from('jars').update({
        'balance': currentJarBalance - amount,
        'updated_at': nowIso,
      }).eq('jar_type', cleanJar);

      // Trừ total_balance trong app_settings
      await _client.from('app_settings').update({
        'total_balance': settings.totalBalance - amount,
      }).eq('id', 1);
    } catch (e) {
      debugPrint('Error adding expense: $e');
      rethrow;
    }
  }

  /// Xử lý quyết toán đầu tháng (Rollover)
  /// - transferToSave: true -> chuyển số dư dương của NEED & WANT sang SAVE, reset NEED & WANT về 0
  /// - transferToSave: false -> giữ lại từng hũ, chỉ cập nhật last_rollover_month thành tháng hiện tại
  Future<void> executeRollover({required bool transferToSave}) async {
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    final nowIso = DateTime.now().toIso8601String();

    try {
      if (transferToSave) {
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
