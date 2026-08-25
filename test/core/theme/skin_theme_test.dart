import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/theme/app_skin.dart';
import 'package:moteur_gr/core/theme/app_theme.dart';
import 'package:moteur_gr/core/theme/skin_theme.dart';

/// Tests SW-SKIN-L2 — porteur technique des peaux (`SkinTheme` ThemeExtension).
///
/// Couvre :
///  - `copyWith` (dont remise a null d'un champ nullable via sentinelle),
///  - `lerp` (interpolation des doubles, bascule discrete du reste),
///  - `fromSkin` / `of` (resolution + fallback),
///  - l'injection dans `ThemeData.extensions` par `buildLightTheme`/`buildDarkTheme`,
///  - la NEUTRALITE VISUELLE : le ThemeData en peau `sentierVivant` (defaut) a
///    exactement les memes couleurs/typo qu'avant L2 (aucun ecran ne change).
///
/// NB google_fonts en test (offline) : construire un theme cable google_fonts
/// (L1) planifie une future de chargement de police qui echoue et *rethrow* de
/// facon asynchrone. Pour tout test qui CONSTRUIT un `ThemeData` complet, on
/// utilise `testWidgets` + [drainFontLoad] (pattern de `typography_test.dart`) :
/// l'exception benigne est alors capturee de maniere deterministe via
/// `tester.takeException()`. Les tests qui ne touchent QUE des instances
/// `SkinTheme` (copyWith/lerp/egalite/fromSkin, sans ThemeData) restent des
/// `test` purs — ils n'appellent jamais google_fonts.
void main() {
  const primary = Color(0xFF2E7D32);
  const secondary = Color(0xFF1565C0);

  ThemeData light(AppSkin skin) => AppTheme.buildLightTheme(
      primaryColor: primary, secondaryColor: secondary, skin: skin);
  ThemeData dark(AppSkin skin) => AppTheme.buildDarkTheme(
      primaryColor: primary, secondaryColor: secondary, skin: skin);

  /// Laisse la future de chargement google_fonts se resoudre puis absorbe
  /// l'exception benigne (police non bundlee + offline en test). Toute AUTRE
  /// exception est propagee (echec de test legitime).
  Future<void> drainFontLoad(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 1));
    final ex = tester.takeException();
    if (ex != null) {
      expect(ex.toString().toLowerCase(), contains('font'),
          reason: 'seule l\'exception de chargement google_fonts est toleree');
    }
  }

  group('SkinTheme — instances des 3 peaux (CCO §3)', () {
    test('Sentier Vivant : degrade, elevation douce, sans image ni mono', () {
      expect(SentierVivantSkin.skin, AppSkin.sentierVivant);
      expect(SentierVivantSkin.headerStyle, SkinHeaderStyle.gradient);
      expect(SentierVivantSkin.cardStyle, SkinCardStyle.elevatedSoft);
      expect(SentierVivantSkin.usesImagery, isFalse);
      expect(SentierVivantSkin.usesMonoData, isFalse);
      expect(SentierVivantSkin.titleFontFamily, isNull);
      expect(SentierVivantSkin.scrimOpacity, 0.0);
    });

    test('Topographique : filet topo, bord fin, mono, sans image', () {
      expect(TopographiqueSkin.skin, AppSkin.topographique);
      expect(TopographiqueSkin.headerStyle, SkinHeaderStyle.topoFilet);
      expect(TopographiqueSkin.cardStyle, SkinCardStyle.thinInstrument);
      expect(TopographiqueSkin.usesImagery, isFalse);
      expect(TopographiqueSkin.usesMonoData, isTrue);
    });

    test('Grand Air : photo, image + scrim > 0, titre serif surcharge', () {
      expect(GrandAirSkin.skin, AppSkin.grandAir);
      expect(GrandAirSkin.headerStyle, SkinHeaderStyle.photo);
      expect(GrandAirSkin.cardStyle, SkinCardStyle.photo);
      expect(GrandAirSkin.usesImagery, isTrue);
      expect(GrandAirSkin.titleFontFamily, isNotNull);
      expect(GrandAirSkin.scrimOpacity, greaterThan(0.0));
    });
  });

  group('SkinTheme — fromSkin', () {
    test('resout chaque enum vers la bonne instance', () {
      expect(SkinTheme.fromSkin(AppSkin.sentierVivant), SentierVivantSkin);
      expect(SkinTheme.fromSkin(AppSkin.topographique), TopographiqueSkin);
      expect(SkinTheme.fromSkin(AppSkin.grandAir), GrandAirSkin);
    });
  });

  group('SkinTheme — copyWith', () {
    test('sans argument : instance egale (tous champs conserves)', () {
      expect(GrandAirSkin.copyWith(), GrandAirSkin);
    });

    test('surcharge selective d\'un champ, le reste inchange', () {
      final modifie = SentierVivantSkin.copyWith(scrimOpacity: 0.7);
      expect(modifie.scrimOpacity, 0.7);
      // Les autres champs restent ceux de Sentier Vivant.
      expect(modifie.skin, SentierVivantSkin.skin);
      expect(modifie.headerStyle, SentierVivantSkin.headerStyle);
      expect(modifie.cardStyle, SentierVivantSkin.cardStyle);
      expect(modifie.usesImagery, SentierVivantSkin.usesImagery);
    });

    test('peut surcharger les enums et drapeaux', () {
      final modifie = SentierVivantSkin.copyWith(
        headerStyle: SkinHeaderStyle.photo,
        cardStyle: SkinCardStyle.photo,
        usesImagery: true,
        usesMonoData: true,
      );
      expect(modifie.headerStyle, SkinHeaderStyle.photo);
      expect(modifie.cardStyle, SkinCardStyle.photo);
      expect(modifie.usesImagery, isTrue);
      expect(modifie.usesMonoData, isTrue);
    });

    test('titleFontFamily : surcharge par une valeur', () {
      final modifie = SentierVivantSkin.copyWith(titleFontFamily: 'Fraunces');
      expect(modifie.titleFontFamily, 'Fraunces');
    });

    test('titleFontFamily : sentinelle -> peut remettre a null', () {
      // Grand Air porte 'Fraunces' ; copyWith(titleFontFamily: null) doit
      // vraiment remettre a null (retour au defaut du theme), pas ignorer.
      final remisANull = GrandAirSkin.copyWith(titleFontFamily: null);
      expect(remisANull.titleFontFamily, isNull);
      // Un autre champ non fourni reste inchange (preuve : ce n'est pas un reset
      // global mais bien la seule famille qui repasse a null).
      expect(remisANull.usesImagery, GrandAirSkin.usesImagery);
    });

    test('titleFontFamily : non fourni -> valeur conservee', () {
      final inchange = GrandAirSkin.copyWith(scrimOpacity: 0.5);
      expect(inchange.titleFontFamily, GrandAirSkin.titleFontFamily);
    });
  });

  group('SkinTheme — lerp', () {
    test('interpole scrimOpacity au milieu', () {
      const a = SentierVivantSkin; // scrim 0.0
      const b = GrandAirSkin; // scrim 0.45
      final mid = a.lerp(b, 0.5);
      expect(mid.scrimOpacity, closeTo(0.225, 1e-9));
    });

    test('t=0 -> depart, t=1 -> arrivee (bornes)', () {
      const a = SentierVivantSkin;
      const b = GrandAirSkin;
      expect(a.lerp(b, 0.0).scrimOpacity, a.scrimOpacity);
      expect(a.lerp(b, 1.0).scrimOpacity, b.scrimOpacity);
    });

    test('champs discrets basculent au point milieu (t<0.5)', () {
      const a = SentierVivantSkin;
      const b = GrandAirSkin;
      // Avant 0.5 : encore la peau de depart.
      expect(a.lerp(b, 0.25).skin, AppSkin.sentierVivant);
      expect(a.lerp(b, 0.25).headerStyle, SkinHeaderStyle.gradient);
      expect(a.lerp(b, 0.25).usesImagery, isFalse);
      // A partir de 0.5 : peau d'arrivee.
      expect(a.lerp(b, 0.5).skin, AppSkin.grandAir);
      expect(a.lerp(b, 0.5).headerStyle, SkinHeaderStyle.photo);
      expect(a.lerp(b, 0.5).usesImagery, isTrue);
    });

    test('lerp avec other null/incompatible -> retourne this', () {
      expect(SentierVivantSkin.lerp(null, 0.5), SentierVivantSkin);
    });
  });

  group('SkinTheme — egalite de valeur', () {
    test('deux instances identiques sont egales et memes hashCode', () {
      const a = SkinTheme(
        skin: AppSkin.sentierVivant,
        titleFontFamily: null,
        headerStyle: SkinHeaderStyle.gradient,
        cardStyle: SkinCardStyle.elevatedSoft,
        usesImagery: false,
        usesMonoData: false,
        scrimOpacity: 0.0,
      );
      expect(a, SentierVivantSkin);
      expect(a.hashCode, SentierVivantSkin.hashCode);
    });

    test('une difference de champ casse l\'egalite', () {
      expect(SentierVivantSkin == TopographiqueSkin, isFalse);
      expect(SentierVivantSkin.copyWith(scrimOpacity: 0.1) == SentierVivantSkin,
          isFalse);
    });
  });

  group('SW-SKIN-L2 — injection dans ThemeData.extensions', () {
    testWidgets('buildLightTheme(skin: topographique) expose la peau topo',
        (tester) async {
      final ext = light(AppSkin.topographique).extension<SkinTheme>();
      expect(ext, isNotNull);
      expect(ext, TopographiqueSkin);
      expect(ext!.skin, AppSkin.topographique);
      await drainFontLoad(tester);
    });

    testWidgets('buildDarkTheme(skin: grandAir) expose la peau grand air',
        (tester) async {
      final ext = dark(AppSkin.grandAir).extension<SkinTheme>();
      expect(ext, GrandAirSkin);
      await drainFontLoad(tester);
    });

    testWidgets('defaut sentierVivant expose bien Sentier Vivant (clair + sombre)',
        (tester) async {
      expect(light(AppSkin.sentierVivant).extension<SkinTheme>(),
          SentierVivantSkin);
      expect(dark(AppSkin.sentierVivant).extension<SkinTheme>(),
          SentierVivantSkin);
      await drainFontLoad(tester);
    });
  });

  group('SkinTheme.of — helper de lecture avec fallback', () {
    testWidgets('lit la peau injectee dans le theme', (tester) async {
      late SkinTheme lue;
      await tester.pumpWidget(
        MaterialApp(
          theme: light(AppSkin.topographique),
          home: Builder(builder: (context) {
            lue = SkinTheme.of(context);
            return const SizedBox.shrink();
          }),
        ),
      );
      expect(lue, TopographiqueSkin);
      await drainFontLoad(tester);
    });

    testWidgets('fallback SentierVivant si aucune extension injectee',
        (tester) async {
      late SkinTheme lue;
      await tester.pumpWidget(
        MaterialApp(
          // Theme SANS extension SkinTheme (ThemeData.light() brut).
          theme: ThemeData.light(),
          home: Builder(builder: (context) {
            lue = SkinTheme.of(context);
            return const SizedBox.shrink();
          }),
        ),
      );
      expect(lue, SentierVivantSkin);
    });
  });

  // -------------------------------------------------------------------------
  // NEUTRALITE VISUELLE (critere d'acceptation cle SW-SKIN-L2)
  //
  // Preuve que poser la structure de peaux (defaut sentierVivant) NE CHANGE
  // RIEN au rendu : le ThemeData produit a exactement les memes champs cles
  // (couleurs de ColorScheme, surfaces, typo, boutons, appbar) qu'avant L2.
  // On compare aussi les 3 peaux entre elles sur ces memes champs : elles sont
  // IDENTIQUES en L2 (seule l'extension SkinTheme differe) — donc aucun ecran
  // ne peut changer tant que les composants ne lisent pas SkinTheme (L5/L6).
  // -------------------------------------------------------------------------
  group('SW-SKIN-L2 — neutralite visuelle (non-regression ThemeData)', () {
    testWidgets('ColorScheme clair inchange (valeurs attendues avant L2)',
        (tester) async {
      final cs = light(AppSkin.sentierVivant).colorScheme;
      expect(cs.brightness, Brightness.light);
      expect(cs.primary, primary);
      expect(cs.onPrimary, Colors.white);
      expect(cs.secondary, secondary);
      expect(cs.error, AppTheme.rougeUrgence);
      expect(cs.surface, AppTheme.blancNeige);
      expect(cs.onSurface, AppTheme.noir);
      expect(cs.surfaceContainerHighest, AppTheme.grisFond);
      expect(cs.outline, const Color(0xFFBDBDBD));
      await drainFontLoad(tester);
    });

    testWidgets('ColorScheme sombre inchange (valeurs attendues avant L2)',
        (tester) async {
      final cs = dark(AppSkin.sentierVivant).colorScheme;
      expect(cs.brightness, Brightness.dark);
      expect(cs.primaryContainer, primary);
      expect(cs.error, AppTheme.rougeUrgence);
      expect(cs.surface, const Color(0xFF1E1E1E));
      expect(cs.onSurface, const Color(0xFFE0E0E0));
      expect(cs.surfaceContainerHighest, const Color(0xFF2C2C2C));
      expect(cs.outline, const Color(0xFF444444));
      await drainFontLoad(tester);
    });

    testWidgets('scaffold / appbar / bottom nav inchanges (clair)',
        (tester) async {
      final th = light(AppSkin.sentierVivant);
      expect(th.scaffoldBackgroundColor, AppTheme.grisFond);
      expect(th.appBarTheme.backgroundColor, primary);
      expect(th.appBarTheme.elevation, 4);
      expect(th.appBarTheme.centerTitle, isTrue);
      expect(th.bottomNavigationBarTheme.backgroundColor, AppTheme.blancNeige);
      expect(th.bottomNavigationBarTheme.unselectedItemColor,
          AppTheme.grisGranite);
      await drainFontLoad(tester);
    });

    testWidgets('typographie inchangee (familles + tailles/poids, clair)',
        (tester) async {
      final tt = light(AppSkin.sentierVivant).textTheme;
      // Familles (L1) : titres Space Grotesk, corps Inter.
      expect(tt.displayLarge?.fontFamily, contains('SpaceGrotesk'));
      expect(tt.bodyMedium?.fontFamily, contains('Inter'));
      // Tailles/poids de l'echelle typo, inchanges par L2.
      expect(tt.displayLarge?.fontSize, 34);
      expect(tt.displayLarge?.fontWeight, FontWeight.w700);
      expect(tt.bodyMedium?.fontSize, 18);
      expect(tt.labelLarge?.fontSize, 16);
      // Couleur texte clair = noir (token existant).
      expect(tt.bodyMedium?.color, AppTheme.noir);
      await drainFontLoad(tester);
    });

    testWidgets('les 3 peaux produisent le MEME ThemeData hors extension (L2)',
        (tester) async {
      // En L2, aucune peau ne modifie encore couleurs/typo/boutons : seul le
      // SkinTheme injecte differe. On le prouve sur les champs les plus visibles.
      final sv = light(AppSkin.sentierVivant);
      final topo = light(AppSkin.topographique);
      final ga = light(AppSkin.grandAir);

      for (final other in [topo, ga]) {
        expect(other.colorScheme.primary, sv.colorScheme.primary);
        expect(other.colorScheme.surface, sv.colorScheme.surface);
        expect(other.colorScheme.onSurface, sv.colorScheme.onSurface);
        expect(other.scaffoldBackgroundColor, sv.scaffoldBackgroundColor);
        expect(other.appBarTheme.backgroundColor,
            sv.appBarTheme.backgroundColor);
        // Typo identique (familles + tailles/poids/couleur).
        expect(other.textTheme.displayLarge?.fontFamily,
            sv.textTheme.displayLarge?.fontFamily);
        expect(other.textTheme.displayLarge?.fontSize,
            sv.textTheme.displayLarge?.fontSize);
        expect(other.textTheme.bodyMedium?.color,
            sv.textTheme.bodyMedium?.color);
      }

      // Seule l'extension differe -> c'est la SEULE chose que L2 ajoute.
      expect(sv.extension<SkinTheme>(), SentierVivantSkin);
      expect(topo.extension<SkinTheme>(), TopographiqueSkin);
      expect(ga.extension<SkinTheme>(), GrandAirSkin);
      await drainFontLoad(tester);
    });
  });
}
