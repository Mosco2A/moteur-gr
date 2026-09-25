// TACHE 564 (LOT M, M1) — L'EFFACEMENT EMPORTE LE DISQUE, PAS LA MEMOIRE VIVE.
//
// CE QUE LA CAMPAGNE A MESURE (verdict #100501). Fiche randonneur enregistree,
// une randonnee passee saisie, puis Reglages > Mes donnees > Effacer. L'appli
// confirme « Vos donnees ont ete effacees » et repart a son premier lancement.
// Apres redemarrage, la fiche randonneur est VIDE — mais l'ecran « Vos 5
// dernieres randos » affiche TOUJOURS la randonnee saisie avant l'effacement, et
// le moteur de faisabilite rend encore un verdict.
//
// LA CAUSE, ET LA SIGNATURE QUI LA DESIGNE. Les deux ecrans ne lisent pas au
// meme endroit : la fiche randonneur relit le REPOSITORY a chaque ouverture
// (`hiker_profile_screen.dart` `_load()` -> `getProfile()`), donc elle voit le
// disque efface ; l'ecran des randos passees lit un PROVIDER RIVERPOD
// (`pastHikesProvider`) que l'effacement n'invalide jamais, donc il ressert son
// instantane d'avant l'effacement. C'est cette asymetrie — une fiche vide a cote
// d'une liste pleine, dans la meme session — qui prouve que le disque est propre
// et que c'est la memoire vive qui parle.
//
// ET CE N'EST PAS QU'UN AFFICHAGE. L'ecran des randos passees repart de cet
// instantane pour enregistrer (`_addOrEdit` lit `ref.read(pastHikesProvider)`
// puis `saveAll`) : ajouter une randonnee apres l'effacement REECRIT SUR LE
// DISQUE les randonnees effacees. La donnee effacee revient, durablement. C'est
// la « reecriture apres l'effacement » cherchee, et son declencheur est le cache.
//
// CE QUE CE FICHIER VERROUILLE :
//   1. LA CAUSE : apres l'effacement, le disque est vide ET le graphe de
//      providers deja chaud ne ressert plus rien.
//   2. LA CONSEQUENCE : plus aucune reecriture possible depuis un cache perime.
//   3. LE VERDICT : le moteur de faisabilite n'a plus de quoi juger.
//   4. LA PROMESSE, LIGNE A LIGNE : chaque element annonce par le dialogue
//      « Ce qui part » est verifie en memoire vive, pas seulement sur le disque.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/services/recovery_code_service.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/consent_service.dart';
import 'package:moteur_gr/core/providers/service_providers.dart';
import 'package:moteur_gr/features/booking/providers/nuitee_selections_provider.dart';
import 'package:moteur_gr/features/consent/providers/consent_ui_providers.dart';
import 'package:moteur_gr/features/journal/providers/journal_day_providers.dart';
import 'package:moteur_gr/features/journal/providers/journal_providers.dart';
import 'package:moteur_gr/features/trail/providers/progress_provider.dart';
import 'package:moteur_gr/features/feasibility/data/hiker_profile_repository.dart';
import 'package:moteur_gr/features/feasibility/domain/hiker_profile.dart';
import 'package:moteur_gr/features/feasibility/domain/past_hike.dart';
import 'package:moteur_gr/features/feasibility/domain/walk_test_result.dart';
import 'package:moteur_gr/features/feasibility/providers/hiker_profile_provider.dart';
import 'package:moteur_gr/features/feasibility/providers/trek_feasibility_provider.dart';
import 'package:moteur_gr/features/feasibility/providers/walk_test_provider.dart';
import 'package:moteur_gr/features/safety/domain/models/health_info.dart';
import 'package:moteur_gr/features/safety/presentation/health_info_screen.dart';
import 'package:moteur_gr/features/settings/providers/account_erasure_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  final randoSaisie = PastHike(
    date: DateTime.utc(2026, 9, 25),
    days: 2,
    avgWalkHoursPerDay: 5,
    totalElevationGain: 700,
    totalDistanceKm: 16,
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  tearDown(() async {
    await db.close();
  });

  /// Un graphe de providers branche sur la base REELLE de l'application (ici
  /// in-memory), comme en production : c'est la meme instance pour l'effacement
  /// et pour les ecrans, sinon le test ne prouverait rien.
  ProviderContainer chauffer() {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Saisit tout ce que le dialogue « Ce qui part » annonce et qui passe par la
  /// fiche randonneur, par le chemin REEL de l'application.
  Future<void> saisirLaFiche(ProviderContainer container) async {
    final repo = container.read(hikerProfileRepositoryProvider);
    await repo.saveProfile(const HikerProfile(
      age: 72,
      heightCm: 172,
      weightKg: 88,
      sex: 'male',
      countryIso: 'FR',
    ));
    await repo.savePastHikes([randoSaisie]);
    await repo.saveExperienceNote('genoux douloureux en descente');
    await repo.saveWalkTestResult(WalkTestResult(
      distanceMeters: 480,
      level: 'moyen',
      takenAt: DateTime.utc(2026, 9, 25),
    ));
  }

  group('M1 — la cause : le disque est propre, la memoire vive ne l etait pas',
      () {
    test('les randos passees ne sont plus SERVIES apres l effacement', () async {
      final container = chauffer();
      await saisirLaFiche(container);

      // L'ecran a ete ouvert AVANT l'effacement : le provider est chaud.
      expect(await container.read(pastHikesProvider.future), hasLength(1),
          reason: 'le test ne prouve rien si la rando n a pas ete saisie');

      await container.read(accountErasureProvider)();

      // Le disque : deja propre avant cette tache (verrouille par
      // data_retention_completeness_test).
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kHikerPastHikesPrefsKey), isNull,
          reason: 'la source durable des randos passees doit etre vide');

      // La memoire vive : c'est ICI que la campagne voyait la rando survivre.
      expect(await container.read(pastHikesProvider.future), isEmpty,
          reason: '« Vos 5 dernieres randos » resservait un cache perime');
    });

    test('la fiche randonneur et le test de marche ne sont plus servis non plus',
        () async {
      final container = chauffer();
      await saisirLaFiche(container);
      expect((await container.read(hikerProfileProvider.future)).age, 72);
      expect(await container.read(walkTestResultProvider.future), isNotNull);
      expect(await container.read(experienceNoteProvider.future), isNotEmpty);

      await container.read(accountErasureProvider)();

      expect((await container.read(hikerProfileProvider.future)).isEmpty, isTrue);
      expect(await container.read(walkTestResultProvider.future), isNull);
      expect(await container.read(experienceNoteProvider.future), isEmpty);
    });
  });

  group('M1 — la consequence : plus de reecriture depuis un cache perime', () {
    test('ajouter une rando APRES l effacement ne ressuscite pas les effacees',
        () async {
      final container = chauffer();
      await saisirLaFiche(container);
      await container.read(pastHikesProvider.future); // l'ecran a lu

      await container.read(accountErasureProvider)();

      // Le geste exact de l'ecran : il repart de ce que le provider lui rend,
      // puis persiste la liste entiere (`past_hikes_screen.dart` _addOrEdit).
      final avant = await container.read(pastHikesProvider.future);
      final nouvelle = PastHike(
        date: DateTime.utc(2026, 9, 26),
        days: 1,
        avgWalkHoursPerDay: 4,
        totalElevationGain: 300,
        totalDistanceKm: 9,
      );
      await container
          .read(pastHikesProvider.notifier)
          .saveAll([...avant, nouvelle]);

      final relues =
          await container.read(hikerProfileRepositoryProvider).loadPastHikes();
      expect(relues, hasLength(1),
          reason: 'la rando effacee est revenue SUR LE DISQUE par ce chemin');
      expect(relues.single.date, nouvelle.date);
    });
  });

  group('M1 — le moteur n a plus de quoi juger', () {
    test('les criteres du verdict retombent tous les trois a zero', () async {
      final container = chauffer();
      await saisirLaFiche(container);
      final avant = await container.read(feasibilityCriteriaProvider.future);
      expect(avant.doneCount, 3,
          reason: 'le moteur doit avoir de quoi juger AVANT l effacement');

      await container.read(accountErasureProvider)();

      final apres = await container.read(feasibilityCriteriaProvider.future);
      expect(apres.doneCount, 0,
          reason: 'le moteur rendait encore un verdict apres l effacement');
      expect(await container.read(hasObjectiveProfileProvider.future), isFalse);
    });
  });

  group('M1 — la promesse « Ce qui part », ligne a ligne, en memoire vive', () {
    test('les autorisations ne sont plus lues comme accordees', () async {
      final container = chauffer();
      final consent = await container.read(consentServiceReadyProvider.future);
      await consent.grant(ConsentPurpose.healthData);
      await consent.grant(ConsentPurpose.locationNavigation);
      // L'ecran Confidentialite a ete ouvert : il OBSERVE l'etat (sans auditeur,
      // un provider ne se rafraichit pas et le test ne mesurerait que sa propre
      // lecture).
      final sub = container.listen(consentStatesProvider, (_, __) {});
      addTearDown(sub.close);
      final avant = await container.read(consentStatesProvider.future);
      expect(avant[ConsentPurpose.healthData]!.granted, isTrue);

      await container.read(accountErasureProvider)();
      await pumpEventQueue();

      final apres = container.read(consentStatesProvider).value!;
      for (final purpose in ConsentPurpose.values) {
        expect(apres[purpose]!.granted, isFalse,
            reason: 'l autorisation « ${purpose.name} » restait accordee');
        expect(apres[purpose]!.decidedAt, isNull,
            reason: 'un consentement est un acte positif : il se re-demande');
      }
    });

    test('le journal n est plus servi', () async {
      final container = chauffer();
      final trailId = container.read(trailIdProvider);
      await container.read(journalRepositoryProvider).addNote(
            trailId: trailId,
            stageNumber: 3,
            text: 'orage au col, bivouac avance',
          );
      // L'ecran du journal a ete ouvert : son notifier charge et garde l'etat.
      final sub = container.listen(journalScreenProvider, (_, __) {});
      addTearDown(sub.close);
      await pumpEventQueue();
      expect(container.read(journalScreenProvider).entries, hasLength(1),
          reason: 'le test ne prouve rien si le journal etait vide');

      await container.read(accountErasureProvider)();
      await pumpEventQueue();

      expect(container.read(journalScreenProvider).entries, isEmpty,
          reason: 'le dialogue promet « votre journal »');
    });

    test('les etapes marchees ne sont plus servies', () async {
      final container = chauffer();
      final trailId = container.read(trailIdProvider);
      await db.progressDao.upsert(UserProgressEntriesCompanion.insert(
        trailId: trailId,
        currentStage: const Value(5),
        totalDistanceWalkedKm: const Value(82.4),
        totalElevationGainedM: const Value(4100),
      ));
      expect(await container.read(progressProvider(trailId).future), isNotNull,
          reason: 'le test ne prouve rien sans progression enregistree');

      await container.read(accountErasureProvider)();

      expect(await container.read(progressProvider(trailId).future), isNull,
          reason: 'le dialogue promet « vos etapes marchees »');
    });

    test('les nuitees choisies ne sont plus servies', () async {
      final container = chauffer();
      final trailId = container.read(trailIdProvider);
      await db.nuiteeSelectionsDao.setBooked(trailId, 2, true);
      final sub = container.listen(nuiteeSelectionsProvider, (_, __) {});
      addTearDown(sub.close);
      await pumpEventQueue();
      expect(container.read(nuiteeSelectionsProvider).bookings[2], isTrue,
          reason: 'le test ne prouve rien sans nuitee reservee');

      await container.read(accountErasureProvider)();
      await pumpEventQueue();

      expect(container.read(nuiteeSelectionsProvider).bookings, isEmpty,
          reason: 'le dialogue promet « vos nuitees »');
    });

    test('les traces GPS ne sont plus servies', () async {
      final container = chauffer();
      final trailId = container.read(trailIdProvider);
      // La trace affichee est celle de la JOURNEE SELECTIONNEE du journal, et
      // les journees selectionnables viennent des entrees du journal : sans
      // entree, aucun jour n'est selectionne et ce provider rend vide d'entree
      // de jeu — le test ne mesurerait alors rien du tout.
      final aujourdhui = DateTime.now();
      await container.read(journalRepositoryProvider).addNote(
            trailId: trailId,
            stageNumber: 4,
            text: 'longue journee, orage au col',
          );
      await db.sessionTrackPointsDao.insertPoint(
        trailId: trailId,
        lat: 42.1,
        lng: 9.2,
        altitude: 1420,
        recordedAt: aujourdhui,
      );
      final subJournal = container.listen(journalScreenProvider, (_, __) {});
      addTearDown(subJournal.close);
      final subTrace = container.listen(journalDayTraceProvider, (_, __) {});
      addTearDown(subTrace.close);
      await pumpEventQueue();
      expect(await container.read(journalDayTraceProvider.future), hasLength(1),
          reason: 'le test ne prouve rien si la trace n etait pas servie');

      await container.read(accountErasureProvider)();
      await pumpEventQueue();

      expect(await container.read(journalDayTraceProvider.future), isEmpty,
          reason: 'le dialogue promet « vos traces GPS »');
      expect((await db.sessionTrackPointsDao.getByTrailId(trailId)), isEmpty);
    });

    test('le code de reconnexion ne survit pas, et n est plus affiche non plus',
        () async {
      final container = chauffer();
      const storage = FlutterSecureStorage();
      await storage.write(key: RecoveryCodeService.storageKey, value: 'ABCD-1234');
      // L'ecran du code l'a affiche : le provider garde la valeur rendue. C'est
      // le piege de cette ligne de la promesse — on croit qu'un secret lu dans le
      // keystore n'est jamais en cache, et il l'est.
      expect(await container.read(recoveryCodeProvider.future), 'ABCD-1234',
          reason: 'le test ne prouve rien sans code affiche');

      final rapport = await container.read(accountErasureProvider)();

      expect(rapport.secureKeysDeleted, greaterThan(0));
      expect(await storage.read(key: RecoveryCodeService.storageKey), isNull,
          reason: 'le dialogue promet « votre code de reconnexion »');
      // L'ancien code ne doit plus etre servi. Ce qui est relu est un code NEUF
      // (la lecture est un `getOrCreate`) : ce qu'on exige, c'est qu'il soit
      // DIFFERENT — un randonneur ne doit pas pouvoir recopier un code efface.
      expect(await container.read(recoveryCodeProvider.future),
          isNot('ABCD-1234'),
          reason: 'l ancien code de reconnexion restait affiche');
    });

    test('la fiche de renseignement medical n est plus servie', () async {
      final container = chauffer();
      final repo = container.read(healthInfoRepositoryProvider);
      await repo.save(const HealthInfo(
        bloodType: 'A+',
        allergies: 'penicilline',
        treatments: 'inhalateur',
        doctorContact: 'Dr Rossi 04 95 00 00 00',
        insuranceNumber: 'FR-123456',
      ));
      final avant = await container.read(healthInfoProvider.future);
      expect(avant.hasData, isTrue,
          reason: 'le test ne prouve rien si la fiche medicale etait vide');

      await container.read(accountErasureProvider)();

      final apres = await container.read(healthInfoProvider.future);
      expect(apres.hasData, isFalse,
          reason: 'la fiche medicale restait affichee apres l effacement');
    });
  });

  // -------------------------------------------------------------------------
  // LA PROMESSE NE PEUT PLUS CHANGER SANS QUE LA PREUVE SUIVE
  // -------------------------------------------------------------------------
  //
  // Le groupe precedent prouve NEUF lignes, une par une. Rien n'empechait
  // jusqu'ici d'AJOUTER une dixieme ligne au dialogue — « et vos contacts
  // d'urgence », « et vos reservations » — sans ecrire la preuve qui va avec. Le
  // defaut de la journee est exactement celui-la : un texte qui promet plus que
  // le code ne tient. Ce test prend donc la promesse affichee au randonneur pour
  // CONTRAT : elle doit nommer ces neuf elements, dans les cinq langues, et
  // seulement eux. Toucher au texte fait echouer ce test, et le prochain
  // developpeur doit alors etendre la preuve avant de pouvoir livrer.
  group('la promesse affichee est le contrat, dans les cinq langues', () {
    /// Les neuf elements promis, et le mot par lequel chaque langue les nomme.
    /// L'ordre suit le texte ; l'index suit le groupe de tests ci-dessus.
    const promesse = <String, List<String>>{
      'fr': [
        'fiche randonneur',
        'test de marche',
        'renseignement médical',
        'randonnées passées',
        'journal',
        'étapes marchées',
        'nuitées',
        'traces GPS',
        'autorisations',
        'code de reconnexion',
      ],
      'en': [
        'hiker profile',
        'walk test',
        'medical information sheet',
        'past hikes',
        'journal',
        'stages you walked',
        'overnight stays',
        'GPS tracks',
        'permissions',
        'recovery code',
      ],
      'de': [
        'Wanderprofil',
        'Gehtest',
        'medizinisches Informationsblatt',
        'vergangenen Wanderungen',
        'Tagebuch',
        'gegangenen Etappen',
        'Übernachtungen',
        'GPS-Aufzeichnungen',
        'Einwilligungen',
        'Wiederherstellungscode',
      ],
      'es': [
        'ficha de senderista',
        'test de marcha',
        'información médica',
        'rutas pasadas',
        'diario',
        'etapas que has caminado',
        'pernoctaciones',
        'trazas GPS',
        'consentimientos',
        'código de recuperación',
      ],
      'it': [
        'scheda escursionista',
        'test del cammino',
        'informazioni mediche',
        'escursioni passate',
        'diario',
        'tappe percorse',
        'pernottamenti',
        'tracce GPS',
        'consensi',
        'codice di recupero',
      ],
    };

    tearDownAll(() => LocaleSettings.setLocaleRaw('fr'));

    for (final entree in promesse.entries) {
      test('« Ce qui part » (${entree.key}) ne promet que ce qui est prouve',
          () {
        LocaleSettings.setLocaleRaw(entree.key);
        final texte = t.erasure.goes;
        for (final element in entree.value) {
          expect(texte, contains(element),
              reason: 'la promesse ne nomme plus « $element » : si cet element '
                  'ne part plus, retirer aussi sa preuve ci-dessus');
        }
      });
    }

    // L'EMPREINTE. La liste de mots-cles ci-dessus attrape un RETRAIT, pas un
    // AJOUT : « et vos contacts d'urgence » glisse dans la meme phrase sans rien
    // faire echouer. On fige donc le texte de reference MOT POUR MOT. Toucher a
    // la promesse fait echouer ici, et le message dit quoi faire.
    test('le texte de reference (fr) est fige, mot pour mot', () {
      LocaleSettings.setLocaleRaw('fr');
      expect(
        t.erasure.goes,
        'Votre fiche randonneur (âge, taille, poids, test de marche), votre '
        'fiche de renseignement médical, vos randonnées passées et votre '
        'journal, vos étapes marchées, vos nuitées, vos traces GPS, vos '
        'autorisations et votre code de reconnexion.',
        reason: 'LA PROMESSE A CHANGE. Si un element a ete AJOUTE : ecrire sa '
            'preuve dans le groupe « ligne a ligne » ci-dessus, l ajouter aux '
            'mots-cles des cinq langues, puis mettre ce texte a jour. Si un '
            'element a ete RETIRE : retirer aussi sa preuve. Ne jamais mettre '
            'ce texte a jour seul — c est exactement le defaut que cette tache '
            'a corrige.',
      );
    });
  });
}
