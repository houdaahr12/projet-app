import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();

  static Future<void> save(String token) =>
      _storage.write(key: 'token', value: token);

  static Future<String?> read() => _storage.read(key: 'token');

  static Future<void> clear() => _storage.delete(key: 'token');
}
