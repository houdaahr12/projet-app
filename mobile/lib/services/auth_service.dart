import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static const storage = FlutterSecureStorage();

  /// Connecte l'utilisateur (admin ou médecin) et renvoie la map "user" du
  /// serveur : id, nom, identifiant, role, sexe.
  static Future<Map<String, dynamic>> login(
    String identifiant,
    String motDePasse,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifiant': identifiant,
          'mot_de_passe': motDePasse,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = Map<String, dynamic>.from(data['user']);

        await storage.write(key: 'access_token', value: data['access_token']);
        await storage.write(key: 'user_name', value: user['nom'] ?? '');
        await storage.write(key: 'user_role', value: user['role'] ?? '');
        await storage.write(key: 'user_sexe', value: user['sexe'] ?? '');

        return user;
      }

      final detail = data is Map ? data['detail'] : null;

      throw Exception(detail is String ? detail : 'Erreur de connexion');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Impossible de contacter le serveur');
    }
  }

  static Future<void> logout() async {
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'user_name');
    await storage.delete(key: 'user_role');
    await storage.delete(key: 'user_sexe');
  }

  static Future<String?> getToken() async {
    return storage.read(key: 'access_token');
  }

  static Future<String?> getUserName() async {
    return storage.read(key: 'user_name');
  }

  /// 'admin' ou 'medecin' (null si personne n'est connecté).
  static Future<String?> getRole() async {
    return storage.read(key: 'user_role');
  }

  /// 'M', 'F' ou chaîne vide.
  static Future<String?> getUserSexe() async {
    return storage.read(key: 'user_sexe');
  }
}