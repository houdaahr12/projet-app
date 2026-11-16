import 'package:flutter/material.dart';
import 'brand.dart';
import 'home_page.dart';
import 'screens/alerts_page.dart';
import 'screens/alert_details_page.dart';
import 'screens/patients_page.dart';
import 'screens/patient_details_page.dart';
import 'screens/doctor_profile_page.dart';
import 'models/demo_data.dart';
import 'theme/colors.dart';

void main() => runApp(const SepsisCareApp());

class SepsisCareApp extends StatelessWidget {
  const SepsisCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: SepsisColors.canvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: SepsisColors.teal,
          primary: SepsisColors.teal,
          surface: Colors.white,
        ),
        fontFamily: 'Poppins',
        appBarTheme: const AppBarTheme(
          backgroundColor: SepsisColors.canvas,
          foregroundColor: SepsisColors.navy,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomePage(),
        '/alerts': (_) => const AlertsPage(),
        '/patients': (_) => const PatientsPage(),
        '/profile': (_) => const DoctorProfilePage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/patient-details') {
          final patient = settings.arguments as DemoPatient;
          return MaterialPageRoute(
            builder: (_) => PatientDetailsPage(patient: patient),
          );
        }
        if (settings.name == '/alert-details') {
          final patient = settings.arguments as DemoPatient;
          return MaterialPageRoute(
            builder: (_) => AlertDetailsPage(patient: patient),
          );
        }
        return null;
      },
    );
  }
}
