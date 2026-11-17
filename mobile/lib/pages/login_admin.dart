
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/login_background.dart';
import '../widgets/login_form.dart';
import 'gestion_medecins.dart';
import 'home_medecin.dart';

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

    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    animationController.forward();
  }

  @override
  void dispose() {
    animationController.dispose();
    identifiantController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ---------- Logique ----------

  Future<void> handleLogin() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      erreur = null;
    });

    try {
      // AuthService.login doit renvoyer la map "user" du serveur
      // (id, nom, identifiant, role, sexe).
      final user = await AuthService.login(
        identifiantController.text.trim(),
        passwordController.text,
      );

      if (!mounted) return;

      final role = user['role'];

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const GestionMedecins(),
          ),
        );
      } else if (role == 'medecin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeMedecin(
              nom: user['nom']?.toString() ?? '',
              sexe: user['sexe']?.toString(),
            ),
          ),
        );
      } else {
        setState(
          () => erreur = "Ce compte n'a pas accès à l'application.",
        );
      }
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      setState(() {
        if (message.toLowerCase().contains('incorrect')) {
          erreur =
              "Identifiant ou mot de passe incorrect. Si vous n'avez pas encore de compte, il doit d'abord être créé par un administrateur.";
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
