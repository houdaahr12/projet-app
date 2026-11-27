import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:mobile/core/theme/colors.dart';

/// Tiny trend line. [values] are scores (0..1) in chronological order.
/// [minSpan] keeps tiny noise (e.g. 5.9% -> 6.1%) looking flat instead of dramatic.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    required this.color,
    this.width = 80,
    this.height = 32,
    this.minSpan = 0.04,
  });

  final List<double> values;
  final Color color;
  final double width;
  final double height;
  final double minSpan;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) {
      return SizedBox(
        width: width,
        height: height,
        child: const Center(
          child: Text('···', style: TextStyle(color: SepsisColors.muted)),
        ),
      );
    }
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _SparklinePainter(values, color, minSpan)),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.values, this.color, this.minSpan);

  final List<double> values;
  final Color color;
  final double minSpan;

  @override
  void paint(Canvas canvas, Size size) {
    var lo = values.reduce((a, b) => a < b ? a : b);
    var hi = values.reduce((a, b) => a > b ? a : b);
    if (hi - lo < minSpan) {
      final mid = (hi + lo) / 2;
      lo = mid - minSpan / 2;
      hi = mid + minSpan / 2;
    }

    const pad = 3.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;
    Offset point(int i) => Offset(
      pad + w * i / (values.length - 1),
      pad + h * (1 - (values[i] - lo) / (hi - lo)),
    );

    final line = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 1; i < values.length; i++) {
      final p = point(i);
      line.lineTo(p.dx, p.dy);
    }

    final last = point(values.length - 1);
    final fill = Path.from(line)
      ..lineTo(last.dx, size.height)
      ..lineTo(point(0).dx, size.height)
      ..close();

    canvas.drawPath(fill, Paint()..color = color.withOpacity(.10));
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(last, 2.8, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      !listEquals(old.values, values) ||
      old.color != color ||
      old.minSpan != minSpan;
}
