
import 'package:flutter/material.dart';

import '../main.dart';
import '../services/doctor_service.dart';
import 'ui.dart';

class DoctorCard extends StatefulWidget {
  final Doctor doctor;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;
  final VoidCallback onReactivate;

  const DoctorCard({
    super.key,
    required this.doctor,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
  });

  @override
  State<DoctorCard> createState() => _DoctorCardState();
}

class _DoctorCardState extends State<DoctorCard> {
  bool hovered = false;

  Widget _pastilleStatut(bool actif) {
    final color = actif ? AppColors.green : AppColors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: color),
          const SizedBox(width: 5),
          Text(
            actif ? 'Actif' : 'Inactif',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: _AnimatedDoctorButton(
        label: label,
        icon: icon,
        color: color,
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctor = widget.doctor;

    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedScale(
        scale: hovered ? 1.025 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: hovered ? const Color(0xFFF5FAFF) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hovered
                  ? AppColors.skyBlue.withValues(alpha: 0.65)
                  : const Color(0xFFE1EAF4),
              width: hovered ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.blue.withValues(
                  alpha: hovered ? 0.13 : 0.055,
                ),
                blurRadius: hovered ? 22 : 12,
                offset: Offset(0, hovered ? 9 : 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: Stack(
              children: [
                // Vagues décoratives au bas de la carte.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 48,
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: DoctorWavePainter(
                        color: AppColors.skyBlue.withValues(
                          alpha: hovered ? 0.24 : 0.15,
                        ),
                      ),
                    ),
                  ),
                ),

                // Contenu de la carte.
                Padding(
                  padding: const EdgeInsets.fromLTRB(13, 11, 13, 13),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            Icons.more_vert,
                            color: AppColors.grey.withValues(alpha: 0.8),
                            size: 19,
                          ),
                          _pastilleStatut(doctor.actif),
                        ],
                      ),

                      const SizedBox(height: 1),

                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hovered
                              ? AppColors.skyBlue.withValues(alpha: 0.18)
                              : AppColors.lightBlue,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.blue.withValues(
                                alpha: hovered ? 0.18 : 0.07,
                              ),
                              blurRadius: hovered ? 15 : 7,
                            ),
                          ],
                        ),
                        child: MedecinAvatar(
                          sexe: doctor.sexe,
                          nom: doctor.nom,
                          size: 72,
                        ),
                      ),

                      const SizedBox(height: 9),

                      Text(
                        nomAvecTitre(doctor.nom),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        '@${doctor.identifiant}',
                        style: const TextStyle(
                          color: AppColors.skyBlue,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 9),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.medical_services_outlined,
                            color: AppColors.blue,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              doctor.service?.isNotEmpty == true
                                  ? doctor.service!
                                  : 'Médecin Réanimateur',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          _actionButton(
                            label: 'Modifier',
                            icon: Icons.edit_rounded,
                            color: AppColors.blue,
                            onTap: widget.onEdit,
                          ),
                          const SizedBox(width: 8),
                          _actionButton(
                            label: doctor.actif ? 'Désactiver' : 'Activer',
                            icon: doctor.actif
                                ? Icons.delete_outline_rounded
                                : Icons.check_circle_outline_rounded,
                            color: doctor.actif
                                ? AppColors.red
                                : AppColors.green,
                            onTap: doctor.actif
                                ? widget.onDeactivate
                                : widget.onReactivate,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Bouton avec animation au clic.
class _AnimatedDoctorButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AnimatedDoctorButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_AnimatedDoctorButton> createState() =>
      _AnimatedDoctorButtonState();
}

class _AnimatedDoctorButtonState extends State<_AnimatedDoctorButton> {
  bool pressed = false;
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = pressed || hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedScale(
        scale: pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 120),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onHighlightChanged: (value) {
              setState(() => pressed = value);
            },
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: active
                    ? widget.color.withValues(alpha: 0.15)
                    : widget.color.withValues(alpha: 0.045),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: widget.color.withValues(
                    alpha: active ? 0.8 : 0.35,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, size: 14, color: widget.color),
                  const SizedBox(width: 4),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: widget.color,
                        ),
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
}

// Dessin des vagues au bas de chaque carte.
class DoctorWavePainter extends CustomPainter {
  final Color color;

  DoctorWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 19)
      ..cubicTo(
        size.width * 0.20, -4,
        size.width * 0.30, 39,
        size.width * 0.52, 19,
      )
      ..cubicTo(
        size.width * 0.72, 0,
        size.width * 0.82, 38,
        size.width, 15,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant DoctorWavePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
