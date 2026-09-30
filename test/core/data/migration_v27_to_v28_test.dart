import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/revision_de_donnee.dart';

/// Tests de MIGRATION Drift v27 -> v28 (StepWays tache 610).
///
/// CE QUE LA v28 FAIT, ET CE QU ELLE NE FAIT PAS. Elle ne touche AUCUNE
/// structure : zero `ALTER TABLE`, zero table, zero colonne. Les colonnes `rev`,
/// `data_version` et `local_version` posees par la v27 sont deja des `INTEGER` ;
/// on y range desormais des MILLISECONDES DEPUIS L EPOCH au lieu d un compteur. Le
/// type SQL ne bouge pas — et c est ce qui rend cette migration incassable : une
/// migration qui echoue EMPECHE LA BASE DE S OUVRIR sur le telephone d un
/// randonneur, sans recours.
///
/// CE QU ELLE CASSE, ET C EST LE SEUL POINT : LES ANCIENNES VALEURS N ONT PLUS DE
/// SENS. Un `local_version` a 4 lu comme un instant designe le 1er janvier 1970.
/// On ne le laisse pas s interpreter tout seul, on le remet a zero.
///
/// LE SENS DE CE CHOIX, ET IL EST ASYMETRIQUE. Se tromper EN ARRIERE (repere trop
/// ancien) coute UN telechargement : tout est plus recent, tout redescend, le
/// telephone repart juste. Se tromper EN AVANT (repere dans le futur des donnees)
/// coute TOUT : le telephone ne demande plus jamais ce qui porte une date
/// inferieure a son repere, et rien ne le lui dit. La v28 choisit donc l erreur qui
/// se repare d elle-meme.
void main() {
  /// Fabrique une base a l etat v27 : colonnes du schema courant, valeurs de
  /// l ancien modele (des compteurs), `user_version` ramene a 27.
  Future<File> baseEnV27() async {
    final dir = await Directory.systemTemp.createTemp('gr_mig_v28_');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    final file = File('${dir.path}/app.sqlite');

    final seedDb = AppDatabase(NativeDatabase(file));
    await seedDb.customStatement('SELECT 1');

    // Un sentier DEJA COPIE avec l ancien modele : liste a la revision 4, repere
    // local a 4, donc « a jour » au sens du compteur.
    await seedDb.customStatement(
      "INSERT INTO trail_manifests "
      "(trail_id, data_version, hash, file_path, file_size, status, "
      "last_updated, local_version) "
      "VALUES ('mare-a-mare-centre', 4, 'h4', 'mam/v4.json', 812345, "
      "'active', '2026-09-27T12:00:00Z', 4)",
    );
    await seedDb.customStatement(
      "INSERT INTO trail_meta (id, code, data_version, status, rev) "
      "VALUES ('mare-a-mare-centre', 'mam-centre', 4, 'active', 4)",
    );
    await seedDb.customStatement(
      "INSERT INTO trail_stages "
      "(id, itinerary_id, stage_number, name_fr, name_en, name_de, name_it, "
      "name_es, start_lat, start_lng, end_lat, end_lng, distance_km, "
      "elevation_gain, elevation_loss, duration_minutes, difficulty, rev) "
      "VALUES ('mam-s1', 'mam-i1', 1, 'Etape 1', 'Stage 1', 'Etappe 1', "
      "'Tappa 1', 'Etapa 1', 42.0, 9.0, 42.1, 9.1, 12.5, 800, 400, 300, "
      "'moyen', 2)",
    );

    await seedDb.customStatement('PRAGMA user_version = 27');
    await seedDb.close();
    return file;
  }

  group('Drift migration v27 -> v28 (le compteur devient un instant)', () {
    test('la version du schema est au moins 28', () {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      expect(db.schemaVersion, greaterThanOrEqualTo(28));
    });

    test(
      'AUCUN ALTER TABLE : les colonnes de revision restent des INTEGER',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        Future<String?> typeDe(String table, String colonne) async {
          final rows = await db.customSelect('PRAGMA table_info($table)').get();
          for (final r in rows) {
            if (r.read<String>('name') == colonne) {
              return r.read<String>('type');
            }
          }
          return null;
        }

        // C EST CE FAIT QUI REND LA MIGRATION INCASSABLE. Si le type SQL avait
        // change (TEXT pour de l ISO 8601, par exemple), il aurait fallu
        // reconstruire sept tables sur le telephone du randonneur.
        expect(await typeDe('trail_manifests', 'data_version'), 'INTEGER');
        expect(await typeDe('trail_manifests', 'local_version'), 'INTEGER');
        for (final table in const [
          'trail_meta',
          'trail_itineraries',
          'trail_stages',
          'trail_accommodations',
          'trail_pois',
          'trail_gpx_tracks',
          'trail_gpx_points',
        ]) {
          expect(
            await typeDe(table, 'rev'),
            'INTEGER',
            reason:
                '$table garde sa colonne INTEGER : on y range des '
                'millisecondes depuis l epoch',
          );
        }
      },
    );

    test(
      'le repere herite du compteur est REMIS A ZERO, pas relu comme une date',
      () async {
        final file = await baseEnV27();
        final db = AppDatabase(NativeDatabase(file));
        addTearDown(db.close);

        final manifeste = await db.trailManifestsDao.getByTrailId(
          'mare-a-mare-centre',
        );
        expect(manifeste, isNotNull);
        expect(
          manifeste!.localVersion,
          isNull,
          reason:
              'un « 4 » relu comme un instant designerait le 1er janvier '
              '1970 : on ne le laisse pas s interpreter, on le remet a zero',
        );
        expect(
          manifeste.dataVersion,
          HorodatageServeur.origine,
          reason:
              'l instant de publication sera reecrit par la prochaine '
              'lecture du catalogue, avec la valeur que le SERVEUR annonce',
        );

        // Les revisions d enregistrement aussi : aucun compteur ne doit pouvoir se
        // faire passer pour une date, meme dans une colonne que personne ne lit
        // aujourd hui pour decider.
        final etapes = await db.trailStagesDao.getByItineraryId('mam-i1');
        expect(etapes, hasLength(1));
        expect(etapes.single.rev, isNull);
        final fiche = await db.trailMetaDao.getById('mare-a-mare-centre');
        expect(fiche, isNotNull);
        expect(fiche!.rev, isNull);
        expect(fiche.dataVersion, HorodatageServeur.origine);
      },
    );

    test(
      'AUCUNE DONNEE DE SENTIER PERDUE : seules les revisions sont remises a '
      'zero',
      () async {
        final file = await baseEnV27();
        final db = AppDatabase(NativeDatabase(file));
        addTearDown(db.close);

        final etapes = await db.trailStagesDao.getByItineraryId('mam-i1');
        expect(etapes, hasLength(1));
        expect(etapes.single.nameFr, 'Etape 1');
        expect(etapes.single.nameEs, 'Etapa 1');
        expect(etapes.single.elevationGain, 800);
        expect(etapes.single.distanceKm, 12.5);

        final manifeste = await db.trailManifestsDao.getByTrailId(
          'mare-a-mare-centre',
        );
        expect(manifeste!.hash, 'h4');
        expect(manifeste.filePath, 'mam/v4.json');
        expect(manifeste.fileSize, 812345);
        expect(manifeste.status, 'active');
      },
    );

    test('APRES LA MIGRATION, LE SENTIER EST A REPRENDRE — et c est voulu', () async {
      final file = await baseEnV27();
      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);

      // `needsUpdate` rend vrai parce que le repere est nul : le sentier sera
      // recopie UNE fois, par le chemin normal et transactionnel, et le telephone
      // repartira avec un repere que le serveur aura annonce.
      expect(
        await db.trailManifestsDao.needsUpdate('mare-a-mare-centre'),
        isTrue,
      );

      // ET IL N EST PLUS COMPTE COMME POSSEDE PAR LA MISE A JOUR PERIODIQUE, tant
      // qu il n a pas ete recopie. C est coherent : son contenu local n est plus
      // certifie par aucun repere.
      expect(await db.trailManifestsDao.getTelecharges(), isEmpty);
    });

    test('la migration est REJOUABLE : la relancer ne casse rien', () async {
      final file = await baseEnV27();

      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);
      await db.customSelect('SELECT 1').get();
      await db.close();

      // On rembobine et on rouvre : c est ce que font les tests de migration du
      // depot, et c est aussi ce qui arrive quand une migration est interrompue.
      // Un `UPDATE` idempotent supporte ce traitement, la ou un `ALTER TABLE`
      // echouerait — la fragilite que la v27 avait fait sortir n est pas reveillee.
      final rembobinee = AppDatabase(NativeDatabase(file));
      await rembobinee.customStatement('PRAGMA user_version = 27');
      await rembobinee.close();

      final rouverte = AppDatabase(NativeDatabase(file));
      addTearDown(rouverte.close);
      await expectLater(rouverte.customSelect('SELECT 1').get(), completes);
      final manifeste = await rouverte.trailManifestsDao.getByTrailId(
        'mare-a-mare-centre',
      );
      expect(manifeste!.localVersion, isNull);
    });
  });
}
