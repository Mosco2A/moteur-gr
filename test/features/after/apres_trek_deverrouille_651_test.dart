import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/after/providers/adventure_recap_provider.dart';
import 'package:moteur_gr/features/planning/providers/trek_edit_lock_provider.dart';
import 'package:moteur_gr/features/trek/data/background_gps_service.dart';
import 'package:moteur_gr/features/trek/data/trek_recorder.dart';
import 'package:moteur_gr/domain/trek_session.dart';
import 'package:moteur_gr/domain/trek_session_mapping.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';

/// NON-REGRESSION — TACHE 651, DEFAUT A (MAJEUR) : L'APRES-TREK RESTAIT
/// VERROUILLE APRES UN TREK TERMINE.
///
/// Symptome mesure par la campagne personas 650 (S1 Lea, reproduit aussi sur un
/// trek reellement marche par S3 Steve) : le randonneur appuie « Terminer le
/// trek », confirme, le dialogue se ferme, le cockpit bascule bien en phase
/// « Apres » — et « Mon aventure » affiche « Disponible a la fin du trek ».
/// Diplome, journal et recapitulatif restaient inaccessibles.
///
/// CAUSE RACINE MESUREE : le lot FIX-2 (finding M4) avait rafraichi les vues du
/// CYCLE DE VIE ([currentTrailSummaryProvider], [myTreksProvider],
/// [activeTrekIdProvider]) a la fin de `_finalize`, mais PAS
/// [latestTrekSessionProvider] — la source UNIQUE de tout l'« apres-trek »
/// ([isRecapAvailableProvider], [isDiplomaUnlockedProvider],
/// [adventureStatsProvider]). C'est un `FutureProvider` qui lit la base UNE
/// fois ; il est maintenu VIVANT pendant la rando par le verrou d'edition du
/// programme ([trekEditLockProvider], lui-meme tenu par `plannedDaysProvider`
/// via `ref.listen(..., fireImmediately: true)`). Sa valeur en cache restait
/// donc la session `active` d'avant la fin : le cockpit disait « termine »
/// pendant que l'ecran de recap lisait encore « en cours ». Deux verites sur le
/// meme trek, au meme instant.
///
/// LE CORRECTIF est d'invalider [latestTrekSessionProvider] la ou les trois
/// autres l'etaient deja : a la fin de `_finalize`, donc pour les TROIS
/// chemins de sortie (fin manuelle, abandon, arrivee GPS).
///
/// Ces tests exercent le VRAI [TrekSessionManagerNotifier] sur une base
/// in-memory ; seul l'isolate GPS de fond est neutralise.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  ProviderContainer conteneur(TrekRecorder recorder) {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        trailConfigProvider.overrideWithValue(_config),
        trekRecorderProvider.overrideWithValue(recorder),
        backgroundGpsServiceProvider.overrideWithValue(_NoopBgService()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Recorder REEL (`_finalize` appelle `recorder.stop()`) qui n'ecrit pas sa
  /// session interne : la seule ecriture autoritaire reste celle de `_finalize`.
  TrekRecorder recorderSurBase() =>
      TrekRecorder(onFlush: (_, __) async {}, onSessionPersist: (_) async {});

  Future<TrekSession> demarrerSession(
    ProviderContainer container,
    TrekRecorder recorder, {
    required String id,
    bool finisher = false,
  }) async {
    final session = TrekSession(
      id: id,
      trailId: _config.id,
      startedAt: DateTime.utc(2026, 6, 15, 8),
      status: 'active',
      completedStages: const ['s1', 's2'],
      parcoursFullyWalked: finisher,
    );
    await db.trekSessionsDao.upsertSession(session);
    await recorder.start(_config.id);
    container
        .read(trekSessionManagerProvider.notifier)
        .state = TrackingSessionState(
      status: TrackingSessionStatus.recording,
      session: session,
    );
    return session;
  }

  /// Reproduit la condition REELLE de l'application : quelque chose tient
  /// [latestTrekSessionProvider] vivant pendant la rando. En production c'est
  /// le verrou d'edition du programme ; ici on s'abonne au MEME provider, pas a
  /// un montage artificiel.
  void tenirLeVerrouDEdition(ProviderContainer container) {
    final sub = container.listen(trekEditLockProvider, (_, __) {});
    addTearDown(sub.close);
  }

  test('DEFAUT A — « Terminer le trek » deverrouille « Mon aventure » sans '
      'redemarrer l application', () async {
    final recorder = recorderSurBase();
    final container = conteneur(recorder);
    await demarrerSession(container, recorder, id: 'sess-651-a');
    tenirLeVerrouDEdition(container);

    // Le recap est bien VERROUILLE pendant la rando (fail-closed attendu).
    await container.read(latestTrekSessionProvider.future);
    expect(
      container.read(isRecapAvailableProvider),
      isFalse,
      reason: 'pendant la rando, « Mon aventure » doit rester ferme',
    );

    await container.read(trekSessionManagerProvider.notifier).stop();

    // Les DONNEES sont soldees en base.
    final persistee = await db.trekSessionsDao.getById('sess-651-a');
    expect(persistee?.status, 'completed');

    // ... ET l'ACCES suit : la source unique de l'apres-trek est relue.
    final relue = await container.read(latestTrekSessionProvider.future);
    expect(
      relue?.status,
      'completed',
      reason:
          'la source unique de l apres-trek doit etre relue apres la '
          'fin du trek, sinon elle sert la session « active » en cache',
    );
    expect(
      container.read(isRecapAvailableProvider),
      isTrue,
      reason:
          'sans invalidation de latestTrekSessionProvider, l ecran « Mon '
          'aventure » affiche « Disponible a la fin du trek » alors que le '
          'trek EST termine (defaut A, campagne personas 650)',
    );
  });

  test(
    'DEFAUT A — un trek REELLEMENT marche ouvre aussi le diplome (persona S3)',
    () async {
      final recorder = recorderSurBase();
      final container = conteneur(recorder);
      await demarrerSession(
        container,
        recorder,
        id: 'sess-651-finisher',
        finisher: true,
      );
      tenirLeVerrouDEdition(container);

      // Le finisher est deja ecrit en base (le randonneur a marche la derniere
      // etape), mais le RECAP reste ferme tant que le trek n'est pas soldé —
      // et c'est par lui que passe l'acces au diplome (une seule porte, L5-8).
      await container.read(latestTrekSessionProvider.future);
      expect(container.read(isRecapAvailableProvider), isFalse);

      await container.read(trekSessionManagerProvider.notifier).stop();

      expect(container.read(isRecapAvailableProvider), isTrue);
      expect(
        container.read(isDiplomaUnlockedProvider),
        isTrue,
        reason:
            'le finisher etait deja ecrit en base : seule la relecture '
            'manquait pour que le diplome s ouvre',
      );
    },
  );

  test(
    'DEFAUT A — un ABANDON ouvre aussi « Mon aventure » (parite GR20)',
    () async {
      final recorder = recorderSurBase();
      final container = conteneur(recorder);
      await demarrerSession(container, recorder, id: 'sess-651-abandon');
      tenirLeVerrouDEdition(container);

      await container.read(latestTrekSessionProvider.future);
      expect(container.read(isRecapAvailableProvider), isFalse);

      await container.read(trekSessionManagerProvider.notifier).abandon();

      expect(
        container.read(isRecapAvailableProvider),
        isTrue,
        reason:
            'un abandon doit pouvoir revoir son aventure ; le diplome, lui, '
            'reste ferme (aucun faux finisher)',
      );
      expect(container.read(isDiplomaUnlockedProvider), isFalse);
    },
  );

  test(
    'DEFAUT A — le verrou d edition se rouvre aussi a la fin du trek',
    () async {
      final recorder = recorderSurBase();
      final container = conteneur(recorder);
      await demarrerSession(container, recorder, id: 'sess-651-verrou');
      tenirLeVerrouDEdition(container);

      await container.read(latestTrekSessionProvider.future);
      expect(container.read(trekEditLockProvider).trekStarted, isTrue);

      await container.read(trekSessionManagerProvider.notifier).stop();
      await container.read(latestTrekSessionProvider.future);

      expect(
        container.read(trekEditLockProvider).trekStarted,
        isFalse,
        reason:
            'le trek est fini : le programme redevient editable sans '
            'redemarrer l application',
      );
    },
  );
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
