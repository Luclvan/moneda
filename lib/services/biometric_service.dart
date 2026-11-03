import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Dịch vụ quản lý xác thực sinh trắc học (Face ID / Vân tay)
class BiometricService {
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyBioUsername = 'bio_username';
  static const String keyBioPassword = 'bio_password';

  final LocalAuthentication _auth;
  final FlutterSecureStorage _storage;

  BiometricService({
    LocalAuthentication? localAuth,
    FlutterSecureStorage? secureStorage,
  })  : _auth = localAuth ?? LocalAuthentication(),
        _storage = secureStorage ?? const FlutterSecureStorage();

  /// Kiểm tra thiết bị có hỗ trợ xác thực sinh trắc học không
  Future<bool> isBiometricAvailable() async {
    // Tránh gọi native plugin trên Web gây lỗi crash
    if (kIsWeb) return false;

    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (e) {
      debugPrint('BiometricService.isBiometricAvailable error: $e');
      return false;
    }
  }

  /// Kiểm tra người dùng đã bật Face ID / Vân tay chưa
  Future<bool> isBiometricEnabled() async {
    try {
      final val = await _storage.read(key: keyBiometricEnabled);
      return val == 'true';
    } catch (e) {
      debugPrint('BiometricService.isBiometricEnabled error: $e');
      return false;
    }
  }

  /// Lấy tên đăng nhập đã liên kết với Face ID / Vân tay
  Future<String?> getSavedUsername() async {
    try {
      return await _storage.read(key: keyBioUsername);
    } catch (e) {
      debugPrint('BiometricService.getSavedUsername error: $e');
      return null;
    }
  }

  /// Kích hoạt đăng nhập sinh trắc học
  Future<bool> enableBiometric({
    required String username,
    required String password,
  }) async {
    if (kIsWeb) return false;

    try {
      final available = await isBiometricAvailable();
      if (!available) return false;

      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Xác thực Face ID / Vân tay để bật đăng nhập nhanh',
        persistAcrossBackgrounding: true,
        biometricOnly: false,
      );

      if (didAuthenticate) {
        await _storage.write(key: keyBiometricEnabled, value: 'true');
        await _storage.write(key: keyBioUsername, value: username.trim());
        await _storage.write(key: keyBioPassword, value: password);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('BiometricService.enableBiometric error: $e');
      return false;
    }
  }

  /// Tắt đăng nhập sinh trắc học và xóa thông tin bảo mật
  Future<void> disableBiometric() async {
    try {
      await _storage.write(key: keyBiometricEnabled, value: 'false');
      await _storage.delete(key: keyBioPassword);
    } catch (e) {
      debugPrint('BiometricService.disableBiometric error: $e');
    }
  }

  /// Quét Face ID / Vân tay và lấy thông tin đăng nhập tự động
  Future<Map<String, String>?> authenticateAndGetCredentials() async {
    if (kIsWeb) return null;

    try {
      final isEnabled = await isBiometricEnabled();
      if (!isEnabled) return null;

      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Quét Face ID / Vân tay để đăng nhập vào Moneda',
        persistAcrossBackgrounding: true,
        biometricOnly: false,
      );

      if (didAuthenticate) {
        final username = await _storage.read(key: keyBioUsername);
        final password = await _storage.read(key: keyBioPassword);
        if (username != null &&
            username.isNotEmpty &&
            password != null &&
            password.isNotEmpty) {
          return {
            'username': username,
            'password': password,
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('BiometricService.authenticateAndGetCredentials error: $e');
      return null;
    }
  }
}
