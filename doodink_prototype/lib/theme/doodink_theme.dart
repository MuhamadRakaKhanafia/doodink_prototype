import 'package:flutter/material.dart';

class DoodinkTheme {
  static const Color purple = Color(0xFF7C3AED);
  static const Color pink = Color(0xFFEC4899);
  static const Color sky = Color(0xFF38BDF8);
  static const Color yellow = Color(0xFFFACC15);

  static ThemeData get theme {
    final base = ThemeData.from(colorScheme: const ColorScheme.dark());
    return base.copyWith(
      colorScheme: const ColorScheme.dark(

        primary: purple,
        secondary: pink,
        surface: Color(0xFF111827),
      ),
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: base.textTheme.copyWith(
        displayLarge: const TextStyle(
          fontSize: 42,
          height: 1.1,
          color: Colors.white,
        ),
        headlineMedium: const TextStyle(
          fontSize: 28,
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: yellow,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          elevation: 2,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.08),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.22),

        elevation: 8,
      ),
    );
  }

  static Widget gradientBackground({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [purple, sky, pink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}

