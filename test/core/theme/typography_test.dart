import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moteur_gr/core/theme/app_theme.dart';

/// Tests SW-SKIN-L1 — typographie portee par le theme (google_fonts).
///
/// Verifie que les deux themes exposent bien :
///  - Space Grotesk sur les roles titres (display / headline / title / label),
///  - Inter sur les roles corps (body),
///  - un role "data" en chiffres tabulaires (FontFeature.tabularFigures),
/// et que les tailles/poids de l'echelle typographique restent inchanges.
///
/// NB google_fonts + offline : on desactive le fetch HTTP runtime
/// (`allowRuntimeFetching = false`, pattern officiel google_fonts). En test,
/// aucune police n'etant bundlee, `GoogleFonts.*` planifie une future de
/// chargement qui echoue (offline) — le `TextStyle` renvoye porte tout de meme
/// la bonne famille (ce que verifient ces tests). On draine cette exception
/// benigne via [_drainFontLoad] : elle reflete la garantie offline-first du
/// produit (aucune dependance reseau au rendu ; fallback police systeme).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  const primary = Color(0xFF2E7D32);
  const secondary = Color(0xFF1565C0);

  ThemeData light() =>
      AppTheme.buildLightTheme(primaryColor: primary, secondaryColor: secondary);
  ThemeData dark() =>
      AppTheme.buildDarkTheme(primaryColor: primary, secondaryColor: secondary);

  /// Laisse les futures de chargement de police se resoudre puis absorbe
  /// l'exception google_fonts (police non bundlee + pas de reseau en test).
  /// Toute AUTRE exception est propagee (echec de test legitime).
  Future<void> drainFontLoad(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 1));
    final ex = tester.takeException();
    if (ex != null) {
      expect(ex.toString().toLowerCase(), contains('font'),
          reason: 'seule l\'exception de chargement google_fonts est toleree');
    }
  }

  group('SW-SKIN-L1 — familles portees par le theme', () {
    for (final entry in {'clair': light, 'sombre': dark}.entries) {
      final buildTheme = entry.value;

      testWidgets('theme ${entry.key} : titres en Space Grotesk',
          (tester) async {
        final tt = buildTheme().textTheme;
        // Roles titres/display/labels -> Space Grotesk.
        expect(tt.displayLarge?.fontFamily, contains('SpaceGrotesk'));
        expect(tt.headlineLarge?.fontFamily, contains('SpaceGrotesk'));
        expect(tt.headlineMedium?.fontFamily, contains('SpaceGrotesk'));
        expect(tt.headlineSmall?.fontFamily, contains('SpaceGrotesk'));
        expect(tt.titleLarge?.fontFamily, contains('SpaceGrotesk'));
        expect(tt.titleMedium?.fontFamily, contains('SpaceGrotesk'));
        expect(tt.labelLarge?.fontFamily, contains('SpaceGrotesk'));
        await drainFontLoad(tester);
      });

      testWidgets('theme ${entry.key} : corps en Inter', (tester) async {
        final tt = buildTheme().textTheme;
        // Roles corps/UI -> Inter.
        expect(tt.bodyLarge?.fontFamily, contains('Inter'));
        expect(tt.bodyMedium?.fontFamily, contains('Inter'));
        expect(tt.bodySmall?.fontFamily, contains('Inter'));
        await drainFontLoad(tester);
      });

      testWidgets('theme ${entry.key} : tailles et poids inchanges (echelle typo)',
          (tester) async {
        final tt = buildTheme().textTheme;
        // On n'assigne QUE la famille : tailles/poids restent ceux d'origine.
        expect(tt.displayLarge?.fontSize, 34);
        expect(tt.displayLarge?.fontWeight, FontWeight.w700);
        expect(tt.headlineLarge?.fontSize, 28);
        expect(tt.headlineLarge?.fontWeight, FontWeight.w700);
        expect(tt.headlineMedium?.fontSize, 24);
        expect(tt.headlineMedium?.fontWeight, FontWeight.w700);
        expect(tt.headlineSmall?.fontSize, 22);
        expect(tt.headlineSmall?.fontWeight, FontWeight.w600);
        expect(tt.titleLarge?.fontSize, 20);
        expect(tt.titleLarge?.fontWeight, FontWeight.w600);
        expect(tt.titleMedium?.fontSize, 18);
        expect(tt.titleMedium?.fontWeight, FontWeight.w600);
        expect(tt.bodyLarge?.fontSize, 20);
        expect(tt.bodyLarge?.fontWeight, FontWeight.w500);
        expect(tt.bodyMedium?.fontSize, 18);
        expect(tt.bodyMedium?.fontWeight, FontWeight.w400);
        expect(tt.bodySmall?.fontSize, 16);
        expect(tt.bodySmall?.fontWeight, FontWeight.w400);
        expect(tt.labelLarge?.fontSize, 16);
        expect(tt.labelLarge?.fontWeight, FontWeight.w600);
        await drainFontLoad(tester);
      });

      testWidgets('theme ${entry.key} : couleur de texte preservee',
          (tester) async {
        final tt = buildTheme().textTheme;
        // Clair -> noir (0xFF212121) ; sombre -> gris clair (0xFFF5F5F5).
        final expected = entry.key == 'clair'
            ? const Color(0xFF212121)
            : const Color(0xFFF5F5F5);
        expect(tt.displayLarge?.color, expected);
        expect(tt.bodyMedium?.color, expected);
        expect(tt.labelLarge?.color, expected);
        await drainFontLoad(tester);
      });
    }
  });

  group('SW-SKIN-L1 — role data (chiffres tabulaires)', () {
    testWidgets('dataTextStyleBase : Space Grotesk w700 + tabularFigures',
        (tester) async {
      final style = AppTheme.dataTextStyleBase;
      expect(style.fontFamily, contains('SpaceGrotesk'));
      expect(style.fontWeight, FontWeight.w700);
      expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
      await drainFontLoad(tester);
    });

    testWidgets('dataTextStyle(context) : tabular + taille/couleur du theme',
        (tester) async {
      late TextStyle resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: light(),
          home: Builder(
            builder: (context) {
              resolved = AppTheme.dataTextStyle(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved.fontFamily, contains('SpaceGrotesk'));
      expect(resolved.fontWeight, FontWeight.w700);
      expect(resolved.fontFeatures, contains(const FontFeature.tabularFigures()));
      // Herite la taille du role headlineMedium (24) du theme actif.
      expect(resolved.fontSize, 24);
      await drainFontLoad(tester);
    });
  });
}
