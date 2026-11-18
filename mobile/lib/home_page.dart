import 'package:flutter/material.dart';

import 'brand.dart';
import 'models/demo_data.dart';
import 'theme/colors.dart';
import 'widgets/sepsis_logo.dart';
import 'widgets/sepsis_bottom_nav.dart';
import 'widgets/section_title.dart';
import 'services/auth_service.dart';

class HomePage extends StatefulWidget {
const HomePage({super.key, String userName = ''});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _doctorName = '';

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final nom = await AuthService.getUserName();
    if (!mounted) return;
    setState(() => _doctorName = nom ?? '');
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
    final d = DateTime.now();
    return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final urgent = demoPatients.where((p) => p.level == 'Élevé').toList();
    return Scaffold(
      backgroundColor: SepsisColors.canvas,
      bottomNavigationBar: const SepsisCareBottomNav(currentIndex: 0),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          children: [
            Row(
              children: [
                const SepsisCareLogo(),
                const Spacer(),
                _roundAction(
                  context,
                  Icons.notifications_none_rounded,
                  () => Navigator.pushNamed(context, '/alerts'),
                  badge: true,
                ),
                const SizedBox(width: 9),
                _roundAction(
                  context,
                  Icons.person_outline_rounded,
                  () => Navigator.pushNamed(context, '/profile'),
                ),
              ],
            ),
            const SizedBox(height: 27),
            Text(
              '${_today().toUpperCase()} · SERVICE DE RÉANIMATION',
              style: const TextStyle(
                fontSize: 11,
                letterSpacing: 1.1,
                color: SepsisColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bonjour, ${_doctorName.isEmpty ? demoDoctorName : _doctorName}',
              style: const TextStyle(
                fontSize: 24,
                height: 1.2,
                letterSpacing: 1.1,
                color: SepsisColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Voici le résumé de votre unité aujourd’hui.',
              style: TextStyle(
                fontSize: 14,
                color: SepsisColors.muted,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 20),
            _statusStrip(),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _metricCard(
                    'Risque élevé',
                    demoAlertCount,
                    SepsisColors.high,
                    SepsisColors.highSoft,
                    Icons.priority_high_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _metricCard(
                    'À surveiller',
                    demoModerateCount,
                    SepsisColors.mid,
                    SepsisColors.midSoft,
                    Icons.monitor_heart_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _metricCard(
                    'Stables',
                    demoStableCount,
                    SepsisColors.low,
                    SepsisColors.lowSoft,
                    Icons.check_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SectionTitle(
              'Alerte prioritaire',
              action: 'Toutes les alertes',
              onAction: () => Navigator.pushNamed(context, '/alerts'),
            ),
            _priorityCard(context, urgent.first),
            const SizedBox(height: 23),
            SectionTitle(
              'Patients surveillés',
              action: 'Voir tous',
              onAction: () => Navigator.pushNamed(context, '/patients'),
            ),
            ...demoPatients.take(3).map((p) => _patientTile(context, p)),
            const SizedBox(height: 18),
            const Text(
              'ACCÈS RAPIDE',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.2,
                color: SepsisColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _quickLink(
                    context,
                    Icons.notifications_active_outlined,
                    'Centre des alertes',
                    '/alerts',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _quickLink(
                    context,
                    Icons.people_alt_outlined,
                    'Dossiers patients',
                    '/patients',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _quickLink(
                    context,
                    Icons.badge_outlined,
                    'Mon profil',
                    '/profile',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Center(
              child: Text(
                'Version de démonstration · Données fictives',
                style: TextStyle(fontSize: 10, color: SepsisColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundAction(
    BuildContext context,
    IconData icon,
    VoidCallback onTap, {
    bool badge = false,
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
          if (badge)
            Positioned(
              right: 9,
              top: 8,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: SepsisColors.high,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _statusStrip() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: SepsisColors.border),
    ),
    child: const Row(
      children: [
        Icon(Icons.circle, size: 8, color: SepsisColors.low),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Unité en activité',
            style: TextStyle(
              color: SepsisColors.navy,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          'DÉMO STATIQUE',
          style: TextStyle(
            color: SepsisColors.muted,
            fontSize: 10,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _metricCard(
    String label,
    int value,
    Color color,
    Color soft,
    IconData icon,
  ) => Container(
    padding: const EdgeInsets.fromLTRB(11, 13, 9, 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: SepsisColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 29,
          height: 29,
          decoration: BoxDecoration(
            color: soft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(height: 10),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.toDouble()),
          duration: const Duration(milliseconds: 850),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => Text(
            v.toInt().toString(),
            style: TextStyle(
              fontSize: 25,
              color: color,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          maxLines: 2,
          style: const TextStyle(
            fontSize: 10,
            color: SepsisColors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _priorityCard(BuildContext context, DemoPatient p) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF18384D),
      borderRadius: BorderRadius.circular(19),
      boxShadow: [
        BoxShadow(
          color: SepsisColors.navy.withOpacity(.10),
          blurRadius: 18,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFFFC4A8),
              size: 18,
            ),
            const SizedBox(width: 7),
            const Expanded(
              child: Text(
                'ALERTE À EXAMINER',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF7E3943),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'ÉLEVÉ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          '${p.code}  ·  Lit ${p.bed}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Risque estimé (simulation de présentation)',
          style: TextStyle(color: Colors.white60, fontSize: 11),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${p.risk}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const Spacer(),
            _trend(p.change, dark: true),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: p.risk / 100,
            minHeight: 6,
            backgroundColor: Colors.white.withOpacity(.16),
            valueColor: const AlwaysStoppedAnimation(Color(0xFFFF9A8F)),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/alert-details', arguments: p),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withOpacity(.35)),
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

  Widget _patientTile(BuildContext context, DemoPatient p) {
    final color = SepsisColors.forLevel(p.level);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () =>
              Navigator.pushNamed(context, '/patient-details', arguments: p),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: SepsisColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 43,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${p.code}  ·  Lit ${p.bed}',
                        style: const TextStyle(
                          color: SepsisColors.navy,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${p.age} ans · ${p.sex} · ${p.updated}',
                        style: const TextStyle(
                          color: SepsisColors.muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                _trend(p.change),
                const SizedBox(width: 9),
                Text(
                  '${p.risk}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: SepsisColors.muted,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _trend(double change, {bool dark = false}) {
    final rising = change > 0;
    final flat = change == 0;
    final color = dark
        ? (rising ? const Color(0xFFFFB0A7) : const Color(0xFF9BE0C8))
        : (rising ? SepsisColors.high : SepsisColors.low);
    final icon = flat
        ? Icons.trending_flat_rounded
        : (rising ? Icons.trending_up_rounded : Icons.trending_down_rounded);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        Text(
          '${change > 0 ? '+' : ''}${change.toStringAsFixed(0)}%',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _quickLink(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) => InkWell(
    onTap: () => Navigator.pushNamed(context, route),
    borderRadius: BorderRadius.circular(15),
    child: Container(
      height: 90,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: SepsisColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: SepsisColors.teal, size: 21),
          Text(
            label,
            style: const TextStyle(
              color: SepsisColors.navy,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}
