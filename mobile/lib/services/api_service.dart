import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../config.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static Future<Map<String, dynamic>> login(
    String identifiant,
    String motDePasse,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'identifiant': identifiant,
              'mot_de_passe': motDePasse,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(utf8.decode(res.bodyBytes));

      if (res.statusCode == 200) {
        return data as Map<String, dynamic>;
      }

      final detail = data is Map ? data['detail'] : null;
      throw ApiException(
        detail is String ? detail : 'Erreur (${res.statusCode})',
      );
    } on TimeoutException {
      throw ApiException('Le serveur ne répond pas. Vérifiez la connexion.');
    } on SocketException {
      throw ApiException('Impossible de joindre le serveur.');
    }
  }
}