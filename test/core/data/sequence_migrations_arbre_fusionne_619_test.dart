import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart';

/// VERIFICATION D INTEGRATION — LA SEQUENCE COMPLETE DE MIGRATION S EXECUTE SUR
/// L ARBRE FUSIONNE (StepWays tache 619).
///
/// POURQUOI CE FICHIER EXISTE, ET CE QU IL COUVRE QUE LES AUTRES NE COUVRENT PAS.
/// Les fichiers `migration_vNN_to_vMM_test.dart` verifient CHAQUE MARCHE
/// SEPAREMENT, chacun depuis une base fabriquee a l etat de la marche precedente.
/// Aucun ne verifie L ESCALIER ENTIER EN UN SEUL COUP. Or c est l escalier entier
/// que le telephone de Christophe va monter : sa derniere version installee porte
/// `user_version = 26` (l etat de `main`), et l arbre fusionne en demande 30. QUATRE
/// marches d un coup, posees par QUATRE LOTS DIFFERENTS qui ne se sont jamais vus
/// (607 pour la v27, 613 pour la v28, 616 pour la v29, 622 pour la v30 — et 610 avait
/// ecrit SA PROPRE v28, renumerotee au moment de la composition).
///
/// UNE MIGRATION QUI ECHOUE EMPECHE LA BASE DE S OUVRIR. L application ne demarre
/// plus, et le randonneur n a aucun recours : ni reinstallation propre ni retour en
/// arriere ne lui rendent ses donnees. C est le seul defaut de l integration qui
/// rend l application INUTILISABLE plutot que diminuee — donc le seul qui doit
/// etre verifie sur l arbre COMPOSE et pas sur chaque branche prise a part.
void main() {
  /// Fabrique un fichier de base vide dans un dossier temporaire jetable.
  Future<File> fichierNeuf(String prefixe) async {
    final dir = await Directory.systemTemp.createTemp(prefixe);
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    return File('${dir.path}/app.sqlite');
  }

  /// Lit `PRAGMA user_version` — c est le compteur que Drift avance marche a marche.
  Future<int> versionUtilisateur(AppDatabase db) async {
    final ligne = await db.customSelect('PRAGMA user_version').getSingle();
    return ligne.data.values.first as int;
  }

  group('619 — la sequence complete sur une base NEUVE', () {
    test(
      'un fichier vide s ouvre du premier coup et se range directement en v30 '
      '— c est le chemin de la PREMIERE INSTALLATION sur le telephone',
      () async {
        final fichier = await fichierNeuf('gr_619_neuve_');
        expect(
          await fichier.exists(),
          isFalse,
          reason: 'le test doit partir d un fichier qui n existe pas',
        );

        final db = AppDatabase(NativeDatabase(fichier));
        // La premiere requete declenche l ouverture, donc onCreate.
        await db.customStatement('SELECT 1');

        expect(
          await versionUtilisateur(db),
          db.schemaVersion,
          reason:
              'une base neuve doit etre posee directement a la version '
              'courante, sans repasser par les marches',
        );
        expect(db.schemaVersion, 30);

        await db.close();
        expect(
          await fichier.exists(),
          isTrue,
          reason: 'la base doit vivre dans un FICHIER (acquis du lot 613)',
        );
      },
    );

    test(
      'sur une base neuve les colonnes des QUATRE derniers lots sont toutes la '
      '— la v27 (lot 607), la v28 (lots 613 et 610), la v29 (lot 616) et la v30 '
      '(lot 622)',
      () async {
        final fichier = await fichierNeuf('gr_619_neuve_col_');
        final db = AppDatabase(NativeDatabase(fichier));
        addTearDown(db.close);
        await db.customStatement('SELECT 1');

        Future<Set<String>> colonnesDe(String table) async {
          final lignes = await db
              .customSelect('PRAGMA table_info($table)')
              .get();
          return lignes.map((l) => l.data['name'] as String).toSet();
        }

        final manifests = await colonnesDe('trail_manifests');
        // v27 (lot 607) : la fiche du sentier et le repere de revision.
        expect(manifests, contains('fiche_json'));
        expect(manifests, contains('local_version'));
        // v29 (lot 616) : jusqu ou le sentier est descendu sur ce telephone.
        expect(
          manifests,
          contains('niveau_local'),
          reason:
              'sans cette colonne le randonneur part sans trace en '
              'croyant avoir tout telecharge',
        );
        // v30 (lot 622) : ou est la carte hors ligne, ce qu elle pese, son
        // empreinte. Sans ces trois colonnes, le geste « telecharger » n a aucune
        // adresse de tuiles a lire et le randonneur part sans fond de carte.
        for (final colonne in ['tiles_path', 'tiles_size', 'tiles_hash']) {
          expect(
            manifests,
            contains(colonne),
            reason:
                'sans $colonne, les cartes hors ligne n ont aucun chemin de '
                'telechargement',
          );
        }

        // v27 (lot 607) : le repere de revision descend jusqu aux tables filles.
        for (final table in ['trail_meta', 'trail_stages', 'trail_pois']) {
          expect(
            await colonnesDe(table),
            contains('rev'),
            reason: '$table doit porter son repere de revision',
          );
        }
      },
    );
  });

  group('619 — la sequence complete sur une base EXISTANTE', () {
    /// Fabrique une base a l etat de `main` : schema courant, mais compteur
    /// ramene a 26. C est exactement ce que porte un telephone ou la derniere
    /// version publiee est installee, et c est l etat que l arbre fusionne doit
    /// savoir rattraper EN UNE SEULE OUVERTURE.
    Future<File> baseEnV26AvecDonnees() async {
      final fichier = await fichierNeuf('gr_619_existante_');
      final semeur = AppDatabase(NativeDatabase(fichier));
      await semeur.customStatement('SELECT 1');

      await semeur.customStatement(
        "INSERT INTO trail_manifests "
        "(trail_id, data_version, hash, file_path, file_size, status, "
        "last_updated, local_version) "
        "VALUES ('gr20', 1759017600000, 'empreinte-619', 'gr20/v1.json', "
        "8192, 'active', '2026-09-28T00:00:00Z', 1759017600000)",
      );
      // Etat d avant la v29 et la v30 : ni le niveau descendu ni le descripteur
      // de carte hors ligne ne sont encore notes.
      await semeur.customStatement(
        'UPDATE trail_manifests SET niveau_local = NULL, tiles_path = NULL, '
        'tiles_size = NULL, tiles_hash = NULL',
      );
      await semeur.customStatement('PRAGMA user_version = 26');
      await semeur.close();
      return fichier;
    }

    test('une base en v26 monte les QUATRE marches d un coup et s ouvre — '
        'c est la MISE A JOUR sur un telephone deja equipe', () async {
      final fichier = await baseEnV26AvecDonnees();

      final db = AppDatabase(NativeDatabase(fichier));
      addTearDown(db.close);
      // Si UNE SEULE des quatre marches leve, cette ligne echoue et la base
      // reste fermee — exactement ce qui se produirait sur le telephone.
      await db.customStatement('SELECT 1');

      expect(
        await versionUtilisateur(db),
        30,
        reason: 'le compteur doit avoir traverse v27, v28, v29 et v30',
      );
    });

    test('la donnee posee avant la migration est TOUJOURS LA apres — '
        'une migration ne doit rien perdre en chemin', () async {
      final fichier = await baseEnV26AvecDonnees();
      final db = AppDatabase(NativeDatabase(fichier));
      addTearDown(db.close);

      final lignes = await db
          .customSelect(
            "SELECT trail_id, hash, file_size, local_version "
            "FROM trail_manifests WHERE trail_id = 'gr20'",
          )
          .get();

      expect(
        lignes,
        hasLength(1),
        reason: 'le sentier inscrit avant la migration a disparu',
      );
      expect(lignes.single.data['hash'], 'empreinte-619');
      expect(lignes.single.data['file_size'], 8192);
    });

    test('rejouer la sequence sur une base DEJA migree ne leve pas — '
        'c est le cas de l application tuee au milieu d une marche', () async {
      final fichier = await baseEnV26AvecDonnees();

      // Premier passage : la base monte de 26 a 30.
      final premier = AppDatabase(NativeDatabase(fichier));
      await premier.customStatement('SELECT 1');
      expect(await versionUtilisateur(premier), 30);
      await premier.close();

      // On remet le compteur en arriere SANS defaire le schema : c est l etat
      // qu une application tuee entre la derniere marche et l ecriture du
      // compteur laisse derriere elle. Les marches vont se rejouer sur des
      // colonnes DEJA POSEES.
      final saboteur = AppDatabase(NativeDatabase(fichier));
      await saboteur.customStatement('PRAGMA user_version = 26');
      await saboteur.close();

      final second = AppDatabase(NativeDatabase(fichier));
      addTearDown(second.close);
      await second.customStatement('SELECT 1');
      expect(
        await versionUtilisateur(second),
        30,
        reason: 'les marches doivent etre rejouables sans echouer',
      );
    });
  });

  group('619 — fermer et rouvrir ne perd rien (acquis du lot 613)', () {
    test('ce qui est ecrit avant la fermeture est relu apres la reouverture, '
        'sur l arbre FUSIONNE et non sur la seule branche du lot 613', () async {
      final fichier = await fichierNeuf('gr_619_cycle_');

      final premiere = AppDatabase(NativeDatabase(fichier));
      await premiere.customStatement(
        "INSERT INTO trail_manifests "
        "(trail_id, data_version, hash, file_path, file_size, status, "
        "last_updated, local_version) "
        "VALUES ('survivant-619', 1759017600000, 'h-cycle', 'x/v1.json', "
        "1024, 'active', '2026-09-28T00:00:00Z', 1759017600000)",
      );
      await premiere.close();

      // Nouvelle instance, meme fichier : c est la reouverture de l application.
      final seconde = AppDatabase(NativeDatabase(fichier));
      addTearDown(seconde.close);
      final lignes = await seconde
          .customSelect(
            "SELECT trail_id FROM trail_manifests "
            "WHERE trail_id = 'survivant-619'",
          )
          .get();

      expect(
        lignes,
        hasLength(1),
        reason:
            'la base est retombee en memoire : tout disparait a la '
            'fermeture, c est le defaut que le lot 613 avait ferme',
      );
    });
  });
}
