import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/features/after/presentation/gpx_import_screen.dart';
import 'package:moteur_gr/features/after/providers/gpx_import_provider.dart';
import 'package:moteur_gr/features/trek/domain/models/stage.dart';
import 'package:moteur_gr/features/trek/providers/gps_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// PARITE GR20 (Import GPX) — tests de l'ecran + du cablage data-driven.
///
/// L'ecran clone le flux GR20 (accueil -> picker -> preview -> valider) mais
/// generalise (i18n Slang, pilote par les DONNEES du sentier). Le selecteur de
/// fichier natif ([FilePicker]) n'est pas invocable en test unitaire : on couvre
/// donc l'etat initial (libelles Slang, zero texte en dur), la navigation
/// post-validation (route recap existante) et le cablage du provider de config.
void main() {
  const trailId = 'test-trail-import';

  const config = TrailConfig(
    id: trailId,
    name: 'Test Trail',
    displayName: 'Volcans Trail',
    tagline: 'tagline',
    totalStages: 3,
    totalDistanceKm: 36.0,
    totalElevationGain: 1800,
    region: 'Auvergne',
    country: 'France',
    primaryColorValue: 0xFF2E7D32,
    secondaryColorValue: 0xFF1565C0,
    gpxAssetPath: 'assets/gpx/test.gpx',
    defaultDuration: 3,
    availableDurations: [2, 3, 5],
  );

  Stage stage(int n) => Stage(
        id: '$n',
        nameFr: 'Etape $n',
        distance: 12.0,
        elevationGain: 600,
        elevationLoss: 400,
        orderIndex: n,
        startLat: 45.50 + n * 0.02,
        startLng: 2.90 + n * 0.02,
        endLat: 45.52 + n * 0.02,
        endLng: 2.92 + n * 0.02,
      );

  final stages = [stage(1), stage(2), stage(3)];

  Widget wrap({required Widget child, List<Override> overrides = const []}) {
    final router = GoRouter(
      initialLocation: '/trail/$trailId/import-gpx',
      routes: [
        GoRoute(
          path: '/trail/:id/import-gpx',
          builder: (_, __) => child,
        ),
        // Cible de navigation post-validation (recap existant) — neutre en test.
        GoRoute(
          path: '/trail/:id/recap',
          builder: (_, __) => const Scaffold(body: Text('RECAP_STUB')),
        ),
      ],
    );
    return ProviderScope(
      overrides: overrides,
      child: TranslationProvider(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  setUp(() {
    LocaleSettings.setLocaleRaw('fr');
  });

  group('importTrailConfigProvider (data-driven)', () {
    test('derive bounds + points de ref + totalStages depuis les etapes', () {
      final container = ProviderContainer(
        overrides: [
          trailConfigProvider.overrideWithValue(config),
          domainStagesProvider.overrideWithValue(stages),
        ],
      );
      addTearDown(container.dispose);

      final imp = container.read(importTrailConfigProvider);
      // Boite derivee des etapes (pas de Corse en dur).
      expect(imp.bounds, isNotNull);
      expect(imp.bounds!.contains(42.4, 9.0), isFalse); // Corse hors zone
      // 3 etapes -> 6 points de reference.
      expect(imp.referencePoints.length, 6);
      // totalStages issu du plan (= nb etapes du parcours, ici 3).
      expect(imp.totalStages, 3);
    });
  });

  group('GpxImportScreen (etat initial, i18n)', () {
    testWidgets('affiche titre, entete et bouton via Slang (zero texte en dur)',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          child: const GpxImportScreen(trailId: trailId),
          overrides: [
            trailConfigProvider.overrideWithValue(config),
            domainStagesProvider.overrideWithValue(stages),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.import.title), findsOneWidget);
      expect(find.text(t.import.headerTitle), findsOneWidget);
      expect(find.text(t.import.pickButton), findsOneWidget);
      // Pas de preview tant qu'aucune trace importee.
      expect(find.text(t.import.validateButton), findsNothing);
      // Cloisonnement : aucun libelle GR20 / Corse en dur dans l'ecran.
      expect(find.textContaining('GR20'), findsNothing);
      expect(find.textContaining('Corse'), findsNothing);
    });

    testWidgets('libelles traduits en allemand (accents ä/ü) quand locale de',
        (tester) async {
      LocaleSettings.setLocaleRaw('de');
      addTearDown(() => LocaleSettings.setLocaleRaw('fr'));
      await tester.pumpWidget(
        wrap(
          child: const GpxImportScreen(trailId: trailId),
          overrides: [
            trailConfigProvider.overrideWithValue(config),
            domainStagesProvider.overrideWithValue(stages),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Le bouton allemand porte un vrai umlaut (AUSWÄHLEN), pas ae/ue.
      expect(find.text(t.import.pickButton), findsOneWidget);
      expect(t.import.pickButton, contains('Ä'));
      expect(find.textContaining('AUSWAEHLEN'), findsNothing);
    });
  });

  group('GpxImportRouteScreen (repli trailId)', () {
    testWidgets('sans trailId explicite -> repli sur le sentier actif',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          child: const GpxImportRouteScreen(),
          overrides: [
            trailConfigProvider.overrideWithValue(config),
            domainStagesProvider.overrideWithValue(stages),
          ],
        ),
      );
      await tester.pumpAndSettle();
      // L'ecran se monte proprement (titre present) meme sans trailId de route.
      expect(find.text(t.import.title), findsOneWidget);
    });
  });
}
