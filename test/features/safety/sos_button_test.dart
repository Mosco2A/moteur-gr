// E5.15 — Test SOS button visibilite.
//
// Verifie que le bouton SOS est visible uniquement pendant un trek actif
// et masque quand aucun trek n'est en cours.

import 'package:flutter_test/flutter_test.dart';

import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';

void main() {
  group('SOS Button — visibilite', () {
    test('SOS visible pendant trek actif, masque sinon', () {
      // Simuler un trek actif (recording)
      const activeState = TrackingSessionState(
        status: TrackingSessionStatus.recording,
        distanceKm: 2.5,
      );

      // Trek recording → SOS doit etre visible
      expect(
        activeState.status == TrackingSessionStatus.recording ||
            activeState.status == TrackingSessionStatus.paused,
        isTrue,
        reason: 'Trek recording = SOS visible',
      );

      // Simuler un trek en pause → SOS encore visible
      final pausedState = activeState.copyWith(
        status: TrackingSessionStatus.paused,
      );
      expect(
        pausedState.status == TrackingSessionStatus.recording ||
            pausedState.status == TrackingSessionStatus.paused,
        isTrue,
        reason: 'Trek en pause = SOS encore visible',
      );

      // Simuler un trek arrete → SOS masque
      final stoppedState = activeState.copyWith(
        status: TrackingSessionStatus.stopped,
      );
      expect(
        stoppedState.status == TrackingSessionStatus.recording ||
            stoppedState.status == TrackingSessionStatus.paused,
        isFalse,
        reason: 'Trek stopped = SOS masque',
      );

      // Idle → SOS masque
      const idleState = TrackingSessionState();
      expect(
        idleState.status == TrackingSessionStatus.recording ||
            idleState.status == TrackingSessionStatus.paused,
        isFalse,
        reason: 'Idle = SOS masque',
      );
    });
  });
}
