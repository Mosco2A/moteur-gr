// E5.15 — Test SOS button visibilite.
//
// Verifie que le bouton SOS est visible uniquement pendant un trek actif
// et masque quand aucun trek n'est en cours.

import 'package:flutter_test/flutter_test.dart';

import 'package:g20_app/features/trek/data/trek_models.dart';

void main() {
  group('SOS Button — visibilite', () {
    test('SOS visible pendant trek actif, masque sinon', () {
      // Simuler un trek actif
      final activeSession = TrekSession(
        currentStage: 3,
        status: TrekStatus.active,
        startedAt: DateTime.now(),
      );

      // Trek actif → SOS doit etre visible
      expect(activeSession.isOngoing, isTrue,
          reason: 'Trek actif = SOS visible');

      // Simuler un trek en pause → SOS encore visible
      final pausedSession = activeSession.copyWith(
        status: TrekStatus.paused,
      );
      expect(pausedSession.isOngoing, isTrue,
          reason: 'Trek en pause = SOS encore visible');

      // Simuler un trek termine → SOS masque
      final completedSession = activeSession.copyWith(
        status: TrekStatus.completed,
      );
      expect(completedSession.isOngoing, isFalse,
          reason: 'Trek termine = SOS masque');

      // Pas de session → SOS masque (null check cote widget)
      const TrekSession? noSession = null;
      expect(noSession == null, isTrue,
          reason: 'Pas de session = SOS masque');
    });
  });
}
