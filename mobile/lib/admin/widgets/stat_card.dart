
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:mobile/main.dart';
import 'package:mobile/admin/widgets/doctor_filters.dart';

class StatCard extends StatefulWidget {
  final String titre;
  final int valeur;
  final IconData icone;
  final Color couleur;
  final bool compact;
  final VoidCallback onTap;

  const StatCard({
    super.key,
    required this.titre,
    required this.valeur,
    required this.icone,
    required this.couleur,
    required this.compact,
    required this.onTap,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool hovered = false;
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    final color = widget.couleur;

    return Expanded(
      child: MouseRegion(
        onEnter: (_) {
          setState(() => hovered = true);
        },
        onExit: (_) {
          setState(() => hovered = false);
        },
        child: AnimatedScale(
          scale: pressed ? 0.96 : hovered ? 1.035 : 1,
          duration: const Duration(milliseconds: 180),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: hovered
                  ? color.withValues(alpha: 0.045)
                  : Colors.white,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: hovered
                    ? color.withValues(alpha: 0.45)
                    : const Color(0xFFE1EAF4),
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(
                    alpha: hovered ? 0.15 : 0.07,
                  ),
                  blurRadius: hovered ? 20 : 12,
                  offset: Offset(0, hovered ? 8 : 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  onHighlightChanged: (value) {
                    setState(() => pressed = value);
                  },
                  child: Stack(
                    children: [
                      // Vagues fixes en bas de la carte.
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: compact ? 35 : 48,
                        child: CustomPaint(
                          painter: StatWavePainter(
                            color: color,
                            phase: 0,
                          ),
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          compact ? 9 : 14,
                          compact ? 10 : 15,
                          compact ? 9 : 14,
                          compact ? 19 : 23,
                        ),
                        child: compact
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _icon(color, compact),
                                  const SizedBox(height: 8),
                                  _number(),
                                  Text(
                                    widget.titre,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.grey,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  _icon(color, compact),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _number(),
                                        Text(
                                          widget.titre,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Icône avec cercle coloré.
  Widget _icon(Color color, bool compact) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: compact ? 40 : 49,
      height: compact ? 40 : 49,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(
              alpha: hovered ? 0.18 : 0,
            ),
            blurRadius: 13,
          ),
        ],
      ),
      child: Icon(
        widget.icone,
        color: color,
        size: compact ? 21 : 26,
      ),
    );
  }

  // Animation progressive des chiffres.
  Widget _number() {
    return TweenAnimationBuilder<double>(
      key: ValueKey(widget.valeur),
      tween: Tween(
        begin: 0,
        end: widget.valeur.toDouble(),
      ),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Text(
          value.toInt().toString(),
          style: TextStyle(
            fontSize: widget.compact ? 21 : 26,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        );
      },
    );
  }
}

// --------------------------------------------------
// PAINTER : VAGUES FIXES
// --------------------------------------------------

class StatWavePainter extends CustomPainter {
  final Color color;
  final double phase;

  StatWavePainter({
    required this.color,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    void drawWave({
      required double offset,
      required double height,
      required double opacity,
    }) {
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      final path = Path();

      double waveY(double x) {
        final normalized = x / size.width;

        return size.height * 0.38 +
            height *
                (0.5 +
                    0.5 *
                        math.sin(
                          normalized * 2 * math.pi * 1.5 +
                              phase +
                              offset,
                        ));
      }

      path.moveTo(0, waveY(0));

      for (double x = 0; x <= size.width; x += 2) {
        path.lineTo(x, waveY(x));
      }

      path
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();

      canvas.drawPath(path, paint);
    }

    // Première vague.
    drawWave(
      offset: 0,
      height: size.height * 0.28,
      opacity: 0.18,
    );

    // Deuxième vague.
    drawWave(
      offset: 2.2,
      height: size.height * 0.20,
      opacity: 0.30,
    );
  }

  @override
  bool shouldRepaint(covariant StatWavePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.phase != phase;
  }
}

// --------------------------------------------------
// LES TROIS CARTES STATISTIQUES
// --------------------------------------------------

class StatsRow extends StatelessWidget {
  final int total;
  final int actifs;
  final int inactifs;
  final bool compact;
  final ValueChanged<FiltreStatut> onSelect;

  const StatsRow({
    super.key,
    required this.total,
    required this.actifs,
    required this.inactifs,
    required this.compact,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        StatCard(
          titre: 'Total médecins',
          valeur: total,
          icone: Icons.groups_rounded,
          couleur: AppColors.blue,
          compact: compact,
          onTap: () => onSelect(FiltreStatut.tous),
        ),

        const SizedBox(width: 12),

        StatCard(
          titre: 'Actifs',
          valeur: actifs,
          icone: Icons.check_circle_rounded,
          couleur: AppColors.green,
          compact: compact,
          onTap: () => onSelect(FiltreStatut.actifs),
        ),

        const SizedBox(width: 12),

        StatCard(
          titre: 'Inactifs',
          valeur: inactifs,
          icone: Icons.pause_circle_rounded,
          couleur: AppColors.grey,
          compact: compact,
          onTap: () => onSelect(FiltreStatut.inactifs),
        ),
      ],
    );
  }
}
