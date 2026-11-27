import 'package:flutter/material.dart';

import 'package:mobile/core/theme/colors.dart';
import 'package:mobile/models/patient_alert.dart';
import 'package:mobile/shared/utils/factor_labels.dart';
import 'package:mobile/shared/widgets/factor_list.dart';

class AlertCard extends StatelessWidget {
  const AlertCard({super.key, required this.alert, this.onTap});

  final PatientAlert alert;
  final VoidCallback? onTap;

  /// First physiological factor of the alert, in plain French (null if none).
  String? get _mainFactor {
    for (final f in parseFactors(alert.factors)) {
      if (!isContextFeature(f.feature)) return describeFactor(f.feature).text;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final patient = alert.patient;
    final nowColor = SepsisColors.forLevel(patient.levelKey);
    final factor = _mainFactor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: SepsisColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 5, color: SepsisColors.high),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Lit ${patient.bed ?? '—'}',
                                      style: const TextStyle(
                                        color: SepsisColors.navy,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 17,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _statusChip(),
                                  ],
                                ),
                                Text(
                                  patient.code,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: SepsisColors.muted,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${patient.ageLabel} · ${patient.sexLabel} · ${alert.createdLabel}',
                                  style: const TextStyle(
                                    color: SepsisColors.navy,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (factor != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.insights_rounded,
                                        size: 12,
                                        color: SepsisColors.muted,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          factor,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: SepsisColors.muted,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 78,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  alert.riskLabel,
                                  style: const TextStyle(
                                    color: SepsisColors.high,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                  ),
                                ),
                                const Text(
                                  'à l’alerte',
                                  style: TextStyle(
                                    color: SepsisColors.muted,
                                    fontSize: 9,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Actuel ${patient.riskLabel}',
                                  style: TextStyle(
                                    color: nowColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: SepsisColors.muted,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip() {
    Color fg;
    Color bg;
    switch (alert.status) {
      case 'nouvelle':
        fg = SepsisColors.high;
        bg = SepsisColors.highSoft;
        break;
      case 'prise_en_charge':
        fg = SepsisColors.low;
        bg = SepsisColors.lowSoft;
        break;
      default:
        fg = SepsisColors.navy;
        bg = SepsisColors.blueLight;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        alert.statusLabel,
        style: TextStyle(color: fg, fontSize: 9, fontWeight: FontWeight.w800),
      ),
    );
  }
}
