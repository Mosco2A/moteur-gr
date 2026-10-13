// LA CLE `stage` DE LA FICHE HEBERGEMENT NE VAUT JAMAIS LA CHAINE "null"
// (lot 645-09b, reserve (b) de la QA d'Artemis du 04/10/2026).
//
// LE DEFAUT. L'ecran recoit un numero d'etape FACULTATIF (`int? stageNumber`)
// et affiche l'etape 1 quand il est absent (`stageNumber ?? 1`). Le lot 645-09
// passait `stage: '$stageNumber'` : absent, la cle `stage` d'un rapport de
// plantage valait la chaine "null" pendant que l'ecran montrait l'etape 1 —
// une valeur qui n'existe nulle part, ni a l'ecran ni dans les donnees.
//
// LA REGLE. Champ absent : la cle n'est PAS posee (le service ne pose `stage`
// que si on lui en donne une). Champ present : la cle porte le numero.
//
// LES TROIS AUTRES PORTEURS DE `stage` N'ONT PAS CE CAS, ET C'EST LE TYPE QUI
// LE GARANTIT : `trail_stage_detail` et `weather` portent `int stageNumber`,
// `trek_stage_detail` porte `int stageId` — non nullables, donc jamais "null".
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/analytics/analytics_service.dart';
import 'package:moteur_gr/core/analytics/screen_breadcrumb.dart';
import 'package:moteur_gr/features/trek/presentation/accommodation_detail_screen.dart';

/// Un puits crash qui NOTE les cles qu'on lui pose.
class _PuitsNoteur implements CrashSink {
  final cles = <String, String>{};

  @override
  Future<void> log(String message) async {}
  @override
  Future<void> setCustomKey(String key, String value) async =>
      cles[key] = value;
  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required bool fatal,
  }) async {}
  @override
  Future<void> setCollectionEnabled(bool enabled) async {}
}

void main() {
  Future<_PuitsNoteur> monter(WidgetTester tester, {int? stageNumber}) async {
    final puits = _PuitsNoteur();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accommodationsByStageProvider.overrideWith(
            (ref, stage) async => const [],
          ),
          analyticsServiceProvider.overrideWithValue(
            AnalyticsService(
              analytics: const NoOpAnalyticsSink(),
              crash: puits,
            ),
          ),
        ],
        child: MaterialApp(
          home: AccommodationDetailScreen(stageNumber: stageNumber),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return puits;
  }

  group('645-09b (b) — la fiche hebergement et sa cle stage', () {
    testWidgets('etape ABSENTE : la cle stage n est pas posee', (tester) async {
      final puits = await monter(tester);

      expect(
        puits.cles[AnalyticsKeys.screen],
        ScreenBreadcrumb.accommodationDetail.name,
      );
      expect(
        puits.cles.containsKey(AnalyticsKeys.stage),
        isFalse,
        reason:
            'la cle stage vaut "${puits.cles[AnalyticsKeys.stage]}" alors '
            'qu aucune etape n a ete donnee',
      );
    });

    testWidgets('etape PRESENTE : la cle stage porte son numero', (
      tester,
    ) async {
      final puits = await monter(tester, stageNumber: 3);

      expect(puits.cles[AnalyticsKeys.stage], '3');
    });
  });
}
