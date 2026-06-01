import 'package:flutter/material.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
const kBackground  = Color(0xFF0B0F19);
const kSurface     = Color(0xFF131929);
const kCard        = Color(0xFF1A2235);
const kAccent      = Color(0xFF10B981); // emerald green
const kIndigo      = Color(0xFF6366F1);
const kTextPrimary = Color(0xFFEEF2FF);
const kTextMuted   = Color(0xFF8892A4);
const kError       = Color(0xFFEF4444);
const kWarning     = Color(0xFFF59E0B);

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBackground,
        colorScheme: const ColorScheme.dark(
          surface: kSurface,
          primary: kAccent,
          secondary: kIndigo,
          error: kError,
          onPrimary: kBackground,
          onSecondary: kTextPrimary,
          onSurface: kTextPrimary,
        ),
        cardTheme: const CardThemeData(
          color: kCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kCard,
          labelStyle: const TextStyle(color: kTextMuted),
          hintStyle: const TextStyle(color: kTextMuted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kIndigo, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: kIndigo.withValues(alpha: 0.4), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kAccent, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kAccent,
            foregroundColor: kBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: kAccent),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kBackground,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: kTextPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          iconTheme: IconThemeData(color: kTextPrimary),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: kSurface,
          selectedItemColor: kAccent,
          unselectedItemColor: kTextMuted,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w800),
          headlineMedium: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w700),
          titleLarge: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: kTextPrimary),
          bodyMedium: TextStyle(color: kTextMuted),
          labelLarge: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600),
        ),
      );
}