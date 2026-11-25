import 'dart:async';

import 'package:flutter/material.dart';

import '../models/patient_alert.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../widgets/sepsis_bottom_nav.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> with WidgetsBindingObserver {
  List<PatientAlert> _alerts = [];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  Timer? _timer;
  Set<int> _knownIds = {};
  bool _firstLoadDone = false;

  int get _newCount => _alerts.where((alert) => alert.isNew).length;
  int get _inProgressCount => _alerts.where((alert) => alert.status == 'prise_en_charge').length;

  @override
  void initState() {
    super.initState();
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
    if (state == AppLifecycleState.resumed) _load(silent: true);
  }

  Future<void> _load({bool silent = false}) async {
    if (_refreshing) return;
    _refreshing = true;
    if (!silent && mounted) setState(() => _loading = true);

    try {
      final activePatients = await ApiService.getPatients(status: 'actif');
      final alerts = await ApiService.getOpenAlertsForPatients(activePatients);
      final currentIds = alerts.map((alert) => alert.id).toSet();
      final newAlerts = _firstLoadDone
          ? alerts.where((alert) => alert.isNew && !_knownIds.contains(alert.id)).toList()
          : <PatientAlert>[];

      if (!mounted) return;
      setState(() {
        _alerts = alerts;
        _knownIds = currentIds;
        _loading = false;
        _error = null;
        _firstLoadDone = true;
      });

      if (newAlerts.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nouvelle alerte : ${newAlerts.first.patient.code} (${newAlerts.first.riskLabel})')),
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

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const SepsisCareBottomNav(currentIndex: 1),
    appBar: AppBar(
      title: const Text('Centre des alertes', style: TextStyle(fontWeight: FontWeight.w800)),
      actions: [IconButton(onPressed: () => _load(), tooltip: 'Actualiser', icon: const Icon(Icons.refresh_rounded))],
    ),
    body: RefreshIndicator(
      onRefresh: () => _load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Alertes ouvertes générées par le modèle pour les patients actuellement actifs.',
            style: TextStyle(color: SepsisColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 17),
          Row(children: [
            Expanded(child: _summaryCard('Nouvelles', _newCount, SepsisColors.high, SepsisColors.highSoft)),
            const SizedBox(width: 9),
            Expanded(child: _summaryCard('En cours', _inProgressCount, SepsisColors.mid, SepsisColors.midSoft)),
            const SizedBox(width: 9),
            Expanded(child: _summaryCard('Ouvertes', _alerts.length, SepsisColors.navy, SepsisColors.blueLight)),
          ]),
          if (_error != null) ...[
            const SizedBox(height: 14),
            _errorCard(),
          ],
          const SizedBox(height: 17),
          if (_loading && _alerts.isEmpty)
            const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator()))
          else if (_alerts.isEmpty)
            _emptyState()
          else ..._alerts.map(_alertTile),
          const SizedBox(height: 12),
          const Text(
            'Actualisation automatique toutes les 20 secondes lorsque cet écran est ouvert. Les notifications push ne sont pas configurées dans le backend actuel.',
            textAlign: TextAlign.center,
            style: TextStyle(color: SepsisColors.muted, fontSize: 10, height: 1.4),
          ),
        ],
      ),
    ),
  );

  Widget _summaryCard(String label, int value, Color color, Color soft) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: SepsisColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(height: 9),
      Text('$value', style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(color: SepsisColors.muted, fontSize: 10, fontWeight: FontWeight.w700)),
    ]),
  );

  Widget _errorCard() => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(color: SepsisColors.highSoft, borderRadius: BorderRadius.circular(13)),
    child: Row(children: [
      const Icon(Icons.cloud_off_outlined, color: SepsisColors.high),
      const SizedBox(width: 9),
      Expanded(child: Text(_error!, style: const TextStyle(color: SepsisColors.high, fontSize: 11))),
      TextButton(onPressed: () => _load(), child: const Text('Réessayer')),
    ]),
  );

  Widget _emptyState() => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: SepsisColors.border)),
    child: const Column(children: [
      CircleAvatar(radius: 27, backgroundColor: SepsisColors.lowSoft, child: Icon(Icons.notifications_off_outlined, color: SepsisColors.low, size: 27)),
      SizedBox(height: 12),
      Text('Aucune alerte ouverte', style: TextStyle(color: SepsisColors.navy, fontSize: 15, fontWeight: FontWeight.w800)),
      SizedBox(height: 5),
      Text('Lorsqu’une prédiction atteint le niveau « alerte », elle apparaîtra ici.', textAlign: TextAlign.center, style: TextStyle(color: SepsisColors.muted, fontSize: 11)),
    ]),
  );

  Widget _alertTile(PatientAlert alert) {
    final color = SepsisColors.high;
    final patient = alert.patient;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: SepsisColors.border)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(backgroundColor: SepsisColors.highSoft, child: Icon(Icons.warning_amber_rounded, color: color)),
        title: Text('${patient.code} · Lit ${patient.bed ?? '—'}', style: const TextStyle(fontWeight: FontWeight.w800, color: SepsisColors.navy)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text('${alert.statusLabel} · ${alert.createdLabel} · ${patient.ageLabel}', style: const TextStyle(color: SepsisColors.muted, fontSize: 10)),
        ),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(alert.riskLabel, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
          const Text('score', style: TextStyle(color: SepsisColors.muted, fontSize: 9)),
        ]),
        onTap: () => Navigator.pushNamed(context, '/alert-details', arguments: alert),
      ),
    );
  }
}
