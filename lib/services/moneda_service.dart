import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/app_settings.dart';
import '../models/jar.dart';
import '../models/monthly_report.dart';
import '../models/saving_goal.dart';
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
  SupabaseClient get _client => SupabaseConfig.client;

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

      final results =
          await Future.wait<dynamic>(<Future<dynamic>>[incomesFuture, expensesFuture]);

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

      final results =
          await Future.wait<dynamic>(<Future<dynamic>>[sourcesFuture, incomesFuture]);
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

        await Future.wait<dynamic>(<Future<dynamic>>[
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

  /// Cập nhật tỷ lệ phân bổ của 3 hũ (phải có tổng bằng 100%)
  Future<void> updateJarRatios({
    required int needRatio,
    required int wantRatio,
    required int saveRatio,
  }) async {
    if (needRatio + wantRatio + saveRatio != 100) {
      throw ArgumentError('Tổng tỷ lệ của 3 hũ bắt buộc phải bằng 100%');
    }

    try {
      await _client.from('app_settings').update({
        'need_ratio': needRatio,
        'want_ratio': wantRatio,
        'save_ratio': saveRatio,
      }).eq('id', 1);
    } catch (e) {
      debugPrint('Error updating jar ratios: $e');
      rethrow;
    }
  }

  /// Chuyển tiền nội bộ giữa các hũ (không làm đổi total_balance)
  Future<void> transferBetweenJars({
    required String fromJar,
    required String toJar,
    required double amount,
  }) async {
    final from = fromJar.toUpperCase();
    final to = toJar.toUpperCase();

    if (from == to) {
      throw ArgumentError('Hũ chuyển và hũ nhận phải khác nhau');
    }
    if (amount <= 0) {
      throw ArgumentError('Số tiền chuyển phải lớn hơn 0');
    }

    try {
      final jars = await getJars();
      final fromBalance = jars[from]?.balance ?? 0.0;
      final toBalance = jars[to]?.balance ?? 0.0;
      final nowIso = DateTime.now().toIso8601String();

      await Future.wait<dynamic>(<Future<dynamic>>[
        _client.from('jars').update({
          'balance': fromBalance - amount,
          'updated_at': nowIso,
        }).eq('jar_type', from),
        _client.from('jars').update({
          'balance': toBalance + amount,
          'updated_at': nowIso,
        }).eq('jar_type', to),
      ]);
    } catch (e) {
      debugPrint('Error transferring between jars: $e');
      rethrow;
    }
  }

  /// Xử lý quyết toán đầu tháng: Chuyển toàn bộ số dư dương của NEED & WANT sang SAVE
  Future<void> executeMonthlyRollover() async {
    await executeRollover(transferToSave: true);
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

  /// Lấy danh sách chi tiêu lọc theo jarType và khoảng thời gian
  Future<List<Map<String, dynamic>>> getExpenses({
    String? jarType,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var query = _client.from('expenses').select('*');

      if (jarType != null && jarType != 'ALL' && jarType.isNotEmpty) {
        query = query.eq('jar_type', jarType.toUpperCase());
      }

      if (fromDate != null) {
        final startOfDay =
            DateTime(fromDate.year, fromDate.month, fromDate.day);
        query = query.gte('transaction_date', startOfDay.toIso8601String());
      }

      if (toDate != null) {
        final endOfDay = DateTime(
            toDate.year, toDate.month, toDate.day, 23, 59, 59, 999);
        query = query.lte('transaction_date', endOfDay.toIso8601String());
      }

      final response =
          await query.order('transaction_date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching expenses: $e');
      return [];
    }
  }

  /// Xóa bản ghi chi tiêu và hoàn lại tiền vào hũ & total_balance
  Future<void> deleteExpense(Map<String, dynamic> expense) async {
    try {
      final id = expense['id'];
      final amount = (expense['amount'] as num?)?.toDouble() ?? 0.0;
      final jarType = (expense['jar_type'] as String? ?? 'NEED').toUpperCase();
      final goalId = expense['goal_id'];

      // 1. Xóa bản ghi
      await _client.from('expenses').delete().eq('id', id);

      // Nếu có goal_id, trừ lùi current_amount của mục tiêu tương ứng trong saving_goals
      if (goalId != null) {
        try {
          final goalRes = await _client
              .from('saving_goals')
              .select('*')
              .eq('id', goalId)
              .maybeSingle();
          if (goalRes != null) {
            final cur =
                (goalRes['current_amount'] as num?)?.toDouble() ?? 0.0;
            await _client.from('saving_goals').update({
              'current_amount': cur - amount,
              'updated_at': DateTime.now().toIso8601String(),
            }).eq('id', goalId);
          }
        } catch (e) {
          debugPrint('Notice updating saving_goals: $e');
        }
      }

      // 2. Hoàn lại tiền vào hũ (hoặc hũ SAVE nếu là khoản trích mục tiêu)
      final refundJar = goalId != null ? 'SAVE' : jarType;
      final jars = await getJars();
      final currentBalance = jars[refundJar]?.balance ?? 0.0;
      await _client.from('jars').update({
        'balance': currentBalance + amount,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('jar_type', refundJar);

      // 3. Hoàn lại tiền vào total_balance trong app_settings
      final settings = await getAppSettings();
      await _client.from('app_settings').update({
        'total_balance': settings.totalBalance + amount,
      }).eq('id', 1);
    } catch (e) {
      debugPrint('Error deleting expense: $e');
      rethrow;
    }
  }

  /// Lấy danh sách thu nhập trong khoảng thời gian
  Future<List<Map<String, dynamic>>> getIncomes({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var query = _client.from('incomes').select('*');

      if (fromDate != null) {
        final startOfDay =
            DateTime(fromDate.year, fromDate.month, fromDate.day);
        query = query.gte('transaction_date', startOfDay.toIso8601String());
      }

      if (toDate != null) {
        final endOfDay = DateTime(
            toDate.year, toDate.month, toDate.day, 23, 59, 59, 999);
        query = query.lte('transaction_date', endOfDay.toIso8601String());
      }

      final response =
          await query.order('transaction_date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching incomes: $e');
      return [];
    }
  }

  /// Xóa bản ghi thu nhập và thu hồi tiền đã phân bổ ở các hũ & total_balance
  Future<void> deleteIncome(Map<String, dynamic> income) async {
    try {
      final id = income['id'];
      final amount = (income['amount'] as num?)?.toDouble() ?? 0.0;
      final allocatedNeed =
          (income['allocated_need'] as num?)?.toDouble() ?? 0.0;
      final allocatedWant =
          (income['allocated_want'] as num?)?.toDouble() ?? 0.0;
      final allocatedSave =
          (income['allocated_save'] as num?)?.toDouble() ?? 0.0;

      // 1. Xóa bản ghi khỏi incomes
      await _client.from('incomes').delete().eq('id', id);

      // 2. Thu hồi số tiền tương ứng ở các hũ
      final jars = await getJars();
      final nowIso = DateTime.now().toIso8601String();

      await Future.wait<dynamic>(<Future<dynamic>>[
        _client.from('jars').update({
          'balance': (jars['NEED']?.balance ?? 0.0) - allocatedNeed,
          'updated_at': nowIso,
        }).eq('jar_type', 'NEED'),
        _client.from('jars').update({
          'balance': (jars['WANT']?.balance ?? 0.0) - allocatedWant,
          'updated_at': nowIso,
        }).eq('jar_type', 'WANT'),
        _client.from('jars').update({
          'balance': (jars['SAVE']?.balance ?? 0.0) - allocatedSave,
          'updated_at': nowIso,
        }).eq('jar_type', 'SAVE'),
      ]);

      // 3. Trừ total_balance trong app_settings
      final settings = await getAppSettings();
      await _client.from('app_settings').update({
        'total_balance': settings.totalBalance - amount,
      }).eq('id', 1);
    } catch (e) {
      debugPrint('Error deleting income: $e');
      rethrow;
    }
  }

  /// Lấy dữ liệu báo cáo & sao kê thống kê theo tháng/năm
  Future<MonthlyReportData> getMonthlyReport({
    required int month,
    required int year,
  }) async {
    try {
      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59, 999);

      final incomesFuture = _client
          .from('incomes')
          .select('*')
          .gte('transaction_date', startOfMonth.toIso8601String())
          .lte('transaction_date', endOfMonth.toIso8601String());

      final expensesFuture = _client
          .from('expenses')
          .select('*')
          .gte('transaction_date', startOfMonth.toIso8601String())
          .lte('transaction_date', endOfMonth.toIso8601String())
          .order('transaction_date', ascending: false);

      final settingsFuture = getAppSettings();

      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        incomesFuture,
        expensesFuture,
        settingsFuture,
      ]);

      final incomeRows = results[0] as List<dynamic>;
      final expenseRows = results[1] as List<dynamic>;
      final settings = results[2] as AppSettings;

      double monthlyIncome = 0.0;
      for (final inc in incomeRows) {
        monthlyIncome += (inc['amount'] as num?)?.toDouble() ?? 0.0;
      }

      final allExpenses = List<Map<String, dynamic>>.from(expenseRows);

      final jarRatios = {
        'NEED': settings.needRatio,
        'WANT': settings.wantRatio,
        'SAVE': settings.saveRatio,
      };

      final Map<String, JarReport> jarsMap = {};

      for (final jarType in ['NEED', 'WANT', 'SAVE']) {
        final ratio = jarRatios[jarType] ?? 0;
        final jarExpenses = allExpenses
            .where((e) =>
                (e['jar_type'] as String? ?? '').toUpperCase() == jarType)
            .toList();

        final actualAmount = jarExpenses.fold<double>(
          0.0,
          (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0.0),
        );

        final targetAmount =
            monthlyIncome > 0 ? monthlyIncome * (ratio / 100.0) : 0.0;

        final actualPercent =
            monthlyIncome > 0 ? (actualAmount / monthlyIncome) * 100.0 : 0.0;

        jarsMap[jarType] = JarReport(
          jarType: jarType,
          ratio: ratio,
          targetAmount: targetAmount,
          actualAmount: actualAmount,
          actualPercent: actualPercent,
          expenses: jarExpenses,
        );
      }

      return MonthlyReportData(
        month: month,
        year: year,
        monthlyIncome: monthlyIncome,
        jars: jarsMap,
        allExpenses: allExpenses,
      );
    } catch (e) {
      debugPrint('Error getting monthly report: $e');
      final defaultSettings = AppSettings(
        id: 1,
        totalBalance: 0,
        needRatio: 50,
        wantRatio: 30,
        saveRatio: 20,
      );
      final Map<String, JarReport> emptyJars = {
        'NEED': JarReport(
          jarType: 'NEED',
          ratio: defaultSettings.needRatio,
          targetAmount: 0,
          actualAmount: 0,
          actualPercent: 0,
          expenses: const [],
        ),
        'WANT': JarReport(
          jarType: 'WANT',
          ratio: defaultSettings.wantRatio,
          targetAmount: 0,
          actualAmount: 0,
          actualPercent: 0,
          expenses: const [],
        ),
        'SAVE': JarReport(
          jarType: 'SAVE',
          ratio: defaultSettings.saveRatio,
          targetAmount: 0,
          actualAmount: 0,
          actualPercent: 0,
          expenses: const [],
        ),
      };
      return MonthlyReportData(
        month: month,
        year: year,
        monthlyIncome: 0.0,
        jars: emptyJars,
        allExpenses: const [],
      );
    }
  }

  /// Lấy danh sách mục tiêu tiết kiệm sắp xếp theo created_at ASC
  Future<List<Map<String, dynamic>>> getSavingGoals() async {
    try {
      final response = await _client
          .from('saving_goals')
          .select('*')
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching saving goals: $e');
      return [];
    }
  }

  /// Lấy danh sách mục tiêu tiết kiệm dưới dạng SavingGoal models
  Future<List<SavingGoal>> getSavingGoalModels() async {
    final list = await getSavingGoals();
    return list.map((json) => SavingGoal.fromJson(json)).toList();
  }

  /// Thêm mới hoặc Cập nhật mục tiêu tiết kiệm
  Future<void> createOrUpdateSavingGoal({
    int? id,
    required String goalName,
    required double targetAmount,
    DateTime? deadline,
  }) async {
    try {
      if (id == null) {
        // Thêm mới
        final data = {
          'goal_name': goalName.trim(),
          'target_amount': targetAmount,
          'current_amount': 0.0,
          if (deadline != null) 'deadline': deadline.toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        };
        await _client.from('saving_goals').insert(data);
      } else {
        // Cập nhật
        final data = {
          'goal_name': goalName.trim(),
          'target_amount': targetAmount,
          'deadline': deadline?.toIso8601String(),
        };
        await _client.from('saving_goals').update(data).eq('id', id);
      }
    } catch (e) {
      debugPrint('Error creating or updating saving goal: $e');
      rethrow;
    }
  }

  /// Xóa mục tiêu tiết kiệm và hoàn trả current_amount vào hũ SAVE & total_balance nếu có
  Future<void> deleteSavingGoal(Map<String, dynamic> goal) async {
    try {
      final goalId = goal['id'];
      final currentAmount = (goal['current_amount'] as num?)?.toDouble() ?? 0.0;

      // Nếu có số dư đã tích lũy > 0, hoàn trả vào hũ SAVE và total_balance
      if (currentAmount > 0) {
        final jars = await getJars();
        final saveBalance = jars['SAVE']?.balance ?? 0.0;
        final newSaveBalance = saveBalance + currentAmount;

        await _client.from('jars').update({
          'balance': newSaveBalance,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('jar_type', 'SAVE');

        final settings = await getAppSettings();
        await _client.from('app_settings').update({
          'total_balance': settings.totalBalance + currentAmount,
        }).eq('id', 1);

        // Xóa các bản ghi expenses phát sinh từ mục tiêu này
        await _client.from('expenses').delete().eq('goal_id', goalId);
      }

      // Xóa bản ghi trong saving_goals
      await _client.from('saving_goals').delete().eq('id', goalId);
    } catch (e) {
      debugPrint('Error deleting saving goal: $e');
      rethrow;
    }
  }

  /// Chuyển tiền từ Hũ SAVE vào mục tiêu tiết kiệm
  Future<void> transferSaveToGoal({
    required int goalId,
    required String goalName,
    required double amount,
  }) async {
    try {
      if (amount <= 0) {
        throw Exception('Số tiền chuyển phải lớn hơn 0');
      }

      final jars = await getJars();
      final currentSaveBalance = jars['SAVE']?.balance ?? 0.0;

      if (amount > currentSaveBalance) {
        throw Exception('Số dư trong Hũ SAVE không đủ để chuyển vào mục tiêu');
      }

      final nowIso = DateTime.now().toIso8601String();

      // 1. Trừ số dư Hũ SAVE trong bảng jars
      await _client.from('jars').update({
        'balance': currentSaveBalance - amount,
        'updated_at': nowIso,
      }).eq('jar_type', 'SAVE');

      // 2. Trừ total_balance trong bảng app_settings
      final settings = await getAppSettings();
      await _client.from('app_settings').update({
        'total_balance': settings.totalBalance - amount,
      }).eq('id', 1);

      // 3. Cộng amount vào current_amount của goal trong saving_goals
      final goalRes = await _client
          .from('saving_goals')
          .select('current_amount')
          .eq('id', goalId)
          .maybeSingle();

      final currentGoalAmount =
          (goalRes?['current_amount'] as num?)?.toDouble() ?? 0.0;

      await _client.from('saving_goals').update({
        'current_amount': currentGoalAmount + amount,
      }).eq('id', goalId);

      // 4. Lưu 1 bản ghi vào bảng expenses
      await _client.from('expenses').insert({
        'jar_type': 'SAVE',
        'category': 'Mục tiêu tiết kiệm',
        'title': 'Nạp tiền vào mục tiêu: $goalName',
        'amount': amount,
        'goal_id': goalId,
        'transaction_date': nowIso,
      });
    } catch (e) {
      debugPrint('Error transferring from SAVE to goal: $e');
      rethrow;
    }
  }
}
