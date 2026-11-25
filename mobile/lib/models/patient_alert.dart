import 'patient.dart';

class PatientAlert {
  final int id;
  final int patientId;
  final int? predictionId;
  final double score;
  final List<dynamic> factors;
  final String status;
  final DateTime? createdAt;
  final int? viewedBy;
  final DateTime? viewedAt;
  final int? handledBy;
  final DateTime? handledAt;
  final String? note;
  final DateTime? closedAt;
  final PatientRecord patient;

  const PatientAlert({
    required this.id,
    required this.patientId,
    required this.predictionId,
    required this.score,
    required this.factors,
    required this.status,
    required this.createdAt,
    required this.viewedBy,
    required this.viewedAt,
    required this.handledBy,
    required this.handledAt,
    required this.note,
    required this.closedAt,
    required this.patient,
  });

  factory PatientAlert.fromJson(
    Map<String, dynamic> json,
    PatientRecord patient,
  ) {
    final rawFactors = json['facteurs'];
    return PatientAlert(
      id: _asInt(json['id']) ?? 0,
      patientId: _asInt(json['patient_id']) ?? patient.id,
      predictionId: _asInt(json['prediction_id']),
      score: _asDouble(json['score']) ?? 0,
      factors: rawFactors is List ? rawFactors : const [],
      status: (json['statut'] ?? 'nouvelle') as String,
      createdAt: _asDate(json['creee_le']),
      viewedBy: _asInt(json['vue_par']),
      viewedAt: _asDate(json['vue_le']),
      handledBy: _asInt(json['prise_en_charge_par']),
      handledAt: _asDate(json['prise_en_charge_le']),
      note: json['note'] as String?,
      closedAt: _asDate(json['cloturee_le']),
      patient: patient,
    );
  }

  double get riskPercent => score * 100;
  String get riskLabel => '${riskPercent.round()}%';
  bool get isNew => status == 'nouvelle';
  bool get isOpen => status == 'nouvelle' || status == 'vue' || status == 'prise_en_charge';

  String get statusLabel {
    switch (status) {
      case 'nouvelle':
        return 'Nouvelle';
      case 'vue':
        return 'Vue';
      case 'prise_en_charge':
        return 'Prise en charge';
      case 'cloturee':
        return 'Clôturée';
      default:
        return status;
    }
  }

  List<String> get factorLines {
    return factors.map((factor) {
      if (factor is Map) {
        final variable = factor['variable']?.toString() ?? 'Facteur';
        final impact = _asDouble(factor['impact']);
        if (impact == null) return variable;
        final sign = impact > 0 ? '+' : '';
        return '$variable · impact $sign${impact.toStringAsFixed(4)}';
      }
      return factor.toString();
    }).toList();
  }

  String get createdLabel {
    final date = createdAt;
    if (date == null) return 'Date indisponible';
    final local = date.toLocal();
    final difference = DateTime.now().difference(local);
    if (difference.inSeconds < 60) return 'À l’instant';
    if (difference.inMinutes < 60) return 'Il y a ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'Il y a ${difference.inHours} h';
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
