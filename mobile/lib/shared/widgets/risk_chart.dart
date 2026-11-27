import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:mobile/core/config/risk_thresholds.dart';
import 'package:mobile/core/theme/colors.dart';

class RiskPoint {
  const RiskPoint(this.hour, this.score, this.level);
  final int hour; // ICU hour (x axis)
  final double score; // 0..1
  final String level; // level returned by the backend for this prediction
}

/// Line chart of the model score over ICU hours, with the Surveillance and
/// Alerte zones drawn behind it. Dots use the level the backend returned.
class RiskChart extends StatelessWidget {
  const RiskChart({super.key, required this.points, this.height = 190});

  final List<RiskPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _RiskChartPainter(points)),
    );
  }
}

class _RiskChartPainter extends CustomPainter {
  _RiskChartPainter(this.points);

  final List<RiskPoint> points;

  static const _left = 36.0;
  static const _right = 8.0;
  static const _top = 10.0;
  static const _bottom = 22.0;

  /// [anchor]: 0 = text starts at x, 0.5 = centered on x, 1 = text ends at x.
  void _text(
    Canvas canvas,
    String text,
    Offset at, {
    Color color = SepsisColors.muted,
    double anchor = 0,
    FontWeight weight = FontWeight.w600,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 9, fontWeight: weight),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(at.dx - painter.width * anchor, at.dy - painter.height / 2),
    );
  }

  void _dashed(Canvas canvas, double y, double x0, double x1, Paint paint) {
    var x = x0;
    while (x < x1) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + 4, x1), y), paint);
      x += 8;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final plot = Rect.fromLTRB(
      _left,
      _top,
      size.width - _right,
      size.height - _bottom,
    );
    final maxScore = points.map((p) => p.score).reduce(math.max);
    final yMax = math
        .max(RiskThresholds.alerte * 2, maxScore * 1.2)
        .clamp(0.1, 1.0)
        .toDouble();

    double yOf(double s) =>
        plot.bottom - plot.height * (s / yMax).clamp(0.0, 1.0).toDouble();

    final minH = points.first.hour;
    final maxH = points.last.hour;
    double xOf(int h) => maxH == minH
        ? plot.center.dx
        : plot.left + plot.width * (h - minH) / (maxH - minH);

    final yAlerte = yOf(RiskThresholds.alerte);
    final ySurv = yOf(RiskThresholds.surveillance);

    // Zones
    canvas.drawRect(
      Rect.fromLTRB(plot.left, yAlerte, plot.right, ySurv),
      Paint()..color = SepsisColors.forLevel('surveillance').withOpacity(.10),
    );
    canvas.drawRect(
      Rect.fromLTRB(plot.left, plot.top, plot.right, yAlerte),
      Paint()..color = SepsisColors.forLevel('alerte').withOpacity(.10),
    );

    // Threshold lines + labels
    final alertColor = SepsisColors.forLevel('alerte');
    final survColor = SepsisColors.forLevel('surveillance');
    _dashed(
      canvas,
      yAlerte,
      plot.left,
      plot.right,
      Paint()
        ..color = alertColor
        ..strokeWidth = 1,
    );
    _dashed(
      canvas,
      ySurv,
      plot.left,
      plot.right,
      Paint()
        ..color = survColor
        ..strokeWidth = 1,
    );
    _text(
      canvas,
      RiskThresholds.pct(RiskThresholds.alerte),
      Offset(_left - 5, yAlerte),
      color: alertColor,
      anchor: 1,
    );
    _text(
      canvas,
      RiskThresholds.pct(RiskThresholds.surveillance),
      Offset(_left - 5, ySurv),
      color: survColor,
      anchor: 1,
    );
    _text(
      canvas,
      'Alerte',
      Offset(plot.right - 4, yAlerte - 7),
      color: alertColor,
      anchor: 1,
    );
    _text(
      canvas,
      'Surveillance',
      Offset(plot.right - 4, ySurv - 7),
      color: survColor,
      anchor: 1,
    );

    // Baseline
    canvas.drawLine(
      Offset(plot.left, plot.bottom),
      Offset(plot.right, plot.bottom),
      Paint()..color = SepsisColors.border,
    );
    _text(canvas, '0%', Offset(_left - 5, plot.bottom), anchor: 1);

    // X labels (ICU hours)
    _text(canvas, 'H+$minH', Offset(plot.left, size.height - 8), anchor: 0);
    if (maxH - minH >= 4) {
      _text(
        canvas,
        'H+${(minH + maxH) ~/ 2}',
        Offset(plot.center.dx, size.height - 8),
        anchor: .5,
      );
    }
    _text(canvas, 'H+$maxH', Offset(plot.right, size.height - 8), anchor: 1);

    // Line
    final line = Path();
    for (var i = 0; i < points.length; i++) {
      final p = Offset(xOf(points[i].hour), yOf(points[i].score));
      i == 0 ? line.moveTo(p.dx, p.dy) : line.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = SepsisColors.navy
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round,
    );

    // Dots colored by the backend level
    final dotRadius = points.length > 40 ? 1.8 : 2.6;
    for (final point in points) {
      canvas.drawCircle(
        Offset(xOf(point.hour), yOf(point.score)),
        dotRadius,
        Paint()..color = SepsisColors.forLevel(point.level),
      );
    }

    // Latest point highlighted
    final last = points.last;
    final lastOffset = Offset(xOf(last.hour), yOf(last.score));
    canvas.drawCircle(lastOffset, 6, Paint()..color = Colors.white);
    canvas.drawCircle(
      lastOffset,
      4.2,
      Paint()..color = SepsisColors.forLevel(last.level),
    );
  }

  @override
  bool shouldRepaint(covariant _RiskChartPainter old) => true;
}

/// Horizontal bar scaled so the Alerte threshold sits at the middle,
/// instead of a 0-100% bar where every patient looks "low".
class ThresholdBar extends StatelessWidget {
  const ThresholdBar({super.key, required this.score, required this.color});

  final double? score; // 0..1
  final Color color;

  @override
  Widget build(BuildContext context) {
    const surv = RiskThresholds.surveillance;
    const alerte = RiskThresholds.alerte;
    final maxValue = (alerte * 2).clamp(0.1, 1.0).toDouble();
    int flex(double v) => (v * 1000).round().clamp(1, 100000);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final fraction = score == null
                ? null
                : (score! / maxValue).clamp(0.0, 1.0).toDouble();
            return SizedBox(
              height: 22,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 8,
                    height: 6,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Row(
                        children: [
                          Expanded(
                            flex: flex(surv),
                            child: ColoredBox(
                              color: SepsisColors.forLevel('normal')
                                  .withOpacity(.35),
                            ),
                          ),
                          Expanded(
                            flex: flex(alerte - surv),
                            child: ColoredBox(
                              color: SepsisColors.forLevel('surveillance')
                                  .withOpacity(.45),
                            ),
                          ),
                          Expanded(
                            flex: flex(maxValue - alerte),
                            child: ColoredBox(
                              color: SepsisColors.forLevel('alerte')
                                  .withOpacity(.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (fraction != null)
                    Positioned(
                      left: (width * fraction - 6)
                          .clamp(0.0, math.max(0.0, width - 12))
                          .toDouble(),
                      top: 4,
                      child: Container(
                        width: 12,
                        height: 14,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        Text(
          'Repères : Surveillance ≈ ${RiskThresholds.pct(surv)} · Alerte ≈ ${RiskThresholds.pct(alerte)} (le niveau est fixé par le modèle)',
          style: const TextStyle(color: SepsisColors.muted, fontSize: 9),
        ),
      ],
    );
  }
}
