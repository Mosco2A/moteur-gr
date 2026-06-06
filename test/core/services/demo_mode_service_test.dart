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
}
