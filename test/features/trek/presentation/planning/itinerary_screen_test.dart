import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/trek/domain/models/itinerary_day.dart';
import 'package:moteur_gr/features/trek/presentation/planning/itinerary_screen.dart';
import 'package:moteur_gr/features/trek/providers/itinerary_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Tests de l'ecran ITINERAIRE (PARITE GR20 #99433) + non-regression du bug de
/// navigation (retour depuis Itineraire).
///
/// Couvre :
///   - le DEROULE des etapes (jour par jour) avec infos par etape (distance,
///     D+, D-) et le chip difficulte ;
///   - l'en-tete de totaux (distance, D+, jours, etapes) ;
///   - l'etat vide (aucune etape) ;
///   - PART A : aller sur Itineraire via `context.push` puis REVENIR sans
///     exception (le crash d'origine venait de `context.go('/map')` qui vidait
///     la pile -> `currentConfiguration.isNotEmpty`).
void main() {
  const stageA = StageModel(
    trailId: 'test-trail',
    stageNumber: 1,
    name: 'Depart - Refuge B',
    distanceKm: 14.5,
    elevationGainM: 850,
    elevationLossM: 620,
    startLat: 42.10,
    startLng: 9.05,
    endLat: 42.15,
    endLng: 9.10,
    difficulty: 'hard',
  );

  const stageB = StageModel(
    trailId: 'test-trail',
    stageNumber: 2,
    name: 'Refuge B - Refuge C',
    distanceKm: 12.0,
    elevationGainM: 600,
    elevationLossM: 500,
    startLat: 42.15,
    startLng: 9.10,
    endLat: 42.20,
    endLng: 9.15,
    difficulty: 'moderate',
  );

  final mockDays = [
    const ItineraryDay(
      dayNumber: 1,
      stages: [stageA, stageB],
      totalDistance: 26.5,
      totalElevation: 1450,
      estimatedHours: 7.5,
    ),
  ];

  Override daysOverride(List<ItineraryDay> days) =>
      itineraryProvider.overrideWith((ref) => Future.value(days));

  group('ItineraryScreen — deroule des etapes (parite GR20)', () {
    testWidgets('affiche le deroule des etapes avec infos par etape',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [daysOverride(mockDays)],
          child: const MaterialApp(
            home: ItineraryScreen(trailId: 'test-trail'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Jour deroule (jour 1 ouvert par defaut) -> etapes visibles.
      expect(find.text('${t.itinerary.day} 1'), findsOneWidget);
      expect(find.text('Depart - Refuge B'), findsOneWidget);
      expect(find.text('Refuge B - Refuge C'), findsOneWidget);

      // Infos par etape : distance + D+ + D- (parite GR20).
      expect(find.text('14.5 km'), findsOneWidget);
      expect(find.text('850 m'), findsOneWidget); // D+ etape A
      expect(find.text('620 m'), findsOneWidget); // D- etape A

      // Chip difficulte (semantique) present.
      expect(find.text(t.stage.difficulty.hard), findsOneWidget);
      expect(find.text(t.stage.difficulty.moderate), findsOneWidget);
    });

    testWidgets('affiche l en-tete de totaux (distance, D+, jours, etapes)',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [daysOverride(mockDays)],
          child: const MaterialApp(
            home: ItineraryScreen(trailId: 'test-trail'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 26.5 -> arrondi 27 km ; D+ total 1450 m.
      expect(find.text('27 km'), findsOneWidget);
      expect(find.text('1450 m'), findsOneWidget);
    });

    testWidgets('affiche l etat vide quand aucune etape', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [daysOverride(const [])],
          child: const MaterialApp(
            home: ItineraryScreen(trailId: 'test-trail'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.itinerary.empty), findsOneWidget);
    });
  });

  group('PART A — bug nav : retour depuis Itineraire (non-regression)', () {
    testWidgets(
        'push Itineraire puis retour revient au HUB sans exception',
        (tester) async {
      // Router minimal : /home (stub HUB avec la carte Itineraire) +
      // /trail/:id/itinerary (l ecran reel). Reproduit le chemin du HUB :
      // le tap fait `context.push` (et NON `context.go('/map')`).
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => Scaffold(
              appBar: AppBar(title: const Text('HUB-HOME')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () =>
                      context.push('/trail/test-trail/itinerary'),
                  child: const Text('Itineraire'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/trail/:id/itinerary',
            builder: (context, state) =>
                const ItineraryScreen(trailId: 'test-trail'),
          ),
          // Cible neutre pour prouver qu on ne bascule PAS vers la carte.
          GoRoute(
            path: '/map',
            builder: (context, state) => const Scaffold(body: Text('MAP')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [daysOverride(mockDays)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Depart : HUB.
      expect(find.text('HUB-HOME'), findsOneWidget);

      // Aller sur Itineraire.
      await tester.tap(find.text('Itineraire'));
      await tester.pumpAndSettle();
      expect(find.text(t.itinerary.title), findsOneWidget);
      expect(find.text('Depart - Refuge B'), findsOneWidget);

      // RETOUR : bouton back de l AppBar. Ne doit PAS lever d exception
      // (le bug d origine : "You have popped the last page off of the stack").
      await tester.pageBack();
      await tester.pumpAndSettle();

      // On est revenu au HUB, proprement, sans bascule vers la carte.
      expect(find.text('HUB-HOME'), findsOneWidget);
      expect(find.text('MAP'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
