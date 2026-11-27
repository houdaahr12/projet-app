import 'package:mobile/core/services/api_service.dart';

int? _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '');
}

double? _asDouble(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '');
}

/// Last [count] scores (0..1) of a patient, oldest first.
/// Returns null on failure so the caller can keep the previous sparkline.
Future<List<double>?> loadRecentScores(int patientId, {int count = 15}) async {
  try {
    final rows = [...await ApiService.getPredictions(patientId, limit: 100)];
    rows.sort(
      (a, b) =>
          (_asInt(a['heure_icu']) ?? 0).compareTo(_asInt(b['heure_icu']) ?? 0),
    );
    final scores = rows
        .map((r) => _asDouble(r['score']))
        .whereType<double>()
        .toList();
    return scores.length > count
        ? scores.sublist(scores.length - count)
        : scores;
  } catch (_) {
    return null;
  }
}
