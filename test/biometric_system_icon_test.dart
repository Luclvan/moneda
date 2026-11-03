import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneda/core/constants/app_colors.dart';
import 'package:moneda/widgets/biometric_system_icon.dart';

void main() {
  group('BiometricSystemIcon Widget Tests', () {
    testWidgets('renders AppleFaceIdPainter when forceFaceId is true',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: BiometricSystemIcon(
                size: 32,
                color: AppColors.primaryBlue,
                forceFaceId: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final customPaintFinder = find.descendant(
        of: find.byType(BiometricSystemIcon),
        matching: find.byType(CustomPaint),
      );
      expect(customPaintFinder, findsOneWidget);

      final customPaint = tester.widget<CustomPaint>(customPaintFinder);
      expect(customPaint.painter, isA<AppleFaceIdPainter>());

      final painter = customPaint.painter as AppleFaceIdPainter;
      expect(painter.color, AppColors.primaryBlue);

      final sizedBoxFinder = find.descendant(
        of: find.byType(BiometricSystemIcon),
        matching: find.byType(SizedBox),
      );
      final sizedBox = tester.widget<SizedBox>(sizedBoxFinder);
      expect(sizedBox.width, 32);
      expect(sizedBox.height, 32);
    });

    testWidgets('renders SamsungFingerprintPainter when forceFaceId is false',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: BiometricSystemIcon(
                size: 28,
                color: Colors.green,
                forceFaceId: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final customPaintFinder = find.descendant(
        of: find.byType(BiometricSystemIcon),
        matching: find.byType(CustomPaint),
      );
      expect(customPaintFinder, findsOneWidget);

      final customPaint = tester.widget<CustomPaint>(customPaintFinder);
      expect(customPaint.painter, isA<SamsungFingerprintPainter>());

      final painter = customPaint.painter as SamsungFingerprintPainter;
      expect(painter.color, Colors.green);
    });

    testWidgets('renders vector paths without throwing any exceptions',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                BiometricSystemIcon(size: 40, forceFaceId: true),
                BiometricSystemIcon(size: 40, forceFaceId: false),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BiometricSystemIcon), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  });
}
