import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/session_demo.dart';
import 'package:moteur_gr/domain/trek_session.dart';
// LES METHODES TYPEES DU DAO VIVENT DANS UNE EXTENSION : sans cet import,
// `findActiveSessions` et `upsertSession` n'existent pas.
import 'package:moteur_gr/domain/trek_session_mapping.dart';
import 'package:moteur_gr/features/hub/presentation/cockpit_phase.dart';
import 'package:moteur_gr/features/trek/data/background_gps_service.dart';
import 'package:moteur_gr/features/trek/data/trek_recorder.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';
import 'package:moteur_gr/features/treks/domain/trek_lifecycle_state.dart';
import 'package:moteur_gr/features/treks/domain/trek_summary.dart';
import 'package:moteur_gr/features/treks/providers/my_treks_provider.dart';

/// UN SEUL ETAT COMMANDE LES BOUTONS DU COCKPIT (tache 809).
///
/// CE QUE CHRISTOPHE A VU LE 10/10, EN MODE DEMO, ET QU'IL A DIT EN TROIS FOIS.
/// Verbatim, dans son ordre :
///   (a) « meme en mode demo preparer devrait disparaitre quand tu es en cours
///       de trek » ;
///   (b) « demarrer la randonne, le bouton aparait encore une fois la randonnee
///       finie au lieu d acceder a la post rando » ;
///   (c) « enlever le bouton acheter quand on est en trek et en post dtrek car
///       le circuit a forcement ete achete ».
///
/// CE BANC MESURE, IL NE CROIT PAS. Il etablit d'abord, avec la VRAIE machine de
/// session et une VRAIE base, ce que valait le cycle de vie du trek pendant et
/// apres une marche simulee — la question a laquelle tout le lot repond. Puis il
/// verrouille les trois etats de [cockpitPhaseProvider], qui est desormais la
/// seule porte publique vers la phase.
///
/// LA GARDE DE RENDU DES TROIS BOUTONS vit dans `hub_screen_test.dart` (section
/// « Préparer », bouton « Démarrer ») et `achat_et_video_614_test.dart` (bouton
/// « Acheter ») : ce fichier-ci tient la SOURCE, pas les pixels.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  // =========================================================================
  // 1. LA MESURE : CE QUE VAUT REELLEMENT LE CYCLE DE VIE EN DEMONSTRATION
  // =========================================================================

  group('809-1 — la demonstration et le cycle de vie du trek', () {
    test('pendant ET apres une marche simulee, le cycle de vie derive ne vaut '
        'JAMAIS inProgress ni completed', () async {
      // LA DEMO N'ECRIT RIEN (tache 760) : quatre barrieres de
      // `tracking_providers.dart` font qu'aucune ligne de session n'atteint la
      // base. On rejoue donc EXACTEMENT cette situation — vraie machine de
      // session, vraie base, `enDemoProvider` a vrai — et on MESURE ce que
      // `currentTrailSummaryProvider` repond.
      final recorder = TrekRecorder(
        onFlush: (_, __) async {},
        // LA BARRIERE, A L'IDENTIQUE DE LA PRODUCTION : en demo, le callback de
        // persistance de session sort sans rien ecrire.
        onSessionPersist: (_) async {},
      );
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          trailConfigProvider.overrideWithValue(testTrailConfig),
          enDemoProvider.overrideWithValue(true),
          trekRecorderProvider.overrideWithValue(recorder),
          backgroundGpsServiceProvider.overrideWithValue(_NoopBgService()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(trekSessionManagerProvider.notifier);

      // --- PENDANT : une session vit en memoire, et en memoire SEULEMENT.
      await recorder.start(testTrailConfig.id);
      notifier.state = TrackingSessionState(
        status: TrackingSessionStatus.recording,
        session: TrekSession(
          id: 'demo-sess',
          trailId: testTrailConfig.id,
          startedAt: DateTime.utc(2026, 10, 10, 8),
          status: 'active',
        ),
      );

      expect(
        await db.trekSessionsDao.findActiveSessions(),
        isEmpty,
        reason: 'la demo ne doit laisser AUCUNE ligne de session en base',
      );
      final pendant = await container.read(currentTrailSummaryProvider.future);
      expect(
        pendant?.state,
        isNot(TrekLifecycleState.inProgress),
        reason:
            'VOILA LE FOND DU DEFAUT : la marche simulee est invisible au '
            'cycle de vie derive, qui ne lit que la base.',
      );
      // Et la phase, elle, est JUSTE — parce qu'elle lit l'etat vivant.
      expect(container.read(cockpitPhaseProvider), CockpitPhase.hike);

      // --- APRES : l'arrivee, par le geste exact du bouton de simulation.
      await notifier.completeOnArrival(fullyWalked: true);

      container.invalidate(currentTrailSummaryProvider);
      final apres = await container.read(currentTrailSummaryProvider.future);
      expect(
        apres?.state,
        isNot(TrekLifecycleState.completed),
        reason:
            'rien n ayant ete ecrit, la base ne peut pas savoir que la '
            'randonnee est finie',
      );

      // ET VOICI LE DEFAUT (b) DE CHRISTOPHE, CORRIGE : la phase sait que la
      // randonnee est finie, donc « Démarrer » ne revient pas et la carte de
      // fin — avec sa porte « Mon aventure » — prend sa place.
      expect(
        container.read(cockpitPhaseProvider),
        CockpitPhase.after,
        reason:
            'apres l arrivee en demo, le cockpit doit etre en phase APRES, '
            'pas revenu a la preparation',
      );
    });

    test('l arret garde la session finalisee en memoire — c est ce qui rend '
        'l arrivee visible sans la base', () async {
      final recorder = TrekRecorder(
        onFlush: (_, __) async {},
        onSessionPersist: (s) async => db.trekSessionsDao.upsertSession(s),
      );
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          trailConfigProvider.overrideWithValue(testTrailConfig),
          trekRecorderProvider.overrideWithValue(recorder),
          backgroundGpsServiceProvider.overrideWithValue(_NoopBgService()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(trekSessionManagerProvider.notifier);
      await recorder.start(testTrailConfig.id);
      notifier.state = TrackingSessionState(
        status: TrackingSessionStatus.recording,
        session: TrekSession(
          id: 'sess-fin',
          trailId: testTrailConfig.id,
          startedAt: DateTime.utc(2026, 10, 10, 8),
          status: 'active',
        ),
      );

      await notifier.stop();

      final etat = container.read(trekSessionManagerProvider);
      expect(etat.status, TrackingSessionStatus.stopped);
      expect(
        etat.session,
        isNotNull,
        reason:
            'l etat final effacait la session : plus rien ne savait quelle '
            'randonnee venait de se terminer',
      );
      expect(etat.session!.status, 'completed');
      expect(etat.session!.finishedAt, isNotNull);
      expect(etat.session!.trailId, testTrailConfig.id);
    });

    test('un ABANDON ne vaut pas une arrivee : la phase ne passe pas en '
        'APRES', () async {
      final recorder = TrekRecorder(
        onFlush: (_, __) async {},
        onSessionPersist: (_) async {},
      );
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          trailConfigProvider.overrideWithValue(testTrailConfig),
          enDemoProvider.overrideWithValue(true),
          trekRecorderProvider.overrideWithValue(recorder),
          backgroundGpsServiceProvider.overrideWithValue(_NoopBgService()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(trekSessionManagerProvider.notifier);
      await recorder.start(testTrailConfig.id);
      notifier.state = TrackingSessionState(
        status: TrackingSessionStatus.recording,
        session: TrekSession(
          id: 'sess-abandon',
          trailId: testTrailConfig.id,
          startedAt: DateTime.utc(2026, 10, 10, 8),
          status: 'active',
        ),
      );

      await notifier.abandon();

      // Un abandon est REJOUABLE : le cockpit doit reproposer le depart, donc
      // revenir en preparation — jamais ouvrir l apres-randonnee.
      expect(
        container.read(trekSessionManagerProvider).session!.status,
        'abandoned',
      );
      expect(container.read(cockpitPhaseProvider), CockpitPhase.prepare);
    });
  });

  // =========================================================================
  // 2. LES TROIS REGLES DE LA PHASE, DANS LEUR ORDRE
  // =========================================================================

  group('809-2 — cockpitPhaseProvider, les trois regles', () {
    ProviderContainer conteneur({
      TrackingSessionStatus status = TrackingSessionStatus.idle,
      TrekSession? session,
      TrekLifecycleState? lifecycle,
    }) {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          trailConfigProvider.overrideWithValue(testTrailConfig),
          trekSessionManagerProvider.overrideWith(
            () => _SessionFigee(
              TrackingSessionState(status: status, session: session),
            ),
          ),
          if (lifecycle != null)
            currentTrailSummaryProvider.overrideWith(
              (ref) async => TrekSummary(
                config: ref.watch(trailConfigProvider),
                state: lifecycle,
              ),
            ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    TrekSession finie({String? trailId, String status = 'completed'}) =>
        TrekSession(
          id: 'sess',
          trailId: trailId ?? testTrailConfig.id,
          startedAt: DateTime.utc(2026, 10, 10, 8),
          finishedAt: DateTime.utc(2026, 10, 10, 18),
          status: status,
        );

    test('regle 1 — la marche vivante prime sur tout le reste', () {
      // Meme avec une base qui dit « termine », un suivi qui enregistre gagne :
      // c est le fait le plus frais.
      for (final status in [
        TrackingSessionStatus.recording,
        TrackingSessionStatus.paused,
      ]) {
        final c = conteneur(
          status: status,
          lifecycle: TrekLifecycleState.completed,
        );
        expect(
          c.read(cockpitPhaseProvider),
          CockpitPhase.hike,
          reason: '$status',
        );
      }
    });

    test(
      'regle 2 — un suivi arrete qui porte sa session TERMINEE dit APRES',
      () {
        final c = conteneur(
          status: TrackingSessionStatus.stopped,
          session: finie(),
        );
        expect(c.read(cockpitPhaseProvider), CockpitPhase.after);
      },
    );

    test('regle 2 — elle ne parle que DU sentier affiche', () {
      // Un sentier B termine ne doit jamais faire basculer le cockpit du
      // sentier A : la regle 2 est neuve, elle compare donc l identifiant.
      final c = conteneur(
        status: TrackingSessionStatus.stopped,
        session: finie(trailId: 'un-autre-sentier'),
      );
      expect(c.read(cockpitPhaseProvider), CockpitPhase.prepare);
    });

    test('regle 3 — a defaut, la base, qui survit au redemarrage', () async {
      // LES QUATRE ETATS DU CYCLE DE VIE, UN PAR UN. On ATTEND la base avant de
      // lire la phase : `currentTrailSummaryProvider` est un futur, et une
      // lecture seche repondrait « en chargement » — donc `prepare` pour tout
      // le monde, et le test ne mesurerait rien.
      const attendu = <TrekLifecycleState, CockpitPhase>{
        TrekLifecycleState.inProgress: CockpitPhase.hike,
        TrekLifecycleState.completed: CockpitPhase.after,
        TrekLifecycleState.owned: CockpitPhase.prepare,
        TrekLifecycleState.prepared: CockpitPhase.prepare,
      };
      // La table doit couvrir TOUT l'enum : un etat ajoute demain sans decision
      // de phase fait rougir ici, pas en production.
      expect(attendu.keys.toSet(), TrekLifecycleState.values.toSet());

      for (final entree in attendu.entries) {
        final c = conteneur(lifecycle: entree.key);
        await c.read(currentTrailSummaryProvider.future);
        expect(
          c.read(cockpitPhaseProvider),
          entree.value,
          reason: '${entree.key} doit donner ${entree.value}',
        );
      }
    });

    test('aucun trek, aucune session -> PREPARE (jamais d ecran casse)', () {
      final c = conteneur();
      expect(c.read(cockpitPhaseProvider), CockpitPhase.prepare);
    });
  });
}

/// Un notifier de session FIGE : ces regles mesurent la SOURCE de la phase, pas
/// la machine de session (tenue par les gardes 638, 649 et 809-1).
class _SessionFigee extends TrekSessionManagerNotifier {
  _SessionFigee(this._etat);

  final TrackingSessionState _etat;

  @override
  TrackingSessionState build() => _etat;
}

/// L'isolate GPS de fond, neutralise : `_finalize` l'arrete en best-effort.
class _NoopBgService extends BackgroundGpsService {
  @override
  Future<void> stop() async {}

  @override
  Future<List<BgTrackPoint>> drainBackgroundPoints() async => const [];
}
