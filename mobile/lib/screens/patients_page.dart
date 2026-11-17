import 'package:flutter/material.dart';
import '../models/demo_data.dart';
import '../theme/colors.dart';
import '../widgets/sepsis_bottom_nav.dart';

class PatientsPage extends StatelessWidget {
  const PatientsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const SepsisCareBottomNav(currentIndex: 2),
    appBar: AppBar(title: const Text('Patients', style: TextStyle(fontWeight: FontWeight.w800))),
    body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
      const Text('Vue d’ensemble des patients de l’unité.',
        style: TextStyle(color: SepsisColors.muted, fontSize: 13)),
      const SizedBox(height: 16),
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: SepsisColors.border)),
        child: Row(children: [
          const Icon(Icons.groups_2_outlined, color: SepsisColors.teal, size: 24),
          const SizedBox(width: 10),
          const Expanded(child: Text('Patients actifs', style: TextStyle(color: SepsisColors.navy, fontWeight: FontWeight.w700))),
          Text('${demoPatients.length}', style: const TextStyle(color: SepsisColors.navy, fontSize: 22, fontWeight: FontWeight.w900)),
        ]),
      ),
      const SizedBox(height: 14),
      ...demoPatients.map((p) {
        final c = SepsisColors.forLevel(p.level);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15),
            border: Border.all(color: SepsisColors.border)),
          child: ListTile(
            onTap: () => Navigator.pushNamed(context, '/patient-details', arguments: p),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: CircleAvatar(backgroundColor: SepsisColors.softForLevel(p.level),
              child: Icon(Icons.person_outline_rounded, color: c)),
            title: Text('${p.code} · Lit ${p.bed}', style: const TextStyle(color: SepsisColors.navy, fontWeight: FontWeight.w800)),
            subtitle: Text('${p.age} ans · ${p.sex} · ${p.updated}',
              style: const TextStyle(color: SepsisColors.muted, fontSize: 10)),
            trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${p.risk}%', style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 18)),
              Text(p.level, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w700)),
            ]),
          ),
        );
      }),
      const Text('Patients et indicateurs fictifs pour la première présentation.',
        textAlign: TextAlign.center, style: TextStyle(color: SepsisColors.muted, fontSize: 10)),
    ]),
  );
}
