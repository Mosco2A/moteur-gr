import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/follow_links_config.dart';
import '../models/share_link.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));
const _uuid = Uuid();

/// Identifiant produit IAP pour le pass suivi web (1 EUR, #81753).
const kWebFollowPassProductId = 'web_follow_pass';

/// Prix du pass suivi web en EUR.
const kWebFollowPassPrice = 1.0;

/// KILL-SWITCH paiement reel — finitions V8 F6.
///
/// `false` = AUCUN appel reel au store possible : toutes les methodes
/// store de [IapService] sont court-circuitees en stub, quel que soit
/// le `testMode` de l'instance. AUCUN produit store reel n'est cree
/// cote Google Play / App Store a ce stade.
///
/// Pour activer le paiement reel (decision produit + GO explicite) :
///  1. creer le produit [kWebFollowPassProductId] dans Play Console
///     et App Store Connect ;
///  2. implementer la verification des recus d'achat
///     (purchaseStream -> verification -> handlePurchaseComplete),
///     aujourd'hui buyAndGenerateLink est un flux mock ;
///  3. passer cette constante a `true` (revue de code obligatoire).
const bool kIapRealModeEnabled = false;

/// Service d achat in-app pour le pass suivi web (E4.14).
///
/// Permet a un proche d acheter un pass a 1 EUR pour suivre
/// le randonneur depuis le web sans publicite.
/// Apres achat, genere un [ShareLink] de type web permanent.
///
/// STUBS/SANDBOX UNIQUEMENT : testMode (defaut) bypasse le store, et
/// le kill-switch [kIapRealModeEnabled] verrouille TOUT appel reel
/// meme si testMode est desactive (garde-fou anti-paiement-reel F6) ;
/// en production le flux passe par purchaseStream (verification
/// d achat requise avant generation du lien).
///
/// E4.14 — Dependances: E4.12a (ShareLink web), E4.13 (AdService).
class IapService {
  IapService({
    InAppPurchase? iapInstance,
    this.linksConfig = const FollowLinksConfig(),
    this.testMode = true,
  }) : _iapOverride = iapInstance;

  /// Instance IAP injectee (ou null pour utiliser le singleton).
  final InAppPurchase? _iapOverride;

  /// Bases d URL des liens de partage (injectees, jamais en dur).
  final FollowLinksConfig linksConfig;

  /// Acces lazy a l instance IAP — evite l init platform en testMode.
  InAppPurchase get _iap => _iapOverride ?? InAppPurchase.instance;

  /// Mode test pour bypasser les appels reels au store.
  ///
  /// `true` par DEFAUT (F6) : le mode reel est un opt-in explicite,
  /// lui-meme verrouille par [kIapRealModeEnabled].
  final bool testMode;

  /// Garde-fou central : true tant que les appels store sont interdits.
  ///
  /// Combine le testMode d'instance et le kill-switch global — une
  /// instance construite avec `testMode: false` reste neutralisee
  /// tant que [kIapRealModeEnabled] est false.
  bool get _stubbed => testMode || !kIapRealModeEnabled;

  /// Verifie si l achat in-app est disponible sur l appareil.
  Future<bool> isAvailable() async {
    if (_stubbed) return true;
    return _iap.isAvailable();
  }

  /// Recupere les details du produit pass suivi web.
  ///
  /// Retourne null si le produit n est pas trouve ou
  /// si le store est indisponible.
  Future<ProductDetails?> getPassDetails() async {
    if (_stubbed) return null;

    final response = await _iap.queryProductDetails({kWebFollowPassProductId});

    if (response.notFoundIDs.contains(kWebFollowPassProductId)) {
      _log.e('[IapService] Produit $kWebFollowPassProductId non trouve');
      return null;
    }

    if (response.productDetails.isEmpty) return null;
    return response.productDetails.first;
  }

  /// Lance l achat du pass suivi web.
  ///
  /// Retourne `true` si l achat a ete initie (pas encore confirme).
  /// L ecoute des [purchaseStream] gere la confirmation.
  Future<bool> purchaseWebFollowPass({ProductDetails? productDetails}) async {
    if (_stubbed) return true;

    final details = productDetails ?? await getPassDetails();
    if (details == null) {
      _log.e('[IapService] Impossible d acheter: produit introuvable');
      return false;
    }

    final purchaseParam = PurchaseParam(productDetails: details);
    return _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Traite un achat confirme et genere le lien permanent.
  ///
  /// Apres verification de l achat, genere un [ShareLink] web
  /// permanent sans pub pour la session donnee.
  /// Retourne le [ShareLink] genere, ou null si l achat est invalide.
  ShareLink? handlePurchaseComplete({
    required String sessionId,
    required String shareCode,
    required bool purchaseVerified,
  }) {
    if (!purchaseVerified) {
      _log.w('[IapService] Achat non verifie pour session $sessionId');
      return null;
    }

    final link = ShareLink(
      id: _uuid.v4(),
      sessionId: sessionId,
      type: ShareLinkTypeValues.web,
      url: '${linksConfig.webLink(shareCode)}?pass=1',
      activatedAt: DateTime.now().toIso8601String(),
    );

    _log.i('[IapService] Pass suivi web genere pour session $sessionId');
    return link;
  }

  /// Flux d achat combine: achat mock + generation lien.
  ///
  /// Methode de commodite pour les tests et l integration.
  /// En production, utiliser [purchaseWebFollowPass] puis
  /// [handlePurchaseComplete] separement via le purchaseStream.
  Future<ShareLink?> buyAndGenerateLink({
    required String sessionId,
    required String shareCode,
  }) async {
    final purchased = await purchaseWebFollowPass();

    if (!purchased) {
      _log.e('[IapService] Echec achat pour session $sessionId');
      return null;
    }

    return handlePurchaseComplete(
      sessionId: sessionId,
      shareCode: shareCode,
      purchaseVerified: true,
    );
  }

  /// Ecoute le flux d achats pour traitement automatique.
  ///
  /// A appeler au demarrage du service pour gerer les achats
  /// en attente et les restaurations.
  Stream<List<PurchaseDetails>> get purchaseStream {
    if (_stubbed) return const Stream.empty();
    return _iap.purchaseStream;
  }
}

/// Provider Riverpod pour le [IapService].
///
/// testMode force (F6) : aucun paiement reel possible depuis l'app.
/// L'activation du mode reel passe par le kill-switch documente
/// [kIapRealModeEnabled] — voir sa doc pour la procedure.
final iapServiceProvider = Provider<IapService>((ref) {
  final links = ref.watch(followLinksConfigProvider);
  return IapService(linksConfig: links, testMode: true);
});
