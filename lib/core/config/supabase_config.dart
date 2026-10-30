import 'package:supabase_flutter/supabase_flutter.dart';

/// Cấu hình kết nối Supabase
class SupabaseConfig {
  SupabaseConfig._();

  /// Endpoint REST API gốc được cấu hình
  static const String endpoint =
      'https://jlswvtzmycervszszhuo.supabase.co/rest/v1/';

  /// Supabase project URL chuẩn (dùng cho SDK)
  static const String supabaseUrl = 'https://jlswvtzmycervszszhuo.supabase.co';

  /// Supabase Public Anon Key
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impsc3d2dHpteWNlcnZzenN6aHVvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMyNjc1ODAsImV4cCI6MjEwODg0MzU4MH0.S5iCrhgFWwhjcwTJPj3FwtK8mXFR5LmZNJ_3j_QmgcI';

  /// Shortcut lấy instance Supabase client
  static SupabaseClient get client => Supabase.instance.client;
}

