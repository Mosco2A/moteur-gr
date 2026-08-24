import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/core/theme/app_skin.dart';
import 'package:moteur_gr/core/theme/app_theme.dart';
import 'package:moteur_gr/features/trail/presentation/trail_stage_detail_screen.dart';
import 'package:moteur_gr/features/trail/presentation/trail_detail_screen.dart';
import 'package:moteur_gr/features/trail/providers/pois_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Tests E5.5b — bascule de theme (clair/sombre) sans casse d'ecran.
///
/// Verifie que les deux ThemeData se construisent depuis les memes couleurs
/// de TrailConfig, et qu'un ecran riche (detail sentier + detail etape)
/// s'affiche sous chaque theme sans exception ni overflow.
void main() {
  const primary = Color(0xFF2E7D32);
  const secondary = Color(0xFF1565C0);

  const testStage = StageModel(
    id: 1,
    trailId: 'test-trail',
    stageNumber: 1,
    name: 'Premiere etape',
    distanceKm: 12.0,
    elevationGainM: 700,
    elevationLossM: 300,
    description: 'Belle montee.',
    startLat: 42.0,
    startLng: 9.0,
    endLat: 42.1,
    endLng: 9.1,
    difficulty: 'medium',
  );

  group('AppTheme — construction des deux themes', () {
    // testWidgets (et non test) car construire le theme cable desormais
    // google_fonts (SW-SKIN-L1) : le chargement de police echoue en test
    // hors-ligne et remonte une exception benigne, drainee ici via
    // takeException (le TextStyle renvoye porte bien la bonne famille).
    testWidgets('buildLightTheme et buildDarkTheme produisent la bonne brightness',
        (tester) async {
      final light = AppTheme.buildLightTheme(
          primaryColor: primary,
          secondaryColor: secondary,
          skin: AppSkin.sentierVivant);
      final dark = AppTheme.buildDarkTheme(
          primaryColor: primary,
          secondaryColor: secondary,
          skin: AppSkin.sentierVivant);

      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(light.useMaterial3, isTrue);
      expect(dark.useMaterial3, isTrue);
      // Couleurs injectees depuis TrailConfig dans les deux themes.
      expect(light.colorScheme.primary, primary);
      expect(dark.colorScheme.primaryContainer, primary);

      // Draine l'eventuelle exception de chargement google_fonts (offline).
      await tester.pump(const Duration(milliseconds: 1));
      final ex = tester.takeException();
      if (ex != null) {
        expect(ex.toString().toLowerCase(), contains('font'));
      }
    });
  });

  group('Bascule de theme — aucun ecran casse', () {
    Widget app({required ThemeData theme}) => ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            stagesProvider('test-trail')
                .overrideWith((ref) => Future.value([testStage])),
            poisProvider('test-trail')
                .overrideWith((ref) => Future.value(const [])),
          ],
          child: TranslationProvider(
            child: MaterialApp(
              theme: theme,
              home: TrailDetailScreen(trailId: testTrailConfig.id),
            ),
          ),
        );

    for (final entry in {
      'clair': AppTheme.buildLightTheme(
          primaryColor: primary,
          secondaryColor: secondary,
          skin: AppSkin.sentierVivant),
      'sombre': AppTheme.buildDarkTheme(
          primaryColor: primary,
          secondaryColor: secondary,
          skin: AppSkin.sentierVivant),
    }.entries) {
      testWidgets('TrailDetailScreen s\'affiche en theme ${entry.key}',
          (tester) async {
        await tester.pumpWidget(app(theme: entry.value));
        await tester.pumpAndSettle();

        // Pas d'exception de rendu (overflow, etc.).
        expect(tester.takeException(), isNull);
        // En-tete + section etapes presents.
        expect(find.text(testTrailConfig.displayName), findsWidgets);
        expect(find.text('Étapes'), findsOneWidget);
        expect(find.text('Premiere etape'), findsOneWidget);
      });
    }

    testWidgets('TrailStageDetailScreen s\'affiche en theme clair (Hero badge)',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            stagesProvider('test-trail')
                .overrideWith((ref) => Future.value([testStage])),
            poisProvider('test-trail')
                .overrideWith((ref) => Future.value(const [])),
          ],
          child: MaterialApp(
            theme: AppTheme.buildLightTheme(
                primaryColor: primary,
                secondaryColor: secondary,
                skin: AppSkin.sentierVivant),
            home: const TrailStageDetailScreen(
              trailId: 'test-trail',
              stageNumber: 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Le badge de numero (Hero) et le nom sont rendus.
      expect(find.text('1'), findsWidgets);
      expect(find.text('Premiere etape'), findsOneWidget);
    });
  });
}
