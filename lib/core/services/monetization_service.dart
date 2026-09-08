import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/feature_flags.dart';
import '../config/trail_catalog.dart';
import '../data/daos/no_ads_dao.dart';
import '../data/daos/trek_entitlements_dao.dart';
import '../data/database.dart';
import '../network/connectivity_monitor.dart';
import '../providers/database_provider.dart';
import 'wallet_iap_service.dart';
import 'wallet_store.dart';

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
/// Trois niveaux (spec §2.4) :
///   - [free]       : trek ni possédé ni couvert par un abo → démo + pub ;
///   - [subscriber] : trek non possédé mais l'utilisateur a un abo actif
///                    → jouable, SANS pub (l'abo débloque le sans-pub app-wide) ;
///   - [owned]      : trek possédé (achat confirmé store) → jouable, sans pub.
///
/// Un sentier VITRINE (parité GR20) est traité comme [owned] (jouable sans
/// achat) — voir [MonetizationService.accessFor].
enum TrailAccess {
  /// Gratuit : démo + pub (trek non débloqué).
  free,

  /// Débloqué par un abonnement actif (sans-pub app-wide).
  subscriber,

  /// Possédé (achat confirmé) ou vitrine.
  owned;

  /// Le trek est-il JOUABLE (carte GPS, journal…) à ce niveau d'accès ?
  ///
  /// Vrai pour [subscriber] et [owned] ; faux pour [free] (démo).
  bool get isPlayable => this != TrailAccess.free;

  /// Faut-il afficher la pub pour ce niveau ? (source unique #99404)
  ///
  /// Pub UNIQUEMENT en [free]. [subscriber] et [owned] sont sans-pub.
  bool get showAds => this == TrailAccess.free;
}

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
  String toString() => 'PurchaseOutcome($status, $trailId, '
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
  String toString() => 'TrailQuote($trailId, besoin=$stepsNeeded, '
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
/// + `showcaseTrailIds`. La persistance durable reste SharedPreferences via
/// [WalletStore] (DB volatile) ; ce service ne fait QUE la règle métier.
class MonetizationService {
  MonetizationService({
    required WalletStore walletStore,
    required TrekEntitlementsDao entitlementsDao,
    required NoAdsDao noAdsDao,
    required WalletIapService iapService,
    required ConnectivityMonitor connectivityMonitor,
    DateTime Function()? nowFn,
    SharedPreferences? prefs,
    Set<String>? showcaseTrailIds,
  })  : _wallet = walletStore,
        _entitlementsDao = entitlementsDao,
        _noAdsDao = noAdsDao,
        _iap = iapService,
        _connectivity = connectivityMonitor,
        _now = nowFn ?? DateTime.now,
        _prefs = prefs,
        _showcaseTrailIds = showcaseTrailIds;

  final WalletStore _wallet;
  final TrekEntitlementsDao _entitlementsDao;
  final NoAdsDao _noAdsDao;
  final WalletIapService _iap;
  final ConnectivityMonitor _connectivity;

  /// Horloge injectable (reward 24 h testable via `Clock`).
  final DateTime Function() _now;

  SharedPreferences? _prefs;
  final Set<String>? _showcaseTrailIds;

  Future<SharedPreferences> get _preferences async =>
      _prefs ??= await SharedPreferences.getInstance();

  bool _loaded = false;

  /// Indique si l'état persisté a été chargé ([load]).
  bool get isLoaded => _loaded;

  // --- Vitrine (parité GR20, LOT 2 #99433) ---------------------------------

  Set<String> get _showcase => _showcaseTrailIds ?? TrailCatalog.showcaseIds;

  /// Vrai si [trailId] est un sentier VITRINE (débloqué jouable sans achat).
  bool isShowcaseTrail(String trailId) => _showcase.contains(trailId);

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

  /// Niveau d'accès effectif du trek (spec §2.4) : owned > subscriber > free.
  ///
  /// Priorité : possédé/vitrine → [TrailAccess.owned] ; sinon abo actif →
  /// [TrailAccess.subscriber] ; sinon [TrailAccess.free] (démo + pub).
  Future<TrailAccess> accessFor(String trailId) async {
    if (isShowcaseTrail(trailId) || await ownsTrail(trailId)) {
      return TrailAccess.owned;
    }
    if (await isSubscriberActive()) return TrailAccess.subscriber;
    return TrailAccess.free;
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
  /// `need = totalStages − acquis` ; `fromWallet = min(wallet, need)` ;
  /// `complément = need − fromWallet`. Le pack de complément est le plus petit
  /// couvrant le manque (reco §3.1). N'engage RIEN (lecture seule).
  Future<TrailQuote> quoteTrail(String trailId, {required int totalStages}) {
    return _quote(trailId, totalStages: totalStages, useAcquired: true);
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
  Future<PurchaseOutcome> buyTrail(
    String trailId, {
    required int totalStages,
  }) async {
    if (await ownsTrail(trailId)) {
      return PurchaseOutcome(
        status: PurchaseStatusResult.alreadyOwned,
        trailId: trailId,
      );
    }

    final quote = await _quote(trailId, totalStages: totalStages, useAcquired: true);

    // 1) Débit wallet (offline OK). Jamais de solde négatif (garde WalletStore).
    if (quote.stepsFromWallet > 0) {
      await _wallet.debit(quote.stepsFromWallet);
    }

    // 2) Complément store : EXIGE le réseau, sinon rollback.
    if (quote.complementSteps > 0) {
      final online = await _isOnline();
      if (!online) {
        await _rollbackWallet(quote.stepsFromWallet);
        _log.w('[Monetization] $trailId : complément store hors-ligne -> '
            'rollback wallet (${quote.stepsFromWallet} étapes)');
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
      _log.w('[Monetization] $trailId : complément store non confirmé (async) -> '
          'rollback wallet (${quote.stepsFromWallet} étapes)');
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
    _log.i('[Monetization] $trailId acheté (wallet: '
        '${quote.stepsFromWallet} étapes)');
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
  /// L'abo pose `expiresAt = null` tant qu'actif (#99404) ; une valeur non nulle
  /// dans le passé = expiré.
  Future<bool> isSubscriberActive() async {
    final now = _now();
    final states = await _noAdsDao.getAll();
    return states.any((s) =>
        s.source == 'subscription' &&
        (s.expiresAt == null || s.expiresAt!.isAfter(now)));
  }

  /// Lance la souscription à l'abonnement sans-pub (achat store).
  ///
  /// Délègue au [WalletIapService] ; la pose réelle de l'abo arrive par la
  /// boucle de complétion. Retourne true si initié (false en stub).
  Future<bool> subscribe() => _iap.buyNoAdsSubscription();

  /// Callback à appeler quand un abonnement est VALIDÉ (store/backend).
  ///
  /// Pose une source sans-pub 'subscription' (expiresAt null tant qu'actif) et
  /// resynchronise le cache [FeatureFlags]. Idempotent au sens métier : plusieurs
  /// abos actifs restent équivalents à « sans-pub actif ».
  Future<void> onSubscriptionValidated() async {
    final now = _now();
    await _noAdsDao.insertState(
      NoAdsStateCompanion.insert(
        source: 'subscription',
        startedAt: now,
        updatedAt: now,
        expiresAt: const Value(null),
      ),
    );
    await _syncFeatureFlags();
    _log.i('[Monetization] Abo sans-pub validé');
  }

  // --- Reward sans-pub (24 h) ----------------------------------------------

  /// Vrai si une récompense sans-pub (rewarded) est ACTIVE (non expirée).
  ///
  /// Une source 'reward' pose `expiresAt = now + 24 h`. Testable via [nowFn].
  Future<bool> isRewardNoAdsActive() async {
    final now = _now();
    final states = await _noAdsDao.getAll();
    return states.any((s) =>
        s.source == 'reward' &&
        s.expiresAt != null &&
        s.expiresAt!.isAfter(now));
  }

  /// Octroie une récompense sans-pub de 24 h (après une pub rewarded).
  ///
  /// Pose une source 'reward' `expiresAt = now + 24 h` (horloge [nowFn]).
  Future<void> grantRewardNoAds() async {
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
  /// La vitrine (parité GR20), jouable sans achat, est traitée sans-pub via
  /// [accessFor] (niveau `owned`) — cohérent avec [TrailAccess.owned.showAds] ==
  /// false. Aucune UI ne recalcule cette règle ; `AdService.shouldShowAd(isPaid:
  /// …)` se branche dessus (branchement app-wide = ST7, hors périmètre ST4).
  Future<bool> isNoAdsActive(String trailId) async {
    // owned OU vitrine (accessFor renvoie owned pour les deux).
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
    _log.i('[Monetization] $trailId abandonné (acquis conservés: '
        '${e.acquiredStages})');
  }

  /// Devis de REPRISE : ne facture que les étapes non encore acquises.
  ///
  /// Identique à [quoteTrail] mais explicite sur l'intention de reprise : le
  /// besoin = `totalStages − acquis` (les étapes déjà acquises ne sont pas
  /// repayées, spec §2.5 « rachat du complément consommé »).
  Future<TrailQuote> quoteResume(String trailId, {required int totalStages}) {
    return _quote(trailId, totalStages: totalStages, useAcquired: true);
  }

  /// Reprend un trek abandonné : rachète UNIQUEMENT le complément restant.
  ///
  /// Même algo que [buyTrail] (wallet d'abord, complément store, rollback si
  /// hors-ligne/échec), mais le besoin part des étapes déjà acquises.
  Future<PurchaseOutcome> resumeTrail(
    String trailId, {
    required int totalStages,
  }) {
    return buyTrail(trailId, totalStages: totalStages);
  }

  // --- Restauration / reset -------------------------------------------------

  /// Restaure les achats passés (abo) via le store.
  ///
  /// Délègue au [WalletIapService] (`restorePurchases`) ; les événements
  /// arrivent en `restored` sur la boucle de complétion. No-op en mode stub.
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  /// Réinitialise TOUT l'état monétisation (tests / support).
  ///
  /// Efface les droits, les sources sans-pub et le cache [FeatureFlags] premium.
  /// Le solde du compte-étapes est laissé à [WalletStore] (non touché ici).
  Future<void> reset() async {
    final entitlements = await _entitlementsDao.getAll();
    for (final e in entitlements) {
      await _entitlementsDao.deleteByTrailId(e.trailId);
      FeatureFlags.setOverride('premium', e.trailId, enabled: false);
    }
    await _noAdsDao.clear();
    _log.d('[Monetization] reset');
  }

  // --- Features (rétro-compat + parité vitrine) ----------------------------

  /// Resynchronise le cache synchrone [FeatureFlags] premium depuis les droits.
  ///
  /// `premium:trailId = owned || vitrine`. Les gardes de routes synchrones
  /// lisent ce cache ; il est réalimenté au boot ([load]) et à chaque mutation.
  Future<void> _syncFeatureFlags() async {
    final entitlements = await _entitlementsDao.getAll();
    for (final e in entitlements) {
      FeatureFlags.setOverride('premium', e.trailId, enabled: e.owned);
    }
    for (final trailId in _showcase) {
      FeatureFlags.setOverride('premium', trailId, enabled: true);
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

  /// Features applicables pour un trek : premium si JOUABLE (owned/abo/vitrine),
  /// sinon gratuit (démo + pub). Décision dérivée d'[accessFor] (source unique).
  Future<TrailFeatures> featuresForTrail(String trailId) async {
    final access = await accessFor(trailId);
    return access.isPlayable ? getPremiumFeatures() : getTrialFeatures();
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
  );
});

/// Provider asynchrone qui garantit le chargement du [MonetizationService].
///
/// À `watch` au boot (`app_bootstrap_provider.dart`) AVANT tout accès aux droits
/// : hydrate le wallet, migre le legacy, démarre l'écoute IAP et resynchronise
/// le cache [FeatureFlags]. Retourne l'instance chargée.
final monetizationReadyProvider = FutureProvider<MonetizationService>((ref) async {
  final service = ref.watch(monetizationServiceProvider);
  await service.load();
  return service;
});

/// Observe le droit d'accès d'un trek (StreamProvider indexé par `trailId`).
///
/// Émet à chaque mutation Drift des `TrekEntitlements` : c'est le signal qui
/// permet à [isDemoModeProvider] de se réévaluer quand un achat pose `owned`.
final _entitlementProvider =
    StreamProvider.family<TrekEntitlement?, String>((ref, trailId) {
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
final isDemoModeProvider = FutureProvider.family<bool, String>((ref, trailId) async {
  final service = await ref.watch(monetizationReadyProvider.future);
  ref.watch(_entitlementProvider(trailId)); // relance au flip owned
  return service.isDemoMode(trailId);
});
