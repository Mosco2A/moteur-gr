import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/a11y/wcag_contrast.dart';
import 'package:moteur_gr/core/theme/app_theme.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Tests E5.3a — audit accessibilite : contraste WCAG AA + labels Slang.
void main() {
  group('WcagContrast — valeurs de reference WCAG', () {
    test('noir/blanc = 21:1 (contraste maximal)', () {
      expect(WcagContrast.ratio(Colors.black, Colors.white),
          closeTo(21.0, 0.1));
    });

    test('couleurs identiques = 1:1', () {
      expect(WcagContrast.ratio(Colors.white, Colors.white), closeTo(1.0, 0.001));
      expect(WcagContrast.ratio(const Color(0xFF123456), const Color(0xFF123456)),
          closeTo(1.0, 0.001));
    });

    test('symetrie : ratio(a,b) == ratio(b,a)', () {
      final ab = WcagContrast.ratio(Colors.black, Colors.white);
      final ba = WcagContrast.ratio(Colors.white, Colors.black);
      expect(ab, closeTo(ba, 0.0001));
    });

    test('seuils AA : blanc/noir conforme, gris moyen sur blanc non conforme', () {
      expect(WcagContrast.meetsAA(Colors.white, Colors.black), isTrue);
      // #999999 sur blanc ~ 2.85:1 -> echoue AA texte normal.
      expect(WcagContrast.meetsAA(const Color(0xFF999999), Colors.white),
          isFalse);
    });
  });

  group('Audit contraste — theme sombre (ecrans principaux)', () {
    final theme = AppTheme.buildDarkTheme(
      primaryColor: const Color(0xFF2E7D32),
      secondaryColor: const Color(0xFF1565C0),
    );
    final surface = theme.colorScheme.surface;
    final scaffold = theme.scaffoldBackgroundColor;
    final raised = theme.colorScheme.surfaceContainerHighest;
    final bodyColor = theme.textTheme.bodyMedium!.color!;

    test('texte principal conforme AA sur toutes les surfaces sombres', () {
      for (final bg in [surface, scaffold, raised]) {
        expect(WcagContrast.meetsAA(bodyColor, bg), isTrue,
            reason: 'texte principal $bodyColor sur $bg < 4.5:1 '
                '(${WcagContrast.ratio(bodyColor, bg).toStringAsFixed(2)})');
      }
    });

    test('texte secondaire (grisTexteSecondaire) conforme AA sur fond sombre',
        () {
      for (final bg in [surface, raised]) {
        expect(WcagContrast.meetsAA(AppTheme.grisTexteSecondaire, bg), isTrue,
            reason: 'ratio = '
                '${WcagContrast.ratio(AppTheme.grisTexteSecondaire, bg).toStringAsFixed(2)}');
      }
    });

    test('couleurs de statut/denivele lisibles en texte sur carte sombre', () {
      // Vert facile + orange difficile + jaune modere : texte colore sur
      // surface sombre -> conforme AA.
      for (final c in [
        AppTheme.vertFacile,
        AppTheme.orangeDifficile,
        AppTheme.jauneModere,
      ]) {
        expect(WcagContrast.meetsAA(c, surface), isTrue,
            reason: 'ratio = ${WcagContrast.ratio(c, surface).toStringAsFixed(2)}');
      }
    });

    test('rouge urgence conforme au seuil non-textuel/UI (>= 3:1) sur sombre',
        () {
      expect(WcagContrast.meetsNonText(AppTheme.rougeUrgence, surface), isTrue);
    });

    test('grisGranite ECHOUE AA en texte sur fond sombre (justifie le token clair)',
        () {
      // Documente la raison de grisTexteSecondaire : grisGranite (adapte aux
      // fonds clairs) n'atteint pas 4.5:1 sur les surfaces sombres.
      expect(WcagContrast.meetsAA(AppTheme.grisGranite, surface), isFalse);
    });

    test('libelle d\'onglet non selectionne (bottom nav) conforme AA — E5.5b',
        () {
      // Reserve R2 : grisGranite passait juste le seuil UI mais pas le confort
      // de lecture. La barre utilise desormais grisTexteSecondaire (>= 4.5:1).
      final navBg = theme.bottomNavigationBarTheme.backgroundColor!;
      final unselected =
          theme.bottomNavigationBarTheme.unselectedItemColor!;
      expect(unselected, AppTheme.grisTexteSecondaire);
      expect(WcagContrast.meetsAA(unselected, navBg), isTrue,
          reason: 'ratio = '
              '${WcagContrast.ratio(unselected, navBg).toStringAsFixed(2)}');
    });
  });

  group('Audit contraste — boutons d\'action suivi (R2 resolue, E5.5b)', () {
    test('texte blanc conforme AA sur les couleurs d\'action', () {
      // Avant E5.5b : Colors.green/Colors.orange -> blanc a ~2.2-2.8:1 (echec).
      // Apres : actionStart / actionPause / rougeUrgence -> blanc >= 4.5:1.
      for (final c in [
        AppTheme.actionStart,
        AppTheme.actionPause,
        AppTheme.rougeUrgence,
      ]) {
        expect(WcagContrast.meetsAA(Colors.white, c), isTrue,
            reason: 'blanc sur $c = '
                '${WcagContrast.ratio(Colors.white, c).toStringAsFixed(2)}:1');
      }
    });

    test('les anciennes couleurs Material vives echouaient AA (regression doc)',
        () {
      // Garde-fou : si quelqu'un revient a Colors.green/orange, ce test
      // rappelle pourquoi on ne le fait pas (echec AA texte blanc).
      expect(WcagContrast.meetsAA(Colors.white, Colors.green), isFalse);
      expect(WcagContrast.meetsAA(Colors.white, Colors.orange), isFalse);
    });
  });

  group('Audit contraste — theme clair (E5.5b)', () {
    final light = AppTheme.buildLightTheme(
      primaryColor: const Color(0xFF2E7D32),
      secondaryColor: const Color(0xFF1565C0),
    );

    test('texte principal conforme AA sur les surfaces claires', () {
      final bodyColor = light.textTheme.bodyMedium!.color!;
      for (final bg in [
        light.colorScheme.surface,
        light.scaffoldBackgroundColor,
        light.colorScheme.surfaceContainerHighest,
      ]) {
        expect(WcagContrast.meetsAA(bodyColor, bg), isTrue,
            reason: 'texte principal $bodyColor sur $bg = '
                '${WcagContrast.ratio(bodyColor, bg).toStringAsFixed(2)}:1');
      }
    });

    test('grisGranite reste conforme AA en texte secondaire sur fond clair', () {
      // Justifie que grisGranite reste le token des contextes clairs
      // (ex: carte de partage), la ou grisTexteSecondaire echouerait.
      for (final bg in [light.colorScheme.surface, AppTheme.blancNeige]) {
        expect(WcagContrast.meetsAA(AppTheme.grisGranite, bg), isTrue,
            reason: 'ratio = '
                '${WcagContrast.ratio(AppTheme.grisGranite, bg).toStringAsFixed(2)}');
      }
    });

    test('grisTexteSecondaire ECHOUE sur fond clair (ne pas l\'y utiliser)', () {
      // Symetrique du test sombre : le token clair n'est PAS lisible sur clair.
      expect(
          WcagContrast.meetsAA(
              AppTheme.grisTexteSecondaire, AppTheme.blancNeige),
          isFalse);
    });
  });

  group('Labels a11y Slang — presents dans les 5 langues', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    test('getters et methodes a11y non vides pour chaque locale', () {
      for (final locale in ['fr', 'en', 'de', 'es', 'it']) {
        LocaleSettings.setLocaleRaw(locale);
        expect(t.a11y.back, isNotEmpty, reason: 'back/$locale');
        expect(t.a11y.zoomIn, isNotEmpty, reason: 'zoomIn/$locale');
        expect(t.a11y.zoomOut, isNotEmpty, reason: 'zoomOut/$locale');
        expect(t.a11y.centerOnMe, isNotEmpty, reason: 'centerOnMe/$locale');
        expect(t.a11y.userPosition, isNotEmpty, reason: 'userPosition/$locale');
        expect(t.a11y.startTracking, isNotEmpty, reason: 'startTracking/$locale');
        expect(t.a11y.stopTracking, isNotEmpty, reason: 'stopTracking/$locale');
        // Methodes parametrees : la valeur doit etre interpolee.
        expect(t.a11y.stageMarker(number: 3), contains('3'),
            reason: 'stageMarker/$locale');
        expect(t.a11y.markerCluster(count: 12), contains('12'),
            reason: 'markerCluster/$locale');
        expect(t.a11y.poiMarker(name: 'Refuge'), contains('Refuge'),
            reason: 'poiMarker/$locale');
      }
      LocaleSettings.setLocaleRaw('fr');
    });
  });
}
