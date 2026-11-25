import 'package:flutter/material.dart';

import 'home_page.dart';
import 'pages/gestion_medecins.dart';
import 'pages/login_admin.dart';
import 'screens/alert_details_page.dart';
import 'screens/alerts_page.dart';
import 'screens/doctor_profile_page.dart';
import 'screens/patient_details_page.dart';
import 'screens/patients_page.dart';
import 'splash_page.dart';
import 'theme/colors.dart';
import 'services/auth_service.dart';
import 'models/patient.dart';
import 'models/patient_alert.dart';

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
        scaffoldBackgroundColor: SepsisColors.canvas,
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
      ),
      home: const StartupGate(),
      routes: {
        '/splash': (_) => const SplashPage(),
        '/home': (_) => const HomePage(),
        '/alerts': (_) => const AlertsPage(),
        '/patients': (_) => const PatientsPage(),
        '/profile': (_) => const DoctorProfilePage(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/alert-details':
            final alert = settings.arguments as PatientAlert;
            return MaterialPageRoute(
              builder: (_) => AlertDetailsPage(alert: alert),
              settings: settings,
            );
          case '/patient-details':
            final patient = settings.arguments as PatientRecord;
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

/// Routes an existing session to the correct workspace.
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool loading = true;
  String? role;
  String nom = '';

  @override
  void initState() {
    super.initState();
    checkSession();
  }

  Future<void> checkSession() async {
    try {
      final values = await Future.wait([
        AuthService.getToken(),
        AuthService.getRole(),
        AuthService.getUserName(),
      ]);
      final token = values[0];
      final savedRole = values[1];
      final savedName = values[2];
      final hasToken = token != null && token.isNotEmpty;
      final validRole = savedRole == 'admin' || savedRole == 'medecin';

      if (hasToken && !validRole) await AuthService.logout();
      if (!mounted) return;
      setState(() {
        role = hasToken && validRole ? savedRole : null;
        nom = savedName ?? '';
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
        body: Center(child: CircularProgressIndicator(color: AppColors.blue)),
      );
    }
    if (role == 'admin') return const GestionMedecins();
    if (role == 'medecin') return HomePage(userName: nom);
    return const LoginAdmin();
  }
}

class StartupGate extends StatelessWidget {
  const StartupGate({super.key});

  @override
  Widget build(BuildContext context) {
    return SplashPage.alreadyShown ? const AppEntry() : const SplashPage();
  }
}
