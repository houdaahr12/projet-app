import 'dart:async';

import 'package:flutter/material.dart';

import 'package:mobile/models/patient.dart';
import 'package:mobile/models/patient_alert.dart';
import 'package:mobile/core/services/api_service.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/theme/colors.dart';
import 'package:mobile/medecin/widgets/patient_card.dart';
import 'package:mobile/medecin/widgets/sepsis_bottom_nav.dart';
import 'package:mobile/shared/utils/level_change_notifier.dart';
import 'package:mobile/shared/utils/score_history.dart';
import 'package:mobile/shared/widgets/section_title.dart';
import 'package:mobile/medecin/pages/add_patient_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.userName = ''});
  final String userName;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  static const _shownCount = 4;

  String _doctorName = '';
  List<PatientRecord> _patients = [];
  List<PatientAlert> _alerts = [];
  final Map<int, List<double>> _history = {};
  bool _loading = true;
  bool _refreshing = false;
  bool _historyBusy = false;
  String? _error;
  DateTime? _lastUpdated;
  Timer? _refreshTimer;

  int get _highCount => _patients.where((p) => p.levelKey == 'alerte').length;
  int get _monitorCount =>
      _patients.where((p) => p.levelKey == 'surveillance').length;
  int get _normalCount => _patients.where((p) => p.levelKey == 'normal').length;
  int get _newAlertCount => _alerts.where((a) => a.isNew).length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _doctorName = widget.userName.trim();
    _loadDoctorName();
    _refresh();
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? true)) {
        _refresh(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        (ModalRoute.of(context)?.isCurrent ?? true)) {
      _refresh(silent: true);
    }
  }

  Future<void> _loadDoctorName() async {
    if (_doctorName.isNotEmpty) return;
    final name = await AuthService.getUserName();
    if (!mounted) return;
    setState(() => _doctorName = name?.trim() ?? '');
  }

  Future<void> _refresh({bool silent = false}) async {
    if (_refreshing) return;
    _refreshing = true;
    if (!silent && mounted) setState(() => _loading = true);

    try {
      // Keep the dashboard focused on currently admitted patients.
      final patients = await ApiService.getPatients(status: 'actif');
      final alerts = await ApiService.getOpenAlertsForPatients(patients);

      if (!mounted) return;

      // Only patients whose level got worse (with a cooldown) trigger a snackbar.
      final escalated = LevelChangeNotifier.instance.detectEscalations(
        patients,
      );

      setState(() {
        _patients = patients;
        _alerts = alerts;
        _lastUpdated = DateTime.now();
        _error = null;
        _loading = false;
      });

      unawaited(
        _refreshHistories(_sortedPatients(patients).take(_shownCount).toList()),
      );

      if (escalated.isNotEmpty && mounted) {
        showEscalationSnackBar(
          context,
          escalated,
          onView: (p) =>
              Navigator.pushNamed(context, '/patient-details', arguments: p),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    } finally {
      _refreshing = false;
    }
  }

  /// Sparklines are only loaded for the patients actually displayed.
  Future<void> _refreshHistories(List<PatientRecord> list) async {
    if (_historyBusy) return;
    _historyBusy = true;
    try {
      final entries = await Future.wait(
        list.map(
          (p) async =>
              MapEntry<int, List<double>?>(p.id, await loadRecentScores(p.id)),
        ),
      );
      if (!mounted) return;
      setState(() {
        for (final e in entries) {
          if (e.value != null) _history[e.key] = e.value!;
        }
      });
    } finally {
      _historyBusy = false;
    }
  }

  int _levelRank(String key) {
    switch (key) {
      case 'alerte':
        return 0;
      case 'surveillance':
        return 1;
      case 'normal':
        return 2;
      default:
        return 3;
    }
  }

  /// Alerte first, then Surveillance, then Normal; highest score first inside a level.
  List<PatientRecord> _sortedPatients(List<PatientRecord> list) => [...list]
    ..sort((a, b) {
      final r = _levelRank(a.levelKey).compareTo(_levelRank(b.levelKey));
      return r != 0 ? r : (b.riskPercent ?? -1).compareTo(a.riskPercent ?? -1);
    });

  /// Open alert whose patient is currently the most at risk (newest alert breaks ties).
  PatientAlert? get _priorityAlert {
    if (_alerts.isEmpty) return null;
    final list = [..._alerts]
      ..sort((a, b) {
        final r = _levelRank(a.patient.levelKey)
            .compareTo(_levelRank(b.patient.levelKey));
        if (r != 0) return r;
        return (b.createdAt ?? DateTime(2000)).compareTo(
          a.createdAt ?? DateTime(2000),
        );
      });
    return list.first;
  }

  String _today() {
    const days = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    final date = DateTime.now();
    return '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
  }

  String _updatedText() {
    if (_error != null) return 'connexion à vérifier';
    final d = _lastUpdated;
    if (d == null) return 'chargement…';
    return 'mis à jour ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  // "ahmed ben-ali" -> "Ahmed Ben-Ali"
  String _capitalize(String text) => text.toLowerCase().replaceAllMapped(
    RegExp(r'(^|[\s-])(\p{L})', unicode: true),
    (m) => '${m[1]}${m[2]!.toUpperCase()}',
  );

  @override
  Widget build(BuildContext context) {
    final priority = _priorityAlert;
    final shown = _sortedPatients(_patients).take(_shownCount).toList();

    return Scaffold(
      backgroundColor: SepsisColors.canvas,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: SepsisColors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Nouveau patient'),
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddPatientPage()),
          );
          if (added == true && mounted) _refresh();
        },
      ),
      bottomNavigationBar: const SepsisCareBottomNav(currentIndex: 0),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            children: [
              _header(),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _errorBanner(),
              ],
              const SizedBox(height: 18),
              if (_loading && _patients.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                Row(
                  children: [
                    _metric('Alerte', _highCount, 'alerte'),
                    const SizedBox(width: 9),
                    _metric('Surveillance', _monitorCount, 'surveillance'),
                    const SizedBox(width: 9),
                    _metric('Normal', _normalCount, 'normal'),
                  ],
                ),
                const SizedBox(height: 22),
                SectionTitle(
                  'Alerte prioritaire',
                  action: 'Toutes les alertes',
                  onAction: () => Navigator.pushNamed(context, '/alerts'),
                ),
                if (priority != null)
                  _priorityCard(priority)
                else
                  _noAlertCard(),
                const SizedBox(height: 22),
                SectionTitle(
                  'Patients suivis · ${_patients.length}',
                  action: 'Voir tous',
                  onAction: () => Navigator.pushNamed(context, '/patients'),
                ),
                if (shown.isEmpty)
                  _emptyPatients()
                else
                  ...shown.map(
                    (p) => PatientCard(
                      patient: p,
                      history: _history[p.id] ?? const [],
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/patient-details',
                        arguments: p,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'Scores et alertes issus du backend SepsisCare · Simulation de recherche',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: SepsisColors.muted),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Header ─────────────────────────

  Widget _header() => Row(
    children: [
      Image.asset('assets/images/sepsis_logo.jpg', height: 42),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour${_doctorName.isEmpty ? '' : ', ${_capitalize(_doctorName)}'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 21,
                height: 1.2,
                color: SepsisColors.navy,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 7,
                  color: _error == null ? SepsisColors.low : SepsisColors.high,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    '${_today()} · ${_updatedText()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: _error == null
                          ? SepsisColors.muted
                          : SepsisColors.high,
                      fontWeight: _error == null
                          ? FontWeight.w500
                          : FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      _roundAction(
        Icons.notifications_none_rounded,
        () => Navigator.pushNamed(context, '/alerts'),
        count: _newAlertCount,
      ),
      IconButton(
        tooltip: 'Actualiser',
        onPressed: () => _refresh(),
        icon: const Icon(Icons.refresh_rounded, color: SepsisColors.navy),
      ),
    ],
  );

  Widget _roundAction(
    IconData icon,
    VoidCallback onTap, {
    int count = 0,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SepsisColors.border),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, color: SepsisColors.navy, size: 21),
          if (count > 0)
            Positioned(
              right: 3,
              top: 3,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: const BoxDecoration(
                  color: SepsisColors.high,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _errorBanner() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: SepsisColors.highSoft,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.cloud_off_outlined,
          color: SepsisColors.high,
          size: 20,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            _error!,
            style: const TextStyle(
              color: SepsisColors.high,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(onPressed: () => _refresh(), child: const Text('Réessayer')),
      ],
    ),
  );

  // ───────────────────────── Counters ─────────────────────────

  /// Tapping opens the Patients page already filtered on this level.
  Widget _metric(String label, int value, String levelKey) {
    final color = SepsisColors.forLevel(levelKey);
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () =>
            Navigator.pushNamed(context, '/patients', arguments: levelKey),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: SepsisColors.softForLevel(levelKey),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 26,
                  color: color,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Priority alert ─────────────────────────

  /// Shows BOTH the score at alert time and the patient's current state,
  /// so an old open alert can't be mistaken for the current situation.
  Widget _priorityCard(PatientAlert alert) {
    final patient = alert.patient;
    final nowColor = SepsisColors.forLevel(patient.levelKey);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SepsisColors.highSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SepsisColors.high.withOpacity(.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: SepsisColors.high,
                size: 18,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Alerte ${alert.statusLabel.toLowerCase()} · ${alert.createdLabel}',
                  style: const TextStyle(
                    color: SepsisColors.high,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Lit ${patient.bed ?? '—'}',
            style: const TextStyle(
              color: SepsisColors.navy,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            '${patient.code} · ${patient.ageLabel} · ${patient.sexLabel}',
            style: const TextStyle(color: SepsisColors.muted, fontSize: 10),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _scoreBlock('À l’alerte', alert.riskLabel, SepsisColors.high),
              const SizedBox(width: 10),
              _scoreBlock(
                'Maintenant',
                '${patient.riskLabel} · ${patient.levelLabel}',
                nowColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pushNamed(
                context,
                '/alert-details',
                arguments: alert,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: SepsisColors.high,
                side: BorderSide(color: SepsisColors.high.withOpacity(.45)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Consulter les détails',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreBlock(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: SepsisColors.muted, fontSize: 10),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _noAlertCard() => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: SepsisColors.border),
    ),
    child: const Row(
      children: [
        CircleAvatar(
          backgroundColor: SepsisColors.lowSoft,
          child: Icon(Icons.check_rounded, color: SepsisColors.low),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Aucune alerte ouverte pour les patients actifs.',
            style: TextStyle(
              color: SepsisColors.navy,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _emptyPatients() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: SepsisColors.border),
    ),
    child: const Text(
      'Aucun patient actif pour le moment. Les patients apparaîtront ici dès leur admission dans le backend.',
      style: TextStyle(color: SepsisColors.muted, fontSize: 12),
    ),
  );
}
