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

/// Service d achat in-app pour le pass suivi web (E4.14).
///
/// Permet a un proche d acheter un pass a 1 EUR pour suivre
/// le randonneur depuis le web sans publicite.
/// Apres achat, genere un [ShareLink] de type web permanent.
///
/// STUBS/SANDBOX UNIQUEMENT : testMode bypasse le store ;
/// en production le flux passe par purchaseStream (verification
/// d achat requise avant generation du lien).
///
/// E4.14 — Dependances: E4.12a (ShareLink web), E4.13 (AdService).
class IapService {
  IapService({
    InAppPurchase? iapInstance,
    this.linksConfig = const FollowLinksConfig(),
    this.testMode = false,
  }) : _iapOverride = iapInstance;

  /// Instance IAP injectee (ou null pour utiliser le singleton).
  final InAppPurchase? _iapOverride;

  /// Bases d URL des liens de partage (injectees, jamais en dur).
  final FollowLinksConfig linksConfig;

  /// Acces lazy a l instance IAP — evite l init platform en testMode.
  InAppPurchase get _iap => _iapOverride ?? InAppPurchase.instance;

  /// Mode test pour bypasser les appels reels au store.
  final bool testMode;

  /// Verifie si l achat in-app est disponible sur l appareil.
  Future<bool> isAvailable() async {
    if (testMode) return true;
    return _iap.isAvailable();
  }

  /// Recupere les details du produit pass suivi web.
  ///
  /// Retourne null si le produit n est pas trouve ou
  /// si le store est indisponible.
  Future<ProductDetails?> getPassDetails() async {
    if (testMode) return null;

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
    if (testMode) return true;

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
    if (testMode) return const Stream.empty();
    return _iap.purchaseStream;
  }
}

/// Provider Riverpod pour le [IapService].
final iapServiceProvider = Provider<IapService>((ref) {
  final links = ref.watch(followLinksConfigProvider);
  return IapService(linksConfig: links);
});
