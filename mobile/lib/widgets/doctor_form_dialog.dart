import 'package:flutter/material.dart';

import '../main.dart';
import '../services/doctor_service.dart';
import 'ui.dart';

// FORMULAIRE AJOUT / MODIFICATION D'UN MÉDECIN

class DoctorFormDialog extends StatefulWidget {
  final Doctor? doctor;

  const DoctorFormDialog({super.key, this.doctor});

  @override
  State<DoctorFormDialog> createState() => _DoctorFormDialogState();
}

class _DoctorFormDialogState extends State<DoctorFormDialog> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController nomController;
  late final TextEditingController identifiantController;
  late final TextEditingController emailController;
  late final TextEditingController serviceController;

  final passwordController = TextEditingController();

  bool loading = false;
  bool actif = true;
  bool obscurePassword = true;

  String? sexe; // 'M' ou 'F'
  bool sexeErreur = false;

  bool get isEditing => widget.doctor != null;

  @override
  void initState() {
    super.initState();

    final doctor = widget.doctor;

    nomController = TextEditingController(text: doctor?.nom ?? '');
    identifiantController = TextEditingController(
      text: doctor?.identifiant ?? '',
    );
    emailController = TextEditingController(text: doctor?.email ?? '');
    serviceController = TextEditingController(text: doctor?.service ?? '');

    actif = doctor?.actif ?? true;
    sexe = doctor?.sexe;
  }

  @override
  void dispose() {
    nomController.dispose();
    identifiantController.dispose();
    emailController.dispose();
    serviceController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> saveDoctor() async {
    final formulaireValide = formKey.currentState!.validate();

    if (!isEditing && sexe == null) {
      setState(() => sexeErreur = true);
      return;
    }

    if (!formulaireValide) return;

    setState(() => loading = true);

    try {
      if (isEditing) {
        await DoctorService.updateDoctor(
          id: widget.doctor!.id,
          nom: nomController.text.trim(),
          identifiant: identifiantController.text.trim(),
          email: emailController.text.trim(),
          service: serviceController.text.trim(),
          motDePasse: passwordController.text,
          actif: actif,
          sexe: sexe,
        );
      } else {
        await DoctorService.addDoctor(
          nom: nomController.text.trim(),
          identifiant: identifiantController.text.trim(),
          email: emailController.text.trim(),
          service: serviceController.text.trim(),
          motDePasse: passwordController.text,
          sexe: sexe!,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.navy,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Widget champ({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool password = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: password && obscurePassword,
        keyboardType: keyboardType,
        decoration: fieldDecoration(
          label,
          icon,
          suffix: password
              ? IconButton(
                  onPressed: () {
                    setState(() => obscurePassword = !obscurePassword);
                  },
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.grey,
                  ),
                )
              : null,
        ),
        validator: validator,
      ),
    );
  }

  Widget tuileSexe(String valeur, String label) {
    final selectionne = sexe == valeur;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: loading
            ? null
            : () => setState(() {
                  sexe = valeur;
                  sexeErreur = false;
                }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: selectionne ? AppColors.lightBlue : const Color(0xFFF5F9FD),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selectionne
                  ? AppColors.blue
                  : (sexeErreur ? AppColors.red : const Color(0xFFDCE7F3)),
              width: selectionne ? 1.8 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MedecinAvatar(sexe: valeur, nom: '', size: 34),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selectionne ? AppColors.blue : AppColors.navy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget choixSexe() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sexe',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              tuileSexe('M', 'Homme'),
              const SizedBox(width: 10),
              tuileSexe('F', 'Femme'),
            ],
          ),
          if (sexeErreur)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Choisissez le sexe du médecin',
                style: TextStyle(color: AppColors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget entete() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 10, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy, AppColors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isEditing ? Icons.edit_outlined : Icons.person_add_alt_1_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Modifier le médecin' : 'Nouveau médecin',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Renseignez les informations du compte',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Fermer',
            onPressed: loading ? null : () => Navigator.pop(context, false),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            entete(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      champ(
                        label: 'Nom complet',
                        controller: nomController,
                        icon: Icons.person_outline,
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return 'Le nom est obligatoire';
                          if (text.length < 2) return 'Minimum 2 caractères';
                          return null;
                        },
                      ),
                      choixSexe(),
                      champ(
                        label: 'Identifiant',
                        controller: identifiantController,
                        icon: Icons.badge_outlined,
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) {
                            return "L'identifiant est obligatoire";
                          }
                          if (text.length < 3) return 'Minimum 3 caractères';
                          return null;
                        },
                      ),
                      champ(
                        label: 'Adresse email (facultatif)',
                        controller: emailController,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isNotEmpty &&
                              !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(text)) {
                            return 'Adresse email invalide';
                          }
                          return null;
                        },
                      ),
                      champ(
                        label: 'Service médical (facultatif)',
                        controller: serviceController,
                        icon: Icons.local_hospital_outlined,
                      ),
                      champ(
                        label: isEditing
                            ? 'Nouveau mot de passe (facultatif)'
                            : 'Mot de passe',
                        controller: passwordController,
                        icon: Icons.lock_outline,
                        password: true,
                        validator: (value) {
                          final text = value ?? '';
                          if (!isEditing && text.isEmpty) {
                            return 'Le mot de passe est obligatoire';
                          }
                          if (text.isNotEmpty && text.length < 8) {
                            return 'Minimum 8 caractères';
                          }
                          return null;
                        },
                      ),
                      if (isEditing)
                        Container(
                          margin: const EdgeInsets.only(bottom: 18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F9FD),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFDCE7F3)),
                          ),
                          child: SwitchListTile(
                            activeThumbColor: AppColors.blue,
                            title: const Text(
                              'Compte actif',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.navy,
                              ),
                            ),
                            subtitle: const Text(
                              "Autoriser l'accès au compte médecin",
                              style: TextStyle(fontSize: 12),
                            ),
                            value: actif,
                            onChanged: loading
                                ? null
                                : (value) => setState(() => actif = value),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: loading
                                  ? null
                                  : () => Navigator.pop(context, false),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                foregroundColor: AppColors.navy,
                                side: const BorderSide(
                                  color: Color(0xFFDCE7F3),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Annuler'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: loading ? null : saveDoctor,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.blue,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(isEditing ? 'Enregistrer' : 'Ajouter'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}