import 'package:flutter/material.dart';

import '../main.dart';
import '../services/auth_service.dart';
import '../widgets/ui.dart';
import 'login_admin.dart';

/// Page d'accueil du médecin réanimateur (après connexion).
/// Les modules ci-dessous sont des emplacements : ils seront branchés
/// au fur et à mesure (patients, mesures, alertes).
class HomeMedecin extends StatelessWidget {
  const HomeMedecin({super.key, required this.nom, this.sexe});

  final String nom;
  final String? sexe; // 'M', 'F' ou null

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginAdmin()),
      (route) => false,
    );
  }

  Widget _accueil() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.blue, AppColors.skyBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: MedecinAvatar(sexe: sexe, nom: nom, size: 70),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bonjour,',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  nomAvecTitre(nom),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Médecin réanimateur',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tuile({
    required IconData icone,
    required String titre,
    required String texte,
    required double largeur,
  }) {
    return SizedBox(
      width: largeur,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE1EAF4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icone, color: AppColors.blue, size: 24),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF1F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Prochainement',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              titre,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              texte,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(8),
          child: DoctorAvatar(size: 36, ring: false),
        ),
        title: const Text(
          'SepsisCare',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.navy, AppColors.blue],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Déconnexion',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _accueil(),
                const SizedBox(height: 22),
                const Text(
                  'Vos outils',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final colonnes = constraints.maxWidth >= 640 ? 2 : 1;
                    const ecart = 14.0;
                    final largeur =
                        (constraints.maxWidth - (colonnes - 1) * ecart) /
                            colonnes;

                    return Wrap(
                      spacing: ecart,
                      runSpacing: ecart,
                      children: [
                        _tuile(
                          icone: Icons.groups_rounded,
                          titre: 'Mes patients',
                          texte:
                              'Liste des patients en réanimation, triés par niveau de risque.',
                          largeur: largeur,
                        ),
                        _tuile(
                          icone: Icons.edit_note_rounded,
                          titre: 'Saisie des mesures',
                          texte:
                              'Entrez les signes vitaux et les analyses de chaque heure.',
                          largeur: largeur,
                        ),
                        _tuile(
                          icone: Icons.notifications_active_outlined,
                          titre: 'Alertes sepsis',
                          texte:
                              "Alertes de risque avec les facteurs qui expliquent le score.",
                          largeur: largeur,
                        ),
                        _tuile(
                          icone: Icons.history_rounded,
                          titre: 'Historique',
                          texte:
                              "Alertes passées et évolution du risque de chaque patient.",
                          largeur: largeur,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}