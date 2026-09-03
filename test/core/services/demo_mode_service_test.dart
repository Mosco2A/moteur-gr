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

  // PARITE GR20, LOT 2 (2.A, #99433) — debridage de la VITRINE.
  group('DemoModeService -- vitrine debloquee (LOT 2)', () {
    test('vitrine NON bridee sans achat, autre sentier non achete BRIDE',
        () async {
      // Aucun achat. La vitrine est declaree via injection (equivaut au flag
      // TrailConfig.isShowcaseTrail derive du catalogue), zero hardcode ici.
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = DemoModeService(
        prefs: prefs,
        showcaseTrailIds: {'vitrine-demo'},
      );

      // Vitrine : DEBRIDEE (GPS + journal jouables, pas de bandeau demo) meme
      // sans achat.
      expect(service.isShowcaseTrail('vitrine-demo'), isTrue);
      expect(service.isDemoMode('vitrine-demo'), isFalse);
      expect(service.isGpsEnabled('vitrine-demo'), isTrue);
      expect(service.isJournalReadOnly('vitrine-demo'), isFalse);
      expect(service.shouldShowDemoBanner('vitrine-demo'), isFalse);

      // GARDE-FOU : un AUTRE sentier non achete reste BRIDE (modele a la carte
      // intact).
      expect(service.isDemoMode('sentier-payant'), isTrue);
      expect(service.isGpsEnabled('sentier-payant'), isFalse);
      expect(service.isJournalReadOnly('sentier-payant'), isTrue);
    });

    test('le sentier par defaut du catalogue est la vitrine (defaultTrail)',
        () async {
      // Sans injection : la source est le catalogue reel (flag isShowcaseTrail).
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = DemoModeService(prefs: prefs);

      final defaultId = TrailCatalog.defaultTrail.id;
      expect(TrailCatalog.defaultTrail.isShowcaseTrail, isTrue,
          reason: 'La vitrine par defaut porte le flag isShowcaseTrail.');
      expect(service.isDemoMode(defaultId), isFalse,
          reason: 'La vitrine par defaut est jouable sans achat.');
      expect(service.isGpsEnabled(defaultId), isTrue);
    });
  });
}
