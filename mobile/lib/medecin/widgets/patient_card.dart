import 'package:flutter/material.dart';

import 'package:mobile/core/theme/colors.dart';
import 'package:mobile/models/patient.dart';
import 'package:mobile/shared/widgets/sparkline.dart';

/// Patient card: bed first, code small and grey, sparkline of the last scores.
/// Reusable on the Patients page and on the Home page.
class PatientCard extends StatelessWidget {
  const PatientCard({
    super.key,
    required this.patient,
    this.history = const [],
    this.onTap,
  });

  final PatientRecord patient;

  /// Last scores (0..1), oldest first, latest last.
  final List<double> history;
  final VoidCallback? onTap;

  static const _staleAfter = Duration(minutes: 2);

  @override
  Widget build(BuildContext context) {
    final color = SepsisColors.forLevel(patient.levelKey);
    final date = patient.latestPredictionAt;
    final stale =
        date != null && DateTime.now().difference(date.toLocal()) > _staleAfter;
    final staleColor = SepsisColors.forLevel('surveillance');

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
                  Container(width: 5, color: color),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lit ${patient.bed ?? '—'}',
                                  style: const TextStyle(
                                    color: SepsisColors.navy,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17,
                                  ),
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
                                  '${patient.ageLabel} · ${patient.sexLabel}',
                                  style: const TextStyle(
                                    color: SepsisColors.navy,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    if (stale) ...[
                                      Icon(
                                        Icons.schedule_rounded,
                                        size: 11,
                                        color: staleColor,
                                      ),
                                      const SizedBox(width: 3),
                                    ],
                                    Flexible(
                                      child: Text(
                                        patient.updatedLabel,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: stale
                                              ? staleColor
                                              : SepsisColors.muted,
                                          fontSize: 10,
                                          fontWeight: stale
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Sparkline(values: history, color: color),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 76,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _trendIcon(),
                                    Text(
                                      patient.riskLabel,
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  patient.levelLabel,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
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

  /// Direction of the score over the visible history (>= 1 point of change).
  Widget _trendIcon() {
    if (history.length < 2) return const SizedBox.shrink();
    final delta = history.last - history.first;
    if (delta.abs() < 0.01) {
      return Icon(
        Icons.trending_flat_rounded,
        size: 16,
        color: SepsisColors.muted,
      );
    }
    final up = delta > 0;
    return Icon(
      up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
      size: 16,
      color: up ? SepsisColors.high : SepsisColors.teal,
    );
  }
}
