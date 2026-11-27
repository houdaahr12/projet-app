import 'package:flutter/material.dart';

import 'package:mobile/core/theme/colors.dart';
import 'package:mobile/models/patient.dart';
import 'package:mobile/models/patient_alert.dart';

/// Style commun à toutes les pages.
class SepsisUI {
  static BoxDecoration card({double radius = 20}) => BoxDecoration(
    color: SepsisColors.surface,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: SepsisColors.navy.withOpacity(.07),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ],
  );

  static const gradient = LinearGradient(
    colors: [SepsisColors.navy, SepsisColors.teal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class LevelPill extends StatelessWidget {
  const LevelPill({super.key, required this.levelKey, required this.label});
  final String levelKey;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: SepsisColors.softForLevel(levelKey),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: SepsisColors.forLevel(levelKey),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

/// Carré coloré contenant le score du modèle.
class ScoreBadge extends StatelessWidget {
  const ScoreBadge({super.key, required this.levelKey, required this.value});
  final String levelKey;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    width: 62,
    height: 62,
    padding: const EdgeInsets.all(7),
    decoration: BoxDecoration(
      color: SepsisColors.softForLevel(levelKey),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: SepsisColors.forLevel(levelKey),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Text(
          'score',
          style: TextStyle(color: SepsisColors.muted, fontSize: 9),
        ),
      ],
    ),
  );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: SepsisUI.card(),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(padding: const EdgeInsets.all(14), child: child),
      ),
    ),
  );
}

const _bedStyle = TextStyle(
  color: SepsisColors.navy,
  fontSize: 16,
  fontWeight: FontWeight.w700,
);
const _detailStyle = TextStyle(color: SepsisColors.muted, fontSize: 11);

class PatientTile extends StatelessWidget {
  const PatientTile({
    super.key,
    required this.patient,
    required this.history,
    required this.onTap,
  });
  final PatientRecord patient;
  final List<double> history;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _Tile(
    onTap: onTap,
    child: Row(
      children: [
        ScoreBadge(levelKey: patient.levelKey, value: patient.riskLabel),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Lit ${patient.bed ?? '—'}', style: _bedStyle),
              Text(
                '${patient.code} · ${patient.ageLabel} · ${patient.sexLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _detailStyle,
              ),
              const SizedBox(height: 6),
              LevelPill(levelKey: patient.levelKey, label: patient.levelLabel),
            ],
          ),
        ),
        if (history.length > 1) ...[
          const SizedBox(width: 10),
          SizedBox(
            width: 64,
            height: 34,
            child: CustomPaint(
              painter: _SparklinePainter(
                history,
                SepsisColors.forLevel(patient.levelKey),
              ),
            ),
          ),
        ],
        const Icon(Icons.chevron_right_rounded, color: SepsisColors.muted),
      ],
    ),
  );
}

class AlertTile extends StatelessWidget {
  const AlertTile({super.key, required this.alert, required this.onTap});
  final PatientAlert alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final patient = alert.patient;
    return _Tile(
      onTap: onTap,
      child: Row(
        children: [
          // Score au moment de l'alerte.
          ScoreBadge(levelKey: 'alerte', value: alert.riskLabel),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lit ${patient.bed ?? '—'}', style: _bedStyle),
                Text(
                  '${patient.code} · ${alert.createdLabel}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _detailStyle,
                ),
                const SizedBox(height: 6),
                LevelPill(
                  levelKey: patient.levelKey,
                  label:
                      'Actuel : ${patient.riskLabel} · ${patient.levelLabel}',
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: SepsisColors.muted),
        ],
      ),
    );
  }
}

/// Mini-courbe des derniers scores (échelle ajustée à chaque patient).
class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.values, this.color);
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final low = values.reduce((a, b) => a < b ? a : b);
    final high = values.reduce((a, b) => a > b ? a : b);
    // Amplitude minimale : évite d'exagérer de très petites variations.
    final range = (high - low) < .05 ? .05 : high - low;
    final middle = (high + low) / 2;
    final path = Path();
    var last = Offset.zero;
    for (var i = 0; i < values.length; i++) {
      last = Offset(
        size.width * i / (values.length - 1),
        size.height * (.5 - (values[i] - middle) / range * .85),
      );
      i == 0 ? path.moveTo(last.dx, last.dy) : path.lineTo(last.dx, last.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(last, 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values || old.color != color;
}
