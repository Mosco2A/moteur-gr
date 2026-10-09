/// TACHE 760 — LA DEMO PROMET QUE RIEN N'EST ENREGISTRE, ET ELLE ENREGISTRAIT.
///
/// LE DEFAUT, MESURE A LA RECETTE 753 SUR EMULATEUR. Pendant une demo, un
/// profil (45 ans, 178 cm, 75 kg) et une randonnee passee ont ete saisis. A la
/// sortie de la demo, APRES UN ARRET FORCE de l'application et apres relance,
/// les deux etaient toujours la, et la demo suivante demarrait avec son verdict
/// de faisabilite deja calcule. L'ecran de depart de la demo affiche pourtant,
/// mot pour mot : « En demo, le depart lance une randonnee simulee : rien n'est
/// enregistre. »
///
/// POURQUOI LA PROMESSE ETAIT FAUSSE. Les barrieres des lots 634, 742 et 744
/// protegeaient l'argent, les droits, la session de randonnee, la trace GPS, le
/// carnet et le sac. Elles ne protegeaient RIEN de ce que le randonneur SAISIT
/// dans un formulaire : le profil, les randonnees passees, le test de marche,
/// la fiche medicale, le consentement art. 9, les seances d'entrainement.
/// Ces chemins-la n'avaient jamais eu de dernier rempart.
///
/// CE QUE CES GARDES TIENNENT :
///   1. EN DEMO, AUCUNE SAISIE NE SURVIT — ni en fichier, ni en base, ni en
///      preferences ; et la garde regarde le DISQUE, pas un drapeau.
///   2. LE CAS REEL EST INTACT : hors demo, tout s'ecrit comme avant, et une
///      demo ne peut ni modifier ni EFFACER ce qu'un vrai randonneur a saisi.
///   3. LA DEMO SUIVANTE REPART VIERGE, y compris apres une premiere demo qui
///      a tout rempli.
///   4. APRES UNE DEMO COMPLETE ET UNE SORTIE, l'instantane des preferences ET
///      des tables du randonneur est IDENTIQUE a celui d'avant. C'est la garde
///      demandee par le lot, et c'est la seule qui couvre les chemins qu'on
///      n'aurait pas pense a nommer.
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/providers/service_providers.dart';
import 'package:moteur_gr/core/services/consent_service.dart';
import 'package:moteur_gr/core/services/session_demo.dart';
import 'package:moteur_gr/features/feasibility/data/hiker_profile_file.dart';
import 'package:moteur_gr/features/feasibility/data/hiker_profile_repository.dart';
import 'package:moteur_gr/features/feasibility/data/profil_volatil_demo.dart';
import 'package:moteur_gr/features/feasibility/domain/hiker_profile.dart';
import 'package:moteur_gr/features/feasibility/domain/past_hike.dart';
import 'package:moteur_gr/features/feasibility/domain/walk_test_result.dart';
import 'package:moteur_gr/features/safety/data/fiche_volatile_de_demo.dart';
import 'package:moteur_gr/features/safety/data/health_info_file.dart';
import 'package:moteur_gr/features/safety/domain/models/health_info.dart';
import 'package:moteur_gr/features/safety/presentation/health_info_screen.dart';
import 'package:moteur_gr/features/safety/providers/health_prepare_providers.dart';
import 'package:moteur_gr/features/training/providers/training_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../structurel/mesure_des_sources_645.dart'
    show estLigneDeCommentaire, lignesDe;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    // LE DISQUE EST REMIS A NEUF ENTRE DEUX CAS. `flutter_test_config.dart`
    // pointe le stockage applicatif sur un dossier temporaire pour TOUTE la
    // suite, mais le meme dossier sert a tous les cas : un fichier laisse par
    // un cas precedent ferait passer une garde pour de mauvaises raisons.
    await HikerProfileFile().effacer();
    await HealthInfoFile().effacer();
  });

  tearDown(() async => db.close());

  ProviderContainer conteneur() {
    final c = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(c.dispose);
    return c;
  }

  void entrerEnDemo(ProviderContainer c) =>
      c.read(sessionDemoProvider.notifier).entrer();
  void sortirDeLaDemo(ProviderContainer c) =>
      c.read(sessionDemoProvider.notifier).sortir();

  /// LE DOCUMENT DU PROFIL EXISTE-T-IL VRAIMENT SUR LE DISQUE ?
  Future<bool> leDocumentDuProfilExiste() async =>
      (await HikerProfileFile().fichier()).existsSync();

  /// LA FICHE MEDICALE EXISTE-T-ELLE VRAIMENT SUR LE DISQUE ?
  Future<bool> laFicheMedicaleExiste() async =>
      (await HealthInfoFile().fichier()).existsSync();

  const profilDeLaRecette = HikerProfile(age: 45, heightCm: 178, weightKg: 75);

  final randoDeLaRecette = PastHike(
    date: DateTime(2026, 8, 12),
    days: 3,
    avgWalkHoursPerDay: 6,
    totalElevationGain: 1800,
    totalDistanceKm: 52,
  );

  group('760 — le profil, les randos passees et le test de marche', () {
    test(
      'HORS DEMO, Enregistrer ecrit le document ET le miroir Drift',
      () async {
        final c = conteneur();
        final depot = c.read(hikerProfileRepositoryProvider);

        await depot.saveProfile(profilDeLaRecette);

        expect(
          await leDocumentDuProfilExiste(),
          isTrue,
          reason: 'le cas reel doit continuer d ecrire son document',
        );
        expect(await db.select(db.hikerProfile).get(), hasLength(1));
        expect((await depot.getProfile()).age, 45);
      },
    );

    test('EN DEMO, Enregistrer n ecrit NI document NI miroir Drift', () async {
      final c = conteneur();
      entrerEnDemo(c);
      final depot = c.read(hikerProfileRepositoryProvider);

      await depot.saveProfile(profilDeLaRecette);

      expect(
        await leDocumentDuProfilExiste(),
        isFalse,
        reason: 'LE DEFAUT DE LA RECETTE 753 : le profil etait sur le disque',
      );
      expect(
        await db.select(db.hikerProfile).get(),
        isEmpty,
        reason: 'le miroir Drift est un second etage de persistance',
      );
    });

    test(
      'EN DEMO, la saisie se relit PENDANT la demo (l ecran marche)',
      () async {
        final c = conteneur();
        entrerEnDemo(c);
        final depot = c.read(hikerProfileRepositoryProvider);

        await depot.saveProfile(profilDeLaRecette);

        // Le formulaire n est pas casse : il rend ce qu on vient d y saisir.
        expect((await depot.getProfile()).age, 45);
      },
    );

    test(
      'EN DEMO, la fiche part VIERGE meme si le reel en porte une',
      () async {
        final c = conteneur();
        await c
            .read(hikerProfileRepositoryProvider)
            .saveProfile(profilDeLaRecette);

        entrerEnDemo(c);

        expect(
          (await c.read(hikerProfileRepositoryProvider).getProfile()).age,
          0,
          reason: 'Christophe : « la demo suivante doit repartir VIERGE »',
        );
      },
    );

    test('A LA SORTIE, le profil REEL est relu intact', () async {
      final c = conteneur();
      await c
          .read(hikerProfileRepositoryProvider)
          .saveProfile(profilDeLaRecette);

      entrerEnDemo(c);
      await c
          .read(hikerProfileRepositoryProvider)
          .saveProfile(
            const HikerProfile(age: 20, heightCm: 150, weightKg: 50),
          );
      sortirDeLaDemo(c);

      final apres = await c.read(hikerProfileRepositoryProvider).getProfile();
      expect(apres.age, 45);
      expect(apres.heightCm, 178);
      expect(apres.weightKg, 75);
    });

    test('DEUX DEMOS DE SUITE : la seconde ne voit pas la premiere', () async {
      final c = conteneur();

      entrerEnDemo(c);
      await c
          .read(hikerProfileRepositoryProvider)
          .saveProfile(profilDeLaRecette);
      sortirDeLaDemo(c);

      entrerEnDemo(c);
      expect(
        (await c.read(hikerProfileRepositoryProvider).getProfile()).age,
        0,
        reason: 'un magasin volatil NEUF est construit a chaque entree',
      );
    });

    test('EN DEMO, les randos passees n ecrivent rien', () async {
      final c = conteneur();
      entrerEnDemo(c);

      await c.read(hikerProfileRepositoryProvider).savePastHikes([
        randoDeLaRecette,
      ]);

      expect(await leDocumentDuProfilExiste(), isFalse);
      expect(await db.select(db.pastHikeEntries).get(), isEmpty);
    });

    test('EN DEMO, les randos passees n EFFACENT pas le miroir reel', () async {
      // Le miroir des randos EFFACE tout avant de reinserer : le laisser
      // tourner en demo ferait perdre au randonneur ses vraies randonnees.
      final c = conteneur();
      await c.read(hikerProfileRepositoryProvider).savePastHikes([
        randoDeLaRecette,
      ]);
      expect(await db.select(db.pastHikeEntries).get(), hasLength(1));

      entrerEnDemo(c);
      await c.read(hikerProfileRepositoryProvider).savePastHikes(const []);

      expect(
        await db.select(db.pastHikeEntries).get(),
        hasLength(1),
        reason: 'une demo a efface les vraies randonnees du randonneur',
      );
    });

    test('EN DEMO, le test de marche n ecrit rien', () async {
      final c = conteneur();
      entrerEnDemo(c);

      await c
          .read(hikerProfileRepositoryProvider)
          .saveWalkTestResult(
            WalkTestResult(
              distanceMeters: 620,
              level: 'bon',
              takenAt: DateTime(2026, 10, 9),
            ),
          );

      expect(await leDocumentDuProfilExiste(), isFalse);
    });

    test('EN DEMO, l effacement total n emporte PAS le reel', () async {
      // Effacer est encore une ecriture. Une demo qui exercerait le droit a
      // l oubli priverait le randonneur de sa fiche.
      final c = conteneur();
      await c
          .read(hikerProfileRepositoryProvider)
          .saveProfile(profilDeLaRecette);

      entrerEnDemo(c);
      await c.read(hikerProfileRepositoryProvider).eraseAllPersonalData();
      sortirDeLaDemo(c);

      expect(await leDocumentDuProfilExiste(), isTrue);
      expect(
        (await c.read(hikerProfileRepositoryProvider).getProfile()).age,
        45,
      );
      expect(await db.select(db.hikerProfile).get(), hasLength(1));
    });

    test('EN DEMO, la migration ne retire pas les cles heritees', () async {
      // La migration ECRIT le document protege puis RETIRE quatre cles de
      // preferences : c est une transformation du telephone, pas une lecture.
      SharedPreferences.setMockInitialValues({
        kHikerProfilePrefsKey: '{"age":45,"heightCm":178,"weightKg":75.0}',
      });
      final c = conteneur();
      entrerEnDemo(c);

      await c.read(hikerProfileRepositoryProvider).migrerDepuisPreferences();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kHikerProfilePrefsKey), isNotNull);
      expect(await leDocumentDuProfilExiste(), isFalse);
    });

    test('le magasin volatil n OUVRE aucun document', () async {
      // Une barriere, pas une limite : un futur chemin d ecriture doit tomber
      // dans les tests plutot qu ecrire en silence sur le telephone.
      expect(ProfilVolatilDeDemo().fichier, throwsUnsupportedError);
      expect(FicheVolatileDeDemo().fichier, throwsUnsupportedError);
    });
  });

  group('760 — la fiche medicale', () {
    test('HORS DEMO, la fiche s ecrit sur le disque', () async {
      final c = conteneur();
      await c
          .read(healthInfoRepositoryProvider)
          .save(const HealthInfo(fullName: 'Christophe'));
      expect(await laFicheMedicaleExiste(), isTrue);
    });

    test('EN DEMO, la fiche medicale n atteint pas le disque', () async {
      final c = conteneur();
      entrerEnDemo(c);

      await c
          .read(healthInfoRepositoryProvider)
          .save(const HealthInfo(fullName: 'Christophe'));

      expect(
        await laFicheMedicaleExiste(),
        isFalse,
        reason: 'groupe sanguin, allergies et traitements restaient sur le tel',
      );
    });

    test(
      'EN DEMO, la fiche se relit PENDANT la demo (l ecran marche)',
      () async {
        final c = conteneur();
        entrerEnDemo(c);
        final depot = c.read(healthInfoRepositoryProvider);

        await depot.save(const HealthInfo(fullName: 'Christophe'));

        expect((await depot.get()).fullName, 'Christophe');
      },
    );

    test('EN DEMO, aucune photo de carte n est enregistree', () async {
      final c = conteneur();
      entrerEnDemo(c);
      final fichier = c.read(healthInfoFileProvider);

      await fichier.saveCard('carte_vitale.jpg', const [1, 2, 3]);

      expect(
        (await HealthInfoFile().cardFile('carte_vitale.jpg')).existsSync(),
        isFalse,
      );
    });

    test('EN DEMO, la fiche REELLE n est pas effacee', () async {
      final c = conteneur();
      await c
          .read(healthInfoRepositoryProvider)
          .save(const HealthInfo(fullName: 'Christophe'));

      entrerEnDemo(c);
      await c.read(healthInfoRepositoryProvider).delete();
      sortirDeLaDemo(c);

      expect(await laFicheMedicaleExiste(), isTrue);
      expect(
        (await c.read(healthInfoRepositoryProvider).get()).fullName,
        'Christophe',
      );
    });
  });

  group('760 — le consentement de l article 9', () {
    const finalite = ConsentPurpose.healthData;

    test('HORS DEMO, la decision s ecrit dans les preferences', () async {
      final c = conteneur();
      final service = c.read(consentServiceProvider);
      await service.initialize();

      await service.grant(finalite);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(finalite.storageKey), isNotNull);
    });

    test('EN DEMO, aucune cle de consentement n est ecrite', () async {
      final c = conteneur();
      entrerEnDemo(c);
      final service = c.read(consentServiceProvider);
      await service.initialize();

      await service.grant(finalite);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(finalite.storageKey), isNull);
    });

    test('EN DEMO, le compteur de revision ne monte PAS sur le tel', () async {
      // Il est MONOTONE et jamais remis a zero : chaque Enregistrer joue en
      // demo le faisait monter d un cran pour toujours.
      final c = conteneur();
      entrerEnDemo(c);
      final service = c.read(consentServiceProvider);
      await service.initialize();

      await service.noterUneModificationDesDonnees(finalite);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(ConsentService.cleDeRevision(finalite)), isNull);
    });

    test('EN DEMO, la decision tient LE TEMPS de la demo', () async {
      // Sans ardoise, la case a cocher se decocherait d un ecran a l autre et
      // l application redemanderait le consentement en boucle.
      final c = conteneur();
      entrerEnDemo(c);
      final service = c.read(consentServiceProvider);
      await service.initialize();

      await service.grant(finalite);

      expect(service.hasConsent(finalite), isTrue);
    });

    test('L ARDOISE SE PERIME a la demo suivante', () async {
      // LA GARDE QUI A TROUVE UN DEFAUT DANS LE CORRECTIF LUI-MEME : un
      // ecouteur sur `enDemoProvider` ne suffisait pas, parce que Riverpod ne
      // recalcule pas une dependance qui a retrouve sa valeur precedente
      // (true -> false -> true). D'ou le NUMERO de demo.
      final c = conteneur();
      entrerEnDemo(c);
      final service = c.read(consentServiceProvider);
      await service.initialize();
      await service.grant(finalite);
      expect(service.hasConsent(finalite), isTrue);

      sortirDeLaDemo(c);
      entrerEnDemo(c);

      expect(
        service.hasConsent(finalite),
        isFalse,
        reason: 'une demo ne repart pas avec la decision de la precedente',
      );
    });

    test(
      'SANS barriere cablee, le comportement d origine est intact',
      () async {
        final service = ConsentService();
        expect(service.enDemo, isFalse);
      },
    );
  });

  group('760 — entrainement et preparation de la fiche', () {
    test('EN DEMO, cocher une seance n ecrit pas la cle', () async {
      final c = conteneur();
      entrerEnDemo(c);
      // La relecture des seances deja faites est asynchrone a la construction
      // du notifier : on la laisse finir, sinon elle ecraserait la coche.
      c.read(trainingProvider);
      await Future<void>.delayed(Duration.zero);

      await c.read(trainingProvider.notifier).toggleDone(3);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('training_done_offsets'), isNull);
      // L etat vit en memoire : l ecran se comporte comme en reel.
      expect(c.read(trainingProvider).isDone(3), isTrue);
    });

    test('EN DEMO, le signal « fiche remplie » n ecrit pas la cle', () async {
      final c = conteneur();
      entrerEnDemo(c);

      await c.read(healthPrepareStepsProvider.notifier).setFilled(true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList(kHealthPrepareStepsKey), isNull);
      expect(
        c.read(healthPrepareStepsProvider),
        contains(HealthPrepStep.filled),
      );
    });
  });

  group('760 — LA GARDE DU LOT : rien n a bouge apres une demo complete', () {
    test('preferences ET tables identiques a l etat d avant', () async {
      // LA SEULE GARDE QUI COUVRE LES CHEMINS QU ON N A PAS PENSE A NOMMER.
      // Elle photographie TOUT (chaque cle de preferences, chaque ligne des
      // tables du randonneur), joue une demo complete, sort, et compare.
      final c = conteneur();

      // Un vrai randonneur, avec de vraies donnees, AVANT la demo.
      await c
          .read(hikerProfileRepositoryProvider)
          .saveProfile(profilDeLaRecette);
      await c.read(hikerProfileRepositoryProvider).savePastHikes([
        randoDeLaRecette,
      ]);
      await c
          .read(healthInfoRepositoryProvider)
          .save(const HealthInfo(fullName: 'Christophe'));

      final prefs = await SharedPreferences.getInstance();
      final avantPrefs = <String, Object?>{
        for (final k in prefs.getKeys()) k: prefs.get(k),
      };
      final avantProfils = await db.select(db.hikerProfile).get();
      final avantRandos = await db.select(db.pastHikeEntries).get();

      // ---- LA DEMO COMPLETE -------------------------------------------------
      entrerEnDemo(c);
      final depot = c.read(hikerProfileRepositoryProvider);
      await depot.saveProfile(
        const HikerProfile(age: 20, heightCm: 150, weightKg: 50),
      );
      await depot.savePastHikes([
        PastHike(date: DateTime(2020, 1, 1), days: 9, totalDistanceKm: 300),
      ]);
      await depot.saveWalkTestResult(
        WalkTestResult(
          distanceMeters: 620,
          level: 'bon',
          takenAt: DateTime(2026, 10, 9),
        ),
      );
      await c
          .read(healthInfoRepositoryProvider)
          .save(const HealthInfo(fullName: 'Visiteur de la demo'));
      final consentement = c.read(consentServiceProvider);
      await consentement.initialize();
      await consentement.noterUneModificationDesDonnees(
        ConsentPurpose.healthData,
      );
      await consentement.grant(ConsentPurpose.healthData);
      await c.read(trainingProvider.notifier).toggleDone(2);
      await c.read(healthPrepareStepsProvider.notifier).setFilled(true);
      sortirDeLaDemo(c);
      // ---- FIN DE LA DEMO ---------------------------------------------------

      final apresPrefs = <String, Object?>{
        for (final k in prefs.getKeys()) k: prefs.get(k),
      };
      expect(
        apresPrefs.keys.toSet(),
        avantPrefs.keys.toSet(),
        reason: 'une demo a cree ou retire une cle de preferences',
      );
      for (final k in avantPrefs.keys) {
        expect(
          apresPrefs[k],
          avantPrefs[k],
          reason: 'une demo a modifie la cle de preferences « $k »',
        );
      }

      expect(
        await db.select(db.hikerProfile).get(),
        avantProfils,
        reason: 'une demo a touche la table du profil',
      );
      expect(
        await db.select(db.pastHikeEntries).get(),
        avantRandos,
        reason: 'une demo a touche la table des randonnees passees',
      );

      // Et le randonneur retrouve EXACTEMENT ce qu il avait saisi.
      final profil = await c.read(hikerProfileRepositoryProvider).getProfile();
      expect(profil.age, 45);
      expect(
        (await c.read(healthInfoRepositoryProvider).get()).fullName,
        'Christophe',
      );
    });
  });

  group('760 — le cas reel n est pas abime', () {
    test('hors demo, le miroir Drift est alimente comme avant', () async {
      final c = conteneur();
      await c
          .read(hikerProfileRepositoryProvider)
          .saveProfile(profilDeLaRecette);
      final lignes = await db.select(db.hikerProfile).get();
      expect(lignes, hasLength(1));
      expect(lignes.single.age, 45);
    });

    test('hors demo, le depot construit sans barriere ecrit', () async {
      // Le constructeur d origine ne connait pas la demo : son comportement
      // doit etre strictement celui d avant ce lot.
      final depot = HikerProfileRepository(db: db);
      await depot.saveProfile(profilDeLaRecette);
      expect(await leDocumentDuProfilExiste(), isTrue);
      expect(await db.select(db.hikerProfile).get(), hasLength(1));
    });

    test('hors demo, une ligne de miroir se met a jour par upsert', () async {
      final depot = HikerProfileRepository(db: db);
      await depot.saveProfile(profilDeLaRecette);
      await depot.saveProfile(profilDeLaRecette.copyWith(weightKg: 72));
      final lignes = await db.select(db.hikerProfile).get();
      expect(lignes, hasLength(1));
      expect(lignes.single.weightKg, 72);
    });
  });

  group('760 — la photo du carnet n est plus ecrite avant la garde', () {
    test('la garde de demo PRECEDE l ecriture du fichier photo', () {
      // LE DEFAUT : la barriere du lot 634 etait UNE LIGNE TROP BAS. Elle
      // protegeait la base, pas le disque : `savePhotoFromFile` tournait
      // d'abord, donc chaque photo prise en demo laissait un JPEG orphelin
      // dans `journal_photos/` — jamais affiche, jamais compte, jamais efface.
      //
      // La garde est STRUCTURELLE parce que c'est un ORDRE qu'elle protege, et
      // qu'un ordre ne se lit pas dans un resultat : les deux versions rendent
      // `null` et ne touchent pas la base. Seule la place de la ligne differe.
      final lignes = lignesDe(
        'lib/features/journal/providers/journal_providers.dart',
      );
      final debut = lignes.indexWhere(
        (l) => l.contains('Future<PhotoError?> addPhotoNote('),
      );
      expect(debut, greaterThan(-1), reason: 'addPhotoNote a ete renommee');

      final corps = lignes.skip(debut).take(40).toList();
      final garde = corps.indexWhere(
        (l) => !estLigneDeCommentaire(l) && l.contains('enDemoProvider'),
      );
      final ecriture = corps.indexWhere(
        (l) => !estLigneDeCommentaire(l) && l.contains('savePhotoFromFile'),
      );

      expect(garde, greaterThan(-1), reason: 'la garde de demo a disparu');
      expect(ecriture, greaterThan(-1), reason: 'l ecriture a ete renommee');
      expect(
        garde,
        lessThan(ecriture),
        reason:
            'LA GARDE DE DEMO EST REPASSEE APRES L ECRITURE DU FICHIER : une '
            'photo prise en demo laisse un JPEG orphelin sur le telephone, la '
            'ou l application promet que rien n est enregistre.',
      );
    });
  });

  group('760 — le miroir reste joignable pour le cas reel', () {
    test(
      'une insertion directe reste visible (la table n est pas bridee)',
      () async {
        await db.hikerProfileDao.upsert(
          HikerProfileCompanion.insert(
            userId: 'local',
            age: const Value(45),
            updatedAt: DateTime(2026, 10, 9),
          ),
        );
        expect(await db.select(db.hikerProfile).get(), hasLength(1));
      },
    );
  });
}
