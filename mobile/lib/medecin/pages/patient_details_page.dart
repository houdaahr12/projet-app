import 'dart:async';

import 'package:flutter/material.dart';

import 'package:mobile/models/patient.dart';
import 'package:mobile/core/services/api_service.dart';
import 'package:mobile/core/theme/colors.dart';
import 'package:mobile/shared/utils/factor_labels.dart';
import 'package:mobile/shared/utils/time_format.dart';
import 'package:mobile/shared/widgets/risk_chart.dart';

class PatientDetailsPage extends StatefulWidget {
  const PatientDetailsPage({super.key, required this.patient});
  final PatientRecord patient;

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _Factor {
  const _Factor(this.feature, this.impact);
  final String feature;
  final double impact;
}

class _VitalSpec {
  const _VitalSpec(this.key, this.label, this.unit, {this.low, this.high});
  final String key;
  final String label;
  final String unit;
  final double?
  low; // display-only reference range, used to color out-of-range values
  final double? high;
}

// Display-only adult reference ranges (not used for any model decision).
// Units follow the PhysioNet-style dataset; adjust if your backend uses others.
const _vitalSpecs = <_VitalSpec>[
  _VitalSpec('hr', 'Fréquence cardiaque', 'bpm', low: 60, high: 100),
  _VitalSpec('o2sat', 'SpO₂', '%', low: 94, high: 100),
  _VitalSpec('temp', 'Température', '°C', low: 36, high: 38),
  _VitalSpec('map', 'Pression moyenne', 'mmHg', low: 65, high: 110),
  _VitalSpec('sbp', 'Pression systolique', 'mmHg', low: 90, high: 140),
  _VitalSpec('dbp', 'Pression diastolique', 'mmHg', low: 50, high: 90),
  _VitalSpec('resp', 'Fréquence respiratoire', '/min', low: 12, high: 20),
  _VitalSpec('lactate', 'Lactate', 'mg/dL', high: 18),
  _VitalSpec('creatinine', 'Créatinine', 'mg/dL', low: 0.6, high: 1.3),
  _VitalSpec('wbc', 'Leucocytes', '10³/µL', low: 4, high: 12),
  _VitalSpec('platelets', 'Plaquettes', '10³/µL', low: 150, high: 450),
  _VitalSpec('glucose', 'Glucose', 'mg/dL', low: 70, high: 180),
];

// Factors about "when / how often / how long", not about the patient's physiology.
const _contextFeatures = {'ICULOS', 'HospAdmTime', 'Unit1', 'Unit2'};

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

  Map<String, dynamic>? get _latestPrediction =>
      _predictions.isEmpty ? null : _predictions.last;
  Map<String, dynamic>? get _latestMeasurement =>
      _measurements.isEmpty ? null : _measurements.last;
  Map<String, dynamic>? get _previousMeasurement =>
      _measurements.length < 2 ? null : _measurements[_measurements.length - 2];

  @override
  Widget build(BuildContext context) {
    final prediction = _latestPrediction;
    final score = _asDouble(prediction?['score']) ?? _patient.latestScore;
    final level = (prediction?['niveau'] ?? _patient.latestLevel ?? 'unknown')
        .toString();
    final color = SepsisColors.forLevel(level);
    final factors = _parseFactors(prediction?['facteurs']);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dossier patient',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _load,
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            if (_error != null) _errorCard(),
            _summaryCard(prediction, score, level, color),
            const SizedBox(height: 18),
            _sectionTitle('Évolution du score'),
            const SizedBox(height: 10),
            _chartCard(),
            const SizedBox(height: 18),
            _sectionTitle('Facteurs du modèle'),
            const SizedBox(height: 10),
            _factorsCard(factors),
            const SizedBox(height: 18),
            _sectionTitle(
              _latestMeasurement?['heure_icu'] == null
                  ? 'Dernières mesures'
                  : 'Dernières mesures · H+${_latestMeasurement!['heure_icu']}',
            ),
            const SizedBox(height: 10),
            _vitalsGrid(),
            const SizedBox(height: 18),
            _historySection(),
            const SizedBox(height: 14),
            if (_loading && _predictions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              ),
            const Text(
              'Le score est celui du modèle et n’est pas une probabilité clinique. Les informations proviennent du backend SepsisCare.',
              textAlign: TextAlign.center,
              style: TextStyle(color: SepsisColors.muted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Summary ─────────────────────────

  Widget _summaryCard(
    Map<String, dynamic>? prediction,
    double? score,
    String level,
    Color color,
  ) {
    final details = [
      _patient.ageLabel,
      _patient.sexLabel,
      _patient.service ?? 'Service non précisé',
      if (_patient.status != 'actif') 'Sorti',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SepsisColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lit ${_patient.bed ?? '—'}',
                      style: const TextStyle(
                        fontSize: 26,
                        color: SepsisColors.navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      _patient.code,
                      style: const TextStyle(
                        color: SepsisColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              _levelChip(level, large: true),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            details,
            style: const TextStyle(
              color: SepsisColors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_patient.isSimulated)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                'Données simulées (split TEST)',
                style: TextStyle(color: SepsisColors.muted, fontSize: 10),
              ),
            ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: SepsisColors.border),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score == null ? '—' : '${(score * 100).round()}%',
                style: TextStyle(
                  fontSize: 34,
                  color: color,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Score du modèle',
                      style: TextStyle(
                        color: SepsisColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _trendText(),
                      style: const TextStyle(
                        color: SepsisColors.navy,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ThresholdBar(score: score, color: color),
          const SizedBox(height: 6),
          Text(
            'Heure ICU ${prediction?['heure_icu'] ?? _patient.lastIcuHour ?? '—'} · calculé à ${clockLabel(prediction?['calcule_le'])} · ${_patient.updatedLabel}',
            style: const TextStyle(color: SepsisColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  String _trendText() {
    if (_predictions.length < 2) return 'Première prédiction';
    final last = _asDouble(_predictions.last['score']);
    final prev = _asDouble(_predictions[_predictions.length - 2]['score']);
    if (last == null || prev == null) return '';
    final delta = (last - prev) * 100;
    if (delta.abs() < 0.05)
      return 'Stable depuis H+${_predictions[_predictions.length - 2]['heure_icu'] ?? '—'}';
    return '${delta > 0 ? '▲ +' : '▼ '}${delta.toStringAsFixed(1)} pt depuis H+${_predictions[_predictions.length - 2]['heure_icu'] ?? '—'}';
  }

  // ───────────────────────── Chart ─────────────────────────

  Widget _chartCard() {
    final points = <RiskPoint>[];
    for (final p in _predictions) {
      final hour = _asInt(p['heure_icu']);
      final s = _asDouble(p['score']);
      if (hour == null || s == null) continue;
      points.add(RiskPoint(hour, s, (p['niveau'] ?? 'unknown').toString()));
    }
    points.sort((a, b) => a.hour.compareTo(b.hour));
    final shown = points.length > 60
        ? points.sublist(points.length - 60)
        : points;

    if (shown.length < 2)
      return _emptyPanel(
        'Pas encore assez de prédictions pour tracer une courbe.',
      );
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SepsisColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text(
              'Score par heure en réanimation (${shown.length} dernières heures)',
              style: const TextStyle(color: SepsisColors.muted, fontSize: 10),
            ),
          ),
          RiskChart(points: shown),
        ],
      ),
    );
  }

  // ───────────────────────── Factors ─────────────────────────

  Widget _factorsCard(List<_Factor> factors) {
    if (factors.isEmpty)
      return _emptyPanel(
        'Aucun facteur explicatif pour la dernière prédiction.',
      );

    final physio = factors.where((f) => !_isContext(f.feature)).toList();
    final contextFactors = factors.where((f) => _isContext(f.feature)).toList();
    final maxAbs = factors
        .map((f) => f.impact.abs())
        .fold<double>(0.0001, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SepsisColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Facteurs physiologiques',
            style: TextStyle(
              color: SepsisColors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          if (physio.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'Aucun facteur physiologique parmi les principaux facteurs de cette prédiction.',
                style: TextStyle(color: SepsisColors.muted, fontSize: 11),
              ),
            )
          else
            ...physio.map((f) => _factorRow(f, maxAbs)),
          if (contextFactors.isNotEmpty) ...[
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text(
                  'Contexte et fréquence des mesures (${contextFactors.length})',
                  style: const TextStyle(
                    color: SepsisColors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: const Text(
                  'Durée de séjour et rythme des prélèvements, pas l’état physiologique.',
                  style: TextStyle(color: SepsisColors.muted, fontSize: 10),
                ),
                children: contextFactors
                    .map((f) => _factorRow(f, maxAbs))
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 6),
          const Text(
            '↑ augmente le score · ↓ le diminue. La barre compare l’influence relative des facteurs.',
            style: TextStyle(color: SepsisColors.muted, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _factorRow(_Factor f, double maxAbs) {
    final label = describeFactor(f.feature).text;
    final up = f.impact >= 0;
    final c = up ? SepsisColors.high : SepsisColors.teal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 14,
                color: c,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: SepsisColors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${up ? '+' : ''}${f.impact.toStringAsFixed(2)}',
                style: const TextStyle(color: SepsisColors.muted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (f.impact.abs() / maxAbs).clamp(0.0, 1.0).toDouble(),
              minHeight: 4,
              backgroundColor: SepsisColors.border,
              valueColor: AlwaysStoppedAnimation(c),
            ),
          ),
        ],
      ),
    );
  }

  bool _isContext(String feature) =>
      _contextFeatures.contains(feature) || describeFactor(feature).isTiming;

  List<_Factor> _parseFactors(dynamic raw) {
    if (raw is! List) return const [];
    final result = <_Factor>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final name = item['variable']?.toString();
      final impact = _asDouble(item['impact']);
      if (name == null || impact == null) continue;
      result.add(_Factor(name, impact));
    }
    return result;
  }

  // ───────────────────────── Vitals ─────────────────────────

  Widget _vitalsGrid() {
    final current = _latestMeasurement;
    if (current == null)
      return _emptyPanel('Aucune mesure clinique disponible.');
    final previous = _previousMeasurement;
    final specs = _vitalSpecs
        .where((s) => _asDouble(current[s.key]) != null)
        .toList();
    if (specs.isEmpty)
      return _emptyPanel(
        'La dernière mesure ne contient pas de valeurs renseignées.',
      );

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: specs
              .map(
                (s) => SizedBox(
                  width: tileWidth,
                  child: _vitalTile(s, current, previous),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _vitalTile(
    _VitalSpec spec,
    Map<String, dynamic> current,
    Map<String, dynamic>? previous,
  ) {
    final value = _asDouble(current[spec.key])!;
    final prev = previous == null ? null : _asDouble(previous[spec.key]);
    final out =
        (spec.low != null && value < spec.low!) ||
        (spec.high != null && value > spec.high!);
    final valueColor = out ? SepsisColors.high : SepsisColors.navy;

    Widget? arrow;
    if (prev != null && (value - prev).abs() > 0.0001) {
      arrow = Icon(
        value > prev
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded,
        size: 14,
        color: SepsisColors.muted,
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: out ? SepsisColors.highSoft : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: out ? SepsisColors.high.withOpacity(.4) : SepsisColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            spec.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: SepsisColors.muted, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmt(value),
                style: TextStyle(
                  color: valueColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  spec.unit,
                  style: const TextStyle(
                    color: SepsisColors.muted,
                    fontSize: 10,
                  ),
                ),
              ),
              const Spacer(),
              if (arrow != null) arrow,
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  // ───────────────────────── History (collapsed) ─────────────────────────

  Widget _historySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SepsisColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          title: const Text(
            'Historique détaillé',
            style: TextStyle(
              fontSize: 15,
              color: SepsisColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            '${_predictions.length} prédictions · ${_alerts.length} alertes · ${_events.length} événements',
            style: const TextStyle(color: SepsisColors.muted, fontSize: 10),
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _MiniTitle('Prédictions'),
            if (_predictions.isEmpty)
              const Text(
                'Aucune prédiction disponible.',
                style: TextStyle(color: SepsisColors.muted, fontSize: 11),
              )
            else
              ..._predictions.reversed.take(20).map(_predictionRow),
            const SizedBox(height: 12),
            const _MiniTitle('Alertes'),
            if (_alerts.isEmpty)
              const Text(
                'Aucune alerte enregistrée pour ce patient.',
                style: TextStyle(color: SepsisColors.muted, fontSize: 11),
              )
            else
              ..._alerts.reversed.take(10).map(_alertRow),
            const SizedBox(height: 12),
            const _MiniTitle('Parcours'),
            if (_events.isEmpty)
              const Text(
                'Aucun événement enregistré.',
                style: TextStyle(color: SepsisColors.muted, fontSize: 11),
              )
            else
              ..._events.reversed.take(10).map(_eventRow),
          ],
        ),
      ),
    );
  }

  Widget _predictionRow(Map<String, dynamic> prediction) {
    final level = prediction['niveau']?.toString() ?? 'normal';
    final color = SepsisColors.forLevel(level);
    final score = _asDouble(prediction['score']);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 8),
          SizedBox(
            width: 52,
            child: Text(
              'H+${prediction['heure_icu'] ?? '—'}',
              style: const TextStyle(
                color: SepsisColors.navy,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
          Text(
            clockLabel(prediction['calcule_le']),
            style: const TextStyle(color: SepsisColors.muted, fontSize: 10),
          ),
          const Spacer(),
          Text(
            score == null ? '—' : '${(score * 100).round()}%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 74,
            child: Text(
              _levelText(level),
              textAlign: TextAlign.end,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertRow(Map<String, dynamic> alert) {
    final score = _asDouble(alert['score']);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active_outlined,
            color: SepsisColors.high,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            _alertStatus(alert['statut']?.toString() ?? ''),
            style: const TextStyle(
              color: SepsisColors.navy,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            shortDateTimeLabel(alert['creee_le']),
            style: const TextStyle(color: SepsisColors.muted, fontSize: 10),
          ),
          const Spacer(),
          Text(
            score == null ? '—' : '${(score * 100).round()}%',
            style: const TextStyle(
              color: SepsisColors.high,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventRow(Map<String, dynamic> event) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.event_note_rounded,
          color: SepsisColors.teal,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event['type']?.toString() ?? 'Événement',
                style: const TextStyle(
                  color: SepsisColors.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
              if (event['details'] != null)
                Text(
                  event['details'].toString(),
                  style: const TextStyle(
                    color: SepsisColors.muted,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),
        Text(
          shortDateTimeLabel(event['cree_le']),
          style: const TextStyle(color: SepsisColors.muted, fontSize: 10),
        ),
      ],
    ),
  );

  // ───────────────────────── Shared bits ─────────────────────────

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 17,
      color: SepsisColors.navy,
      fontWeight: FontWeight.w800,
    ),
  );

  Widget _levelChip(String level, {bool large = false}) {
    final label = _levelText(level);
    final color = SepsisColors.forLevel(level);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 10,
        vertical: large ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: SepsisColors.softForLevel(level),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: large ? 13 : 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _emptyPanel(String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: SepsisColors.border),
    ),
    child: Text(
      text,
      style: const TextStyle(color: SepsisColors.muted, fontSize: 11),
    ),
  );

  Widget _errorCard() => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: SepsisColors.highSoft,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      _error!,
      style: const TextStyle(color: SepsisColors.high, fontSize: 11),
    ),
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

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}

class _MiniTitle extends StatelessWidget {
  const _MiniTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      style: const TextStyle(
        color: SepsisColors.navy,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
