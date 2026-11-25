class PatientRecord {
  final int id;
  final String code;
  final double age;
  final String sex;
  final String? service;
  final String? bed;
  final int? unit1;
  final int? unit2;
  final double? hospitalAdmissionTime;
  final DateTime? admittedAt;
  final String status;
  final DateTime? dischargedAt;
  final String source;
  final int? lastIcuHour;
  final double? latestScore;
  final String? latestLevel;
  final DateTime? latestPredictionAt;

  const PatientRecord({
    required this.id,
    required this.code,
    required this.age,
    required this.sex,
    required this.service,
    required this.bed,
    required this.unit1,
    required this.unit2,
    required this.hospitalAdmissionTime,
    required this.admittedAt,
    required this.status,
    required this.dischargedAt,
    required this.source,
    required this.lastIcuHour,
    required this.latestScore,
    required this.latestLevel,
    required this.latestPredictionAt,
  });

  factory PatientRecord.fromJson(Map<String, dynamic> json) {
    return PatientRecord(
      id: _asInt(json['id']) ?? 0,
      code: (json['code_patient'] ?? 'Patient') as String,
      age: _asDouble(json['age']) ?? 0,
      sex: (json['sexe'] ?? '') as String,
      service: json['service'] as String?,
      bed: json['lit']?.toString(),
      unit1: _asInt(json['unit1']),
      unit2: _asInt(json['unit2']),
      hospitalAdmissionTime: _asDouble(json['hosp_adm_time']),
      admittedAt: _asDate(json['admis_icu_le']),
      status: (json['statut'] ?? 'actif') as String,
      dischargedAt: _asDate(json['sorti_le']),
      source: (json['source'] ?? 'manuel') as String,
      lastIcuHour: _asInt(json['derniere_heure_icu']),
      latestScore: _asDouble(json['dernier_score']),
      latestLevel: json['dernier_niveau'] as String?,
      latestPredictionAt: _asDate(json['derniere_prediction_le']),
    );
  }

  bool get isActive => status == 'actif';
  bool get isSimulated => source == 'simulation';
  double? get riskPercent => latestScore == null ? null : latestScore! * 100;

  /// Uses the model's own classification returned by the backend.
  /// No client-side clinical thresholds are invented here.
  String get levelKey {
    switch ((latestLevel ?? '').toLowerCase()) {
      case 'alerte':
        return 'alerte';
      case 'surveillance':
        return 'surveillance';
      case 'normal':
        return 'normal';
      default:
        return 'unknown';
    }
  }

  String get levelLabel {
    switch (levelKey) {
      case 'alerte':
        return 'Alerte';
      case 'surveillance':
        return 'Surveillance';
      case 'normal':
        return 'Normal';
      default:
        return 'En attente';
    }
  }

  String get riskLabel => riskPercent == null
      ? '—'
      : '${riskPercent!.round()}%';

  String get sexLabel {
    switch (sex.toUpperCase()) {
      case 'M':
        return 'Homme';
      case 'F':
        return 'Femme';
      default:
        return 'Non renseigné';
    }
  }

  String get ageLabel {
    return age == age.roundToDouble() ? '${age.toInt()} ans' : '${age.toStringAsFixed(1)} ans';
  }

  String get updatedLabel {
    final date = latestPredictionAt;
    if (date == null) return 'Aucune prédiction';
    final difference = DateTime.now().difference(date.toLocal());
    if (difference.inSeconds < 60) return 'À l’instant';
    if (difference.inMinutes < 60) return 'Il y a ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'Il y a ${difference.inHours} h';
    return '${date.toLocal().day.toString().padLeft(2, '0')}/${date.toLocal().month.toString().padLeft(2, '0')}/${date.toLocal().year}';
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
