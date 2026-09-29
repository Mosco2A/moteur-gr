import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart';

/// Tests de MIGRATION Drift v29 -> v30 (StepWays tache 625).
///
/// CE QUE LA v30 FAIT : elle cree UNE table, `trail_meteo`, huitieme famille de
/// donnees de sentier. Decision de Christophe du 28/09, verbatim : « Ce n est pas
/// l appli qui demande la meteo mais notre serveur, les infos meteo sont mises sur
/// firebase et quand l appli voit qu il y a des donnees a jour elle les met a jour,
/// comme pour le reste. »
///
/// POURQUOI UNE CREATION DE TABLE ET NON UN ELARGISSEMENT DU CACHE EXISTANT. La
/// table `weather_cache` portait un `expires_at` : elle decidait QUAND RAPPELER LE
/// FOURNISSEUR. Il n y a plus de fournisseur a rappeler cote telephone, donc plus
/// rien a faire expirer. Y ranger la meteo du serveur aurait garde la colonne qui
/// gouvernait le DROIT D AFFICHER — le defaut que la tache 572 avait deja eu a
/// corriger une fois — et aurait melange deux natures de donnees dans une table dont
/// le nom dit « cache ».
///
/// CE QU ELLE NE FAIT PAS, ET C EST DELIBERE : elle ne transporte AUCUNE donnee de
/// l ancien cache. Les lignes de `weather_cache` portent des previsions relevees par
/// le telephone, SANS date de fabrication. Les reprendre reviendrait a inventer la
/// seule date que ce lot existe pour dire avec honnetete. Le randonneur recoit son
/// premier bulletin serveur a la premiere passe de l ordonnanceur, et l ecran dit
/// clairement qu il attend en attendant.
void main() {
  /// Fabrique une base a l etat v29 : schema courant, `user_version` ramene a 29,
  /// et la table `trail_meteo` RETIREE — c est exactement ce qu une base montee
  /// depuis la v29 presente.
  Future<File> baseEnV29() async {
    final dir = await Directory.systemTemp.createTemp('gr_mig_v30_');
    addTearDown(() async {
      if (await dir.exists()) {
        try {
          await dir.delete(recursive: true);
        } on FileSystemException {
          // Sous Windows le fichier peut rester tenu par le moteur SQLite le
          // temps d un tour de boucle. Ce n est pas l objet du test.
        }
      }
    });
    final file = File('${dir.path}/app.sqlite');

    final seedDb = AppDatabase(NativeDatabase(file));
    await seedDb.customStatement('SELECT 1');

    // Un sentier DEJA copie : la marche ne doit rien lui faire perdre.
    await seedDb.customStatement(
      "INSERT INTO trail_manifests "
      "(trail_id, data_version, hash, file_path, file_size, status, "
      "last_updated, local_version, niveau_local) "
      "VALUES ('gr-monts-dore', 1759017600000, 'h1', 'montsdore/v1.json', "
      "4096, 'active', '2026-09-28T00:00:00Z', 1759017600000, 'preparer')",
    );

    await seedDb.customStatement('DROP TABLE trail_meteo');
    await seedDb.customStatement('PRAGMA user_version = 29');
    await seedDb.close();
    return file;
  }

  group('Drift migration v29 -> v30 (la meteo devient une donnee de sentier)', () {
    test('la version du schema est au moins 30', () {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      expect(db.schemaVersion, greaterThanOrEqualTo(30));
    });

    test('UNE BASE MONTEE DEPUIS LA v29 S OUVRE, et la table meteo y est',
        () async {
      final file = await baseEnV29();
      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);

      // Si la marche leve, cette ligne echoue et la base reste fermee — ce qui,
      // sur le telephone d un randonneur, veut dire une application qui ne
      // demarre plus, sans recours.
      await db.customStatement('SELECT 1');

      final tables = (await db
              .customSelect("SELECT name FROM sqlite_master WHERE type='table'")
              .get())
          .map((r) => r.read<String>('name'))
          .toSet();

      expect(tables, contains('trail_meteo'));
    });

    test('la table porte la DATE DE FABRICATION, et elle est OBLIGATOIRE',
        () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final colonnes =
          await db.customSelect('PRAGMA table_info(trail_meteo)').get();
      final parNom = {
        for (final c in colonnes) c.read<String>('name'): c,
      };

      expect(parNom.keys, contains('produite_le'));
      expect(parNom['produite_le']!.read<int>('notnull'), 1,
          reason: 'UN BULLETIN SANS DATE DE FABRICATION NE PEUT PAS AFFICHER SON '
              'AGE. Sans age, une prevision de trois jours est indistinguable '
              'd une prevision d une heure — et c est exactement le mensonge '
              'dangereux que ce lot ferme. La colonne est donc NON NULLE, et la '
              'pose refuse l enregistrement qui n en porte pas.');
      expect(parNom['produite_le']!.read<String>('type'), 'INTEGER',
          reason: 'millisecondes depuis l epoch, comme toutes les colonnes '
              'd horodatage du modele (tache 610) : la comparaison est STRICTE et '
              'la seconde entiere serait trop grossiere.');

      // Le reperage d un bulletin par l ecran.
      expect(parNom.keys, containsAll(['trail_id', 'stage_id', 'stage_number']));
      // Le fournisseur NOMME dans la donnee (#A3) : un basculement se voit.
      expect(parNom.keys, contains('source'));
      // L horodatage de synchronisation, comme sur les sept autres familles.
      expect(parNom.keys, contains('rev'));
    });

    test('AUCUNE DONNEE PERDUE : la ligne de liste traverse la marche intacte',
        () async {
      final file = await baseEnV29();
      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);

      final manifeste = await db.trailManifestsDao.getByTrailId('gr-monts-dore');
      expect(manifeste, isNotNull);
      expect(manifeste!.localVersion, isNotNull,
          reason: 'la v30 cree une table : elle ne touche a aucun repere');
      expect(manifeste.niveauLocal, 'preparer');
    });

    test('LA TABLE ARRIVE VIDE, et c est la bonne reponse', () async {
      final file = await baseEnV29();
      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);

      final lignes = await db.select(db.trailMeteo).get();
      expect(lignes, isEmpty,
          reason: 'Rien n est repris de l ancien cache : ses previsions n ont pas '
              'de date de FABRICATION, et leur en inventer une serait la faute '
              'que ce lot corrige.');
    });

    test('la migration est REJOUABLE : la relancer ne casse rien', () async {
      final file = await baseEnV29();

      final premier = AppDatabase(NativeDatabase(file));
      await premier.customStatement('SELECT 1');
      await premier.close();

      // L etat qu une application tuee entre la marche et l ecriture du compteur
      // laisse derriere elle : la table est DEJA la, et la marche va se rejouer.
      final saboteur = AppDatabase(NativeDatabase(file));
      await saboteur.customStatement('PRAGMA user_version = 29');
      await saboteur.close();

      final second = AppDatabase(NativeDatabase(file));
      addTearDown(second.close);

      // `createTable` sur une table existante leve : la marche doit donc etre
      // ecrite pour le supporter, sinon l application d un randonneur tue au
      // mauvais moment ne redemarre plus.
      await expectLater(second.customStatement('SELECT 1'), completes);
    });
  });
}
