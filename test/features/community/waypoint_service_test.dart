import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/daos/waypoints_dao.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/features/community/data/waypoint_service.dart';

/// Sink distant simule (F8A-02).
///
/// - [failPush] : echec de tout push (reste pending) ;
/// - [pullResult] : donnees distantes renvoyees au pull (merge last-write-wins).
class _FakeSink implements WaypointRemoteSink {
  _FakeSink({this.failPush = false, this.pullResult});

  bool failPush;
  WaypointRemotePull? pullResult;
  int pushCommentCount = 0;
  int pushWaypointCount = 0;
  int pullCount = 0;
  DateTime? lastSince;

  @override
  Future<WaypointPushResult> pushWaypoint(WaypointData waypoint) async {
    pushWaypointCount++;
    if (failPush) return const WaypointPushResult.failure('reseau KO');
    return WaypointPushResult.success('fs-${waypoint.id}');
  }

  @override
  Future<WaypointPushResult> pushComment(WaypointCommentData comment) async {
    pushCommentCount++;
    if (failPush) return const WaypointPushResult.failure('reseau KO');
    return WaypointPushResult.success('fs-${comment.id}');
  }

  @override
  Future<WaypointRemotePull> pull({
    required String trailId,
    DateTime? since,
  }) async {
    pullCount++;
    lastSince = since;
    return pullResult ?? const WaypointRemotePull();
  }
}

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

  WaypointService makeService(_FakeSink sink) =>
      WaypointService(database: db, remoteSink: sink);

  // Seed direct en cache pour les tests de lecture offline.
  Future<void> seedWaypoint({
    required String id,
    String trailId = 'mare_a_mare_centre',
    String type = WaypointType.eau,
    String titre = 'Source',
    DateTime? updatedAt,
    String source = WaypointSource.officiel,
  }) async {
    await dao.upsertWaypoints([
      WaypointCompanion.insert(
        id: id,
        trailId: trailId,
        type: type,
        latitude: 42.0,
        longitude: 9.0,
        titre: titre,
        lastUpdatedAt: updatedAt ?? DateTime.utc(2026, 6, 14, 9),
        source: Value(source),
      ),
    ]);
  }

  group('WaypointService — lecture 100% cache offline (R1/R3)', () {
    test('waypointsForTrail lit le cache local sans reseau', () async {
      final sink = _FakeSink();
      final service = makeService(sink);
      await seedWaypoint(id: 'wp-1', trailId: 'mare_a_mare_centre');
      await seedWaypoint(id: 'wp-2', trailId: 'gr20');

      final mam = await service.waypointsForTrail('mare_a_mare_centre');

      expect(mam.length, 1);
      expect(mam.first.id, 'wp-1');
      // Aucune sync n'a ete declenchee par une simple lecture.
      expect(sink.pullCount, 0);
      expect(sink.pushCommentCount, 0);
    });

    test('waypointsByType filtre par type (Comment Filtering FarOut)', () async {
      final service = makeService(_FakeSink());
      await seedWaypoint(id: 'wp-1', type: WaypointType.eau, titre: 'Eau A');
      await seedWaypoint(id: 'wp-2', type: WaypointType.eau, titre: 'Eau B');
      await seedWaypoint(id: 'wp-3', type: WaypointType.danger, titre: 'Danger');

      final eaux = await service.waypointsByType(WaypointType.eau);
      expect(eaux.map((w) => w.id).toSet(), {'wp-1', 'wp-2'});

      final dangers = await service.waypointsByType(WaypointType.danger);
      expect(dangers.single.id, 'wp-3');
    });

    test('visibleComments masque les removed (DSA)', () async {
      final service = makeService(_FakeSink());
      await service.contributeComment(
          waypointId: 'wp-1', authorUidHash: 'h1', texte: 'visible');
      final removedId = await service.contributeComment(
          waypointId: 'wp-1', authorUidHash: 'h2', texte: 'removed');
      await dao.setCommentModerationState(removedId, 'removed');

      final visible = await service.visibleComments('wp-1');
      final textes = visible.map((c) => c.texte).toSet();
      expect(textes.contains('visible'), isTrue);
      expect(textes.contains('removed'), isFalse);
    });
  });

  group('WaypointService — contribution offline (hors-ligne)', () {
    test('contributeWaypoint stocke en cache source communaute', () async {
      final service = makeService(_FakeSink());
      await service.contributeWaypoint(
        id: 'wp-c1',
        trailId: 'mare_a_mare_centre',
        type: WaypointType.eau,
        latitude: 42.1,
        longitude: 9.1,
        titre: 'Source trouvee',
      );

      final wp = await service.waypointById('wp-c1');
      expect(wp, isNotNull);
      expect(wp!.source, WaypointSource.communaute);
      expect(wp.isCommunity, isTrue);
    });

    test('contributeWaypoint rejette un type inconnu', () async {
      final service = makeService(_FakeSink());
      expect(
        () => service.contributeWaypoint(
            id: 'x',
            trailId: 't',
            type: 'invalide',
            latitude: 0,
            longitude: 0,
            titre: 'x'),
        throwsArgumentError,
      );
    });

    test('contributeComment cree un commentaire pending SANS reseau', () async {
      final sink = _FakeSink();
      final service = makeService(sink);
      final id = await service.contributeComment(
        waypointId: 'wp-1',
        authorUidHash: 'hash-aaa',
        texte: 'source a sec',
        condition: 'eau_a_sec',
      );

      expect(id, greaterThan(0));
      expect(await service.pendingCount(), 1);
      // Contribuer ne touche PAS le reseau (sync differee).
      expect(sink.pushCommentCount, 0);
    });
  });

  group('WaypointService — sync differee (push + pull/merge)', () {
    test('au retour reseau, pousse les commentaires pending -> synced',
        () async {
      final sink = _FakeSink();
      final service = makeService(sink);
      await service.contributeComment(
          waypointId: 'wp-1', authorUidHash: 'h1', texte: 'a');
      await service.contributeComment(
          waypointId: 'wp-1', authorUidHash: 'h2', texte: 'b');

      final pushed = await service.trySync(trailId: 'mare_a_mare_centre');

      expect(pushed, 2);
      expect(sink.pushCommentCount, 2);
      expect(await service.pendingCount(), 0);
      expect(service.lastSyncAt, isNotNull);
    });

    test('zone blanche (deferSync) : aucune tentative de sync', () async {
      final sink = _FakeSink();
      final service = makeService(sink);
      await service.contributeComment(
          waypointId: 'wp-1', authorUidHash: 'h1', texte: 'a');

      final pushed =
          await service.trySync(trailId: 't', shouldDeferSync: true);

      expect(pushed, 0);
      expect(sink.pushCommentCount, 0);
      expect(sink.pullCount, 0);
      expect(await service.pendingCount(), 1); // reste en attente
      expect(service.lastSyncAt, isNull);
    });

    test('echec reseau : le commentaire reste pending (retry ulterieur)',
        () async {
      final sink = _FakeSink(failPush: true);
      final service = makeService(sink);
      await service.contributeComment(
          waypointId: 'wp-1', authorUidHash: 'h1', texte: 'a');

      final pushed = await service.trySync(trailId: 't');

      expect(pushed, 0);
      expect(await service.pendingCount(), 1); // requeue
    });

    test('retry BORNE : abandon apres maxAttempts (pas de boucle infinie X6)',
        () async {
      final sink = _FakeSink(failPush: true);
      final service = makeService(sink);
      await service.contributeComment(
          waypointId: 'wp-1', authorUidHash: 'h1', texte: 'a');

      for (var i = 0; i < WaypointService.maxAttempts + 3; i++) {
        await service.trySync(trailId: 't');
      }

      // Le plafond limite le nombre de push reels.
      expect(sink.pushCommentCount, WaypointService.maxAttempts);
      // Plus en file (plafond atteint), reste en echec.
      expect(await service.pendingCount(), 0);
    });

    test('pull : merge last-write-wins (distant plus recent ecrase)', () async {
      await seedWaypoint(
          id: 'wp-1', titre: 'Ancien', updatedAt: DateTime.utc(2026, 6, 10));
      final remote = WaypointData(
        id: 'wp-1',
        trailId: 'mare_a_mare_centre',
        type: WaypointType.eau,
        latitude: 42.0,
        longitude: 9.0,
        titre: 'Recent',
        lastUpdatedAt: DateTime.utc(2026, 6, 14),
        source: WaypointSource.officiel,
      );
      final sink =
          _FakeSink(pullResult: WaypointRemotePull(waypoints: [remote]));
      final service = makeService(sink);

      await service.trySync(trailId: 'mare_a_mare_centre');

      final wp = await service.waypointById('wp-1');
      expect(wp!.titre, 'Recent'); // distant plus recent applique
    });

    test('pull : distant plus ANCIEN ne reecrit pas le cache (LWW)', () async {
      await seedWaypoint(
          id: 'wp-1',
          titre: 'Local recent',
          updatedAt: DateTime.utc(2026, 6, 14));
      final stale = WaypointData(
        id: 'wp-1',
        trailId: 'mare_a_mare_centre',
        type: WaypointType.eau,
        latitude: 42.0,
        longitude: 9.0,
        titre: 'Distant vieux',
        lastUpdatedAt: DateTime.utc(2026, 6, 1),
        source: WaypointSource.officiel,
      );
      final sink =
          _FakeSink(pullResult: WaypointRemotePull(waypoints: [stale]));
      final service = makeService(sink);

      await service.trySync(trailId: 'mare_a_mare_centre');

      final wp = await service.waypointById('wp-1');
      expect(wp!.titre, 'Local recent'); // local conserve
    });

    test('pull : nouveau waypoint distant ajoute au cache', () async {
      final remote = WaypointData(
        id: 'wp-new',
        trailId: 'mare_a_mare_centre',
        type: WaypointType.ravitaillement,
        latitude: 42.0,
        longitude: 9.0,
        titre: 'Refuge',
        lastUpdatedAt: DateTime.utc(2026, 6, 14),
        source: WaypointSource.officiel,
      );
      final sink =
          _FakeSink(pullResult: WaypointRemotePull(waypoints: [remote]));
      final service = makeService(sink);

      await service.trySync(trailId: 'mare_a_mare_centre');

      expect(await service.waypointById('wp-new'), isNotNull);
    });

    test('pull : moderation serveur masque un commentaire localement (DSA)',
        () async {
      final service = makeService(_FakeSink());
      final id = await service.contributeComment(
          waypointId: 'wp-1', authorUidHash: 'h1', texte: 'litige');
      // Le serveur renvoie ce commentaire passe en 'removed'.
      final removed = WaypointCommentData(
        id: id,
        waypointId: 'wp-1',
        authorUidHash: 'h1',
        texte: 'litige',
        condition: null,
        createdAt: DateTime.utc(2026, 6, 14),
        moderationState: 'removed',
        syncState: 'synced',
      );
      final sink2 =
          _FakeSink(pullResult: WaypointRemotePull(comments: [removed]));
      final service2 = makeService(sink2);

      await service2.trySync(trailId: 'mare_a_mare_centre');

      expect(await service2.visibleComments('wp-1'), isEmpty);
    });

    test('since : le 2e pull part de la derniere sync (incrementiel)', () async {
      final sink = _FakeSink();
      final service = makeService(sink);

      await service.trySync(trailId: 't', now: DateTime.utc(2026, 6, 14, 12));
      expect(sink.lastSince, isNull); // 1er pull : depuis le debut

      await service.trySync(trailId: 't');
      expect(sink.lastSince, isNotNull); // 2e pull : depuis lastSyncAt
    });
  });

  group('WaypointService — fraicheur (R3)', () {
    test('freshness expose l anciennete depuis lastUpdatedAt', () async {
      final service = makeService(_FakeSink());
      await seedWaypoint(id: 'wp-1', updatedAt: DateTime.utc(2026, 6, 14, 9));

      final wp = await service.waypointById('wp-1');
      final age = wp!.freshness(now: DateTime.utc(2026, 6, 14, 11));

      expect(age, const Duration(hours: 2));
    });
  });
}
