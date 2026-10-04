/// Grille du compte-etapes : prix d'un palier, packs de recharge, et achat qui
/// prend d'abord au solde avant de passer au store.
///
/// RANGEMENT (lot 645-06b, regle 12 : pas de `part` hors code genere). Ce
/// fichier porte [MonetizationService], la FACADE de la monetisation : son API
/// publique n'a pas change d'un symbole, et elle delegue chaque responsabilite
/// a une classe collaboratrice du meme dossier :
///   - `monetization_pricing.dart` : catalogue et prix ([TrailPricing]) ;
///   - `monetization_entitlements.dart` : droits par trek
///     ([TrekEntitlementLedger]) ;
///   - `monetization_subscription.dart` : abonnement et cagnotte
///     ([SubscriptionLedger]) ;
///   - `monetization_rewards.dart` : recompense video de 24 h
///     ([RewardNoAdsLedger]) ;
///   - `monetization_access.dart` : niveau d'acces et regle sans-pub
///     ([TrailAccessPolicy]) ;
///   - `monetization_purchases.dart` : devis, achat, reprise, restauration
///     ([TrailPurchases]).
/// Il re-exporte `monetization_models.dart` (les types),
/// `monetization_providers.dart` (les fournisseurs Riverpod) et les constantes
/// de la grille et des cles legacy : les appelants n'importent que lui.
library;

import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/daos/no_ads_dao.dart';
import '../data/daos/trek_entitlements_dao.dart';
import '../data/database.dart';
import '../network/connectivity_monitor.dart';
import 'monetization_access.dart';
import 'monetization_dependencies.dart';
import 'monetization_entitlements.dart';
import 'monetization_models.dart';
import 'monetization_pricing.dart';
import 'monetization_purchases.dart';
import 'monetization_rewards.dart';
import 'monetization_subscription.dart';
import 'wallet_iap_service.dart';
import 'wallet_store.dart';

export 'monetization_entitlements.dart'
    show kDemoModePurchasedTrailsPrefsKey, kPurchasedTrailsPrefsKey;
export 'monetization_models.dart';
export 'monetization_pricing.dart' show kStepPacks, kStepTierEur;
export 'monetization_providers.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

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
/// reflété dans `FeatureFlags` (`premium:trailId`, cache synchrone) pour les
/// gardes de routes.
///
/// Injection intégrale (tests) : collaborateurs + horloge `nowFn` (reward 24 h)
/// + `freeTrailIds`. La persistance durable reste SharedPreferences via
/// [WalletStore] ; ce service ne fait QUE la règle métier. (La base n'est plus
/// volatile depuis la tâche 613 — voir [WalletStore] pour l'arbitrage qui laisse
/// les préférences en source durable du solde.)
///
/// COMPOSITION (lot 645-06b). Chaque methode publique ci-dessous delegue a la
/// classe qui porte sa responsabilite ; la documentation detaillee de chaque
/// regle vit avec son code, dans cette classe.
class MonetizationService {
  /// Construit le service sur ses dependances injectees ; les collaborateurs
  /// sont crees au premier usage, tous sur ces memes dependances.
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
  }) : _deps = MonetizationDependencies(
         wallet: walletStore,
         entitlementsDao: entitlementsDao,
         noAdsDao: noAdsDao,
         iap: iapService,
         connectivity: connectivityMonitor,
         now: nowFn ?? DateTime.now,
         prefs: prefs,
         enDemo: enDemo,
         freeTrailIds: freeTrailIds,
         stagesOf: stagesOf,
       );

  final MonetizationDependencies _deps;
  late final TrailPricing _pricing = TrailPricing(_deps);
  late final TrekEntitlementLedger _entitlements = TrekEntitlementLedger(_deps);
  late final SubscriptionLedger _subscription = SubscriptionLedger(
    _deps,
    _entitlements,
  );
  late final RewardNoAdsLedger _rewards = RewardNoAdsLedger(_deps);
  late final TrailAccessPolicy _access = TrailAccessPolicy(
    ownsTrail: _entitlements.ownsTrail,
    isFreeTrail: _pricing.isFreeTrail,
    isSubscriberActive: _subscription.isSubscriberActive,
    isRewardNoAdsActive: _rewards.isRewardNoAdsActive,
  );
  late final TrailPurchases _purchases = TrailPurchases(
    _deps,
    _pricing,
    _entitlements,
  );

  /// Vrai quand une demo volontaire est en cours : AUCUNE ecriture d'argent,
  /// de droit ou d'abonnement ne doit partir (voir
  /// [MonetizationDependencies.enDemo]).
  bool get enDemo => _deps.enDemo;

  bool _loaded = false;

  /// Indique si l'état persisté a été chargé ([load]).
  bool get isLoaded => _loaded;

  // --- Sentiers gratuits et prix : [TrailPricing] ---------------------------

  /// Vrai si [trailId] est un sentier GRATUIT — son prix est nul.
  bool isFreeTrail(String trailId) => _pricing.isFreeTrail(trailId);

  /// Nombre d'étapes du sentier [trailId] — SOURCE UNIQUE DU PRIX.
  int stagesOfTrail(String trailId) => _pricing.stagesOfTrail(trailId);

  /// Prix EUR du sentier [trailId], lu depuis le catalogue (affichage).
  double eurPriceForTrail(String trailId) => _pricing.eurPriceForTrail(trailId);

  /// Prix « catalogue » d'un trek EN ÉTAPES = son nombre d'étapes.
  int stepPriceForTrail({required int totalStages}) =>
      _pricing.stepPriceForTrail(totalStages: totalStages);

  /// Prix EUR d'un nombre d'étapes au tarif palier ([kStepTierEur]).
  double eurPriceForSteps(int steps) => _pricing.eurPriceForSteps(steps);

  /// Nombre d'étapes créditées par un [pack] (raccourci).
  int packSteps(StepPack pack) => _pricing.packSteps(pack);

  /// Prix EUR d'un [pack] (raccourci sur la grille).
  double packPriceEur(StepPack pack) => _pricing.packPriceEur(pack);

  /// Le plus petit pack couvrant [steps] étapes (reco complément §3.1).
  StepPack smallestPackCovering(int steps) =>
      _pricing.smallestPackCovering(steps);

  // --- Boot / migration -----------------------------------------------------

  /// Charge l'état durable (wallet + droits) et migre le legacy (idempotent).
  ///
  /// À appeler au boot (`monetizationReadyProvider` dans
  /// `app_bootstrap_provider.dart`). Corrige l'ancien `loadPurchases()` JAMAIS
  /// appelé : hydrate le [WalletStore], migre les 2 clés prefs legacy vers les
  /// `TrekEntitlements`, démarre l'écoute IAP et resynchronise le cache
  /// `FeatureFlags` premium.
  Future<void> load() async {
    await _deps.wallet.load();
    await migrateLegacyPurchases();
    _deps.iap.startListening();
    await _entitlements.syncFeatureFlags();
    _loaded = true;
    _log.d(
      '[Monetization] Chargé (wallet=${_deps.wallet.balanceSteps} étapes)',
    );
  }

  /// Migre les 2 clés prefs legacy d'achats vers `TrekEntitlements.owned=true`.
  Future<void> migrateLegacyPurchases() =>
      _entitlements.migrateLegacyPurchases();

  // --- Compte-étapes (wallet) ----------------------------------------------

  /// Solde courant du compte-étapes, en étapes.
  int get walletSteps => _deps.wallet.balanceSteps;

  /// Observe le solde du compte-étapes (émet à chaque mouvement).
  Stream<int> watchWalletSteps() =>
      _deps.wallet.watch().map((snap) => snap.balanceSteps);

  /// Recharge le compte-étapes via un [pack] (achat store consommable).
  Future<bool> rechargeWallet(StepPack pack) => _purchases.rechargeWallet(pack);

  // --- Droits / accès : [TrekEntitlementLedger], [TrailAccessPolicy] -------

  /// Vrai si le trek [trailId] est POSSÉDÉ (achat confirmé store).
  Future<bool> ownsTrail(String trailId) => _entitlements.ownsTrail(trailId);

  /// Observe le droit d'accès du trek [trailId] (émet à chaque mutation Drift).
  Stream<TrekEntitlement?> watchEntitlement(String trailId) =>
      _entitlements.watchEntitlement(trailId);

  /// Niveau d'accès effectif du trek (spec §2.4) :
  /// owned > freeTrail > subscriber > free.
  Future<TrailAccess> accessFor(String trailId) => _access.accessFor(trailId);

  /// LE DROIT DE **RÉALISER** LE TREK [trailId] (tâche 594, A1).
  Future<bool> canRealizeTrail(String trailId) =>
      _access.canRealizeTrail(trailId);

  /// Nombre d'étapes déjà acquises pour [trailId] (base du non-repaiement).
  Future<int> acquiredStagesFor(String trailId) =>
      _entitlements.acquiredStagesFor(trailId);

  // --- Devis / achat : [TrailPurchases] -------------------------------------

  /// Devis d'achat d'un trek : besoin, part wallet, complément store.
  Future<TrailQuote> quoteTrail(String trailId) =>
      _purchases.quoteTrail(trailId);

  /// Achète le trek [trailId] (algo spec §2.5 — wallet d'abord, complément store).
  Future<PurchaseOutcome> buyTrail(String trailId) =>
      _purchases.buyTrail(trailId);

  // --- Abonnement : [SubscriptionLedger] ------------------------------------

  /// Vrai si un abonnement sans-pub est ACTIF (source 'subscription' non expirée).
  Future<bool> isSubscriberActive() => _subscription.isSubscriberActive();

  /// Échéance courante du sans-pub d'abonnement (null si aucun abo actif).
  Future<DateTime?> subscriptionExpiresAt() =>
      _subscription.subscriptionExpiresAt();

  /// Lance la souscription à l'abonnement sans-pub (achat store).
  Future<bool> subscribe() => _subscription.subscribe();

  /// Vrai si l'achat in-app est réellement proposé (kill-switch ouvert).
  ///
  /// L'UI en a besoin pour ne PAS promettre un paiement qui n'aura pas lieu :
  /// un bouton qui ne produit rien est un mensonge (règle du LOT X).
  bool get purchaseEnabled => _deps.iap.purchaseEnabled;

  /// Callback à appeler quand un abonnement est VALIDÉ (store/backend).
  Future<void> onSubscriptionValidated() =>
      _subscription.onSubscriptionValidated();

  /// Callback à appeler quand l'abonnement est ANNULÉ / expiré côté store.
  Future<void> onSubscriptionCanceled() =>
      _subscription.onSubscriptionCanceled();

  /// Verse la CAGNOTTE d'étapes de l'abonné pour la période courante (A5).
  Future<SubscriberAllowanceOutcome> grantSubscriberAllowance() =>
      _subscription.grantSubscriberAllowance();

  // --- Reward sans-pub (24 h) : [RewardNoAdsLedger] ------------------------

  /// Vrai si une récompense sans-pub (rewarded) est ACTIVE (non expirée).
  Future<bool> isRewardNoAdsActive() => _rewards.isRewardNoAdsActive();

  /// Échéance de la récompense sans-pub de 24 h (null si aucune active).
  Future<DateTime?> rewardNoAdsExpiresAt() => _rewards.rewardNoAdsExpiresAt();

  /// Octroie une récompense sans-pub de 24 h (après une pub rewarded).
  Future<void> grantRewardNoAds() => _rewards.grantRewardNoAds();

  // --- Règle sans-pub #99404 (source unique) : [TrailAccessPolicy] ---------

  /// SOURCE UNIQUE de la règle sans-pub (#99404) :
  /// `ownsTrail(trailId) || isSubscriberActive || isRewardNoAdsActive`.
  Future<bool> isNoAdsActive(String trailId) => _access.isNoAdsActive(trailId);

  // --- Abandon / reprise ----------------------------------------------------

  /// Enregistre l'abandon d'un trek : les étapes acquises deviennent la BASE de
  /// rachat à la reprise (spec §2.4). Ne détruit rien, ne rembourse rien.
  Future<void> onTrailAbandoned(String trailId) =>
      _entitlements.onTrailAbandoned(trailId);

  /// Devis de REPRISE : ne facture que les étapes non encore acquises.
  Future<TrailQuote> quoteResume(String trailId) =>
      _purchases.quoteResume(trailId);

  /// Reprend un trek abandonné : rachète UNIQUEMENT le complément restant.
  Future<PurchaseOutcome> resumeTrail(String trailId) =>
      _purchases.resumeTrail(trailId);

  // --- Restauration / reset -------------------------------------------------

  /// Restaure les achats passés (abo, recharges) via le store, ET DIT CE QU'ELLE
  /// A PU FAIRE (tâche 594, A3).
  Future<PurchaseRestoreOutcome> restorePurchases() =>
      _purchases.restorePurchases();

  /// Réinitialise TOUT l'état monétisation (tests / support).
  ///
  /// Efface les droits, les sources sans-pub et le cache `FeatureFlags` premium.
  /// Le solde du compte-étapes est laissé à [WalletStore] (non touché ici).
  Future<void> reset() async {
    // DEMO : une demonstration n'efface pas les droits REELS du randonneur
    // (tache 634). Rien ne s'ecrit pendant une demo, et effacer est encore une
    // ecriture.
    if (enDemo) return;
    await _entitlements.deleteAll();
    await _deps.noAdsDao.clear();
    _log.d('[Monetization] reset');
  }

  // --- Features (rétro-compat) : [TrailAccessPolicy] ------------------------

  /// Features du mode gratuit : préparation avec pub + démo.
  TrailFeatures getTrialFeatures() => _access.getTrialFeatures();

  /// Features du mode premium (jouable) : tout, sans pub.
  TrailFeatures getPremiumFeatures() => _access.getPremiumFeatures();

  /// Features applicables pour un trek : premium si JOUABLE (trek acheté ou
  /// vitrine), sinon démo bridée. Décision dérivée d'[accessFor].
  Future<TrailFeatures> featuresForTrail(String trailId) =>
      _access.featuresForTrail(trailId);

  /// Vrai si le trek est en mode démo (non jouable).
  Future<bool> isDemoMode(String trailId) => _access.isDemoMode(trailId);
}
