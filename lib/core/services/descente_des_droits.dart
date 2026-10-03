/// Le sens manquant du miroir de compte : faire DESCENDRE solde et droits du
/// serveur vers le telephone, pas seulement les faire monter.
library;

import "dart:async";

import "package:cloud_firestore/cloud_firestore.dart";
import "package:drift/drift.dart" show Value;
import "package:firebase_auth/firebase_auth.dart" as fb;
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../data/daos/no_ads_dao.dart";
import "../data/daos/trek_entitlements_dao.dart";
import "../data/database.dart";
import "../data/revision_de_donnee.dart";
import "../firebase/firebase_service.dart";
import "../network/connectivity_monitor.dart";
import "../providers/database_provider.dart";
import "droits_distants.dart";
import "monetization_service.dart";
import "wallet_store.dart";

/// LA DESCENTE DES DROITS — LA MOITIE QUI MANQUAIT (tache 631).
///
/// CE QU ELLE REGLE, ET C EST MESURE. `cloud_sync_service.dart` portait deja un
/// miroir du compte (`users/{uid}/wallet/current`, `users/{uid}/entitlements/
/// {trailId}`) depuis le LOT A5. Deux trous, tous les deux verifies dans le
/// depot :
///   1. IL NE FAIT QUE MONTER. Les methodes existantes sont `pushBatchHourly`,
///      `pushOnRefugeArrival`, `pushEncryptedBackup` et une seule descente,
///      `pullEncryptedBackup`, qui ne concerne QUE la sauvegarde chiffree.
///      Aucune descente des droits n existait : ce qu on ecrit au serveur
///      n arrive jamais sur le telephone.
///   2. ET IL NE MONTE MEME PAS. `syncWallet` n est appelee de NULLE PART dans
///      `lib/` — verifie. Le miroir n a donc jamais rien contenu.
///
/// CE QU ELLE APPLIQUE, ET RIEN D AUTRE. Le COMPTE : solde d etapes, droits de
/// sentier, abonnement sans-pub. Decision de Christophe du 29/09 13:43-13:44 :
/// « je veux que tout soit en base ... seul la copie sur le tel », « sauf les
/// donnees persos ». LES DONNEES PERSONNELLES NE PASSENT PAS PAR ICI : ni fiche
/// medicale, ni profil, ni contacts, ni journal, ni progression, ni photos. Ce
/// fichier ne connait AUCUN de ces champs, et les suites 612 / 613 / 615 / 617
/// le verifient de leur cote. Le miroir reste NON NOMINATIF : un identifiant,
/// des entiers, des instants. Rien qui dise QUI.
///
/// CE N EST PAS UNE PORTE DEROBEE. C est le chemin par lequel passeront les
/// VRAIS achats quand la caisse sera branchee — la confirmation du magasin
/// ecrira au serveur, et le telephone lira ici — et c est aussi ce qu il faut
/// pour retrouver ses achats en changeant de telephone. Le compte de test
/// (`core/config/compte_de_test.dart`) est la mesure provisoire qui ecrit EN
/// LOCAL exactement ce que cette descente ecrit ; il disparait le jour ou elle
/// tourne pour de vrai.
///
/// HORS LIGNE, RIEN NE CASSE, ET C EST LE CAS NOMINAL EN MONTAGNE. Pas de
/// Firebase, pas de reseau, pas d identifiant : la descente rend une raison et
/// n ecrit RIEN. L application continue sur sa base locale exactement comme
/// aujourd hui. Elle ne leve jamais : une descente qui empecherait de marcher
/// serait pire que pas de descente.
///
/// LA REGLE DE RESOLUTION est demontree dans `droits_distants.dart`. En une
/// phrase : le serveur fait foi, mais on ne le laisse pas EFFACER ce qu il ne
/// peut pas savoir — les compteurs du compte se fusionnent par leur maximum
/// (donc une depense faite hors ligne ne revient jamais), les droits de sentier
/// sont des loquets, et seul l abonnement — le seul qui puisse DESCENDRE — est
/// arbitre par l horodatage de serveur du lot 610.
class DescenteDesDroits {
  DescenteDesDroits({
    required this.stageCount,
    required this.entitlementsDao,
    required this.noAdsDao,
    required this.firebaseService,
    required this.connectivityMonitor,
    required this.identifiant,
    required this.preferences,
    FirebaseFirestore? firestore,
    this.apresApplication,
  }) : _firestore = firestore;

  /// Le compte-etapes local (source durable : preferences + miroir Drift).
  final WalletStore stageCount;

  /// Les droits de sentier locaux.
  final TrekEntitlementsDao entitlementsDao;

  /// L abonnement sans-pub local.
  final NoAdsDao noAdsDao;

  /// Firebase est-il seulement la ?
  final FirebaseService firebaseService;

  /// Y a-t-il du reseau ?
  final ConnectivityMonitor connectivityMonitor;

  /// QUI LIT — l identifiant du compte cote serveur.
  ///
  /// INJECTE, et pas lu ici. Deux raisons : la descente se verifie alors sans
  /// Firebase Auth, et surtout les regles de securite du depot
  /// (`firestore.rules`) n autorisent `users/{userId}` QUE si
  /// `request.auth.uid == userId`. C est donc l identifiant d authentification
  /// qui doit etre passe, et pas autre chose. VOIR LE POINT OUVERT EN BAS DE
  /// FICHIER : le miroir A5, lui, ecrit sous le HASH anonymise, ce qu aucune
  /// regle n autorise — et personne ne l a vu parce que rien ne l appelle.
  final Future<String?> Function() identifiant;

  /// Ou l on retient le dernier instant d abonnement applique.
  final SharedPreferences preferences;

  /// Appele APRES une application reussie.
  ///
  /// Sert a resynchroniser le cache synchrone des gardes de routes
  /// (`FeatureFlags`) via `MonetizationService.load()` : sans lui, un sentier
  /// qui vient de descendre serait possede en base mais encore verrouille pour
  /// les gardes qui lisent le cache.
  final Future<void> Function()? apresApplication;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _base => _firestore ?? FirebaseFirestore.instance;

  final List<StreamSubscription<Object?>> _ecoutes = [];
  bool _enCours = false;

  /// Vrai quand l ecoute en direct est armee.
  bool get ecouteArmee => _ecoutes.isNotEmpty;

  /// Cle de l instant d abonnement deja applique (millisecondes epoch).
  static const String subscriptionTimestampPrefsKey =
      "droits.abonnement.horodatage";

  /// L ECOUTE EN DIRECT — CE QUE CHRISTOPHE VERRA ARRIVER SANS RIEN FAIRE.
  ///
  /// POURQUOI ELLE EXISTE, ET POURQUOI LA CADENCE NE SUFFIT PAS. Le scenario
  /// d acceptation est : on ecrit deux etapes depuis le PC, et elles doivent
  /// apparaitre dans l application OUVERTE, sans la fermer ni la reinstaller.
  /// L ordonnanceur se reveille toutes les quatre heures — c est le bon rythme
  /// pour des sentiers de plusieurs dizaines de mega-octets, c est une eternite
  /// pour trois petits documents qu on regarde changer.
  ///
  /// TROIS ECOUTES, PARCE QU IL Y A TROIS ECRITURES INDEPENDANTES : le solde,
  /// les sentiers, l abonnement. Chacune peut etre posee seule, dans n importe
  /// quel ordre, et chacune doit se voir arriver seule.
  ///
  /// CHAQUE EVENEMENT RELIT LES TROIS, plutot que d appliquer le seul document
  /// qui a bouge. C est volontairement plus simple : trois lectures de document
  /// coutent une misere, la regle de fusion reste la MEME que pour la cadence
  /// (donc un seul comportement a comprendre et a prouver), et on ne peut pas se
  /// retrouver avec deux chemins d application qui divergent.
  ///
  /// SANS FIREBASE OU SANS IDENTITE, ELLE NE S ARME PAS et le dit. L application
  /// continue sur sa base locale.
  Future<bool> ecouterEnDirect() async {
    if (_ecoutes.isNotEmpty) return true;
    if (!firebaseService.isAvailable) return false;

    final String? uid;
    try {
      uid = await identifiant();
    } on Object {
      return false;
    }
    if (uid == null || uid.isEmpty) return false;

    final racine = _base.collection("users").doc(uid);

    void surChangement(String quoi) {
      // Non attendu : un evenement Firestore ne doit pas bloquer le flux.
      unawaited(() async {
        final r = await executer();
        debugPrint("[DescenteDesDroits] en direct ($quoi) : $r");
      }());
    }

    try {
      _ecoutes.add(
        racine
            .collection("wallet")
            .doc("current")
            .snapshots()
            .listen(
              (_) => surChangement("solde"),
              onError: (Object e) =>
                  debugPrint("[DescenteDesDroits] ecoute solde : $e"),
            ),
      );
      _ecoutes.add(
        racine
            .collection(kEntitlementsPath)
            .snapshots()
            .listen(
              (_) => surChangement("sentiers"),
              onError: (Object e) =>
                  debugPrint("[DescenteDesDroits] ecoute sentiers : $e"),
            ),
      );
      _ecoutes.add(
        racine
            .collection("subscription")
            .doc("current")
            .snapshots()
            .listen(
              (_) => surChangement("abonnement"),
              onError: (Object e) =>
                  debugPrint("[DescenteDesDroits] ecoute abonnement : $e"),
            ),
      );
      return true;
    } on Object catch (e) {
      debugPrint("[DescenteDesDroits] ecoute impossible : $e");
      await cesserDEcouter();
      return false;
    }
  }

  /// Coupe l ecoute en direct.
  Future<void> cesserDEcouter() async {
    for (final e in List.of(_ecoutes)) {
      await e.cancel();
    }
    _ecoutes.clear();
  }

  /// UNE PASSE DE DESCENTE. Ne leve jamais.
  ///
  /// UNE SEULE A LA FOIS : l ecoute en direct et la cadence peuvent tomber
  /// ensemble (une ecriture au moment ou les quatre heures echoient). Deux
  /// passes concurrentes liraient le meme etat local et se marcheraient dessus
  /// sur le compte-etapes. Meme raisonnement que le verrou de l ordonnanceur.
  Future<ResultatDescente> executer() async {
    if (_enCours) {
      return const ResultatDescente.sansEffet("une descente tourne deja");
    }
    _enCours = true;
    try {
      return await _executer();
    } finally {
      _enCours = false;
    }
  }

  Future<ResultatDescente> _executer() async {
    if (!firebaseService.isAvailable) {
      return const ResultatDescente.sansEffet("Firebase indisponible");
    }

    final ConnectivityStatus statut;
    try {
      statut = await connectivityMonitor.checkStatus();
    } on Object catch (e) {
      return ResultatDescente.sansEffet("connectivite illisible : $e");
    }
    if (statut == ConnectivityStatusValues.offline) {
      return const ResultatDescente.sansEffet("hors ligne");
    }

    final String? uid;
    try {
      uid = await identifiant();
    } on Object catch (e) {
      return ResultatDescente.sansEffet("identifiant illisible : $e");
    }
    if (uid == null || uid.isEmpty) {
      return const ResultatDescente.sansEffet("aucun identifiant de compte");
    }

    final DroitsDistants annonces;
    try {
      annonces = await lire(uid);
    } on Object catch (e) {
      // Un refus de regle, une coupure en plein transport : on le DIT et on
      // laisse la copie locale intacte.
      return ResultatDescente.sansEffet("lecture refusee ou coupee : $e");
    }
    if (annonces.estVide) {
      return const ResultatDescente.sansEffet("le serveur n annonce rien");
    }

    try {
      return await appliquer(annonces);
    } on Object catch (e) {
      return ResultatDescente.sansEffet("application impossible : $e");
    }
  }

  /// LIT les trois documents du compte. Aucune ecriture.
  @visibleForTesting
  Future<DroitsDistants> lire(String uid) async {
    final racine = _base.collection("users").doc(uid);

    final solde = SoldeDistant.lire(
      (await racine.collection("wallet").doc("current").get()).data(),
    );

    final trails = <DroitDeSentierDistant>[];
    final lot = await racine.collection(kEntitlementsPath).get();
    for (final doc in lot.docs) {
      final lu = DroitDeSentierDistant.lire(doc.id, doc.data());
      if (lu != null) trails.add(lu);
    }

    final subscription = AbonnementDistant.lire(
      (await racine.collection("subscription").doc("current").get()).data(),
    );

    return DroitsDistants(
      solde: solde,
      trails: trails,
      subscription: subscription,
    );
  }

  /// APPLIQUE ce que le serveur annonce, selon la regle de resolution.
  @visibleForTesting
  Future<ResultatDescente> appliquer(DroitsDistants annonces) async {
    var quelqueChose = false;
    final sentiersTouches = <String>[];

    // --- LE COMPTE-ETAPES : maximum des deux compteurs monotones ------------
    final distantSolde = annonces.solde;
    if (distantSolde != null) {
      final local = stageCount.snapshot;
      final fusion = fusionnerSolde(
        gagneLocal: local.lifetimeEarnedSteps,
        depenseLocal: local.lifetimeSpentSteps,
        distant: distantSolde,
      );
      if (fusion.cumulGagne != local.lifetimeEarnedSteps ||
          fusion.cumulDepense != local.lifetimeSpentSteps ||
          fusion.solde != local.balanceSteps) {
        await stageCount.restoreSnapshot(
          WalletSnapshot(
            balanceSteps: fusion.solde,
            lifetimeEarnedSteps: fusion.cumulGagne,
            lifetimeSpentSteps: fusion.cumulDepense,
          ),
        );
        quelqueChose = true;
      }
    }

    // --- LES DROITS DE SENTIER : loquets ------------------------------------
    for (final distant in annonces.trails) {
      final local = await entitlementsDao.getByTrailId(distant.trailId);
      final fusion = mergeTrailEntitlement(
        possedeLocal: local?.owned ?? false,
        etapesAcquisesLocal: local?.acquiredStages ?? 0,
        complementConsommeLocal: local?.consumedComplementSteps ?? 0,
        distant: distant,
      );

      final inchange =
          local != null &&
          local.owned == fusion.possede &&
          local.acquiredStages == fusion.etapesAcquises &&
          local.consumedComplementSteps == fusion.complementConsomme;
      if (inchange) continue;

      await entitlementsDao.upsert(
        TrekEntitlementsCompanion.insert(
          trailId: fusion.trailId,
          owned: Value(fusion.possede),
          acquiredStages: Value(fusion.etapesAcquises),
          // `totalStages` NE DESCEND PAS DU SERVEUR : c est une donnee de
          // CATALOGUE, pas de compte. On preserve ce que le telephone sait
          // deja, plutot que de l ecraser avec un zero venu d ailleurs.
          totalStages: Value(local?.totalStages ?? 0),
          consumedComplementSteps: Value(fusion.complementConsomme),
          purchaseSource: Value(local?.purchaseSource ?? "serveur"),
          purchasedAt: Value(local?.purchasedAt),
          updatedAt: DateTime.now(),
        ),
      );
      sentiersTouches.add(fusion.trailId);
      quelqueChose = true;
    }

    // --- L ABONNEMENT : le serveur tranche, l horodatage arbitre ------------
    var abonnementApplique = false;
    final distantAbo = annonces.subscription;
    if (distantAbo != null) {
      final dejaApplique =
          HorodatageServeur.annonceParLeServeur(
            preferences.getInt(subscriptionTimestampPrefsKey),
          ) ??
          HorodatageServeur.origine;

      if (abonnementAApplique(
        horodatageApplique: dejaApplique,
        distant: distantAbo,
      )) {
        // UN ABONNEMENT EST UN ETAT, PAS UNE COLLECTION DE LIGNES : chaque
        // annonce REMPLACE la precedente au lieu de s empiler. C est
        // exactement ce que fait `onSubscriptionValidated`.
        await noAdsDao.deleteBySource("subscription");
        if (distantAbo.actif && distantAbo.echeance != null) {
          final maintenant = DateTime.now();
          await noAdsDao.insertState(
            NoAdsStateCompanion.insert(
              source: "subscription",
              startedAt: maintenant,
              updatedAt: maintenant,
              expiresAt: Value(distantAbo.echeance),
            ),
          );
        }
        await preferences.setInt(
          subscriptionTimestampPrefsKey,
          distantAbo.horodatage.millisecondesEpoch,
        );
        abonnementApplique = true;
        quelqueChose = true;
      }
    }

    if (!quelqueChose) {
      return const ResultatDescente.sansEffet("le telephone etait deja a jour");
    }

    await apresApplication?.call();

    return ResultatDescente(
      appliquee: true,
      soldeApres: stageCount.balanceSteps,
      sentiersMisAJour: List.unmodifiable(sentiersTouches),
      abonnementApplique: abonnementApplique,
    );
  }
}

/// CE QU A FAIT UNE PASSE DE DESCENTE.
class ResultatDescente {
  const ResultatDescente({
    required this.appliquee,
    this.raison = "",
    this.soldeApres = 0,
    this.sentiersMisAJour = const [],
    this.abonnementApplique = false,
  });

  /// Une passe qui n a rien ecrit, et qui DIT pourquoi.
  const ResultatDescente.sansEffet(String pourquoi)
    : appliquee = false,
      raison = pourquoi,
      soldeApres = 0,
      sentiersMisAJour = const [],
      abonnementApplique = false;

  /// Vrai si quelque chose a ete ecrit dans la base locale.
  final bool appliquee;

  /// Pourquoi rien n a ete ecrit.
  final String raison;

  /// Le solde d etapes APRES la descente.
  final int soldeApres;

  /// Les sentiers dont le droit a bouge.
  final List<String> sentiersMisAJour;

  /// Vrai si l abonnement a ete pose ou revoque par cette passe.
  final bool abonnementApplique;

  @override
  String toString() => appliquee
      ? "ResultatDescente(solde: $soldeApres, "
            "sentiers: ${sentiersMisAJour.join(", ")}, "
            "abonnement: $abonnementApplique)"
      : "ResultatDescente(sans effet : $raison)";
}

/// PROVIDER DE LA DESCENTE DES DROITS (tache 631).
///
/// ASYNCHRONE parce qu il lui faut les preferences, et qu elles le sont. Il est
/// lu au PREMIER REVEIL de l ordonnanceur, pas a sa creation : rien ne se
/// construit au demarrage tant que personne n en a besoin.
///
/// L IDENTIFIANT EST CELUI DE L AUTHENTIFICATION, ET C EST LA SEULE VALEUR
/// POSSIBLE. `firestore.rules` n autorise `users/{userId}` que si
/// `request.auth.uid == userId` : tout autre identifiant se ferait refuser la
/// lecture. Pour un compte ANONYME, cet identifiant ne designe personne — c est
/// un numero tire par Firebase, sans nom, sans adresse, sans appareil. Le miroir
/// reste donc non nominatif.
///
/// SANS FIREBASE, IL REND UN SERVICE QUI NE FAIT RIEN : `executer()` sort a sa
/// premiere ligne (`firebaseService.isAvailable` faux) et n ecrit rien. C est
/// l etat du telephone de Christophe aujourd hui, et c est pourquoi la descente
/// y sera muette tant que la configuration Firebase n entre pas dans le paquet.
final descenteDesDroitsProvider = FutureProvider<DescenteDesDroits>((
  ref,
) async {
  final db = ref.watch(databaseProvider);
  final prefs = await SharedPreferences.getInstance();
  return DescenteDesDroits(
    stageCount: ref.watch(walletStoreProvider),
    entitlementsDao: db.trekEntitlementsDao,
    noAdsDao: db.noAdsDao,
    firebaseService: ref.watch(firebaseServiceProvider),
    connectivityMonitor: ref.watch(connectivityMonitorProvider),
    identifiant: () async => fb.FirebaseAuth.instance.currentUser?.uid,
    preferences: prefs,
    // APRES COUP, LE CACHE DES GARDES SYNCHRONES EST RESYNCHRONISE. Sans cette
    // ligne, un sentier qui vient de descendre serait possede EN BASE et encore
    // verrouille pour les gardes de routes, qui lisent `FeatureFlags` et non la
    // base. Le randonneur verrait son achat arriver... et resterait dehors.
    apresApplication: () async {
      await ref.read(monetizationServiceProvider).load();
    },
  );
});

/// ARME L ECOUTE EN DIRECT DES DROITS (tache 631).
///
/// Observe par `_BootstrapGate` dans `main.dart` — la garde qui vit au-dessus du
/// `Navigator` et ne se demonte JAMAIS. C est la seule place correcte : une
/// ecoute branchee depuis un ecran s arreterait en changeant d ecran (Riverpod 3
/// met en pause les abonnements d un ecran qui n est plus a l avant-plan), et
/// une ecoute qui s arrete quand on navigue n est pas une ecoute.
///
/// IL NE BLOQUE PAS LE DEMARRAGE : il ne rend rien et n attend rien. Sans
/// Firebase ou sans identite, il ne s arme pas, en silence.
final descenteEnDirectProvider = Provider<void>((ref) {
  // LE NETTOYAGE SE DECLARE TOUT DE SUITE, PAS DANS LA SUITE ASYNCHRONE.
  // `ref.onDispose` doit etre appele PENDANT la construction du provider ;
  // l appeler apres un `await` arrive quand le corps a deja rendu la main, et
  // Riverpod le refuse. L erreur ne remontait nulle part et se manifestait
  // ailleurs : la garde `aucun_geste_mort_573` voyait l ecran des reglages
  // changer sous elle et declarait mort un bouton qui ne l etait pas.
  DescenteDesDroits? service;
  ref.onDispose(() => service?.cesserDEcouter());
  unawaited(() async {
    service = await ref.read(descenteDesDroitsProvider.future);
    await service?.ecouterEnDirect();
  }());
});
