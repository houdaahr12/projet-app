import 'package:flutter/material.dart';

class LoginBackground extends StatelessWidget {
  const LoginBackground({super.key});

  static const _fallback = LinearGradient(
    colors: [Color(0xFF0B2545), Color(0xFF1976D2), Color(0xFF55A9E8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/Hospital.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const DecoratedBox(decoration: BoxDecoration(gradient: _fallback)),
        ),
        // Voile bleu par-dessus la photo
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF0B2545).withValues(alpha: 0.70),
                const Color(0xFF1976D2).withValues(alpha: 0.45),
                const Color(0xFF0B2545).withValues(alpha: 0.80),
              ],
            ),
          ),
        ),
      ],
    );
  }
}