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

/// ACCORD SINGULIER / PLURIEL DU NOMBRE D'ETAPES — tache 560, defaut N4
/// (campagne personas 559, rapport #100474).
///
/// CE QUI S'AFFICHAIT : « 1 etapes ». La cle `itinerary.stageCount` valait
/// « {count} etapes » et le nombre y etait substitue A LA MAIN
/// (`replaceAll('{count}', ...)`) : le pluriel etait ECRIT EN DUR dans la
/// traduction, donc faux des qu'il n'y avait qu'une etape — et faux dans les
/// cinq langues a la fois.
///
/// CE QUI EST TESTE : le MECANISME, pas une chaine. La cle est devenue un
/// pluriel Slang, chaque langue applique donc sa regle CLDR par son resolveur
/// integre. Ce fichier verifie les deux choses que seul le mecanisme peut
/// garantir : la forme change entre 1 et plusieurs, DANS LES CINQ LANGUES, et
/// l'ecran affiche bien la forme accordee.
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

  Override daysOverride(List<ItineraryDay> days) =>
      itineraryProvider.overrideWith((ref) => Future.value(days));

  Widget wrap(String trailId) => MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/itinerary',
          routes: [
            GoRoute(
              path: '/itinerary',
              builder: (_, __) => ItineraryScreen(trailId: trailId),
            ),
            GoRoute(path: '/my-treks', builder: (_, __) => const SizedBox()),
          ],
        ),
      );

  setUp(() => LocaleSettings.setLocaleRaw('fr'));
  tearDown(() => LocaleSettings.setLocaleRaw('fr'));

  group('N4 — le nombre d etapes s accorde', () {
    test('une etape et plusieurs etapes ne s ecrivent PAS pareil, dans les '
        'cinq langues', () {
      for (final locale in AppLocale.values) {
        LocaleSettings.setLocaleRaw(locale.languageCode);
        final une = t.itinerary.stageCount(n: 1);
        final plusieurs = t.itinerary.stageCount(n: 7);

        // Le nombre est bien injecte (pas de gabarit reste en place).
        expect(une, contains('1'),
            reason: '${locale.languageCode} : le nombre manque');
        expect(plusieurs, contains('7'));
        expect(une, isNot(contains('{')),
            reason: '${locale.languageCode} : gabarit non substitue');
        expect(plusieurs, isNot(contains('{')));

        // ET LA FORME CHANGE. C'est tout le defaut : « 1 etapes ».
        final singulier = une.replaceAll('1', '').trim();
        final pluriel = plusieurs.replaceAll('7', '').trim();
        expect(singulier, isNot(equals(pluriel)),
            reason: '${locale.languageCode} : « $une » et « $plusieurs » '
                'portent le MEME mot — le pluriel n est pas accorde');
      }
    });

    test('le francais accorde 0 comme 1 (regle CLDR fr), l anglais non', () {
      LocaleSettings.setLocaleRaw('fr');
      expect(t.itinerary.stageCount(n: 0).replaceAll('0', '').trim(),
          t.itinerary.stageCount(n: 1).replaceAll('1', '').trim());
      LocaleSettings.setLocaleRaw('en');
      expect(t.itinerary.stageCount(n: 0).replaceAll('0', '').trim(),
          isNot(t.itinerary.stageCount(n: 1).replaceAll('1', '').trim()));
    });

    testWidgets('l ecran affiche « 1 etape » et non « 1 etapes »',
        (tester) async {
      final unSeulJour = [
        const ItineraryDay(
          dayNumber: 1,
          stages: [stageA],
          totalDistance: 14.5,
          totalElevation: 850,
          estimatedHours: 5.75,
        ),
      ];
      await tester.pumpWidget(ProviderScope(
        overrides: [daysOverride(unSeulJour)],
        child: wrap('test-trail'),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining(t.itinerary.stageCount(n: 1)), findsOneWidget);
      // Le defaut exact de la campagne, nomme : plus jamais « 1 etapes ».
      expect(find.textContaining('1 ${t.itinerary.stages.toLowerCase()}s'),
          findsNothing);
      expect(find.textContaining('1 étapes'), findsNothing);
    });

    testWidgets('deux etapes restent au pluriel', (tester) async {
      final deuxEtapes = [
        const ItineraryDay(
          dayNumber: 1,
          stages: [stageA, stageB],
          totalDistance: 26.5,
          totalElevation: 1450,
          estimatedHours: 7.5,
        ),
      ];
      await tester.pumpWidget(ProviderScope(
        overrides: [daysOverride(deuxEtapes)],
        child: wrap('test-trail'),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining(t.itinerary.stageCount(n: 2)), findsOneWidget);
    });
  });
}
