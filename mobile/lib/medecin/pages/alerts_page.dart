import 'dart:async';

import 'package:flutter/material.dart';

import 'package:mobile/models/patient_alert.dart';
import 'package:mobile/core/services/api_service.dart';
import 'package:mobile/core/theme/colors.dart';
import 'package:mobile/medecin/widgets/alert_card.dart';
import 'package:mobile/medecin/widgets/sepsis_bottom_nav.dart';
import 'package:mobile/shared/utils/level_change_notifier.dart';

const _statusOrder = ['nouvelle', 'vue', 'prise_en_charge'];
const _statusTitles = {
  'nouvelle': 'Nouvelles',
  'vue': 'Vues',
  'prise_en_charge': 'Prises en charge',
};

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
      if (!mounted) return;

      // Same rule as the home page: only notify when a patient's level gets worse.
      final escalated = LevelChangeNotifier.instance.detectEscalations(
        activePatients,
      );

      setState(() {
        _alerts = alerts;
        _loading = false;
        _error = null;
      });

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

  List<Widget> _sections() {
    final groups = {for (final key in _statusOrder) key: <PatientAlert>[]};
    for (final alert in _alerts) {
      (groups[alert.status] ?? groups['vue']!).add(alert);
    }

    final widgets = <Widget>[];
    for (final key in _statusOrder) {
      final list = groups[key]!;
      if (list.isEmpty) continue;
      list.sort(
        (a, b) => (b.createdAt ?? DateTime(2000)).compareTo(
          a.createdAt ?? DateTime(2000),
        ),
      );
      widgets.add(_sectionHeader(key, list.length));
      widgets.addAll(
        list.map(
          (alert) => AlertCard(
            alert: alert,
            onTap: () => Navigator.pushNamed(
              context,
              '/alert-details',
              arguments: alert,
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  Color _statusColor(String key) {
    switch (key) {
      case 'nouvelle':
        return SepsisColors.high;
      case 'prise_en_charge':
        return SepsisColors.teal;
      default:
        return SepsisColors.navy;
    }
  }

  Widget _sectionHeader(String key, int count) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
    child: Row(
      children: [
        Icon(Icons.circle, size: 9, color: _statusColor(key)),
        const SizedBox(width: 7),
        Text(
          '${_statusTitles[key]} · $count',
          style: TextStyle(
            color: _statusColor(key),
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const SepsisCareBottomNav(currentIndex: 1),
    appBar: AppBar(
      title: const Text(
        'Centre des alertes',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      actions: [
        IconButton(
          onPressed: () => _load(),
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
          Text(
            _alerts.isEmpty
                ? 'Alertes ouvertes des patients actifs.'
                : '${_alerts.length} alerte${_alerts.length > 1 ? 's' : ''} ouverte${_alerts.length > 1 ? 's' : ''} · les plus récentes en premier',
            style: const TextStyle(color: SepsisColors.muted, fontSize: 13),
          ),
          if (_error != null) ...[const SizedBox(height: 14), _errorCard()],
          const SizedBox(height: 8),
          if (_loading && _alerts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_alerts.isEmpty)
            _emptyState()
          else
            ..._sections(),
          const SizedBox(height: 12),
          const Text(
            'Actualisation automatique toutes les 20 secondes.',
            textAlign: TextAlign.center,
            style: TextStyle(color: SepsisColors.muted, fontSize: 10),
          ),
        ],
      ),
    ),
  );

  Widget _errorCard() => Container(
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
        TextButton(onPressed: () => _load(), child: const Text('Réessayer')),
      ],
    ),
  );

  Widget _emptyState() => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: SepsisColors.border),
    ),
    child: const Column(
      children: [
        CircleAvatar(
          radius: 27,
          backgroundColor: SepsisColors.lowSoft,
          child: Icon(
            Icons.notifications_off_outlined,
            color: SepsisColors.low,
            size: 27,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Aucune alerte ouverte',
          style: TextStyle(
            color: SepsisColors.navy,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Lorsqu’une prédiction atteint le niveau « alerte », elle apparaîtra ici.',
          textAlign: TextAlign.center,
          style: TextStyle(color: SepsisColors.muted, fontSize: 11),
        ),
      ],
    ),
  );
}
