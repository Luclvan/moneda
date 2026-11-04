import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneda/models/app_settings.dart';
import 'package:moneda/models/jar.dart';
import 'package:moneda/screens/app_settings_screen.dart';
import 'package:moneda/screens/auth_screen.dart';
import 'package:moneda/screens/home_screen.dart';
import 'package:moneda/screens/user_profile_screen.dart';
import 'package:moneda/services/moneda_service.dart';
import 'package:moneda/widgets/mb_menu_drawer.dart';
import 'package:moneda/widgets/settings_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockProfileService extends MonedaService {
  String currentFullName = 'Lê Văn Lực';
  String currentUsername = 'levanluc';
  String? updatedFullName;
  String? updatedPassword;
  bool signedOut = false;

  @override
  Future<AppSettings> getAppSettings() async {
    return AppSettings(
      id: 1,
      totalBalance: 10000000,
      needRatio: 50,
      wantRatio: 30,
      saveRatio: 20,
    );
  }

  @override
  Future<Map<String, Jar>> getJars() async {
    return {
      'NEED': Jar(jarType: 'NEED', balance: 5000000),
      'WANT': Jar(jarType: 'WANT', balance: 3000000),
      'SAVE': Jar(jarType: 'SAVE', balance: 2000000),
    };
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile() async {
    final profile = {
      'user_id': 'test-uid-123',
      'username': currentUsername,
      'full_name': currentFullName,
    };
    MonedaService.cachedUserProfile = profile;
    return profile;
  }

  @override
  Future<void> updateFullName(String newFullName) async {
    currentFullName = newFullName;
    updatedFullName = newFullName;
    MonedaService.cachedUserProfile?['full_name'] = newFullName;
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    updatedPassword = newPassword;
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
    MonedaService.cachedUserProfile = null;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('SettingsModal Title Check', () {
    testWidgets('Header displays "Tiện ích"', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsModal(
              settings: AppSettings(
                id: 1,
                totalBalance: 1000000,
                needRatio: 50,
                wantRatio: 30,
                saveRatio: 20,
              ),
              jars: {
                'NEED': Jar(jarType: 'NEED', balance: 500000),
                'WANT': Jar(jarType: 'WANT', balance: 300000),
                'SAVE': Jar(jarType: 'SAVE', balance: 200000),
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tiện ích'), findsOneWidget);
      expect(find.text('Cài đặt Moneda'), findsNothing);
    });
  });

  group('MbMenuDrawer Widget Tests', () {
    testWidgets('renders all MB Bank layout sections and elements',
        (tester) async {
      MonedaService.cachedUserProfile = {
        'username': 'levanluc',
        'full_name': 'Lê Văn Lực',
      };

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            endDrawer: MbMenuDrawer(),
            body: Center(child: Text('Home')),
          ),
        ),
      );

      // Open drawer
      final scaffoldState =
          tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openEndDrawer();
      await tester.pumpAndSettle();

      // Check header info
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.text('LÊ VĂN LỰC'), findsOneWidget);
      expect(find.text('Hồ sơ người dùng'), findsOneWidget);

      // Check menu items
      expect(find.text('Tiện ích'), findsOneWidget);
      expect(find.text('Cài đặt'), findsOneWidget);
      expect(find.text('NEW'), findsOneWidget);
      expect(find.text('Hội viên Moneda'), findsOneWidget);
      expect(find.text('Basic'), findsOneWidget);

      // Check bottom items
      expect(find.text('Ngôn ngữ'), findsOneWidget);
      expect(find.text('Tiếng Việt'), findsOneWidget);
      expect(find.text('Đăng xuất'), findsOneWidget);
      expect(find.text('v1.0.0'), findsOneWidget);
      expect(find.text('Phiên bản mới nhất'), findsOneWidget);
    });

    testWidgets('tapping "Tiện ích" triggers onOpenUtilities callback',
        (tester) async {
      bool openedUtilities = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            endDrawer: MbMenuDrawer(
              onOpenUtilities: () {
                openedUtilities = true;
              },
            ),
            body: const Center(child: Text('Home')),
          ),
        ),
      );

      final scaffoldState =
          tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openEndDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tiện ích'));
      await tester.pumpAndSettle();

      expect(openedUtilities, isTrue);
    });

    testWidgets('tapping "Đăng xuất" shows confirm dialog and handles sign out',
        (tester) async {
      final mockService = MockProfileService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            endDrawer: MbMenuDrawer(monedaService: mockService),
            body: const Center(child: Text('Home')),
          ),
        ),
      );

      final scaffoldState =
          tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openEndDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();

      expect(find.text('Đăng xuất tài khoản'), findsOneWidget);
      expect(
        find.text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản hiện tại không?'),
        findsOneWidget,
      );

      // Confirm sign out
      await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng xuất'));
      await tester.pumpAndSettle();

      expect(mockService.signedOut, isTrue);
      expect(find.byType(AuthScreen), findsOneWidget);
    });
  });

  group('UserProfileScreen Widget Tests', () {
    testWidgets('renders header card and options card properly',
        (tester) async {
      final mockService = MockProfileService();

      await tester.pumpWidget(
        MaterialApp(
          home: UserProfileScreen(monedaService: mockService),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hồ sơ người dùng'), findsOneWidget);
      expect(find.text('LÊ VĂN LỰC'), findsOneWidget);
      expect(find.text('User ID: levanluc'), findsOneWidget);
      expect(find.text('Tăng cường bảo vệ'), findsOneWidget);
      expect(find.text('Gói hội viên Moneda'), findsOneWidget);
      expect(find.text('Basic'), findsOneWidget);

      expect(find.text('Đổi họ và tên hiển thị'), findsOneWidget);
      expect(find.text('Tên đăng nhập (User ID)'), findsOneWidget);
      expect(find.text('Đổi mật khẩu'), findsOneWidget);
    });

    testWidgets('edit full name dialog validates and updates name',
        (tester) async {
      final mockService = MockProfileService();

      await tester.pumpWidget(
        MaterialApp(
          home: UserProfileScreen(monedaService: mockService),
        ),
      );
      await tester.pumpAndSettle();

      // Tap pencil icon on Avatar
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Đổi họ và tên hiển thị'), findsNWidgets(2)); // Card & Dialog

      final inputFinder = find.widgetWithText(TextField, 'Lê Văn Lực');
      await tester.enterText(inputFinder, 'Nguyễn Văn A');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      expect(mockService.updatedFullName, 'Nguyễn Văn A');
      expect(find.text('NGUYỄN VĂN A'), findsOneWidget);
    });

    testWidgets('change password dialog validates min 6 chars and mismatch',
        (tester) async {
      final mockService = MockProfileService();

      await tester.pumpWidget(
        MaterialApp(
          home: UserProfileScreen(monedaService: mockService),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Đổi mật khẩu"
      await tester.tap(find.text('Đổi mật khẩu'));
      await tester.pumpAndSettle();

      expect(find.text('Mật khẩu mới'), findsOneWidget);
      expect(find.text('Xác nhận mật khẩu mới'), findsOneWidget);

      final newPassField = find.widgetWithText(TextField, 'Tối thiểu 6 ký tự');
      final confirmPassField =
          find.widgetWithText(TextField, 'Nhập lại mật khẩu mới');

      // Test < 6 chars
      await tester.enterText(newPassField, '123');
      await tester.enterText(confirmPassField, '123');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cập nhật'));
      await tester.pumpAndSettle();

      expect(
        find.text('Mật khẩu cần tối thiểu 6 ký tự (hiện tại: 3/6 ký tự)'),
        findsOneWidget,
      );

      // Test mismatch
      await tester.enterText(newPassField, 'pass123');
      await tester.enterText(confirmPassField, 'pass456');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cập nhật'));
      await tester.pumpAndSettle();

      expect(find.text('Mật khẩu nhập lại chưa khớp'), findsOneWidget);

      // Test valid matching passwords
      await tester.enterText(confirmPassField, 'pass123');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cập nhật'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      expect(mockService.updatedPassword, 'pass123');
    });
  });

  group('HomeScreen Menu ☰ opens MbMenuDrawer', () {
    testWidgets('tapping ☰ opens MbMenuDrawer', (tester) async {
      MonedaService.cachedSettings = {
        'id': 1,
        'total_balance': 10000000,
        'need_ratio': 50,
        'want_ratio': 30,
        'save_ratio': 20,
      };
      MonedaService.cachedJars = [
        {'id': 1, 'jar_type': 'NEED', 'balance': 5000000},
        {'id': 2, 'jar_type': 'WANT', 'balance': 3000000},
        {'id': 3, 'jar_type': 'SAVE', 'balance': 2000000},
      ];
      MonedaService.cachedRecentTransactions = [];
      MonedaService.cachedUserProfile = {
        'username': 'levanluc',
        'full_name': 'Lê Văn Lực',
      };

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MbMenuDrawer), findsNothing);

      final popScope = tester.widget<PopScope>(find.byType(PopScope));
      expect(popScope.canPop, isFalse);

      // Tap ☰ icon
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(MbMenuDrawer), findsOneWidget);
      expect(find.text('LÊ VĂN LỰC'), findsOneWidget);
    });
  });

  group('AppSettingsScreen Widget Tests', () {
    testWidgets('renders all MB Bank layout sections and elements',
        (tester) async {
      final mockService = MockProfileService();
      MonedaService.cachedUserProfile = {
        'username': 'levanluc',
        'full_name': 'Lê Văn Lực',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: AppSettingsScreen(
            monedaService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top AppBar
      expect(find.text('Cài đặt'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);

      // Group 1: Bảo mật
      expect(find.text('Bảo mật'), findsOneWidget);
      expect(find.text('Đổi mật khẩu'), findsOneWidget);

      // Group 2: Tiện ích ngân sách
      expect(find.text('Tiện ích ngân sách'), findsOneWidget);
      expect(find.text('Cài đặt tỷ lệ 3 hũ (50/30/20)'), findsOneWidget);
      expect(find.text('Chuyển tiền nội bộ giữa các hũ'), findsOneWidget);
    });

    testWidgets('tapping "Cài đặt tỷ lệ 3 hũ" opens SettingsModal tab 0',
        (tester) async {
      final mockService = MockProfileService();
      await tester.pumpWidget(
        MaterialApp(
          home: AppSettingsScreen(monedaService: mockService),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cài đặt tỷ lệ 3 hũ (50/30/20)'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsModal), findsOneWidget);
      expect(find.text('Tiện ích'), findsOneWidget);
      expect(find.text('Cài đặt tỷ lệ 3 hũ'), findsOneWidget);
    });

    testWidgets(
        'tapping "Chuyển tiền nội bộ giữa các hũ" opens SettingsModal tab 1',
        (tester) async {
      final mockService = MockProfileService();
      await tester.pumpWidget(
        MaterialApp(
          home: AppSettingsScreen(monedaService: mockService),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chuyển tiền nội bộ giữa các hũ'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsModal), findsOneWidget);
      expect(find.text('Chuyển tiền nội bộ'), findsOneWidget);
    });

    testWidgets('change password dialog validates and updates password',
        (tester) async {
      final mockService = MockProfileService();
      await tester.pumpWidget(
        MaterialApp(
          home: AppSettingsScreen(monedaService: mockService),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Đổi mật khẩu'));
      await tester.pumpAndSettle();

      expect(find.text('Mật khẩu mới'), findsOneWidget);
      expect(find.text('Xác nhận mật khẩu mới'), findsOneWidget);

      final newPassField = find.widgetWithText(TextField, 'Tối thiểu 6 ký tự');
      final confirmPassField =
          find.widgetWithText(TextField, 'Nhập lại mật khẩu mới');

      // Test validation mismatch
      await tester.enterText(newPassField, 'password123');
      await tester.enterText(confirmPassField, 'differentpass');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cập nhật'));
      await tester.pumpAndSettle();

      expect(find.text('Mật khẩu nhập lại chưa khớp'), findsOneWidget);

      // Fix matching password
      await tester.enterText(confirmPassField, 'password123');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cập nhật'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(mockService.updatedPassword, 'password123');
      expect(find.text('Đã đổi mật khẩu thành công'), findsOneWidget);

      // Settle toast timer
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    });
  });

  group('Navigation to AppSettingsScreen Tests', () {
    testWidgets('MbMenuDrawer "Cài đặt" navigates to AppSettingsScreen',
        (tester) async {
      final mockService = MockProfileService();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            endDrawer: MbMenuDrawer(monedaService: mockService),
            body: const Center(child: Text('Home')),
          ),
        ),
      );

      final scaffoldState =
          tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openEndDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cài đặt'));
      await tester.pumpAndSettle();

      expect(find.byType(AppSettingsScreen), findsOneWidget);
    });

    testWidgets(
        'UserProfileScreen "Tăng cường bảo vệ" navigates to AppSettingsScreen',
        (tester) async {
      final mockService = MockProfileService();
      await tester.pumpWidget(
        MaterialApp(
          home: UserProfileScreen(monedaService: mockService),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tăng cường bảo vệ'));
      await tester.pumpAndSettle();

      expect(find.byType(AppSettingsScreen), findsOneWidget);
    });

    testWidgets('AppSettingsScreen home icon button pops to root',
        (tester) async {
      final mockService = MockProfileService();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(builder: (ctx) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) =>
                          AppSettingsScreen(monedaService: mockService),
                    ),
                  );
                },
                child: const Text('Open Settings'),
              );
            }),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(AppSettingsScreen), findsOneWidget);

      // Tap home icon
      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(AppSettingsScreen), findsNothing);
      expect(find.text('Open Settings'), findsOneWidget);
    });
  });
}

