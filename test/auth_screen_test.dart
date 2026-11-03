import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneda/main.dart';
import 'package:moneda/screens/auth_screen.dart';
import 'package:moneda/screens/home_screen.dart';
import 'package:moneda/screens/register_screen.dart';
import 'package:moneda/services/moneda_service.dart';
import 'package:moneda/utils/moneda_validator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthMonedaService extends MonedaService {
  String? lastSignedInUser;
  String? lastSignedInPass;
  String? lastSignedUpName;
  String? lastSignedUpUser;
  String? lastSignedUpPass;
  bool shouldThrowError = false;
  String errorMessage = 'Invalid login credentials';

  Map<String, String>? mockSavedUser;

  @override
  Future<Map<String, String>?> getLastLoggedInUser() async {
    return mockSavedUser;
  }

  @override
  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    if (shouldThrowError) {
      throw Exception(errorMessage);
    }
    lastSignedInUser = username;
    lastSignedInPass = password;
  }

  @override
  Future<void> signUp({
    required String fullName,
    required String username,
    required String password,
  }) async {
    if (shouldThrowError) {
      throw Exception(errorMessage);
    }
    lastSignedUpName = fullName;
    lastSignedUpUser = username;
    lastSignedUpPass = password;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('MonedaValidator Auth & Inline Validation Tests', () {
    test('validateFullName enforces non-empty and >= 2 chars', () {
      expect(
        MonedaValidator.validateFullName(null),
        'Vui lòng nhập họ và tên hiển thị',
      );
      expect(
        MonedaValidator.validateFullName(''),
        'Vui lòng nhập họ và tên hiển thị',
      );
      expect(
        MonedaValidator.validateFullName('A'),
        'Họ và tên phải có ít nhất 2 ký tự',
      );
      expect(MonedaValidator.validateFullName('Lê Văn Lực'), isNull);
    });

    test('validateUsername enforces min 3 chars and valid characters', () {
      expect(
        MonedaValidator.validateUsername(null),
        'Vui lòng nhập tên đăng nhập',
      );
      expect(
        MonedaValidator.validateUsername(''),
        'Vui lòng nhập tên đăng nhập',
      );
      expect(
        MonedaValidator.validateUsername('ab'),
        'Tên đăng nhập cần tối thiểu 3 ký tự',
      );
      expect(
        MonedaValidator.validateUsername('le van luc'),
        'Tên đăng nhập chỉ gồm chữ không dấu, số, dấu chấm (.) hoặc gạch dưới (_)',
      );
      expect(
        MonedaValidator.validateUsername('luc@123'),
        'Tên đăng nhập chỉ gồm chữ không dấu, số, dấu chấm (.) hoặc gạch dưới (_)',
      );
      expect(MonedaValidator.validateUsername('luc.van_99'), isNull);
      expect(MonedaValidator.validateUsername('levanluc'), isNull);
    });

    test('validatePassword enforces min 6 chars with dynamic count', () {
      expect(
        MonedaValidator.validatePassword(null),
        'Vui lòng nhập mật khẩu',
      );
      expect(
        MonedaValidator.validatePassword(''),
        'Vui lòng nhập mật khẩu',
      );
      expect(
        MonedaValidator.validatePassword('123'),
        'Mật khẩu cần tối thiểu 6 ký tự (hiện tại: 3/6 ký tự)',
      );
      expect(MonedaValidator.validatePassword('pass123'), isNull);
    });

    test('validateConfirmPassword enforces match', () {
      expect(
        MonedaValidator.validateConfirmPassword('pass123', null),
        'Mật khẩu nhập lại chưa khớp',
      );
      expect(
        MonedaValidator.validateConfirmPassword('pass123', 'pass456'),
        'Mật khẩu nhập lại chưa khớp',
      );
      expect(
        MonedaValidator.validateConfirmPassword('pass123', 'pass123'),
        isNull,
      );
    });

    test('formatAuthErrorMessage translates Supabase errors properly', () {
      expect(
        MonedaService.formatAuthErrorMessage('Invalid login credentials'),
        'Tên đăng nhập hoặc mật khẩu không chính xác',
      );
      expect(
        MonedaService.formatAuthErrorMessage('User already registered'),
        'Tên đăng nhập này đã tồn tại, vui lòng chọn tên khác',
      );
      expect(
        MonedaService.formatAuthErrorMessage('over_email_send_rate_limit'),
        'Bạn thao tác quá nhanh, vui lòng đợi 1 phút hoặc tắt Confirm Email trên Supabase',
      );
    });
  });

  group('AuthScreen Trạng thái A (Đăng nhập Lần đầu) Widget Tests', () {
    testWidgets('renders brand MONEDA, header, fields and version text',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthScreen(forceFirstTime: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MONEDA'), findsOneWidget);
      expect(find.text('Chào mừng bạn đến với Moneda'), findsOneWidget);
      expect(find.text('Tên đăng nhập'), findsOneWidget);
      expect(find.text('Mật khẩu'), findsOneWidget);
      expect(find.text('Tạo tài khoản'), findsOneWidget);
      expect(find.text('Quên mật khẩu?'), findsOneWidget);
      expect(find.text('Phiên bản v1.0.0   Phiên bản mới nhất'), findsOneWidget);
    });

    testWidgets('shows real-time inline errors when typing invalid inputs',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthScreen(forceFirstTime: true),
        ),
      );
      await tester.pumpAndSettle();

      final usernameField = find.widgetWithText(TextField, 'Nhập tên đăng nhập');
      final passwordField = find.widgetWithText(TextField, 'Nhập mật khẩu');

      // Type username < 3 chars
      await tester.enterText(usernameField, 'ab');
      await tester.pumpAndSettle();
      expect(find.text('Tên đăng nhập cần tối thiểu 3 ký tự'), findsOneWidget);

      // Type password < 6 chars
      await tester.enterText(passwordField, '123');
      await tester.pumpAndSettle();
      expect(
        find.text('Mật khẩu cần tối thiểu 6 ký tự (hiện tại: 3/6 ký tự)'),
        findsOneWidget,
      );

      // Fix username and password
      await tester.enterText(usernameField, 'levanluc');
      await tester.enterText(passwordField, 'secret123');
      await tester.pumpAndSettle();

      expect(find.text('Tên đăng nhập cần tối thiểu 3 ký tự'), findsNothing);
      expect(
        find.text('Mật khẩu cần tối thiểu 6 ký tự (hiện tại: 3/6 ký tự)'),
        findsNothing,
      );
    });

    testWidgets('login button toggles disabled and enabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthScreen(forceFirstTime: true),
        ),
      );
      await tester.pumpAndSettle();

      final loginBtnFinder = find.widgetWithText(ElevatedButton, 'Đăng nhập');
      ElevatedButton btn = tester.widget(loginBtnFinder);
      expect(btn.onPressed, isNull);

      await tester.enterText(
        find.widgetWithText(TextField, 'Nhập tên đăng nhập'),
        'levanluc',
      );
      await tester.pumpAndSettle();
      btn = tester.widget(loginBtnFinder);
      expect(btn.onPressed, isNull); // Still disabled without password

      await tester.enterText(
        find.widgetWithText(TextField, 'Nhập mật khẩu'),
        'pass123456',
      );
      await tester.pumpAndSettle();
      btn = tester.widget(loginBtnFinder);
      expect(btn.onPressed, isNotNull); // Enabled!
    });

    testWidgets('tapping "Tạo tài khoản" navigates to RegisterScreen',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthScreen(forceFirstTime: true),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tạo tài khoản'));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);
    });

    testWidgets('failed login shows readable Vietnamese error alert',
        (tester) async {
      final mockService = MockAuthMonedaService()
        ..shouldThrowError = true
        ..errorMessage = 'Invalid login credentials';

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(
            monedaService: mockService,
            forceFirstTime: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Nhập tên đăng nhập'),
        'wronguser',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Nhập mật khẩu'),
        'wrongpass',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
      await tester.pumpAndSettle();

      expect(
        find.text('Tên đăng nhập hoặc mật khẩu không chính xác'),
        findsOneWidget,
      );
    });

  });

  group('AuthScreen Trạng thái B (Đăng nhập Lần 2+) Widget Tests', () {
    testWidgets(
        'renders returning user UI with full name & single password field',
        (tester) async {
      final mockService = MockAuthMonedaService()
        ..mockSavedUser = {
          'username': 'levanluc',
          'full_name': 'LÊ VĂN LỰC',
        };

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(monedaService: mockService),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Xin chào,'), findsOneWidget);
      expect(find.text('LÊ VĂN LỰC'), findsOneWidget);
      expect(find.text('Tên đăng nhập'), findsNothing); // Hidden in State B
      expect(find.text('Mật khẩu'), findsOneWidget);
      expect(find.text('Tài khoản khác'), findsOneWidget);

      // Tapping "Tài khoản khác" switches to State A
      await tester.tap(find.text('Tài khoản khác'));
      await tester.pumpAndSettle();

      expect(find.text('Chào mừng bạn đến với Moneda'), findsOneWidget);
      expect(find.text('Quay lại (levanluc)'), findsOneWidget);

      // Tapping "Quay lại" switches back to State B
      await tester.tap(find.text('Quay lại (levanluc)'));
      await tester.pumpAndSettle();

      expect(find.text('LÊ VĂN LỰC'), findsOneWidget);
    });

    testWidgets('successful sign in from State B invokes service and navigates',
        (tester) async {
      final mockService = MockAuthMonedaService()
        ..mockSavedUser = {
          'username': 'levanluc',
          'full_name': 'LÊ VĂN LỰC',
        };

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(monedaService: mockService),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Nhập mật khẩu'),
        'mypass123',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      expect(mockService.lastSignedInUser, 'levanluc');
      expect(mockService.lastSignedInPass, 'mypass123');
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('RegisterScreen Widget Tests', () {
    testWidgets('renders all 3 groups and enforces inline validations',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đăng ký tài khoản'), findsOneWidget);
      expect(find.text('Thông tin cá nhân'), findsOneWidget);
      expect(find.text('Thiết lập bảo mật'), findsOneWidget);
      expect(find.text('Quy tắc ngân sách khởi tạo'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('30%'), findsOneWidget);
      expect(find.text('20%'), findsOneWidget);

      final continueBtnFinder =
          find.widgetWithText(ElevatedButton, 'Tiếp tục');
      ElevatedButton btn = tester.widget(continueBtnFinder);
      expect(btn.onPressed, isNull);

      // 1. Enter full name
      await tester.enterText(
        find.widgetWithText(TextField, 'VD: LE VAN LUC'),
        'Lê Văn Lực',
      );
      await tester.pumpAndSettle();

      // 2. Enter username
      await tester.enterText(
        find.widgetWithText(TextField, 'VD: luclvan'),
        'luclvan',
      );
      await tester.pumpAndSettle();

      // 3. Enter password
      await tester.enterText(
        find.widgetWithText(TextField, 'Tối thiểu 6 ký tự'),
        'pass123456',
      );
      // 4. Enter confirm password mismatch
      await tester.enterText(
        find.widgetWithText(TextField, 'Nhập lại mật khẩu'),
        'pass999999',
      );
      await tester.pumpAndSettle();

      expect(find.text('Mật khẩu nhập lại chưa khớp'), findsOneWidget);
      btn = tester.widget(continueBtnFinder);
      expect(btn.onPressed, isNull);

      // Match confirm password
      await tester.enterText(
        find.widgetWithText(TextField, 'Nhập lại mật khẩu'),
        'pass123456',
      );
      await tester.pumpAndSettle();
      expect(find.text('Mật khẩu nhập lại chưa khớp'), findsNothing);

      btn = tester.widget(continueBtnFinder);
      expect(btn.onPressed, isNotNull); // Enabled!
    });

    testWidgets('successful registration invokes service and goes to HomeScreen',
        (tester) async {
      final mockService = MockAuthMonedaService();

      await tester.pumpWidget(
        MaterialApp(
          home: RegisterScreen(monedaService: mockService),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'VD: LE VAN LUC'),
        'Lê Văn Lực',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'VD: luclvan'),
        'luclvan',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Tối thiểu 6 ký tự'),
        'pass123456',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Nhập lại mật khẩu'),
        'pass123456',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Tiếp tục'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      expect(mockService.lastSignedUpName, 'Lê Văn Lực');
      expect(mockService.lastSignedUpUser, 'luclvan');
      expect(mockService.lastSignedUpPass, 'pass123456');
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  testWidgets('MonedaApp widget defaults to AuthScreen when not authenticated',
      (tester) async {
    await tester.pumpWidget(const MonedaApp());
    await tester.pumpAndSettle();

    expect(find.byType(AuthScreen), findsOneWidget);
  });
}
