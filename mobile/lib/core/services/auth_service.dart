import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:mobile/core/config.dart';
import 'package:mobile/core/services/api_service.dart';
import 'package:mobile/core/services/biometric_service.dart';

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
    await storage.write(
      key: 'user_role',
      value: user['role']?.toString() ?? '',
    );
    await storage.write(
      key: 'user_sexe',
      value: user['sexe']?.toString() ?? '',
    );
    await storage.write(
      key: 'user_identifiant',
      value: user['identifiant']?.toString() ?? identifiant,
    );
    return user;
  }

  /// Retourne null si tout va bien, sinon le message d'erreur à afficher.
  static Future<String?> changePassword({
    required String ancien,
    required String nouveau,
  }) async {
    try {
      final token = await getToken();
      final response = await http
          .put(
            Uri.parse('$baseUrl/profile/password'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'ancien_mot_de_passe': ancien,
              'nouveau_mot_de_passe': nouveau,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) return null;
      if (response.statusCode == 401)
        return 'Session expirée, reconnectez-vous';

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final detail = body is Map ? body['detail'] : null;
      if (detail is String) return detail;
      // Erreur de validation FastAPI (422) : detail est une liste
      if (detail is List && detail.isNotEmpty) {
        return detail.first['msg'].toString().replaceFirst('Value error, ', '');
      }
      return 'Erreur ${response.statusCode}';
    } catch (_) {
      return 'Impossible de contacter le serveur';
    }
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
  static Future<String?> getIdentifiant() =>
      storage.read(key: 'user_identifiant');
}
