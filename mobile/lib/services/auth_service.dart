import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config.dart';
import 'api_service.dart';
import 'biometric_service.dart';

class AuthService {
  static const String baseUrl = apiBaseUrl;
  static const storage = FlutterSecureStorage();

  /// Authenticates against POST /auth/login and persists the returned user.
  static Future<Map<String, dynamic>> login(
    String identifiant,
    String motDePasse,
  ) async {
    final data = await ApiService.login(identifiant, motDePasse);
    final token = data['access_token']?.toString();
    final rawUser = data['user'];

    if (token == null || token.isEmpty || rawUser is! Map) {
      throw Exception('Réponse de connexion incomplète.');
    }

    final user = Map<String, dynamic>.from(rawUser);
    await storage.write(key: 'access_token', value: token);
    await storage.write(key: 'user_id', value: user['id']?.toString() ?? '');
    await storage.write(key: 'user_name', value: user['nom']?.toString() ?? '');
    await storage.write(key: 'user_role', value: user['role']?.toString() ?? '');
    await storage.write(key: 'user_sexe', value: user['sexe']?.toString() ?? '');
    await storage.write(key: 'user_identifiant', value: user['identifiant']?.toString() ?? identifiant);
    return user;
  }

  static Future<void> logout({bool forgetBiometric = false}) async {
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'user_id');
    await storage.delete(key: 'user_name');
    await storage.delete(key: 'user_role');
    await storage.delete(key: 'user_sexe');
    await storage.delete(key: 'user_identifiant');
    if (forgetBiometric) await BiometricService().disable();
  }

  static Future<String?> getToken() => storage.read(key: 'access_token');
  static Future<String?> getUserName() => storage.read(key: 'user_name');
  static Future<String?> getRole() => storage.read(key: 'user_role');
  static Future<String?> getUserSexe() => storage.read(key: 'user_sexe');
  static Future<String?> getUserId() => storage.read(key: 'user_id');
  static Future<String?> getIdentifiant() => storage.read(key: 'user_identifiant');
}
