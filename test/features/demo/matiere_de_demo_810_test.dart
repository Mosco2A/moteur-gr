/// TACHE 810 — EN DEMO, TOUT SE VOIT, RIEN NE S'ECRIT.
///
/// LA LOI, POSEE PAR CHRISTOPHE LE 11/10/2026 A 09:27, verbatim : « tu rends
/// accessible le faux journal er le faux recap oui . Demo = toutes les
/// fonctionalite visible mais bouchonnees ».
///
/// CE QUE CE FICHIER PROUVE, ET DANS CET ORDRE :
///   (A) la matiere fabriquee est PURE et DETERMINISTE — c'est la propriete qui
///       permet au carnet et au recapitulatif de s'accorder sans se parler ;
///   (B) ses chiffres sont CEUX DU SENTIER, additionnes, non des constantes ;
///   (C) les pages du carnet nomment les vraies etapes et ne portent AUCUN
///       fichier ;
///   (D) LA PREUVE DEMANDEE PAR LA TACHE : en demonstration tout s'ouvre, et a
///       la sortie il ne reste RIEN — ni a l'ecran, ni en base.
///
/// LE GROUPE (D) N'UTILISE AUCUNE SURCHARGE DE `enDemoProvider`. Il entre et
/// sort de la demonstration par le VRAI mecanisme (`sessionDemoProvider`,
/// `entrer()` / `sortir()`), sur le VRAI sentier de demonstration : une preuve
/// obtenue en forcant le drapeau ne prouverait rien du chemin reel.
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/core/data/daos/session_track_points_dao.dart';
// `Stage` est masque : la base Drift en expose une, et c'est le modele de
// DOMAINE qu'on fabrique ici (meme levee d'ambiguite que dans
// `adventure_recap_provider.dart`).
import 'package:moteur_gr/core/data/database.dart' hide Stage;
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage_duration.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/providers/service_providers.dart';
import 'package:moteur_gr/core/services/demo_mode_service.dart';
import 'package:moteur_gr/core/services/session_demo.dart';
import 'package:moteur_gr/domain/matiere_de_demo.dart';
import 'package:moteur_gr/domain/stage.dart';
import 'package:moteur_gr/domain/trek_session_mapping.dart';
import 'package:moteur_gr/features/after/providers/adventure_recap_provider.dart';
import 'package:moteur_gr/features/journal/providers/journal_providers.dart';
import 'package:moteur_gr/features/planning/providers/trek_edit_lock_provider.dart';
import 'package:moteur_gr/features/trek/providers/stage_providers.dart';

void main() {
  // LE VRAI SENTIER DE DEMONSTRATION, et pas un sentier de test : `entrer()`
  // n'accepte que celui-la (refus silencieux pour tout autre, cf.
  // `SessionDemoNotifier.entrer`). Un identifiant invente aurait fait passer
  // les tests du groupe (D) sans jamais entrer en demonstration.
  final trailId = kSentierDeDemo;

  // Quatre etapes aux chiffres RONDS et VOLONTAIREMENT differents des totaux
  // declares par le sentier : si la matiere lisait les totaux au lieu
  // d'additionner les etapes, (B) le verrait.
  final config = TrailConfig(
    id: trailId,
    name: 'Demo Trail',
    displayName: 'Demo Trail',
    tagline: 'tagline',
    totalStages: 4,
    totalDistanceKm: 999.0,
    totalElevationGain: 99999,
    region: 'Region',
    country: 'France',
    primaryColorValue: 0xFF2E7D32,
    secondaryColorValue: 0xFF1565C0,
    gpxAssetPath: 'assets/gpx/test.gpx',
    defaultDuration: 4,
    availableDurations: const [2, 4, 6],
  );

  /// Une etape de domaine, pour les tests PURS des groupes (A) a (C).
  Stage etape(int n) => Stage(
    id: 'etape-$n',
    nameFr: 'Depart $n - Arrivee $n',
    nameEn: 'Start $n to Finish $n',
    distance: 10.0,
    elevationGain: 500,
    elevationLoss: 400,
    orderIndex: n,
    startLat: 42.0,
    startLng: 9.0,
    endLat: 42.1,
    endLng: 9.1,
  );

  List<Stage> etapes(int combien) => [
    for (var n = 1; n <= combien; n++) etape(n),
  ];

  MatiereDeDemo matiere({int combien = 7, DateTime? arriveeLe}) =>
      MatiereDeDemo.pourSentier(
        trailId: trailId,
        etapes: etapes(combien),
        arriveeLe: arriveeLe ?? DateTime(2026, 10, 11, 18, 42),
      );

  // -------------------------------------------------------------------------
  group('(A) LA MATIERE FABRIQUEE EST PURE ET DETERMINISTE', () {
    test('sept etapes font sept journees, une par etape, dans l ordre', () {
      final m = matiere();
      expect(m.journees.length, 7);
      expect(m.estVide, isFalse);
      for (var i = 0; i < 7; i++) {
        final JourneeFabriquee j = m.journees[i];
        expect(j.numero, i + 1, reason: 'le jour 1 est le jour du depart');
        expect(j.etape.id, 'etape-${i + 1}');
      }
    });

    test('la session fabriquee est terminee, finisher, et porte tout', () {
      final m = matiere();
      expect(m.session.status, kTrekStatusTermine);
      expect(m.session.parcoursFullyWalked, isTrue);
      expect(m.session.completedStages.length, 7);
      expect(m.session.trailId, trailId);
      expect(m.session.id, MatiereDeDemo.idSessionFabriquee);
      expect(m.session.finishedAt, isNotNull);
    });

    test('le calendrier remonte depuis le jour d arrivee', () {
      final m = matiere(arriveeLe: DateTime(2026, 10, 11, 18, 42));
      // Derniere journee = le jour d arrivee, ramene a minuit.
      expect(m.dernierJour, DateTime(2026, 10, 11));
      // Sept journees, donc le depart six jours plus tot.
      expect(m.premierJour, DateTime(2026, 10, 5));
      // Une journee de marche commence a l heure dite, et finit plus tard.
      final premiere = m.journees.first;
      expect(premiere.depart, DateTime(2026, 10, 5, 7, 30));
      expect(premiere.arrivee.isAfter(premiere.depart), isTrue);
      // Sans duree declaree par l etape, la REGLE DE MARCHE DU DEPOT decide :
      // 10 km / 4 km/h + 500 m / 400 m/h = 2 h 30 + 1 h 15 = 3 h 45.
      expect(premiere.duree, const Duration(hours: 3, minutes: 45));
      expect(
        premiere.duree,
        Duration(
          minutes: estimatedStageDurationMinutes(
            distanceKm: premiere.etape.distance,
            elevationGainM: premiere.etape.elevationGain,
          ),
        ),
      );
    });

    test('la regle de marche rend les durees declarees par le sentier', () {
      // CE QUI REND LA DUREE FABRIQUEE JUSTE, ET NON FORFAITAIRE. Le mappeur du
      // depot ne recopie pas la duree des etapes, donc la matiere la recalcule.
      // Ce cas verifie que le recalcul retombe sur la donnee REELLE du Mare a
      // Mare Centre : 457 minutes pour sa premiere etape (19,9 km, 1 058 m de
      // D+), 175 pour sa derniere (11,1 km, 54 m). Si la regle de marche du
      // depot changeait, les durees de la demonstration cesseraient de coller
      // au sentier, et ce cas le dirait.
      expect(
        estimatedStageDurationMinutes(distanceKm: 19.9, elevationGainM: 1058),
        457,
      );
      expect(
        estimatedStageDurationMinutes(distanceKm: 11.1, elevationGainM: 54),
        175,
      );
    });

    test('deux fabrications du meme jour sont identiques', () {
      // C EST LA PROPRIETE QUI FAIT TENIR TOUT LE LOT. Le carnet et le
      // recapitulatif fabriquent CHACUN leur matiere, sans se parler et sans
      // facade : si deux appels a quelques secondes d intervalle donnaient deux
      // calendriers differents, le carnet nommerait des journees que le
      // recapitulatif ignore.
      final a = matiere(arriveeLe: DateTime(2026, 10, 11, 0, 0, 1));
      final b = matiere(arriveeLe: DateTime(2026, 10, 11, 23, 59, 59));
      expect(a.premierJour, b.premierJour);
      expect(a.dernierJour, b.dernierJour);
      expect(a.session.startedAt, b.session.startedAt);
      expect(a.session.finishedAt, b.session.finishedAt);
      expect(a.session.completedStages, b.session.completedStages);
      for (var i = 0; i < a.journees.length; i++) {
        expect(a.journees[i].jour, b.journees[i].jour);
        expect(a.journees[i].depart, b.journees[i].depart);
      }
    });

    test('sans etape, la matiere est vide et ne felicite personne', () {
      final m = MatiereDeDemo.pourSentier(
        trailId: trailId,
        etapes: const <Stage>[],
        arriveeLe: DateTime(2026, 10, 11),
      );
      expect(m.estVide, isTrue);
      expect(m.journees, isEmpty);
      expect(m.premierJour, isNull);
      expect(m.dernierJour, isNull);
      expect(m.session.parcoursFullyWalked, isFalse);
      expect(m.session.completedStages, isEmpty);
      expect(m.session.finishedAt, isNull);
    });

    test('les identifiants fabriques sont negatifs, jamais de la base', () {
      // Une cle Drift auto-incrementee vaut 1 ou plus : un identifiant negatif
      // ne peut designer qu une page fabriquee, et ne collisionne jamais.
      for (var rang = 1; rang <= 7; rang++) {
        expect(MatiereDeDemo.idEntreeFabriquee(rang), lessThan(0));
      }
      expect(MatiereDeDemo.idSessionFabriquee, contains('demo'));
    });
  });

  // -------------------------------------------------------------------------
  group('(B) LES CHIFFRES SONT CEUX DU SENTIER, ADDITIONNES', () {
    test('la matiere ne porte aucun chiffre en dur', () {
      final m = matiere();
      // Quatre etapes de 10 km feraient 40 km ; sept en font 70. Le sentier
      // declare 999 km : si la matiere lisait le total declare, on le verrait.
      final km = m.journees.fold<double>(0, (a, j) => a + j.etape.distance);
      final dPlus = m.journees.fold<int>(
        0,
        (a, j) => a + j.etape.elevationGain,
      );
      final dMoins = m.journees.fold<int>(
        0,
        (a, j) => a + j.etape.elevationLoss,
      );
      expect(km, 70.0);
      expect(dPlus, 3500);
      expect(dMoins, 2800);
      expect(km, isNot(config.totalDistanceKm));
      expect(dPlus, isNot(config.totalElevationGain));
    });

    test('le statut termine est le meme des deux cotes de la frontiere', () {
      // `lib/domain/` ne peut pas lire `lib/features/after/` (plafond a zero,
      // cf. couches_respectees_645_test.dart), donc la constante est repetee.
      // CETTE GARDE EXISTE POUR QUE LA REPETITION NE DERIVE PAS EN SILENCE :
      // si l un des deux changeait, le recapitulatif se refermerait en
      // demonstration sans qu aucun autre test ne le dise.
      expect(kTrekStatusTermine, kTrekStatusCompleted);
    });
  });

  // -------------------------------------------------------------------------
  group('(C) LES PAGES DU CARNET', () {
    test('une page par journee, et chacune nomme son etape', () {
      final m = matiere();
      final pages = pagesFabriqueesDuCarnet(m, langue: 'fr');
      expect(pages.length, 7);
      for (var i = 0; i < pages.length; i++) {
        final etapeDuJour = m.journees[i].etape;
        expect(pages[i].text, contains(etapeDuJour.nameFr));
        expect(pages[i].stageNumber, etapeDuJour.orderIndex);
        expect(pages[i].trailId, trailId);
        expect(pages[i].createdAt, m.journees[i].arrivee);
        expect(pages[i].id, lessThan(0));
      }
    });

    test('la langue choisie est celle des noms d etape', () {
      final m = matiere();
      final fr = pagesFabriqueesDuCarnet(m, langue: 'fr');
      final en = pagesFabriqueesDuCarnet(m, langue: 'en');
      expect(fr.first.text, contains('Depart 1 - Arrivee 1'));
      expect(en.first.text, contains('Start 1 to Finish 1'));
    });

    test('un carnet de sept jours ne lit pas sept fois la meme phrase', () {
      final m = matiere();
      final pages = pagesFabriqueesDuCarnet(m, langue: 'fr');
      // On compare les phrases DEBARRASSEES du nom d etape : ce qui doit
      // varier, c est le modele de note, pas seulement le lieu.
      final modeles = <String>{
        for (var i = 0; i < pages.length; i++)
          pages[i].text.replaceAll(m.journees[i].etape.nameFr, '{}'),
      };
      expect(modeles.length, greaterThan(1));
    });

    test('aucune page fabriquee ne porte de fichier', () {
      // Une page avec photo porte un CHEMIN : la fabriquer obligerait a ecrire
      // un fichier sur le telephone, ce que la demonstration promet de ne pas
      // faire.
      for (final page in pagesFabriqueesDuCarnet(matiere(), langue: 'fr')) {
        expect(page.photoPath, isNull);
        expect(page.photoSizeBytes, isNull);
      }
    });
  });

  // -------------------------------------------------------------------------
  group('(D) EN DEMO TOUT S OUVRE, ET A LA SORTIE IL NE RESTE RIEN', () {
    late AppDatabase db;

    StagesCompanion ligneEtape(int n) => StagesCompanion(
      trailId: Value(trailId),
      stageNumber: Value(n),
      name: Value('Depart $n - Arrivee $n'),
      distanceKm: const Value(10.0),
      elevationGainM: const Value(500),
      elevationLossM: const Value(400),
      description: const Value('desc'),
      startLat: const Value(42.0),
      startLng: const Value(9.0),
      endLat: const Value(42.1),
      endLng: const Value(9.1),
      difficulty: const Value('moderate'),
    );

    ProviderContainer conteneur() => ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        trailConfigProvider.overrideWithValue(config),
        currentTrailIdProvider.overrideWith((ref) => trailId),
        demoModeServiceProvider.overrideWithValue(DemoModeService()),
      ],
    );

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      await db.stagesDao.insertAll([
        ligneEtape(1),
        ligneEtape(2),
        ligneEtape(3),
        ligneEtape(4),
      ]);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'hors demo et sans session : tout est ferme, et c est normal',
      () async {
        final c = conteneur();
        addTearDown(c.dispose);

        expect(c.read(enDemoProvider), isFalse);
        await c.read(latestTrekSessionProvider.future);
        expect(c.read(isRecapAvailableProvider), isFalse);
        expect(c.read(isDiplomaUnlockedProvider), isFalse);
      },
    );

    test('en demo : le recapitulatif et le diplome s ouvrent', () async {
      final c = conteneur();
      addTearDown(c.dispose);

      c.read(sessionDemoProvider.notifier).entrer();
      expect(
        c.read(enDemoProvider),
        isTrue,
        reason: 'entrer() n accepte que le sentier de demonstration',
      );

      final session = await c.read(latestTrekSessionProvider.future);
      expect(session, isNotNull);
      expect(session!.id, MatiereDeDemo.idSessionFabriquee);
      expect(c.read(isRecapAvailableProvider), isTrue);
      expect(c.read(isDiplomaUnlockedProvider), isTrue);

      // Les chiffres sont la somme des QUATRE etapes seedees, pas les totaux
      // absurdes declares par le sentier.
      final stats = await c.read(adventureStatsProvider.future);
      expect(stats.stagesWalked, 4);
      expect(stats.distanceKm, 40.0);
      expect(stats.elevationGainM, 2000);
      expect(stats.elevationLossM, 1600);
      expect(stats.fullyWalked, isTrue);
      expect(stats.distanceKm, isNot(config.totalDistanceKm));
    });

    test('en demo : le carnet porte ses pages fabriquees', () async {
      final c = conteneur();
      addTearDown(c.dispose);

      // Avant d entrer, le carnet est vide : rien n a jamais ete ecrit.
      expect(c.read(journalScreenProvider).entries, isEmpty);

      c.read(sessionDemoProvider.notifier).entrer();
      // Les etapes doivent etre chargees pour que la matiere naisse.
      await c.read(latestTrekSessionProvider.future);

      final pages = c.read(journalScreenProvider).entries;
      expect(pages.length, 4, reason: 'une page par etape seedee');
      expect(c.read(journalScreenProvider).isLoading, isFalse);
      for (final page in pages) {
        expect(page.id, lessThan(0), reason: 'fabriquee, donc reconnaissable');
        expect(page.photoPath, isNull);
      }
      // L ajout de photo reste ferme : le carnet est une vitrine.
      expect(c.read(journalScreenProvider).canAddPhoto, isFalse);
    });

    test('A LA SORTIE : plus rien a l ecran, et RIEN EN BASE', () async {
      final c = conteneur();
      addTearDown(c.dispose);

      // 1. On entre, et tout s ouvre.
      c.read(sessionDemoProvider.notifier).entrer();
      await c.read(latestTrekSessionProvider.future);
      expect(c.read(isRecapAvailableProvider), isTrue);
      expect(c.read(isDiplomaUnlockedProvider), isTrue);
      expect(c.read(journalScreenProvider).entries, isNotEmpty);

      // 2. On sort.
      c.read(sessionDemoProvider.notifier).sortir();
      expect(c.read(enDemoProvider), isFalse);

      // 3. L ECRAN : tout est redevenu ce qu il etait.
      await c.read(latestTrekSessionProvider.future);
      expect(
        c.read(isRecapAvailableProvider),
        isFalse,
        reason: 'le recapitulatif se referme avec la demonstration',
      );
      expect(c.read(isDiplomaUnlockedProvider), isFalse);
      expect(
        c.read(journalScreenProvider).entries,
        isEmpty,
        reason: 'les pages fabriquees meurent avec la demonstration',
      );

      // 4. LA BASE : elle n a RIEN recu. C est la preuve demandee par la
      //    tache — on interroge le telephone, pas les providers.
      expect(
        await db.trekSessionsDao.getLatestByTrailId(trailId),
        isNull,
        reason: 'aucune session de demonstration n a ete persistee',
      );
      expect(
        await c.read(journalRepositoryProvider).getByTrailId(trailId),
        isEmpty,
        reason: 'aucune page de demonstration n a ete ecrite',
      );
      expect(
        await db.sessionTrackPointsDao.getByTrailId(
          trailId,
          read: TrackPointsRead.withEstimated,
        ),
        isEmpty,
        reason: 'aucun point de la trace fabriquee n a ete ecrit',
      );
    });

    test('la matiere fabriquee ne verrouille pas le programme', () async {
      // LA MATIERE EST FAITE POUR ETRE MONTREE, PAS POUR CONTRAINDRE. La
      // session fabriquee est terminee et porte TOUTES les etapes : lue par le
      // verrou d edition du programme, elle aurait ferme l edition de chacune,
      // et le visiteur aurait trouve un programme en lecture seule sans avoir
      // rien marche (cf. `trek_edit_lock_provider.dart`).
      final c = conteneur();
      addTearDown(c.dispose);

      c.read(sessionDemoProvider.notifier).entrer();
      await c.read(latestTrekSessionProvider.future);
      // La session fabriquee existe bien, et elle porte ses etapes.
      expect(c.read(latestTrekSessionProvider).value, isNotNull);
      expect(
        c.read(latestTrekSessionProvider).value!.completedStages,
        isNotEmpty,
      );
      // Et pourtant le programme reste entierement editable.
      final verrou = c.read(trekEditLockProvider);
      expect(verrou.trekStarted, isFalse);
      expect(verrou.doneStageIds, isEmpty);
    });

    test('rentrer en demo refabrique une matiere neuve', () async {
      // Riverpod ne recalcule pas un provider dont la dependance a retrouve sa
      // valeur precedente : sortir puis rentrer rend `true` apres `true`. Sans
      // `generationDeDemoProvider`, la matiere de la demonstration precedente
      // serait resservie (cf. l en-tete de `session_demo.dart`).
      final c = conteneur();
      addTearDown(c.dispose);

      c.read(sessionDemoProvider.notifier).entrer();
      await c.read(latestTrekSessionProvider.future);
      final premiere = c.read(generationDeDemoProvider);
      expect(c.read(journalScreenProvider).entries, isNotEmpty);

      c.read(sessionDemoProvider.notifier).sortir();
      await c.read(latestTrekSessionProvider.future);

      c.read(sessionDemoProvider.notifier).entrer();
      await c.read(latestTrekSessionProvider.future);
      expect(c.read(generationDeDemoProvider), greaterThan(premiere));
      expect(c.read(journalScreenProvider).entries, isNotEmpty);
      expect(c.read(isRecapAvailableProvider), isTrue);
    });
  });
}
