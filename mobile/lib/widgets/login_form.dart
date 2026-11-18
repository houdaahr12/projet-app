import 'dart:ui';

import 'package:flutter/material.dart';

import 'ui.dart';

class LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController identifiantController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool loading;
  final String? erreur;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

    final VoidCallback? onBiometricLogin;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.identifiantController,
    required this.passwordController,
    required this.obscurePassword,
    required this.loading,
    required this.erreur,
    required this.onToggleObscure,
    required this.onSubmit,
    this.onBiometricLogin,
  });

  static const _erreurClaire = Color(0xFFFFB4B4);

  InputDecoration _decoration(String hint, IconData icon, {Widget? suffix}) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: c, width: w),
        );

    final normal = border(Colors.white.withValues(alpha: 0.22));

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
      prefixIcon: Icon(icon, color: Colors.white70),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.14),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      border: normal,
      enabledBorder: normal,
      focusedBorder: border(Colors.white, 1.5),
      errorBorder: border(_erreurClaire),
      focusedErrorBorder: border(_erreurClaire, 1.5),
      errorStyle: const TextStyle(color: _erreurClaire),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          // Effet verre dépoli : floute la photo derrière la carte
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DoctorAvatar(size: 84),
                  const SizedBox(height: 14),
                  const Text(
                    'Bienvenue',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'SepsisCare · Accès sécurisé',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 26),
                  TextFormField(
                    controller: identifiantController,
                    textInputAction: TextInputAction.next,
                    cursorColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    decoration: _decoration('Identifiant', Icons.person_outline),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Saisissez votre identifiant';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    cursorColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    decoration: _decoration(
                      'Mot de passe',
                      Icons.lock_outline,
                      suffix: IconButton(
                        tooltip: obscurePassword
                            ? 'Afficher le mot de passe'
                            : 'Masquer le mot de passe',
                        onPressed: onToggleObscure,
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    onFieldSubmitted: (_) => onSubmit(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Saisissez votre mot de passe';
                      }
                      return null;
                    },
                  ),
                  if (erreur != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB3261E).withValues(alpha: 0.30),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _erreurClaire.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              erreur!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Bouton en dégradé bleu
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1976D2).withValues(alpha: 0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: loading ? null : onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white70,
                        minimumSize: const Size.fromHeight(54),
                        shape: const StadiumBorder(),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'SE CONNECTER',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                    ),
                                 ),

                  if (onBiometricLogin != null) ...[
                    const SizedBox(height: 14),
                    TextButton.icon(
                      onPressed: loading ? null : onBiometricLogin,
                      icon: const Icon(
                        Icons.fingerprint,
                        color: Colors.white,
                        size: 28,
                      ),
                      label: const Text(
                        "Utiliser l'empreinte",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                  

                  // 👆 END FINGERPRINT BUTTON
                  const SizedBox(height: 20),

                  Text(
                    "Compte créé par l'administrateur de votre service",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.white.withValues(alpha: 0.75),
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