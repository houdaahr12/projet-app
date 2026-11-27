import 'package:flutter/material.dart';

import 'package:mobile/models/patient_alert.dart';
import 'package:mobile/core/theme/colors.dart';
import 'package:mobile/shared/widgets/factor_list.dart';
import 'package:mobile/shared/widgets/risk_chart.dart';

class AlertDetailsPage extends StatelessWidget {
  const AlertDetailsPage({super.key, required this.alert});
  final PatientAlert alert;

  @override
  Widget build(BuildContext context) {
    final patient = alert.patient;
    final nowColor = SepsisColors.forLevel(patient.levelKey);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Alerte · Lit ${patient.bed ?? '—'}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: SepsisColors.highSoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: SepsisColors.high.withOpacity(.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: SepsisColors.high,
                      size: 18,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Alerte ${alert.statusLabel.toLowerCase()} · ${alert.createdLabel}',
                        style: const TextStyle(
                          color: SepsisColors.high,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Lit ${patient.bed ?? '—'}',
                  style: const TextStyle(
                    color: SepsisColors.navy,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  patient.code,
                  style: const TextStyle(
                    color: SepsisColors.muted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${patient.ageLabel} · ${patient.sexLabel} · ${patient.service ?? 'Service non précisé'}',
                  style: const TextStyle(
                    color: SepsisColors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _scoreBlock(
                      'Score à l’alerte',
                      alert.riskLabel,
                      SepsisColors.high,
                    ),
                    const SizedBox(width: 10),
                    _scoreBlock(
                      'Actuellement',
                      '${patient.riskLabel} · ${patient.levelLabel}',
                      nowColor,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ThresholdBar(score: alert.score, color: SepsisColors.high),
                if (alert.note?.isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Note : ${alert.note!}',
                    style: const TextStyle(
                      color: SepsisColors.navy,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Pourquoi cette alerte ?',
            style: TextStyle(
              color: SepsisColors.navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          FactorsView(factors: parseFactors(alert.factors)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              '/patient-details',
              arguments: patient,
            ),
            icon: const Icon(Icons.folder_open_outlined),
            label: const Text('Ouvrir le dossier patient'),
            style: FilledButton.styleFrom(
              backgroundColor: SepsisColors.teal,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Le score est celui du modèle, pas une probabilité clinique. Données issues du rejeu du jeu TEST anonymisé : outil de recherche, pas un diagnostic médical.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SepsisColors.muted,
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreBlock(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: SepsisColors.muted, fontSize: 10),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );
}
