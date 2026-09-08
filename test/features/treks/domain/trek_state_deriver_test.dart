import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/domain/models/trek_session.dart';
import 'package:moteur_gr/features/treks/domain/trek_lifecycle_state.dart';
import 'package:moteur_gr/features/treks/domain/trek_state_deriver.dart';

/// StepWays LOT 2, §1 — derivation PURE de l'etat-trek.
///
/// Prouve la priorite inProgress > completed > prepared > owned et la regle
/// « abandoned -> retombe prepared » (trek rejouable), sans aucune base.
void main() {
  TrekSession session(String status) => TrekSession(
        id: 'sess-1',
        trailId: 'gr20',
        startedAt: DateTime.utc(2026, 6, 15, 8),
        status: status,
      );

  group('deriveState — priorite inProgress > completed > prepared > owned', () {
    test('session active -> inProgress (prioritaire)', () {
      expect(
        deriveState(
          latestSession: session(kSessionStatusActive),
          // Meme avec de la planif, inProgress prime.
          hasPlanningOrProgress: true,
        ),
        TrekLifecycleState.inProgress,
      );
    });

    test('session paused -> inProgress (paused compte comme en cours, C4)', () {
      expect(
        deriveState(
          latestSession: session(kSessionStatusPaused),
          hasPlanningOrProgress: false,
        ),
        TrekLifecycleState.inProgress,
      );
    });

    test('derniere session completed -> completed', () {
      expect(
        deriveState(
          latestSession: session(kSessionStatusCompleted),
          hasPlanningOrProgress: true,
        ),
        TrekLifecycleState.completed,
      );
    });

    test('planif/progression sans session en cours -> prepared', () {
      expect(
        deriveState(
          latestSession: null,
          hasPlanningOrProgress: true,
        ),
        TrekLifecycleState.prepared,
      );
    });

    test('rien fait (ni session ni planif) -> owned', () {
      expect(
        deriveState(
          latestSession: null,
          hasPlanningOrProgress: false,
        ),
        TrekLifecycleState.owned,
      );
    });
  });

  group('deriveState — abandon retombe prepared (rejouable)', () {
    test('derniere session abandoned -> prepared, PAS completed', () {
      expect(
        deriveState(
          latestSession: session(kSessionStatusAbandoned),
          hasPlanningOrProgress: false,
        ),
        TrekLifecycleState.prepared,
        reason: 'Un abandon ne termine pas le trek : il retombe prepared.',
      );
    });

    test('abandon + planif -> prepared', () {
      expect(
        deriveState(
          latestSession: session(kSessionStatusAbandoned),
          hasPlanningOrProgress: true,
        ),
        TrekLifecycleState.prepared,
      );
    });
  });

  group('deriveState — robustesse (statut inconnu = non terminal)', () {
    test('statut inconnu avec de la matiere -> prepared (fail-safe)', () {
      expect(
        deriveState(
          latestSession: session('some-future-status'),
          hasPlanningOrProgress: false,
        ),
        TrekLifecycleState.prepared,
        reason: 'Un statut inconnu ne doit etre ni inProgress ni completed.',
      );
    });
  });
}
