import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/data/arrival_detection_service.dart';
import 'package:moteur_gr/features/trek/domain/models/trek_session.dart';
import 'package:moteur_gr/features/trek/domain/trek_completion.dart';
import 'package:moteur_gr/features/trek/providers/gps_providers.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';

/// GO-85 inc2 — PORTE DU FINISHER + persistance ALPHA (port GR20 #97501 B).
///
/// Ces tests prouvent le fix du bug « demi-tour felicite » cote StepWays au
/// niveau du gestionnaire de session ([TrekSessionManagerNotifier]) :
///
///  - un parcours REELLEMENT marche integralement -> la porte s'ouvre, le trek
///    se termine (finish), et [TrekSession.parcoursFullyWalked] est fige a vrai ;
///  - un demi-tour / une arrivee opportuniste (derniere etape touchee mais
///    etapes intermediaires manquantes) -> la porte reste FERMEE : pas de
///    finish, pas de felicitations, la session reste active.
///
/// [recordStageCompleted] et [completeOnArrival] sont exerces reellement ;
/// seul [stop] (isolate GPS de fond, permissions, DAOs) est neutralise et
/// instrumente via [_GateNotifier], pour isoler la logique de gate.
void main() {
  /// Cree une session active minimale, eventuellement avec des etapes deja
  /// completees (retro-compat : defaut = aucune).
  TrekSession _activeSession({List<String> completed = const []}) {
    return TrekSession(
      id: 'sess-gate-001',
      trailId: 'sentier-test',
      startedAt: DateTime.utc(2026, 6, 15, 8),
      status: 'active',
      completedStages: completed,
    );
  }

  /// Etat de tracking « en cours » portant [session].
  TrackingSessionState _recording(TrekSession session) => TrackingSessionState(
        status: TrackingSessionStatus.recording,
        session: session,
      );

  group('recordStageCompleted — persistance ALPHA des etapes marchees', () {
    test('ajoute chaque etape completee sur la session (sans doublon)', () {
      final container = ProviderContainer(
        overrides: [
          trekSessionManagerProvider.overrideWith(
            () => _GateNotifier(_recording(_activeSession())),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(trekSessionManagerProvider.notifier);

      notifier.recordStageCompleted('s1');
      notifier.recordStageCompleted('s2');
      notifier.recordStageCompleted('s1'); // doublon ignore

      final session = container.read(trekSessionManagerProvider).session;
      expect(session?.completedStages, ['s1', 's2']);
    });

    test('ignore l enregistrement hors session active', () {
      final container = ProviderContainer(
        overrides: [
          trekSessionManagerProvider.overrideWith(
            () => _GateNotifier(const TrackingSessionState()),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(trekSessionManagerProvider.notifier);
      notifier.recordStageCompleted('s1');

      expect(container.read(trekSessionManagerProvider).session, isNull);
    });
  });

  group('completeOnArrival — porte du finisher', () {
    test('parcours entierement marche -> FINISH + parcoursFullyWalked=true', () {
      // Toutes les etapes du parcours ont ete completees : la gate (calculee en
      // amont par le pont d'arrivee) est ouverte.
      final container = ProviderContainer(
        overrides: [
          trekSessionManagerProvider.overrideWith(
            () => _GateNotifier(
              _recording(_activeSession(completed: ['s1', 's2', 's3'])),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier =
          container.read(trekSessionManagerProvider.notifier) as _GateNotifier;

      notifier.completeOnArrival(fullyWalked: true);

      // La porte s'est ouverte : parcoursFullyWalked fige a vrai AVANT stop...
      expect(notifier.fullyWalkedAtStop, isTrue,
          reason: 'Le finisher legitime doit marquer la session fully walked.');
      // ... et le trek a bien ete finalise (stop appele une fois).
      expect(notifier.stopCallCount, 1);
    });

    test('demi-tour (fullyWalked=false) -> AUCUN finish, session preservee', () {
      // Derniere etape touchee mais intermediaires manquantes : gate fermee.
      final container = ProviderContainer(
        overrides: [
          trekSessionManagerProvider.overrideWith(
            () => _GateNotifier(
              _recording(_activeSession(completed: ['s1', 's3'])),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier =
          container.read(trekSessionManagerProvider.notifier) as _GateNotifier;

      notifier.completeOnArrival(fullyWalked: false);

      // Porte fermee : pas de stop, pas de felicitations.
      expect(notifier.stopCallCount, 0,
          reason: 'Un demi-tour ne doit jamais terminer le trek.');
      final session = container.read(trekSessionManagerProvider).session;
      expect(session, isNotNull);
      expect(session!.status, 'active',
          reason: 'La session reste active apres un demi-tour.');
      expect(session.parcoursFullyWalked, isFalse,
          reason: 'Pas de finisher => parcoursFullyWalked reste faux.');
    });

    test('idempotent hors session active (deja arrete) -> no-op', () {
      final container = ProviderContainer(
        overrides: [
          trekSessionManagerProvider.overrideWith(
            () => _GateNotifier(const TrackingSessionState(
              status: TrackingSessionStatus.stopped,
            )),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier =
          container.read(trekSessionManagerProvider.notifier) as _GateNotifier;
      notifier.completeOnArrival(fullyWalked: true);

      expect(notifier.stopCallCount, 0);
    });
  });

  // Bout-en-bout du PONT d'arrivee (arrivalCompletionListenerProvider) : on
  // pilote de vrais ArrivalEvent dans le sens de marche et on verifie que la
  // porte du finisher n'est franchie que si toutes les etapes sont marchees.
  group('arrivalCompletionListenerProvider — pont arrivee -> gate finisher', () {
    // Parcours NS a 3 etapes : s1 -> s2 -> s3 (s3 = derniere reelle).
    const plan = TrekPlan(
      orderedStageIds: ['s1', 's2', 's3'],
      direction: 'NS',
      isFullTrail: true,
    );

    ProviderContainer makeContainer(StreamController<ArrivalEvent> ctrl) {
      final container = ProviderContainer(
        overrides: [
          currentTrekPlanProvider.overrideWithValue(plan),
          arrivalEventsProvider.overrideWith((ref) => ctrl.stream),
          trekSessionManagerProvider.overrideWith(
            () => _GateNotifier(_recording(_activeSession())),
          ),
        ],
      );
      // Active le pont (sinon le listener ne tourne pas).
      container.listen(arrivalCompletionListenerProvider, (_, __) {});
      return container;
    }

    ArrivalEvent evt(String stageId, {required bool isFinal}) => ArrivalEvent(
          type: isFinal ? 'trailEnd' : 'stageEnd',
          stageId: stageId,
          timestamp: DateTime.now(),
        );

    test('parcours entier marche (s1,s2 puis trailEnd s3) -> FINISH', () async {
      final ctrl = StreamController<ArrivalEvent>();
      final container = makeContainer(ctrl);
      addTearDown(() {
        container.dispose();
        ctrl.close();
      });
      final notifier =
          container.read(trekSessionManagerProvider.notifier) as _GateNotifier;

      ctrl.add(evt('s1', isFinal: false));
      ctrl.add(evt('s2', isFinal: false));
      ctrl.add(evt('s3', isFinal: true)); // derniere reelle
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(
        container.read(trekSessionManagerProvider).session?.completedStages,
        containsAll(<String>['s1', 's2', 's3']),
      );
      expect(notifier.stopCallCount, 1,
          reason: 'Parcours complet marche -> la porte s ouvre, finish.');
      expect(notifier.fullyWalkedAtStop, isTrue);
    });

    test('demi-tour (s1 puis trailEnd s3, s2 jamais marchee) -> AUCUN finish',
        () async {
      final ctrl = StreamController<ArrivalEvent>();
      final container = makeContainer(ctrl);
      addTearDown(() {
        container.dispose();
        ctrl.close();
      });
      final notifier =
          container.read(trekSessionManagerProvider.notifier) as _GateNotifier;

      // Le randonneur marche s1, revient a s3 par un raccourci/arrivee
      // opportuniste : s2 (intermediaire) n'est JAMAIS completee.
      ctrl.add(evt('s1', isFinal: false));
      ctrl.add(evt('s3', isFinal: true));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final session = container.read(trekSessionManagerProvider).session;
      expect(session?.completedStages, containsAll(<String>['s1', 's3']));
      expect(session?.completedStages, isNot(contains('s2')));
      expect(notifier.stopCallCount, 0,
          reason: 'Etape intermediaire manquante -> porte fermee, pas de '
              'finish ni felicitations.');
      expect(session?.status, 'active');
    });
  });

  group('TrekSession — serialisation retro-compatible (persistance ALPHA)', () {
    test('JSON legacy sans nouveaux champs -> defauts surs (pas de faux '
        'finisher)', () {
      final legacy = TrekSession.fromJson(<String, dynamic>{
        'id': 'legacy-1',
        'trailId': 'sentier-x',
        'startedAt': '2026-06-01T08:00:00.000Z',
        'status': 'completed',
      });
      expect(legacy.completedStages, isEmpty);
      expect(legacy.parcoursFullyWalked, isFalse);
    });

    test('round-trip toJson/fromJson preserve etapes + flag', () {
      final session = TrekSession(
        id: 'rt-1',
        trailId: 'sentier-y',
        startedAt: DateTime.utc(2026, 6, 2, 9),
        finishedAt: DateTime.utc(2026, 6, 4, 17),
        status: 'completed',
        completedStages: const ['s1', 's2', 's3'],
        parcoursFullyWalked: true,
      );
      final restored = TrekSession.fromJson(session.toJson());
      expect(restored.completedStages, ['s1', 's2', 's3']);
      expect(restored.parcoursFullyWalked, isTrue);
      expect(restored, session);
    });
  });
}

/// Notifier de test : garde les vrais [recordStageCompleted] /
/// [completeOnArrival] (la logique de gate a prouver) et neutralise [stop]
/// (dependances lourdes : isolate GPS de fond, permissions, DAOs Drift).
///
/// Instrumente le nombre d'appels a [stop] et l'etat `parcoursFullyWalked` de
/// la session au moment ou [stop] est declenche, pour verifier que la porte du
/// finisher fige bien le flag AVANT de finaliser.
class _GateNotifier extends TrekSessionManagerNotifier {
  _GateNotifier(this._initial);
  final TrackingSessionState _initial;

  /// Nombre de fois ou [stop] a ete declenche (0 = pas de finish).
  int stopCallCount = 0;

  /// Valeur de `parcoursFullyWalked` sur la session au moment du stop.
  bool? fullyWalkedAtStop;

  @override
  TrackingSessionState build() => _initial;

  @override
  Future<void> stop() async {
    stopCallCount++;
    fullyWalkedAtStop = state.session?.parcoursFullyWalked;
    // Simule la finalisation sans toucher aux services reels.
    state = state.copyWith(status: TrackingSessionStatus.stopped);
  }
}
