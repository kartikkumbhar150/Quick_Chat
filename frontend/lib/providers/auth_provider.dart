import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/socket_service.dart';
import '../config/api_config.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  bool _loading = false;
  String? _error;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await StorageService.getToken();
    if (token != null) {
      try {
        final res = await ApiService.get(ApiConfig.me);
        if (res['success'] == true) {
          _user = UserModel.fromJson(res['user']);
          _status = AuthStatus.authenticated;
          SocketService.init(token);
        } else {
          await StorageService.clearAll();
          _status = AuthStatus.unauthenticated;
        }
      } catch (_) {
        _status = AuthStatus.unauthenticated;
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    final res = await AuthService.login(email, password);
    _loading = false;

    if (res['success'] == true) {
      _user = UserModel.fromJson(res['user']);
      _status = AuthStatus.authenticated;
      final token = await StorageService.getToken();
      if (token != null) SocketService.init(token);
      notifyListeners();
      return true;
    } else {
      _error = res['message'] ?? 'Login failed';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    SocketService.dispose();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    try {
      final res = await ApiService.get(ApiConfig.me);
      if (res['success'] == true) {
        _user = UserModel.fromJson(res['user']);
        notifyListeners();
      }
    } catch (_) {}
  }

  void updateUser(UserModel updated) {
    _user = updated;
    notifyListeners();
  }
}
