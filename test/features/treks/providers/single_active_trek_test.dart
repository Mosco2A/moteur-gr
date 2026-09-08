import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/trek/domain/models/trek_session.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';

/// StepWays LOT 2, C4 — machine d'unicite de rando active.
///
/// Prouve la garde [TrekSessionManagerNotifier.ensureSingleActiveThenStart] :
/// au plus 1 session active|paused, cross-trail, dialog Terminer/Abandonner
/// resolu via callback (aucune dependance UI). [start]/[stop]/[abandon] sont
/// instrumentes (les vrais toucheraient isolate GPS, permissions, recorder).
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  TrekSession ongoing({
    required String id,
    required String trailId,
    String status = 'active',
    DateTime? startedAt,
  }) =>
      TrekSession(
        id: id,
        trailId: trailId,
        startedAt: startedAt ?? DateTime.utc(2026, 6, 15, 8),
        status: status,
      );

  ProviderContainer makeContainer(_C4Notifier notifier) {
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      trekSessionManagerProvider.overrideWith(() => notifier),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  group('ensureSingleActiveThenStart — garde cross-trail', () {
    test('aucune session en cours -> demarrage direct', () async {
      final notifier = _C4Notifier(const TrackingSessionState());
      final container = makeContainer(notifier);
      final n = container.read(trekSessionManagerProvider.notifier);

      final outcome = await n.ensureSingleActiveThenStart(
        'gr20',
        resolve: (_) async {
          fail('Aucun conflit : le resolver ne doit pas etre appele.');
        },
      );

      expect(outcome, StartOutcome.started);
      expect(notifier.startedTrailIds, ['gr20']);
    });

    test('meme trek deja en cours -> idempotent, pas de demarrage', () async {
      await db.trekSessionsDao
          .upsertSession(ongoing(id: 's1', trailId: 'gr20'));
      final notifier = _C4Notifier(const TrackingSessionState());
      final container = makeContainer(notifier);
      final n = container.read(trekSessionManagerProvider.notifier);

      final outcome = await n.ensureSingleActiveThenStart(
        'gr20',
        resolve: (_) async =>
            fail('Meme trek : pas de dialog de conflit attendu.'),
      );

      expect(outcome, StartOutcome.alreadyActiveSameTrail);
      expect(notifier.startedTrailIds, isEmpty);
    });

    test('autre trek en cours + ANNULER -> non demarre, rien solde', () async {
      await db.trekSessionsDao
          .upsertSession(ongoing(id: 's1', trailId: 'gr10'));
      final notifier = _C4Notifier(const TrackingSessionState());
      final container = makeContainer(notifier);
      final n = container.read(trekSessionManagerProvider.notifier);

      String? askedFor;
      final outcome = await n.ensureSingleActiveThenStart(
        'gr20',
        resolve: (ongoingId) async {
          askedFor = ongoingId;
          return ActiveTrekConflictChoice.cancel;
        },
      );

      expect(askedFor, 'gr10', reason: 'Le dialog cible le trek en cours.');
      expect(outcome, StartOutcome.cancelled);
      expect(notifier.startedTrailIds, isEmpty);
      // La session en cours reste active (rien soldee).
      expect((await db.trekSessionsDao.getById('s1'))!.status, 'active');
    });

    test('autre trek en cours (ORPHELIN) + ABANDONNER -> solde puis demarre',
        () async {
      await db.trekSessionsDao
          .upsertSession(ongoing(id: 's1', trailId: 'gr10', status: 'paused'));
      // La session en cours n'est PAS dans l'etat en memoire du notifier
      // (orpheline d'un crash sur un autre trek) -> soldee en base directement.
      final notifier = _C4Notifier(const TrackingSessionState());
      final container = makeContainer(notifier);
      final n = container.read(trekSessionManagerProvider.notifier);

      final outcome = await n.ensureSingleActiveThenStart(
        'gr20',
        resolve: (_) async => ActiveTrekConflictChoice.abandonCurrent,
      );

      expect(outcome, StartOutcome.started);
      expect(notifier.startedTrailIds, ['gr20']);
      // L'orpheline a ete soldee en `abandoned` (statut, sans finisher).
      final solded = await db.trekSessionsDao.getById('s1');
      expect(solded!.status, 'abandoned');
      expect(solded.parcoursFullyWalked, isFalse);
      expect(solded.finishedAt, isNotNull);
    });

    test('autre trek en cours (EN MEMOIRE) + TERMINER -> stop() puis demarre',
        () async {
      final live = ongoing(id: 's1', trailId: 'gr10');
      await db.trekSessionsDao.upsertSession(live);
      // Cette fois la session en cours EST la session vivante du notifier ->
      // on doit passer par stop() (teardown complet), pas par un solde en base.
      final notifier = _C4Notifier(
        TrackingSessionState(
          status: TrackingSessionStatus.recording,
          session: live,
        ),
      );
      final container = makeContainer(notifier);
      final n = container.read(trekSessionManagerProvider.notifier);

      final outcome = await n.ensureSingleActiveThenStart(
        'gr20',
        resolve: (_) async => ActiveTrekConflictChoice.finishCurrent,
      );

      expect(outcome, StartOutcome.started);
      expect(notifier.stopCallCount, 1,
          reason: 'La session vivante est terminee via stop().');
      expect(notifier.abandonCallCount, 0);
      expect(notifier.startedTrailIds, ['gr20']);
    });
  });
}

/// Notifier de test : instrumente [start]/[stop]/[abandon] (les vrais touchent
/// isolate GPS/permissions/recorder) tout en gardant la VRAIE logique de garde
/// [ensureSingleActiveThenStart] (heritee, non redefinie) et le vrai acces DAO.
class _C4Notifier extends TrekSessionManagerNotifier {
  _C4Notifier(this._initial);
  final TrackingSessionState _initial;

  final List<String> startedTrailIds = [];
  int stopCallCount = 0;
  int abandonCallCount = 0;

  @override
  TrackingSessionState build() => _initial;

  @override
  Future<void> start(String trailId) async {
    startedTrailIds.add(trailId);
    state = TrackingSessionState(
      status: TrackingSessionStatus.recording,
      session: TrekSession(
        id: 'new-$trailId',
        trailId: trailId,
        startedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> stop() async {
    stopCallCount++;
    state = state.copyWith(status: TrackingSessionStatus.stopped);
  }

  @override
  Future<void> abandon() async {
    abandonCallCount++;
    state = state.copyWith(status: TrackingSessionStatus.stopped);
  }
}
