import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneda/core/utils/currency_formatter.dart';
import 'package:moneda/models/app_settings.dart';
import 'package:moneda/models/jar.dart';
import 'package:moneda/models/monthly_report.dart';
import 'package:moneda/models/saving_goal.dart';
import 'package:moneda/models/transaction_item.dart';
import 'package:moneda/screens/expense_detail_screen.dart';
import 'package:moneda/screens/income_detail_screen.dart';
import 'package:moneda/screens/report_screen.dart';
import 'package:moneda/screens/saving_goals_screen.dart';
import 'package:moneda/screens/transaction_history_screen.dart';
import 'package:moneda/widgets/moneda_bottom_bar.dart';
import 'package:moneda/widgets/quick_actions_grid.dart';
import 'package:moneda/widgets/rollover_alert_banner.dart';
import 'package:moneda/widgets/settings_modal.dart';

void main() {
  group('Moneda Unit & Widget Tests', () {
    test('CurrencyFormatter formats currency properly', () {
      expect(CurrencyFormatter.format(3480832), '3,480,832 VND');
      expect(CurrencyFormatter.format(3480832, isHidden: true), '***,*** VND');
      expect(
        CurrencyFormatter.formatTransaction(1000000, isIncome: true),
        '+1,000,000 VND',
      );
      expect(
        CurrencyFormatter.formatTransaction(10000, isIncome: false),
        '-10,000 VND',
      );
      expect(CurrencyFormatter.parseRawAmount('3,000,000 VND'), 3000000.0);
      expect(CurrencyFormatter.parseRawAmount('0 VND'), 0.0);
      expect(CurrencyFormatter.parseRawAmount(''), 0.0);
    });

    test('CurrencyInputFormatter formats input values with commas and VND', () {
      final formatter = CurrencyInputFormatter();
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '1234567'),
      );
      expect(result.text, '1,234,567 VND');
      expect(result.selection.baseOffset, 9);
    });

    test('AppSettings JSON serialization and defaults', () {
      final settings = AppSettings.fromJson({
        'id': 1,
        'total_balance': 5000000,
        'need_ratio': 50,
        'want_ratio': 30,
        'save_ratio': 20,
        'last_rollover_month': '2026-10',
      });

      expect(settings.id, 1);
      expect(settings.totalBalance, 5000000.0);
      expect(settings.needRatio, 50);
      expect(settings.wantRatio, 30);
      expect(settings.saveRatio, 20);
      expect(settings.lastRolloverMonth, '2026-10');
    });

    test('Jar model returns correct display name and subtitle', () {
      final jar = Jar(jarType: 'NEED', balance: 2500000);
      expect(jar.displayName, 'Need');
      expect(jar.subtitle, 'Thiết yếu');
    });

    test('TransactionItem parses income and expense correctly', () {
      final incomeItem = TransactionItem.fromIncome({
        'id': 1,
        'source_name': 'Lương tháng 10',
        'target_jar': 'ALL',
        'amount': 25000000,
        'transaction_date': '2026-10-30T10:00:00Z',
      });
      expect(incomeItem.isIncome, true);
      expect(incomeItem.title, 'Lương tháng 10');
      expect(incomeItem.amount, 25000000.0);

      final expenseItem = TransactionItem.fromExpense({
        'id': 2,
        'jar_type': 'NEED',
        'title': 'Tiền điện nước',
        'amount': 1500000,
        'transaction_date': '2026-10-30T11:00:00Z',
      });
      expect(expenseItem.isIncome, false);
      expect(expenseItem.title, 'Tiền điện nước');
      expect(expenseItem.jarType, 'NEED');
    });

    testWidgets('MonedaBottomBar renders 5 buttons without overflow and handles taps',
        (WidgetTester tester) async {
      int tappedIndex = -1;
      bool paymentTapped = false;
      bool receiveTapped = false;

      // Pump Bottom Bar bên trong Scaffold với kích thước chuẩn mobile iPhone (390x844)
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MonedaBottomBar(
              currentIndex: 0,
              onTap: (index) {
                tappedIndex = index;
              },
              onPaymentTap: () {
                paymentTapped = true;
              },
              onReceiveTap: () {
                receiveTapped = true;
              },
            ),
          ),
        ),
      );

      // Kiểm tra sự hiện diện của cả 5 nhãn điều hướng
      expect(find.text('Trang chủ'), findsOneWidget);
      expect(find.text('Báo cáo'), findsOneWidget);
      expect(find.text('Thanh toán'), findsOneWidget);
      expect(find.text('Nhận tiền'), findsOneWidget);
      expect(find.text('Mục tiêu'), findsOneWidget);

      // Thao tác bấm nút Thanh toán ở giữa (index 2)
      await tester.tap(find.text('Thanh toán'));
      await tester.pumpAndSettle();

      expect(tappedIndex, 2);
      expect(paymentTapped, true);

      // Thao tác bấm nút Nhận tiền (index 3)
      await tester.tap(find.text('Nhận tiền'));
      await tester.pumpAndSettle();

      expect(tappedIndex, 3);
      expect(receiveTapped, true);
    });

    testWidgets('QuickActionsGrid renders 4 buttons and handles taps',
        (WidgetTester tester) async {
      bool paymentPressed = false;
      bool receivePressed = false;
      bool transferPressed = false;
      bool historyPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionsGrid(
              onPaymentTap: () => paymentPressed = true,
              onReceiveTap: () => receivePressed = true,
              onTransferTap: () => transferPressed = true,
              onHistoryTap: () => historyPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Thanh toán'), findsOneWidget);
      expect(find.text('Nhận tiền'), findsOneWidget);
      expect(find.text('Chuyển tiền'), findsOneWidget);
      expect(find.text('Lịch sử GD'), findsOneWidget);

      await tester.tap(find.text('Thanh toán'));
      expect(paymentPressed, true);

      await tester.tap(find.text('Nhận tiền'));
      expect(receivePressed, true);

      await tester.tap(find.text('Chuyển tiền'));
      expect(transferPressed, true);

      await tester.tap(find.text('Lịch sử GD'));
      expect(historyPressed, true);
    });

    testWidgets('RolloverAlertBanner renders correctly and fires callbacks',
        (WidgetTester tester) async {
      bool transferCalled = false;
      bool keepCalled = false;
      bool dismissCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RolloverAlertBanner(
              onTransferToSave: () => transferCalled = true,
              onKeepJars: () => keepCalled = true,
              onDismiss: () => dismissCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Chuyển sang Save'), findsOneWidget);
      expect(find.text('Giữ lại'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.text('Chuyển sang Save'));
      expect(transferCalled, true);

      await tester.tap(find.text('Giữ lại'));
      expect(keepCalled, true);

      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(dismissCalled, true);
    });

    testWidgets('SettingsModal renders tabs, sliders, and resets to default',
        (WidgetTester tester) async {
      final settings = AppSettings(
        id: 1,
        totalBalance: 10000000,
        needRatio: 60,
        wantRatio: 25,
        saveRatio: 15,
      );
      final jars = {
        'NEED': Jar(jarType: 'NEED', balance: 6000000),
        'WANT': Jar(jarType: 'WANT', balance: 2500000),
        'SAVE': Jar(jarType: 'SAVE', balance: 1500000),
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsModal(
              settings: settings,
              jars: jars,
            ),
          ),
        ),
      );

      // Kiểm tra tiêu đề và các Tab
      expect(find.text('Cài đặt Moneda'), findsOneWidget);
      expect(find.text('Cài đặt tỷ lệ 3 hũ'), findsOneWidget);
      expect(find.text('Chuyển tiền nội bộ'), findsOneWidget);

      // Kiểm tra tổng tỷ lệ ban đầu
      expect(find.text('100% (Hợp lệ)'), findsOneWidget);

      // Bấm nút Mặc định 50/30/20
      await tester.tap(find.text('Mặc định 50/30/20'));
      await tester.pump();

      expect(find.text('50%'), findsOneWidget);
      expect(find.text('30%'), findsOneWidget);
      expect(find.text('20%'), findsOneWidget);
      expect(find.text('100% (Hợp lệ)'), findsOneWidget);

      // Chuyển sang Tab 2
      await tester.tap(find.text('Chuyển tiền nội bộ'));
      await tester.pump();

      expect(find.text('Từ hũ'), findsOneWidget);
      expect(find.text('Sang hũ'), findsOneWidget);
      expect(find.text('Số tiền chuyển'), findsOneWidget);
      expect(find.text('Xác nhận chuyển'), findsOneWidget);
    });

    testWidgets('TransactionHistoryScreen renders tabs and query card without crash',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TransactionHistoryScreen(initialTab: 'ALL'),
        ),
      );
      await tester.pump();

      expect(find.text('Lịch sử giao dịch'), findsOneWidget);
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Thu nhập'), findsOneWidget);
      expect(find.text('Hũ Need'), findsOneWidget);
      expect(find.text('Hũ Want'), findsOneWidget);
      expect(find.text('Hũ Save'), findsOneWidget);
      expect(find.text('Truy vấn giao dịch'), findsOneWidget);
      expect(find.text('Thanh toán'), findsOneWidget);
      expect(find.text('Nhận tiền'), findsOneWidget);
    });

    testWidgets('ExpenseDetailScreen renders tabs and query card without crash',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ExpenseDetailScreen(initialJarFilter: 'ALL'),
        ),
      );
      await tester.pump();

      expect(find.text('Chi tiết chi tiêu'), findsOneWidget);
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Hũ Need'), findsOneWidget);
      expect(find.text('Hũ Want'), findsOneWidget);
      expect(find.text('Hũ Save'), findsOneWidget);
      expect(find.text('Truy vấn giao dịch'), findsOneWidget);
    });

    test('MonthlyReportData and JarReport calculations and progress', () {
      final jarNeed = JarReport(
        jarType: 'NEED',
        ratio: 50,
        targetAmount: 7500000,
        actualAmount: 3750000,
        actualPercent: 25.0,
        expenses: [
          {
            'id': 1,
            'title': 'Cơm trưa',
            'category': 'Ăn uống',
            'amount': 50000,
            'transaction_date': '2026-10-15T12:00:00Z',
          }
        ],
      );

      expect(jarNeed.jarType, 'NEED');
      expect(jarNeed.ratio, 50);
      expect(jarNeed.targetAmount, 7500000.0);
      expect(jarNeed.actualAmount, 3750000.0);
      expect(jarNeed.actualPercent, 25.0);
      expect(jarNeed.progress, 0.5);

      final report = MonthlyReportData(
        month: 10,
        year: 2026,
        monthlyIncome: 15000000,
        jars: {'NEED': jarNeed},
        allExpenses: jarNeed.expenses,
      );

      expect(report.month, 10);
      expect(report.year, 2026);
      expect(report.monthlyIncome, 15000000.0);
      expect(report.needReport.actualAmount, 3750000.0);
      expect(report.wantReport.actualAmount, 0.0);
    });

    testWidgets('ReportScreen renders 3 tiers and bottom bar without crash',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReportScreen(initialMonth: 10, initialYear: 2026),
        ),
      );
      await tester.pump();

      // Top AppBar
      expect(find.text('Báo cáo & Sao kê'), findsOneWidget);

      // Tầng 1: Thu nhập tháng & Thời gian
      expect(find.text('Thu nhập tháng'), findsOneWidget);
      expect(find.text('Thời gian'), findsOneWidget);
      expect(find.text('Tháng 10/2026'), findsOneWidget);

      // Tầng 2: Ngân sách Mục tiêu vs Thực tế
      expect(find.text('Ngân sách Mục tiêu vs Thực tế'), findsOneWidget);
      expect(find.text('Hũ NEED'), findsOneWidget);
      expect(find.text('Hũ WANT'), findsOneWidget);
      expect(find.text('Hũ SAVE'), findsOneWidget);
      expect(find.text('Đang xem chi tiết'), findsOneWidget);

      // Tầng 3: Chi tiết chi tiêu hũ đang chọn
      expect(find.textContaining('Chi tiết chi tiêu: Hũ NEED'), findsOneWidget);

      // Bottom Bar có nhãn Báo cáo
      expect(find.text('Báo cáo'), findsOneWidget);
    });

    testWidgets('IncomeDetailScreen renders header and query card without crash',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: IncomeDetailScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Chi tiết thu nhập'), findsOneWidget);
      expect(find.text('Tổng thu nhập trong tháng'), findsOneWidget);
      expect(find.text('Nhận tiền'), findsOneWidget);
      expect(find.text('Truy vấn giao dịch'), findsOneWidget);
    });

    test('SavingGoal model calculations and JSON serialization', () {
      final goal = SavingGoal(
        id: 1,
        goalName: 'Mua MacBook Pro M3',
        targetAmount: 30000000,
        currentAmount: 15000000,
        deadline: DateTime(2026, 12, 31),
        createdAt: DateTime(2026, 10, 1),
      );

      expect(goal.id, 1);
      expect(goal.goalName, 'Mua MacBook Pro M3');
      expect(goal.targetAmount, 30000000.0);
      expect(goal.currentAmount, 15000000.0);
      expect(goal.progress, 0.5);
      expect(goal.progressPercent, 50);
      expect(goal.formattedDeadline, '31/12/2026');
      expect(goal.isCompleted, false);

      final json = goal.toJson();
      expect(json['id'], 1);
      expect(json['goal_name'], 'Mua MacBook Pro M3');

      final fromJson = SavingGoal.fromJson(json);
      expect(fromJson.id, 1);
      expect(fromJson.goalName, 'Mua MacBook Pro M3');
      expect(fromJson.targetAmount, 30000000.0);
      expect(fromJson.currentAmount, 15000000.0);
    });

    testWidgets('SavingGoalsScreen renders cards and bottom bar without crash',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SavingGoalsScreen(),
        ),
      );
      await tester.pump();

      // Top AppBar
      expect(find.text('Mục tiêu tiết kiệm'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);

      // Khối 1: Nguồn tích lũy Hũ SAVE & Nút chuyển vào mục tiêu
      expect(find.textContaining('Nguồn tích lũy: HŨ SAVE'), findsOneWidget);
      expect(find.text('Chuyển vào mục tiêu'), findsOneWidget);

      // Khối 2: Tiêu đề danh sách mục tiêu
      expect(find.text('Danh sách mục tiêu'), findsOneWidget);
      expect(find.text('+ Thêm mới'), findsOneWidget);

      // Bottom Bar có nhãn Mục tiêu
      expect(find.text('Mục tiêu'), findsOneWidget);
    });
  });
}
