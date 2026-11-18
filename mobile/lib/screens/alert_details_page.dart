import 'package:flutter/material.dart';
import '../models/demo_data.dart';
import '../theme/colors.dart';

class AlertDetailsPage extends StatelessWidget {
  const AlertDetailsPage({super.key, required this.patient});
  final DemoPatient patient;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Détail de l’alerte', style: TextStyle(fontWeight: FontWeight.w800))),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(
        color: SepsisColors.highSoft, borderRadius: BorderRadius.circular(17)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.warning_amber_rounded, color: SepsisColors.high),
            SizedBox(width: 8),
            Text('ALERTE DE DÉMONSTRATION', style: TextStyle(color: SepsisColors.high, fontSize: 10, letterSpacing: .8, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 13),
          Text(patient.code, style: const TextStyle(color: SepsisColors.navy, fontSize: 22, fontWeight: FontWeight.w900)),
          Text('Lit ${patient.bed} · ${patient.age} ans · ${patient.sex}',
            style: const TextStyle(color: SepsisColors.muted, fontSize: 12)),
          const SizedBox(height: 14),
          Text('${patient.risk}%', style: const TextStyle(color: SepsisColors.high, fontSize: 38, fontWeight: FontWeight.w900)),
          const Text('Indicateur fictif de risque', style: TextStyle(color: SepsisColors.muted, fontSize: 11)),
        ]),
      ),
      const SizedBox(height: 20),
      const Text('Éléments associés', style: TextStyle(color: SepsisColors.navy, fontSize: 17, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      ...patient.factors.map((f) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.analytics_outlined, color: SepsisColors.teal),
        title: Text(f, style: const TextStyle(color: SepsisColors.navy, fontSize: 13)),
      )),
      const SizedBox(height: 15),
      FilledButton.icon(
        onPressed: () => Navigator.pushNamed(context, '/patient-details', arguments: patient),
        icon: const Icon(Icons.folder_open_outlined),
        label: const Text('Ouvrir le dossier patient'),
        style: FilledButton.styleFrom(backgroundColor: SepsisColors.teal, minimumSize: const Size.fromHeight(48)),
      ),
      const SizedBox(height: 12),
      const Text('Cette alerte est une donnée fictive de présentation. Elle ne constitue pas une alerte médicale.',
        textAlign: TextAlign.center, style: TextStyle(color: SepsisColors.muted, fontSize: 10)),
    ]),
  );
}
