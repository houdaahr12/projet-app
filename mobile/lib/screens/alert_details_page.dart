import 'package:flutter/material.dart';

import '../models/patient_alert.dart';
import '../theme/colors.dart';

class AlertDetailsPage extends StatelessWidget {
  const AlertDetailsPage({super.key, required this.alert});
  final PatientAlert alert;

  @override
  Widget build(BuildContext context) {
    final patient = alert.patient;
    return Scaffold(
      appBar: AppBar(title: const Text('Détail de l’alerte', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: SepsisColors.highSoft, borderRadius: BorderRadius.circular(17)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.warning_amber_rounded, color: SepsisColors.high),
              SizedBox(width: 8),
              Text('ALERTE DU MODÈLE', style: TextStyle(color: SepsisColors.high, fontSize: 10, letterSpacing: .8, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 13),
            Text(patient.code, style: const TextStyle(color: SepsisColors.navy, fontSize: 22, fontWeight: FontWeight.w900)),
            Text('Lit ${patient.bed ?? '—'} · ${patient.ageLabel} · ${patient.sexLabel}', style: const TextStyle(color: SepsisColors.muted, fontSize: 12)),
            const SizedBox(height: 14),
            Text(alert.riskLabel, style: const TextStyle(color: SepsisColors.high, fontSize: 38, fontWeight: FontWeight.w900)),
            const Text('Score retourné par le modèle (0–100 %)', style: TextStyle(color: SepsisColors.muted, fontSize: 11)),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: (alert.riskPercent / 100).clamp(0, 1).toDouble(), minHeight: 7, backgroundColor: Colors.white, valueColor: const AlwaysStoppedAnimation(SepsisColors.high))),
            const SizedBox(height: 13),
            _infoLine('État', alert.statusLabel),
            _infoLine('Créée', alert.createdLabel),
            if (alert.note?.isNotEmpty == true) _infoLine('Note', alert.note!),
          ]),
        ),
        const SizedBox(height: 20),
        const Text('Facteurs associés', style: TextStyle(color: SepsisColors.navy, fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        if (alert.factorLines.isEmpty)
          const Text('Aucun facteur explicatif fourni pour cette alerte.', style: TextStyle(color: SepsisColors.muted, fontSize: 12))
        else
          ...alert.factorLines.map((factor) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13), border: Border.all(color: SepsisColors.border)),
            child: Row(children: [
              const Icon(Icons.analytics_outlined, color: SepsisColors.teal, size: 19),
              const SizedBox(width: 10),
              Expanded(child: Text(factor, style: const TextStyle(color: SepsisColors.navy, fontSize: 12))),
            ]),
          )),
        const SizedBox(height: 15),
        FilledButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/patient-details', arguments: patient),
          icon: const Icon(Icons.folder_open_outlined),
          label: const Text('Ouvrir le dossier patient'),
          style: FilledButton.styleFrom(backgroundColor: SepsisColors.teal, minimumSize: const Size.fromHeight(48)),
        ),
        const SizedBox(height: 12),
        const Text(
          'Données issues du rejeu du jeu TEST anonymisé. Cette simulation est un outil de recherche et ne constitue pas un diagnostic médical.',
          textAlign: TextAlign.center,
          style: TextStyle(color: SepsisColors.muted, fontSize: 10, height: 1.4),
        ),
      ]),
    );
  }

  Widget _infoLine(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 7),
    child: Row(children: [
      SizedBox(width: 85, child: Text(label, style: const TextStyle(color: SepsisColors.muted, fontSize: 11))),
      Expanded(child: Text(value, style: const TextStyle(color: SepsisColors.navy, fontSize: 11, fontWeight: FontWeight.w700))),
    ]),
  );
}
