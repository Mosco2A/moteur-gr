import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/daos/no_ads_dao.dart';
import '../data/database.dart';
import '../providers/database_provider.dart';
import 'wallet_store.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// KILL-SWITCH paiement reel du compte-etapes StepWays (LOT 1, aligne F6/F8B).
///
/// `false` = AUCUN appel reel au store. La boucle de completion tourne quand
/// meme (elle est le point d'entree des recus reels a l'activation) mais en
/// mode stub `purchaseStream` est vide et les achats sont court-circuites.
///
/// Pour activer (decision produit + GO explicite + revue de code) :
///  1. creer les produits [kWalletCredits11] / [kWalletCredits25] /
///     [kWalletCredits50] (consommables) et [kWalletSubNoAdsMonthly] (abo)
///     dans Play Console / App Store Connect (SANS prefixe `pack_`, deja pris
///     par les packs de cartes) ;
///  2. implementer la VERIFICATION reelle des recus dans [_verify] (Cloud
///     Function O1C, cf. point d'extension documente) ;
///  3. passer ce drapeau a `true`.
const bool kWalletIapRealModeEnabled = false;

/// ProductId consommable : recharge de 11 etapes (SANS prefixe `pack_`).
const kWalletCredits11 = 'stepways_credits_11';

/// ProductId consommable : recharge de 25 etapes.
const kWalletCredits25 = 'stepways_credits_25';

/// ProductId consommable : recharge de 50 etapes.
const kWalletCredits50 = 'stepways_credits_50';

/// ProductId abonnement : sans-pub mensuel.
const kWalletSubNoAdsMonthly = 'stepways_sub_noads_monthly';

/// Cle SharedPreferences : ids d'achats DEJA DELIVRES (idempotence).
///
/// Anti double-credit : un `purchaseID` present ici a deja ete applique au
/// wallet / a l'abo — la boucle de completion l'ignore (mais le
/// `completePurchase` store est rejoue par securite).
const kWalletDeliveredPurchaseIdsPrefsKey = 'wallet.deliveredPurchaseIds';

/// Nombre d'etapes credite par produit de recharge (consommables).
///
/// L'abonnement ([kWalletSubNoAdsMonthly]) n'est pas ici : il ne credite pas
/// d'etapes, il pose une source sans-pub.
const Map<String, int> kWalletCreditStepsByProduct = {
  kWalletCredits11: 11,
  kWalletCredits25: 25,
  kWalletCredits50: 50,
};

/// Tous les productIds StepWays connus (recharges + abo).
const Set<String> kWalletProductIds = {
  kWalletCredits11,
  kWalletCredits25,
  kWalletCredits50,
  kWalletSubNoAdsMonthly,
};

/// Service IAP du compte-etapes StepWays + BOUCLE DE COMPLETION (LOT 1, ST3).
///
/// Calque sur `iap_service.dart` (group) et `pack_purchase_service.dart`
/// (kill-switch [kWalletIapRealModeEnabled] + `testMode` verrouillent tout
/// appel reel), mais COMBLE le manque de l'existant : la BOUCLE DE COMPLETION
/// absente. En production, chaque achat suit le cycle obligatoire :
///
///   purchaseStream -> (purchased|restored) -> [_verify] (validation online,
///   stub tant que backend absent) -> [_applyDelivery] (credite le wallet /
///   pose l'abo sans-pub) -> `completePurchase` OBLIGATOIRE.
///
/// IDEMPOTENCE par `purchaseID` (cle prefs [kWalletDeliveredPurchaseIdsPrefsKey])
/// : un achat deja delivre n'est jamais re-credite (anti double-credit), meme
/// si le store re-emet l'evenement (restauration, redemarrage). Les recharges
/// sont des CONSOMMABLES ([buyConsumable]) ; l'abo est une subscription.
///
/// La verification reelle des recus (point d'extension [_verify]) sera cablee
/// sur la Cloud Function O1C quand le backend sera pret ; en attendant, stub
/// permissif (tout achat non-stub est considere valide).
class WalletIapService {
  WalletIapService({
    required WalletStore walletStore,
    required NoAdsDao noAdsDao,
    InAppPurchase? iapInstance,
    SharedPreferences? prefs,
    this.testMode = true,
  })  : _walletStore = walletStore,
        _noAdsDao = noAdsDao,
        _iapOverride = iapInstance,
        _prefs = prefs;

  final WalletStore _walletStore;
  final NoAdsDao _noAdsDao;
  final InAppPurchase? _iapOverride;
  SharedPreferences? _prefs;

  /// Mode test (defaut true, F6) : aucun appel reel au store.
  final bool testMode;

  StreamSubscription<List<PurchaseDetails>>? _sub;

  InAppPurchase get _iap => _iapOverride ?? InAppPurchase.instance;

  Future<SharedPreferences> get _preferences async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Garde-fou central : true tant que les appels store sont interdits.
  ///
  /// Combine le `testMode` d'instance et le kill-switch global — une instance
  /// construite avec `testMode: false` reste neutralisee tant que
  /// [kWalletIapRealModeEnabled] est false.
  bool get _stubbed => testMode || !kWalletIapRealModeEnabled;

  /// Vrai si l'achat in-app est propose dans l'app (false = pas de paiement).
  bool get purchaseEnabled => kWalletIapRealModeEnabled;

  /// Disponibilite de l'achat in-app sur l'appareil (false en mode stub).
  Future<bool> isAvailable() async {
    if (_stubbed) return false;
    return _iap.isAvailable();
  }

  /// Flux d'achats du store (VIDE en mode stub — aucun evenement reel).
  Stream<List<PurchaseDetails>> get purchaseStream {
    if (_stubbed) return const Stream<List<PurchaseDetails>>.empty();
    return _iap.purchaseStream;
  }

  /// Recupere les details des produits StepWays (vide en mode stub).
  Future<List<ProductDetails>> queryProducts() async {
    if (_stubbed) return const [];
    final response = await _iap.queryProductDetails(kWalletProductIds);
    if (response.notFoundIDs.isNotEmpty) {
      _log.e('[WalletIap] Produits introuvables: ${response.notFoundIDs}');
    }
    return response.productDetails;
  }

  /// Demarre l'ECOUTE de la boucle de completion (a appeler au boot).
  ///
  /// En mode stub, ne s'abonne a rien (`purchaseStream` vide). En reel, chaque
  /// evenement passe par [_handlePurchases].
  void startListening() {
    _sub ??= purchaseStream.listen(
      _handlePurchases,
      onError: (Object e, StackTrace s) =>
          _log.e('[WalletIap] purchaseStream erreur', error: e, stackTrace: s),
    );
  }

  /// Coupe l'ecoute (a appeler au dispose).
  Future<void> stopListening() async {
    await _sub?.cancel();
    _sub = null;
  }

  /// Lance l'achat d'une RECHARGE (consommable). Retourne true si initie.
  ///
  /// La confirmation passe par la boucle de completion ([purchaseStream]).
  /// En mode stub, aucun appel reel : retourne false.
  Future<bool> buyCredits(String productId) async {
    assert(
      kWalletCreditStepsByProduct.containsKey(productId),
      'productId recharge inconnu: $productId',
    );
    if (_stubbed) return false;
    final details = await _productById(productId);
    if (details == null) return false;
    final param = PurchaseParam(productDetails: details);
    // CONSOMMABLE : une recharge peut etre rachetee (autoConsume par defaut).
    return _iap.buyConsumable(purchaseParam: param);
  }

  /// Lance l'achat de l'ABONNEMENT sans-pub. Retourne true si initie.
  ///
  /// Subscription (pas un consommable). Confirmation via la boucle de
  /// completion. En mode stub, aucun appel reel : retourne false.
  Future<bool> buyNoAdsSubscription() async {
    if (_stubbed) return false;
    final details = await _productById(kWalletSubNoAdsMonthly);
    if (details == null) return false;
    final param = PurchaseParam(productDetails: details);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  /// Restaure les achats passes (abo). Les evenements arrivent en `restored`
  /// sur la boucle de completion. No-op en mode stub.
  Future<void> restorePurchases() async {
    if (_stubbed) return;
    await _iap.restorePurchases();
  }

  Future<ProductDetails?> _productById(String id) async {
    final products = await queryProducts();
    for (final p in products) {
      if (p.id == id) return p;
    }
    _log.e('[WalletIap] Produit $id introuvable');
    return null;
  }

  // --- BOUCLE DE COMPLETION (le manque comble par ST3) ---------------------

  /// Traite un lot d'evenements du store (coeur de la boucle de completion).
  ///
  /// Cycle par achat : selon le statut, deliver (verify -> apply) puis TOUJOURS
  /// `completePurchase` si le store l'attend (obligatoire, sinon l'achat reste
  /// en attente et est re-emis indefiniment).
  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          // Rien a faire : l'UI peut afficher un etat "en attente".
          break;
        case PurchaseStatus.error:
          _log.e('[WalletIap] Achat en erreur: ${purchase.error}');
          break;
        case PurchaseStatus.canceled:
          _log.w('[WalletIap] Achat annule: ${purchase.productID}');
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _deliver(purchase);
          break;
      }
      // OBLIGATOIRE : finaliser l'achat cote store des qu'il l'attend, quel que
      // soit le resultat de la livraison (sinon re-emission infinie).
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  /// Verifie puis delivre un achat, avec idempotence par `purchaseID`.
  Future<void> _deliver(PurchaseDetails purchase) async {
    if (await _isAlreadyDelivered(purchase.purchaseID)) {
      _log.d('[WalletIap] Achat deja delivre (idempotence): '
          '${purchase.purchaseID}');
      return;
    }
    final verified = await _verify(purchase);
    if (!verified) {
      _log.w('[WalletIap] Achat non verifie: ${purchase.productID}');
      return;
    }
    final delivered = await _applyDelivery(purchase);
    if (delivered) {
      await _markDelivered(purchase.purchaseID);
    }
  }

  /// Verification de l'achat (VALIDATION ONLINE — STUB tant que backend absent).
  ///
  /// POINT D'EXTENSION : brancher ici la Cloud Function O1C de validation des
  /// recus (`purchase.verificationData.serverVerificationData`) quand le backend
  /// sera pret. En attendant, stub permissif : tout achat non-stub est
  /// considere valide. En mode stub complet, rien n'arrive jamais ici (stream
  /// vide), donc le retour est sans effet.
  Future<bool> _verify(PurchaseDetails purchase) async {
    // TODO(backend): validation online via Cloud Function O1C
    // (purchase.verificationData). Stub permissif en attendant.
    return true;
  }

  /// Applique la livraison selon le produit : credite le wallet (recharges) ou
  /// pose la source sans-pub (abo). Retourne true si quelque chose a ete livre.
  Future<bool> _applyDelivery(PurchaseDetails purchase) async {
    final creditSteps = kWalletCreditStepsByProduct[purchase.productID];
    if (creditSteps != null) {
      await _walletStore.credit(creditSteps);
      _log.i('[WalletIap] +$creditSteps etapes (${purchase.productID})');
      return true;
    }
    if (purchase.productID == kWalletSubNoAdsMonthly) {
      final now = DateTime.now();
      // Abo sans-pub : expiresAt = null tant qu'actif (#99404). Le suivi fin de
      // l'expiration reelle de l'abo releve de ST4 (MonetizationService).
      await _noAdsDao.insertState(
        NoAdsStateCompanion.insert(
          source: 'subscription',
          startedAt: now,
          updatedAt: now,
          expiresAt: const Value(null),
        ),
      );
      _log.i('[WalletIap] Abo sans-pub pose (${purchase.productID})');
      return true;
    }
    _log.w('[WalletIap] ProductId inconnu, rien livre: ${purchase.productID}');
    return false;
  }

  // --- Idempotence (prefs) --------------------------------------------------

  Future<Set<String>> _deliveredIds() async {
    final prefs = await _preferences;
    return (prefs.getStringList(kWalletDeliveredPurchaseIdsPrefsKey) ??
            const <String>[])
        .toSet();
  }

  Future<bool> _isAlreadyDelivered(String? purchaseId) async {
    if (purchaseId == null || purchaseId.isEmpty) return false;
    return (await _deliveredIds()).contains(purchaseId);
  }

  Future<void> _markDelivered(String? purchaseId) async {
    if (purchaseId == null || purchaseId.isEmpty) return;
    final prefs = await _preferences;
    final ids = await _deliveredIds()
      ..add(purchaseId);
    await prefs.setStringList(
      kWalletDeliveredPurchaseIdsPrefsKey,
      ids.toList()..sort(),
    );
  }
}

/// Provider Riverpod du [WalletIapService].
///
/// testMode force (F6) : aucun paiement reel possible depuis l'app.
/// L'activation passe par le kill-switch [kWalletIapRealModeEnabled] (decision
/// produit + GO + revue). Branche sur le [walletStoreProvider] (credits) et la
/// meme instance Drift ([databaseProvider]) pour la source sans-pub (abo).
final walletIapServiceProvider = Provider<WalletIapService>((ref) {
  final walletStore = ref.watch(walletStoreProvider);
  final db = ref.watch(databaseProvider);
  final service = WalletIapService(
    walletStore: walletStore,
    noAdsDao: db.noAdsDao,
    testMode: true,
  );
  ref.onDispose(service.stopListening);
  return service;
});
