import 'package:flutter/material.dart';
import '../models/demo_data.dart';
import '../theme/colors.dart';

class PatientDetailsPage extends StatelessWidget {
  const PatientDetailsPage({super.key, required this.patient});
  final DemoPatient patient;

  @override
  Widget build(BuildContext context) {
    final color = SepsisColors.forLevel(patient.level);
    return Scaffold(
      appBar: AppBar(title: const Text('Dossier patient', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: SepsisColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(radius: 25, backgroundColor: SepsisColors.softForLevel(patient.level),
                child: Icon(Icons.person_outline_rounded, color: color, size: 27)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(patient.code, style: const TextStyle(fontSize: 19, color: SepsisColors.navy, fontWeight: FontWeight.w900)),
                Text('Lit ${patient.bed} · Service de réanimation', style: const TextStyle(color: SepsisColors.muted, fontSize: 11)),
              ])),
              _levelChip(patient.level),
            ]),
            const SizedBox(height: 20),
            const Divider(color: SepsisColors.border),
            _infoRow('Âge', '${patient.age} ans'),
            _infoRow('Sexe', patient.sex),
            _infoRow('Dernière actualisation', patient.updated),
          ]),
        ),
        const SizedBox(height: 17),
        const Text('Évaluation du risque', style: TextStyle(fontSize: 17, color: SepsisColors.navy, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: SepsisColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${patient.risk}%', style: TextStyle(fontSize: 34, color: color, fontWeight: FontWeight.w900)),
              const Spacer(),
              Icon(patient.change > 0 ? Icons.trending_up : Icons.trending_down, color: color),
              Text('${patient.change > 0 ? '+' : ''}${patient.change.toStringAsFixed(0)}%',
                style: TextStyle(color: color, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(
              value: patient.risk / 100, minHeight: 8, backgroundColor: SepsisColors.border,
              valueColor: AlwaysStoppedAnimation(color))),
            const SizedBox(height: 8),
            const Text('Indicateur illustratif — aucune prédiction réelle n’est exécutée dans cette version.',
              style: TextStyle(color: SepsisColors.muted, fontSize: 10)),
          ]),
        ),
        const SizedBox(height: 18),
        const Text('Paramètres à examiner', style: TextStyle(fontSize: 17, color: SepsisColors.navy, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        ...patient.factors.map((f) => Container(
          margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13),
            border: Border.all(color: SepsisColors.border)),
          child: Row(children: [
            Icon(Icons.circle, size: 7, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(f, style: const TextStyle(color: SepsisColors.navy, fontSize: 12))),
          ]),
        )),
      ]),
    );
  }

  Widget _levelChip(String level) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: SepsisColors.softForLevel(level), borderRadius: BorderRadius.circular(20)),
    child: Text(level, style: TextStyle(color: SepsisColors.forLevel(level), fontSize: 10, fontWeight: FontWeight.w800)),
  );

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: SepsisColors.muted, fontSize: 12))),
      Text(value, style: const TextStyle(color: SepsisColors.navy, fontWeight: FontWeight.w700, fontSize: 12)),
    ]),
  );
}
