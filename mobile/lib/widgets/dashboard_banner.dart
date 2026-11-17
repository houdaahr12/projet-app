
import 'package:flutter/material.dart';

import '../main.dart';

class DashboardBanner extends StatefulWidget {
  final bool compact;
  final VoidCallback onShowList;

  const DashboardBanner({
    super.key,
    required this.compact,
    required this.onShowList,
  });

  @override
  State<DashboardBanner> createState() => _DashboardBannerState();
}

class _DashboardBannerState extends State<DashboardBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> fade;
  late final Animation<Offset> slide;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    fade = CurvedAnimation(parent: controller, curve: Curves.easeOut);
    slide = Tween<Offset>(
      begin: const Offset(-0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    ));

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: widget.compact ? 190 : 160,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/Stethoscope.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.blue,
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: Colors.white24,
                  size: 100,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.navy.withValues(alpha: 0.95),
                    AppColors.blue.withValues(alpha: 0.76),
                    AppColors.blue.withValues(alpha: 0.12),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Positioned(
              right: -15,
              bottom: -35,
              child: Icon(
                Icons.health_and_safety_rounded,
                size: 160,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: slide,
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Tableau de bord',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Gestion des médecins-réanimateurs',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                      if (widget.compact) ...[
                        const SizedBox(height: 14),
                        _button(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (!widget.compact)
              Positioned(
                right: 18,
                bottom: 18,
                child: _button(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _button() {
    return FilledButton.icon(
      onPressed: widget.onShowList,
      icon: const Icon(Icons.groups_rounded, size: 17),
      label: const Text('Liste des médecins'),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.blue,
        elevation: 3,
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
