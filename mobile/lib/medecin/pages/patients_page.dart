import 'dart:async';

import 'package:flutter/material.dart';

import 'package:mobile/models/patient.dart';
import 'package:mobile/core/services/api_service.dart';
import 'package:mobile/core/theme/colors.dart';
import 'package:mobile/medecin/widgets/patient_card.dart';
import 'package:mobile/medecin/widgets/sepsis_bottom_nav.dart';

const _levelOrder = ['alerte', 'surveillance', 'normal', 'unknown'];
const _levelNames = {
  'alerte': 'Alerte',
  'surveillance': 'Surveillance',
  'normal': 'Normal',
  'unknown': 'En attente',
};

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  List<PatientRecord> _patients = [];
  final Map<int, List<double>> _history =
      {}; // patient id -> last scores (oldest first)
  bool _loading = true;
  String? _error;
  String _status = 'actif';
  String? _levelFilter; // null = all levels
  Timer? _timer;
  bool _requesting = false;
  bool _reloadAfterCurrent = false;
  bool _historyBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? true))
        _load(silent: true);
    });
  }

  bool _argRead = false;

  /// Home counters open this page with a level ('alerte', 'surveillance', 'normal').
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argRead) return;
    _argRead = true;
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is String && _levelNames.containsKey(arg)) _levelFilter = arg;
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
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
    if (_requesting) {
      _reloadAfterCurrent = true;
      return;
    }
    _requesting = true;
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final patients = await ApiService.getPatients(status: _status);
      if (!mounted) return;
      setState(() {
        _patients = patients;
        _loading = false;
        _error = null;
      });
      unawaited(_refreshHistories(patients));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    } finally {
      _requesting = false;
      if (_reloadAfterCurrent && mounted) {
        _reloadAfterCurrent = false;
        _load(silent: true);
      }
    }
  }

  /// Loads the last 15 scores of each patient for the sparklines.
  /// On a failure for one patient, its previous sparkline is kept.
  Future<void> _refreshHistories(List<PatientRecord> patients) async {
    if (_historyBusy) return;
    _historyBusy = true;
    try {
      final entries = await Future.wait(
        patients.map((p) async {
          try {
            final rows = [...await ApiService.getPredictions(p.id, limit: 100)];
            rows.sort(
              (a, b) => (_asInt(a['heure_icu']) ?? 0).compareTo(
                _asInt(b['heure_icu']) ?? 0,
              ),
            );
            final scores = rows
                .map((r) => _asDouble(r['score']))
                .whereType<double>()
                .toList();
            final recent = scores.length > 15
                ? scores.sublist(scores.length - 15)
                : scores;
            return MapEntry<int, List<double>?>(p.id, recent);
          } catch (_) {
            return MapEntry<int, List<double>?>(p.id, null);
          }
        }),
      );
      if (!mounted) return;
      setState(() {
        for (final entry in entries) {
          if (entry.value != null) _history[entry.key] = entry.value!;
        }
      });
    } finally {
      _historyBusy = false;
    }
  }

  List<PatientRecord> get _visiblePatients {
    final search = _searchController.text.trim().toLowerCase();
    final result = _patients.where((patient) {
      final matchesSearch =
          search.isEmpty ||
          patient.code.toLowerCase().contains(search) ||
          (patient.service ?? '').toLowerCase().contains(search) ||
          (patient.bed ?? '').toLowerCase().contains(search);
      final matchesLevel =
          _levelFilter == null || patient.levelKey == _levelFilter;
      return matchesSearch && matchesLevel;
    }).toList();
    result.sort((a, b) => (b.riskPercent ?? -1).compareTo(a.riskPercent ?? -1));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visiblePatients;
    return Scaffold(
      bottomNavigationBar: const SepsisCareBottomNav(currentIndex: 2),
      appBar: AppBar(
        title: const Text(
          'Patients',
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
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            const Text(
              'Regroupés par niveau, puis triés par score du modèle.',
              style: TextStyle(color: SepsisColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 15),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'actif',
                  label: Text('Actifs'),
                  icon: Icon(Icons.monitor_heart_outlined),
                ),
                ButtonSegment(
                  value: 'sorti',
                  label: Text('Sortis'),
                  icon: Icon(Icons.exit_to_app_rounded),
                ),
              ],
              selected: {_status},
              onSelectionChanged: (value) {
                setState(() {
                  _status = value.first;
                  _levelFilter = null;
                });
                _load();
              },
            ),
            const SizedBox(height: 13),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Rechercher par code, lit ou service',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: SepsisColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: SepsisColors.border),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _filterChips(),
            const SizedBox(height: 8),
            if (_error != null) _errorCard(),
            if (_loading && _patients.isEmpty)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (visible.isEmpty)
              _emptyState()
            else
              ..._groups(visible),
            const SizedBox(height: 8),
            const Text(
              'Les niveaux Normal, Surveillance et Alerte sont ceux retournés par le modèle backend.',
              textAlign: TextAlign.center,
              style: TextStyle(color: SepsisColors.muted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChips() {
    int count(String key) => _patients.where((p) => p.levelKey == key).length;
    Widget chip(String? key, String label, int n) {
      final base = key == null ? SepsisColors.teal : SepsisColors.forLevel(key);
      final selected = _levelFilter == key;
      return ChoiceChip(
        label: Text('$label · $n'),
        selected: selected,
        showCheckmark: false,
        selectedColor: base.withOpacity(.16),
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? base : SepsisColors.border),
        labelStyle: TextStyle(
          color: selected ? base : SepsisColors.navy,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        onSelected: (_) => setState(() => _levelFilter = selected ? null : key),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        chip(null, 'Tous', _patients.length),
        chip('alerte', 'Alerte', count('alerte')),
        chip('surveillance', 'Surveillance', count('surveillance')),
        chip('normal', 'Normal', count('normal')),
      ],
    );
  }

  List<Widget> _groups(List<PatientRecord> visible) {
    final widgets = <Widget>[];
    for (final key in _levelOrder) {
      final group = visible.where((p) => p.levelKey == key).toList();
      if (group.isEmpty) continue;
      widgets.add(_groupHeader(key, group.length));
      widgets.addAll(
        group.map(
          (p) => PatientCard(
            patient: p,
            history: _history[p.id] ?? const [],
            onTap: () =>
                Navigator.pushNamed(context, '/patient-details', arguments: p),
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _groupHeader(String key, int count) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
    child: Row(
      children: [
        Icon(Icons.circle, size: 9, color: SepsisColors.forLevel(key)),
        const SizedBox(width: 7),
        Text(
          '${_levelNames[key]} · $count',
          style: TextStyle(
            color: SepsisColors.forLevel(key),
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );

  Widget _errorCard() => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: SepsisColors.highSoft,
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_outlined, color: SepsisColors.high),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            _error!,
            style: const TextStyle(color: SepsisColors.high, fontSize: 11),
          ),
        ),
        TextButton(onPressed: _load, child: const Text('Réessayer')),
      ],
    ),
  );

  Widget _emptyState() => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: SepsisColors.border),
    ),
    child: Text(
      _status == 'actif'
          ? 'Aucun patient actif ne correspond à votre recherche.'
          : 'Aucun patient sorti ne correspond à votre recherche.',
      textAlign: TextAlign.center,
      style: const TextStyle(color: SepsisColors.muted, fontSize: 12),
    ),
  );

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}
