import 'package:flutter/material.dart';

import '../brand.dart';
import '../services/auth_service.dart';
import '../theme/colors.dart';
import '../widgets/sepsis_bottom_nav.dart';

class DoctorProfilePage extends StatefulWidget {
  const DoctorProfilePage({super.key});

  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  String _nom = '';
  String? _sexe;
  String? _identifiant;
  String? _role;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final values = await Future.wait([
      AuthService.getUserName(),
      AuthService.getUserSexe(),
      AuthService.getIdentifiant(),
      AuthService.getRole(),
    ]);
    if (!mounted) return;
    setState(() {
      _nom = values[0] ?? '';
      _sexe = values[1];
      _identifiant = values[2];
      _role = values[3];
    });
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const SepsisCareBottomNav(currentIndex: 3),
    appBar: AppBar(title: const Text('Mon profil', style: TextStyle(fontWeight: FontWeight.w800))),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: SepsisColors.border),
        ),
        child: Column(children: [
          const CircleAvatar(radius: 37, backgroundColor: Color(0xFFE5F3F1),
            child: Icon(Icons.person_rounded, color: SepsisColors.teal, size: 39)),
          const SizedBox(height: 12),
          Text(_nom.isEmpty ? 'Nom non disponible' : _nom,
            textAlign: TextAlign.center,
            style: const TextStyle(color: SepsisColors.navy, fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(_role == 'admin' ? 'Administrateur' : 'Médecin',
            style: const TextStyle(color: SepsisColors.muted, fontSize: 12)),
        ]),
      ),
      const SizedBox(height: 17),
      _item(Icons.badge_outlined, 'Identifiant', _identifiant?.isNotEmpty == true ? _identifiant! : '—'),
      _item(Icons.wc_rounded, 'Sexe', _sexe == 'F' ? 'Femme' : _sexe == 'M' ? 'Homme' : '—'),
      _item(Icons.info_outline_rounded, 'À propos de SepsisCare', appSlogan),
      const SizedBox(height: 18),
      OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Se déconnecter'),
        style: OutlinedButton.styleFrom(foregroundColor: SepsisColors.navy, minimumSize: const Size.fromHeight(47)),
      ),
    ]),
  );

  Widget _item(IconData icon, String title, String value) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(14),
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
