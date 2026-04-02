import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';
  static const _userIdKey = 'user_id';
  static const _usernameKey = 'username';

  static Future<void> saveToken(String token) async =>
      await _storage.write(key: _tokenKey, value: token);

  static Future<String?> getToken() async =>
      await _storage.read(key: _tokenKey);

  static Future<void> deleteToken() async =>
      await _storage.delete(key: _tokenKey);

  static Future<void> saveUserId(String id) async =>
      await _storage.write(key: _userIdKey, value: id);

  static Future<String?> getUserId() async =>
      await _storage.read(key: _userIdKey);

  static Future<void> saveUsername(String username) async =>
      await _storage.write(key: _usernameKey, value: username);

  static Future<String?> getUsername() async =>
      await _storage.read(key: _usernameKey);

  static Future<void> clearAll() async => await _storage.deleteAll();
}
