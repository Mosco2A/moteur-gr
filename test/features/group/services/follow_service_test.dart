import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/follow_links_config.dart';
import 'package:moteur_gr/core/firebase/firebase_service.dart';
import 'package:moteur_gr/features/group/models/share_link.dart';
import 'package:moteur_gr/features/group/services/follow_service.dart';

/// Tests du FollowService (E4.11).
///
/// Test 1: creation de session retourne null si Firebase indisponible,
///         et generateShareLink produit des URLs conformes (3 canaux).
/// Test 2: limite de 2 suiveurs gratuits (#81759) via canAddFreeFollower.
void main() {
  late FollowService svc;

  setUp(() {
    svc = FollowService(
      firebaseService: FirebaseService.testOnly(isAvailable: false),
      linksConfig: const FollowLinksConfig(
        appLinkBase: 'montrek://follow',
        webLinkBase: 'https://montrek.example/follow',
        companionLinkBase: 'https://montrek.example/companion',
      ),
    );
  });

  group('createSession', () {
    test('retourne null si Firebase indisponible', () async {
      final session = await svc.createSession(trekkerUserId: 'user-001');
      expect(session, isNull);
    });
  });

  group('generateShareLink — 3 canaux (#81753)', () {
    test('genere un deeplink app avec le shareCode', () {
      final link = svc.generateShareLink(
        sessionId: 'sess-001',
        shareCode: 'XK9P2L',
        type: ShareLinkTypeValues.app,
      );

      expect(link.sessionId, 'sess-001');
      expect(link.type, ShareLinkTypeValues.app);
      expect(link.url, 'montrek://follow/XK9P2L');
      expect(link.id, isNotEmpty);
      expect(link.activatedAt, isNotNull);
    });

    test('genere une URL web avec le shareCode', () {
      final link = svc.generateShareLink(
        sessionId: 'sess-002',
        shareCode: 'AB3C7D',
        type: ShareLinkTypeValues.web,
      );

      expect(link.type, ShareLinkTypeValues.web);
      expect(link.url, 'https://montrek.example/follow/AB3C7D');
    });

    test('genere un lien app complementaire avec le shareCode', () {
      final link = svc.generateShareLink(
        sessionId: 'sess-003',
        shareCode: 'QR5T8W',
        type: ShareLinkTypeValues.companionApp,
      );

      expect(link.type, ShareLinkTypeValues.companionApp);
      expect(link.url, 'https://montrek.example/companion/QR5T8W');
    });

    test('type inconnu retombe sur le canal web (String extensible)', () {
      final link = svc.generateShareLink(
        sessionId: 'sess-004',
        shareCode: 'ZZ9Y2X',
        type: 'canal-futur',
      );

      expect(link.type, ShareLinkTypeValues.web);
      expect(link.url, 'https://montrek.example/follow/ZZ9Y2X');
    });

    test('generateAllShareLinks produit les 3 canaux', () {
      final links = svc.generateAllShareLinks(
        sessionId: 'sess-005',
        shareCode: 'KL4M6N',
      );

      expect(links, hasLength(3));
      expect(
        links.map((l) => l.type),
        containsAll([
          ShareLinkTypeValues.app,
          ShareLinkTypeValues.web,
          ShareLinkTypeValues.companionApp,
        ]),
      );
      for (final link in links) {
        expect(link.url, contains('KL4M6N'));
      }
    });
  });

  group('limite suiveurs gratuits (#81759)', () {
    test('canAddFreeFollower: 2 premiers gratuits, 3eme refuse', () {
      expect(svc.canAddFreeFollower(0), isTrue);
      expect(svc.canAddFreeFollower(1), isTrue);
      expect(svc.canAddFreeFollower(2), isFalse);
      expect(svc.canAddFreeFollower(5), isFalse);
      expect(kMaxFreeFollowers, 2);
    });

    test('addFollower retourne null si Firebase indisponible', () async {
      final slot = await svc.addFollower(
        sessionId: 'sess-001',
        name: 'Marie',
      );
      expect(slot, isNull);
    });
  });

  group('publishPosition', () {
    test('retourne false si Firebase indisponible', () async {
      final result = await svc.publishPosition(
        sessionId: 'sess-001',
        lat: 45.83,
        lng: 6.86,
      );
      expect(result, isFalse);
    });
  });
}
