import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

class ApiService {
  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await StorageService.getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Uri _uri(String path, [Map<String, String>? queryParams]) {
    final base = Uri.parse(ApiConfig.baseUrl + path);
    if (queryParams != null) {
      return base.replace(queryParameters: queryParams);
    }
    return base;
  }

  static Future<Map<String, dynamic>> get(String path,
      {Map<String, String>? query, bool auth = true}) async {
    final res = await http.get(_uri(path, query), headers: await _headers(auth: auth));
    return _parse(res);
  }

  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body,
      {bool auth = false}) async {
    final res = await http.post(_uri(path),
        headers: await _headers(auth: auth), body: jsonEncode(body));
    return _parse(res);
  }

  static Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    final res = await http.put(_uri(path),
        headers: await _headers(), body: jsonEncode(body));
    return _parse(res);
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    final res = await http.delete(_uri(path), headers: await _headers());
    return _parse(res);
  }

  /// Multipart for file uploads
  static Future<Map<String, dynamic>> uploadFile(
      String path, String fieldName, String filePath) async {
    final token = await StorageService.getToken();
    final req = http.MultipartRequest('PUT', _uri(path));
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    req.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    return _parse(res);
  }

  static Map<String, dynamic> _parse(http.Response res) {
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return {'success': false, 'message': 'Failed to parse response'};
    }
  }
}
