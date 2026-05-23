import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const SentinelApp(),
    ),
  );
}

class SentinelApp extends StatelessWidget {
  const SentinelApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Custom premium cyber-grid dark theme
    final themeData = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A0F1D),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00E5FF),     // Cyber Cyan
        secondary: Color(0xFF00E676),   // Cyber Green
        error: Color(0xFFFF3D00),       // Alert Red
        background: Color(0xFF0A0F1D),
        surface: Color(0xFF141C33),      // Dark Blue Card
        onPrimary: Color(0xFF0A0F1D),
        onSecondary: Color(0xFF0A0F1D),
        onSurface: Color(0xFFE2E8F0),
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.w700, letterSpacing: 1.5, color: Colors.white),
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w600, letterSpacing: 0.8, color: const Color(0xFF00E5FF)),
        bodyLarge: GoogleFonts.outfit(letterSpacing: 0.2, color: const Color(0xFFE2E8F0)),
        labelLarge: GoogleFonts.outfit(fontWeight: FontWeight.w500, letterSpacing: 1.0, color: const Color(0xFF00E5FF)),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF141C33),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1E294B), width: 1.5),
        ),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111726),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E294B), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E294B), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 2.0),
        ),
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        floatingLabelStyle: const TextStyle(color: Color(0xFF00E5FF)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00E5FF),
          foregroundColor: const Color(0xFF0A0F1D),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 0.8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 0,
        ),
      ),
    );

    return MaterialApp(
      title: 'NHAI Sentinel Biometric',
      theme: themeData,
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
