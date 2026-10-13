// LA CLE `screen` SUIT L'ECRAN VISIBLE DANS L'APPLICATION REELLE (lot 645-09b).
//
// CE QUE CE TEST REJOUE. La traversee d'Artemis du 04/10/2026 empilait les
// ecrans sans jamais revenir, et apres l'ouverture de `/settings` le journal
// portait `settings`, puis `trail_stage_detail`, `weather`, `journal` : les
// ecrans instrumentes dans `build`, restes vivants sous la pile, reparlaient a
// tour de role. Ici, le VRAI routeur et les VRAIS ecrans, sans une surcharge
// hors du puits qui note :
//
//   1. on part du cockpit (`/home`, ecran A ETAT : miette dans `initState`) ;
//   2. on empile la meteo, le journal, puis les reglages (trois ecrans SANS
//      etat, miette dans `build`) — a chaque etage, la cle `screen` doit
//      nommer l'ecran du DESSUS, et le journal ne porter que les entrees ;
//   3. on depile jusqu'au cockpit — a chaque retour, la cle doit revenir a
//      l'ecran redevenu visible. Le dernier retour est celui que le filtre
//      seul ne savait pas faire : le cockpit pose sa miette dans `initState`,
//      et c'est l'observateur branche sur le routeur qui la repose.
//
// COMMENT IL ROUGIRAIT. Retirez le filtre de `observeScreenEntry` et l'etape 2
// rougit (une miette `weather` ou `journal` apres `settings`) ; debranchez
// `ScreenEntryObserver` du routeur et le dernier retour rougit (la cle reste
// sur `weather`).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/analytics/analytics_service.dart';
import 'package:moteur_gr/core/routing/app_router.dart';

import '../structurel/parcours_reel.dart';

/// Un puits crash qui NOTE ce qu'on lui pose : c'est le journal de ce test.
class _PuitsNoteur implements CrashSink {
  final cles = <String, String>{};
  final miettes = <String>[];

  @override
  Future<void> log(String message) async => miettes.add(message);
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
  testWidgets(
    'empiler puis depiler : la cle screen nomme toujours l ecran visible',
    (tester) async {
      final puits = _PuitsNoteur();
      await monterAppliReelle(
        tester,
        depart: '/home',
        surcharges: [
          analyticsServiceProvider.overrideWithValue(
            AnalyticsService(
              analytics: const NoOpAnalyticsSink(),
              crash: puits,
            ),
          ),
        ],
      );
      expect(cheminAffiche(), '/home');
      expect(puits.cles[AnalyticsKeys.screen], 'hub');

      // L'EMPILEMENT : trois ecrans sans etat au-dessus du cockpit.
      const etages = <String, String>{
        '/trail/mare-a-mare-centre/weather': 'weather',
        '/journal': 'journal',
        '/settings': 'settings',
      };
      for (final etage in etages.entries) {
        appRouter.push(etage.key);
        await stabiliser(tester);
        expect(
          puits.cles[AnalyticsKeys.screen],
          etage.value,
          reason:
              'apres l ouverture de ${etage.key}, la cle screen nomme un '
              'ecran cache. Journal : ${puits.miettes}',
        );
      }
      expect(puits.miettes, [
        'screen:hub',
        'screen:weather',
        'screen:journal',
        'screen:settings',
      ], reason: 'un ecran cache sous la pile a repose sa miette');

      // LE DEPILEMENT : chaque retour renomme l'ecran redevenu visible.
      for (final attendu in ['journal', 'weather', 'hub']) {
        appRouter.pop();
        await stabiliser(tester);
        expect(
          puits.cles[AnalyticsKeys.screen],
          attendu,
          reason:
              'retour sur $attendu : la cle screen nomme encore un ecran '
              'depile. Journal : ${puits.miettes}',
        );
      }
      expect(cheminAffiche(), '/home');
      expect(puits.miettes.last, 'screen:hub');

      await demonterAppli(tester);
    },
  );
}
