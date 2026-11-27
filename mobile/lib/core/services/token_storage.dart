import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();

  static Future<void> save(String token) =>
      _storage.write(key: 'access_token', value: token);

  static Future<String?> read() => _storage.read(key: 'access_token');

  static Future<void> clear() => _storage.delete(key: 'access_token');
}
