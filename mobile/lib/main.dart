import 'package:flutter/material.dart';

import 'splash_page.dart';
import 'brand.dart';
import 'home_page.dart';
import 'screens/alerts_page.dart';
import 'screens/alert_details_page.dart';
import 'screens/patients_page.dart';
import 'screens/patient_details_page.dart';
import 'screens/doctor_profile_page.dart';
import 'models/demo_data.dart';
import 'theme/colors.dart';

import 'pages/gestion_medecins.dart';
import 'pages/home_medecin.dart';
import 'pages/login_admin.dart';
import 'services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SepsisCareApp());
}

class AppColors {
  static const navy = Color(0xFF12345A);
  static const blue = Color(0xFF1976D2);
  static const lightBlue = Color(0xFFE8F3FC);
  static const skyBlue = Color(0xFF58A9E8);
  static const background = Color(0xFFDCEBFF);
  static const backgroundColor = Color(0xFFDCEBFF);
  static const white = Colors.white;
  static const text = Color(0xFF20364D);
  static const grey = Color(0xFF8495A8);
  static const green = Color(0xFF16A879);
  static const red = Color(0xFFE45D68);
}

class SepsisCareApp extends StatelessWidget {
  const SepsisCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SepsisCare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.blue,
          primary: AppColors.blue,
          secondary: AppColors.skyBlue,
          surface: AppColors.white,
        ),
        fontFamily: 'Arial',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundColor,
          foregroundColor: AppColors.navy,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F8FC),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 17,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE3EBF3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
          ),
        ),
      ),
      home: const SplashPage(),
      routes: {
        '/home': (_) => const HomePage(userName: '',),
        '/alerts': (_) => const AlertsPage(),
        '/patients': (_) => const PatientsPage(),
        '/profile': (_) => const DoctorProfilePage(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/alert-details':
            final patient = settings.arguments as DemoPatient;
            return MaterialPageRoute(
              builder: (_) => AlertDetailsPage(patient: patient),
              settings: settings,
            );
          case '/patient-details':
            final patient = settings.arguments as DemoPatient;
            return MaterialPageRoute(
              builder: (_) => PatientDetailsPage(patient: patient),
              settings: settings,
            );
        }
        return null;
      },
    );
  }
}
/// Premier écran : regarde s'il y a une session enregistrée et ouvre la bonne
/// page selon le rôle (admin ou médecin), sinon la page de connexion.
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool loading = true;
  String? role; // 'admin', 'medecin' ou null (non connecté)
  String nom = '';
  String? sexe;

  @override
  void initState() {
    super.initState();
    checkSession();
  }

  Future<void> checkSession() async {
    try {
      final token = await AuthService.getToken();
      final roleSauvegarde = await AuthService.getRole();
      final nomSauvegarde = await AuthService.getUserName();
      final sexeSauvegarde = await AuthService.getUserSexe();

      final aUnToken = token != null && token.isNotEmpty;
      final roleValide = roleSauvegarde == 'admin' || roleSauvegarde == 'medecin';

      // Ancienne session sans rôle enregistré : on la ferme proprement.
      if (aUnToken && !roleValide) {
        await AuthService.logout();
      }

      if (!mounted) return;

      setState(() {
        role = (aUnToken && roleValide) ? roleSauvegarde : null;
        nom = nomSauvegarde ?? '';
        sexe = (sexeSauvegarde == null || sexeSauvegarde.isEmpty)
            ? null
            : sexeSauvegarde;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        role = null;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.blue),
        ),
      );
    }

    if (role == 'admin') return const GestionMedecins();

    if (role == 'medecin') return HomePage(userName: '',);

    return const LoginAdmin();
  }
}