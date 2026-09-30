// E5.18 -- Tests mode demo universel (R1.8).
//
// VRAIS tests : SharedPreferences mocke via setMockInitialValues,
// service reellement instancie. Fixtures : sentiers FICTIFS.
//
// 2 tests spec V8 :
// - isDemoMode true si trek pas achete meme user premium
// - isDemoMode false si trek achete (chemin "achete" COUVERT)

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/core/config/trail_catalog.dart';
import 'package:moteur_gr/core/services/demo_mode_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DemoModeService -- R1.8', () {
    test('isDemoMode true si trek pas achete meme user premium', () async {
      // Prefs mockees SANS achat
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = DemoModeService(prefs: prefs);

      // Aucun sentier achete => tout en demo
      expect(service.isDemoMode('sentier-volcans'), isTrue);
      expect(service.isDemoMode('sentier-crete'), isTrue);

      // Le statut premium n'entre pas en jeu :
      // pas de notion de "premium global" — tout est par trailId.
      expect(service.isDemoMode('un-autre-sentier'), isTrue);

      // Limites du mode demo actives
      expect(service.shouldShowDemoBanner('sentier-volcans'), isTrue);
      expect(service.isGpsEnabled('sentier-volcans'), isFalse);
      expect(service.isJournalReadOnly('sentier-volcans'), isTrue);
    });

    test('isDemoMode false si trek achete', () async {
      // Prefs mockees AVEC un achat : le chemin "achete" est couvert
      SharedPreferences.setMockInitialValues({
        'purchased_trail_ids': <String>['sentier-volcans'],
      });
      final prefs = await SharedPreferences.getInstance();
      final service = DemoModeService(prefs: prefs);

      // Sentier achete => PAS en demo
      expect(service.isDemoMode('sentier-volcans'), isFalse);
      expect(service.getPurchasedTrails(), contains('sentier-volcans'));

      // Toutes les limites demo levees pour le sentier achete
      expect(service.shouldShowDemoBanner('sentier-volcans'), isFalse);
      expect(service.isGpsEnabled('sentier-volcans'), isTrue);
      expect(service.isJournalReadOnly('sentier-volcans'), isFalse);

      // Un sentier NON achete reste en demo (universel, par trailId)
      expect(service.isDemoMode('sentier-crete'), isTrue);
      expect(service.isGpsEnabled('sentier-crete'), isFalse);
    });
  });

  // TACHE 601 — CE SERVICE NE PORTE PLUS AUCUNE EXEMPTION.
  //
  // Il en portait une : un sentier declare « vitrine » n'etait JAMAIS en mode
  // demo, meme non achete. Ce drapeau avait ete invente pour corriger une
  // divergence relevee par un audit de parite, puis attribue a Christophe dans
  // un commentaire de code alors qu'aucune decision ne le soutenait.
  //
  // CE QUE CES TESTS VERROUILLENT : ce service ne repond plus qu'a UNE question
  // — ce trek a-t-il ete debloque ? Les sentiers GRATUITS ne passent pas par
  // ici : leur jouabilite est resolue par `MonetizationService.accessFor`, qui
  // lit leur PRIX. Une seule reponse, un seul endroit.
  group('DemoModeService -- aucune exemption (tache 601)', () {
    test('AUCUN sentier n echappe au mode demo sans achat, pas meme le '
        'sentier GRATUIT du catalogue', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = DemoModeService(prefs: prefs);

      // Le catalogue porte bien un sentier gratuit. TACHE 638 : ce n'est plus le
      // « Mare a Mare Centre Demo » (supprime avec le doublon du bug 1 et
      // l'amputation du bug 8) mais le sentier des Volcans. Ce qui compte ici est
      // inchange : le niveau GRATUIT du modele eco a une INSTANCE, et il n'a
      // toujours aucune exemption posee sur un sentier payant.
      expect(
        TrailCatalog.freeIds,
        isNotEmpty,
        reason:
            'le niveau gratuit du modele repose sur un sentier au PRIX '
            'NUL, pas sur une exemption posee sur un sentier payant',
      );
      expect(
        TrailCatalog.freeIds,
        isNot(contains('mare-a-mare-centre')),
        reason:
            'le Mare a Mare Centre est PAYANT, et la demo ne le rend pas '
            'gratuit : elle montre, elle ne debloque rien',
      );

      for (final id in TrailCatalog.ids) {
        expect(
          service.isDemoMode(id),
          isTrue,
          reason:
              'sans achat et sans delegue, ce service repond « demo » '
              'pour TOUS les sentiers, y compris $id. Il n a plus de liste '
              'de privilegies a consulter',
        );
      }
    });

    test('le sentier par defaut du catalogue est PAYANT (il est redevenu '
        'vendable)', () async {
      expect(
        TrailCatalog.defaultTrail.isFreeTrail,
        isFalse,
        reason:
            'le Mare a Mare portait le drapeau vitrine, qui le rendait '
            'jouable et sans-pub sans achat : il etait INVENDABLE. Le sentier '
            'par defaut est de nouveau un sentier payant',
      );
      expect(
        TrailCatalog.defaultTrail.priceInStages,
        TrailCatalog.defaultTrail.totalStages,
        reason: 'son prix vaut une etape par etape — le defaut du modele',
      );
    });

    test('le delegue de droits fait foi quand il est cable', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = DemoModeService(
        prefs: prefs,
        demoResolver: (trailId) async => trailId != 'debloque',
      );

      expect(await service.isDemoModeAsync('debloque'), isFalse);
      expect(await service.isDemoModeAsync('autre'), isTrue);
    });
  });
}
