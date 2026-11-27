import 'package:flutter/material.dart';

import 'package:mobile/core/theme/colors.dart';
import 'package:mobile/shared/utils/factor_labels.dart';

// Factors about "how long / how often", not about the patient's physiology.
const _contextFeatures = {'ICULOS', 'HospAdmTime', 'Unit1', 'Unit2'};

bool isContextFeature(String feature) =>
    _contextFeatures.contains(feature) || describeFactor(feature).isTiming;

class FactorImpact {
  const FactorImpact(this.feature, this.impact);
  final String feature;
  final double impact;
}

/// Parses the backend's `facteurs` list: [{variable: 'HR_mean6', impact: 0.4}, ...]
List<FactorImpact> parseFactors(dynamic raw) {
  if (raw is! List) return const [];
  final result = <FactorImpact>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final name = item['variable']?.toString();
    final impactRaw = item['impact'];
    final impact = impactRaw is num
        ? impactRaw.toDouble()
        : double.tryParse(impactRaw?.toString() ?? '');
    if (name == null || impact == null) continue;
    result.add(FactorImpact(name, impact));
  }
  return result;
}

/// Card listing the model factors: physiological ones first,
/// context / measurement-frequency ones in a collapsed section.
class FactorsView extends StatelessWidget {
  const FactorsView({super.key, required this.factors});
  final List<FactorImpact> factors;

  @override
  Widget build(BuildContext context) {
    if (factors.isEmpty) {
      return _panel(
        const Text(
          'Aucun facteur explicatif fourni.',
          style: TextStyle(color: SepsisColors.muted, fontSize: 11),
        ),
      );
    }

    final physio = factors.where((f) => !isContextFeature(f.feature)).toList();
    final contextFactors = factors
        .where((f) => isContextFeature(f.feature))
        .toList();
    final maxAbs = factors
        .map((f) => f.impact.abs())
        .fold<double>(0.0001, (a, b) => a > b ? a : b);

    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Facteurs physiologiques',
            style: TextStyle(
              color: SepsisColors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          if (physio.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'Aucun facteur physiologique parmi les principaux facteurs.',
                style: TextStyle(color: SepsisColors.muted, fontSize: 11),
              ),
            )
          else
            ...physio.map((f) => _row(f, maxAbs)),
          if (contextFactors.isNotEmpty) ...[
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text(
                  'Contexte et fréquence des mesures (${contextFactors.length})',
                  style: const TextStyle(
                    color: SepsisColors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: const Text(
                  'Durée de séjour et rythme des prélèvements, pas l’état physiologique.',
                  style: TextStyle(color: SepsisColors.muted, fontSize: 10),
                ),
                children: contextFactors.map((f) => _row(f, maxAbs)).toList(),
              ),
            ),
          ],
          const SizedBox(height: 6),
          const Text(
            '↑ augmente le score · ↓ le diminue. La barre compare l’influence relative des facteurs.',
            style: TextStyle(color: SepsisColors.muted, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _panel(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: SepsisColors.border),
    ),
    child: child,
  );

  Widget _row(FactorImpact f, double maxAbs) {
    final label = describeFactor(f.feature).text;
    final up = f.impact >= 0;
    final c = up ? SepsisColors.high : SepsisColors.teal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 14,
                color: c,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: SepsisColors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${up ? '+' : ''}${f.impact.toStringAsFixed(2)}',
                style: const TextStyle(color: SepsisColors.muted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (f.impact.abs() / maxAbs).clamp(0.0, 1.0).toDouble(),
              minHeight: 4,
              backgroundColor: SepsisColors.border,
              valueColor: AlwaysStoppedAnimation(c),
            ),
          ),
        ],
      ),
    );
  }
}
