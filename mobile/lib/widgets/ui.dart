import 'package:flutter/material.dart';

import '../main.dart';

/// Initiales d'un nom (ignore « Dr » et « Dr. »).
String initialesDe(String nom) {
  final mots = nom
      .trim()
      .split(RegExp(r'\s+'))
      .where(
        (m) =>
            m.isNotEmpty &&
            m.toLowerCase() != 'dr' &&
            m.toLowerCase() != 'dr.',
      )
      .toList();

  if (mots.isEmpty) return 'M';
  if (mots.length == 1) return mots[0][0].toUpperCase();
  return (mots[0][0] + mots[1][0]).toUpperCase();
}

/// Affiche « Dr. Nom » sans doubler le préfixe s'il existe déjà.
String nomAvecTitre(String nom) {
  final n = nom.trim();
  if (n.toLowerCase().startsWith('dr')) return n;
  return 'Dr. $n';
}

/// Avatar du médecin pour la page de connexion (assets/images/doctor_avatar.png).
class DoctorAvatar extends StatelessWidget {
  const DoctorAvatar({super.key, this.size = 120, this.ring = true});

  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final image = ClipOval(
      child: Image.asset(
        'assets/images/doctor_avatar.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: AppColors.lightBlue,
          child: Icon(
            Icons.medical_services_rounded,
            size: size * 0.5,
            color: AppColors.blue,
          ),
        ),
      ),
    );

    if (!ring) return image;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: image,
    );
  }
}

/// Avatar d'un médecin selon son sexe : 'M' = garçon, 'F' = fille.
/// Si le sexe n'est pas renseigné, les initiales s'affichent.
class MedecinAvatar extends StatelessWidget {
  const MedecinAvatar({
    super.key,
    required this.sexe,
    required this.nom,
    this.size = 72,
  });

  final String? sexe;
  final String nom;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.lightBlue,
        shape: BoxShape.circle,
      ),
      child: Text(
        initialesDe(nom),
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.bold,
          color: AppColors.blue,
        ),
      ),
    );

    String? asset;
    if (sexe == 'M') asset = 'assets/images/avatar_homme.png';
    if (sexe == 'F') asset = 'assets/images/avatar_femme.png';

    if (asset == null) return fallback;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.lightBlue, width: 2),
      ),
      child: ClipOval(
        child: Image.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        ),
      ),
    );
  }
}

/// Style commun des champs de saisie (bleu et blanc).
InputDecoration fieldDecoration(
  String label,
  IconData icon, {
  String? hint,
  Widget? suffix,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon, color: AppColors.blue, size: 21),
    suffixIcon: suffix,
    filled: true,
    fillColor: const Color(0xFFF5F9FD),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border(const Color(0xFFDCE7F3)),
    enabledBorder: border(const Color(0xFFDCE7F3)),
    focusedBorder: border(AppColors.blue, 1.6),
    errorBorder: border(AppColors.red),
    focusedErrorBorder: border(AppColors.red, 1.6),
  );
}