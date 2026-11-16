import 'package:flutter/material.dart';
import '../brand.dart';
import '../theme/colors.dart';
import '../widgets/sepsis_bottom_nav.dart';

class DoctorProfilePage extends StatelessWidget {
  const DoctorProfilePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const SepsisCareBottomNav(currentIndex: 3),
    appBar: AppBar(title: const Text('Mon profil', style: TextStyle(fontWeight: FontWeight.w800))),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: SepsisColors.border)),
        child: Column(children: [
          const CircleAvatar(radius: 37, backgroundColor: Color(0xFFE5F3F1),
            child: Icon(Icons.person_rounded, color: SepsisColors.teal, size: 39)),
          const SizedBox(height: 12),
          const Text(demoDoctorName, style: TextStyle(color: SepsisColors.navy, fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text(demoDoctorRole, style: TextStyle(color: SepsisColors.muted, fontSize: 12)),
          const SizedBox(height: 14),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: SepsisColors.lowSoft, borderRadius: BorderRadius.circular(20)),
            child: const Text('Compte de démonstration', style: TextStyle(color: SepsisColors.low, fontSize: 10, fontWeight: FontWeight.w800))),
        ]),
      ),
      const SizedBox(height: 17),
      _item(Icons.local_hospital_outlined, 'Service', 'Réanimation'),
      _item(Icons.badge_outlined, 'Fonction', 'Médecin réanimateur'),
      _item(Icons.shield_outlined, 'Confidentialité', 'Données de démonstration'),
      _item(Icons.info_outline_rounded, 'À propos de SepsisCare', appSlogan),
      const SizedBox(height: 18),
      OutlinedButton.icon(
        onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Retour à l’accueil'),
        style: OutlinedButton.styleFrom(foregroundColor: SepsisColors.navy, minimumSize: const Size.fromHeight(47)),
      ),
    ]),
  );

  Widget _item(IconData icon, String title, String value) => Container(
    margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: SepsisColors.border)),
    child: Row(children: [
      Icon(icon, color: SepsisColors.teal),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: SepsisColors.muted, fontSize: 10)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(color: SepsisColors.navy, fontSize: 12, fontWeight: FontWeight.w700)),
      ])),
    ]),
  );
}
