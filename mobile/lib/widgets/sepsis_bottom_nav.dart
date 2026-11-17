import 'package:flutter/material.dart';
import '../theme/colors.dart';

class SepsisCareBottomNav extends StatelessWidget {
  const SepsisCareBottomNav({super.key, required this.currentIndex});
  final int currentIndex;

  void _go(BuildContext context, int index) {
    const routes = ['/', '/alerts', '/patients', '/profile'];
    if (index == currentIndex) return;
    Navigator.pushNamedAndRemoveUntil(context, routes[index], (route) => false);
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: SepsisColors.border)),
    ),
    child: SafeArea(
      top: false,
      child: NavigationBar(
        height: 66,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE5F3F1),
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => _go(context, i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view_rounded), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.notifications_none_rounded), selectedIcon: Icon(Icons.notifications_rounded), label: 'Alertes'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups_rounded), label: 'Patients'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profil'),
        ],
      ),
    ),
  );
}
