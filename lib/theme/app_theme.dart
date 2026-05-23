// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0A0F1D),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00E5FF), // Cyber Cyan
      secondary: Color(0xFF00E676), // Cyber Green
      error: Color(0xFFFF3D00), // Alert Red
      background: Color(0xFF0A0F1D),
      surface: Color(0xFF141C33),
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
    cardTheme: const CardTheme(
      color: Color(0xFF141C33),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: Color(0xFF1E294B), width: 1.5),
      ),
      elevation: 0,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF111726),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFF1E294B), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFF1E294B), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFF00E5FF), width: 2.0),
      ),
      labelStyle: TextStyle(color: Color(0xFF94A3B8)),
      floatingLabelStyle: TextStyle(color: Color(0xFF00E5FF)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF00E5FF),
        foregroundColor: Color(0xFF0A0F1D),
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        elevation: 0,
      ),
    ),
  );

  // Light theme can be added similarly if needed
}
