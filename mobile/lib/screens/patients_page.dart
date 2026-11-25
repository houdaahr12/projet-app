import 'dart:async';

import 'package:flutter/material.dart';

import '../models/patient.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../widgets/sepsis_bottom_nav.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  List<PatientRecord> _patients = [];
  bool _loading = true;
  String? _error;
  String _status = 'actif';
  Timer? _timer;
  bool _requesting = false;
  bool _reloadAfterCurrent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? true)) _load(silent: true);
    });
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
    if (state == AppLifecycleState.resumed && (ModalRoute.of(context)?.isCurrent ?? true)) {
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
      });
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

  List<PatientRecord> get _visiblePatients {
    final search = _searchController.text.trim().toLowerCase();
    final result = _patients.where((patient) {
      return search.isEmpty ||
          patient.code.toLowerCase().contains(search) ||
          (patient.service ?? '').toLowerCase().contains(search) ||
          (patient.bed ?? '').toLowerCase().contains(search);
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
        title: const Text('Patients', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [IconButton(onPressed: _load, tooltip: 'Actualiser', icon: const Icon(Icons.refresh_rounded))],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            const Text('Patients accessibles à votre compte, triés par score de risque.', style: TextStyle(color: SepsisColors.muted, fontSize: 13)),
            const SizedBox(height: 15),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'actif', label: Text('Actifs'), icon: Icon(Icons.monitor_heart_outlined)),
                ButtonSegment(value: 'sorti', label: Text('Sortis'), icon: Icon(Icons.exit_to_app_rounded)),
              ],
              selected: {_status},
              onSelectionChanged: (value) {
                setState(() => _status = value.first);
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
                suffixIcon: _searchController.text.isEmpty ? null : IconButton(onPressed: () { _searchController.clear(); setState(() {}); }, icon: const Icon(Icons.close_rounded)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: SepsisColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: SepsisColors.border)),
              ),
            ),
            const SizedBox(height: 13),
            if (_error != null) _errorCard(),
            if (_loading && _patients.isEmpty)
              const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator()))
            else if (visible.isEmpty)
              _emptyState()
            else ...[
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: SepsisColors.border)),
                child: Row(children: [
                  const Icon(Icons.groups_2_outlined, color: SepsisColors.teal, size: 23),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_status == 'actif' ? 'Patients actifs' : 'Patients sortis', style: const TextStyle(color: SepsisColors.navy, fontWeight: FontWeight.w700))),
                  Text('${visible.length}', style: const TextStyle(color: SepsisColors.navy, fontSize: 21, fontWeight: FontWeight.w900)),
                ]),
              ),
              const SizedBox(height: 13),
              ...visible.map(_patientTile),
            ],
            const SizedBox(height: 8),
            const Text('Les niveaux Normal, Surveillance et Alerte sont ceux retournés par le modèle backend.', textAlign: TextAlign.center, style: TextStyle(color: SepsisColors.muted, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _errorCard() => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(color: SepsisColors.highSoft, borderRadius: BorderRadius.circular(13)),
    child: Row(children: [
      const Icon(Icons.cloud_off_outlined, color: SepsisColors.high),
      const SizedBox(width: 9),
      Expanded(child: Text(_error!, style: const TextStyle(color: SepsisColors.high, fontSize: 11))),
      TextButton(onPressed: _load, child: const Text('Réessayer')),
    ]),
  );

  Widget _emptyState() => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: SepsisColors.border)),
    child: Text(
      _status == 'actif' ? 'Aucun patient actif ne correspond à votre recherche.' : 'Aucun patient sorti ne correspond à votre recherche.',
      textAlign: TextAlign.center,
      style: const TextStyle(color: SepsisColors.muted, fontSize: 12),
    ),
  );

  Widget _patientTile(PatientRecord patient) {
    final color = SepsisColors.forLevel(patient.levelKey);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: SepsisColors.border)),
      child: ListTile(
        onTap: () => Navigator.pushNamed(context, '/patient-details', arguments: patient),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(backgroundColor: SepsisColors.softForLevel(patient.levelKey), child: Icon(Icons.person_outline_rounded, color: color)),
        title: Text('${patient.code} · Lit ${patient.bed ?? '—'}', style: const TextStyle(color: SepsisColors.navy, fontWeight: FontWeight.w800)),
        subtitle: Text('${patient.ageLabel} · ${patient.sexLabel} · ${patient.service ?? 'Service non précisé'} · ${patient.updatedLabel}', style: const TextStyle(color: SepsisColors.muted, fontSize: 10)),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(patient.riskLabel, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
          Text(patient.levelLabel, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}
