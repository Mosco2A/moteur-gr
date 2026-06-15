import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logger/logger.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// KILL-SWITCH paiement reel des packs (F8B-03, aligne sur F6 #81753).
///
/// `false` = AUCUN appel reel au store. La MONETISATION des packs est une
/// DECISION DE CHRISTOPHE (briefing R2) : le code modelise « achat de pack »
/// (produit NON-CONSOMMABLE par pack, JAMAIS un abonnement force facon Komoot)
/// mais ne declenche aucun paiement reel tant que ce drapeau est false.
///
/// Pour activer (decision produit + GO explicite + revue de code) :
///  1. creer les produits non-consommables par pack dans Play Console /
///     App Store Connect (un id par pack, voir [PackPurchaseService.productId]) ;
///  2. implementer la verification des recus (purchaseStream -> verification) ;
///  3. passer ce drapeau a `true`.
const bool kPackPurchaseRealModeEnabled = false;

/// Resultat d'une tentative d'achat de pack (F8B-03).
class PackPurchaseResult {
  const PackPurchaseResult.initiated()
      : initiated = true,
        error = null;
  const PackPurchaseResult.unavailable(this.error) : initiated = false;

  /// Vrai si l'achat a ete INITIE (la confirmation passe par le purchaseStream).
  final bool initiated;

  /// Motif d'indisponibilite (null si initie).
  final String? error;
}

/// Service d'achat des packs sentier A LA CARTE (F8B-03, regle metier R2).
///
/// Modelise l'achat d'un PACK comme un produit NON-CONSOMMABLE (un achat = un
/// pack debloque a vie), JAMAIS un abonnement (R2, eviter le piege Komoot
/// A3-11). Aligne sur [IapService] (group) : kill-switch [kPackPurchaseRealModeEnabled]
/// + testMode verrouillent tout appel reel ; en l'etat AUCUN produit store reel
/// n'existe. La decision finale de monetisation revient a Christophe.
class PackPurchaseService {
  PackPurchaseService({
    InAppPurchase? iapInstance,
    this.testMode = true,
  }) : _iapOverride = iapInstance;

  final InAppPurchase? _iapOverride;

  /// Mode test (defaut true, F6) : aucun appel reel au store.
  final bool testMode;

  InAppPurchase get _iap => _iapOverride ?? InAppPurchase.instance;

  /// Garde-fou central : true tant que les appels store sont interdits.
  bool get _stubbed => testMode || !kPackPurchaseRealModeEnabled;

  /// Vrai si l'achat de pack est propose dans l'app (false = pas de paiement).
  ///
  /// Tant que la monetisation n'est pas activee par Christophe, l'UI N'AFFICHE
  /// PAS de bouton d'achat (seulement telecharger) — pas d'abo impose (R2).
  bool get purchaseEnabled => kPackPurchaseRealModeEnabled;

  /// Identifiant produit store NON-CONSOMMABLE d'un pack (1 id par pack, R2).
  static String productId(String packId) => 'pack_$packId';

  /// Disponibilite de l'achat in-app sur l'appareil.
  Future<bool> isAvailable() async {
    if (_stubbed) return false; // pas de store en mode stub
    return _iap.isAvailable();
  }

  /// Recupere les details du produit non-consommable d'un pack (null si stub).
  Future<ProductDetails?> packProduct(String packId) async {
    if (_stubbed) return null;
    final id = productId(packId);
    final response = await _iap.queryProductDetails({id});
    if (response.notFoundIDs.contains(id) || response.productDetails.isEmpty) {
      _log.e('[PackPurchaseService] Produit $id non trouve');
      return null;
    }
    return response.productDetails.first;
  }

  /// Lance l'achat NON-CONSOMMABLE d'un pack (jamais un abonnement, R2).
  ///
  /// Retourne [PackPurchaseResult.initiated] si l'achat a demarre. En mode stub
  /// (defaut), renvoie `unavailable` SANS aucun appel reel : la monetisation est
  /// une decision de Christophe.
  Future<PackPurchaseResult> buyPack(String packId) async {
    if (_stubbed) {
      return const PackPurchaseResult.unavailable(
        'achat desactive (decision monetisation Christophe)',
      );
    }
    final details = await packProduct(packId);
    if (details == null) {
      return const PackPurchaseResult.unavailable('produit introuvable');
    }
    final param = PurchaseParam(productDetails: details);
    // NON-CONSOMMABLE : un achat debloque le pack a vie (R2, pas d'abo).
    final ok = await _iap.buyNonConsumable(purchaseParam: param);
    return ok
        ? const PackPurchaseResult.initiated()
        : const PackPurchaseResult.unavailable('achat refuse par le store');
  }

  /// Flux d'achats du store (vide en mode stub).
  Stream<List<PurchaseDetails>> get purchaseStream {
    if (_stubbed) return const Stream.empty();
    return _iap.purchaseStream;
  }
}

/// Provider du service d'achat de packs (F8B-03).
///
/// testMode force (F6) : aucun paiement reel possible. L'activation passe par
/// [kPackPurchaseRealModeEnabled] (decision Christophe + GO + revue).
final packPurchaseServiceProvider = Provider<PackPurchaseService>(
  (ref) => PackPurchaseService(testMode: true),
);
