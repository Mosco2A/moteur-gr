import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/trek/data/background_gps_service.dart';
import 'package:moteur_gr/features/trek/data/trek_recorder.dart';
import 'package:moteur_gr/features/trek/domain/models/trek_session.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';
import 'package:moteur_gr/features/treks/domain/trek_lifecycle_state.dart';
import 'package:moteur_gr/features/treks/providers/my_treks_provider.dart';

/// NON-REGRESSION — LOT FIX-2, finding M4 (MAJEUR).
///
/// « Apres "Terminer le trek", les artefacts de fin ne sont pas atteignables :
/// carte Diplome introuvable au defilement, Journal present dans l'arbre mais
/// non tapable, Recapitulatif non atteint. Les DONNEES sont conservees, c'est
/// l'ACCES qui coince. »
///
/// CAUSE RACINE : la phase du cockpit est DERIVEE de
/// [currentTrailSummaryProvider], un `FutureProvider` qui lit la base UNE fois
/// et ne s'invalide sur rien de ce que la fin de trek ecrit. La session passait
/// bien a `completed` en base, mais le cockpit continuait de lire `inProgress` :
/// il restait en phase « Randonner », donc la section « Apres la randonnee »
/// (Diplome + Recapitulatif) n'etait JAMAIS construite, la carte Journal de la
/// section Informations restait masquee, et le bouton « Terminer le trek »
/// restait propose alors qu'il n'y avait plus rien a terminer.
///
/// CE QUE CES TESTS VERROUILLENT : apres une finalisation, les vues derivees du
/// cycle de vie disent la VERITE de la base sans qu'on ait a relancer l'app.
/// Ils exercent le VRAI [TrekSessionManagerNotifier] (donc le vrai `_finalize`,
/// partage par la fin manuelle, l'abandon et l'arrivee GPS) sur une base
/// in-memory ; seul l'isolate GPS de fond est neutralise.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  /// Conteneur cable sur la base in-memory, avec le sentier de test actif.
  ProviderContainer conteneur(TrekRecorder recorder) {
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      trailConfigProvider.overrideWithValue(_config),
      trekRecorderProvider.overrideWithValue(recorder),
      backgroundGpsServiceProvider.overrideWithValue(_NoopBgService()),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  /// Recorder REEL (necessaire : `_finalize` appelle `recorder.stop()`), mais
  /// qui n'ECRIT PAS sa session interne.
  ///
  /// En production, la session du recorder et la session autoritaire du notifier
  /// sont la MEME (le demarrage passe par le notifier). Ici on pose la session
  /// de test a la main, donc `recorder.start()` en fabriquerait une SECONDE,
  /// plus recente, qui deviendrait celle que lit le cycle de vie derive
  /// (`getLatestByTrailId`) — un artefact de montage qui masquerait ce qu'on
  /// veut mesurer. On laisse donc la seule ecriture autoritaire, celle de
  /// `_finalize`.
  TrekRecorder recorderSurBase() => TrekRecorder(
        onFlush: (_, __) async {},
        onSessionPersist: (_) async {},
      );

  /// Pose une session EN COURS sur le sentier de test, en base et en memoire.
  Future<void> demarrerSession(
    ProviderContainer container,
    TrekRecorder recorder, {
    required String id,
  }) async {
    final session = TrekSession(
      id: id,
      trailId: _config.id,
      startedAt: DateTime.utc(2026, 6, 15, 8),
      status: 'active',
      completedStages: const ['s1', 's2'],
    );
    await db.trekSessionsDao.upsertSession(session);
    // Le recorder doit avoir une session vivante : `_finalize` appelle stop().
    await recorder.start(_config.id);
    container.read(trekSessionManagerProvider.notifier).state =
        TrackingSessionState(
      status: TrackingSessionStatus.recording,
      session: session,
    );
  }

  test(
    'stop() -> le cycle de vie derive passe a completed SANS redemarrer l app',
    () async {
      final recorder = recorderSurBase();
      final container = conteneur(recorder);
      await demarrerSession(container, recorder, id: 'sess-fin-001');

      // Etat vu par le cockpit AVANT : trek en cours -> phase « Randonner ».
      final avant = await container.read(currentTrailSummaryProvider.future);
      expect(avant?.state, TrekLifecycleState.inProgress);

      await container.read(trekSessionManagerProvider.notifier).stop();

      // Les DONNEES sont bien soldees en base...
      final persistee = await db.trekSessionsDao.getById('sess-fin-001');
      expect(persistee?.status, 'completed');
      expect(persistee?.completedStages, ['s1', 's2']);

      // ... ET l'ACCES suit : la vue derivee est relue, le cockpit peut basculer
      // en phase « Apres » et construire Diplome + Recapitulatif. C'est CE
      // point qui manquait (finding M4).
      final apres = await container.read(currentTrailSummaryProvider.future);
      expect(
        apres?.state,
        TrekLifecycleState.completed,
        reason: 'sans invalidation, le cockpit reste bloque sur inProgress : '
            'section « Apres la randonnee » jamais construite, Diplome et '
            'Recapitulatif inatteignables (finding M4)',
      );
    },
  );

  test('stop() -> plus aucun trek en cours (activeTrekIdProvider relu)',
      () async {
    final recorder = recorderSurBase();
    final container = conteneur(recorder);
    await demarrerSession(container, recorder, id: 'sess-fin-002');

    expect(await container.read(activeTrekIdProvider.future), _config.id);

    await container.read(trekSessionManagerProvider.notifier).stop();

    expect(
      await container.read(activeTrekIdProvider.future),
      isNull,
      reason: 'le creneau d unicite C4 doit etre libere pour l UI des la fin '
          'du trek, sans attendre un redemarrage',
    );
  });

  test('abandon() rafraichit aussi les vues derivees (meme _finalize)',
      () async {
    final recorder = recorderSurBase();
    final container = conteneur(recorder);
    await demarrerSession(container, recorder, id: 'sess-fin-003');

    expect(
      (await container.read(currentTrailSummaryProvider.future))?.state,
      TrekLifecycleState.inProgress,
    );

    await container.read(trekSessionManagerProvider.notifier).abandon();

    // Un abandon retombe `prepared` (trek re-preparable), jamais `completed` :
    // pas de faux finisher, mais le cockpit quitte bien la phase « Randonner ».
    expect(
      (await container.read(currentTrailSummaryProvider.future))?.state,
      TrekLifecycleState.prepared,
    );
    expect(await container.read(activeTrekIdProvider.future), isNull);
  });

  test('finalisation hors session active -> no-op, aucune vue faussee',
      () async {
    final container = conteneur(recorderSurBase());

    // Etat idle : rien a finaliser.
    await container.read(trekSessionManagerProvider.notifier).stop();

    expect(container.read(trekSessionManagerProvider).status,
        TrackingSessionStatus.idle);
    expect(await container.read(activeTrekIdProvider.future), isNull);
  });
}

/// Fake d'isolate GPS de fond : no-op (appels best-effort dans `_finalize`).
class _NoopBgService extends BackgroundGpsService {
  @override
  Future<void> stop() async {}

  @override
  Future<List<BgTrackPoint>> drainBackgroundPoints() async => const [];
}

/// Sentier de test neutre — aucun toponyme reel (cloisonnement #326).
const _config = TrailConfig(
  id: 'sentier-test',
  name: 'sentier-test',
  displayName: 'Sentier de test',
  tagline: 'parcours de test',
  totalStages: 5,
  totalDistanceKm: 50,
  totalElevationGain: 2000,
  region: 'Region de test',
  country: 'Pays de test',
  primaryColorValue: 0xFF2E7D32,
  secondaryColorValue: 0xFF1565C0,
  gpxAssetPath: 'assets/gpx/test.gpx',
);
