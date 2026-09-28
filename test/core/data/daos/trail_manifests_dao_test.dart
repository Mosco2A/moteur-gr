import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/trail_manifests_dao.dart';
import 'package:moteur_gr/core/data/revision_de_donnee.dart';
import 'package:moteur_gr/core/models/niveau_de_telechargement.dart';

import '../../../fixtures/horodatage_de_serveur.dart';

/// LA REVISION N DEVIENT L INSTANT « REFERENCE + N JOURS » (tache 610).
///
/// La bascule du compteur vers l horodatage ne change pas ce que ces tests
/// verifient : des RELATIONS D ORDRE entre publications. `v(1) < v(2)` dit
/// exactement ce que `1 < 2` disait, et aucune assertion n est affaiblie.
HorodatageServeur v(int n) => aJPlus(n);

/// Tests du DAO TrailManifests sur une base in-memory.
void main() {
  late AppDatabase db;
  late TrailManifestsDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = TrailManifestsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  /// Helper : cree un companion TrailManifests de test
  TrailManifestsCompanion makeManifest({
    required String trailId,
    int dataVersion = 1,
    String hash = 'test_hash_sha256',
    String filePath = 'trails/test/data.json',
    int fileSize = 1024,
    String status = 'active',
    String lastUpdated = '2026-05-26T12:00:00Z',
    int? localVersion,
  }) {
    return TrailManifestsCompanion(
      trailId: Value(trailId),
      dataVersion: Value(v(dataVersion)),
      hash: Value(hash),
      filePath: Value(filePath),
      fileSize: Value(fileSize),
      status: Value(status),
      lastUpdated: Value(lastUpdated),
      localVersion: Value(localVersion == null ? null : v(localVersion)),
    );
  }

  group('TrailManifestsDao CRUD', () {
    test('insertOrReplace puis getByTrailId retourne le bon manifest', () async {
      await dao.insertOrReplace(makeManifest(trailId: 'sentier-bleu'));

      final result = await dao.getByTrailId('sentier-bleu');
      expect(result, isNotNull);
      expect(result!.trailId, 'sentier-bleu');
      expect(result.dataVersion, v(1));
      expect(result.hash, 'test_hash_sha256');
      expect(result.status, 'active');
    });

    test('getAll retourne tous les manifests', () async {
      await dao.insertOrReplace(makeManifest(trailId: 'sentier-bleu'));
      await dao.insertOrReplace(makeManifest(trailId: 'mare_a_mare'));
      await dao.insertOrReplace(makeManifest(trailId: 'tmb'));

      final result = await dao.getAll();
      expect(result.length, 3);
    });

    test('getByTrailId retourne null si inexistant', () async {
      final result = await dao.getByTrailId('inexistant');
      expect(result, isNull);
    });

    test('insertOrReplace met a jour un manifest existant', () async {
      await dao.insertOrReplace(makeManifest(
        trailId: 'sentier-bleu',
        dataVersion: 1,
        hash: 'old_hash',
      ));
      await dao.insertOrReplace(makeManifest(
        trailId: 'sentier-bleu',
        dataVersion: 2,
        hash: 'new_hash',
      ));

      final result = await dao.getByTrailId('sentier-bleu');
      expect(result!.dataVersion, v(2));
      expect(result.hash, 'new_hash');
    });

    test('deleteByTrailId supprime le bon manifest', () async {
      await dao.insertOrReplace(makeManifest(trailId: 'sentier-bleu'));
      await dao.insertOrReplace(makeManifest(trailId: 'mare'));

      final deleted = await dao.deleteByTrailId('sentier-bleu');
      expect(deleted, 1);

      final remaining = await dao.getAll();
      expect(remaining.length, 1);
      expect(remaining.first.trailId, 'mare');
    });

    test('deleteByTrailId retourne 0 si inexistant', () async {
      final deleted = await dao.deleteByTrailId('fantome');
      expect(deleted, 0);
    });

    test('localVersion nullable fonctionne', () async {
      await dao.insertOrReplace(makeManifest(trailId: 'sentier-bleu'));

      final result = await dao.getByTrailId('sentier-bleu');
      expect(result!.localVersion, isNull);
    });

    test('localVersion se met a jour correctement', () async {
      await dao.insertOrReplace(makeManifest(
        trailId: 'sentier-bleu',
        dataVersion: 3,
        localVersion: 2,
      ));

      final result = await dao.getByTrailId('sentier-bleu');
      expect(result!.localVersion, v(2));
      expect(result.dataVersion, v(3));
    });
  });

  group('TrailManifestsDao needsUpdate', () {
    test('retourne true si le sentier n existe pas en local', () async {
      final needs = await dao.needsUpdate('inexistant');
      expect(needs, isTrue);
    });

    test('retourne true si localVersion est null', () async {
      await dao.insertOrReplace(makeManifest(
        trailId: 'sentier-bleu',
        dataVersion: 3,
        localVersion: null,
      ));

      final needs = await dao.needsUpdate('sentier-bleu');
      expect(needs, isTrue);
    });

    test('retourne true si dataVersion > localVersion', () async {
      await dao.insertOrReplace(makeManifest(
        trailId: 'sentier-bleu',
        dataVersion: 5,
        localVersion: 3,
      ));

      final needs = await dao.needsUpdate('sentier-bleu');
      expect(needs, isTrue);
    });

    test('retourne false si dataVersion == localVersion', () async {
      await dao.insertOrReplace(makeManifest(
        trailId: 'sentier-bleu',
        dataVersion: 3,
        localVersion: 3,
      ));

      final needs = await dao.needsUpdate('sentier-bleu');
      expect(needs, isFalse);
    });

    test('retourne false si dataVersion < localVersion', () async {
      await dao.insertOrReplace(makeManifest(
        trailId: 'sentier-bleu',
        dataVersion: 2,
        localVersion: 3,
      ));

      final needs = await dao.needsUpdate('sentier-bleu');
      expect(needs, isFalse);
    });
  });

  /// LE PERIMETRE : « SES SENTIERS », PAS LE CATALOGUE (tache 610).
  ///
  /// Precision de Christophe du 28/09 : « on telecharge tout ce qui concerne SES
  /// sentiers ». [TrailManifestsDao.getAll] rend une ligne par sentier PUBLIE,
  /// parce que la lecture du catalogue les conserve toutes pour survivre au
  /// hors-ligne. Confondre les deux faisait telecharger les quarante sentiers du
  /// catalogue a un randonneur qui en possede un.
  group('TrailManifestsDao getPossedes', () {
    test('ne rend QUE les sentiers dont une copie a ete posee ici', () async {
      await dao.insertOrReplace(
          makeManifest(trailId: 'copie', localVersion: 3));
      await dao.insertOrReplace(makeManifest(trailId: 'vu-au-catalogue'));
      await dao.insertOrReplace(makeManifest(trailId: 'vu-aussi'));

      expect(await dao.getAll(), hasLength(3),
          reason: 'les trois sont au catalogue, et c est voulu : c est ce qui '
              'fait survivre la liste au hors-ligne');
      expect((await dao.getTelecharges()).map((e) => e.trailId), ['copie']);
    });

    test('un sentier supprime du telephone sort du perimetre', () async {
      await dao.insertOrReplace(
          makeManifest(trailId: 'copie', localVersion: 3));
      await dao.oublierRevision('copie');

      expect(await dao.getTelecharges(), isEmpty,
          reason: 'le repere oublie, il n y a plus de copie a maintenir a jour');
    });

    test('inscrireRevision LEVE quand aucune ligne de liste n existe (#X10)',
        () async {
      // LE FAUX SUCCES QUE CECI FERME. C est un `UPDATE` : sans ligne il rendait
      // 0 EN SILENCE, la copie etait annoncee reussie et le telephone
      // retelechargeait tout a l ouverture suivante. Le mot « complet » de
      // Christophe l interdit.
      await expectLater(
        dao.inscrireRevision('inexistant', v(3),
            niveau: NiveauDeTelechargement.realiser),
        throwsA(isA<RepereNonInscriptible>()),
      );
    });
  });
}
