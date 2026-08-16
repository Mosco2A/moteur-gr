import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Theme generique du Moteur GR.
///
/// Les couleurs primaires et secondaires sont injectees via TrailConfig.
/// Ce fichier fournit les tokens de design (spacing, radius, typo)
/// communs a toutes les apps sentier.
class AppTheme {
  AppTheme._();

  // --- Typographie (SW-SKIN-L1) ---
  //
  // Couple de polices porte par le theme (jamais ecran par ecran) :
  //  - Titres / display / labels : Space Grotesk (via [GoogleFonts.spaceGrotesk]).
  //  - Corps / UI               : Inter        (via [GoogleFonts.inter]).
  //  - Role "data" (gros chiffres km / D+ / duree) : Space Grotesk w700 +
  //    FontFeature.tabularFigures() -> chiffres a chasse fixe (alignement HUD).
  //
  // Offline-first (arbitrage A1) : google_fonts recupere la police au runtime
  // et la met en cache disque ; si aucun asset embarque ET pas de reseau, il
  // retombe sur la police systeme (Roboto) — jamais de "boite tofu", jamais de
  // blocage reseau. Pour un offline garanti au 1er lancement, deposer les .ttf
  // dans assets/google_fonts/ (voir note de livraison) : google_fonts les
  // detecte alors automatiquement et cesse tout fetch HTTP.

  /// Base du role "data" (gros chiffres de stats) : Space Grotesk w700 avec
  /// chiffres tabulaires. Reutilisable sans BuildContext ; la couleur et la
  /// taille sont heritees du contexte de rendu (widget parent / DefaultTextStyle).
  ///
  /// Preferer [dataTextStyle] quand un BuildContext est disponible : la taille
  /// et la couleur y sont alors alignees sur le TextTheme actif.
  static TextStyle get dataTextStyleBase => GoogleFonts.spaceGrotesk(
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Style du role "data" resolu depuis le [BuildContext].
  ///
  /// Reprend taille et couleur de `headlineMedium` (gros chiffre) du TextTheme
  /// courant, en Space Grotesk w700 + chiffres tabulaires. A utiliser pour les
  /// valeurs de stats (distance, D+, duree) du hub, de la fiche etape et du HUD.
  static TextStyle dataTextStyle(BuildContext context) {
    final base = Theme.of(context).textTheme.headlineMedium;
    return GoogleFonts.spaceGrotesk(
      textStyle: base,
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Construit le [TextTheme] commun aux themes clair et sombre (SW-SKIN-L1).
  ///
  /// Les tailles et poids sont ceux de l'echelle typographique existante
  /// (display 34/w700 … labelLarge 16/w600) : on n'assigne QUE la famille par
  /// role. [onColor] est la couleur du texte (noir sur clair, gris clair sur
  /// sombre) appliquee a tous les roles, a l'identique de l'ancien TextTheme.
  ///
  ///  - display / headline* / title* / label* -> Space Grotesk (titres).
  ///  - body*                                  -> Inter (corps / UI).
  static TextTheme _textTheme(Color onColor) {
    TextStyle title(FontWeight weight, double size) => GoogleFonts.spaceGrotesk(
          textStyle: TextStyle(fontWeight: weight, fontSize: size, color: onColor),
        );
    TextStyle body(FontWeight weight, double size) => GoogleFonts.inter(
          textStyle: TextStyle(fontWeight: weight, fontSize: size, color: onColor),
        );

    return TextTheme(
      displayLarge: title(FontWeight.w700, 34),
      headlineLarge: title(FontWeight.w700, 28),
      headlineMedium: title(FontWeight.w700, 24),
      headlineSmall: title(FontWeight.w600, 22),
      titleLarge: title(FontWeight.w600, 20),
      titleMedium: title(FontWeight.w600, 18),
      bodyLarge: body(FontWeight.w500, 20),
      bodyMedium: body(FontWeight.w400, 18),
      bodySmall: body(FontWeight.w400, 16),
      labelLarge: title(FontWeight.w600, 16),
    );
  }

  // --- Couleurs neutres (communes a tous les sentiers) ---
  static const grisGranite = Color(0xFF616161);

  /// Texte secondaire lisible sur fond SOMBRE (WCAG AA, contraste >= 4.5:1).
  ///
  /// [grisGranite] (0xFF616161) reste adapte aux fonds clairs (ex: share card)
  /// mais echoue le contraste AA sur les surfaces sombres du theme (~2.6:1).
  /// Ce gris clair (~7:1 sur 0xFF1E1E1E) le remplace pour le texte secondaire
  /// des ecrans sombres (suivi, etc.). Voir WcagContrast / audit a11y E5.3a.
  static const grisTexteSecondaire = Color(0xFFB0B0B0);
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

  // --- Couleurs d'action (boutons de suivi) — WCAG AA avec texte blanc ---
  //
  // E5.5b : les boutons d'action du suivi (Demarrer/Reprendre/Pause/Stop)
  // utilisaient `Colors.green`/`Colors.orange` -> texte blanc a ~2.4:1
  // (echec AA, reserve R2 de la gate socles). Ces variantes foncees
  // remontent le contraste texte blanc au-dessus de 4.5:1.
  /// Vert d'action (Demarrer/Reprendre) — blanc dessus ~5.1:1.
  static const actionStart = Color(0xFF2E7D32);

  /// Orange d'action (Pause) — blanc dessus ~5.6:1.
  static const actionPause = Color(0xFFBF360C);

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
        // grisTexteSecondaire (E5.5b) : grisGranite passait juste le seuil UI
        // (3:1) sur le fond sombre de la barre mais echouait le confort de
        // lecture des libelles d'onglet -> token clair conforme AA (7.7:1).
        unselectedItemColor: grisTexteSecondaire,
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
      // SW-SKIN-L1 : familles portees par le theme (Space Grotesk / Inter),
      // tailles et poids inchanges. Couleur texte sombre = gris clair (F5F5F5).
      textTheme: _textTheme(const Color(0xFFF5F5F5)),
    );
  }

  /// Genere un ThemeData clair a partir des couleurs du sentier (E5.5b).
  ///
  /// Pendant clair du theme sombre : meme injection de couleurs depuis
  /// TrailConfig, mais ColorScheme.light + surfaces claires. Tous les
  /// tokens de spacing/radius/typo restent communs. Le texte secondaire
  /// utilise [grisGranite] (conforme AA sur fond clair, ~6:1) et JAMAIS
  /// [grisTexteSecondaire] (reserve aux fonds sombres).
  static ThemeData buildLightTheme({
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    final primaryDark = _darken(primaryColor, 0.1);
    final secondaryDark = _darken(secondaryColor, 0.1);

    final colorScheme = ColorScheme.light(
      primary: primaryColor,
      onPrimary: Colors.white,
      primaryContainer: _lighten(primaryColor, 0.4),
      onPrimaryContainer: _darken(primaryColor, 0.35),
      secondary: secondaryColor,
      onSecondary: Colors.white,
      secondaryContainer: _lighten(secondaryColor, 0.4),
      onSecondaryContainer: secondaryDark,
      error: rougeUrgence,
      onError: Colors.white,
      surface: blancNeige,
      onSurface: noir,
      surfaceContainerHighest: grisFond,
      outline: const Color(0xFFBDBDBD),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: grisFond,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: blancNeige,
        selectedItemColor: primaryDark,
        unselectedItemColor: grisGranite,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: blancNeige,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
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
          foregroundColor: primaryDark,
          minimumSize: const Size(double.infinity, 52),
          side: BorderSide(color: primaryDark, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: secondaryDark,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: blancNeige,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: primaryDark, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingBase,
          vertical: spacingMd,
        ),
      ),
      // SW-SKIN-L1 : familles portees par le theme (Space Grotesk / Inter),
      // tailles et poids inchanges. Couleur texte clair = noir (token existant).
      textTheme: _textTheme(noir),
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
