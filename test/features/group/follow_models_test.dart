import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:moteur_gr/features/group/models/follow_session.dart'
    as freezed_session;
import 'package:moteur_gr/features/group/models/follower_slot.dart'
    as freezed_slot;
import 'package:moteur_gr/features/group/models/share_link.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/follow_sessions_dao.dart';

/// Tests des modeles de suivi (E4.10).
///
/// Verifie la serialisation JSON des modeles Freezed,
/// le contrat String extensible de ShareLinkType (#81752)
/// et la contrainte d unicite du shareCode en base Drift.
void main() {
  group('FollowSession Freezed serialization', () {
    test('toJson / fromJson roundtrip preserve toutes les proprietes', () {
      const session = freezed_session.FollowSession(
        id: 'sess-001',
        trekkerUserId: 'user-abc',
        shareCode: 'XK9P2L',
        createdAt: '2026-06-01T10:00:00Z',
        expiresAt: '2026-06-02T10:00:00Z',
        isActive: true,
      );

      final json = session.toJson();
      final restored = freezed_session.FollowSession.fromJson(json);

      expect(restored.id, session.id);
      expect(restored.trekkerUserId, session.trekkerUserId);
      expect(restored.shareCode, session.shareCode);
      expect(restored.createdAt, session.createdAt);
      expect(restored.expiresAt, session.expiresAt);
      expect(restored.isActive, session.isActive);
      expect(restored, session);
    });

    test('FollowerSlot toJson / fromJson roundtrip', () {
      const slot = freezed_slot.FollowerSlot(
        id: 'slot-001',
        sessionId: 'sess-001',
        followerName: 'Marie',
        isPaid: false,
        adSupported: true,
      );

      final json = slot.toJson();
      final restored = freezed_slot.FollowerSlot.fromJson(json);

      expect(restored.id, slot.id);
      expect(restored.sessionId, slot.sessionId);
      expect(restored.followerName, slot.followerName);
      expect(restored.isPaid, false);
      expect(restored.adSupported, true);
      expect(restored, slot);
    });

    test('ShareLink serialise le type String correctement', () {
      const link = ShareLink(
        id: 'link-001',
        sessionId: 'sess-001',
        type: ShareLinkTypeValues.web,
        url: 'https://example.org/follow/XK9P2L',
      );

      final json = link.toJson();
      expect(json['type'], 'web');

      final restored = ShareLink.fromJson(json);
      expect(restored.type, ShareLinkTypeValues.web);
      expect(restored.activatedAt, isNull);
    });

    test('ShareLinkType couvre les 3 canaux et tolere une valeur inconnue',
        () {
      // 3 canaux de suivi (#81753) : app gratuite, web payant,
      // app complementaire payante.
      expect(ShareLinkTypeValues.values, hasLength(3));
      expect(ShareLinkTypeValues.values, contains(ShareLinkTypeValues.app));
      expect(ShareLinkTypeValues.values, contains(ShareLinkTypeValues.web));
      expect(
        ShareLinkTypeValues.values,
        contains(ShareLinkTypeValues.companionApp),
      );

      // String extensible (#81752) : valeur inconnue -> fallback
      expect(
        ShareLinkTypeValues.fromString('canal-inconnu'),
        ShareLinkTypeValues.fallback,
      );
      expect(
        ShareLinkTypeValues.fromString('companion_app'),
        ShareLinkTypeValues.companionApp,
      );
    });
  });

  group('shareCode unique en base Drift', () {
    late AppDatabase db;
    late FollowSessionsDao dao;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      dao = FollowSessionsDao(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('insertion avec shareCode duplique leve une exception', () async {
      const entry1 = FollowSessionsCompanion(
        id: Value('sess-001'),
        trekkerUserId: Value('user-abc'),
        shareCode: Value('XK9P2L'),
        createdAt: Value('2026-06-01T10:00:00Z'),
        expiresAt: Value('2026-06-02T10:00:00Z'),
      );

      const entry2 = FollowSessionsCompanion(
        id: Value('sess-002'),
        trekkerUserId: Value('user-def'),
        shareCode: Value('XK9P2L'),
        createdAt: Value('2026-06-01T11:00:00Z'),
        expiresAt: Value('2026-06-02T11:00:00Z'),
      );

      await dao.insertOrReplace(entry1);

      // Le second insert avec le meme shareCode mais un id different
      // doit echouer car shareCode est unique
      expect(
        () async => db
            .into(db.followSessions)
            .insert(entry2, mode: InsertMode.insert),
        throwsA(isA<Object>()),
      );
    });

    test('deux shareCodes differents s inserent sans erreur', () async {
      const entry1 = FollowSessionsCompanion(
        id: Value('sess-001'),
        trekkerUserId: Value('user-abc'),
        shareCode: Value('XK9P2L'),
        createdAt: Value('2026-06-01T10:00:00Z'),
        expiresAt: Value('2026-06-02T10:00:00Z'),
      );

      const entry2 = FollowSessionsCompanion(
        id: Value('sess-002'),
        trekkerUserId: Value('user-def'),
        shareCode: Value('AB3C7D'),
        createdAt: Value('2026-06-01T11:00:00Z'),
        expiresAt: Value('2026-06-02T11:00:00Z'),
      );

      await dao.insertOrReplace(entry1);
      await dao.insertOrReplace(entry2);

      final all = await dao.getAll();
      expect(all.length, 2);
      expect(all[0].shareCode, isNot(all[1].shareCode));
    });
  });
}
