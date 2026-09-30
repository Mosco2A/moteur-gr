import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moteur_gr/core/config/mare_a_mare_centre_trail_config.dart';
import 'package:moteur_gr/core/data/daos/journal_dao.dart';
import 'package:moteur_gr/core/data/daos/progress_dao.dart';
import 'package:moteur_gr/core/data/daos/session_track_points_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_accommodations_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_gpx_points_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_gpx_tracks_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_itineraries_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_manifests_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_meta_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_pois_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_stages_dao.dart';
import 'package:moteur_gr/core/data/database.dart' hide TrailManifest;
import 'package:moteur_gr/core/models/trail_manifest.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/data_retention_service.dart';
import 'package:moteur_gr/core/services/delta_update_service.dart';
import 'package:moteur_gr/core/services/manifest_service.dart';
import 'package:moteur_gr/core/services/sauvegarde_systeme.dart';
import 'package:moteur_gr/core/services/wallet_store.dart';
import 'package:moteur_gr/features/feasibility/data/hiker_profile_repository.dart';
import 'package:moteur_gr/features/feasibility/domain/hiker_profile.dart';
import 'package:moteur_gr/features/safety/data/fiche_medicale_fichier.dart';
import 'package:moteur_gr/features/safety/data/health_info_repository.dart';
import 'package:moteur_gr/features/safety/domain/models/health_info.dart';
import 'package:moteur_gr/features/trek/data/seed_data_loader.dart';
import 'package:moteur_gr/core/models/niveau_de_telechargement.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../tool/publication/publicateur.dart';

/// TACHE 613 — LE TEST QUI MANQUAIT DEPUIS DES MOIS : REMPLIR, FERMER, ROUVRIR.
///
/// ---------------------------------------------------------------------------
/// POURQUOI CE FICHIER EST LE COEUR DU LOT, ET PAS UN ACCESSOIRE
/// ---------------------------------------------------------------------------
///
/// La base de StepWays etait ouverte EN MEMOIRE en production
/// (`database_provider.dart` : `NativeDatabase.memory()`). Tout ce que le
/// randonneur faisait disparaissait a la fermeture de l'application : sa fiche
/// medicale, sa progression, son journal, ses sentiers telecharges.
///
/// CE DEFAUT A SURVECU DES MOIS PARCE QU'AUCUN TEST NE FERMAIT LA BASE. Les 59
/// fichiers de tests qui touchent [databaseProvider] le SURCHARGENT tous : ils
/// travaillaient sur une base substituee, jamais sur celle de production. Un
/// defaut que personne ne regarde ne se voit pas — et il etait meme DOCUMENTE en
/// trois endroits du code sans que quiconque le rebranche.
///
/// LES TESTS DE CE FICHIER NE SURCHARGENT DONC PAS [databaseProvider]. Ils
/// exercent le VRAI provider, sur un VRAI fichier. Ce qui est simule, c'est le
/// telephone : le repertoire de documents et le stockage applicatif pointent
/// dans un bac temporaire, par le canal de methode de `path_provider` — donc
/// exactement le chemin que la production emprunte.
///
/// « FERMER ET ROUVRIR » se joue avec DEUX [ProviderContainer] successifs. Le
/// premier est dispose — ce qui ferme la base, via le `onDispose` du provider —
/// et le second recree tout depuis zero. Aucune valeur n'est transportee de l'un
/// a l'autre : ce qui est retrouve a ete relu sur le disque.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory bac;
  late Directory documents;
  late Directory stockageApplicatif;

  const canalChemins = MethodChannel('plugins.flutter.io/path_provider');

  setUp(() async {
    bac = Directory.systemTemp.createTempSync('persistance613');
    documents = Directory('${bac.path}/documents')..createSync(recursive: true);
    stockageApplicatif = Directory('${bac.path}/support')
      ..createSync(recursive: true);

    // LE TELEPHONE SIMULE. On ne remplace ni le provider de la base ni celui de
    // la fiche : on remplace le TELEPHONE sous eux.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canalChemins, (appel) async {
          switch (appel.method) {
            case 'getApplicationDocumentsDirectory':
              return documents.path;
            case 'getApplicationSupportDirectory':
              return stockageApplicatif.path;
            case 'getTemporaryDirectory':
              return bac.path;
          }
          return null;
        });

    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canalChemins, null);
    if (bac.existsSync()) {
      try {
        bac.deleteSync(recursive: true);
      } on FileSystemException {
        // Windows garde parfois la main sur le fichier de base quelques
        // millisecondes apres sa fermeture. Le bac est temporaire : l'echec du
        // menage ne doit pas faire echouer une verification de persistance.
      }
    }
  });

  /// Ouvre une « session d'application » : un conteneur Riverpod neuf, avec le
  /// VRAI [databaseProvider]. Le fermer ferme la base.
  ProviderContainer ouvrirLApplication() => ProviderContainer();

  /// FERME L'APPLICATION, ET ATTEND VRAIMENT QUE LA BASE SOIT FERMEE.
  ///
  /// `ref.onDispose` est SYNCHRONE : il lance `db.close()` sans l'attendre. En
  /// production cela n'a pas d'importance (le systeme reprend le fichier avec le
  /// processus), mais ici la session suivante rouvre le MEME fichier dans la
  /// foulee — et sous Windows un fichier encore tenu se rouvre mal. On laisse
  /// donc la fermeture s'achever avant de rouvrir, sinon ce test mesurerait un
  /// verrou de fichier au lieu de mesurer la persistance.
  Future<void> fermerLApplication(ProviderContainer session) async {
    session.dispose();
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  // ===========================================================================
  // 1. LE COEUR DU LOT
  // ===========================================================================
  group('613 — remplir, FERMER, ROUVRIR, tout retrouver', () {
    test('LE TEST D ACCEPTATION : progression, journal, trace GPS, solde, '
        'profil et sentier survivent a la fermeture de l application', () async {
      // ------------------------------------------------------------------
      // PREMIERE SESSION — le randonneur fait des choses
      // ------------------------------------------------------------------
      final session1 = ouvrirLApplication();
      final db1 = session1.read(databaseProvider);

      await ProgressDao(db1).upsert(
        UserProgressEntriesCompanion.insert(
          trailId: 'mare-a-mare-centre',
          currentStage: const Value(4),
          totalDistanceWalkedKm: const Value(52.5),
          totalElevationGainedM: const Value(2800),
          totalTimeMinutes: const Value(1_320),
          startedAt: Value(DateTime.utc(2026, 9, 20)),
        ),
      );

      await JournalDao(db1).insertEntry(
        JournalEntriesCompanion.insert(
          trailId: 'mare-a-mare-centre',
          stageNumber: 3,
          content: const Value('Orage au col, arrivee trempe mais heureux.'),
          createdAt: DateTime.utc(2026, 9, 23, 18, 30),
        ),
      );

      await SessionTrackPointsDao(db1).insertPoint(
        trailId: 'mare-a-mare-centre',
        lat: 42.1234,
        lng: 9.1234,
        altitude: 1480,
        recordedAt: DateTime.utc(2026, 9, 23, 14),
        sessionId: 'sess-1',
        dayIndex: 3,
      );

      // Le solde d'etapes : sa SOURCE durable reste les preferences, mais son
      // miroir canonique vit en base. Avant ce lot, ce miroir mourait a chaque
      // fermeture et devait etre re-fabrique au demarrage suivant.
      await WalletStore(db: db1).credit(12);

      await HikerProfileRepository(
        db: db1,
        prefs: await SharedPreferences.getInstance(),
      ).saveProfile(
        const HikerProfile(
          age: 41,
          heightCm: 178,
          weightKg: 74.5,
          countryIso: 'FR',
        ),
      );

      // LA FERMETURE. Le `onDispose` du provider ferme la base.
      await fermerLApplication(session1);

      // ------------------------------------------------------------------
      // SECONDE SESSION — rien n'est transporte, tout est relu sur le disque
      // ------------------------------------------------------------------
      final session2 = ouvrirLApplication();
      addTearDown(session2.dispose);
      final db2 = session2.read(databaseProvider);

      expect(
        identical(db1, db2),
        isFalse,
        reason: 'sans une base VRAIMENT neuve, ce test ne prouverait rien',
      );

      final progression = await ProgressDao(
        db2,
      ).getByTrailId('mare-a-mare-centre');
      expect(
        progression,
        isNotNull,
        reason:
            'LA PROGRESSION : c est ce que le randonneur a marche. Avant '
            'ce lot elle disparaissait a chaque fermeture.',
      );
      expect(progression!.currentStage, 4);
      expect(progression.totalDistanceWalkedKm, 52.5);
      expect(progression.totalElevationGainedM, 2800);

      final journal = await JournalDao(db2).getByTrailId('mare-a-mare-centre');
      expect(journal, hasLength(1));
      expect(journal.single.content, contains('Orage au col'));

      final trace = await SessionTrackPointsDao(
        db2,
      ).getByTrailId('mare-a-mare-centre');
      expect(
        trace,
        hasLength(1),
        reason:
            'la trace GPS est la preuve du trek realise ; le modele '
            'economique promet qu elle reste A VIE',
      );
      expect(trace.single.altitude, 1480);
      expect(trace.single.sessionId, 'sess-1');

      final solde = await db2.walletDao.getByUserId(kWalletLocalUserId);
      expect(solde, isNotNull);
      expect(
        solde!.balanceSteps,
        12,
        reason:
            'NUANCE A NE PAS PERDRE : les achats au magasin n ont jamais '
            'ete perdus (la transaction est chez Google ou Apple). Ce qui '
            'disparaissait, c etait NOTRE comptabilite — le solde d etapes.',
      );

      final profil = await db2.hikerProfileDao.getByUserId(kHikerLocalUserId);
      expect(profil, isNotNull);
      expect(profil!.age, 41);
      expect(profil.heightCm, 178);
      expect(profil.weightKg, 74.5);
    });

    test(
      'LE FICHIER EXISTE VRAIMENT SUR LE DISQUE, la ou la production le pose',
      () async {
        final session = ouvrirLApplication();
        addTearDown(session.dispose);
        // La base est PARESSEUSE : le fichier n'apparait qu'a la premiere
        // requete. C est voulu (un test de widgets qui n interroge pas la base ne
        // reclame pas `path_provider`), et c est verifie ici pour que personne ne
        // prenne l absence initiale du fichier pour une panne.
        await session.read(databaseProvider).customSelect('SELECT 1').get();

        final fichier = File('${documents.path}/$kFichierBaseStepWays');
        expect(
          fichier.existsSync(),
          isTrue,
          reason:
              'la base doit etre un FICHIER du repertoire de documents : '
              'c est tout l objet du lot',
        );
        expect(fichier.lengthSync(), greaterThan(0));
      },
    );
  });

  // ===========================================================================
  // 2. LA FICHE MEDICALE — DEHORS DE LA BASE, ET DANS LE DOSSIER EXCLU
  // ===========================================================================
  group('613 — la fiche medicale survit AUSSI, mais dans son propre fichier', () {
    test('remplie, fermee, rouverte : elle est retrouvee', () async {
      final session1 = ouvrirLApplication();
      await HealthInfoRepository(fichier: FicheMedicaleFichier()).save(
        const HealthInfo(
          bloodType: 'O-',
          allergies: 'Penicilline',
          treatments: 'Levothyrox 50',
          doctorContact: 'Dr Rossi 04 95 00 00 00',
          insuranceNumber: 'CEAM-12345',
        ),
      );
      await fermerLApplication(session1);

      final session2 = ouvrirLApplication();
      addTearDown(session2.dispose);
      final relue = await HealthInfoRepository(
        fichier: FicheMedicaleFichier(),
      ).get();
      expect(relue.bloodType, 'O-');
      expect(relue.allergies, 'Penicilline');
      expect(relue.insuranceNumber, 'CEAM-12345');
    });

    test('ELLE EST DANS LE DOSSIER DECLARE EXCLU DE LA SAUVEGARDE, et PAS dans '
        'la base', () async {
      final session = ouvrirLApplication();
      addTearDown(session.dispose);

      await HealthInfoRepository(
        fichier: FicheMedicaleFichier(),
      ).save(const HealthInfo(bloodType: 'AB+'));

      final attendu = File(
        '${stockageApplicatif.path}/'
        '${SauvegardeSysteme.dossierExclu}/${FicheMedicaleFichier.nomFichier}',
      );
      expect(
        attendu.existsSync(),
        isTrue,
        reason:
            'LE POINT ENTIER DU MONTAGE : la fiche vit sous '
            '"${SauvegardeSysteme.dossierExclu}/", le seul emplacement que les '
            'regles de sauvegarde excluent. C est ce qui permet a la base, '
            'elle, de redevenir sauvegardable.',
      );
      expect(attendu.readAsStringSync(), contains('AB+'));

      // ET SURTOUT : rien de medical dans le fichier de la base.
      final db = session.read(databaseProvider);
      final lignes = await db.healthInfoDao.getFirst();
      expect(
        lignes,
        isNull,
        reason:
            'la base est desormais SAUVEGARDEE par le telephone : une '
            'seule ligne de sante ecrite ici partirait chez Google ou Apple',
      );

      final octets = File(
        '${documents.path}/$kFichierBaseStepWays',
      ).readAsBytesSync();
      expect(
        utf8.decode(octets, allowMalformed: true).contains('AB+'),
        isFalse,
        reason:
            'preuve par le contenu du fichier lui-meme, pas seulement par '
            'l API : le groupe sanguin ne doit apparaitre nulle part dedans',
      );
    });

    test('L EFFACEMENT DU COMPTE EMPORTE LE FICHIER DE LA FICHE — sortir la '
        'fiche de la base ne doit pas la mettre hors de portee du droit a '
        'l effacement', () async {
      final session = ouvrirLApplication();
      addTearDown(session.dispose);

      await HealthInfoRepository(
        fichier: FicheMedicaleFichier(),
      ).save(const HealthInfo(bloodType: 'O+', allergies: 'Arachides'));
      final surLeDisque = File(
        '${stockageApplicatif.path}/'
        '${SauvegardeSysteme.dossierExclu}/${FicheMedicaleFichier.nomFichier}',
      );
      expect(surLeDisque.existsSync(), isTrue);

      await DataRetentionService(
        database: session.read(databaseProvider),
        prefs: await SharedPreferences.getInstance(),
        // Le keystore de l'OS n'a pas d'implementation en test (canal natif) ;
        // il est couvert par `effacement_stockage_securise_test.dart`. Ce qui est
        // mesure ICI est le FICHIER de la fiche, et il l'est par DEFAUT : aucun
        // `ficheMedicaleEraser` n'est injecte, sinon le test verifierait son
        // propre double au lieu du cablage reel.
        secureKeystoreErasure: () async => 0,
      ).deleteAccountData();

      expect(
        surLeDisque.existsSync(),
        isFalse,
        reason:
            'jusqu a la tache 613 la purge des tables emportait la fiche '
            'sans avoir a la nommer. En lui donnant son propre fichier, ce lot '
            'aurait DEFAIT le droit a l effacement conquis aux lots J a O si '
            'l effacement ne la nommait pas explicitement.',
      );
      expect(
        await HealthInfoRepository(
          fichier: FicheMedicaleFichier(),
        ).get().then((f) => f.hasData),
        isFalse,
      );
    });

    test('effacee, elle ne revient pas apres une reouverture', () async {
      final session1 = ouvrirLApplication();
      final depot1 = HealthInfoRepository(fichier: FicheMedicaleFichier());
      await depot1.save(const HealthInfo(bloodType: 'A+'));
      await depot1.delete();
      await fermerLApplication(session1);

      final session2 = ouvrirLApplication();
      addTearDown(session2.dispose);
      final relue = await HealthInfoRepository(
        fichier: FicheMedicaleFichier(),
      ).get();
      expect(relue.hasData, isFalse);
      expect(
        Directory(
          '${stockageApplicatif.path}/'
          '${SauvegardeSysteme.dossierExclu}',
        ).listSync().whereType<File>(),
        isEmpty,
        reason: 'ni la fiche ni son fichier temporaire ne doivent rester',
      );
    });
  });

  // ===========================================================================
  // 3. LA SAUVEGARDE DU TELEPHONE — CE QUE LE LOT 612 SUPPOSAIT N EST PLUS VRAI
  // ===========================================================================
  group('613 — l exclusion de sauvegarde revue', () {
    test('LA BASE N EST PLUS EXCLUE : la progression et le carnet doivent '
        'suivre le randonneur qui change de telephone', () {
      expect(
        SauvegardeSysteme.exclusions.where((e) => e.domaine == 'database'),
        isEmpty,
        reason:
            'le lot 612 avait exclu le domaine `database` EN SUPPOSANT la '
            'base volatile. Avec une base durable, cette exclusion ferait perdre '
            'la progression et le journal au changement de telephone, alors que '
            'le modele economique promet qu un trek realise garde A VIE sa trace '
            'et son carnet.',
      );
    });

    test(
      'LA FICHE MEDICALE, ELLE, RESTE EXCLUE — c est la seule exclusion',
      () {
        expect(SauvegardeSysteme.exclusions, hasLength(1));
        expect(SauvegardeSysteme.exclusions.single.domaine, 'file');
        expect(SauvegardeSysteme.exclusions.single.chemin, 'medical/');
      },
    );

    test('LE FICHIER DE LA BASE N EST PAS DANS LE DOMAINE `database` — c est '
        'pour cela que l exclusion du lot 612 ne protegeait rien', () async {
      final session = ouvrirLApplication();
      addTearDown(session.dispose);
      await session.read(databaseProvider).customSelect('SELECT 1').get();

      // Le domaine `database` des regles Android designe
      // `/data/data/<paquet>/databases/`. La base de StepWays vit sous le
      // repertoire de DOCUMENTS (`app_flutter/` sur Android, domaine `root`) :
      // une application Flutter n ecrit jamais dans `databases/`.
      expect(
        File('${documents.path}/$kFichierBaseStepWays').existsSync(),
        isTrue,
      );
      expect(Directory('${bac.path}/databases').existsSync(), isFalse);
    });
  });

  // ===========================================================================
  // 4. LES MIGRATIONS — ELLES N AVAIENT JAMAIS EU DE FICHIER A MIGRER
  // ===========================================================================
  group('613 — la sequence de migrations sur une base neuve', () {
    test(
      'une base NEUVE s ouvre au schema courant, avec toutes ses tables',
      () async {
        final session = ouvrirLApplication();
        addTearDown(session.dispose);
        final db = session.read(databaseProvider);

        final version = await db
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(
          version.read<int>('user_version'),
          db.schemaVersion,
          reason:
              'une base neuve est creee au schema courant : `onUpgrade` '
              'n est pas appele, `onCreate` pose tout',
        );

        final tables =
            (await db
                    .customSelect(
                      "SELECT name FROM sqlite_master WHERE type='table'",
                    )
                    .get())
                .map((r) => r.read<String>('name'))
                .toSet();
        for (final attendue in db.allTables.map((t) => t.actualTableName)) {
          expect(tables, contains(attendue));
        }
      },
    );

    test('LA SEQUENCE COMPLETE DEPUIS LA v1 S EXECUTE SANS CASSER, ET ELLE NE '
        'PERD RIEN', () async {
      // Ce que ce test joue est le cas REEL que le lot vient de rendre
      // possible : une base posee sur le telephone, puis une mise a jour de
      // l application qui fait monter le schema. Une migration qui echoue
      // EMPECHE LA BASE DE S OUVRIR — l application ne demarre plus, sans
      // recours. Avant la tache 613, vingt-six des vingt-huit marches
      // ajoutaient des colonnes sans verifier leur presence : rejouees sur une
      // base deja pourvue (migration interrompue, `user_version` en arriere),
      // elles echouaient sur « duplicate column name ».
      final fichier = File('${documents.path}/$kFichierBaseStepWays');

      final amorce = AppDatabase(NativeDatabase(fichier));
      await amorce.customStatement('SELECT 1');
      await amorce
          .into(amorce.userProgressEntries)
          .insert(
            UserProgressEntriesCompanion.insert(
              trailId: 'gr20',
              currentStage: const Value(7),
            ),
          );
      await amorce.customStatement('PRAGMA user_version = 1');
      await amorce.close();

      final session = ouvrirLApplication();
      addTearDown(session.dispose);
      final db = session.read(databaseProvider);

      await expectLater(db.customSelect('SELECT 1').get(), completes);
      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.read<int>('user_version'), db.schemaVersion);

      final progression = await ProgressDao(db).getByTrailId('gr20');
      expect(
        progression,
        isNotNull,
        reason:
            'une migration ne doit rien perdre de ce que le randonneur '
            'avait deja marche',
      );
      expect(progression!.currentStage, 7);
    });

    test(
      'LA MARCHE v28 VIDE LA TABLE DE SANTE — aucune donnee medicale ne doit '
      'entrer dans un fichier desormais sauvegarde',
      () async {
        final fichier = File('${documents.path}/$kFichierBaseStepWays');

        final amorce = AppDatabase(NativeDatabase(fichier));
        await amorce.customStatement('SELECT 1');
        await amorce.healthInfoDao.insertEntry(
          HealthInfoEntriesCompanion.insert(bloodType: const Value('B-')),
        );
        await amorce.customStatement('PRAGMA user_version = 27');
        await amorce.close();

        final session = ouvrirLApplication();
        addTearDown(session.dispose);
        final db = session.read(databaseProvider);

        expect(
          await db.healthInfoDao.getFirst(),
          isNull,
          reason:
              'la fiche a quitte la base ; une ligne laissee par un binaire '
              'intermediaire monterait chez Google avec le reste',
        );
      },
    );
  });

  // ===========================================================================
  // 5. LE SENTIER TELECHARGE — CE QUE LE LOT DEBLOQUE POUR LES LOTS 605 A 610
  // ===========================================================================
  group('613 — un sentier publie par l outil survit a une fermeture', () {
    test('gr-monts-dore, telecharge puis ferme, est toujours la A LA '
        'REOUVERTURE — avec son repere de revision, donc sans tout '
        'retelecharger', () async {
      final source = Directory('${bac.path}/source')
        ..createSync(recursive: true);
      final publie = '${bac.path}/publie';
      for (final nom in const ['sentier.json', 'trace.gpx']) {
        File(
          'test/fixtures/publication/gr-monts-dore/$nom',
        ).copySync('${source.path}/$nom');
      }
      Publicateur(
        sortie: publie,
        horloge: DateTime.utc(2026, 9, 28),
      ).publier(source.path.replaceAll(r'\', '/'));

      final liste =
          jsonDecode(
                File('$publie/${Publicateur.nomDeLaListe}').readAsStringSync(),
              )
              as Map<String, dynamic>;
      final entree = TrailManifest.fromJson(
        liste,
      ).trails.firstWhere((e) => e.trailId == 'gr-monts-dore');

      MockClient stockage() => MockClient((requete) async {
        final url = requete.url.toString();
        for (final f in Directory(
          publie,
        ).listSync(recursive: true).whereType<File>()) {
          final chemin = f.path
              .replaceAll(r'\', '/')
              .substring(publie.length + 1);
          if (!url.contains(Uri.encodeComponent(chemin)) &&
              !url.contains(chemin)) {
            continue;
          }
          return http.Response.bytes(
            f.readAsBytesSync(),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('non trouve', 404);
      });

      // --- SESSION 1 : le randonneur telecharge le sentier ---
      final session1 = ouvrirLApplication();
      final db1 = session1.read(databaseProvider);
      final manifestes1 = TrailManifestsDao(db1);
      final reseau = _FauxReseau(ConnectivityStatusValues.online);

      await ManifestService(
        dao: manifestes1,
        connectivityMonitor: reseau,
      ).saveLocalManifest(entree);
      await DeltaUpdateService(
        db: db1,
        manifestService: ManifestService(
          dao: manifestes1,
          connectivityMonitor: reseau,
        ),
        trailManifestsDao: manifestes1,
        trailMetaDao: TrailMetaDao(db1),
        trailItinerariesDao: TrailItinerariesDao(db1),
        trailStagesDao: TrailStagesDao(db1),
        trailAccommodationsDao: TrailAccommodationsDao(db1),
        trailPoisDao: TrailPoisDao(db1),
        trailGpxTracksDao: TrailGpxTracksDao(db1),
        trailGpxPointsDao: TrailGpxPointsDao(db1),
        httpClient: stockage(),
      ).synchroniser(
        'gr-monts-dore',
        'https://double/${entree.filePath}',
        niveau: NiveauDeTelechargement.realiser,
        revisionCible: entree.dataVersion,
        empreinteAttendue: entree.hash,
      );

      expect(await manifestes1.needsUpdate('gr-monts-dore'), isFalse);
      await fermerLApplication(session1);

      // --- SESSION 2 : le sentier est toujours la, et il n est pas a refaire ---
      final session2 = ouvrirLApplication();
      addTearDown(session2.dispose);
      final db2 = session2.read(databaseProvider);

      expect(
        await TrailStagesDao(db2).getByItineraryId('montsdore-i1'),
        hasLength(2),
        reason:
            'les etapes du sentier telecharge doivent survivre : sans ca, '
            'les lots 605 a 610 ne servaient a rien',
      );
      expect(
        await TrailPoisDao(db2).getByStageId('montsdore-s1'),
        hasLength(2),
      );
      final points = await TrailGpxPointsDao(db2).getAll();
      expect(
        points,
        hasLength(10),
        reason: 'LA TRACE : c est elle que la carte lit depuis le lot 606',
      );

      final ligne = await TrailManifestsDao(db2).getByTrailId('gr-monts-dore');
      expect(ligne, isNotNull);
      expect(
        ligne!.localVersion,
        entree.dataVersion,
        reason:
            'LE REPERE DE REVISION LOCALE SURVIT AUSSI. Sans lui, chaque '
            'ouverture de l application retelechargerait le sentier entier, '
            'et tout le modele de revision de Christophe (lots 605 a 610) ne '
            'servirait a rien.',
      );
      expect(
        await TrailManifestsDao(db2).needsUpdate('gr-monts-dore'),
        isFalse,
        reason:
            'la question « dois-je telecharger ? » doit repondre NON a la '
            'reouverture',
      );
    });
  });

  // ===========================================================================
  // 6. LE SEED — CE QUE LA PERSISTANCE AURAIT CASSE SI ON N Y AVAIT PAS TOUCHE
  // ===========================================================================
  group('613 — le semeur ne duplique plus rien, et c est LA BASE qui decide', () {
    test('UNE PREFERENCE QUI DIT « DEJA SEEDE » DEVANT UNE BASE VIDE NE DOIT '
        'PAS EMPECHER LE SEED', () async {
      // Cas reel : preferences restaurees depuis la sauvegarde d un ancien
      // telephone, ou drapeau pose par une version de l application dont la base
      // etait en memoire. Le croire ouvrirait l application sur une carte sans
      // etapes.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(SeedDataLoader.kDataSeededPrefsKey, true);

      final session = ouvrirLApplication();
      addTearDown(session.dispose);
      final db = session.read(databaseProvider);
      final semeur = SeedDataLoader(
        db: db,
        prefs: prefs,
        trailConfig: mareAMareCentreTrailConfig,
      );

      expect(await semeur.seedIfNeeded(), isTrue);
      expect(
        prefs.getBool(SeedDataLoader.kDataSeededPrefsKey),
        isNull,
        reason: 'l ancien drapeau est OUBLIE, pas laisse derriere soi',
      );
      expect(await db.stagesDao.getByTrailId('mare-a-mare-centre'), isNotEmpty);
    });

    test('UNE BASE DEJA PEUPLEE NE DOIT PAS ETRE RE-SEEDEE, MEME SANS AUCUNE '
        'PREFERENCE — c est le cas de l effacement de compte', () async {
      // L effacement art. 17 purge les preferences mais CONSERVE les tables de
      // reference du sentier (`stages`, `pois`, la trace — decision du lot J :
      // effacer SES donnees ne doit pas lui retirer SON sentier). Un semeur qui
      // se fiait a une preference aurait donc re-seede par-dessus au lancement
      // suivant, et ce code INSERE sans jamais vider : etapes, points d interet
      // et trace GPX ENTIERE dupliques. C est la base qu on interroge.
      final session = ouvrirLApplication();
      addTearDown(session.dispose);
      final db = session.read(databaseProvider);

      SeedDataLoader semeur(SharedPreferences prefs) => SeedDataLoader(
        db: db,
        prefs: prefs,
        trailConfig: mareAMareCentreTrailConfig,
      );

      expect(
        await semeur(await SharedPreferences.getInstance()).seedIfNeeded(),
        isTrue,
      );
      final etapes = await db.stagesDao.getByTrailId('mare-a-mare-centre');
      final points = await db.trailGpxPointsDao.getAll();
      expect(etapes, isNotEmpty);
      expect(points, isNotEmpty);

      // Preferences ENTIEREMENT vides, comme apres un effacement de compte.
      SharedPreferences.setMockInitialValues(<String, Object>{});
      expect(
        await semeur(await SharedPreferences.getInstance()).seedIfNeeded(),
        isFalse,
        reason: 'la base dit deja que le sentier est pose',
      );

      expect(
        await db.stagesDao.getByTrailId('mare-a-mare-centre'),
        hasLength(etapes.length),
      );
      expect(
        await db.trailGpxPointsDao.getAll(),
        hasLength(points.length),
        reason:
            'la trace ne doit pas doubler : c est ce que le randonneur '
            'verrait a l ecran, un trait pose deux fois',
      );
    });
  });
}

class _FauxReseau extends ConnectivityMonitor {
  _FauxReseau(this._statut);
  final ConnectivityStatus _statut;
  @override
  Future<ConnectivityStatus> checkStatus() async => _statut;
  @override
  Stream<ConnectivityStatus> get onStatusChange => Stream.value(_statut);
}
