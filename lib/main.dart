import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/auth_service.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/camera_scan_screen.dart';
import 'ui/screens/registration_screen.dart';
import 'ui/screens/audit_dashboard_screen.dart';
import 'ui/screens/offline_sync_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set orientation to portrait only for mobile biometric scanning consistency
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Lock status bar color and dark overlay
  SystemChrome.setSystemUIOverlayStyle(const SystemOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0F1D),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

      runApp(
      ProviderScope(
        child: const SentinelApp(),
      ),
    );
}

class SentinelApp extends StatelessWidget {
  const SentinelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NHAI Sentinel Biometric',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/camera_scan': (context) => const CameraScanScreen(),
        '/registration': (context) => const RegistrationScreen(),
        '/audit_dashboard': (context) => const AuditDashboardScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
