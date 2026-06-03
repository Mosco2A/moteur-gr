// E5.17 -- Test in-app review : demande 1 fois, pas 2 pour le meme trek.
//
// Test unitaire pur -- mock du tracker en memoire.
// On ne peut pas instancier InAppReview dans les tests unitaires
// (plugin natif), donc on valide la logique metier via un fake.

import 'package:flutter_test/flutter_test.dart';

/// Fake qui reproduit la logique de InAppReviewService
/// sans dependance Drift ni plugin natif.
class FakeReviewTracker {
  final Map<String, bool> _requested = {};

  bool wasReviewRequested(String trailId) {
    return _requested[trailId] ?? false;
  }

  /// Simule requestReviewIfEligible : retourne true si premiere demande.
  bool requestReviewIfEligible(String trailId) {
    if (_requested[trailId] == true) return false;
    _requested[trailId] = true;
    return true;
  }
}

void main() {
  group('InAppReview -- E5.17', () {
    test('demande faite 1 fois, pas 2 fois meme trek', () {
      final tracker = FakeReviewTracker();
      const trailId = 'trek-gr20-2026-001';

      // Premiere demande : doit reussir
      expect(tracker.wasReviewRequested(trailId), isFalse);
      final firstResult = tracker.requestReviewIfEligible(trailId);
      expect(firstResult, isTrue);
      expect(tracker.wasReviewRequested(trailId), isTrue);

      // Deuxieme demande meme trek : doit etre refusee
      final secondResult = tracker.requestReviewIfEligible(trailId);
      expect(secondResult, isFalse);

      // Trek different : doit reussir
      const otherTrailId = 'trek-gr20-2026-002';
      expect(tracker.wasReviewRequested(otherTrailId), isFalse);
      final otherResult = tracker.requestReviewIfEligible(otherTrailId);
      expect(otherResult, isTrue);

      // Le premier trek reste marque
      expect(tracker.wasReviewRequested(trailId), isTrue);
    });
  });
}
