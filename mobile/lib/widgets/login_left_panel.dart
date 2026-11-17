import 'package:flutter/material.dart';

import 'ui.dart';

const loginGradient = LinearGradient(
  colors: [Color(0xFF12345A), Color(0xFF1976D2), Color(0xFF55A9E8)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class LoginLeftPanel extends StatelessWidget {
  const LoginLeftPanel({super.key});

  Widget _circle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _feature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 19),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: loginGradient),
      child: Stack(
        children: [
          Positioned(top: -90, right: -90, child: _circle(260)),
          Positioned(bottom: -110, left: -70, child: _circle(280)),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(35),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const DoctorAvatar(size: 210),
                  const SizedBox(height: 28),
                  const Text(
                    'SepsisCare',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Détection précoce du sepsis\npour les équipes de réanimation.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _feature(Icons.verified_user_outlined, 'Accès sécurisé'),
                  _feature(Icons.groups_outlined, 'Gestion des médecins'),
                  _feature(Icons.monitor_heart_outlined, 'Suivi des alertes'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}