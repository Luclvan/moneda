import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneda/models/app_settings.dart';
import 'package:moneda/models/jar.dart';
import 'package:moneda/screens/payment_screen.dart';
import 'package:moneda/screens/receive_money_screen.dart';
import 'package:moneda/screens/report_screen.dart';
import 'package:moneda/screens/saving_goals_screen.dart';
import 'package:moneda/services/moneda_service.dart';
import 'package:moneda/utils/moneda_validator.dart';
import 'package:moneda/widgets/settings_modal.dart';

void main() {
  // ===========================================================================
  // PHẦN A: UNIT TEST NGHIỆP VỤ LÕI (MonedaValidator đang gắn trực tiếp App)
  // ===========================================================================
  group('Phần A - Unit Test nghiệp vụ lõi (MonedaValidator)', () {
    group('1. Phân bổ thu nhập calculateIncomeAllocation (Bảo toàn tuyệt đối 100%)', () {
      test('Tỷ lệ chẵn 50/30/20 với 10,000,000 VND', () {
        final result = MonedaValidator.calculateIncomeAllocation(
          amount: 10000000,
          targetJar: 'ALL_SPLIT',
          needRatio: 50,
          wantRatio: 30,
          saveRatio: 20,
        );

        expect(result['need'], 5000000.0);
        expect(result['want'], 3000000.0);
        expect(result['save'], 2000000.0);
        expect(result['need']! + result['want']! + result['save']!, 10000000.0);
      });

      test('Tỷ lệ lẻ 33/33/34 với số tiền 100,000 VND: Tuyệt đối không lệch 1 đồng', () {
        const amount = 100000.0;
        final result = MonedaValidator.calculateIncomeAllocation(
          amount: amount,
          targetJar: 'ALL_SPLIT',
          needRatio: 33,
          wantRatio: 33,
          saveRatio: 34,
        );

        // need = (100,000 * 33 / 100).roundToDouble() = 33000.0
        // want = (100,000 * 33 / 100).roundToDouble() = 33000.0
        // save = 100,000 - 33000 - 33000 = 34000.0
        expect(result['need'], 33000.0);
        expect(result['want'], 33000.0);
        expect(result['save'], 34000.0);
        expect(
          result['need']! + result['want']! + result['save']!,
          amount,
          reason: 'Tổng 3 hũ bắt buộc phải khớp 100% với số tiền nạp vào',
        );
      });

      test('Số tiền lẻ nguyên tố 100,001 VND với tỷ lệ 33/33/34', () {
        const amount = 100001.0;
        final result = MonedaValidator.calculateIncomeAllocation(
          amount: amount,
          targetJar: 'ALL_SPLIT',
          needRatio: 33,
          wantRatio: 33,
          saveRatio: 34,
        );

        // need = (100001 * 0.33).roundToDouble() = (33000.33).roundToDouble() = 33000.0
        // want = (100001 * 0.33).roundToDouble() = 33000.0
        // save = 100001 - 33000 - 33000 = 34001.0
        expect(result['need'], 33000.0);
        expect(result['want'], 33000.0);
        expect(result['save'], 34001.0);
        expect(result['need']! + result['want']! + result['save']!, amount);
      });

      test('Phân bổ 100% vào hũ đích cụ thể (NEED / WANT / SAVE)', () {
        final needRes = MonedaValidator.calculateIncomeAllocation(
          amount: 5000000,
          targetJar: 'NEED',
          needRatio: 50,
          wantRatio: 30,
          saveRatio: 20,
        );
        expect(needRes['need'], 5000000.0);
        expect(needRes['want'], 0.0);
        expect(needRes['save'], 0.0);

        final wantRes = MonedaValidator.calculateIncomeAllocation(
          amount: 3000000,
          targetJar: 'WANT',
          needRatio: 50,
          wantRatio: 30,
          saveRatio: 20,
        );
        expect(wantRes['need'], 0.0);
        expect(wantRes['want'], 3000000.0);
        expect(wantRes['save'], 0.0);

        final saveRes = MonedaValidator.calculateIncomeAllocation(
          amount: 2000000,
          targetJar: 'SAVE',
          needRatio: 50,
          wantRatio: 30,
          saveRatio: 20,
        );
        expect(saveRes['need'], 0.0);
        expect(saveRes['want'], 0.0);
        expect(saveRes['save'], 2000000.0);
      });
    });

    group('2. Chặn âm quỹ các nghiệp vụ (Anti-Negative Balance)', () {
      test('validateExpense: Chặn khi số tiền chi > số dư hũ', () {
        final error = MonedaValidator.validateExpense(
          jarType: 'NEED',
          category: 'Ăn uống',
          amount: 550000,
          currentJarBalance: 500000,
          title: 'Cơm trưa',
        );
        expect(error, 'Số dư trong Hũ NEED không đủ');

        final valid = MonedaValidator.validateExpense(
          jarType: 'NEED',
          category: 'Ăn uống',
          amount: 500000,
          currentJarBalance: 500000,
          title: 'Cơm trưa',
        );
        expect(valid, isNull);
      });

      test('validateDeleteIncome: Chặn xóa thu nhập khi số dư hũ đã bị tiêu âm', () {
        final error = MonedaValidator.validateDeleteIncome(
          allocatedNeed: 1000000,
          allocatedWant: 600000,
          allocatedSave: 400000,
          currentNeedBalance: 500000, // Đã tiêu mất 500k
          currentWantBalance: 600000,
          currentSaveBalance: 400000,
        );
        expect(
          error,
          'Không thể xóa khoản thu nhập này vì số tiền trong hũ đã được chi tiêu!',
        );

        final valid = MonedaValidator.validateDeleteIncome(
          allocatedNeed: 1000000,
          allocatedWant: 600000,
          allocatedSave: 400000,
          currentNeedBalance: 1200000,
          currentWantBalance: 800000,
          currentSaveBalance: 500000,
        );
        expect(valid, isNull);
      });

      test('validateInternalTransfer: Chặn chuyển tiền vượt quá số dư hũ nguồn', () {
        final error = MonedaValidator.validateInternalTransfer(
          fromJar: 'NEED',
          toJar: 'SAVE',
          amount: 1500000,
          fromJarBalance: 1000000,
        );
        expect(error, 'Số dư hũ nguồn không đủ để chuyển');

        final sameJarError = MonedaValidator.validateInternalTransfer(
          fromJar: 'NEED',
          toJar: 'NEED',
          amount: 200000,
          fromJarBalance: 1000000,
        );
        expect(sameJarError, 'Hũ nhận phải khác hũ nguồn');

        final valid = MonedaValidator.validateInternalTransfer(
          fromJar: 'NEED',
          toJar: 'SAVE',
          amount: 1000000,
          fromJarBalance: 1000000,
        );
        expect(valid, isNull);
      });

      test('validateGoalDeposit: Chặn nạp vào mục tiêu vượt quá số dư Hũ SAVE', () {
        final error = MonedaValidator.validateGoalDeposit(
          goalId: 1,
          amount: 3000000,
          saveJarBalance: 2000000,
        );
        expect(error, 'Số dư Hũ SAVE không đủ để gửi vào mục tiêu');

        final valid = MonedaValidator.validateGoalDeposit(
          goalId: 1,
          amount: 2000000,
          saveJarBalance: 2000000,
        );
        expect(valid, isNull);
      });

      test('validateGoalWithdraw: Chặn rút tiền vượt quá số dư hiện có trong mục tiêu', () {
        final error = MonedaValidator.validateGoalWithdraw(
          targetJar: 'SAVE',
          amount: 5000000,
          goalCurrentAmount: 4000000,
        );
        expect(error, 'Số tiền rút vượt quá số dư mục tiêu');

        final valid = MonedaValidator.validateGoalWithdraw(
          targetJar: 'SAVE',
          amount: 4000000,
          goalCurrentAmount: 4000000,
        );
        expect(valid, isNull);
      });
    });

    group('3. Kéo Slider tự cân bằng autoBalanceSliders ở mọi biên', () {
      test('Kéo Slider NEED chạm 0%', () {
        final res = MonedaValidator.autoBalanceSliders(
          changedJar: 'NEED',
          newValue: 0,
          currentNeed: 50,
          currentWant: 30,
          currentSave: 20,
        );
        expect(res['need'], 0);
        expect(res['want'], 30);
        expect(res['save'], 70);
        expect(res['need']! + res['want']! + res['save']!, 100);
      });

      test('Kéo Slider NEED chạm 100%', () {
        final res = MonedaValidator.autoBalanceSliders(
          changedJar: 'NEED',
          newValue: 100,
          currentNeed: 50,
          currentWant: 30,
          currentSave: 20,
        );
        expect(res['need'], 100);
        expect(res['want'], 0);
        expect(res['save'], 0);
        expect(res['need']! + res['want']! + res['save']!, 100);
      });

      test('Kéo Slider WANT chạm 0%', () {
        final res = MonedaValidator.autoBalanceSliders(
          changedJar: 'WANT',
          newValue: 0,
          currentNeed: 50,
          currentWant: 30,
          currentSave: 20,
        );
        expect(res['need'], 50);
        expect(res['want'], 0);
        expect(res['save'], 50);
        expect(res['need']! + res['want']! + res['save']!, 100);
      });

      test('Kéo Slider WANT chạm 100%', () {
        final res = MonedaValidator.autoBalanceSliders(
          changedJar: 'WANT',
          newValue: 100,
          currentNeed: 50,
          currentWant: 30,
          currentSave: 20,
        );
        expect(res['need'], 0);
        expect(res['want'], 100);
        expect(res['save'], 0);
        expect(res['need']! + res['want']! + res['save']!, 100);
      });

      test('Kéo Slider SAVE chạm 0%', () {
        final res = MonedaValidator.autoBalanceSliders(
          changedJar: 'SAVE',
          newValue: 0,
          currentNeed: 50,
          currentWant: 30,
          currentSave: 20,
        );
        expect(res['need'], 50);
        expect(res['want'], 50);
        expect(res['save'], 0);
        expect(res['need']! + res['want']! + res['save']!, 100);
      });

      test('Kéo Slider SAVE chạm 100%', () {
        final res = MonedaValidator.autoBalanceSliders(
          changedJar: 'SAVE',
          newValue: 100,
          currentNeed: 50,
          currentWant: 30,
          currentSave: 20,
        );
        expect(res['need'], 0);
        expect(res['want'], 0);
        expect(res['save'], 100);
        expect(res['need']! + res['want']! + res['save']!, 100);
      });

      test('Xử lý clamp giá trị ngoài dải [0, 100]', () {
        final resNeg = MonedaValidator.autoBalanceSliders(
          changedJar: 'NEED',
          newValue: -50,
          currentNeed: 50,
          currentWant: 30,
          currentSave: 20,
        );
        expect(resNeg['need'], 0);
        expect(resNeg['want'], 30);
        expect(resNeg['save'], 70);

        final resOver = MonedaValidator.autoBalanceSliders(
          changedJar: 'WANT',
          newValue: 150,
          currentNeed: 50,
          currentWant: 30,
          currentSave: 20,
        );
        expect(resOver['need'], 0);
        expect(resOver['want'], 100);
        expect(resOver['save'], 0);
      });
    });
  });

  // ===========================================================================
  // PHẦN B: WIDGET TEST MÀN HÌNH THẬT ĐÃ KẾT NỐI MONEDAVALIDATOR
  // ===========================================================================
  group('Phần B - Widget Test màn hình thật kết nối MonedaValidator', () {
    testWidgets('ReceiveMoneyScreen: Tính toán phân bổ thời gian thực và khóa/mở nút Tiếp tục',
        (WidgetTester tester) async {
      MonedaService.cachedSettings = {
        'id': 1,
        'total_balance': 20000000.0,
        'need_ratio': 50,
        'want_ratio': 30,
        'save_ratio': 20,
      };
      MonedaService.cachedJars = [
        {'id': 1, 'jar_type': 'NEED', 'balance': 10000000.0},
        {'id': 2, 'jar_type': 'WANT', 'balance': 6000000.0},
        {'id': 3, 'jar_type': 'SAVE', 'balance': 4000000.0},
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: ReceiveMoneyScreen(),
        ),
      );
      await tester.pump();

      // Nút Tiếp tục ban đầu bị khóa do form chưa nhập
      final continueButtonInitial = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Tiếp tục'),
      );
      expect(continueButtonInitial.onPressed, isNull);

      // Nhập nguồn thu nhập và số tiền
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Lương tháng 10');
      await tester.enterText(textFields.at(1), '10,000,000');
      await tester.pump();

      // Kiểm tra 3 thẻ mini card hiển thị đúng số tiền phân bổ qua MonedaValidator
      expect(find.text('5,000,000 VND'), findsOneWidget); // Need 50%
      expect(find.text('3,000,000 VND'), findsOneWidget); // Want 30%
      expect(find.text('2,000,000 VND'), findsOneWidget); // Save 20%

      // Nút Tiếp tục mở khóa khi form hợp lệ
      final continueButtonValid = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Tiếp tục'),
      );
      expect(continueButtonValid.onPressed, isNotNull);

      // Xóa nguồn thu -> nút tự động bị khóa lại
      await tester.enterText(textFields.at(0), '');
      await tester.pump();
      final continueButtonDisabled = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Tiếp tục'),
      );
      expect(continueButtonDisabled.onPressed, isNull);
    });

    testWidgets('PaymentScreen: Kiểm tra hợp lệ 4 trường và chặn âm quỹ với cảnh báo đỏ',
        (WidgetTester tester) async {
      MonedaService.cachedSettings = {
        'id': 1,
        'total_balance': 10000000.0,
        'need_ratio': 50,
        'want_ratio': 30,
        'save_ratio': 20,
      };
      MonedaService.cachedJars = [
        {'id': 1, 'jar_type': 'NEED', 'balance': 500000.0},
        {'id': 2, 'jar_type': 'WANT', 'balance': 300000.0},
        {'id': 3, 'jar_type': 'SAVE', 'balance': 200000.0},
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: PaymentScreen(),
        ),
      );
      await tester.pump();

      final textFields = find.byType(TextField);
      // Nhập danh mục
      await tester.enterText(textFields.at(0), 'Ăn uống');
      // Nhập số tiền vượt quá số dư Hũ NEED (500,000)
      await tester.enterText(textFields.at(1), '750,000');
      // Nhập nội dung
      await tester.enterText(textFields.at(2), 'Tiệc liên hoan');
      await tester.pump();

      // Xuất hiện cảnh báo chống âm quỹ màu đỏ do MonedaValidator.validateExpense trả về
      expect(find.textContaining('Số dư trong Hũ NEED không đủ'), findsOneWidget);

      // Nút Tiếp tục bị mờ và khóa
      final continueBtnExceeded = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Tiếp tục'),
      );
      expect(continueBtnExceeded.onPressed, isNull);

      // Đổi số tiền về mức hợp lệ <= 500,000 VND
      await tester.enterText(textFields.at(1), '200,000');
      await tester.pump();

      // Cảnh báo biến mất và nút Tiếp tục được mở khóa
      expect(find.textContaining('Số dư trong Hũ NEED không đủ'), findsNothing);
      final continueBtnValid = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Tiếp tục'),
      );
      expect(continueBtnValid.onPressed, isNotNull);
    });

    testWidgets('SettingsModal: Slider tự cân bằng Tab 1 và kiểm tra chuyển tiền nội bộ Tab 2',
        (WidgetTester tester) async {
      final settings = AppSettings(
        id: 1,
        totalBalance: 10000000,
        needRatio: 50,
        wantRatio: 30,
        saveRatio: 20,
      );
      final jars = {
        'NEED': Jar(jarType: 'NEED', balance: 5000000),
        'WANT': Jar(jarType: 'WANT', balance: 3000000),
        'SAVE': Jar(jarType: 'SAVE', balance: 2000000),
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
      await tester.pump();

      // Tab 1: Kiểm tra tổng tỷ lệ ban đầu
      expect(find.text('100% (Hợp lệ)'), findsOneWidget);

      // Tab 2: Chuyển sang Tab Chuyển tiền nội bộ
      await tester.tap(find.text('Chuyển tiền nội bộ'));
      await tester.pump();

      // Nút Xác nhận chuyển ban đầu bị khóa do amount = 0
      final transferBtnInitial = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Xác nhận chuyển'),
      );
      expect(transferBtnInitial.onPressed, isNull);

      // Nhập số tiền chuyển vượt quá số dư hũ nguồn (NEED balance = 5,000,000)
      final transferAmountField = find.byType(TextField);
      await tester.enterText(transferAmountField, '6,000,000');
      await tester.pump();

      // Cảnh báo số dư không đủ và nút vẫn bị khóa
      expect(find.textContaining('Số dư trong Hũ NEED không đủ'), findsOneWidget);
      final transferBtnExceeded = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Xác nhận chuyển'),
      );
      expect(transferBtnExceeded.onPressed, isNull);

      // Nhập số tiền hợp lệ <= 5,000,000 VND
      await tester.enterText(transferAmountField, '1,500,000');
      await tester.pump();

      // Nút Xác nhận chuyển được mở khóa
      expect(find.textContaining('Số dư trong Hũ NEED không đủ'), findsNothing);
      final transferBtnValid = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Xác nhận chuyển'),
      );
      expect(transferBtnValid.onPressed, isNotNull);
    });

    testWidgets('SavingGoalsScreen: Modal Thêm mục tiêu tiết kiệm khóa/mở nút Lưu qua MonedaValidator',
        (WidgetTester tester) async {
      MonedaService.cachedSettings = {
        'id': 1,
        'total_balance': 15000000.0,
        'need_ratio': 50,
        'want_ratio': 30,
        'save_ratio': 20,
      };
      MonedaService.cachedJars = [
        {'id': 1, 'jar_type': 'SAVE', 'balance': 3000000.0},
      ];
      MonedaService.cachedSavingGoals = [];

      await tester.pumpWidget(
        const MaterialApp(
          home: SavingGoalsScreen(),
        ),
      );
      await tester.pump();

      // Mở modal "+ Thêm mới"
      await tester.tap(find.text('+ Thêm mới'));
      await tester.pumpAndSettle();

      expect(find.text('Thêm mục tiêu tiết kiệm'), findsOneWidget);

      // Nút Lưu mục tiêu ban đầu bị khóa
      final saveBtnInitial = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Lưu mục tiêu'),
      );
      expect(saveBtnInitial.onPressed, isNull);

      // Nhập tên và số tiền mục tiêu
      final dialogTextFields = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(dialogTextFields.at(0), 'Mua máy tính mới');
      await tester.enterText(dialogTextFields.at(1), '25,000,000');
      await tester.pump();

      // Nút Lưu mục tiêu mở khóa thành công
      final saveBtnValid = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Lưu mục tiêu'),
      );
      expect(saveBtnValid.onPressed, isNotNull);
    });

    testWidgets('ReportScreen: Mặc định đóng thẻ danh mục, bấm để mở và đóng lại khi chuyển hũ',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      MonedaService.cachedSettings = {
        'id': 1,
        'total_balance': 15000000.0,
        'need_ratio': 50,
        'want_ratio': 30,
        'save_ratio': 20,
      };
      MonedaService.cachedMonthlyReports['2026-10'] = {
        'month': 10,
        'year': 2026,
        'monthly_income': 15000000.0,
        'all_expenses': [
          {
            'id': 101,
            'jar_type': 'NEED',
            'category': 'Ăn uống',
            'title': 'Cơm trưa văn phòng',
            'amount': 50000.0,
            'transaction_date': '2026-10-15T12:00:00Z',
          },
          {
            'id': 102,
            'jar_type': 'WANT',
            'category': 'Giải trí',
            'title': 'Xem phim CGV',
            'amount': 200000.0,
            'transaction_date': '2026-10-16T19:00:00Z',
          },
        ],
      };

      await tester.pumpWidget(
        const MaterialApp(
          home: ReportScreen(initialMonth: 10, initialYear: 2026),
        ),
      );
      await tester.pump();

      // 1. Kiểm tra danh mục "Ăn uống" hiển thị nhưng các khoản chi bên trong mặc định đóng (collapsed)
      expect(find.text('Ăn uống'), findsOneWidget);
      expect(find.text('Cơm trưa văn phòng'), findsNothing);

      // 2. Chạm vào thẻ "Ăn uống" để mở rộng
      await tester.tap(find.text('Ăn uống'));
      await tester.pumpAndSettle();

      // Danh sách khoản chi bên trong đã hiển thị
      expect(find.text('Cơm trưa văn phòng'), findsOneWidget);

      // 3. Chuyển sang "Hũ WANT": thẻ danh mục của hũ mới phải tự động đóng
      await tester.tap(find.text('Hũ WANT').first);
      await tester.pumpAndSettle();

      expect(find.text('Giải trí'), findsOneWidget);
      expect(find.text('Xem phim CGV'), findsNothing); // Đóng mặc định
    });
  });
}
