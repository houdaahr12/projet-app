import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class Doctor {
  final int id;
  final String nom;
  final String identifiant;
  final String? sexe;
  final String? email;
  final String? service;
  final String role;
  final bool actif;
  final bool doitChangerMdp;

  Doctor({
    required this.id,
    required this.nom,
    required this.identifiant,
    this.sexe,
    this.email,
    this.service,
    required this.role,
    required this.actif,
    required this.doitChangerMdp,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'],
      nom: json['nom'] ?? '',
      identifiant: json['identifiant'] ?? '',
      sexe: json['sexe'] as String?,
      email: json['email'],
      service: json['service'],
      role: json['role'] ?? 'medecin',
      actif: json['actif'] ?? false,
      doitChangerMdp: json['doit_changer_mdp'] ?? false,
    );
  }
}

class DoctorStats {
  final int total;
  final int actifs;
  final int inactifs;

  DoctorStats({
    required this.total,
    required this.actifs,
    required this.inactifs,
  });

  factory DoctorStats.fromJson(Map<String, dynamic> json) {
    return DoctorStats(
      total: json['total_medecins'] ?? 0,
      actifs: json['medecins_actifs'] ?? 0,
      inactifs: json['medecins_inactifs'] ?? 0,
    );
  }
}

class DoctorService {
  static Future<Map<String, String>> headers() async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Session expirée. Reconnectez-vous.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<List<Doctor>> getDoctors({String q = ''}) async {
    final uri = Uri.parse('${AuthService.baseUrl}/admin/doctors')
        .replace(queryParameters: q.trim().isEmpty ? null : {'q': q.trim()});

    final response = await http.get(uri, headers: await headers());

    if (response.statusCode != 200) {
      throw Exception('Impossible de charger les médecins');
    }

    final List data = jsonDecode(response.body);

    return data.map((item) => Doctor.fromJson(item)).toList();
  }

  static Future<DoctorStats> getStats() async {
    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}/admin/stats'),
      headers: await headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Impossible de charger les statistiques');
    }

    return DoctorStats.fromJson(jsonDecode(response.body));
  }

  static Future<void> addDoctor({
    required String nom,
    required String identifiant,
    required String motDePasse,
    required String sexe,
    String? email,
    String? service,
  }) async {
    final response = await http.post(
      Uri.parse('${AuthService.baseUrl}/admin/doctors'),
      headers: await headers(),
      body: jsonEncode({
        'nom': nom,
        'identifiant': identifiant,
        'sexe': sexe,
        'email': email?.trim().isEmpty == true ? null : email,
        'mot_de_passe': motDePasse,
        'service': service?.trim().isEmpty == true ? null : service,
      }),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Erreur lors de l’ajout');
    }
  }

  static Future<void> updateDoctor({
    required int id,
    required String nom,
    required String identifiant,
    String? sexe,
    String? email,
    String? service,
    String? motDePasse,
    bool? actif,
  }) async {
    final body = <String, dynamic>{
      'nom': nom,
      'identifiant': identifiant,
      'sexe': sexe,
      'email': email?.trim().isEmpty == true ? null : email,
      'service': service?.trim().isEmpty == true ? null : service,
    };

    if (motDePasse != null && motDePasse.isNotEmpty) {
      body['mot_de_passe'] = motDePasse;
    }

    if (actif != null) {
      body['actif'] = actif;
    }

    final response = await http.put(
      Uri.parse('${AuthService.baseUrl}/admin/doctors/$id'),
      headers: await headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Erreur de modification');
    }
  }

  static Future<void> deleteDoctor(int id) async {
    final response = await http.delete(
      Uri.parse('${AuthService.baseUrl}/admin/doctors/$id'),
      headers: await headers(),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Erreur de désactivation');
    }
  }
}
