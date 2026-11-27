import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:mobile/core/config.dart';
import 'package:mobile/models/patient.dart';
import 'package:mobile/models/patient_alert.dart';
import 'package:mobile/core/services/token_storage.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static const Duration _timeout = Duration(seconds: 15);

  static Future<Map<String, dynamic>> login(
    String identifiant,
    String motDePasse,
  ) async {
    final response = await _send(
      'POST',
      '/auth/login',
      authenticated: false,
      body: {
        'identifiant': identifiant,
        'mot_de_passe': motDePasse,
      },
    );
    return _asMap(response);
  }

  static Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final uri = Uri.parse('$apiBaseUrl$path').replace(queryParameters: query);
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (authenticated) {
      final token = await TokenStorage.read();
      if (token == null || token.isEmpty) {
        throw ApiException('Session expirée. Reconnectez-vous.');
      }
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      late http.Response response;
      switch (method) {
        case 'POST':
          response = await http
              .post(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(_timeout);
          break;
        default:
          response = await http.get(uri, headers: headers).timeout(_timeout);
      }

      final decoded = response.bodyBytes.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is List) return {'items': decoded};
        return <String, dynamic>{'value': decoded};
      }

      final detail = decoded is Map ? decoded['detail'] : null;
      final message = detail is String
          ? detail
          : 'Erreur serveur (${response.statusCode}).';
      if (response.statusCode == 401) {
        throw ApiException('Session expirée. Reconnectez-vous.');
      }
      throw ApiException(message);
    } on TimeoutException {
      throw ApiException('Le serveur ne répond pas. Vérifiez qu’il est démarré.');
    } on FormatException {
      throw ApiException('Réponse API illisible. Vérifiez le backend.');
    } on http.ClientException {
      throw ApiException('Connexion à l’API impossible. Vérifiez le réseau et CORS.');
    } catch (error) {
      if (error is ApiException) rethrow;
      final message = error.toString();
      if (message.contains('SocketException') || message.contains('Failed host lookup')) {
        throw ApiException('Impossible de joindre l’API. Vérifiez l’adresse du serveur.');
      }
      rethrow;
    }
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw ApiException('Format de réponse API inattendu.');
  }

  static List<Map<String, dynamic>> _items(Map<String, dynamic> response) {
    final value = response['items'];
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<List<PatientRecord>> getPatients({
    String? status,
    String? source,
    String? query,
  }) async {
    const pageSize = 200;
    final result = <PatientRecord>[];
    var offset = 0;
    var hasMore = true;

    while (hasMore) {
      final params = <String, String>{
        'limit': '$pageSize',
        'offset': '$offset',
      };
      if (status != null && status.isNotEmpty) params['statut'] = status;
      if (source != null && source.isNotEmpty) params['source'] = source;
      if (query != null && query.trim().isNotEmpty) params['q'] = query.trim();

      final response = await _send('GET', '/patients', query: params);
      result.addAll(_items(response).map(PatientRecord.fromJson));
      hasMore = response['has_more'] == true;
      offset += pageSize;
    }
    return result;
  }

  static Future<PatientRecord> getPatient(int patientId) async {
    final response = await _send('GET', '/patients/$patientId');
    return PatientRecord.fromJson(response);
  }

  /// The backend currently exposes alerts per patient, not through a global
  /// notification endpoint. Fetch active patients in small concurrent batches.
  static Future<List<PatientAlert>> getOpenAlertsForPatients(
    List<PatientRecord> patients,
  ) async {
    final alerts = <PatientAlert>[];
    const batchSize = 8;

    for (var start = 0; start < patients.length; start += batchSize) {
      final batch = patients.skip(start).take(batchSize).toList();
      final batches = await Future.wait(batch.map((patient) async {
        final response = await _send(
          'GET',
          '/patients/${patient.id}/alerts',
          query: const {'limit': '100', 'offset': '0'},
        );
        return _items(response)
            .map((item) => PatientAlert.fromJson(item, patient))
            .where((alert) => alert.isOpen)
            .toList();
      }));
      for (final patientAlerts in batches) {
        alerts.addAll(patientAlerts);
      }
    }

    alerts.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return alerts;
  }

  static Future<List<Map<String, dynamic>>> getMeasurements(
    int patientId, {
    int limit = 100,
  }) async {
    final response = await _send(
      'GET',
      '/patients/$patientId/measurements',
      query: {'limit': '$limit', 'offset': '0'},
    );
    return _items(response);
  }

  static Future<List<Map<String, dynamic>>> getPredictions(
    int patientId, {
    int limit = 100,
  }) async {
    final response = await _send(
      'GET',
      '/patients/$patientId/predictions',
      query: {'limit': '$limit', 'offset': '0'},
    );
    return _items(response);
  }

  static Future<List<Map<String, dynamic>>> getPatientAlerts(
    int patientId, {
    int limit = 100,
  }) async {
    final response = await _send(
      'GET',
      '/patients/$patientId/alerts',
      query: {'limit': '$limit', 'offset': '0'},
    );
    return _items(response);
  }

  static Future<List<Map<String, dynamic>>> getPatientEvents(
    int patientId, {
    int limit = 100,
  }) async {
    final response = await _send(
      'GET',
      '/patients/$patientId/events',
      query: {'limit': '$limit', 'offset': '0'},
    );
    return _items(response);
  }
}
