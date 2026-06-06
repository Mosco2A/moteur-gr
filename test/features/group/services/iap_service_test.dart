import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/follow_links_config.dart';
import 'package:moteur_gr/features/group/services/iap_service.dart';
import 'package:moteur_gr/features/group/models/share_link.dart';

/// Tests du IapService (E4.14).
///
/// Verifie que l achat mock genere un lien web permanent
/// sans pub (pass=1), avec base d URL injectee (zero marque en dur).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IapService svc;

  setUp(() {
    svc = IapService(
      testMode: true,
      linksConfig: const FollowLinksConfig(
        webLinkBase: 'https://montrek.example/follow',
      ),
    );
  });

  group('IapService', () {
    test('achat mock genere un ShareLink web permanent avec pass', () async {
      // Arrange
      const sessionId = 'session-test-123';
      const shareCode = 'AB3K7P';

      // Act — buyAndGenerateLink en testMode retourne un lien
      final link = await svc.buyAndGenerateLink(
        sessionId: sessionId,
        shareCode: shareCode,
      );

      // Assert — lien genere, type web, URL avec pass=1
      expect(link, isNotNull);
      expect(link!.sessionId, equals(sessionId));
      expect(link.type, equals(ShareLinkTypeValues.web));
      expect(link.url, contains(shareCode));
      expect(link.url, contains('pass=1'));
      expect(link.url, startsWith('https://montrek.example/follow/'));
      expect(link.activatedAt, isNotNull);
      expect(link.id, isNotEmpty);
    });

    test('handlePurchaseComplete retourne null si achat non verifie', () {
      // Arrange & Act
      final link = svc.handlePurchaseComplete(
        sessionId: 'session-xyz',
        shareCode: 'XY9Z3R',
        purchaseVerified: false,
      );

      // Assert
      expect(link, isNull);
    });

    test('isAvailable retourne true en testMode', () async {
      final available = await svc.isAvailable();
      expect(available, isTrue);
    });
  });

  group('IapService — garde-fou anti-paiement-reel (F6)', () {
    test('kill-switch global desactive', () {
      expect(kIapRealModeEnabled, isFalse,
          reason: 'AUCUN produit store reel cree : le kill-switch doit '
              'rester false tant que la procedure documentee (produits '
              'store + verification recus + GO) n est pas executee');
    });

    test('testMode est force par defaut', () {
      final defaultSvc = IapService();
      expect(defaultSvc.testMode, isTrue);
    });

    test(
        'meme testMode:false ne touche jamais le store '
        'tant que le kill-switch est off', () async {
      // Aucune instance IAP injectee : tout acces plateforme reel
      // leverait MissingPluginException en environnement de test.
      final svc = IapService(testMode: false);

      expect(await svc.isAvailable(), isTrue);
      expect(await svc.getPassDetails(), isNull);
      expect(await svc.purchaseWebFollowPass(), isTrue);
      expect(await svc.purchaseStream.isEmpty, isTrue);
    });
  });
}
