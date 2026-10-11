import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
// `Stage` est masque : la base Drift en expose une, et c'est le modele de
// DOMAINE que la matiere fabrique (meme levee d'ambiguite que dans
// `matiere_de_demo_810_test.dart`).
import 'package:moteur_gr/core/data/database.dart' hide Stage;
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/providers/service_providers.dart';
import 'package:moteur_gr/core/services/demo_mode_service.dart';
import 'package:moteur_gr/core/services/session_demo.dart';
import 'package:moteur_gr/domain/trek_session.dart';
// LES METHODES TYPEES DU DAO VIVENT DANS UNE EXTENSION : sans cet import,
// `findActiveSessions` n'existe pas.
import 'package:moteur_gr/domain/trek_session_mapping.dart';
import 'package:moteur_gr/features/after/providers/adventure_recap_provider.dart';
import 'package:moteur_gr/features/hub/presentation/cockpit_phase.dart';
import 'package:moteur_gr/features/trek/data/background_gps_service.dart';
import 'package:moteur_gr/features/trek/data/trek_recorder.dart';
import 'package:moteur_gr/features/trek/providers/stage_providers.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';

/// L'ARRIVEE SIMULEE OUVRE L'APRES-RANDONNEE — LA PREUVE DU CROISEMENT 809/810
/// (tache 812).
///
/// POURQUOI CE BANC EXISTE, ET POURQUOI AUCUNE DES DEUX BRANCHES NE POUVAIT LE
/// PORTER. Deux lots du 11/10 se croisent exactement ici, et chacun n'avait
/// sous la main que la moitie du mecanisme :
///
///   - LE LOT 810 A MESURE SUR SA BRANCHE que la phase du cockpit ne basculait
///     PAS en « Apres » en demonstration : `currentTrailSummaryProvider` derive
///     son etat de la BASE, et la demo n'ecrit rien (tache 760). Son constat
///     etait juste — sur sa branche.
///   - LE LOT 809 A CORRIGE EXACTEMENT CELA, par deux gestes : `_finalize`
///     cesse de jeter la session finalisee (elle reste en MEMOIRE, jamais en
///     base), et `cockpitPhaseProvider` la lit en regle 2 avant de retomber
///     sur la base.
///
/// SEPAREES, LES DEUX PREUVES EXISTENT DEJA : `un_seul_etat_de_rando_809_test`
/// tient la bascule de phase, `matiere_de_demo_810_test` (D) tient l'ouverture
/// du recapitulatif. AUCUN BANC NE LES TENAIT ENSEMBLE, dans UN SEUL conteneur,
/// apres UNE SEULE arrivee simulee — or c'est precisement ce que Christophe
/// verra a l'ecran : il arrive, et il pousse la porte « Mon aventure ».
///
/// CE BANC N'UTILISE AUCUNE SURCHARGE DE `enDemoProvider`. Il entre en
/// demonstration par le VRAI mecanisme (`sessionDemoProvider.entrer()`) sur le
/// VRAI sentier de demonstration, et il arrive par le VRAI geste du bouton de
/// simulation (`completeOnArrival`), avec la VRAIE machine de session et une
/// VRAIE base. Une preuve obtenue en forcant un drapeau ne prouverait rien du
/// chemin reel.
///
/// LES DEUX FAITS LISENT DEUX SOURCES DIFFERENTES, ET C'EST TOUT L'INTERET :
/// la phase lit la session VIVANTE gardee en memoire par 809 ; le
/// recapitulatif lit la matiere FABRIQUEE par 810. Rien ne garantissait a
/// l'avance qu'ils tombent d'accord apres la fusion. Ce banc le mesure.
void main() {
  // LE VRAI SENTIER DE DEMONSTRATION : `entrer()` n'accepte que celui-la et
  // refuse silencieusement tout autre identifiant.
  final trailId = kSentierDeDemo;

  final config = TrailConfig(
    id: trailId,
    name: 'Demo Trail',
    displayName: 'Demo Trail',
    tagline: 'tagline',
    totalStages: 4,
    totalDistanceKm: 999.0,
    totalElevationGain: 99999,
    region: 'Region',
    country: 'France',
    primaryColorValue: 0xFF2E7D32,
    secondaryColorValue: 0xFF1565C0,
    gpxAssetPath: 'assets/gpx/test.gpx',
    defaultDuration: 4,
    availableDurations: const [2, 4, 6],
  );

  late AppDatabase db;

  StagesCompanion ligneEtape(int n) => StagesCompanion(
    trailId: Value(trailId),
    stageNumber: Value(n),
    name: Value('Depart $n - Arrivee $n'),
    distanceKm: const Value(10.0),
    elevationGainM: const Value(500),
    elevationLossM: const Value(400),
    description: const Value('desc'),
    startLat: const Value(42.0),
    startLng: const Value(9.0),
    endLat: const Value(42.1),
    endLng: const Value(9.1),
    difficulty: const Value('moderate'),
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.stagesDao.insertAll([
      ligneEtape(1),
      ligneEtape(2),
      ligneEtape(3),
      ligneEtape(4),
    ]);
  });

  tearDown(() async => db.close());

  test(
    'EN DEMO, apres l arrivee simulee : le cockpit passe en phase APRES et la '
    'porte « Mon aventure » ouvre sur le recapitulatif BOUCHONNE',
    () async {
      // LA BARRIERE DE LA DEMO, A L'IDENTIQUE DE LA PRODUCTION : le callback
      // de persistance de session sort sans rien ecrire (tache 760).
      final recorder = TrekRecorder(
        onFlush: (_, __) async {},
        onSessionPersist: (_) async {},
      );
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          trailConfigProvider.overrideWithValue(config),
          currentTrailIdProvider.overrideWith((ref) => trailId),
          demoModeServiceProvider.overrideWithValue(DemoModeService()),
          trekRecorderProvider.overrideWithValue(recorder),
          backgroundGpsServiceProvider.overrideWithValue(_NoopBgService()),
        ],
      );
      addTearDown(container.dispose);

      // --- ON ENTRE EN DEMONSTRATION PAR LE VRAI CHEMIN.
      container.read(sessionDemoProvider.notifier).entrer();
      expect(
        container.read(enDemoProvider),
        isTrue,
        reason: 'entrer() n accepte que le sentier de demonstration',
      );

      // --- LA MARCHE SIMULEE : une session vit en memoire, et la SEULEMENT.
      final notifier = container.read(trekSessionManagerProvider.notifier);
      await recorder.start(trailId);
      notifier.state = TrackingSessionState(
        status: TrackingSessionStatus.recording,
        session: TrekSession(
          id: 'demo-sess-812',
          trailId: trailId,
          startedAt: DateTime.utc(2026, 10, 11, 8),
          status: 'active',
        ),
      );
      expect(
        container.read(cockpitPhaseProvider),
        CockpitPhase.hike,
        reason: 'pendant la marche simulee, le cockpit est en phase RANDONNER',
      );

      // --- L'ARRIVEE, PAR LE GESTE EXACT DU BOUTON DE SIMULATION.
      await notifier.completeOnArrival(fullyWalked: true);

      // (1) RIEN N'A ETE ECRIT — la loi de la demo tient toujours.
      expect(
        await db.trekSessionsDao.findActiveSessions(),
        isEmpty,
        reason: 'la demo ne doit laisser AUCUNE ligne de session en base',
      );

      // (2) LE FAIT DU LOT 809 : la phase bascule en APRES, donc « Démarrer »
      //     ne revient pas et la carte de fin prend sa place.
      expect(
        container.read(cockpitPhaseProvider),
        CockpitPhase.after,
        reason:
            'apres l arrivee en demo, le cockpit doit etre en phase APRES — '
            'c est la regle 2 de cockpitPhaseProvider, qui lit la session '
            'finalisee gardee en memoire par _finalize',
      );

      // (3) LE FAIT DU LOT 810 : la porte « Mon aventure » est OUVERTE, sur la
      //     matiere fabriquee — pas l'ecran verrouille.
      final session = await container.read(latestTrekSessionProvider.future);
      expect(
        session,
        isNotNull,
        reason: 'en demo, la matiere fabriquee tient lieu de session',
      );
      expect(
        container.read(isRecapAvailableProvider),
        isTrue,
        reason:
            'la porte « Mon aventure » doit ouvrir sur le recapitulatif '
            'bouchonne, et non sur l ecran verrouille',
      );

      // (4) ET LE RECAPITULATIF A VRAIMENT DE LA MATIERE A MONTRER : les
      //     chiffres sont la somme des QUATRE etapes seedees.
      final stats = await container.read(adventureStatsProvider.future);
      expect(stats.stagesWalked, 4);
      expect(stats.distanceKm, 40.0);
      expect(
        stats.distanceKm,
        isNot(config.totalDistanceKm),
        reason:
            'les chiffres additionnent les etapes, ils ne lisent pas les '
            'totaux declares par le sentier',
      );
    },
  );
}

/// L'isolate GPS de fond, neutralise : `_finalize` l'arrete en best-effort.
class _NoopBgService extends BackgroundGpsService {
  @override
  Future<void> stop() async {}

  @override
  Future<List<BgTrackPoint>> drainBackgroundPoints() async => const [];
}
