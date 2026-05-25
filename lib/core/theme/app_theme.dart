import 'package:flutter/material.dart';

/// Theme generique du Moteur GR.
///
/// Les couleurs primaires et secondaires sont injectees via TrailConfig.
/// Ce fichier fournit les tokens de design (spacing, radius, typo)
/// communs a toutes les apps sentier.
class AppTheme {
  AppTheme._();

  // --- Couleurs neutres (communes a tous les sentiers) ---
  static const grisGranite = Color(0xFF616161);
  static const grisClair = Color(0xFFE0E0E0);
  static const grisFond = Color(0xFFF5F5F5);
  static const blancNeige = Color(0xFFFAFAFA);
  static const rougeUrgence = Color(0xFFD32F2F);
  static const noir = Color(0xFF212121);

  // --- Couleurs de denivele (universelles pour le trek) ---
  static const vertFacile = Color(0xFF66BB6A);
  static const jauneModere = Color(0xFFFDD835);
  static const orangeDifficile = Color(0xFFFB8C00);
  static const rougeExtreme = Color(0xFFE53935);

  // --- Spacing (design tokens) ---
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacingBase = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacingXxl = 48;

  // --- Border Radius ---
  static const double radiusCard = 8;
  static const double radiusButton = 12;
  static const double radiusChip = 24;
  static const double radiusBottomSheet = 16;
  static const double radiusInput = 8;

  /// Genere un ThemeData dark a partir des couleurs du sentier.
  static ThemeData buildDarkTheme({
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    final primaryLight = _lighten(primaryColor, 0.3);
    final secondaryLight = _lighten(secondaryColor, 0.2);

    final colorScheme = ColorScheme.dark(
      primary: primaryLight,
      onPrimary: Colors.black,
      primaryContainer: primaryColor,
      onPrimaryContainer: Colors.white,
      secondary: secondaryColor,
      onSecondary: Colors.white,
      secondaryContainer: _darken(secondaryColor, 0.2),
      onSecondaryContainer: secondaryLight,
      error: rougeUrgence,
      onError: Colors.white,
      surface: const Color(0xFF1E1E1E),
      onSurface: const Color(0xFFE0E0E0),
      surfaceContainerHighest: const Color(0xFF2C2C2C),
      outline: const Color(0xFF444444),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        backgroundColor: _darken(primaryColor, 0.1),
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: primaryLight,
        unselectedItemColor: grisGranite,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: Color(0xFF333333), width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          minimumSize: const Size(double.infinity, 52),
          side: BorderSide(color: primaryLight, width: 2),
          backgroundColor: primaryColor.withAlpha(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: secondaryLight,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: Color(0xFF444444)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: primaryLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingBase,
          vertical: spacingMd,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.w700, fontSize: 34, color: Color(0xFFF5F5F5)),
        headlineLarge: TextStyle(fontWeight: FontWeight.w700, fontSize: 28, color: Color(0xFFF5F5F5)),
        headlineMedium: TextStyle(fontWeight: FontWeight.w700, fontSize: 24, color: Color(0xFFF5F5F5)),
        headlineSmall: TextStyle(fontWeight: FontWeight.w600, fontSize: 22, color: Color(0xFFF5F5F5)),
        titleLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 20, color: Color(0xFFF5F5F5)),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Color(0xFFF5F5F5)),
        bodyLarge: TextStyle(fontWeight: FontWeight.w500, fontSize: 20, color: Color(0xFFF5F5F5)),
        bodyMedium: TextStyle(fontWeight: FontWeight.w400, fontSize: 18, color: Color(0xFFF5F5F5)),
        bodySmall: TextStyle(fontWeight: FontWeight.w400, fontSize: 16, color: Color(0xFFF5F5F5)),
        labelLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFFF5F5F5)),
      ),
    );
  }

  /// Eclaircit une couleur
  static Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  /// Assombrit une couleur
  static Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
}
