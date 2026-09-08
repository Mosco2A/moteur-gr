import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/trek/data/background_gps_service.dart';
import 'package:moteur_gr/features/trek/data/trek_recorder.dart';
import 'package:moteur_gr/features/trek/domain/models/trek_session.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';

/// StepWays LOT 2, C4 — transition ABANDONNER de la machine d'unicite.
///
/// Exerce le VRAI [TrekSessionManagerNotifier.abandon] (partage [_finalize] avec
/// stop) : il finalise en `abandoned` et NE POSE PAS `parcoursFullyWalked` (pas
/// de faux finisher). Seuls l'isolate GPS de fond (best-effort, try/catch) est
/// neutralise via un fake ; le recorder ecrit dans la base in-memory.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('abandon() persiste status=abandoned SANS parcoursFullyWalked', () async {
    // Recorder REEL branche sur la base in-memory (comme en prod).
    final recorder = TrekRecorder(
      onFlush: (_, __) async {},
      onSessionPersist: (s) async => db.trekSessionsDao.upsertSession(s),
    );

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      trekRecorderProvider.overrideWithValue(recorder),
      backgroundGpsServiceProvider.overrideWithValue(_NoopBgService()),
    ]);
    addTearDown(container.dispose);

    final notifier = container.read(trekSessionManagerProvider.notifier);

    // Session en cours portee par le notifier + presente en base (active).
    final session = TrekSession(
      id: 'sess-abandon',
      trailId: 'gr20',
      startedAt: DateTime.utc(2026, 6, 15, 8),
      status: 'active',
      completedStages: const ['s1', 's2'],
    );
    await db.trekSessionsDao.upsertSession(session);
    // Le recorder doit avoir une session vivante pour que recorder.stop()
    // (appele dans _finalize) ne jette pas.
    await recorder.start('gr20');
    notifier.state = TrackingSessionState(
      status: TrackingSessionStatus.recording,
      session: session,
    );

    await notifier.abandon();

    // Etat en memoire : la session est arretee.
    expect(container.read(trekSessionManagerProvider).status,
        TrackingSessionStatus.stopped);

    // En base : la session AUTORITAIRE du notifier est soldee en `abandoned`,
    // etapes marchees preservees, finisher JAMAIS pose.
    final persisted = await db.trekSessionsDao.getById('sess-abandon');
    expect(persisted, isNotNull);
    expect(persisted!.status, 'abandoned',
        reason: 'abandon() finalise en abandoned, pas completed.');
    expect(persisted.parcoursFullyWalked, isFalse,
        reason: 'Un abandon n ouvre jamais la porte du finisher.');
    expect(persisted.finishedAt, isNotNull);
    expect(persisted.completedStages, ['s1', 's2']);
  });

  test('abandon() hors session active -> no-op (idempotent)', () async {
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      backgroundGpsServiceProvider.overrideWithValue(_NoopBgService()),
    ]);
    addTearDown(container.dispose);

    final notifier = container.read(trekSessionManagerProvider.notifier);
    // Etat idle par defaut.
    await notifier.abandon();

    expect(container.read(trekSessionManagerProvider).status,
        TrackingSessionStatus.idle);
  });
}

/// Fake d'isolate GPS de fond : no-op. Les appels de [_finalize] au service de
/// fond sont best-effort (try/catch) ; ce fake evite tout branchement natif.
class _NoopBgService extends BackgroundGpsService {
  @override
  Future<void> stop() async {}

  @override
  Future<List<BgTrackPoint>> drainBackgroundPoints() async => const [];
}
