import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/models/niveau_de_telechargement.dart';

/// Tests de MIGRATION Drift v29 -> v30 (StepWays tache 622).
///
/// CE QUE LA v30 FAIT : elle ajoute TROIS colonnes a `trail_manifests` —
/// `tiles_path`, `tiles_size`, `tiles_hash` — qui disent OU est la carte hors ligne
/// d un sentier, CE QU ELLE PESE et QUELLE EMPREINTE elle doit avoir.
///
/// POURQUOI CES TROIS COLONNES EXISTENT. Le code qui descend un `.mbtiles` existait
/// depuis des mois et n avait AUCUN appelant de production ; mais meme branche, il
/// n aurait rien eu a descendre : la liste distante ne portait ni adresse, ni taille,
/// ni empreinte de tuiles. Un randonneur qui preparait son sentier puis montait sans
/// reseau n avait donc pas de fond de carte, quoi qu il fasse.
///
/// POURQUOI LE GESTE LIT LA BASE ET PAS LE RESEAU. « Telecharger » lit la LIGNE
/// LOCALE (`CatalogNotifier.downloadTrail` -> `getByTrailId`) : c est ce qui lui
/// permet de partir d un catalogue affiche depuis le dernier distant recu. Sans ces
/// colonnes, la descente des cartes exigerait une SECONDE lecture du manifeste au
/// moment du geste — donc un second chemin de resolution de l adresse, avec sa propre
/// facon d echouer.
///
/// POURQUOI ELLES PASSENT PAR `_ajouterColonneSiAbsente`. Regle du depot depuis la
/// tache 613, et elle a une raison mesuree : la base vit dans un FICHIER, donc ces
/// marches s executent VRAIMENT sur le telephone d un randonneur. `ALTER TABLE ADD
/// COLUMN` echoue sur une colonne deja presente, et UNE MIGRATION QUI ECHOUE EMPECHE
/// LA BASE DE S OUVRIR — l application ne demarre plus, sans recours.
void main() {
  /// Fabrique une base a l etat v29 : schema courant, `user_version` ramene a 29,
  /// et un sentier DEJA COPIE au niveau « realiser » mais SANS aucune carte declaree.
  ///
  /// C est l etat exact d un telephone d avant ce lot : il croyait avoir « tout »
  /// telecharge, et il n avait pas de fond de carte.
  Future<File> baseEnV29() async {
    final dir = await Directory.systemTemp.createTemp('gr_mig_v30_');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    final file = File('${dir.path}/app.sqlite');

    final seedDb = AppDatabase(NativeDatabase(file));
    await seedDb.customStatement('SELECT 1');

    await seedDb.customStatement(
      "INSERT INTO trail_manifests "
      "(trail_id, data_version, hash, file_path, file_size, status, "
      "last_updated, local_version, niveau_local) "
      "VALUES ('gr-monts-dore', 1759017600000, 'h1', 'montsdore/v1.json', "
      "4096, 'active', '2026-09-28T00:00:00Z', 1759017600000, 'realiser')",
    );
    // Les trois colonnes de tuiles sont mises a NULL explicitement : c est l etat
    // d avant la v30.
    await seedDb.customStatement(
      'UPDATE trail_manifests SET tiles_path = NULL, tiles_size = NULL, '
      'tiles_hash = NULL',
    );

    await seedDb.customStatement('PRAGMA user_version = 29');
    await seedDb.close();
    return file;
  }

  group('Drift migration v29 -> v30 (la liste declare ses cartes hors ligne)', () {
    test('la version du schema est au moins 30', () {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      expect(db.schemaVersion, greaterThanOrEqualTo(30));
    });

    test('les trois colonnes existent, avec le bon type, et toutes nullables',
        () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final rows =
          await db.customSelect('PRAGMA table_info(trail_manifests)').get();
      Map<String, dynamic> colonne(String nom) {
        final trouvees =
            rows.where((r) => r.read<String>('name') == nom).toList();
        expect(trouvees, hasLength(1), reason: 'colonne $nom absente');
        return {
          'type': trouvees.single.read<String>('type'),
          'notnull': trouvees.single.read<int>('notnull'),
        };
      }

      expect(colonne('tiles_path')['type'], 'TEXT');
      expect(colonne('tiles_path')['notnull'], 0,
          reason: 'null = aucune carte publiee, et c est un cas NORMAL');
      expect(colonne('tiles_size')['type'], 'INTEGER');
      expect(colonne('tiles_size')['notnull'], 0);
      expect(colonne('tiles_hash')['type'], 'TEXT');
      expect(colonne('tiles_hash')['notnull'], 0,
          reason: 'sans empreinte, une carte de 260 Mo ne serait pas verifiable');
    });

    test('UNE BASE MONTEE DEPUIS LA v29 S OUVRE, et son sentier ne pretend PAS '
        'avoir une carte', () async {
      final file = await baseEnV29();
      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);

      final manifeste = await db.trailManifestsDao.getByTrailId('gr-monts-dore');
      expect(manifeste, isNotNull);
      expect(manifeste!.tilesPath, isNull);
      expect(manifeste.tilesSize, isNull);
      expect(manifeste.tilesHash, isNull);

      // ET SON NIVEAU N EST PAS TOUCHE : il reste « realiser ». Les colonnes de
      // tuiles disent ce que le SERVEUR publie, pas ce que le telephone a fait —
      // deux faits differents, deux sources differentes. La prochaine lecture du
      // catalogue apportera l adresse de la carte ; d ici la, la descente est
      // refusee avec la cause « aucune carte publiee », jamais tentee a l aveugle.
      expect(await db.trailManifestsDao.niveauDe('gr-monts-dore'),
          NiveauDeTelechargement.realiser);
    });

    test('AUCUNE DONNEE PERDUE : la ligne de liste traverse la marche intacte',
        () async {
      final file = await baseEnV29();
      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);

      final manifeste = await db.trailManifestsDao.getByTrailId('gr-monts-dore');
      expect(manifeste!.hash, 'h1');
      expect(manifeste.filePath, 'montsdore/v1.json');
      expect(manifeste.fileSize, 4096);
      expect(manifeste.status, 'active');
      expect(manifeste.lastUpdated, '2026-09-28T00:00:00Z');
      expect(manifeste.localVersion, isNotNull,
          reason: 'la v30 ne touche PAS au repere : elle ajoute trois colonnes');
    });

    test('LE SENTIER RESTE DANS LE PERIMETRE DE LA CADENCE', () async {
      final file = await baseEnV29();
      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);

      final telecharges = await db.trailManifestsDao.getTelecharges();
      expect(telecharges.map((e) => e.trailId), ['gr-monts-dore'],
          reason: 'ajouter trois colonnes ne doit pas faire sortir un sentier '
              'deja copie du perimetre de la mise a jour periodique');
    });

    test('la migration est REJOUABLE : la relancer ne casse rien', () async {
      final file = await baseEnV29();

      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);
      await db.customSelect('SELECT 1').get();
      await db.close();

      // On rembobine et on rouvre : c est ce qui arrive quand l application est tuee
      // au milieu d une marche. Un `ALTER TABLE ADD COLUMN` nu echouerait sur
      // « duplicate column name » et la base ne s ouvrirait plus du tout.
      final rembobinee = AppDatabase(NativeDatabase(file));
      await rembobinee.customStatement('PRAGMA user_version = 29');
      await rembobinee.close();

      final rouverte = AppDatabase(NativeDatabase(file));
      addTearDown(rouverte.close);
      await expectLater(rouverte.customSelect('SELECT 1').get(), completes);
      expect(
        await rouverte.trailManifestsDao.getByTrailId('gr-monts-dore'),
        isNotNull,
      );
    });

    test('LE DESCRIPTEUR DE CARTE SE RELIT TEL QU IL A ETE ECRIT', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await db.customStatement(
        "INSERT INTO trail_manifests "
        "(trail_id, data_version, hash, file_path, file_size, status, "
        "last_updated, tiles_path, tiles_size, tiles_hash) "
        "VALUES ('mare-a-mare', 1759017600000, 'h2', 'mam/v1.json', 2048, "
        "'active', '2026-09-28T00:00:00Z', 'mam/tuiles_v1.mbtiles', 260000000, "
        "'abc123')",
      );

      final ligne = await db.trailManifestsDao.getByTrailId('mare-a-mare');
      expect(ligne!.tilesPath, 'mam/tuiles_v1.mbtiles');
      expect(ligne.tilesSize, 260000000,
          reason: '260 Mo : le poids mesure par le chiffrage de la tache 608');
      expect(ligne.tilesHash, 'abc123');
    });
  });
}
