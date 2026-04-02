import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> signup(
      String username, String email, String password) async {
    return await ApiService.post(ApiConfig.signup, {
      'username': username,
      'email': email,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>> verifyOtp(
      String userId, String otp) async {
    final res = await ApiService.post(ApiConfig.verifyOtp, {
      'userId': userId,
      'otp': otp,
    });
    if (res['success'] == true) {
      await StorageService.saveToken(res['token']);
      final user = UserModel.fromJson(res['user']);
      await StorageService.saveUserId(user.id);
      await StorageService.saveUsername(user.username);
    }
    return res;
  }

  static Future<Map<String, dynamic>> resendOtp(String userId) async {
    return await ApiService.post(ApiConfig.resendOtp, {'userId': userId});
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final res = await ApiService.post(ApiConfig.login, {
      'email': email,
      'password': password,
    });
    if (res['success'] == true) {
      await StorageService.saveToken(res['token']);
      final user = UserModel.fromJson(res['user']);
      await StorageService.saveUserId(user.id);
      await StorageService.saveUsername(user.username);
    }
    return res;
  }

  static Future<void> logout() async {
    try {
      await ApiService.post(ApiConfig.logout, {}, auth: true);
    } catch (_) {}
    await StorageService.clearAll();
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    return await ApiService.post(ApiConfig.forgotPassword, {'email': email});
  }

  static Future<Map<String, dynamic>> resetPassword(
      String userId, String otp, String newPassword) async {
    return await ApiService.post(ApiConfig.resetPassword, {
      'userId': userId,
      'otp': otp,
      'newPassword': newPassword,
    });
  }

  static Future<bool> isLoggedIn() async {
    final token = await StorageService.getToken();
    return token != null;
  }
}
