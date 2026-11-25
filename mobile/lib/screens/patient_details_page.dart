import 'dart:async';

import 'package:flutter/material.dart';

import '../models/patient.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';

class PatientDetailsPage extends StatefulWidget {
  const PatientDetailsPage({super.key, required this.patient});
  final PatientRecord patient;

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage>
    with WidgetsBindingObserver {
  late PatientRecord _patient;
  Timer? _timer;
  bool _requesting = false;
  List<Map<String, dynamic>> _measurements = [];
  List<Map<String, dynamic>> _predictions = [];
  List<Map<String, dynamic>> _alerts = [];
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
    WidgetsBinding.instance.addObserver(this);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? true)) {
        _load(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        (ModalRoute.of(context)?.isCurrent ?? true)) {
      _load(silent: true);
    }
  }

  Future<void> _load({bool silent = false}) async {
    if (_requesting) return;
    _requesting = true;
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait<dynamic>([
        ApiService.getPatient(widget.patient.id),
        ApiService.getMeasurements(widget.patient.id, limit: 100),
        ApiService.getPredictions(widget.patient.id, limit: 100),
        ApiService.getPatientAlerts(widget.patient.id, limit: 100),
        ApiService.getPatientEvents(widget.patient.id, limit: 100),
      ]);
      if (!mounted) return;
      setState(() {
        _patient = results[0] as PatientRecord;
        _measurements = results[1] as List<Map<String, dynamic>>;
        _predictions = results[2] as List<Map<String, dynamic>>;
        _alerts = results[3] as List<Map<String, dynamic>>;
        _events = results[4] as List<Map<String, dynamic>>;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    } finally {
      _requesting = false;
    }
  }

  Map<String, dynamic>? get _latestPrediction => _predictions.isEmpty ? null : _predictions.last;
  Map<String, dynamic>? get _latestMeasurement => _measurements.isEmpty ? null : _measurements.last;

  @override
  Widget build(BuildContext context) {
    final prediction = _latestPrediction;
    final score = _asDouble(prediction?['score']) ?? _patient.latestScore;
    final level = (prediction?['niveau'] ?? _patient.latestLevel ?? 'unknown').toString();
    final color = SepsisColors.forLevel(level);
    final riskPercent = score == null ? null : score * 100;
    final factors = _factorLines(prediction?['facteurs']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dossier patient', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [IconButton(onPressed: _load, tooltip: 'Actualiser', icon: const Icon(Icons.refresh_rounded))],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(),
        child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(20), children: [
          if (_error != null) _errorCard(),
          _patientHeader(color),
          const SizedBox(height: 17),
          _sectionTitle('Évaluation du risque'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: SepsisColors.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(riskPercent == null ? '—' : '${riskPercent.round()}%', style: TextStyle(fontSize: 34, color: color, fontWeight: FontWeight.w900)),
                const Spacer(),
                _levelChip(level),
              ]),
              const SizedBox(height: 8),
              ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: riskPercent == null ? 0 : (riskPercent / 100).clamp(0, 1).toDouble(), minHeight: 8, backgroundColor: SepsisColors.border, valueColor: AlwaysStoppedAnimation(color))),
              const SizedBox(height: 8),
              Text(prediction?['calcule_le']?.toString() ?? _patient.updatedLabel, style: const TextStyle(color: SepsisColors.muted, fontSize: 10)),
              if (factors.isNotEmpty) ...[
                const SizedBox(height: 13),
                const Text('Facteurs explicatifs de la dernière prédiction', style: TextStyle(color: SepsisColors.navy, fontSize: 12, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                ...factors.map((factor) => _bullet(factor, color)),
              ],
            ]),
          ),
          const SizedBox(height: 18),
          _sectionTitle('Dernières mesures cliniques'),
          const SizedBox(height: 10),
          _measurementsCard(_latestMeasurement),
          const SizedBox(height: 18),
          _sectionTitle('Historique des prédictions'),
          const SizedBox(height: 10),
          if (_predictions.isEmpty)
            _emptyPanel('Aucune prédiction disponible pour ce patient.')
          else
            ..._predictions.reversed.take(8).map(_predictionTile),
          const SizedBox(height: 18),
          _sectionTitle('Historique des alertes'),
          const SizedBox(height: 10),
          if (_alerts.isEmpty)
            _emptyPanel('Aucune alerte enregistrée pour ce patient.')
          else
            ..._alerts.reversed.take(8).map(_alertHistoryTile),
          const SizedBox(height: 18),
          _sectionTitle('Événements du parcours'),
          const SizedBox(height: 10),
          if (_events.isEmpty)
            _emptyPanel('Aucun événement enregistré.')
          else
            ..._events.reversed.take(8).map(_eventTile),
          const SizedBox(height: 14),
          if (_loading) const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),
          const Text('Les informations affichées proviennent des routes patient du backend SepsisCare.', textAlign: TextAlign.center, style: TextStyle(color: SepsisColors.muted, fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _patientHeader(Color color) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: SepsisColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        CircleAvatar(radius: 25, backgroundColor: color.withOpacity(.12), child: Icon(Icons.person_outline_rounded, color: color, size: 27)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_patient.code, style: const TextStyle(fontSize: 19, color: SepsisColors.navy, fontWeight: FontWeight.w900)),
          Text('Lit ${_patient.bed ?? '—'} · ${_patient.service ?? 'Service non précisé'}', style: const TextStyle(color: SepsisColors.muted, fontSize: 11)),
        ])),
        _levelChip(_patient.levelKey == 'unknown' ? 'unknown' : _patient.levelKey),
      ]),
      const SizedBox(height: 17),
      const Divider(color: SepsisColors.border),
      _infoRow('Âge', _patient.ageLabel),
      _infoRow('Sexe', _patient.sexLabel),
      _infoRow('Statut', _patient.status == 'actif' ? 'Actif' : 'Sorti'),
      _infoRow('Source', _patient.isSimulated ? 'Simulation TEST' : 'Dossier manuel'),
      _infoRow('Heure en réanimation', _patient.lastIcuHour?.toString() ?? '—'),
      _infoRow('Dernière actualisation', _patient.updatedLabel),
    ]),
  );

  Widget _measurementsCard(Map<String, dynamic>? measurement) {
    if (measurement == null) return _emptyPanel('Aucune mesure clinique disponible.');
    const fields = <String, String>{
      'hr': 'Fréquence cardiaque',
      'o2sat': 'SpO₂',
      'temp': 'Température',
      'sbp': 'Pression systolique',
      'map': 'Pression moyenne',
      'dbp': 'Pression diastolique',
      'resp': 'Fréquence respiratoire',
      'lactate': 'Lactate',
      'creatinine': 'Créatinine',
      'wbc': 'Leucocytes',
      'platelets': 'Plaquettes',
      'glucose': 'Glucose',
    };
    final rows = fields.entries.where((entry) => measurement[entry.key] != null).toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: SepsisColors.border)),
      child: Column(children: [
        _infoRow('Heure ICU', measurement['heure_icu']?.toString() ?? '—'),
        for (final entry in rows) _infoRow(entry.value, measurement[entry.key].toString()),
        if (rows.isEmpty) const Text('La dernière mesure ne contient pas de valeurs renseignées.', style: TextStyle(color: SepsisColors.muted, fontSize: 11)),
      ]),
    );
  }

  Widget _predictionTile(Map<String, dynamic> prediction) {
    final level = prediction['niveau']?.toString() ?? 'normal';
    final color = SepsisColors.forLevel(level);
    final score = _asDouble(prediction['score']);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13), border: Border.all(color: SepsisColors.border)),
      child: Row(children: [
        Icon(Icons.circle, size: 9, color: color),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Heure ICU ${prediction['heure_icu'] ?? '—'}', style: const TextStyle(color: SepsisColors.navy, fontWeight: FontWeight.w800, fontSize: 12)),
          Text(prediction['calcule_le']?.toString() ?? '', style: const TextStyle(color: SepsisColors.muted, fontSize: 9)),
        ])),
        Text(score == null ? '—' : '${(score * 100).round()}%', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 17)),
        const SizedBox(width: 7),
        Text(_levelText(level), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _alertHistoryTile(Map<String, dynamic> alert) {
    final score = _asDouble(alert['score']);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13), border: Border.all(color: SepsisColors.border)),
      child: Row(children: [
        const Icon(Icons.notifications_active_outlined, color: SepsisColors.high),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_alertStatus(alert['statut']?.toString() ?? ''), style: const TextStyle(color: SepsisColors.navy, fontWeight: FontWeight.w800, fontSize: 12)),
          Text(alert['creee_le']?.toString() ?? '', style: const TextStyle(color: SepsisColors.muted, fontSize: 9)),
        ])),
        Text(score == null ? '—' : '${(score * 100).round()}%', style: const TextStyle(color: SepsisColors.high, fontWeight: FontWeight.w900, fontSize: 17)),
      ]),
    );
  }

  Widget _eventTile(Map<String, dynamic> event) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13), border: Border.all(color: SepsisColors.border)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.event_note_rounded, color: SepsisColors.teal, size: 19),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(event['type']?.toString() ?? 'Événement', style: const TextStyle(color: SepsisColors.navy, fontWeight: FontWeight.w800, fontSize: 12)),
        if (event['details'] != null) Text(event['details'].toString(), style: const TextStyle(color: SepsisColors.muted, fontSize: 11)),
        Text(event['cree_le']?.toString() ?? '', style: const TextStyle(color: SepsisColors.muted, fontSize: 9)),
      ])),
    ]),
  );

  Widget _sectionTitle(String title) => Text(title, style: const TextStyle(fontSize: 17, color: SepsisColors.navy, fontWeight: FontWeight.w800));

  Widget _levelChip(String level) {
    final label = _levelText(level);
    final color = SepsisColors.forLevel(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: SepsisColors.softForLevel(level), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: SepsisColors.muted, fontSize: 11))),
      const SizedBox(width: 12),
      Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(color: SepsisColors.navy, fontWeight: FontWeight.w700, fontSize: 11))),
    ]),
  );

  Widget _bullet(String text, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(children: [
      Icon(Icons.circle, size: 6, color: color),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(color: SepsisColors.navy, fontSize: 11))),
    ]),
  );

  Widget _emptyPanel(String text) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13), border: Border.all(color: SepsisColors.border)),
    child: Text(text, style: const TextStyle(color: SepsisColors.muted, fontSize: 11)),
  );

  Widget _errorCard() => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: SepsisColors.highSoft, borderRadius: BorderRadius.circular(12)),
    child: Text(_error!, style: const TextStyle(color: SepsisColors.high, fontSize: 11)),
  );

  String _levelText(String level) {
    switch (level.toLowerCase()) {
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

  String _alertStatus(String status) {
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

  List<String> _factorLines(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((item) {
      if (item is Map) {
        final variable = item['variable']?.toString() ?? 'Facteur';
        final impact = _asDouble(item['impact']);
        if (impact == null) return variable;
        return '$variable · impact ${impact > 0 ? '+' : ''}${impact.toStringAsFixed(4)}';
      }
      return item.toString();
    }).toList();
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}
