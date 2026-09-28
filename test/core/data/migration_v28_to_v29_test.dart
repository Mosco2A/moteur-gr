import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/models/niveau_de_telechargement.dart';

/// Tests de MIGRATION Drift v28 -> v29 (StepWays tache 616).
///
/// CE QUE LA v29 FAIT : elle ajoute UNE colonne, `trail_manifests.niveau_local`,
/// qui note JUSQU OU un sentier est descendu sur ce telephone (regarder, preparer,
/// realiser).
///
/// POURQUOI CETTE COLONNE N EST PAS UN CONFORT — C EST LE PIEGE QUE LES NIVEAUX
/// OUVRENT. Le repere de synchronisation est UN SEUL instant pour tout le sentier,
/// et la regle de pose est « je prends ce qui est plus recent que mon repere ». Un
/// telephone copie au niveau « preparer » jusqu a l instant T, qui demanderait
/// ensuite « realiser », verrait ses points de trace REFUSES un a un : ils portent
/// une date anterieure a T, donc la regle les declare deja a jour. Le randonneur
/// partirait sans trace en croyant avoir tout telecharge, et aucune mise a jour
/// ulterieure n irait jamais la chercher. Sans cette colonne, le defaut est
/// silencieux ET definitif.
///
/// POURQUOI ELLE PASSE PAR `_ajouterColonneSiAbsente`, ET CE N EST PAS COSMETIQUE.
/// C est la regle posee par la tache 613, et elle a une raison mesuree : la base
/// vit desormais dans un FICHIER, donc ces marches vont VRAIMENT s executer sur le
/// telephone d un randonneur. `ALTER TABLE ADD COLUMN` echoue sur une colonne deja
/// presente, et UNE MIGRATION QUI ECHOUE EMPECHE LA BASE DE S OUVRIR —
/// l application ne demarre plus, sans recours. Le cas n est pas theorique : si
/// l application est tuee au milieu d une marche, `user_version` reste en arriere et
/// la marche se rejoue sur une colonne deja posee.
void main() {
  /// Fabrique une base a l etat v28 : schema courant, `user_version` ramene a 28.
  ///
  /// Le sentier y est DEJA COPIE (repere non nul) mais SANS niveau — c est
  /// exactement l etat qu une base montee depuis la v28 presenterait.
  Future<File> baseEnV28() async {
    final dir = await Directory.systemTemp.createTemp('gr_mig_v29_');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    final file = File('${dir.path}/app.sqlite');

    final seedDb = AppDatabase(NativeDatabase(file));
    await seedDb.customStatement('SELECT 1');

    await seedDb.customStatement(
      "INSERT INTO trail_manifests "
      "(trail_id, data_version, hash, file_path, file_size, status, "
      "last_updated, local_version) "
      "VALUES ('gr-monts-dore', 1759017600000, 'h1', 'montsdore/v1.json', "
      "4096, 'active', '2026-09-28T00:00:00Z', 1759017600000)",
    );
    // Le niveau est mis a NULL explicitement : c est l etat d avant la v29.
    await seedDb
        .customStatement('UPDATE trail_manifests SET niveau_local = NULL');

    await seedDb.customStatement('PRAGMA user_version = 28');
    await seedDb.close();
    return file;
  }

  group('Drift migration v28 -> v29 (le niveau descendu se note en base)', () {
    test('la version du schema est au moins 29', () {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      expect(db.schemaVersion, greaterThanOrEqualTo(29));
    });

    test('la colonne `niveau_local` existe, en TEXT et nullable', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final rows =
          await db.customSelect('PRAGMA table_info(trail_manifests)').get();
      final colonne = rows
          .where((r) => r.read<String>('name') == 'niveau_local')
          .toList();

      expect(colonne, hasLength(1),
          reason: 'sans cette colonne, monter de niveau est un echec silencieux');
      expect(colonne.single.read<String>('type'), 'TEXT',
          reason: 'on y range le CODE STABLE du niveau, pas son index : un '
              'renommage de constante Dart ne doit pas rendre illisibles les '
              'reperes deja poses sur les telephones');
      expect(colonne.single.read<int>('notnull'), 0,
          reason: 'null = jamais telecharge, comme `local_version`');
    });

    test('UNE BASE MONTEE DEPUIS LA v28 S OUVRE, et son sentier sans niveau est '
        'traite comme « regarder » — le repli le plus BAS', () async {
      final file = await baseEnV28();
      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);

      final manifeste = await db.trailManifestsDao.getByTrailId('gr-monts-dore');
      expect(manifeste, isNotNull);
      expect(manifeste!.niveauLocal, isNull);
      expect(manifeste.localVersion, isNotNull,
          reason: 'la v29 ne touche PAS au repere : elle ajoute une colonne');

      // LE REPLI EST ASYMETRIQUE, ET C EST LE MEME RAISONNEMENT QUE LA v28. Ne pas
      // savoir jusqu ou un sentier est descendu doit faire RECOPIER (cout : un
      // telechargement, une fois), jamais faire croire complet (cout : une trace
      // absente que rien ne signale et que rien ne va plus chercher).
      expect(await db.trailManifestsDao.niveauDe('gr-monts-dore'),
          NiveauDeTelechargement.regarder);
    });

    test('AUCUNE DONNEE PERDUE : la ligne de liste traverse la marche intacte',
        () async {
      final file = await baseEnV28();
      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);

      final manifeste = await db.trailManifestsDao.getByTrailId('gr-monts-dore');
      expect(manifeste!.hash, 'h1');
      expect(manifeste.filePath, 'montsdore/v1.json');
      expect(manifeste.fileSize, 4096);
      expect(manifeste.status, 'active');
      expect(manifeste.lastUpdated, '2026-09-28T00:00:00Z');
    });

    test('LE SENTIER RESTE DANS LE PERIMETRE DE LA CADENCE : son repere est '
        'toujours la', () async {
      final file = await baseEnV28();
      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);

      final telecharges = await db.trailManifestsDao.getTelecharges();
      expect(telecharges.map((e) => e.trailId), ['gr-monts-dore'],
          reason: 'ajouter une colonne ne doit pas faire sortir un sentier deja '
              'copie du perimetre de la mise a jour periodique');
    });

    test('la migration est REJOUABLE : la relancer ne casse rien', () async {
      final file = await baseEnV28();

      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);
      await db.customSelect('SELECT 1').get();
      await db.close();

      // On rembobine et on rouvre : c est ce que font les tests de migration du
      // depot, et c est aussi ce qui arrive quand l application est tuee au milieu
      // d une marche. `_ajouterColonneSiAbsente` supporte ce traitement ; un
      // `ALTER TABLE ADD COLUMN` nu echouerait sur « duplicate column name » et la
      // base ne s ouvrirait plus du tout.
      final rembobinee = AppDatabase(NativeDatabase(file));
      await rembobinee.customStatement('PRAGMA user_version = 28');
      await rembobinee.close();

      final rouverte = AppDatabase(NativeDatabase(file));
      addTearDown(rouverte.close);
      await expectLater(rouverte.customSelect('SELECT 1').get(), completes);
      expect(
        await rouverte.trailManifestsDao.getByTrailId('gr-monts-dore'),
        isNotNull,
      );
    });

    test('LE NIVEAU SE RELIT TEL QU IL A ETE ECRIT, pour les trois valeurs',
        () async {
      final file = await baseEnV28();
      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);

      for (final niveau in NiveauDeTelechargement.values) {
        await db.trailManifestsDao.inscrireRevision(
          'gr-monts-dore',
          (await db.trailManifestsDao.getByTrailId('gr-monts-dore'))!
              .localVersion!,
          niveau: niveau,
        );
        expect(await db.trailManifestsDao.niveauDe('gr-monts-dore'), niveau);
      }
    });
  });
}
