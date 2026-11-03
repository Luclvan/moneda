import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/constants/app_colors.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo kết nối Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    // ignore: deprecated_member_use
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Cấu hình thanh trạng thái hệ thống
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(const MonedaApp());
}

class MonedaApp extends StatelessWidget {
  const MonedaApp({super.key});

  bool _isLoggedIn() {
    try {
      return Supabase.instance.client.auth.currentSession != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moneda',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.backgroundGray,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          primary: AppColors.primaryBlue,
        ),
      ),
      builder: (context, child) {
        // Bọc GestureDetector hạ bàn phím số khi chạm ngoài trên iPhone thật
        // Bọc giao diện trong khung căn giữa chuẩn Mobile (maxWidth: 430px)
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Container(
            color: kIsWeb ? const Color(0xFFE2E8F0) : AppColors.backgroundGray,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
      home: _isLoggedIn() ? const HomeScreen() : const AuthScreen(),
    );
  }
}
