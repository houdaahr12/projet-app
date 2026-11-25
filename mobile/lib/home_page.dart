import 'dart:async';

import 'package:flutter/material.dart';

import 'models/patient.dart';
import 'models/patient_alert.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'theme/colors.dart';
import 'widgets/sepsis_bottom_nav.dart';
import 'widgets/sepsis_logo.dart';
import 'widgets/section_title.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.userName = ''});
  final String userName;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  String _doctorName = '';
  List<PatientRecord> _patients = [];
  List<PatientAlert> _alerts = [];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  DateTime? _lastUpdated;
  Timer? _refreshTimer;
  Set<int> _knownAlertIds = {};
  bool _hasCompletedFirstLoad = false;

  int get _highCount => _patients.where((p) => p.levelKey == 'alerte').length;
  int get _monitorCount => _patients.where((p) => p.levelKey == 'surveillance').length;
  int get _normalCount => _patients.where((p) => p.levelKey == 'normal').length;
  int get _newAlertCount => _alerts.where((a) => a.isNew).length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _doctorName = widget.userName.trim();
    _loadDoctorName();
    _refresh();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) {
        if (mounted && (ModalRoute.of(context)?.isCurrent ?? true)) {
          _refresh(silent: true);
        }
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && (ModalRoute.of(context)?.isCurrent ?? true)) {
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
      // The backend lets a doctor see simulation patients and manually assigned
      // patients. Keep the dashboard focused on currently admitted patients.
      final patients = await ApiService.getPatients(status: 'actif');
      final alerts = await ApiService.getOpenAlertsForPatients(patients);
      final currentIds = alerts.map((a) => a.id).toSet();
      final appeared = _hasCompletedFirstLoad
          ? alerts.where((a) => a.isNew && !_knownAlertIds.contains(a.id)).toList()
          : <PatientAlert>[];

      if (!mounted) return;
      setState(() {
        _patients = patients;
        _alerts = alerts;
        _knownAlertIds = currentIds;
        _lastUpdated = DateTime.now();
        _error = null;
        _loading = false;
        _hasCompletedFirstLoad = true;
      });

      if (appeared.isNotEmpty && mounted) {
        final alert = appeared.first;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nouvelle alerte pour ${alert.patient.code} · ${alert.riskLabel}'),
            action: SnackBarAction(
              label: 'Voir',
              onPressed: () => Navigator.pushNamed(
                context,
                '/alert-details',
                arguments: alert,
              ),
            ),
          ),
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

  String _today() {
    const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    const months = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
    final date = DateTime.now();
    return '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final priority = _alerts.isNotEmpty ? _alerts.first : null;
    final shownPatients = [..._patients]
      ..sort((a, b) => (b.riskPercent ?? -1).compareTo(a.riskPercent ?? -1));

    return Scaffold(
      backgroundColor: SepsisColors.canvas,
      bottomNavigationBar: const SepsisCareBottomNav(currentIndex: 0),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            children: [
              Row(
                children: [
                  const SepsisCareLogo(),
                  const Spacer(),
                  _roundAction(
                    Icons.notifications_none_rounded,
                    () => Navigator.pushNamed(context, '/alerts'),
                    count: _newAlertCount,
                  ),
                  const SizedBox(width: 9),
                  _roundAction(
                    Icons.person_outline_rounded,
                    () => Navigator.pushNamed(context, '/profile'),
                  ),
                  const SizedBox(width: 5),
                  IconButton(
                    tooltip: 'Actualiser',
                    onPressed: () => _refresh(),
                    icon: const Icon(Icons.refresh_rounded, color: SepsisColors.navy),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Text(
                '${_today().toUpperCase()} · ESPACE MÉDECIN',
                style: const TextStyle(fontSize: 11, letterSpacing: 1.1, color: SepsisColors.muted, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Bonjour${_doctorName.isEmpty ? '' : ', $_doctorName'}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 23, height: 1.2, color: SepsisColors.navy, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Voici la situation actuelle des patients suivis.',
                style: TextStyle(fontSize: 14, color: SepsisColors.muted),
              ),
              const SizedBox(height: 18),
              _statusStrip(),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _errorBanner(),
              ],
              const SizedBox(height: 17),
              if (_loading && _patients.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                Row(
                  children: [
                    Expanded(child: _metricCard('Alerte', _highCount, SepsisColors.high, SepsisColors.highSoft, Icons.priority_high_rounded)),
                    const SizedBox(width: 9),
                    Expanded(child: _metricCard('Surveillance', _monitorCount, SepsisColors.mid, SepsisColors.midSoft, Icons.monitor_heart_outlined)),
                    const SizedBox(width: 9),
                    Expanded(child: _metricCard('Normal', _normalCount, SepsisColors.low, SepsisColors.lowSoft, Icons.check_rounded)),
                  ],
                ),
                const SizedBox(height: 24),
                SectionTitle(
                  'Alerte prioritaire',
                  action: 'Toutes les alertes',
                  onAction: () => Navigator.pushNamed(context, '/alerts'),
                ),
                if (priority != null)
                  _priorityCard(priority)
                else
                  _noAlertCard(),
                const SizedBox(height: 23),
                SectionTitle(
                  'Patients suivis',
                  action: 'Voir tous',
                  onAction: () => Navigator.pushNamed(context, '/patients'),
                ),
                if (shownPatients.isEmpty)
                  _emptyPatients()
                else
                  ...shownPatients.take(4).map(_patientTile),
                const SizedBox(height: 18),
                const Text('ACCÈS RAPIDE', style: TextStyle(fontSize: 10, letterSpacing: 1.2, color: SepsisColors.muted, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _quickLink(Icons.notifications_active_outlined, 'Centre des alertes', '/alerts')),
                  const SizedBox(width: 10),
                  Expanded(child: _quickLink(Icons.people_alt_outlined, 'Dossiers patients', '/patients')),
                  const SizedBox(width: 10),
                  Expanded(child: _quickLink(Icons.badge_outlined, 'Mon profil', '/profile')),
                ]),
                const SizedBox(height: 18),
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

  Widget _roundAction(IconData icon, VoidCallback onTap, {int count = 0}) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: SepsisColors.border)),
      child: Stack(alignment: Alignment.center, children: [
        Icon(icon, color: SepsisColors.navy, size: 21),
        if (count > 0)
          Positioned(
            right: 3,
            top: 3,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: const BoxDecoration(color: SepsisColors.high, shape: BoxShape.circle),
              child: Text('$count', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
            ),
          ),
      ]),
    ),
  );

  Widget _statusStrip() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: SepsisColors.border)),
    child: Row(children: [
      Icon(Icons.circle, size: 8, color: _error == null ? SepsisColors.low : SepsisColors.high),
      const SizedBox(width: 8),
      Expanded(child: Text(_error == null ? 'API connectée · patients actifs' : 'Connexion API à vérifier', style: const TextStyle(color: SepsisColors.navy, fontSize: 12, fontWeight: FontWeight.w700))),
      Text(_lastUpdated == null ? '—' : '${_lastUpdated!.hour.toString().padLeft(2, '0')}:${_lastUpdated!.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: SepsisColors.muted, fontSize: 10, fontWeight: FontWeight.w700)),
    ]),
  );

  Widget _errorBanner() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: SepsisColors.highSoft, borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      const Icon(Icons.cloud_off_outlined, color: SepsisColors.high, size: 20),
      const SizedBox(width: 9),
      Expanded(child: Text(_error!, style: const TextStyle(color: SepsisColors.high, fontSize: 11, fontWeight: FontWeight.w600))),
      TextButton(onPressed: () => _refresh(), child: const Text('Réessayer')),
    ]),
  );

  Widget _metricCard(String label, int value, Color color, Color soft, IconData icon) => Container(
    padding: const EdgeInsets.fromLTRB(10, 13, 8, 12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: SepsisColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 29, height: 29, decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 17)),
      const SizedBox(height: 10),
      TweenAnimationBuilder<double>(
        key: ValueKey('$label-$value'),
        tween: Tween(begin: 0, end: value.toDouble()),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (_, number, __) => Text(number.toInt().toString(), style: TextStyle(fontSize: 24, color: color, fontWeight: FontWeight.w900, height: 1)),
      ),
      const SizedBox(height: 5),
      Text(label, maxLines: 2, style: const TextStyle(fontSize: 10, color: SepsisColors.muted, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _priorityCard(PatientAlert alert) {
    final patient = alert.patient;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18384D),
        borderRadius: BorderRadius.circular(19),
        boxShadow: [BoxShadow(color: SepsisColors.navy.withOpacity(.10), blurRadius: 18, offset: const Offset(0, 7))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFC4A8), size: 18),
          const SizedBox(width: 7),
          const Expanded(child: Text('ALERTE GÉNÉRÉE PAR LE MODÈLE', style: TextStyle(color: Colors.white70, fontSize: 9, letterSpacing: .7, fontWeight: FontWeight.w800))),
          _darkChip(alert.statusLabel),
        ]),
        const SizedBox(height: 14),
        Text('${patient.code} · Lit ${patient.bed ?? '—'}', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('${patient.ageLabel} · ${patient.sexLabel} · ${alert.createdLabel}', style: const TextStyle(color: Colors.white60, fontSize: 10)),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(alert.riskLabel, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, height: 1)),
          const Spacer(),
          const Text('Score du modèle', style: TextStyle(color: Colors.white60, fontSize: 10)),
        ]),
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: (alert.riskPercent / 100).clamp(0, 1).toDouble(), minHeight: 6, backgroundColor: Colors.white.withOpacity(.16), valueColor: const AlwaysStoppedAnimation(Color(0xFFFF9A8F)))),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, '/alert-details', arguments: alert),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: Colors.white.withOpacity(.35)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Consulter les détails', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  Widget _darkChip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(color: const Color(0xFF7E3943), borderRadius: BorderRadius.circular(20)),
    child: Text(text.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
  );

  Widget _noAlertCard() => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: SepsisColors.border)),
    child: const Row(children: [
      CircleAvatar(backgroundColor: SepsisColors.lowSoft, child: Icon(Icons.check_rounded, color: SepsisColors.low)),
      SizedBox(width: 12),
      Expanded(child: Text('Aucune alerte ouverte pour les patients actifs.', style: TextStyle(color: SepsisColors.navy, fontWeight: FontWeight.w700, fontSize: 12))),
    ]),
  );

  Widget _emptyPatients() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: SepsisColors.border)),
    child: const Text('Aucun patient actif pour le moment. Les patients apparaîtront ici dès leur admission dans le backend.', style: TextStyle(color: SepsisColors.muted, fontSize: 12)),
  );

  Widget _patientTile(PatientRecord patient) {
    final color = SepsisColors.forLevel(patient.levelKey);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => Navigator.pushNamed(context, '/patient-details', arguments: patient),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: SepsisColors.border)),
            child: Row(children: [
              Container(width: 4, height: 43, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5))),
              const SizedBox(width: 11),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${patient.code} · Lit ${patient.bed ?? '—'}', style: const TextStyle(color: SepsisColors.navy, fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('${patient.ageLabel} · ${patient.sexLabel} · ${patient.updatedLabel}', style: const TextStyle(color: SepsisColors.muted, fontSize: 10)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(patient.riskLabel, style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w900)),
                Text(patient.levelLabel, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: SepsisColors.muted, size: 18),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _quickLink(IconData icon, String label, String route) => InkWell(
    onTap: () => Navigator.pushNamed(context, route),
    borderRadius: BorderRadius.circular(15),
    child: Container(
      height: 90,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: SepsisColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Icon(icon, color: SepsisColors.teal, size: 21),
        Text(label, style: const TextStyle(color: SepsisColors.navy, fontSize: 10, fontWeight: FontWeight.w700)),
      ]),
    ),
  );
}
