import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneda/core/constants/app_colors.dart';
import 'package:moneda/widgets/biometric_system_icon.dart';

void main() {
  group('BiometricSystemIcon Widget Tests', () {
    testWidgets('renders Face ID Apple viewfinder on iOS theme or isFaceId=true',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          themeMode: ThemeMode.light,
          home: Scaffold(
            body: Center(
              child: BiometricSystemIcon(
                size: 32,
                color: AppColors.primaryBlue,
                isFaceId: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(CupertinoIcons.viewfinder), findsOneWidget);
      expect(find.byIcon(Icons.face_unlock_rounded), findsOneWidget);
      expect(find.byIcon(Icons.fingerprint_rounded), findsNothing);
    });

    testWidgets('renders Face ID on iOS platform theme when isFaceId is null',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: const Scaffold(
            body: Center(
              child: BiometricSystemIcon(size: 28),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(CupertinoIcons.viewfinder), findsOneWidget);
      expect(find.byIcon(Icons.face_unlock_rounded), findsOneWidget);
      expect(find.byIcon(Icons.fingerprint_rounded), findsNothing);
    });

    testWidgets('renders Fingerprint on Android platform theme or isFaceId=false',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: BiometricSystemIcon(
                size: 32,
                isFaceId: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.fingerprint_rounded), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.viewfinder), findsNothing);
      expect(find.byIcon(Icons.face_unlock_rounded), findsNothing);
    });

    testWidgets('renders Fingerprint on Android platform theme when isFaceId is null',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: const Scaffold(
            body: Center(
              child: BiometricSystemIcon(size: 28),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.fingerprint_rounded), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.viewfinder), findsNothing);
    });
  });
}

