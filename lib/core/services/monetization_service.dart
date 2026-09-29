import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/feature_flags.dart';
import '../config/trail_catalog.dart';
import '../config/trail_selection.dart';
import '../data/daos/no_ads_dao.dart';
import '../data/daos/trek_entitlements_dao.dart';
import '../data/database.dart';
import '../network/connectivity_monitor.dart';
import '../providers/database_provider.dart';
import 'wallet_iap_service.dart';
import 'wallet_store.dart';
import 'session_demo.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Prix d'un PALIER d'étape (1 étape), en euros (StepWays LOT 1, modèle éco).
///
/// Remplace l'ancien `kPricePerStageEur` (1,0). Le prix « catalogue » d'un trek
/// = nombre d'étapes × [kStepTierEur] ; il sert d'ancrage d'affichage. L'achat
/// réel passe par le compte-étapes ([buyTrail]) : wallet d'abord, complément
/// store via un PACK (grille [kStepPacks]).
const double kStepTierEur = 0.99;

/// Étapes créditées et prix EUR de chaque PACK de recharge (grille officielle).
///
/// Les packs sont vendus par le store (consommables StepWays,
/// `wallet_iap_service.dart`). Le complément d'un achat passe par le PLUS PETIT
/// pack couvrant le manque (reco spec §3.1) : évite les SKU unitaires
/// ingérables. Trié par nombre d'étapes croissant (contrat pour [packSteps]).
const List<StepPack> kStepPacks = <StepPack>[
  StepPack(steps: 11, priceEur: 9.99, productId: kWalletCredits11),
  StepPack(steps: 25, priceEur: 19.99, productId: kWalletCredits25),
  StepPack(steps: 50, priceEur: 34.99, productId: kWalletCredits50),
];

/// Clé SharedPreferences legacy #1 : treks achetés (booléen par trek).
///
/// Écrite par l'ANCIEN `MonetizationService` (`purchaseTrail` stub). Migrée en
/// runtime vers `TrekEntitlements.owned=true` par [migrateLegacyPurchases].
const kPurchasedTrailsPrefsKey = 'monetization.purchasedTrails';

/// Clé SharedPreferences legacy #2 : treks achetés vus par `DemoModeService`.
///
/// 2ᵉ source d'achat historique (doublon). Migrée elle aussi vers
/// `TrekEntitlements.owned=true` (idempotent).
const kDemoModePurchasedTrailsPrefsKey = 'purchased_trail_ids';

/// Un pack de recharge du compte-étapes : nombre d'étapes + prix EUR + SKU store.
class StepPack {
  const StepPack({
    required this.steps,
    required this.priceEur,
    required this.productId,
  });

  /// Nombre d'étapes créditées par le pack.
  final int steps;

  /// Prix du pack en euros (grille officielle).
  final double priceEur;

  /// ProductId store du pack (consommable, `wallet_iap_service.dart`).
  final String productId;

  @override
  String toString() => 'StepPack($steps étapes, $priceEur€, $productId)';
}

/// Niveau d'accès d'un trek (StepWays LOT 1 — remplace le booléen par-trek).
///
/// Quatre niveaux (`MODELE_ECO.md` du 08/09, §2, + sentier gratuit du 27/09) :
///   - [free]       : trek PAYANT ni possédé ni couvert par un abo → démo
///                    bridée + pub ;
///   - [freeTrail]  : SENTIER GRATUIT (prix nul) → entièrement jouable, ET avec
///                    pub — y compris pendant la marche — parce qu'il n'a rien
///                    payé ;
///   - [subscriber] : abo light actif → SANS PUB PARTOUT + cagnotte d'étapes,
///                    mais **ni les outils complets ni la réalisation** ;
///   - [owned]      : trek acheté → outils COMPLETS pour ce trek, réalisation,
///                    et sans pub sur ce trek.
///
/// POURQUOI UN QUATRIÈME NIVEAU (tâche 601), ET CE QU'IL RÉPARE. Cet enum
/// confondait deux axes que le modèle sépare : le DROIT DE JOUER et le SANS-PUB.
/// Tant que « jouable » et « sans pub » voulaient dire la même chose (`owned`),
/// un sentier de démonstration entièrement jouable ne pouvait exister qu'en
/// étant déclaré `owned` — ce que faisait le drapeau `isShowcaseTrail`, lui
/// offrant au passage le sans-pub PERMANENT réservé à l'achat, donc gratuitement
/// ce que l'abonnement fait payer. Le sentier gratuit est précisément le cas où
/// les deux axes divergent : jouable ET avec pub. Nommer ce niveau supprime
/// l'exemption plutôt que de la déplacer.
enum TrailAccess {
  /// Gratuit sur un sentier PAYANT : démo bridée + pub (trek non débloqué).
  free,

  /// SENTIER GRATUIT (prix nul) : entièrement jouable, avec pub hors mode trek.
  freeTrail,

  /// Abo light actif : sans-pub app-wide + cagnotte. RIEN de plus.
  subscriber,

  /// Possédé — achat confirmé.
  owned;

  /// Le trek est-il JOUABLE (outils complets, carte GPS, journal, réalisation) ?
  ///
  /// [owned] (on a payé) ou [freeTrail] (il n'y avait rien à payer). PAS
  /// l'abonné : **CORRIGE LA CONTRADICTION A2a (tâche 594)** — cette règle
  /// rendait jouable tout ce qui n'était pas [free], donc l'abonné, et un abonné
  /// light obtenait ainsi les outils complets ET la réalisation de TOUS les treks
  /// sans en acheter un seul. L'arbitrage du 08/09 dit exactement l'inverse, et
  /// il **prime sur #99405** : « l'abonné NE débloque PAS les outils complets ni
  /// la réalisation — pour les outils complets d'un trek, il faut l'acheter
  /// (comme le gratuit) ».
  bool get isPlayable =>
      this == TrailAccess.owned || this == TrailAccess.freeTrail;

  /// Faut-il afficher la pub pour ce niveau ? (source unique #99404)
  ///
  /// Pub en [free] ET en [freeTrail] : le sans-pub est la contrepartie d'avoir
  /// PAYÉ (§3, « trek acheté → sans pub sur ce trek »), pas d'être jouable. Un
  /// sentier gratuit n'a rien payé, il reste donc dans le niveau gratuit du §2,
  /// « AVEC pub ». [subscriber] et [owned] sont sans-pub — c'est ce que l'abo
  /// light donne, et c'est tout ce qu'il donne.
  ///
  /// TROIS EXCEPTIONS, ET PAS UNE DE PLUS. Décision de Christophe du **27/09
  /// 14:41**, verbatim : « TOUT PORTER LA PUB sauf si tu es abonné ou sur le
  /// trek que tu as acheté .. Pas la peine de mettre plus de règles » — les
  /// deux qu'il nomme, plus la récompense vidéo de 24 h déjà prévue au §3.
  /// AUCUNE condition de mode trek : ce getter rend `true` pour un sentier
  /// gratuit MÊME PENDANT LA MARCHE, et c'est voulu.
  ///
  /// CE COMMENTAIRE AFFIRMAIT L'INVERSE, ET IL L'ATTRIBUAIT À CHRISTOPHE. Il
  /// annonçait une règle « EN MODE TREK JAMAIS » qui « s'applique par-dessus »,
  /// alors qu'elle avait été retirée le jour même. C'est exactement le motif du
  /// drapeau `isShowcaseTrail` : un commentaire qui survit à la décision qui
  /// l'abroge et sert ensuite de justification. Il est corrigé ici, sur le getter
  /// lui-même, parce que c'est là qu'on vient le lire avant de « réparer ».
  bool get showAds => this == TrailAccess.free || this == TrailAccess.freeTrail;
}

/// Issue d'un versement de la CAGNOTTE de l'abonné (modèle éco §2, A5).
enum SubscriberAllowanceOutcome {
  /// Aucun abonnement actif : rien à verser.
  notSubscriber,

  /// Abonnement actif, mais le MONTANT de la cagnotte n'est pas décidé
  /// ([kSubscriberStepsAllowance] vaut `null`) → rien versé, décision attendue.
  pendingDecision,

  /// La cagnotte de la période courante a déjà été versée (anti double-crédit).
  alreadyGranted,

  /// Cagnotte versée au compte-étapes.
  granted,
}

/// Ce qu'une demande de restauration d'achats a réellement pu faire.
enum PurchaseRestoreStatus {
  /// Le store a été sollicité : les achats restaurés arriveront par la boucle
  /// de complétion (asynchrone).
  requested,

  /// L'achat in-app est indisponible sur cet appareil (ou kill-switch fermé) :
  /// aucune restauration possible, et on le DIT.
  storeUnavailable,
}

/// Résultat d'une restauration d'achats (ce qui a été sollicité, ce qui est
/// redescendu). Sert à ne JAMAIS laisser le bouton « Restaurer » muet.
class PurchaseRestoreOutcome {
  const PurchaseRestoreOutcome({required this.status, this.itemsRestored = 0});

  /// Ce que la demande a pu faire.
  final PurchaseRestoreStatus status;

  /// Nombre de droits redescendus de la sauvegarde (0 si aucune sauvegarde).
  final int itemsRestored;

  @override
  String toString() => 'PurchaseRestoreOutcome($status, $itemsRestored)';
}

/// MONTANT DE LA CAGNOTTE DE L'ABONNÉ — **DÉCIDÉ PAR CHRISTOPHE LE 27/09**.
///
/// Verbatim (27/09 12:26) : « Le prix on l'avait fixé à 2 euros mous = pub nul
/// part et 2 étapes cagnottes par mois ». Deux étapes par mois, versées tant que
/// l'abonnement est actif.
///
/// LA VALEUR A ATTENDU SA DÉCISION, ELLE NE L'A PAS INVENTÉE. La tâche 594 avait
/// implémenté le MÉCANISME complet ([MonetizationService.grantSubscriberAllowance])
/// et laissé cette constante à `null` = non décidé, parce qu'un chiffre inventé
/// dans un modèle économique est une faute et pas un défaut. Le prix avait été
/// fixé à l'oral et jamais consigné : il l'est maintenant, ici et dans
/// `MODELE_ECO.md`.
///
/// CE QUE CETTE CAGNOTTE N'EST PAS : un cadeau de bienvenue. C'est un versement
/// PÉRIODIQUE, borné par l'échéance de l'abonnement (une fois par période, cf.
/// [kSubscriberAllowanceGrantedAtPrefsKey]), qui s'arrête avec l'abonnement. Les
/// étapes déjà versées, elles, restent acquises À VIE — règle d'or #99404 :
/// crédits à vie, sans-pub lié à un état actif. Les deux ne se mélangent pas.
/// LE TYPE RESTE NULLABLE À DESSEIN : `null` = « pas décidé » est un MÉCANISME
/// ([SubscriberAllowanceOutcome.pendingDecision]), pas un reste de brouillon.
/// Il a servi une fois et resservira au prochain chiffre en attente ; le rendre
/// non-nullable parce qu'une valeur est enfin posée supprimerait la seule façon
/// qu'a ce code de dire « je ne sais pas encore » au lieu d'inventer.
// ignore: unnecessary_nullable_for_final_variable_declarations
const int? kSubscriberStepsAllowance = 2;

/// PRIX DE L'ABONNEMENT, EN EUROS PAR MOIS — **DÉCIDÉ PAR CHRISTOPHE LE 27/09**.
///
/// Verbatim (27/09 12:26) : « Le prix on l'avait fixé à 2 euros mous = pub nul
/// part et 2 étapes cagnottes par mois ».
///
/// CE QU'IL ACHÈTE, ET CE QU'IL N'ACHÈTE PAS. Sans publicité PARTOUT tant qu'il
/// est actif, plus [kSubscriberStepsAllowance] étapes par mois. Il ne débloque NI
/// les outils complets NI la réalisation d'un trek : pour cela il faut acheter le
/// trek (arbitrage du 08/09, qui prime sur #99405 et reste entier).
///
/// UN PRIX QUI VIT À L'ORAL EST UN PRIX QU'ON AFFICHE FAUX LE JOUR OÙ ON
/// L'AFFICHE. Il est déclaré ici, en un seul point, et l'écran d'abonnement le
/// lit — il annonçait jusqu'ici ce que l'abo donne et ce qu'il ne donne pas, sans
/// jamais dire ce qu'il coûte.
///
/// La PÉRIODE facturée est le mois. Ne pas la confondre avec
/// [kSubscriptionNoAdsWindow] (31 jours), qui n'est pas une durée commerciale
/// mais le temps pendant lequel l'appareil accepte de croire un reçu sans
/// nouvelle preuve.
const double kSubscriptionPriceEur = 2.0;

/// Clé prefs : début de la période de cagnotte déjà versée (ISO-8601).
const kSubscriberAllowanceGrantedAtPrefsKey =
    'monetization.subscriberAllowanceGrantedAt';

/// Nombre de PHASES du plan d'entraînement réellement jouables en démo bridée.
///
/// Modèle éco §2 : en gratuit, « SAC À DOS + PRÉPA PHYSIQUE jouables *pour de
/// faux* (version bridée) ». Les phases au-delà restent VISIBLES et GRISÉES,
/// jamais cachées. Point de réglage unique du bridage de la prépa physique.
const int kDemoTrainingPhasesPlayable = 1;

/// Nombre de CATÉGORIES du sac réellement jouables en démo bridée.
///
/// Même règle que [kDemoTrainingPhasesPlayable], côté sac à dos : les autres
/// catégories restent visibles, grisées et verrouillées. Avant la tâche 594 le
/// sac n'avait AUCUN bridage — il était intégralement gratuit et complet,
/// contraire à la décision qui exige l'achat du trek (inventaire 593 §M7c).
const int kDemoChecklistCategoriesPlayable = 2;

/// Issue d'un achat de trek via [MonetizationService.buyTrail] (spec §2.5).
///
/// Décrit précisément CE QUI S'EST PASSÉ (pour l'UI et les tests) : succès ou
/// motif d'échec, part payée par le wallet, complément store requis/consommé.
class PurchaseOutcome {
  const PurchaseOutcome({
    required this.status,
    required this.trailId,
    this.stepsFromWallet = 0,
    this.complementSteps = 0,
    this.complementPack,
  });

  /// Résultat global de la tentative.
  final PurchaseStatusResult status;

  /// Trek concerné.
  final String trailId;

  /// Nombre d'étapes débitées du compte-étapes (wallet) pour cet achat.
  final int stepsFromWallet;

  /// Nombre d'étapes du complément couvert par le store (0 si wallet suffisant).
  final int complementSteps;

  /// Pack store utilisé pour le complément (null si aucun complément).
  final StepPack? complementPack;

  /// Vrai si le trek est possédé à l'issue (achat abouti).
  bool get isOwned => status == PurchaseStatusResult.owned;

  @override
  String toString() =>
      'PurchaseOutcome($status, $trailId, '
      'wallet=$stepsFromWallet, complément=$complementSteps)';
}

/// Statut détaillé d'une tentative d'achat.
enum PurchaseStatusResult {
  /// Le trek est désormais possédé (achat confirmé).
  owned,

  /// Déjà possédé avant l'appel (idempotent, rien débité).
  alreadyOwned,

  /// Complément store requis mais l'appareil est hors-ligne → wallet rollback.
  offlineComplementRequired,

  /// Complément store nécessaire mais échoué/annulé/non initié → wallet rollback.
  complementFailed,

  /// PRIX INTROUVABLE : le sentier n'est pas au catalogue, donc invendable.
  ///
  /// LE SECOND VERROU DE L'AVENANT 614, et il ne fait pas doublon avec le
  /// premier. Retirer `totalStages` de [MonetizationService.buyTrail] empêche un
  /// APPELANT d'annoncer un prix nul ; il n'empêche pas le CATALOGUE de ne rien
  /// savoir d'un identifiant. Un sentier absent du catalogue rend 0 étape, et 0
  /// étape traverserait l'algorithme sans débit jusqu'à poser `owned` — le
  /// sentier serait OFFERT. On refuse donc explicitement, et on le NOMME.
  ///
  /// UN SENTIER GRATUIT N'ARRIVE JAMAIS ICI, et c'est toute la différence. Sa
  /// gratuité est lue au catalogue ([MonetizationService.isFreeTrail]) et
  /// traitée AVANT ce refus, par [alreadyOwned] : il reste jouable sans débit,
  /// conformément à la décision de Christophe du 27/09 sur le sentier démo.
  /// « Prix nul parce que le catalogue le dit » et « prix nul parce qu'on ne
  /// sait pas » sont deux choses, et ce statut n'existe que pour la seconde.
  unknownPrice,

  /// REFUSE PARCE QU'ON EST EN DEMO (tache 634, DEM-260929-1123).
  ///
  /// Christophe, le 29/09 : « ON EST EN MODE DEMO » = rien ne compte, « pas
  /// d etapes gagnees, pas de diplome, pas de droits, rien en base ». Une
  /// demonstration qui deduirait des etapes du compte, ou qui poserait un droit
  /// acquis, ne serait plus une demonstration.
  ///
  /// CE STATUT EXISTE POUR ETRE LU. Le refus n'est pas silencieux : l'ecran le
  /// recoit et peut le dire, la ou un `false` muet aurait ressemble a une
  /// panne.
  refuseEnDemo,
}

/// Devis d'achat/reprise d'un trek (spec §2.4/§2.5).
class TrailQuote {
  const TrailQuote({
    required this.trailId,
    required this.totalStages,
    required this.acquiredStages,
    required this.stepsNeeded,
    required this.stepsFromWallet,
    required this.complementSteps,
    this.complementPack,
  });

  /// Trek concerné.
  final String trailId;

  /// Nombre total d'étapes du trek.
  final int totalStages;

  /// Étapes déjà acquises (base = ne pas repayer).
  final int acquiredStages;

  /// Étapes restant à acquérir (`totalStages - acquiredStages`, ≥ 0).
  final int stepsNeeded;

  /// Part du besoin couverte par le wallet (`min(wallet, stepsNeeded)`).
  final int stepsFromWallet;

  /// Complément store (`stepsNeeded - stepsFromWallet`, ≥ 0).
  final int complementSteps;

  /// Plus petit pack couvrant le complément (null si complément = 0).
  final StepPack? complementPack;

  /// Prix EUR à régler au store pour le complément (0 si wallet suffisant).
  double get complementPriceEur => complementPack?.priceEur ?? 0.0;

  @override
  String toString() =>
      'TrailQuote($trailId, besoin=$stepsNeeded, '
      'wallet=$stepsFromWallet, complément=$complementSteps)';
}

/// Features disponibles selon le mode (gratuit ou premium).
///
/// En mode gratuit : préparation avec pub + démo limitée.
/// En mode premium (jouable) : carte GPS tracking journal diplôme
/// goodies + 2 suiveurs gratuits, SANS pub.
class TrailFeatures {
  const TrailFeatures({
    required this.hasAds,
    required this.isDemo,
    required this.hasGpsTracking,
    required this.hasJournal,
    required this.hasDiploma,
    required this.hasGoodies,
    required this.freeFollowerSlots,
    required this.hasPreparation,
  });

  /// Publicités affichées
  final bool hasAds;

  /// Mode démonstration (fonctionnalités limitées)
  final bool isDemo;

  /// Carte GPS + suivi en direct
  final bool hasGpsTracking;

  /// Journal de bord
  final bool hasJournal;

  /// Diplôme de fin de trek
  final bool hasDiploma;

  /// Boutique goodies
  final bool hasGoodies;

  /// Nombre de suiveurs gratuits (0 en gratuit, 2 en premium)
  final int freeFollowerSlots;

  /// Accès à la préparation du trek
  final bool hasPreparation;

  /// Copie en changeant l'affichage de la pub (l'abonné light garde la démo
  /// bridée mais n'a PAS de pub — modèle éco §2 + règle d'or #99404).
  TrailFeatures withAds(bool showAds) {
    if (showAds == hasAds) return this;
    return TrailFeatures(
      hasAds: showAds,
      isDemo: isDemo,
      hasGpsTracking: hasGpsTracking,
      hasJournal: hasJournal,
      hasDiploma: hasDiploma,
      hasGoodies: hasGoodies,
      freeFollowerSlots: freeFollowerSlots,
      hasPreparation: hasPreparation,
    );
  }
}

/// Service de monétisation compte-étapes (StepWays LOT 1, ST4 — le CŒUR).
///
/// REMPLACE le modèle per-trek booléen historique (#81774 : `_purchases` Set en
/// prefs, `kPricePerStageEur`, `purchaseTrail` stub) par le modèle DEUX POCHES :
///
///   1. COMPTE-ÉTAPES (wallet, [WalletStore]) : solde d'étapes rechargeable ;
///   2. DROITS PAR TREK ([TrekEntitlementsDao]) : `owned` posé à confirmation
///      store, avec `acquiredStages` / `consumedComplementSteps` (rachat reprise).
///
/// [buyTrail] (algo spec §2.5) : `need = prix − acquis` ; `fromWallet =
/// min(wallet, need)` ; `complément = need − fromWallet`. On DÉBITE le wallet
/// (offline OK) ; si un complément > 0 subsiste, l'achat store EXIGE le réseau
/// ([ConnectivityMonitor]) — sinon le débit wallet est ROLLBACK (jamais de wallet
/// débité sans contrepartie, spec §5). `owned` n'est posé qu'à confirmation store.
/// Le complément passe par le PLUS PETIT PACK couvrant le manque (reco §3.1).
///
/// Sans-pub (#99404) : `isNoAdsActive(trailId) = ownsTrail || isSubscriberActive
/// || isRewardNoAdsActive` — SOURCE UNIQUE, aucune UI ne recalcule. L'état est
/// reflété dans [FeatureFlags] (`premium:trailId`, cache synchrone) pour les
/// gardes de routes.
///
/// Injection intégrale (tests) : collaborateurs + horloge [nowFn] (reward 24 h)
/// + `freeTrailIds`. La persistance durable reste SharedPreferences via
/// [WalletStore] ; ce service ne fait QUE la règle métier. (La base n'est plus
/// volatile depuis la tâche 613 — voir [WalletStore] pour l'arbitrage qui laisse
/// les préférences en source durable du solde.)
class MonetizationService {
  MonetizationService({
    required WalletStore walletStore,
    required TrekEntitlementsDao entitlementsDao,
    required NoAdsDao noAdsDao,
    required WalletIapService iapService,
    required ConnectivityMonitor connectivityMonitor,
    DateTime Function()? nowFn,
    SharedPreferences? prefs,
    Set<String>? freeTrailIds,
    int Function(String trailId)? stagesOf,
    bool Function()? enDemo,
  }) : _enDemo = enDemo,
       _wallet = walletStore,
       _entitlementsDao = entitlementsDao,
       _noAdsDao = noAdsDao,
       _iap = iapService,
       _connectivity = connectivityMonitor,
       _now = nowFn ?? DateTime.now,
       _prefs = prefs,
       _freeTrailIds = freeTrailIds,
       _stagesOf = stagesOf;

  /// LA BARRIERE D'ECRITURE DE LA DEMO (tache 634, DEM-260929-1123).
  ///
  /// Rendue par une FONCTION et non par un booleen fige : la demo s'entre et se
  /// quitte pendant la vie du service, et le service n'est pas reconstruit pour
  /// autant. On interroge donc l'etat A L'INSTANT DE L'ECRITURE — meme
  /// raisonnement que `stagesOf`, qui lit le prix a l'instant de l'achat.
  ///
  /// `null` (defaut) = jamais en demo. C'est ce que lisent les tests qui ne
  /// connaissent pas ce mode, et le comportement d'origine est donc
  /// strictement inchange pour eux.
  final bool Function()? _enDemo;

  /// Vrai quand une demo volontaire est en cours : AUCUNE ecriture d'argent,
  /// de droit ou d'abonnement ne doit partir.
  bool get enDemo => _enDemo?.call() ?? false;

  final WalletStore _wallet;
  final TrekEntitlementsDao _entitlementsDao;
  final NoAdsDao _noAdsDao;
  final WalletIapService _iap;
  final ConnectivityMonitor _connectivity;

  /// Horloge injectable (reward 24 h testable via `Clock`).
  final DateTime Function() _now;

  SharedPreferences? _prefs;

  /// Sentiers GRATUITS (injectés en test, sinon dérivés du catalogue).
  final Set<String>? _freeTrailIds;

  /// Nombre d'étapes d'un sentier — LE PRIX, résolu depuis le CATALOGUE.
  ///
  /// Injecté par [monetizationServiceProvider] sur le catalogue EFFECTIF
  /// (distant > dernier reçu > compilé) ; `null` en test ou hors Riverpod, où
  /// l'on retombe sur le catalogue COMPILÉ. Même forme d'injection que
  /// [_freeTrailIds], et pour la même raison : le prix et la gratuité sont deux
  /// lectures de la même donnée, jamais deux décisions.
  final int Function(String trailId)? _stagesOf;

  Future<SharedPreferences> get _preferences async =>
      _prefs ??= await SharedPreferences.getInstance();

  bool _loaded = false;

  /// Indique si l'état persisté a été chargé ([load]).
  bool get isLoaded => _loaded;

  // --- Sentiers GRATUITS (prix nul, tâche 601) ------------------------------

  /// Ensemble effectif des sentiers gratuits (injection > catalogue).
  Set<String> get _gratuits => _freeTrailIds ?? TrailCatalog.freeIds;

  /// Vrai si [trailId] est un sentier GRATUIT — son prix est nul.
  ///
  /// Dérive du PRIX porté par la donnée du catalogue, jamais d'un id de localité
  /// en dur ni d'un drapeau d'exemption (tâche 601).
  bool isFreeTrail(String trailId) => _gratuits.contains(trailId);

  // --- LE PRIX D'UN SENTIER, ET PERSONNE D'AUTRE NE LE DÉCIDE (avenant 614) --

  /// Nombre d'étapes du sentier [trailId] — SOURCE UNIQUE DU PRIX.
  ///
  /// LE TROU QUE CETTE MÉTHODE FERME. [buyTrail] prenait `totalStages` en
  /// paramètre REQUIS : c'était l'APPELANT qui annonçait le prix. Un appelant
  /// qui passait zéro sur un sentier payant traversait tout l'algorithme sans
  /// rien débiter — `need = 0`, `fromWallet = 0`, `complément = 0` — et
  /// atteignait la pose de `owned`. Autrement dit : il existait un chemin par
  /// lequel un sentier PAYANT devenait GRATUIT, et il suffisait de se tromper
  /// d'argument. C'est exactement le motif `isShowcaseTrail` du lot 601 sous un
  /// autre nom : une exemption qui n'est écrite nulle part dans le modèle.
  ///
  /// LA CORRECTION EST DE RETIRER LE CHOIX, PAS DE LE SURVEILLER. Le prix d'un
  /// sentier est une propriété de la DONNÉE du catalogue, comme sa gratuité
  /// ([isFreeTrail]) et comme tout le reste du modèle éco §2 bis. Le service la
  /// lit ; plus aucun appelant ne la déclare, donc plus aucun appelant ne peut
  /// se tromper. Les six écrans qui passaient chacun leur montant n'ont plus
  /// rien à passer.
  ///
  /// Rend 0 pour un sentier INCONNU du catalogue — et 0 n'est pas gratuit :
  /// [buyTrail] refuse alors la vente par [PurchaseStatusResult.unknownPrice]
  /// plutôt que d'offrir le sentier.
  int stagesOfTrail(String trailId) =>
      _stagesOf?.call(trailId) ?? TrailCatalog.byId(trailId)?.totalStages ?? 0;

  /// Prix EUR du sentier [trailId], lu depuis le catalogue (affichage).
  ///
  /// Point d'entrée UNIQUE du prix affiché : la vitrine, le catalogue et le
  /// cockpit l'appellent, et il repose sur la même lecture que le débit. Le
  /// montant montré et le montant prélevé ne peuvent donc plus diverger.
  double eurPriceForTrail(String trailId) =>
      eurPriceForSteps(stagesOfTrail(trailId));

  // --- Boot / migration -----------------------------------------------------

  /// Charge l'état durable (wallet + droits) et migre le legacy (idempotent).
  ///
  /// À appeler au boot (`monetizationReadyProvider` dans
  /// `app_bootstrap_provider.dart`). Corrige l'ancien `loadPurchases()` JAMAIS
  /// appelé : hydrate le [WalletStore], migre les 2 clés prefs legacy vers les
  /// `TrekEntitlements`, démarre l'écoute IAP et resynchronise le cache
  /// [FeatureFlags] premium.
  Future<void> load() async {
    await _wallet.load();
    await migrateLegacyPurchases();
    _iap.startListening();
    await _syncFeatureFlags();
    _loaded = true;
    _log.d('[Monetization] Chargé (wallet=${_wallet.balanceSteps} étapes)');
  }

  /// Migre les 2 clés prefs legacy d'achats vers `TrekEntitlements.owned=true`.
  ///
  /// Sources : [kPurchasedTrailsPrefsKey] (ancien `MonetizationService`) +
  /// [kDemoModePurchasedTrailsPrefsKey] (`demo_mode_service.dart`). IDEMPOTENT :
  /// un trek déjà `owned` n'est pas réécrit ; l'union des 2 listes est traitée.
  /// Les clés legacy sont laissées en place (aucune donnée détruite).
  Future<void> migrateLegacyPurchases() async {
    final prefs = await _preferences;
    final legacy = <String>{
      ...(prefs.getStringList(kPurchasedTrailsPrefsKey) ?? const []),
      ...(prefs.getStringList(kDemoModePurchasedTrailsPrefsKey) ?? const []),
    };
    if (legacy.isEmpty) return;

    var migrated = 0;
    for (final trailId in legacy) {
      if (trailId.isEmpty) continue;
      final existing = await _entitlementsDao.getByTrailId(trailId);
      if (existing?.owned ?? false) continue; // déjà migré (idempotent)
      final now = _now();
      await _entitlementsDao.upsert(
        TrekEntitlementsCompanion.insert(
          trailId: trailId,
          owned: const Value(true),
          purchaseSource: const Value('legacy'),
          purchasedAt: Value(existing?.purchasedAt ?? now),
          acquiredStages: Value(existing?.acquiredStages ?? 0),
          totalStages: Value(existing?.totalStages ?? 0),
          updatedAt: now,
        ),
      );
      migrated++;
    }
    if (migrated > 0) {
      _log.i('[Monetization] $migrated achat(s) legacy migré(s) en droits');
    }
  }

  // --- Compte-étapes (wallet) ----------------------------------------------

  /// Solde courant du compte-étapes, en étapes.
  int get walletSteps => _wallet.balanceSteps;

  /// Observe le solde du compte-étapes (émet à chaque mouvement).
  Stream<int> watchWalletSteps() =>
      _wallet.watch().map((snap) => snap.balanceSteps);

  /// Recharge le compte-étapes via un [pack] (achat store consommable).
  ///
  /// Délègue au [WalletIapService] ; le crédit réel du wallet arrive par la
  /// boucle de complétion (`purchaseStream`). Retourne true si l'achat est
  /// initié (false en mode stub / hors-ligne). Le crédit n'est PAS immédiat.
  Future<bool> rechargeWallet(StepPack pack) async {
    // DEMO : on ne recharge pas un compte qui ne compte pas (tache 634).
    if (enDemo) return false;
    return _iap.buyCredits(pack.productId);
  }

  // --- Droits / accès -------------------------------------------------------

  /// Vrai si le trek [trailId] est POSSÉDÉ (achat confirmé store).
  ///
  /// Un sentier VITRINE n'est PAS « owned » (il est jouable sans achat, cf.
  /// [accessFor]) — la possession reste un fait d'achat.
  Future<bool> ownsTrail(String trailId) async {
    final e = await _entitlementsDao.getByTrailId(trailId);
    return e?.owned ?? false;
  }

  /// Observe le droit d'accès du trek [trailId] (émet à chaque mutation Drift).
  ///
  /// Signal réactif du flip démo ⇄ jouable : quand un achat confirmé pose
  /// `owned` ([_markOwned] → upsert), le stream émet et l'UI (gate) se
  /// reconstruit sans rester sur un état périmé (StepWays LOT 1).
  Stream<TrekEntitlement?> watchEntitlement(String trailId) =>
      _entitlementsDao.watchByTrailId(trailId);

  /// Niveau d'accès effectif du trek (spec §2.4) :
  /// owned > freeTrail > subscriber > free.
  ///
  /// Priorité : possédé → [TrailAccess.owned] ; sinon sentier GRATUIT →
  /// [TrailAccess.freeTrail] ; sinon abo actif → [TrailAccess.subscriber] ;
  /// sinon [TrailAccess.free] (démo bridée + pub).
  ///
  /// POURQUOI LE SENTIER GRATUIT PASSE AVANT L'ABONNÉ : le niveau doit rester
  /// JOUABLE pour un abonné qui marche la démo. Son sans-pub, lui, ne dépend pas
  /// de ce niveau — [isNoAdsActive] interroge l'abonnement séparément, parce que
  /// « jouable » et « sans pub » sont deux axes distincts (tâche 601).
  ///
  /// ET POURQUOI `owned` PASSE AVANT LE GRATUIT : si un sentier gratuit devenait
  /// payant un jour, un randonneur qui l'a réellement acheté garde son droit.
  Future<TrailAccess> accessFor(String trailId) async {
    if (await ownsTrail(trailId)) return TrailAccess.owned;
    if (isFreeTrail(trailId)) return TrailAccess.freeTrail;
    if (await isSubscriberActive()) return TrailAccess.subscriber;
    return TrailAccess.free;
  }

  /// LE DROIT DE **RÉALISER** LE TREK [trailId] (tâche 594, A1).
  ///
  /// SOURCE UNIQUE du verrou de réalisation. Vrai pour un trek ACHETÉ, et pour
  /// un SENTIER GRATUIT — dont il n'y avait rien à acheter : `accessFor.isPlayable`.
  ///
  /// CE QUI MANQUAIT. Le modèle éco réserve la réalisation au trek acheté
  /// (§2, « Trek acheté : outils COMPLETS … + réalisation »). Le code ne la
  /// verrouillait nulle part : « Démarrer la randonnée » n'avait qu'une
  /// condition de PRÉPARATION (itinéraire + date + programme), et le
  /// démarrage de session n'interrogeait NI ce service NI les droits d'achat.
  /// N'importe qui démarrait, enregistrait et terminait le parcours entier
  /// sans payer — la contradiction la plus coûteuse de l'inventaire 593 (§M2),
  /// et la seule atteignable en trois gestes depuis l'accueil.
  ///
  /// L'ABONNÉ N'EST PAS CONCERNÉ : l'abo light ne débloque pas la réalisation
  /// (arbitrage du 08/09, qui prime sur #99405). Il faut acheter le trek.
  ///
  /// HORS-LIGNE : dérive des droits Drift LOCAUX, aucun appel réseau — un
  /// payeur n'est jamais bloqué faute de réseau sur le sentier.
  Future<bool> canRealizeTrail(String trailId) async {
    return (await accessFor(trailId)).isPlayable;
  }

  /// Nombre d'étapes déjà acquises pour [trailId] (base du non-repaiement).
  Future<int> acquiredStagesFor(String trailId) async {
    final e = await _entitlementsDao.getByTrailId(trailId);
    return e?.acquiredStages ?? 0;
  }

  // --- Grille de prix -------------------------------------------------------

  /// Prix « catalogue » d'un trek EN ÉTAPES = son nombre d'étapes.
  ///
  /// Remplace `priceForTrail` (qui rendait des euros). Le prix en étapes est
  /// l'unité du compte-étapes ; l'affichage EUR passe par [eurPriceForSteps].
  int stepPriceForTrail({required int totalStages}) => totalStages;

  /// Prix EUR d'un nombre d'étapes au tarif palier ([kStepTierEur]).
  double eurPriceForSteps(int steps) => steps * kStepTierEur;

  /// Nombre d'étapes créditées par un [pack] (raccourci).
  int packSteps(StepPack pack) => pack.steps;

  /// Prix EUR d'un [pack] (raccourci sur la grille).
  double packPriceEur(StepPack pack) => pack.priceEur;

  /// Le plus petit pack couvrant [steps] étapes (reco complément §3.1).
  ///
  /// Retourne le pack de plus petit `steps >= steps demandé` ; si aucun ne
  /// couvre (demande > plus gros pack), retourne le plus gros pack.
  StepPack smallestPackCovering(int steps) {
    for (final pack in kStepPacks) {
      if (pack.steps >= steps) return pack;
    }
    return kStepPacks.last;
  }

  // --- Devis / achat --------------------------------------------------------

  /// Devis d'achat d'un trek : besoin, part wallet, complément store.
  ///
  /// `need = prix − acquis` ; `fromWallet = min(wallet, need)` ;
  /// `complément = need − fromWallet`. Le pack de complément est le plus petit
  /// couvrant le manque (reco §3.1). N'engage RIEN (lecture seule).
  ///
  /// Le prix vient du catalogue ([stagesOfTrail]), plus de l'appelant
  /// (avenant 614) : un devis et l'achat qui le suit lisent le MÊME nombre.
  Future<TrailQuote> quoteTrail(String trailId) {
    return _quote(
      trailId,
      totalStages: stagesOfTrail(trailId),
      useAcquired: true,
    );
  }

  Future<TrailQuote> _quote(
    String trailId, {
    required int totalStages,
    required bool useAcquired,
  }) async {
    final acquired = useAcquired ? await acquiredStagesFor(trailId) : 0;
    final needed = (totalStages - acquired).clamp(0, totalStages);
    final fromWallet = needed < walletSteps ? needed : walletSteps;
    final complement = needed - fromWallet;
    return TrailQuote(
      trailId: trailId,
      totalStages: totalStages,
      acquiredStages: acquired,
      stepsNeeded: needed,
      stepsFromWallet: fromWallet,
      complementSteps: complement,
      complementPack: complement > 0 ? smallestPackCovering(complement) : null,
    );
  }

  /// Achète le trek [trailId] (algo spec §2.5 — wallet d'abord, complément store).
  ///
  /// Étapes :
  ///   1. si déjà possédé → [PurchaseStatusResult.alreadyOwned] (idempotent) ;
  ///   2. `need = totalStages − acquis` ; `fromWallet = min(wallet, need)` ;
  ///   3. DÉBIT wallet de `fromWallet` (offline OK) ;
  ///   4. si `complément > 0` → EXIGE le réseau ([ConnectivityMonitor]) :
  ///        - hors-ligne → ROLLBACK du débit → `offlineComplementRequired` ;
  ///        - en ligne → achat du PLUS PETIT PACK couvrant le complément ; en
  ///          l'état (stub IAP) l'achat n'est pas confirmé synchronement →
  ///          ROLLBACK + `complementFailed` (le crédit du pack, quand il
  ///          arrivera par la boucle de complétion, réalimentera le wallet) ;
  ///   5. sinon (`complément == 0`) → `owned` POSÉ (achat couvert par le wallet).
  ///
  /// `owned` n'est JAMAIS posé tant que le complément store n'est pas confirmé
  /// (spec §5). Jamais de wallet débité sans contrepartie : tout échec du
  /// complément rollback le débit.
  ///
  /// LE PRIX N'EST PLUS UN PARAMÈTRE (avenant 614). Il était `required`, donc
  /// déclaré par l'appelant, et un zéro traversait l'algorithme sans débit
  /// jusqu'à poser `owned` : un sentier payant devenait gratuit sur une erreur
  /// d'argument. Il est désormais LU au catalogue ([stagesOfTrail]) — voir cette
  /// méthode pour la mesure complète du trou et la raison de le fermer en
  /// retirant le choix plutôt qu'en le surveillant.
  Future<PurchaseOutcome> buyTrail(String trailId) async {
    // DEMO : AUCUN DEBIT, AUCUN DROIT (tache 634, DEM-260929-1123). C'est le
    // refus le plus important des cinq : c'est ici qu'un sentier payant
    // deviendrait possede, et c'est exactement le trou que le lot 601 avait
    // ferme en supprimant le drapeau vitrine. La demo MONTRE, elle ne DEBLOQUE
    // jamais.
    if (enDemo) {
      return PurchaseOutcome(
        status: PurchaseStatusResult.refuseEnDemo,
        trailId: trailId,
      );
    }
    if (await ownsTrail(trailId)) {
      return PurchaseOutcome(
        status: PurchaseStatusResult.alreadyOwned,
        trailId: trailId,
      );
    }

    // ON NE VEND PAS UN SENTIER GRATUIT (tâche 601). Son prix est nul : il n'y a
    // rien à débiter, rien à compléter au store, et l'accès est DÉJÀ acquis.
    //
    // ET ON NE LUI POSE PAS DE DROIT D'ACHAT POUR AUTANT. Ce serait la même
    // faute que le drapeau vitrine sous un autre nom : une ligne `owned` en base
    // lui donnerait le sans-pub PERMANENT réservé à celui qui a payé. Sa
    // gratuité est une propriété du catalogue, lue par [accessFor] ; elle n'a
    // aucune raison de se recopier en droit acquis.
    if (isFreeTrail(trailId)) {
      return PurchaseOutcome(
        status: PurchaseStatusResult.alreadyOwned,
        trailId: trailId,
      );
    }

    // LE PRIX VIENT DU CATALOGUE, ET S'IL N'Y EST PAS ON NE VEND PAS.
    //
    // L'ordre de ces trois gardes est le fond de l'affaire. « Déjà possédé » et
    // « gratuit » sont traités AVANT : un sentier dont le catalogue dit que le
    // prix est nul reste jouable sans débit (décision de Christophe du 27/09,
    // modèle éco §2 bis — tout se déduit du prix). Ce qui tombe ICI est le cas
    // opposé : un identifiant que le catalogue ne connaît pas, dont on ignore
    // le prix. Zéro étape n'est alors pas une gratuité, c'est une ignorance —
    // et l'offrir serait rejouer `isShowcaseTrail`, l'exemption qui a rendu le
    // Mare a Mare invendable jusqu'à ce qu'un audit la trouve.
    final totalStages = stagesOfTrail(trailId);
    if (totalStages <= 0) {
      _log.w(
        '[Monetization] $trailId : prix introuvable au catalogue -> '
        'vente REFUSEE (rien debite, aucun droit pose)',
      );
      return PurchaseOutcome(
        status: PurchaseStatusResult.unknownPrice,
        trailId: trailId,
      );
    }

    final quote = await _quote(
      trailId,
      totalStages: totalStages,
      useAcquired: true,
    );

    // 1) Débit wallet (offline OK). Jamais de solde négatif (garde WalletStore).
    if (quote.stepsFromWallet > 0) {
      await _wallet.debit(quote.stepsFromWallet);
    }

    // 2) Complément store : EXIGE le réseau, sinon rollback.
    if (quote.complementSteps > 0) {
      final online = await _isOnline();
      if (!online) {
        await _rollbackWallet(quote.stepsFromWallet);
        _log.w(
          '[Monetization] $trailId : complément store hors-ligne -> '
          'rollback wallet (${quote.stepsFromWallet} étapes)',
        );
        return PurchaseOutcome(
          status: PurchaseStatusResult.offlineComplementRequired,
          trailId: trailId,
          complementSteps: quote.complementSteps,
          complementPack: quote.complementPack,
        );
      }
      // En ligne : initier l'achat du pack de complément (best-effort). La
      // confirmation store est ASYNCHRONE (boucle de complétion) : elle ne peut
      // pas poser `owned` dans cet appel. Tant que l'IAP n'est pas confirmé
      // synchronement (kill-switch off = stub), on ROLLBACK le débit wallet et on
      // signale l'échec (jamais de wallet débité sans contrepartie, §5). Le
      // crédit du pack, quand il arrivera, réalimentera le wallet pour un futur
      // achat. POINT D'EXTENSION : à confirmation synchrone, poser `owned` ici.
      await rechargeWallet(quote.complementPack!);
      await _rollbackWallet(quote.stepsFromWallet);
      _log.w(
        '[Monetization] $trailId : complément store non confirmé (async) -> '
        'rollback wallet (${quote.stepsFromWallet} étapes)',
      );
      return PurchaseOutcome(
        status: PurchaseStatusResult.complementFailed,
        trailId: trailId,
        complementSteps: quote.complementSteps,
        complementPack: quote.complementPack,
      );
    }

    // 3) Complément nul : le wallet couvre tout -> achat confirmé, owned posé.
    await _markOwned(
      trailId,
      totalStages: totalStages,
      acquiredStages: totalStages,
      consumedComplementSteps: 0,
      source: 'wallet',
    );
    _log.i(
      '[Monetization] $trailId acheté (wallet: '
      '${quote.stepsFromWallet} étapes)',
    );
    return PurchaseOutcome(
      status: PurchaseStatusResult.owned,
      trailId: trailId,
      stepsFromWallet: quote.stepsFromWallet,
    );
  }

  /// Vrai si l'appareil est en ligne (complement store exige le reseau, §5).
  Future<bool> _isOnline() async {
    final status = await _connectivity.checkStatus();
    return status == ConnectivityStatusValues.online;
  }

  Future<void> _rollbackWallet(int steps) async {
    if (steps > 0) await _wallet.credit(steps);
  }

  Future<void> _markOwned(
    String trailId, {
    required int totalStages,
    required int acquiredStages,
    required int consumedComplementSteps,
    required String source,
  }) async {
    final now = _now();
    await _entitlementsDao.upsert(
      TrekEntitlementsCompanion.insert(
        trailId: trailId,
        owned: const Value(true),
        acquiredStages: Value(acquiredStages),
        totalStages: Value(totalStages),
        consumedComplementSteps: Value(consumedComplementSteps),
        purchaseSource: Value(source),
        purchasedAt: Value(now),
        updatedAt: now,
      ),
    );
    FeatureFlags.setOverride('premium', trailId, enabled: true);
  }

  // --- Abonnement -----------------------------------------------------------

  /// Vrai si un abonnement sans-pub est ACTIF (source 'subscription' non expirée).
  ///
  /// **UNE ÉCHÉANCE EST DÉSORMAIS OBLIGATOIRE** (tâche 594, A2b). Une ligne
  /// d'abo sans `expiresAt` n'est plus acceptée : c'était exactement le
  /// « à vie » que la règle d'or #99404 interdit (« jamais à vie, toujours lié
  /// à un état actif »). L'abo était posé avec `expiresAt = null`, rien ne
  /// l'expirait jamais, `PurchaseStatus.canceled` ne faisait que journaliser,
  /// et le DAO écrivait noir sur blanc que ces lignes n'étaient jamais purgées
  /// (inventaire 593 §M5). Une fois posé, le sans-pub était acquis pour
  /// toujours.
  ///
  /// L'échéance est repoussée à chaque confirmation du store (achat initial et
  /// renouvellement) par [onSubscriptionValidated] ; elle est révoquée par
  /// [onSubscriptionCanceled]. Sans renouvellement, elle tombe d'elle-même.
  Future<bool> isSubscriberActive() async {
    final now = _now();
    final states = await _noAdsDao.getAll();
    return states.any(
      (s) =>
          s.source == 'subscription' &&
          s.expiresAt != null &&
          s.expiresAt!.isAfter(now),
    );
  }

  /// Échéance courante du sans-pub d'abonnement (null si aucun abo actif).
  ///
  /// Sert à l'écran d'abonnement : on affiche jusqu'à QUAND l'état est acquis,
  /// plutôt qu'un « actif » sans horizon.
  Future<DateTime?> subscriptionExpiresAt() async {
    final now = _now();
    final actifs = (await _noAdsDao.getAll())
        .where(
          (s) =>
              s.source == 'subscription' &&
              s.expiresAt != null &&
              s.expiresAt!.isAfter(now),
        )
        .map((s) => s.expiresAt!)
        .toList();
    if (actifs.isEmpty) return null;
    return actifs.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  /// Lance la souscription à l'abonnement sans-pub (achat store).
  ///
  /// Délègue au [WalletIapService] ; la pose réelle de l'abo arrive par la
  /// boucle de complétion. Retourne true si initié (false en stub).
  Future<bool> subscribe() =>
      // DEMO : pas d'abonnement souscrit depuis une demonstration (tache 634).
      enDemo ? Future.value(false) : _iap.buyNoAdsSubscription();

  /// Vrai si l'achat in-app est réellement proposé (kill-switch ouvert).
  ///
  /// L'UI en a besoin pour ne PAS promettre un paiement qui n'aura pas lieu :
  /// un bouton qui ne produit rien est un mensonge (règle du LOT X).
  bool get purchaseEnabled => _iap.purchaseEnabled;

  /// Callback à appeler quand un abonnement est VALIDÉ (store/backend).
  ///
  /// Pose (ou REMPLACE) l'unique source sans-pub 'subscription', avec une
  /// échéance à `now + `[kSubscriptionNoAdsWindow] — jamais `null`. Un
  /// abonnement est un ÉTAT, pas une collection de lignes : chaque
  /// confirmation remplace la précédente au lieu de s'empiler.
  Future<void> onSubscriptionValidated() async {
    final now = _now();
    await _noAdsDao.deleteBySource('subscription');
    await _noAdsDao.insertState(
      NoAdsStateCompanion.insert(
        source: 'subscription',
        startedAt: now,
        updatedAt: now,
        expiresAt: Value(now.add(kSubscriptionNoAdsWindow)),
      ),
    );
    await _syncFeatureFlags();
    _log.i(
      '[Monetization] Abo sans-pub validé jusqu au '
      '${now.add(kSubscriptionNoAdsWindow)}',
    );
  }

  /// Callback à appeler quand l'abonnement est ANNULÉ / expiré côté store.
  ///
  /// Révoque immédiatement la source sans-pub 'subscription'. Avant la tâche
  /// 594, `PurchaseStatus.canceled` ne faisait que journaliser : l'annulation
  /// ne retirait rien.
  Future<void> onSubscriptionCanceled() async {
    final supprimees = await _noAdsDao.deleteBySource('subscription');
    if (supprimees > 0) {
      _log.i('[Monetization] Abo sans-pub révoqué ($supprimees source(s))');
    }
  }

  // --- Cagnotte de l'abonné (modèle éco §2 — MONTANT NON DÉCIDÉ) -----------

  /// Verse la CAGNOTTE d'étapes de l'abonné pour la période courante (A5).
  ///
  /// Mécanisme complet : on ne verse qu'à un abonné ACTIF, une seule fois par
  /// période (bornée par l'échéance de l'abo, clé prefs
  /// [kSubscriberAllowanceGrantedAtPrefsKey] — une cagnotte versée deux fois
  /// dans la même période serait un crédit gratuit).
  ///
  /// **LE MONTANT N'EST PAS DÉCIDÉ** : tant que [kSubscriberStepsAllowance]
  /// vaut `null`, rien n'est versé et l'appel retourne
  /// [SubscriberAllowanceOutcome.pendingDecision]. Voir la documentation de
  /// cette constante : la valeur attend une décision de Christophe.
  Future<SubscriberAllowanceOutcome> grantSubscriberAllowance() async {
    // DEMO : aucune cagnotte versee (tache 634).
    if (enDemo) return SubscriberAllowanceOutcome.notSubscriber;
    if (!await isSubscriberActive()) {
      return SubscriberAllowanceOutcome.notSubscriber;
    }
    const montant = kSubscriberStepsAllowance;
    if (montant == null || montant <= 0) {
      _log.w(
        '[Monetization] Cagnotte abonné : montant NON DÉCIDÉ '
        '(kSubscriberStepsAllowance == null) -> rien versé',
      );
      return SubscriberAllowanceOutcome.pendingDecision;
    }
    final prefs = await _preferences;
    final periode = (await subscriptionExpiresAt())?.toIso8601String();
    if (periode != null &&
        prefs.getString(kSubscriberAllowanceGrantedAtPrefsKey) == periode) {
      return SubscriberAllowanceOutcome.alreadyGranted;
    }
    await _wallet.credit(montant);
    if (periode != null) {
      await prefs.setString(kSubscriberAllowanceGrantedAtPrefsKey, periode);
    }
    _log.i('[Monetization] Cagnotte abonné : +$montant étapes');
    return SubscriberAllowanceOutcome.granted;
  }

  // --- Reward sans-pub (24 h) ----------------------------------------------

  /// Vrai si une récompense sans-pub (rewarded) est ACTIVE (non expirée).
  ///
  /// Une source 'reward' pose `expiresAt = now + 24 h`. Testable via [nowFn].
  Future<bool> isRewardNoAdsActive() async {
    final now = _now();
    final states = await _noAdsDao.getAll();
    return states.any(
      (s) =>
          s.source == 'reward' &&
          s.expiresAt != null &&
          s.expiresAt!.isAfter(now),
    );
  }

  /// Octroie une récompense sans-pub de 24 h (après une pub rewarded).
  ///
  /// Pose une source 'reward' `expiresAt = now + 24 h` (horloge [nowFn]).
  Future<void> grantRewardNoAds() async {
    // DEMO : aucune recompense video ecrite en base (tache 634).
    if (enDemo) return;
    final now = _now();
    await _noAdsDao.insertState(
      NoAdsStateCompanion.insert(
        source: 'reward',
        startedAt: now,
        updatedAt: now,
        expiresAt: Value(now.add(const Duration(hours: 24))),
      ),
    );
    _log.i('[Monetization] Reward sans-pub 24 h accordé');
  }

  // --- Règle sans-pub #99404 (source unique) --------------------------------

  /// SOURCE UNIQUE de la règle sans-pub (#99404) :
  /// `ownsTrail(trailId) || isSubscriberActive || isRewardNoAdsActive`.
  ///
  /// LE SANS-PUB EST LA CONTREPARTIE D'AVOIR PAYÉ, jamais d'être jouable
  /// (modèle éco §3 : « trek acheté → sans pub sur ce trek »). Un SENTIER
  /// GRATUIT ([TrailAccess.freeTrail]) est entièrement jouable et n'a rien
  /// payé : il relève du niveau gratuit du §2, « AVEC pub ». C'est ce que
  /// `accessFor` produit, et la nuance n'est pas décorative — le drapeau
  /// vitrine, lui, résolvait le sentier de démonstration en `owned` et lui
  /// offrait donc le sans-pub PERMANENT réservé à l'achat : il donnait
  /// gratuitement ce que l'abonnement fait payer (tâche 601).
  ///
  /// CE QUI RESTE VRAI APRÈS UNE ANNULATION D'ABONNEMENT (règle de Chris,
  /// 27/09 12:27 : « quand il arrête l'abonnement il revoit la pub partout sauf
  /// sur les sentiers achetés ») : la première condition ne porte AUCUNE
  /// échéance — la propriété d'un sentier est permanente. Arrêter l'abonnement
  /// éteint la deuxième et laisse la première intacte.
  ///
  /// Aucune UI ne recalcule cette règle ; `AdService.shouldShowAd(isPaid: …)`
  /// se branche dessus (branchement app-wide = ST7, hors périmètre ST4).
  Future<bool> isNoAdsActive(String trailId) async {
    // ACHETÉ : permanent, sans échéance (le « sauf » de la règle de Chris).
    if (await accessFor(trailId) == TrailAccess.owned) return true;
    if (await isSubscriberActive()) return true;
    if (await isRewardNoAdsActive()) return true;
    return false;
  }

  // --- Abandon / reprise ----------------------------------------------------

  /// Enregistre l'abandon d'un trek : les étapes acquises deviennent la BASE de
  /// rachat à la reprise (spec §2.4). Ne détruit rien, ne rembourse rien.
  ///
  /// On mémorise le complément store DÉJÀ consommé
  /// (`consumedComplementSteps`) pour que la reprise ne le refasse pas payer :
  /// à la reprise, seules les étapes NON encore acquises sont (re)dues.
  Future<void> onTrailAbandoned(String trailId) async {
    final e = await _entitlementsDao.getByTrailId(trailId);
    if (e == null) return;
    // Le trek n'est plus "owned" (abandonné) mais acquiredStages est conservé
    // comme base de rachat. Le complément déjà consommé reste tracé.
    final now = _now();
    await _entitlementsDao.upsert(
      TrekEntitlementsCompanion.insert(
        trailId: trailId,
        owned: const Value(false),
        acquiredStages: Value(e.acquiredStages),
        totalStages: Value(e.totalStages),
        consumedComplementSteps: Value(e.consumedComplementSteps),
        purchaseSource: Value(e.purchaseSource),
        purchasedAt: Value(e.purchasedAt),
        updatedAt: now,
      ),
    );
    FeatureFlags.setOverride('premium', trailId, enabled: false);
    _log.i(
      '[Monetization] $trailId abandonné (acquis conservés: '
      '${e.acquiredStages})',
    );
  }

  /// Devis de REPRISE : ne facture que les étapes non encore acquises.
  ///
  /// Identique à [quoteTrail] mais explicite sur l'intention de reprise : le
  /// besoin = `prix − acquis` (les étapes déjà acquises ne sont pas repayées,
  /// spec §2.5 « rachat du complément consommé »). Prix lu au catalogue.
  Future<TrailQuote> quoteResume(String trailId) {
    return _quote(
      trailId,
      totalStages: stagesOfTrail(trailId),
      useAcquired: true,
    );
  }

  /// Reprend un trek abandonné : rachète UNIQUEMENT le complément restant.
  ///
  /// Même algo que [buyTrail] (wallet d'abord, complément store, rollback si
  /// hors-ligne/échec), mais le besoin part des étapes déjà acquises. Le prix
  /// vient du catalogue, comme pour l'achat (avenant 614).
  Future<PurchaseOutcome> resumeTrail(String trailId) {
    return buyTrail(trailId);
  }

  // --- Restauration / reset -------------------------------------------------

  /// Restaure les achats passés (abo, recharges) via le store, ET DIT CE QU'ELLE
  /// A PU FAIRE (tâche 594, A3).
  ///
  /// Délègue au [WalletIapService] ; les événements arrivent en `restored` sur
  /// la boucle de complétion. Quand l'achat in-app est indisponible (mode stub,
  /// kill-switch fermé, appareil sans store), on retourne
  /// [PurchaseRestoreStatus.storeUnavailable] au lieu de ne rien faire en
  /// silence — l'UI a de quoi expliquer le refus.
  ///
  /// CE QUE LA RESTAURATION NE RAMÈNE PAS ENCORE : les droits de trek achetés
  /// avec le compte-étapes ne sont PAS des produits store, ils vivent dans la
  /// base locale. Leur sauvegarde hors de l'appareil existe
  /// (`CloudSyncService.syncWallet` / `restoreWallet`) mais exige une identité
  /// de compte et un Firebase réel — verrous hors de ce lot. L'UI le dit.
  Future<PurchaseRestoreOutcome> restorePurchases() async {
    // DEMO : on ne restaure pas des achats reels au milieu d'une demo
    // (tache 634) — ils ecriraient de vrais droits en base.
    if (enDemo) {
      return const PurchaseRestoreOutcome(
        status: PurchaseRestoreStatus.storeUnavailable,
      );
    }
    if (!await _iap.isAvailable()) {
      _log.w(
        '[Monetization] Restauration demandée mais achat in-app '
        'indisponible',
      );
      return const PurchaseRestoreOutcome(
        status: PurchaseRestoreStatus.storeUnavailable,
      );
    }
    await _iap.restorePurchases();
    return const PurchaseRestoreOutcome(
      status: PurchaseRestoreStatus.requested,
    );
  }

  /// Réinitialise TOUT l'état monétisation (tests / support).
  ///
  /// Efface les droits, les sources sans-pub et le cache [FeatureFlags] premium.
  /// Le solde du compte-étapes est laissé à [WalletStore] (non touché ici).
  Future<void> reset() async {
    // DEMO : une demonstration n'efface pas les droits REELS du randonneur
    // (tache 634). Rien ne s'ecrit pendant une demo, et effacer est encore une
    // ecriture.
    if (enDemo) return;
    final entitlements = await _entitlementsDao.getAll();
    for (final e in entitlements) {
      await _entitlementsDao.deleteByTrailId(e.trailId);
      FeatureFlags.setOverride('premium', e.trailId, enabled: false);
    }
    await _noAdsDao.clear();
    _log.d('[Monetization] reset');
  }

  // --- Features (rétro-compat) ----------------------------------------------

  /// Resynchronise le cache synchrone [FeatureFlags] premium depuis les droits.
  ///
  /// `premium:trailId = owned`. Les gardes de routes synchrones lisent ce cache ;
  /// il est réalimenté au boot ([load]) et à chaque mutation.
  ///
  /// LES SENTIERS GRATUITS N'Y ENTRENT PAS (tâche 601). `premium` dit « ce trek a
  /// été PAYÉ » : y inscrire un sentier gratuit — ce que faisait la boucle
  /// vitrine — c'est refabriquer l'exemption dans un cache. Leur jouabilité est
  /// portée par [accessFor], source unique, qui lit leur prix.
  Future<void> _syncFeatureFlags() async {
    final entitlements = await _entitlementsDao.getAll();
    for (final e in entitlements) {
      FeatureFlags.setOverride('premium', e.trailId, enabled: e.owned);
    }
  }

  /// Features du mode gratuit : préparation avec pub + démo.
  TrailFeatures getTrialFeatures() {
    return const TrailFeatures(
      hasAds: true,
      isDemo: true,
      hasGpsTracking: false,
      hasJournal: false,
      hasDiploma: false,
      hasGoodies: false,
      freeFollowerSlots: 0,
      hasPreparation: true,
    );
  }

  /// Features du mode premium (jouable) : tout, sans pub.
  TrailFeatures getPremiumFeatures() {
    return const TrailFeatures(
      hasAds: false,
      isDemo: false,
      hasGpsTracking: true,
      hasJournal: true,
      hasDiploma: true,
      hasGoodies: true,
      freeFollowerSlots: 2,
      hasPreparation: true,
    );
  }

  /// Features applicables pour un trek : premium si JOUABLE (trek acheté ou
  /// vitrine), sinon démo bridée. Décision dérivée d'[accessFor].
  ///
  /// LA PUB EST DÉCIDÉE À PART (règle d'or #99404) : l'abonné light reste en
  /// démo bridée — il n'a pas acheté le trek — mais il n'a PAS de pub. Les deux
  /// axes viennent de la même source ([TrailAccess.isPlayable] et
  /// [TrailAccess.showAds]), ils ne sont simplement plus confondus.
  Future<TrailFeatures> featuresForTrail(String trailId) async {
    final access = await accessFor(trailId);
    final base = access.isPlayable ? getPremiumFeatures() : getTrialFeatures();
    return base.withAds(access.showAds);
  }

  /// Vrai si le trek est en mode démo (non jouable).
  ///
  /// Un trek est en démo s'il n'est ni possédé, ni couvert par un abo, ni
  /// vitrine (parité GR20). Async car dérive des droits Drift.
  Future<bool> isDemoMode(String trailId) async {
    final access = await accessFor(trailId);
    return !access.isPlayable;
  }
}

/// Provider Riverpod du [MonetizationService] (StepWays LOT 1, ST4).
///
/// Branché sur les briques ST1-ST3 : [walletStoreProvider],
/// [walletIapServiceProvider], les DAOs de [databaseProvider] et le
/// [connectivityMonitorProvider]. L'initialisation asynchrone ([load]) est
/// awaitée au boot par [monetizationReadyProvider] (corrige l'ancien
/// `loadPurchases()` jamais appelé).
final monetizationServiceProvider = Provider<MonetizationService>((ref) {
  final db = ref.watch(databaseProvider);
  return MonetizationService(
    walletStore: ref.watch(walletStoreProvider),
    entitlementsDao: db.trekEntitlementsDao,
    noAdsDao: db.noAdsDao,
    iapService: ref.watch(walletIapServiceProvider),
    connectivityMonitor: ref.watch(connectivityMonitorProvider),
    // LA BARRIERE DE LA DEMO (tache 634, DEM-260929-1123). `ref.read` DANS la
    // fonction, comme `stagesOf` juste en dessous : l'etat est lu A L'INSTANT
    // de l'ecriture, donc entrer ou quitter la demo agit sans reconstruire le
    // service ni invalider quoi que ce soit.
    enDemo: () => ref.read(enDemoProvider),
    // LE PRIX VIENT DU CATALOGUE EFFECTIF (avenant 614), pas du catalogue
    // compilé. La nuance est tout l'enjeu depuis la tâche 605 : un sentier
    // décrit à DISTANCE n'a pas le nombre d'étapes du sentier compilé du même
    // nom, et c'est précisément pour cela que laisser six écrans déclarer
    // chacun leur montant était six occasions de vendre au mauvais prix.
    //
    // `ref.read` DANS la fonction, et non au-dessus : le nombre est lu À
    // L'INSTANT DE L'ACHAT. Un manifeste distant reçu entre-temps est donc pris
    // en compte, sans reconstruire le service ni invalider quoi que ce soit.
    stagesOf: (trailId) {
      for (final sentier in ref.read(availableTrailsProvider)) {
        if (sentier.id == trailId) return sentier.totalStages;
      }
      return TrailCatalog.byId(trailId)?.totalStages ?? 0;
    },
  );
});

/// Provider asynchrone qui garantit le chargement du [MonetizationService].
///
/// À `watch` au boot (`app_bootstrap_provider.dart`) AVANT tout accès aux droits
/// : hydrate le wallet, migre le legacy, démarre l'écoute IAP et resynchronise
/// le cache [FeatureFlags]. Retourne l'instance chargée.
final monetizationReadyProvider = FutureProvider<MonetizationService>((
  ref,
) async {
  final service = ref.watch(monetizationServiceProvider);
  await service.load();
  return service;
});

/// Observe le droit d'accès d'un trek (StreamProvider indexé par `trailId`).
///
/// Émet à chaque mutation Drift des `TrekEntitlements` : c'est le signal qui
/// permet à [isDemoModeProvider] de se réévaluer quand un achat pose `owned`.
final _entitlementProvider = StreamProvider.family<TrekEntitlement?, String>((
  ref,
  trailId,
) {
  return ref.watch(monetizationServiceProvider).watchEntitlement(trailId);
});

/// Mode démo RÉACTIF d'un trek (`isDemoMode`), indexé par `trailId`.
///
/// Remplace l'appel one-shot `FutureBuilder(monetization.isDemoMode(...))` du
/// [PurchaseGateWidget] : en observant [monetizationReadyProvider] (boot) ET
/// [_entitlementProvider] (mutations Drift), le calcul est RELANCÉ dès qu'un
/// achat débloque le trek pendant l'affichage — le bandeau démo ne peut plus
/// rester périmé (réserve QA StepWays LOT 1). Vitrine/abo restent couverts par
/// la source unique [MonetizationService.isDemoMode].
final isDemoModeProvider = FutureProvider.family<bool, String>((
  ref,
  trailId,
) async {
  final service = await ref.watch(monetizationReadyProvider.future);
  ref.watch(_entitlementProvider(trailId)); // relance au flip owned
  return service.isDemoMode(trailId);
});

/// Solde du COMPTE-ÉTAPES, en étapes (correctif L7-1).
///
/// Le portefeuille existait entièrement — table Drift, DAO, `WalletStore`,
/// recharge et débit dans ce service — mais son solde n'était affiché NULLE
/// PART : le randonneur dépensait des étapes sans jamais voir ce qu'il lui en
/// restait. Ce provider n'ajoute aucune règle métier, il expose la source
/// existante ([MonetizationService.watchWalletSteps]) en la faisant précéder du
/// chargement ([monetizationReadyProvider]) — sans quoi le premier rendu
/// afficherait un solde de zéro avant l'hydratation des préférences.
final walletStepsProvider = StreamProvider<int>((ref) async* {
  final service = await ref.watch(monetizationReadyProvider.future);
  // Valeur d'ouverture : le solde déjà hydraté, pour ne pas attendre le
  // premier mouvement du portefeuille avant d'afficher quelque chose.
  yield service.walletSteps;
  yield* service.watchWalletSteps();
});
