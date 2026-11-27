import 'package:flutter/material.dart';
import 'package:mobile/medecin/pages/home_page.dart';

import 'package:mobile/core/services/biometric_service.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/auth/widgets/login_background.dart';
import 'package:mobile/auth/widgets/login_form.dart';
import 'package:mobile/admin/pages/gestion_medecins.dart';

class LoginAdmin extends StatefulWidget {
  const LoginAdmin({super.key});

  @override
  State<LoginAdmin> createState() => _LoginAdminState();
}

class _LoginAdminState extends State<LoginAdmin>
    with SingleTickerProviderStateMixin {
  final identifiantController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;

  bool obscurePassword = true;
  bool loading = false;
  bool bioReady = false; // fingerprint available AND enabled
  String? erreur;

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    fadeAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    );

    slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(
            parent: animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    animationController.forward();
    _checkBiometric();
  }

  @override
  void dispose() {
    animationController.dispose();
    identifiantController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ---------- Logique ----------

  /// Decides whether the "Utiliser l'empreinte" button is shown.
  Future<void> _checkBiometric() async {
    try {
      final bio = BiometricService();
      final ready = await bio.isAvailable() && await bio.isEnabled();
      if (!mounted) return;
      setState(() => bioReady = ready);
    } catch (_) {
      // Chrome or no sensor: no button
    }
  }

  /// Opens the right page depending on the role.
  void _ouvrirSelonRole(String? role, String name) {
    if (role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GestionMedecins()),
      );
    } else if (role == 'medecin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage(userName: name)),
      );
    } else {
      setState(() {
        erreur = "Ce compte n'a pas accès à l'application.";
      });
    }
  }

  /// After a successful login: offer to enable the fingerprint,
  /// or refresh the saved credentials if it is already enabled.
  Future<void> _proposerEmpreinte(String identifiant, String motDePasse) async {
    try {
      final bio = BiometricService();

      if (!await bio.isAvailable())
        return; // no sensor / no fingerprint enrolled

      if (await bio.isEnabled()) {
        await bio.enable(identifiant: identifiant, motDePasse: motDePasse);
        return;
      }

      if (!mounted) return;

      final wantsBiometric = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Activer l'empreinte ?"),
          content: const Text(
            'Connectez-vous plus vite la prochaine fois avec votre empreinte.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Plus tard'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Activer'),
            ),
          ],
        ),
      );

      if (wantsBiometric == true && await bio.authenticate()) {
        await bio.enable(identifiant: identifiant, motDePasse: motDePasse);
      }
    } catch (_) {
      // The fingerprint must never block a normal login
    }
  }

  Future<void> handleLogin() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      erreur = null;
    });

    try {
      final identifiant = identifiantController.text.trim();
      final motDePasse = passwordController.text;

      final user = await AuthService.login(identifiant, motDePasse);

      final role = user['role'] as String?;
      final name = (user['nom'] ?? '') as String;

      await _proposerEmpreinte(identifiant, motDePasse);

      if (!mounted) return;
      _ouvrirSelonRole(role, name);
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      setState(() {
        if (message.toLowerCase().contains('incorrect')) {
          erreur = "Identifiant ou mot de passe incorrect. Si vous n'avez pas encore de compte, il doit d'abord être créé par un administrateur.";
        } else {
          erreur = message;
        }
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  /// Manual fingerprint login (button on the form).
  Future<void> handleBiometricLogin() async {
    final bio = BiometricService();

    setState(() {
      loading = true;
      erreur = null;
    });

    try {
      if (!await bio.authenticate()) return; // cancelled or failed

      final creds = await bio.readCredentials();
      if (creds == null) {
        setState(() {
          erreur = "Aucune empreinte enregistrée. Connectez-vous avec votre mot de passe.";
        });
        return;
      }

      // Silent login: fresh token, role and name are saved again
      final user = await AuthService.login(
        creds['identifiant']!,
        creds['mot_de_passe']!,
      );

      if (!mounted) return;
      _ouvrirSelonRole(user['role'] as String?, (user['nom'] ?? '') as String);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        erreur = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  // ---------- Affichage ----------

  Widget loginForm() {
    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: LoginForm(
          formKey: formKey,
          identifiantController: identifiantController,
          passwordController: passwordController,
          obscurePassword: obscurePassword,
          loading: loading,
          erreur: erreur,
          onToggleObscure: () {
            setState(() => obscurePassword = !obscurePassword);
          },
          onSubmit: handleLogin,
          onBiometricLogin: bioReady ? handleBiometricLogin : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const LoginBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: loginForm(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
