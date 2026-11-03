import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneda/screens/payment_screen.dart';
import 'package:moneda/screens/receive_money_screen.dart';
import 'package:moneda/services/moneda_service.dart';
import 'package:moneda/widgets/floating_suggestions_field.dart';

void main() {
  group('FloatingSuggestionsField Unit & Widget Tests', () {
    testWidgets('Tapping anywhere in the text field displays suggestions overlay immediately',
        (WidgetTester tester) async {
      final controller = TextEditingController();
      final suggestions = ['Lương tháng', 'Thưởng dự án', 'Đầu tư'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: FloatingSuggestionsField(
                controller: controller,
                suggestions: suggestions,
                hintText: 'Nhập nguồn thu',
              ),
            ),
          ),
        ),
      );

      // Ban đầu overlay chưa hiển thị các gợi ý
      expect(find.text('Lương tháng'), findsNothing);
      expect(find.text('Thưởng dự án'), findsNothing);

      // Chạm vào bất kỳ vị trí nào trên ô TextField
      await tester.tap(find.byType(TextField));
      await tester.pump();

      // Danh sách gợi ý hiển thị ngay lập tức
      expect(find.text('Lương tháng'), findsOneWidget);
      expect(find.text('Thưởng dự án'), findsOneWidget);
      expect(find.text('Đầu tư'), findsOneWidget);
    });

    testWidgets('Tapping a suggestion fills controller, invokes onSelected, and dismisses overlay',
        (WidgetTester tester) async {
      final controller = TextEditingController();
      final suggestions = ['Ăn uống', 'Mua sắm', 'Di chuyển'];
      String? selectedValue;
      String? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: FloatingSuggestionsField(
                controller: controller,
                suggestions: suggestions,
                onChanged: (val) {
                  changedValue = val;
                },
                onSelected: (val) {
                  selectedValue = val;
                },
              ),
            ),
          ),
        ),
      );

      // Chạm mở gợi ý
      await tester.tap(find.byType(TextField));
      await tester.pump();

      // Bấm vào mục 'Mua sắm'
      await tester.tap(find.text('Mua sắm'));
      await tester.pump();

      // Controller được điền đúng giá trị
      expect(controller.text, 'Mua sắm');
      expect(selectedValue, 'Mua sắm');
      expect(changedValue, 'Mua sắm');

      // Khung gợi ý tự đóng lại (chỉ còn chữ trong TextField)
      expect(find.text('Ăn uống'), findsNothing);
      expect(find.text('Di chuyển'), findsNothing);
    });

    testWidgets('Typing filters suggestions in real time',
        (WidgetTester tester) async {
      final controller = TextEditingController();
      final suggestions = ['Cà phê sáng', 'Cơm trưa', 'Trà sữa', 'Cơm tối'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: FloatingSuggestionsField(
                controller: controller,
                suggestions: suggestions,
              ),
            ),
          ),
        ),
      );

      // Chạm mở ô nhập
      await tester.tap(find.byType(TextField));
      await tester.pump();

      // Ban đầu hiển thị tất cả
      expect(find.text('Cơm trưa'), findsOneWidget);
      expect(find.text('Cơm tối'), findsOneWidget);
      expect(find.text('Trà sữa'), findsOneWidget);

      // Gõ chữ "cơm"
      await tester.enterText(find.byType(TextField), 'cơm');
      await tester.pump();

      // Chỉ còn các mục có chữ "cơm"
      expect(find.text('Cơm trưa'), findsOneWidget);
      expect(find.text('Cơm tối'), findsOneWidget);
      expect(find.text('Trà sữa'), findsNothing);
      expect(find.text('Cà phê sáng'), findsNothing);
    });

    testWidgets('Tapping outside dismisses overlay and closes suggestions',
        (WidgetTester tester) async {
      final controller = TextEditingController();
      final suggestions = ['Mục 1', 'Mục 2'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: FloatingSuggestionsField(
                    controller: controller,
                    suggestions: suggestions,
                  ),
                ),
                const SizedBox(height: 100),
                const Text('Vùng trống ngoài ô nhập'),
              ],
            ),
          ),
        ),
      );

      // Chạm mở
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(find.text('Mục 1'), findsOneWidget);

      // Chạm ra ngoài ô nhập
      await tester.tap(find.text('Vùng trống ngoài ô nhập'));
      await tester.pump();

      // Khung gợi ý tự động đóng lại
      expect(find.text('Mục 1'), findsNothing);
    });

    testWidgets('Arrow icon toggles dropdown open and closed',
        (WidgetTester tester) async {
      final controller = TextEditingController();
      final suggestions = ['Danh mục A', 'Danh mục B'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: FloatingSuggestionsField(
                controller: controller,
                suggestions: suggestions,
              ),
            ),
          ),
        ),
      );

      // Bấm vào icon mũi tên để mở
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
      await tester.pump();
      expect(find.text('Danh mục A'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);

      // Bấm vào icon mũi tên lần nữa để đóng
      await tester.tap(find.byIcon(Icons.keyboard_arrow_up_rounded));
      await tester.pump();
      expect(find.text('Danh mục A'), findsNothing);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
    });

    testWidgets('Switching focus to another field closes the overlay',
        (WidgetTester tester) async {
      final c1 = TextEditingController();
      final c2 = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  FloatingSuggestionsField(
                    controller: c1,
                    suggestions: const ['Gợi ý ô 1'],
                    hintText: 'Ô 1',
                  ),
                  const SizedBox(height: 120),
                  TextField(
                    controller: c2,
                    decoration: const InputDecoration(hintText: 'Ô 2'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Chạm mở ô 1
      await tester.tap(find.widgetWithText(TextField, 'Ô 1'));
      await tester.pump();
      expect(find.text('Gợi ý ô 1'), findsOneWidget);

      // Chuyển sang ô 2
      await tester.tap(find.widgetWithText(TextField, 'Ô 2'));
      await tester.pump();

      // Gợi ý ô 1 tự đóng lại
      expect(find.text('Gợi ý ô 1'), findsNothing);
    });

    testWidgets('ReceiveMoneyScreen: Tapping suggestion fills source and updates Continue button',
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

      // Nhập số tiền trước
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(1), '5,000,000');
      await tester.pump();

      // Nút Tiếp tục ban đầu bị khóa do chưa có nguồn thu
      final btnBefore = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Tiếp tục'),
      );
      expect(btnBefore.onPressed, isNull);

      // Nhập chữ 'Lương' vào ô Nguồn thu nhập (ô 0) để lọc gợi ý
      await tester.enterText(textFields.at(0), 'Lương');
      await tester.pump();

      // Bấm vào gợi ý 'Tiền lương'
      expect(find.text('Tiền lương'), findsOneWidget);
      await tester.tap(find.text('Tiền lương'));
      await tester.pump();

      // Giá trị được điền vào ô Nguồn thu nhập
      expect(find.text('Tiền lương'), findsOneWidget);

      // Nút Tiếp tục được kích hoạt mở khóa
      final btnAfter = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Tiếp tục'),
      );
      expect(btnAfter.onPressed, isNotNull);
    });

    testWidgets('PaymentScreen: Tapping suggestion fills category and triggers title suggestions update',
        (WidgetTester tester) async {
      MonedaService.cachedSettings = {
        'id': 1,
        'total_balance': 20000000.0,
        'need_ratio': 50,
        'want_ratio': 30,
        'save_ratio': 20,
      };
      MonedaService.cachedJars = [
        {'id': 1, 'jar_type': 'NEED', 'balance': 5000000.0},
        {'id': 2, 'jar_type': 'WANT', 'balance': 3000000.0},
        {'id': 3, 'jar_type': 'SAVE', 'balance': 2000000.0},
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: PaymentScreen(),
        ),
      );
      await tester.pump();

      final textFields = find.byType(TextField);

      // Gõ chữ 'Ăn' vào ô Danh mục (ô 0)
      await tester.enterText(textFields.at(0), 'Ăn');
      await tester.pump();

      // Bấm chọn mục gợi ý 'Ăn uống'
      expect(find.text('Ăn uống'), findsOneWidget);
      await tester.tap(find.text('Ăn uống'));
      await tester.pump();

      // Giá trị 'Ăn uống' được điền vào TextField
      final catField = tester.widget<TextField>(textFields.at(0));
      expect(catField.controller?.text, 'Ăn uống');
    });
  });
}
