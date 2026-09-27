import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart';

/// Tests de MIGRATION Drift v26 -> v27 (StepWays tache 605, MUR N1).
///
/// CE QUE LA v27 FAIT, ET CE QU ELLE NE CASSE PAS. Huit colonnes NULLABLES
/// ajoutees, zero table creee, zero colonne supprimee, zero donnee reinterpretee :
///
///  * `trail_manifests.ficheJson` — le dernier catalogue distant RECU, pour que le
///    randonneur hors ligne garde les sentiers que son binaire ne connait pas.
///  * `rev` sur les SEPT tables telechargeables — la revision portee par chaque
///    enregistrement (decision de Christophe du 27/09 20:43).
///
/// POURQUOI L ADDITIF SEUL A ETE RETENU. La premiere conception de ce lot creait
/// une table de versions par famille de donnees et DEPLACAIT `localVersion` — donc
/// supprimait une colonne et reinterpretait les lignes existantes (une version par
/// sentier ne se decoupe pas en sept sans inventer six valeurs). La simplification
/// de Christophe a rendu tout cela inutile : `localVersion` garde sa forme et
/// devient le REPERE DE REVISION du sentier. Rien a defaire, rien a reecrire.
///
/// Methode : la migration ne s execute que si une base persistee est ouverte a une
/// version inferieure au schema courant. On fabrique donc les tables dans leur
/// forme v26 (sans les colonnes neuves), on y insere des donnees, on ramene
/// `user_version` a 26, puis on rouvre.
void main() {
  group('Drift migration v26 -> v27 (catalogue distant + revision)', () {
    test('la version du schema est au moins 27', () {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      expect(db.schemaVersion, greaterThanOrEqualTo(27));
    });

    test('migration reelle 26 -> 27 : 8 colonnes ajoutees, AUCUNE donnee perdue',
        () async {
      final dir = await Directory.systemTemp.createTemp('gr_mig_v27_');
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });
      final file = File('${dir.path}/app.sqlite');

      final seedDb = AppDatabase(NativeDatabase(file));
      await seedDb.customStatement('SELECT 1');

      // --- Les tables dans leur forme v26 : SANS ficheJson, SANS rev ---
      await seedDb.customStatement('DROP TABLE IF EXISTS trail_manifests');
      await seedDb.customStatement(
        'CREATE TABLE trail_manifests ('
        'trail_id TEXT NOT NULL PRIMARY KEY, '
        'data_version INTEGER NOT NULL, '
        'hash TEXT NOT NULL, '
        'file_path TEXT NOT NULL, '
        'file_size INTEGER NOT NULL, '
        'status TEXT NOT NULL, '
        'last_updated TEXT NOT NULL, '
        'local_version INTEGER)',
      );
      await seedDb.customStatement('DROP TABLE IF EXISTS trail_stages');
      await seedDb.customStatement(
        'CREATE TABLE trail_stages ('
        'id TEXT NOT NULL PRIMARY KEY, '
        'itinerary_id TEXT NOT NULL, '
        'stage_number INTEGER NOT NULL, '
        'name_fr TEXT NOT NULL, name_en TEXT NOT NULL, name_de TEXT NOT NULL, '
        'name_it TEXT NOT NULL, name_es TEXT NOT NULL, '
        'start_lat REAL NOT NULL, start_lng REAL NOT NULL, '
        'end_lat REAL NOT NULL, end_lng REAL NOT NULL, '
        'distance_km REAL NOT NULL, elevation_gain INTEGER NOT NULL, '
        'elevation_loss INTEGER NOT NULL, duration_minutes INTEGER NOT NULL, '
        'difficulty TEXT NOT NULL)',
      );

      // Un sentier DEJA COPIE avant la migration : sa revision locale doit
      // survivre, sinon le randonneur retelechargerait tout apres mise a jour de
      // l application.
      await seedDb.customStatement(
        "INSERT INTO trail_manifests "
        "(trail_id, data_version, hash, file_path, file_size, status, "
        "last_updated, local_version) "
        "VALUES ('mare-a-mare-centre', 4, 'h4', 'mam/v4.json', 812345, "
        "'active', '2026-09-27T12:00:00Z', 4)",
      );
      await seedDb.customStatement(
        "INSERT INTO trail_stages "
        "(id, itinerary_id, stage_number, name_fr, name_en, name_de, name_it, "
        "name_es, start_lat, start_lng, end_lat, end_lng, distance_km, "
        "elevation_gain, elevation_loss, duration_minutes, difficulty) "
        "VALUES ('mam-s1', 'mam-i1', 1, 'Etape 1', 'Stage 1', 'Etappe 1', "
        "'Tappa 1', 'Etapa 1', 42.0, 9.0, 42.1, 9.1, 12.5, 800, 400, 300, "
        "'moyen')",
      );

      await seedDb.customStatement('PRAGMA user_version = 26');
      await seedDb.close();

      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);

      // --- Les colonnes sont la ---
      Future<Set<String>> colonnesDe(String table) async {
        final rows = await db.customSelect('PRAGMA table_info($table)').get();
        return rows.map((r) => r.read<String>('name')).toSet();
      }

      expect(await colonnesDe('trail_manifests'), contains('fiche_json'),
          reason: 'sans elle, le dernier catalogue distant recu ne survit pas au '
              'hors-ligne');
      for (final table in const [
        'trail_meta',
        'trail_itineraries',
        'trail_stages',
        'trail_accommodations',
        'trail_pois',
        'trail_gpx_tracks',
        'trail_gpx_points',
      ]) {
        expect(await colonnesDe(table), contains('rev'),
            reason: '$table doit porter la revision de chaque enregistrement');
      }

      // --- AUCUNE PERTE, et la revision locale est intacte ---
      final manifeste =
          await db.trailManifestsDao.getByTrailId('mare-a-mare-centre');
      expect(manifeste, isNotNull);
      expect(manifeste!.localVersion, 4,
          reason: 'LE POINT LE PLUS IMPORTANT DE CETTE MIGRATION : un sentier '
              'deja copie garde son repere de revision. `localVersion` change de '
              'METIER (il devient « je suis a jour jusqu a 4 ») sans changer de '
              'forme ni de valeur — c est pour cela qu aucune reinterpretation '
              'n etait necessaire.');
      expect(manifeste.ficheJson, isNull,
          reason: 'la fiche n a jamais ete recue : la colonne est nullable '
              'precisement pour que les lignes d avant restent lisibles');

      final etapes = await db.trailStagesDao.getByItineraryId('mam-i1');
      expect(etapes, hasLength(1));
      expect(etapes.single.nameFr, 'Etape 1');
      expect(etapes.single.elevationGain, 800);
      expect(etapes.single.rev, isNull,
          reason: 'une donnee d avant le modele n a pas de revision propre : '
              'elle sera rattachee a la revision du sentier a la prochaine '
              'synchronisation (cf. RevisionDeDonnee.revisionDe)');
    });

    test('la migration est REJOUABLE : la relancer sur une base deja migree ne '
        'la casse pas', () async {
      // Une migration qui echoue EMPECHE LA BASE DE S OUVRIR : l application ne
      // demarre plus, sur le telephone d un randonneur, sans recours. Deux
      // situations reelles y menent — une migration interrompue (user_version
      // encore a 26 alors que des colonnes sont posees) et une base au schema
      // courant rembobinee (ce que font les tests de migration du depot).
      final dir = await Directory.systemTemp.createTemp('gr_mig_v27_rejouee_');
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });
      final file = File('${dir.path}/app.sqlite');

      // Base creee au schema COURANT : elle porte deja les huit colonnes.
      final seedDb = AppDatabase(NativeDatabase(file));
      await seedDb.customStatement('SELECT 1');
      await seedDb.customStatement('PRAGMA user_version = 26');
      await seedDb.close();

      // Reouverture : la v27 se rejoue sur des colonnes existantes.
      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);
      await expectLater(db.customSelect('SELECT 1').get(), completes);
      expect(await db.trailManifestsDao.getAll(), isEmpty);
    });
  });
}
