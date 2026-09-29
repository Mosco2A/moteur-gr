import "dart:async";

import "package:drift/drift.dart" show TableUpdateQuery;
import "package:flutter/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:logger/logger.dart";

import "../../features/auth/data/firebase_auth_service.dart";
import "../../features/auth/providers/auth_provider.dart";
import "../data/daos/progress_dao.dart";
import "../data/database.dart";
import "../firebase/firebase_service.dart";
import "../models/sync_config.dart";
import "../network/connectivity_monitor.dart";
import "../providers/database_provider.dart";
import "cloud_sync_service.dart";
import "fiche_technique_du_telephone.dart";

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// LA MONTEE EN BASE — LE TELEPHONE ECRIT ENFIN CE QUE CHRISTOPHE SAISIT
/// (tache 635).
///
/// LE DEFAUT MESURE, ET IL ETAIT DOUBLE. Toute la mecanique de montee existait
/// depuis le LOT A5 (`CloudSyncService.syncUserData`), et DEUX ordonnanceurs
/// etaient censes la reveiller : celui-ci et `BackgroundSyncService`. Recherche
/// faite dans tout `lib/` le 29/09 : ni l un ni l autre n avait le moindre
/// appelant. Deux horloges mortes pour un travail que personne ne declenchait —
/// exactement le meme trou que `syncWallet` avant le lot 631, et que
/// `UpdateDownloader.scheduleBackgroundDownload` avant le lot 616. Le second
/// ordonnanceur a ete RETIRE avec ce lot : garder deux mecaniques dont une seule
/// est branchee, c est garder un piege.
///
/// CE QUE CHRISTOPHE ATTEND, MOT POUR MOT (29/09) : « je veux voir toutes les
/// donnees en base qui se mettent a jour quand je rentre des infos dans
/// l appli ». Il regarde la console Firestore PENDANT qu il touche son
/// telephone. Une cadence horaire ne repond pas a cette demande ; il faut que
/// l ecriture locale POUSSE.
///
/// LES QUATRE REVEILS, ET ILS SONT DE NATURES DIFFERENTES :
///
///  1. LE DEMARRAGE, apres la connexion anonyme. On pose la fiche technique et
///     on rattrape TOUT ce qui attendait (la file `sync_queue`), puis on monte
///     l etat courant de chaque sentier connu. C est ce qui fait qu un
///     telephone reste hors ligne trois jours n a rien perdu.
///  2. CHAQUE ECRITURE LOCALE — etape validee, sac coche, rando saisie. C est LE
///     reveil de Christophe. Il est DEBOUNCE a trois secondes : cocher dix
///     articles d affilee ne doit pas produire dix montees, et trois secondes
///     restent sous le seuil ou l on se demande si ca marche.
///  3. LE RETOUR DU RESEAU. `ConnectivityMonitor.onStatusChange` rend deja un
///     flux debounce a cinq secondes : un reseau qui clignote en bord de
///     couverture ne declenche donc pas dix passes.
///  4. LE RETOUR AU PREMIER PLAN, pour la seule `last_seen_at` de la fiche
///     technique. Rien d autre : revenir sur l application n est pas un
///     evenement de donnee.
///
/// HORS LIGNE, RIEN NE SE PERD, ET C EST LE CAS NOMINAL EN MONTAGNE. Quand la
/// montee ne peut pas partir, chaque sentier concerne est INSCRIT DANS LA FILE
/// (`sync_queue`, action `cloud_sync_batch`) — une seule fois par sentier, pas
/// une par geste — et le retour du reseau la vide. Sans Firebase du tout (mode
/// local, aucun `--dart-define`), on n inscrit rien : il n y a pas de
/// destinataire, et remplir une file qui ne sera jamais lue serait mentir.
///
/// CE QUI MONTE ET CE QUI NE MONTE PAS est decide dans [CloudSyncService], pas
/// ici : cet objet sait QUAND reveiller, pas QUOI envoyer. En deux mots : la
/// progression, le sac et les randos passees montent ; le journal, la fiche
/// sante, les photos, les contacts d urgence et la morphologie restent sur le
/// telephone. Le COMPTE, lui, ne fait que DESCENDRE (tache 631).
class SyncScheduler with WidgetsBindingObserver {
  SyncScheduler({
    required this.cloudSyncService,
    required this.connectivityMonitor,
    required this.firebaseService,
    required this.progressDao,
    this.ficheTechnique,
    this.attenteAvantMontee = attenteParDefaut,
    this.config = const SyncConfig(),
    this.identifiantLocalDesRandos = "local",
    this.observerLeCycleDeVie = true,
  });

  /// LE DELAI DE CHRISTOPHE : TROIS SECONDES AU PLUS.
  ///
  /// C est la borne haute de sa demande, pas une valeur choisie au hasard : il
  /// doit voir la console bouger pendant qu il a encore le telephone en main.
  /// Assez long pour absorber une rafale de cases cochees, assez court pour
  /// qu on ne se demande pas si ca marche.
  static const Duration attenteParDefaut = Duration(seconds: 3);

  final CloudSyncService cloudSyncService;
  final ConnectivityMonitor connectivityMonitor;
  final FirebaseService firebaseService;

  /// Pour savoir QUELS sentiers ce telephone connait. Un randonneur qui a
  /// commence deux sentiers doit voir les deux au serveur, pas seulement celui
  /// qu il regarde.
  final ProgressDao progressDao;

  /// La fiche technique `users/{uid}`. Nullable : une instance de test qui ne
  /// s y interesse pas n a pas a la fabriquer.
  final FicheTechniqueDuTelephone? ficheTechnique;

  /// Le delai de regroupement des ecritures locales.
  final Duration attenteAvantMontee;

  final SyncConfig config;

  /// La cle sous laquelle les randos passees sont rangees EN LOCAL
  /// (`kHikerLocalUserId`), a ne pas confondre avec l identifiant du compte.
  final String identifiantLocalDesRandos;

  /// Faux dans les tests qui n ont pas de liaison Flutter a observer.
  final bool observerLeCycleDeVie;

  Timer? _attente;
  StreamSubscription<ConnectivityStatus>? _ecouteReseau;
  StreamSubscription<void>? _ecouteEcritures;
  String? _userId;
  bool _enCours = false;
  bool _redemander = false;
  int _monteesExecutees = 0;
  bool _observe = false;

  /// Vrai quand la montee est armee pour un compte.
  bool get isRunning => _userId != null;

  /// Vrai quand une ecriture locale attend son tour de montee.
  bool get monteeEnAttente => _attente?.isActive ?? false;

  /// Vrai quand une passe est en train de tourner.
  ///
  /// Mesure, pas decoration : c est ce qui permet a un test d attendre la fin
  /// d une passe lancee au demarrage sans deviner une duree, et c est aussi ce
  /// qui rend visible, en journal, une montee qui tarde.
  bool get enCours => _enCours;

  /// Nombre de montees REELLEMENT parties. Mesure, pas decoration : c est ce
  /// qui permet a un test d affirmer qu une rafale de gestes n en produit
  /// qu une.
  int get monteesExecutees => _monteesExecutees;

  /// ARME LA MONTEE POUR [userId]. Idempotent : un second appel reprend a zero.
  ///
  /// [ecrituresLocales] est le flux des changements de la base locale (les
  /// tables de progression, de sac et de randos passees). Il est injecte plutot
  /// que construit ici : cet objet n a pas a connaitre Drift, et un test doit
  /// pouvoir pousser un evenement sans base.
  ///
  /// NE BLOQUE PAS LE DEMARRAGE : la fiche technique et le rattrapage partent
  /// sans etre attendus. Le premier ecran ne doit pas attendre le reseau.
  Future<void> demarrer({
    required String userId,
    Stream<void>? ecrituresLocales,
  }) async {
    if (_userId != null) await arreter();
    if (userId.isEmpty) {
      _log.d("[Montee] Aucun identifiant de compte — montee inactive.");
      return;
    }
    _userId = userId;

    if (observerLeCycleDeVie) {
      try {
        WidgetsBinding.instance.addObserver(this);
        _observe = true;
      } on Object catch (e) {
        _log.d("[Montee] Cycle de vie non observable ($e) — ignore.");
      }
    }

    _ecouteReseau = connectivityMonitor.onStatusChange.listen(
      _auChangementDeReseau,
      onError: (Object e) => _log.w("[Montee] Flux de connectivite : $e"),
    );

    _ecouteEcritures = ecrituresLocales?.listen(
      (_) => signalerUneEcritureLocale(),
      onError: (Object e) => _log.w("[Montee] Flux des ecritures locales : $e"),
    );

    // LA FICHE TECHNIQUE D ABORD, ET SANS DEPENDRE DU RESTE. C est elle qui
    // fait EXISTER `users/{uid}` — sans elle la console montre l utilisateur en
    // italique, ce que Christophe a lu comme « pas d utilisateur en base ».
    unawaited(_poserLaFicheTechnique("demarrage"));

    // PUIS LE RATTRAPAGE. Non attendu, pour la meme raison.
    unawaited(monterMaintenant("demarrage"));

    _log.d(
      "[Montee] Armee : demarrage + ecritures locales (debounce "
      "${attenteAvantMontee.inSeconds} s) + retour du reseau + premier plan.",
    );
  }

  /// Desarme tout. Idempotent.
  ///
  /// UNE PASSE DEJA EN COURS N EST PAS INTERROMPUE : elle est a mi-chemin entre
  /// la base locale et le serveur, et l abandonner laisserait un sentier monte
  /// et le suivant non. Elle finira, puis plus rien ne la relancera. Meme
  /// raisonnement que l ordonnanceur de la tache 616.
  Future<void> arreter() async {
    _attente?.cancel();
    _attente = null;
    await _ecouteReseau?.cancel();
    _ecouteReseau = null;
    await _ecouteEcritures?.cancel();
    _ecouteEcritures = null;
    if (_observe) {
      try {
        WidgetsBinding.instance.removeObserver(this);
      } on Object {
        // Liaison deja demontee : rien a faire.
      }
      _observe = false;
    }
    _userId = null;
    _log.d("[Montee] Desarmee.");
  }

  /// UNE ECRITURE LOCALE VIENT D AVOIR LIEU — on montera dans trois secondes.
  ///
  /// Chaque appel REPOUSSE l echeance : c est ce qui transforme une rafale de
  /// cases cochees en une seule montee. Le compteur du minuteur est le seul
  /// etat : pas de file de gestes a tenir, donc rien a perdre.
  void signalerUneEcritureLocale() {
    if (_userId == null) return;
    _attente?.cancel();
    _attente = Timer(
      attenteAvantMontee,
      () => unawaited(monterMaintenant("ecriture locale")),
    );
  }

  /// UNE PASSE DE MONTEE. Ne leve jamais. Rend le nombre de documents ecrits.
  ///
  /// UNE SEULE A LA FOIS, ET LE VERROU SE POSE AVANT LE PREMIER `await` : les
  /// reveils peuvent tomber ensemble (une ecriture locale a l instant ou le
  /// reseau revient). Une passe demandee pendant qu une autre tourne n est pas
  /// PERDUE — elle est REJOUEE a la fin, sinon le dernier geste du randonneur,
  /// celui qui a declenche la demande, ne monterait jamais.
  Future<int> monterMaintenant([String cause = "appel direct"]) async {
    final userId = _userId;
    if (userId == null) return 0;
    if (_enCours) {
      _redemander = true;
      _log.d("[Montee] Passe ($cause) differee : une montee tourne deja.");
      return 0;
    }
    _enCours = true;
    try {
      return await _monter(userId, cause);
    } catch (e) {
      // UNE PASSE QUI ECHOUE NE TUE PAS LA MONTEE. Le prochain geste ou le
      // prochain retour de reseau reessaiera. Avaler sans DIRE serait la faute
      // inverse.
      _log.e("[Montee] Passe ($cause) en echec : $e");
      return 0;
    } finally {
      _enCours = false;
      if (_redemander) {
        _redemander = false;
        unawaited(monterMaintenant("$cause (rejouee)"));
      }
    }
  }

  Future<int> _monter(String userId, String cause) async {
    if (!firebaseService.isAvailable) {
      _log.d("[Montee] Passe ($cause) sans effet : Firebase indisponible.");
      return 0;
    }

    final ConnectivityStatus statut;
    try {
      statut = await connectivityMonitor.checkStatus();
    } on Object catch (e) {
      _log.w("[Montee] Connectivite illisible ($e) — mise en file.");
      await _mettreEnFile(userId);
      return 0;
    }
    if (statut == ConnectivityStatusValues.offline) {
      _log.d("[Montee] Passe ($cause) hors ligne : mise en file.");
      await _mettreEnFile(userId);
      return 0;
    }

    var total = 0;

    // 1. LE RATTRAPAGE D ABORD. Ce qui attendait depuis hier passe avant ce qui
    //    vient d etre saisi : sinon un telephone longtemps hors ligne verrait sa
    //    file grossir pendant que le present monte.
    final rattrapage = await cloudSyncService.catchUpOnReconnect(
      userId,
      config: config,
    );
    if (rattrapage.status == CloudSyncStatusValues.success) {
      total += rattrapage.itemsSynced;
    }

    // 2. TOUS LES SENTIERS CONNUS, pas seulement celui qui est affiche.
    final connus = await progressDao.getAll();
    for (final ligne in connus) {
      final r = await cloudSyncService.syncUserData(
        userId,
        ligne.trailId,
        config: config,
      );
      if (r.status == CloudSyncStatusValues.success) {
        total += r.itemsSynced;
      }
    }

    // 3. LES RANDOS PASSEES. Deux identifiants distincts, voir
    //    [CloudSyncService.syncPastHikes] : le chemin au serveur porte
    //    l identifiant d authentification, la lecture locale une cle locale.
    final randos = await cloudSyncService.syncPastHikes(
      userId,
      identifiantLocal: identifiantLocalDesRandos,
    );
    if (randos.status == CloudSyncStatusValues.success) {
      total += randos.itemsSynced;
    }

    _monteesExecutees++;
    _log.d("[Montee] Passe ($cause) terminee : $total document(s).");
    return total;
  }

  /// INSCRIT CHAQUE SENTIER CONNU DANS LA FILE, UNE SEULE FOIS.
  ///
  /// La file n a pas de contrainte d unicite (`id` auto-incremente) : sans ce
  /// filtre, rester hors ligne une journee en cochant son sac y deposerait des
  /// centaines de lignes identiques, toutes rejouees au retour du reseau.
  Future<void> _mettreEnFile(String userId) async {
    if (!firebaseService.isAvailable) return;
    final connus = await progressDao.getAll();
    for (final ligne in connus) {
      final deja = await cloudSyncService.syncQueueDao.getByTrailId(
        ligne.trailId,
      );
      final dejaEnAttente = deja.any(
        (a) => a.status == "pending" && a.action == "cloud_sync_batch",
      );
      if (dejaEnAttente) continue;
      await cloudSyncService.pushBatchHourly(userId, ligne.trailId);
    }
  }

  void _auChangementDeReseau(ConnectivityStatus statut) {
    if (statut != ConnectivityStatusValues.online) return;
    if (!config.syncOnReconnect) return;
    unawaited(monterMaintenant("retour du reseau"));
  }

  /// LE RETOUR AU PREMIER PLAN NE MONTE QUE LA DERNIERE VENUE.
  ///
  /// Revenir sur l application n est pas un evenement de donnee : rien n a
  /// change en base pendant qu elle etait derriere. Y declencher une montee
  /// complete ferait du va-et-vient entre deux applications un generateur de
  /// trafic.
  Future<void> auRetourAuPremierPlan() =>
      _poserLaFicheTechnique("premier plan");

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(auRetourAuPremierPlan());
    }
  }

  Future<void> _poserLaFicheTechnique(String cause) async {
    final fiche = ficheTechnique;
    if (fiche == null || _userId == null) return;
    try {
      final posee = await fiche.poser();
      _log.d(
        "[Montee] Fiche technique ($cause) : ${posee ? "posee" : "sans effet"}",
      );
    } on Object catch (e) {
      _log.w("[Montee] Fiche technique ($cause) en echec : $e");
    }
  }
}

/// Provider de la montee. Il ne demarre PAS tout seul : un provider lu par un
/// test ne doit pas se mettre a ecrire au serveur.
final syncSchedulerProvider = Provider<SyncScheduler>((ref) {
  final db = ref.watch(databaseProvider);
  final montee = SyncScheduler(
    cloudSyncService: ref.watch(cloudSyncServiceProvider),
    connectivityMonitor: ref.watch(connectivityMonitorProvider),
    firebaseService: ref.watch(firebaseServiceProvider),
    progressDao: ProgressDao(db),
    ficheTechnique: ref.watch(ficheTechniqueDuTelephoneProvider),
  );
  ref.onDispose(montee.arreter);
  return montee;
});

/// LES TROIS TABLES DONT UN CHANGEMENT DOIT FAIRE MONTER QUELQUE CHOSE.
///
/// POURQUOI ON ECOUTE LA BASE PLUTOT QUE D INSTRUMENTER LES ECRANS. La
/// progression, le sac et les randos passees s ecrivent depuis une vingtaine
/// d endroits (`checklist_provider` a lui seul ouvre le DAO dix fois). Appeler
/// la montee a chacun d eux, c est vingt occasions d en oublier un — et un
/// oubli ne se voit pas : la donnee reste simplement sur le telephone, en
/// silence, ce qui est EXACTEMENT le defaut que ce lot corrige. Drift signale
/// tout changement de table ; un seul branchement couvre donc tous les gestes,
/// presents et futurs.
///
/// LE JOURNAL N Y EST PAS, et c est volontaire : il ne monte plus (tache 635).
TableUpdateQuery _tablesQuiFontMonter(AppDatabase db) {
  return TableUpdateQuery.allOf([
    TableUpdateQuery.onTable(db.userProgressEntries),
    TableUpdateQuery.onTable(db.checklistItems),
    TableUpdateQuery.onTable(db.pastHikeEntries),
  ]);
}

/// LE GESTE QUI BRANCHE LA MONTEE, ET IL N EXISTAIT PAS.
///
/// Observe par `_BootstrapGate` dans `main.dart` — la garde qui vit au-dessus du
/// `Navigator` et ne se demonte JAMAIS. C est la seule place correcte, pour la
/// meme raison que la cadence (tache 616) et l ecoute des droits (tache 631) :
/// Riverpod met en PAUSE les abonnements d un ecran qui n est plus a
/// l avant-plan, et une montee qui s arrete quand on navigue n est pas une
/// montee.
///
/// IL ATTEND L IDENTITE, ET C EST TOUT CE QU IL ATTEND. Sans identifiant de
/// compte il n y a pas de `users/{uid}` a ecrire : la montee ne s arme pas, en
/// silence, et l application marche sur sa base locale exactement comme avant.
/// `garantirUneIdentite()` est idempotente et ne leve pas (tache 631).
///
/// EN MODE LOCAL (aucun `--dart-define=STEPWAYS_FIREBASE_PROJECT_ID`), le
/// service d authentification n est pas celui de Firebase : rien ne s arme, et
/// c est le comportement attendu, pas une panne.
final monteeEnBaseDemarreeProvider = Provider<void>((ref) {
  final montee = ref.watch(syncSchedulerProvider);
  final db = ref.watch(databaseProvider);
  final auth = ref.read(authServiceProvider);

  if (auth is! FirebaseAuthService) {
    _log.d("[Montee] Mode local : aucune identite serveur, montee inactive.");
    return;
  }

  unawaited(() async {
    await auth.garantirUneIdentite();
    final uid = auth.identifiantDeCompte;
    if (uid == null || uid.isEmpty) {
      _log.d("[Montee] Identite absente au demarrage — montee non armee.");
      return;
    }
    await montee.demarrer(
      userId: uid,
      ecrituresLocales: db.tableUpdates(_tablesQuiFontMonter(db)),
    );
  }());
});
