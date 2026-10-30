import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneda/core/utils/currency_formatter.dart';
import 'package:moneda/models/app_settings.dart';
import 'package:moneda/models/jar.dart';
import 'package:moneda/models/transaction_item.dart';
import 'package:moneda/widgets/moneda_bottom_bar.dart';

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

    testWidgets('MonedaBottomBar renders without overflow and handles taps',
        (WidgetTester tester) async {
      int tappedIndex = -1;
      bool paymentTapped = false;

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
            ),
          ),
        ),
      );

      // Kiểm tra sự hiện diện của 3 nhãn điều hướng
      expect(find.text('Trang chủ'), findsOneWidget);
      expect(find.text('Thanh toán'), findsOneWidget);
      expect(find.text('Nhận tiền'), findsOneWidget);

      // Thao tác bấm nút Thanh toán ở giữa
      await tester.tap(find.text('Thanh toán'));
      await tester.pumpAndSettle();

      expect(tappedIndex, 1);
      expect(paymentTapped, true);
    });
  });
}
