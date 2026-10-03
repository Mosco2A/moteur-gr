/// L'etat de l'enregistrement expose a l'ecran : distance, duree, denivele,
/// vitesse, et ou en est la session.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/daos/session_track_points_dao.dart';
import '../../../core/engine/trail_engine.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/services/monetization_service.dart';
import '../../map/map_facade.dart' show stageDistanceCoveredProvider;
// TACHE 651 (defaut A) : la SOURCE UNIQUE de tout l'« apres-trek » (recap,
// diplome, journal, stats) est `latestTrekSessionProvider`. Elle doit etre
// relue a la fin de CHAQUE finalisation, comme les trois vues du cycle de vie
// (cf. `_finalize`). Sens unique : `adventure_recap_provider` n'importe pas ce
// fichier, aucun cycle d'import.
import '../../after/after_facade.dart' show latestTrekSessionProvider;
// TACHE 630 : la fiche d'urgence monte sur l'ecran verrouille au depart du trek
// et en redescend a l'arrivee. Sens unique : le module securite n'importe pas ce
// fichier, aucun cycle d'import.
import '../../safety/safety_facade.dart' show ficheEcranVerrouilleProvider;
// FIX-2 (M4) : invalidation des vues derivees du cycle de vie apres une
// finalisation de session (cf. `_finalize`). Sens unique : `my_treks_provider`
// n'importe pas ce fichier, aucun cycle d'import.
import '../../treks/treks_facade.dart'
    show activeTrekIdProvider, currentTrailSummaryProvider, myTreksProvider;
import '../data/background_gps_service.dart';
import '../data/trek_recorder.dart';
import '../../../domain/trek_session.dart';
import '../../../domain/trek_stats.dart';
import '../../../core/services/session_demo.dart';

/// Etat immutable du tracking expose a l'UI.
///
/// Contient les stats temps reel (distance, duree, D+, vitesse)
/// et l'etat de la session (idle, recording, paused, stopped).
class TrackingSessionState {
  const TrackingSessionState({
    this.status = TrackingSessionStatus.idle,
    this.distanceKm = 0.0,
    this.elevationGainM = 0.0,
    this.elapsedDuration = Duration.zero,
    this.currentSpeedKmh = 0.0,
    this.avgSpeedKmh = 0.0,
    this.session,
  });

  /// Etat de la session.
  final TrackingSessionStatus status;

  /// Distance parcourue en kilometres.
  final double distanceKm;

  /// Denivele positif cumule en metres.
  final double elevationGainM;

  /// Duree ecoulee active (hors pauses).
  final Duration elapsedDuration;

  /// Vitesse instantanee en km/h.
  final double currentSpeedKmh;

  /// Vitesse moyenne en km/h.
  final double avgSpeedKmh;

  /// Session active (null si idle/stopped).
  final TrekSession? session;

  TrackingSessionState copyWith({
    TrackingSessionStatus? status,
    double? distanceKm,
    double? elevationGainM,
    Duration? elapsedDuration,
    double? currentSpeedKmh,
    double? avgSpeedKmh,
    TrekSession? session,
  }) {
    return TrackingSessionState(
      status: status ?? this.status,
      distanceKm: distanceKm ?? this.distanceKm,
      elevationGainM: elevationGainM ?? this.elevationGainM,
      elapsedDuration: elapsedDuration ?? this.elapsedDuration,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
      session: session ?? this.session,
    );
  }
}

/// Etats possibles d'une session de tracking.
enum TrackingSessionStatus { idle, recording, paused, stopped }

/// Decision de l'utilisateur face a un CONFLIT d'unicite (StepWays LOT 2, C4).
///
/// Quand [TrekSessionManagerNotifier.ensureSingleActiveThenStart] detecte qu'un
/// AUTRE trek est deja en cours (session `active`|`paused`), la couche UI doit
/// trancher via un dialog « Terminer / Abandonner » avant de demarrer le
/// nouveau. Ce type est le CONTRAT data<->UI : la garde recoit un callback qui
/// renvoie ce choix, sans que la couche data ne connaisse le dialog (aucune
/// dependance Flutter/UI ici — les widgets vivent en Phase 4-5).
enum ActiveTrekConflictChoice {
  /// Terminer la rando en cours (finish, `completed`) puis demarrer la nouvelle.
  finishCurrent,

  /// Abandonner la rando en cours (`abandoned`) puis demarrer la nouvelle.
  abandonCurrent,

  /// Ne rien faire : garder la rando en cours, ne PAS demarrer la nouvelle.
  cancel,
}

/// Callback fourni par l'UI pour resoudre un conflit d'unicite (dialog
/// Terminer/Abandonner). Recoit le sentier DEJA en cours et renvoie le choix.
typedef ActiveTrekConflictResolver =
    Future<ActiveTrekConflictChoice> Function(String ongoingTrailId);

/// Issue d'un appel a [TrekSessionManagerNotifier.ensureSingleActiveThenStart].
enum StartOutcome {
  /// La nouvelle rando a bien demarre (aucun conflit, ou conflit resolu).
  started,

  /// Le meme trek etait deja en cours -> rien fait (idempotent).
  alreadyActiveSameTrail,

  /// Un autre trek etait en cours et l'utilisateur a ANNULE -> non demarre.
  cancelled,

  /// LE TREK N'EST PAS ACHETE : la realisation lui est reservee (tache 594,
  /// A1). L'UI doit DIRE pourquoi et OU acheter — jamais un bouton muet.
  purchaseRequired,
}

/// Provider du TrekRecorder (E2.8a).
///
/// Fournit une instance de TrekRecorder. La persistence Drift des
/// points est branchee au moment du start (DAOs).
/// E5.19a : chaque flush met a jour les donnees du widget Home
/// Screen (WidgetDataService) avec la progression courante.
/// Overridable dans les tests.
final trekRecorderProvider = Provider<TrekRecorder>((ref) {
  return TrekRecorder(
    onFlush: (sessionId, points) async {
      // E5.19a — MAJ widget Home Screen a chaque flush (10 positions).
      final config = ref.read(trailConfigProvider);
      final widgetData = ref.read(widgetDataServiceProvider);
      final tracking = ref.read(trekSessionManagerProvider);

      final totalKm = config.totalDistanceKm;
      // Coherence accueil<->carte (correctif build 117, spec AM-5/RM-2) :
      // le « parcouru » et la progression du widget Home lisent la source
      // PROJETEE sur le trace (stageDistanceCoveredProvider), JAMAIS le cumul
      // GPS brut (tracking.distanceKm) qui gonfle sur un aller-retour.
      final doneKm = ref.read(stageDistanceCoveredProvider) / 1000;
      final progress = totalKm > 0 ? (doneKm / totalKm) : 0.0;
      final remainingKm = (totalKm - doneKm) < 0 ? 0.0 : (totalKm - doneKm);
      final etaMinutes = tracking.avgSpeedKmh > 0.5
          ? (remainingKm / tracking.avgSpeedKmh * 60).round()
          : 0;
      final altitude = points.isNotEmpty ? points.last.elevation : 0.0;

      await widgetData.updateWidgetData(
        trailName: config.name,
        // Le nom d'etape detaille arrive avec la detection d'etape ;
        // en attendant, le widget affiche le sentier + progression.
        stageName: config.name,
        stageProgress: progress,
        distanceRemaining: remainingKm * 1000,
        etaMinutes: etaMinutes,
        altitude: altitude,
        stageIndex: 0,
        totalStages: config.totalStages,
        themeColorValue: config.primaryColorValue,
      );
    },
    // GO-85 inc2 / PARITE GR20, LOT 2 (#99433) : persistance REELLE de la
    // session en local Drift (au LOT 1 ce callback etait VIDE -> completedStages
    // et parcoursFullyWalked etaient perdus au redemarrage). On upsert la
    // session (par id) a chaque etape du cycle de vie (start/stop) ET a chaque
    // etape marchee : la memoire du finisher SURVIT desormais a un
    // redemarrage. Best-effort (ne casse jamais le trek). Firestore = Phase 4.
    onSessionPersist: (session) async {
      // DEMO : LA RANDO SIMULEE NE TOUCHE PAS LA BASE (tache 634,
      // DEM-260929-1123). Christophe : « ON EST EN MODE DEMO » = rien ne
      // compte, « rien en base ». La session vit alors en MEMOIRE seulement —
      // le randonneur voit son trek avancer, son journal, son arrivee, et
      // fermer l'application n'en laisse aucune trace.
      if (ref.read(enDemoProvider)) return;
      try {
        await ref.read(databaseProvider).trekSessionsDao.upsertSession(session);
      } catch (_) {
        // Best-effort : un echec de persistance ne doit pas casser le trek.
      }
    },
  );
});

/// Provider du TrekStats (E2.8b).
///
/// Fournit une instance de TrekStats parametree avec la distance
/// totale du sentier. Par defaut 0 km (overridable).
/// Overridable dans les tests.
final trekStatsProvider = Provider<TrekStats>((ref) {
  return TrekStats(totalDistanceKm: 0.0);
});

/// Notifier de la session de tracking orchestrant TrekRecorder + TrekStats.
///
/// Responsabilites :
/// - Coordonner start / pause / resume / stop
/// - Mettre a jour l'etat expose a l'UI
/// - Deleguer l'enregistrement a TrekRecorder
/// - Deleguer les stats a TrekStats
class TrekSessionManagerNotifier extends Notifier<TrackingSessionState> {
  /// Abonnement aux points captes par l'isolate de fond (ecran eteint), pour
  /// les persister dans la trace de session (sessionTrackPoints).
  StreamSubscription<BgTrackPoint>? _bgPointsSub;

  @override
  TrackingSessionState build() {
    ref.onDispose(() {
      _bgPointsSub?.cancel();
    });
    return const TrackingSessionState();
  }

  /// Persiste un point capte de fond dans la table de trace (sessionTrackPoints)
  /// via le DAO Drift, en dedupliquant implicitement par la source (l'isolate de
  /// fond applique deja son filtre de distance). Best-effort.
  Future<void> _persistBgPoint(BgTrackPoint p) async {
    // DEMO : aucune trace GPS ecrite (tache 634). De toute facon le GPS est
    // coupe en demo — cette garde ferme le chemin meme si un point arrivait
    // d'une capture de fond restee armee d'une vraie rando precedente.
    if (ref.read(enDemoProvider)) return;
    final trailId = p.trailId.isNotEmpty ? p.trailId : _activeTrailId;
    if (trailId == null || trailId.isEmpty) return;
    final dao = ref.read(databaseProvider).sessionTrackPointsDao;
    // L3-1 : chaque point porte sa session, son jour de marche et l'etape
    // en cours. Sans ces trois reperes, la trace n'etait qu'un tas de
    // points et le trace du jour 3 restait inaccessible.
    final session = state.session;
    await dao.insertPoint(
      trailId: trailId,
      lat: p.latitude,
      lng: p.longitude,
      altitude: p.altitude,
      recordedAt: p.timestamp,
      sessionId: session?.id,
      dayIndex: session == null
          ? null
          : SessionTrackPointsDao.dayIndexFor(session.startedAt, p.timestamp),
      stageId: _currentStageId,
    );
  }

  /// Etape detectee sous les pieds du randonneur, notee par l'ecran carte
  /// (cf. `_ArrivalPipelineMount`) pour etiqueter les points de trace.
  ///
  /// Passe par un setter plutot que par un `ref.watch` de
  /// `currentStageIdProvider` : ce fichier est importe PAR `gps_providers`,
  /// l'importer en retour creerait une dependance croisee.
  String? _currentStageId;

  /// Note l'etape courante (L3-1). Sans effet sur l'etat expose a l'UI.
  void noteCurrentStage(String? stageId) {
    _currentStageId = (stageId != null && stageId.isNotEmpty) ? stageId : null;
  }

  /// Draine le tampon de points captes ecran eteint (rempli par l'isolate de
  /// fond) et les insere dans la trace. Appele au demarrage et au retour d'app.
  Future<void> _drainBackgroundBuffer() async {
    final service = ref.read(backgroundGpsServiceProvider);
    final points = await service.drainBackgroundPoints();
    for (final p in points) {
      await _persistBgPoint(p);
    }
  }

  /// Sentier de la session active (pour rattacher les points de fond).
  String? _activeTrailId;

  /// Persiste la session courante en local Drift (PARITE GR20, LOT 2, #99433).
  ///
  /// Branche la memoire du finisher sur la base : les mutations de session qui
  /// n'ont PAS lieu via le TrekRecorder — [recordStageCompleted] (etape marchee)
  /// et [completeOnArrival] (drapeau finisher) — doivent aussi etre ecrites pour
  /// SURVIVRE a un redemarrage. Best-effort (ne casse jamais le trek).
  Future<void> _persistSession(TrekSession session) async {
    // Le provider a pu etre dispose pendant un gap async (ex. ecran quitte) :
    // on evite tout acces a un Ref invalide.
    if (!ref.mounted) return;
    // DEMO : rien en base (tache 634). L'etat reste en memoire, ce qui suffit
    // a montrer tout le parcours et ne survit a rien.
    if (ref.read(enDemoProvider)) return;
    try {
      await ref.read(databaseProvider).trekSessionsDao.upsertSession(session);
    } catch (_) {
      // Best-effort : un echec de persistance ne doit pas casser le trek.
    }
  }

  /// Demarre une session de tracking sur le sentier [trailId].
  ///
  /// Cree la session via TrekRecorder.start() et passe en mode recording.
  /// Ne fait rien si une session est deja active.
  Future<void> start(String trailId) async {
    if (state.status == TrackingSessionStatus.recording ||
        state.status == TrackingSessionStatus.paused) {
      return;
    }

    final recorder = ref.read(trekRecorderProvider);
    final stats = ref.read(trekStatsProvider);
    stats.reset();

    final session = await recorder.start(trailId);
    _activeTrailId = trailId;
    state = TrackingSessionState(
      status: TrackingSessionStatus.recording,
      session: session,
    );

    // Capture GPS de fond fiabilisee (re-portage socle) : la trace ne doit pas
    // se couper ecran eteint. On (1) escalade les permissions de fond
    // (Toujours + notifications + exemption batterie) AU LANCEMENT du trek,
    // (2) demarre l'isolate de fond, (3) draine tout point deja tamponne, et
    // (4) persiste les points captes de fond dans la trace. Best-effort et NON
    // bloquant pour le premier plan (le tracking UI marche deja) : une escalade
    // de fond ratee ne casse jamais le demarrage.
    unawaited(_startBackgroundCapture(session.id, trailId));
  }

  /// Garde d'UNICITE de rando active (StepWays LOT 2, C4) : garantit **au plus
  /// une** session `active`|`paused`, CROSS-TRAIL et cross-restart, avant de
  /// demarrer le trek [trailId].
  ///
  /// Contrat de la machine C4 : on interroge la source d'unicite
  /// [TrekSessionsDao.findActiveSessions] (qui inclut `paused`, gap C4a) —
  /// AUTORITAIRE au-dela de l'etat en memoire (couvre une session orpheline
  /// laissee par un crash sur un AUTRE trek) :
  ///  * aucune session en cours -> demarrage direct ([start]) ;
  ///  * une session en cours sur le MEME trek -> idempotent, rien fait
  ///    ([StartOutcome.alreadyActiveSameTrail]) ;
  ///  * une session en cours sur un AUTRE trek -> on demande a l'UI via
  ///    [resolve] (dialog Terminer/Abandonner) :
  ///      - `finishCurrent`  -> [stop] la rando en cours, puis [start] ;
  ///      - `abandonCurrent` -> [abandon] la rando en cours, puis [start] ;
  ///      - `cancel`         -> on ne demarre pas ([StartOutcome.cancelled]).
  ///
  /// Si la rando en cours est CELLE du notifier (etat en memoire), on la termine
  /// via [stop]/[abandon] (teardown complet). Si elle est ORPHELINE (autre trek,
  /// pas dans l'etat en memoire), on la solde directement en base
  /// (`updateStatus`) — il n'y a pas de capture de fond a arreter pour elle.
  Future<StartOutcome> ensureSingleActiveThenStart(
    String trailId, {
    required ActiveTrekConflictResolver resolve,
  }) async {
    // 0. LE DROIT DE REALISER, AVANT TOUT LE RESTE (tache 594, A1).
    //
    // CE QUI MANQUAIT : rien, sur tout ce chemin, ne regardait si le trek
    // avait ete achete. La seule condition du bouton « Demarrer la randonnee »
    // portait sur la PREPARATION (itineraire + date + programme) et cette
    // garde-ci ne verifiait que l'UNICITE de session. Un utilisateur gratuit
    // demarrait, enregistrait et terminait le parcours entier — alors que le
    // modele eco reserve la realisation au trek achete. C'est le trou le plus
    // couteux de l'inventaire 593 (§M2), et le seul atteignable en trois
    // gestes depuis l'accueil.
    //
    // ON REFUSE AVANT D'OUVRIR QUOI QUE CE SOIT : aucune session creee, aucun
    // conflit resolu, aucune capture GPS demarree. Le refus est TYPE
    // ([StartOutcome.purchaseRequired]) pour que l'UI dise pourquoi et ou
    // acheter — un refus muet serait un geste mort (regle du LOT X).
    //
    // L'ABONNE EST REFUSE LUI AUSSI : l'abo light ne debloque pas la
    // realisation (arbitrage du 08/09, qui prime sur #99405). La vitrine
    // (parite GR20) passe, elle est resolue `owned` par `accessFor`.
    //
    // EN DEMO, ON NE DEMANDE PAS LE DROIT : ON SIMULE (tache 638, bug 16,
    // DEM-260930-1024). Christophe, 30/09 10:24 : « le bouton demarrer la rando
    // doit etre accessible en mode demo ! ». La demo NE DEBLOQUE PAS le droit —
    // `canRealizeTrail` repond exactement la meme chose qu'avant, et personne ne
    // le change : elle ouvre une SIMULATION, dont pas une ligne n'atteint la
    // base (toutes les persistances de session sont barrees plus haut dans ce
    // fichier). C'est la difference de fond avec le drapeau d'exemption
    // `isShowcaseTrail` que le lot 601 a supprime : la, le sentier payant
    // devenait realisable POUR DE VRAI et invendable ; ici il ne se passe
    // strictement rien de durable.
    if (ref.read(enDemoProvider)) {
      return demarrerSimulationDemo(trailId);
    }

    final monetization = ref.read(monetizationServiceProvider);
    if (!await monetization.canRealizeTrail(trailId)) {
      return StartOutcome.purchaseRequired;
    }

    final dao = ref.read(databaseProvider).trekSessionsDao;
    final ongoing = await dao.findActiveSessions();

    // 1. Rien en cours -> demarrage direct.
    if (ongoing.isEmpty) {
      await start(trailId);
      return StartOutcome.started;
    }

    // Session en cours la plus recente = celle qui occupe le creneau.
    final current = ongoing.reduce(
      (a, b) => a.startedAt.isAfter(b.startedAt) ? a : b,
    );

    // 2. Meme trek deja en cours -> idempotent.
    if (current.trailId == trailId) {
      return StartOutcome.alreadyActiveSameTrail;
    }

    // 3. Autre trek en cours -> l'UI tranche (dialog Terminer/Abandonner).
    final choice = await resolve(current.trailId);
    switch (choice) {
      case ActiveTrekConflictChoice.cancel:
        return StartOutcome.cancelled;
      case ActiveTrekConflictChoice.finishCurrent:
        await _resolveOngoing(current, status: 'completed');
        break;
      case ActiveTrekConflictChoice.abandonCurrent:
        await _resolveOngoing(current, status: 'abandoned');
        break;
    }

    await start(trailId);
    return StartOutcome.started;
  }

  /// DEMARRE LA SIMULATION DE LA RANDONNEE EN DEMO (tache 638, bug 16).
  ///
  /// Le chemin reel pose trois questions avant de demarrer : le DROIT
  /// (`canRealizeTrail`), l'UNICITE de rando active (une requete en base) et la
  /// capture GPS de fond. Aucune des trois n'a de sens pour une demonstration :
  /// la premiere refuserait (la demo ne debloque rien), la deuxieme ferait
  /// dependre une demonstration d'une vraie rando en cours, et la troisieme
  /// demanderait une permission de localisation pour marcher sans bouger.
  ///
  /// ON NE TOUCHE DONC PAS A LA BASE, NI A LA VRAIE RANDO. Si une vraie session
  /// est en cours en memoire, on REFUSE la simulation plutot que de l'ecraser :
  /// une demonstration ne doit jamais faire perdre son trek a quelqu'un. Le
  /// refus est type et l'ecran le dit.
  ///
  /// Le GPS de fond n'est pas arme (`_startBackgroundCapture` sort en demo), et
  /// la session creee ne s'ecrit nulle part (`_persistSession` sort en demo) :
  /// elle vit en memoire et meurt avec [arreterSimulationDemo].
  Future<StartOutcome> demarrerSimulationDemo(String trailId) async {
    if (!ref.read(enDemoProvider)) return StartOutcome.purchaseRequired;
    if (state.status == TrackingSessionStatus.recording ||
        state.status == TrackingSessionStatus.paused) {
      // Deja en cours : idempotent si c'est la simulation, refus si c'est une
      // vraie rando (on ne la remplace pas).
      return _activeTrailId == trailId
          ? StartOutcome.alreadyActiveSameTrail
          : StartOutcome.cancelled;
    }
    await start(trailId);
    return StartOutcome.started;
  }

  /// ARRETE LA SIMULATION DE DEMO SANS RIEN FINALISER NI RIEN ECRIRE
  /// (tache 638, bug 19 — la sortie atomique).
  ///
  /// A NE PAS CONFONDRE AVEC [stop] NI [abandon] : ceux-la FINALISENT une vraie
  /// randonnee (statut en base, fiche d'urgence eteinte, rafraichissement des
  /// vues de trek, drapeau finisher). Une simulation, elle, n'a rien a
  /// finaliser : elle n'existe nulle part. On rend donc le recorder disponible
  /// pour une VRAIE rando et on remet l'etat a zero, point.
  ///
  /// Appelee par `quitterLaDemo` PENDANT que la barriere d'ecriture est encore
  /// posee — c'est ce qui garantit que l'arret lui-meme n'ecrit rien.
  Future<void> arreterSimulationDemo() async {
    await _bgPointsSub?.cancel();
    _bgPointsSub = null;
    _activeTrailId = null;
    _currentStageId = null;
    // Le recorder doit repartir de zero, sinon un vrai demarrage ulterieur
    // leverait `StateError: session deja active`. En demo son unique ecriture
    // (`_onSessionPersist`) est barree, et son tampon de points est vide puisque
    // le GPS n'a jamais ete arme : cet arret n'ecrit rien.
    //
    // ON DEMANDE AVANT D'ARRETER (`isStopped`) : quitter la demo sans avoir
    // demarre de simulation est le cas le PLUS courant, et appeler `stop()` a
    // vide faisait remonter un `StateError` a l'ErrorHandler — un incident
    // rapporte pour un fonctionnement normal.
    final recorder = ref.read(trekRecorderProvider);
    if (!recorder.isStopped) {
      try {
        await recorder.stop();
      } catch (_) {
        // Best-effort : l'arret d'une simulation ne doit rien casser.
      }
    }
    ref.read(trekStatsProvider).reset();
    state = const TrackingSessionState();
  }

  /// Solde la session EN COURS [current] avant d'en demarrer une autre.
  ///
  /// Si [current] est la session vivante du notifier (etat en memoire), on
  /// passe par [stop]/[abandon] (teardown complet : capture de fond, abonnement,
  /// persistance autoritaire). Sinon (session ORPHELINE d'un autre trek), on la
  /// solde directement en base — il n'y a pas de tracking en memoire pour elle.
  Future<void> _resolveOngoing(
    TrekSession current, {
    required String status,
  }) async {
    final isInMemory =
        state.session?.id == current.id &&
        (state.status == TrackingSessionStatus.recording ||
            state.status == TrackingSessionStatus.paused);
    if (isInMemory) {
      if (status == 'abandoned') {
        await abandon();
      } else {
        await stop();
      }
      return;
    }
    // Session orpheline : solder son statut en base, best-effort.
    try {
      await ref
          .read(databaseProvider)
          .trekSessionsDao
          .upsertSession(
            current.copyWith(
              status: status,
              finishedAt: current.finishedAt ?? DateTime.now(),
            ),
          );
    } catch (_) {
      // Best-effort : un echec ne doit pas empecher le nouveau demarrage.
    }
  }

  /// Demarre la capture de fond + branche la persistance des points. Isole du
  /// chemin de demarrage principal (fire-and-forget) : ne jette jamais.
  ///
  /// NE DEMANDE AUCUNE PERMISSION (campagne personas 21/09, MAJEUR-1). Cette
  /// methode part en fire-and-forget pendant que la carte s'ouvre : l'escalade
  /// « Toujours autoriser » qu'elle lancait ici faisait surgir un ecran SYSTEME
  /// PAR-DESSUS la carte, sans explication, des la toute premiere rando — et
  /// entrait en collision avec la demande du bouton de demarrage. Les demandes
  /// se font maintenant AVANT, une seule fois, expliquees
  /// (`ensureBackgroundTrackingExplained`). Ici on se contente de ce qui est
  /// deja accorde : sans permission de fond la capture premier plan continue.
  Future<void> _startBackgroundCapture(String sessionId, String trailId) async {
    // DEMO : PAS DE GPS DU TOUT (tache 634, DEM-260929-1123). Christophe
    // demande une SIMULATION : « le randonneur avance sur les etapes sans
    // GPS ». Armer la capture de fond ecrirait en prefs et en base, et
    // demanderait une permission de localisation pour une demonstration.
    if (ref.read(enDemoProvider)) return;
    try {
      final service = ref.read(backgroundGpsServiceProvider);

      // Brancher la persistance AVANT le start pour ne perdre aucun point.
      await _bgPointsSub?.cancel();
      _bgPointsSub = service.trackPointStream.listen((p) {
        unawaited(_persistBgPoint(p));
      });

      await service.start(
        sessionId: sessionId,
        trailId: trailId,
        stageInfo: ref.read(trailConfigProvider).displayName,
      );

      // LA FICHE D'URGENCE MONTE SUR L'ECRAN VERROUILLE (tache 630). Le trek
      // commence : c'est le moment ou un secouriste peut avoir besoin de la lire
      // sans deverrouiller le telephone, et c'est le moment ou la permission
      // POST_NOTIFICATIONS vient d'etre accordee pour le service de fond. Elle
      // s'eteindra avec le trek (voir `_finalize`). Lancee, pas attendue, et non
      // levante : le raisonnement entier est dans `FicheEcranVerrouille`.
      unawaited(ref.read(ficheEcranVerrouilleProvider).allumer());

      // Draine un eventuel reliquat tamponne (session precedente interrompue).
      await _drainBackgroundBuffer();
    } catch (_) {
      // Best-effort : la capture de fond ne doit jamais casser le trek.
    }
  }

  /// Met en pause le tracking.
  void pause() {
    if (state.status != TrackingSessionStatus.recording) {
      return;
    }

    final recorder = ref.read(trekRecorderProvider);
    recorder.pause();
    state = state.copyWith(status: TrackingSessionStatus.paused);
  }

  /// Reprend le tracking apres une pause.
  void resume() {
    if (state.status != TrackingSessionStatus.paused) {
      return;
    }

    final recorder = ref.read(trekRecorderProvider);
    recorder.resume();
    state = state.copyWith(status: TrackingSessionStatus.recording);
  }

  /// Arrete le tracking et finalise la session en `completed`.
  Future<void> stop() async {
    await _finalize(status: 'completed');
  }

  /// Abandonne le trek en cours (StepWays LOT 2, C4 — machine d'unicite).
  ///
  /// Finalise la session courante en `abandoned`, SANS toucher a
  /// `parcoursFullyWalked` (jamais de faux finisher : un abandon n'ouvre pas la
  /// porte du diplome). Meme teardown que [stop] (capture de fond arretee,
  /// abonnement coupe, session persistee). Idempotent : ne fait rien hors
  /// session active|paused. C'est la 3ᵉ transition de la machine (Demarrer /
  /// Terminer / **Abandonner**) exigee par C4, utilisee par la garde
  /// [ensureSingleActiveThenStart] pour liberer le creneau avant d'en lancer un
  /// autre. La remise a zero de l'acquis cote droits (`onTrailAbandoned`) reste
  /// portee par le [MonetizationService] — non declenchee ici (separation des
  /// responsabilites : ce notifier gere la SESSION, pas les droits).
  Future<void> abandon() async {
    await _finalize(status: 'abandoned');
  }

  /// Abandonne une session ORPHELINE detectee au boot (StepWays LOT 2, C4 —
  /// reprise orpheline, complement §3).
  ///
  /// A distinguer de [abandon] : la session orpheline N'EST PAS celle vivante du
  /// notifier (l'app vient de demarrer — aucun tracking en memoire, aucune
  /// capture de fond a arreter). On la solde donc DIRECTEMENT en base
  /// (`status=abandoned` + `finishedAt`), sans teardown, exactement comme la
  /// branche orpheline de [_resolveOngoing]. `parcoursFullyWalked` n'est JAMAIS
  /// touche (jamais de faux finisher). Best-effort : un echec de persistance ne
  /// doit pas casser le demarrage. Renvoie `true` si le solde a reussi.
  ///
  /// Par securite (defense en profondeur) si [session] se trouvait etre CELLE du
  /// notifier — cas theorique, l'orpheline est par definition hors memoire — on
  /// delegue a [abandon] (teardown complet) plutot que d'ecrire en base a cote.
  Future<bool> abandonPendingSession(TrekSession session) async {
    final isInMemory =
        state.session?.id == session.id &&
        (state.status == TrackingSessionStatus.recording ||
            state.status == TrackingSessionStatus.paused);
    if (isInMemory) {
      await abandon();
      return true;
    }
    try {
      await ref
          .read(databaseProvider)
          .trekSessionsDao
          .upsertSession(
            session.copyWith(
              status: 'abandoned',
              finishedAt: session.finishedAt ?? DateTime.now(),
            ),
          );
      return true;
    } catch (_) {
      // Best-effort : un echec ne doit pas casser le demarrage.
      return false;
    }
  }

  /// Teardown + persistance communs a [stop] (completed) et [abandon]
  /// (abandoned). Facteur commun : seule la valeur de `status` ecrite en base
  /// change ; `parcoursFullyWalked` n'est JAMAIS pose ici (il l'est en amont par
  /// [completeOnArrival] uniquement, porte du finisher).
  Future<void> _finalize({required String status}) async {
    if (state.status != TrackingSessionStatus.recording &&
        state.status != TrackingSessionStatus.paused) {
      return;
    }

    // Arreter la capture de fond, draîner le reliquat et couper l'abonnement.
    try {
      final service = ref.read(backgroundGpsServiceProvider);
      await service.stop();
      await _drainBackgroundBuffer();
    } catch (_) {
      // Best-effort : l'arret du service ne doit pas empecher la finalisation.
    }

    // ET LA FICHE D'URGENCE QUITTE L'ECRAN VERROUILLE AVEC LE TREK (tache 630).
    // Une notification portant un nom, une adresse et un groupe sanguin ne doit
    // pas survivre des semaines a la randonnee qui la justifiait.
    await ref.read(ficheEcranVerrouilleProvider).eteindre();

    await _bgPointsSub?.cancel();
    _bgPointsSub = null;
    _activeTrailId = null;

    // Session AUTORITAIRE du notifier (porte completedStages + le drapeau
    // finisher). Capturee AVANT la finalisation pour la persister ensuite.
    final authoritative = state.session;

    final recorder = ref.read(trekRecorderProvider);
    await recorder.stop();

    // PARITE GR20, LOT 2 (#99433) : reecrire la session autoritaire finalisee
    // APRES le recorder. Le TrekRecorder persiste sa session INTERNE (sans
    // completedStages ni parcoursFullyWalked) : sans ce dernier upsert, l'etat
    // final en base perdrait la memoire du finisher. Meme id -> derniere ecriture
    // gagnante, avec les etapes marchees preservees. `status` distingue
    // completed (finish) d'abandoned (abandon) sans autre difference.
    if (authoritative != null) {
      await _persistSession(
        authoritative.copyWith(
          status: status,
          finishedAt: authoritative.finishedAt ?? DateTime.now(),
        ),
      );
    }

    final stats = ref.read(trekStatsProvider);
    final finalState = TrackingSessionState(
      status: TrackingSessionStatus.stopped,
      distanceKm: stats.distanceKm,
      elevationGainM: stats.elevationGain,
      elapsedDuration: stats.elapsedDuration,
      currentSpeedKmh: 0.0,
      avgSpeedKmh: stats.avgSpeedKmh,
    );
    state = finalState;

    // FIX-2 (finding M4) — RAFRAICHIR L'ETAT DERIVE DU TREK. Le cycle de vie
    // affiche par le cockpit ne vient PAS de ce notifier mais de
    // [currentTrailSummaryProvider] / [myTreksProvider], des FutureProvider qui
    // lisent la base UNE fois et ne s'invalident sur rien d'ecrit ici. Apres
    // « Terminer le trek », la session passait bien a `completed` en base, mais
    // le cockpit continuait de lire `inProgress` : il restait en phase
    // « Randonner » -> la section « Apres la randonnee » (Diplome, Recapitulatif)
    // n'etait JAMAIS construite, la carte Journal de la section Informations
    // restait masquee, et le bouton « Terminer le trek » restait propose alors
    // qu'il n'y avait plus rien a terminer. Les DONNEES etaient bien conservees,
    // c'est l'ACCES qui etait coince — exactement le finding M4. On invalide donc
    // les trois vues derivees a la fin de CHAQUE finalisation (fin manuelle,
    // abandon et arrivee GPS passent toutes par ici).
    ref.invalidate(currentTrailSummaryProvider);
    ref.invalidate(myTreksProvider);
    ref.invalidate(activeTrekIdProvider);

    // TACHE 651, DEFAUT A (MAJEUR) — ET LA SOURCE DE L'APRES-TREK AVEC ELLES.
    // FIX-2 avait rafraichi les trois vues du CYCLE DE VIE ci-dessus, mais pas
    // [latestTrekSessionProvider], qui est la source UNIQUE de tout ce qui
    // vient apres : `isRecapAvailableProvider`, `isDiplomaUnlockedProvider`,
    // `adventureStatsProvider` (donc « Mon aventure », le diplome, le journal,
    // les chiffres, la trace, le partage), et le verrou d'edition du programme
    // (`trekEditLockProvider`). C'est un `FutureProvider` qui lit la base UNE
    // fois, et il est tenu VIVANT pendant la rando par ce meme verrou : sa
    // valeur en cache restait la session `active` d'avant la fin. Le cockpit
    // basculait donc en phase « Apres » pendant que l'ecran de recap lisait
    // encore « en cours » et affichait « Disponible a la fin du trek » — deux
    // verites sur le meme trek au meme instant. Les DONNEES etaient justes en
    // base ; seule la RELECTURE manquait. Relue ici, donc pour les trois
    // chemins de sortie (fin manuelle, abandon, arrivee GPS).
    //
    // RELECTURE ATTENDUE, et non simplement invalidee : `isRecapAvailableProvider`
    // est fail-closed pendant le chargement (jamais de faux deverrouillage), et
    // la fin manuelle ouvre le recap DANS LA FOULEE de ce `stop()`. Une simple
    // invalidation, paresseuse, laissait donc l'ecran s'ouvrir sur l'etat
    // verrouille pendant la relecture — le meme ecran faux, pour une raison
    // differente. On attend la lecture (base locale, quelques millisecondes) ;
    // best-effort, car un echec de relecture ne doit pas empecher la fin du
    // trek, qui est deja ecrite en base.
    ref.invalidate(latestTrekSessionProvider);
    try {
      // La lecture qui suit VIDE l'invalidation en attente et attend la base :
      // a la sortie de `stop()`, l'apres-trek est deja deverrouille.
      await ref.read(latestTrekSessionProvider.future);
    } catch (_) {
      // Best-effort : le trek est termine quoi qu'il arrive.
    }
  }

  /// GO-85 inc2 (persistance ALPHA, porte du finisher) — enregistre l'etape
  /// [stageId] comme REELLEMENT completee sur la session courante.
  ///
  /// Appele a chaque arrivee detectee en fin d'etape (stageEnd/trailEnd) par le
  /// pont d'arrivee. Idempotent (Set-like : pas de doublon) et sans effet hors
  /// session active. Alimente [TrekSession.completedStages], le critere
  /// BLOQUANT que la gate du finisher ([completeOnArrival]) verifie : un
  /// demi-tour qui touche la derniere etape sans avoir marche les etapes
  /// intermediaires ne pourra pas terminer le parcours.
  void recordStageCompleted(String stageId) {
    final session = state.session;
    if (session == null) return;
    if (state.status != TrackingSessionStatus.recording &&
        state.status != TrackingSessionStatus.paused) {
      return;
    }
    if (session.completedStages.contains(stageId)) return;

    final updated = session.copyWith(
      completedStages: [...session.completedStages, stageId],
    );
    state = state.copyWith(session: updated);

    // PARITE GR20, LOT 2 (#99433) : persister l'etape marchee tout de suite ->
    // la memoire du finisher survit a un redemarrage (best-effort, non
    // bloquant : cette mutation ne passe pas par le TrekRecorder).
    unawaited(_persistSession(updated));
  }

  /// Termine le trek suite a la **detection d'arrivee a la derniere etape**
  /// (evenement `trailEnd`, direction-aware) — MAIS uniquement si la **porte du
  /// finisher** est ouverte.
  ///
  /// GO-85 inc2 (porte du finisher, port GR20) : la completion n'a lieu que si
  /// [fullyWalked] est vrai, c.-a-d. si TOUTES les etapes du parcours ont ete
  /// reellement marchees (cf. [TrekPlan.isFullyWalked] sur
  /// [TrekSession.completedStages]). Atteindre la derniere etape ne suffit PAS :
  /// un demi-tour ou une arrivee opportuniste (derniere etape touchee sans les
  /// intermediaires) est REFUSE — pas de finish, pas de felicitations. Le
  /// randonneur garde alors la main (arret manuel via [stop]).
  ///
  /// Quand la porte s'ouvre : on fige [TrekSession.parcoursFullyWalked] a vrai
  /// puis on finalise comme [stop] (statut `completed`). Idempotent : ne fait
  /// rien hors session active.
  Future<void> completeOnArrival({required bool fullyWalked}) async {
    if (state.status != TrackingSessionStatus.recording &&
        state.status != TrackingSessionStatus.paused) {
      return;
    }
    // Porte du finisher : parcours pas entierement marche -> pas de finish.
    if (!fullyWalked) return;

    // Trace du finisher legitime sur la session avant de finaliser.
    final session = state.session;
    if (session != null && !session.parcoursFullyWalked) {
      final finished = session.copyWith(parcoursFullyWalked: true);
      state = state.copyWith(session: finished);
      // PARITE GR20, LOT 2 (#99433) : persister le drapeau finisher (+ etapes
      // marchees). Fire-and-forget (best-effort) pour NE PAS inserer de gap
      // async avant stop() : la finalisation reste synchrone. La persistance
      // AUTORITAIRE est de toute facon reecrite dans stop() (derniere ecriture
      // gagnante), donc le flag survit au redemarrage meme si celui-ci echoue.
      unawaited(_persistSession(finished));
    }

    await stop();
  }

  /// Met a jour les stats depuis TrekStats.
  ///
  /// Appelee periodiquement par le pipeline GPS pour rafraichir
  /// les valeurs affichees dans l'overlay.
  void updateStats() {
    if (state.status != TrackingSessionStatus.recording) {
      return;
    }

    final stats = ref.read(trekStatsProvider);
    state = state.copyWith(
      distanceKm: stats.distanceKm,
      elevationGainM: stats.elevationGain,
      elapsedDuration: stats.elapsedDuration,
      currentSpeedKmh: stats.currentSpeedKmh,
      avgSpeedKmh: stats.avgSpeedKmh,
    );
  }
}

/// Provider principal du session manager de tracking.
///
/// Orchestre TrekRecorder (E2.8a) + TrekStats (E2.8b).
/// Expose un [TrackingSessionState] immutable a l'UI.
final trekSessionManagerProvider =
    NotifierProvider<TrekSessionManagerNotifier, TrackingSessionState>(
      TrekSessionManagerNotifier.new,
    );
