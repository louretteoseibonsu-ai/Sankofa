import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color plantainGreen = Color(0xFF2E8B57);
  static const Color accentCoral = Color(0xFFE2725B);
  static const Color cardBackground = Color(0xFFF7F4EE);
  static const Color nudgeSurface = Color(0xFFFFFAEF);
  static const double cardRadius = 24.0;
  static const double cardElevation = 6.0;
  static const double buttonHeight = 56.0;

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: plantainGreen,
        scaffoldBackgroundColor: const Color(0xFFF2EFE9),
        cardTheme: CardThemeData(
          color: cardBackground,
          elevation: cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: plantainGreen,
            shape: const StadiumBorder(),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
}
