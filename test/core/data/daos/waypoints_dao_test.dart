import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/waypoints_dao.dart';

/// Tests du DAO waypoints + commentaires offline-first (F8A-01) en memoire.
void main() {
  late AppDatabase db;
  late WaypointsDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = WaypointsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  WaypointCompanion makeWaypoint({
    String id = 'wp-1',
    String trailId = 'mare_a_mare_centre',
    String type = 'eau',
    double latitude = 42.0,
    double longitude = 9.0,
    String titre = 'Source du col',
    DateTime? lastUpdatedAt,
    String source = 'officiel',
  }) {
    return WaypointCompanion.insert(
      id: id,
      trailId: trailId,
      type: type,
      latitude: latitude,
      longitude: longitude,
      titre: titre,
      lastUpdatedAt: lastUpdatedAt ?? DateTime.utc(2026, 6, 14, 9),
      source: Value(source),
    );
  }

  WaypointCommentCompanion makeComment({
    String waypointId = 'wp-1',
    String author = 'hash-aaa',
    String texte = 'Eau coule bien',
    String? condition,
    DateTime? createdAt,
    String moderationState = 'visible',
    String syncState = 'pending',
  }) {
    return WaypointCommentCompanion(
      waypointId: Value(waypointId),
      authorUidHash: Value(author),
      texte: Value(texte),
      condition: Value(condition),
      createdAt: Value(createdAt ?? DateTime.utc(2026, 6, 14, 10)),
      moderationState: Value(moderationState),
      syncState: Value(syncState),
    );
  }

  group('WaypointsDao — waypoints cache offline', () {
    test('upsertWaypoints puis waypointsByType filtre par type', () async {
      await dao.upsertWaypoints([
        makeWaypoint(id: 'wp-1', type: 'eau', titre: 'Source A'),
        makeWaypoint(id: 'wp-2', type: 'eau', titre: 'Source B'),
        makeWaypoint(id: 'wp-3', type: 'danger', titre: 'Passage expose'),
        makeWaypoint(id: 'wp-4', type: 'camp', titre: 'Bivouac'),
      ]);

      final eaux = await dao.waypointsByType('eau');
      expect(eaux.length, 2);
      expect(eaux.map((w) => w.id).toSet(), {'wp-1', 'wp-2'});
      // Tri par titre.
      expect(eaux.first.titre, 'Source A');

      final dangers = await dao.waypointsByType('danger');
      expect(dangers.length, 1);
      expect(dangers.first.id, 'wp-3');

      final jonctions = await dao.waypointsByType('jonction');
      expect(jonctions, isEmpty);
    });

    test('upsert idempotent (meme id -> update)', () async {
      await dao.upsertWaypoints([makeWaypoint(id: 'wp-1', titre: 'Avant')]);
      await dao.upsertWaypoints([makeWaypoint(id: 'wp-1', titre: 'Apres')]);
      final wp = await dao.waypointById('wp-1');
      expect(wp, isNotNull);
      expect(wp!.titre, 'Apres');
    });

    test('waypointsForTrail lit le cache d un sentier', () async {
      await dao.upsertWaypoints([
        makeWaypoint(id: 'wp-1', trailId: 'mare_a_mare_centre'),
        makeWaypoint(id: 'wp-2', trailId: 'gr20'),
      ]);
      final mam = await dao.waypointsForTrail('mare_a_mare_centre');
      expect(mam.length, 1);
      expect(mam.first.id, 'wp-1');
    });
  });

  group('WaypointsDao — commentaires offline-first', () {
    test('addCommentLocal cree un commentaire pending sans reseau', () async {
      final id = await dao.addCommentLocal(
        makeComment(condition: 'eau_a_sec'),
      );
      expect(id, greaterThan(0));
      final pending = await dao.pendingComments();
      expect(pending.length, 1);
      expect(pending.first.waypointId, 'wp-1');
      expect(pending.first.authorUidHash, 'hash-aaa');
      expect(pending.first.condition, 'eau_a_sec');
      expect(pending.first.syncState, 'pending');
    });

    test('markCommentSynced retire le commentaire de la file pending', () async {
      final id = await dao.addCommentLocal(makeComment());
      await dao.markCommentSynced(id);
      expect(await dao.pendingComments(), isEmpty);
    });

    test('markCommentFailed + requeue refait passer pending', () async {
      final id = await dao.addCommentLocal(makeComment());
      await dao.markCommentFailed(id);
      expect(await dao.pendingComments(), isEmpty);
      await dao.requeueComment(id);
      expect((await dao.pendingComments()).length, 1);
    });

    test('visibleComments masque les commentaires removed (DSA)', () async {
      await dao.addCommentLocal(
        makeComment(texte: 'visible', moderationState: 'visible'),
      );
      await dao.addCommentLocal(
        makeComment(texte: 'flagged', moderationState: 'flagged'),
      );
      await dao.addCommentLocal(
        makeComment(texte: 'removed', moderationState: 'removed'),
      );

      final visible = await dao.visibleComments('wp-1');
      final textes = visible.map((c) => c.texte).toSet();
      expect(textes.contains('visible'), isTrue);
      expect(textes.contains('flagged'), isTrue); // flagged reste visible
      expect(textes.contains('removed'), isFalse); // removed masque
    });

    test('visibleComments est filtre par waypoint', () async {
      await dao.addCommentLocal(makeComment(waypointId: 'wp-1'));
      await dao.addCommentLocal(makeComment(waypointId: 'wp-2'));
      final wp1 = await dao.visibleComments('wp-1');
      expect(wp1.length, 1);
      expect(wp1.first.waypointId, 'wp-1');
    });

    test('setCommentModerationState reflete une decision serveur', () async {
      final id = await dao.addCommentLocal(makeComment());
      await dao.setCommentModerationState(id, 'removed');
      expect(await dao.visibleComments('wp-1'), isEmpty);
    });
  });
}
