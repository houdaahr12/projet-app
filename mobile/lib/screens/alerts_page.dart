import 'package:flutter/material.dart';
import '../models/demo_data.dart';
import '../theme/colors.dart';
import '../widgets/sepsis_bottom_nav.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final alerts = demoPatients.where((p) => p.level != 'Stable').toList()
      ..sort((a, b) => b.risk.compareTo(a.risk));
    return Scaffold(
      bottomNavigationBar: const SepsisCareBottomNav(currentIndex: 1),
      appBar: AppBar(title: const Text('Centre des alertes', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Priorisez les patients nécessitant une vérification clinique.',
          style: TextStyle(color: SepsisColors.muted, fontSize: 13)),
        const SizedBox(height: 17),
        Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(
          color: SepsisColors.highSoft, borderRadius: BorderRadius.circular(15)),
          child: Row(children: [
            const Icon(Icons.notifications_active_outlined, color: SepsisColors.high),
            const SizedBox(width: 10),
            Expanded(child: Text('${alerts.length} alertes de démonstration à consulter',
              style: const TextStyle(color: SepsisColors.high, fontWeight: FontWeight.w800, fontSize: 13))),
          ]),
        ),
        const SizedBox(height: 17),
        ...alerts.map((p) => Card(
          color: Colors.white, elevation: 0, margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: SepsisColors.border)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            leading: CircleAvatar(backgroundColor: SepsisColors.softForLevel(p.level),
              child: Icon(Icons.warning_amber_rounded, color: SepsisColors.forLevel(p.level))),
            title: Text('${p.code} · Lit ${p.bed}', style: const TextStyle(fontWeight: FontWeight.w800, color: SepsisColors.navy)),
            subtitle: Padding(padding: const EdgeInsets.only(top: 5),
              child: Text('${p.level} · ${p.updated}', style: const TextStyle(color: SepsisColors.muted, fontSize: 11))),
            trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('${p.risk}%', style: TextStyle(color: SepsisColors.forLevel(p.level), fontWeight: FontWeight.w900, fontSize: 18)),
              const Text('risque', style: TextStyle(color: SepsisColors.muted, fontSize: 9)),
            ]),
            onTap: () => Navigator.pushNamed(context, '/alert-details', arguments: p),
          ),
        )),
        const SizedBox(height: 10),
        const Text('Données fictives destinées à la présentation de l’interface.',
          textAlign: TextAlign.center, style: TextStyle(color: SepsisColors.muted, fontSize: 10)),
      ]),
    );
  }
}
