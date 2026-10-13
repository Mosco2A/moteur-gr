import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/map/mbtiles_manager.dart';
import 'package:moteur_gr/features/feasibility/domain/hiker_profile.dart';
import 'package:moteur_gr/features/hub/providers/cockpit_start_providers.dart';
import 'package:moteur_gr/features/hub/providers/prepare_progress_providers.dart';
import 'package:moteur_gr/features/planning/data/retained_plan_store.dart';
import 'package:moteur_gr/features/safety/providers/health_prepare_providers.dart';
import 'package:moteur_gr/shared/widgets/step_status_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'coche_de_preparation_banc.dart';

/// LA COCHE DE PREPARATION, CALCULEE — LES CINQ RUBRIQUES AU SIGNAL PLUS PAUVRE,
/// LES TROIS SANS COCHE, ET L'EQUIVALENCE AVEC LA PORTE « DEMARRER ».
///
/// Chaque rubrique est nourrie par SA VRAIE SOURCE PERSISTEE, fabriquee ici :
/// preferences simulees pour les signaux en preferences, base Drift EN MEMOIRE
/// pour le sac et les nuitees, dossier temporaire pour la carte hors ligne.
/// Rien n'est pose a la main dans le calculateur : si une source change de
/// forme, c'est ce fichier qui rougit, pas l'ecran de Christophe.
///
/// Pour chaque rubrique : le cas VIDE (rien de persiste), le cas PARTIEL et le
/// cas COMPLET. Les rubriques a deux etats le disent, et les trois rubriques
/// sans source le prouvent : pas de coche, jamais.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final banc = BancDeCoche();
  final trailId = banc.trailId;
  ProviderContainer conteneur({
    HikerProfile profil = HikerProfile.empty,
    List<Override> plus = const [],
  }) => banc.conteneur(profil: profil, plus: plus);
  Future<PlanningStepStatus?> coche(
    ProviderContainer c,
    SujetDePreparation s,
  ) => banc.coche(c, s);

  group('FAISABILITE — la fiche profil sur laquelle repose le verdict', () {
    test('VIDE : fiche vide -> a faire', () async {
      expect(
        await coche(conteneur(), SujetDePreparation.faisabilite),
        PlanningStepStatus.notStarted,
      );
    });

    test('PARTIEL : taille et poids sans age -> entame', () async {
      final c = conteneur(
        profil: const HikerProfile(heightCm: 172, weightKg: 70),
      );
      expect(
        await coche(c, SujetDePreparation.faisabilite),
        PlanningStepStatus.inProgress,
      );
    });

    test('COMPLET : age, taille, poids -> fait', () async {
      final c = conteneur(
        profil: const HikerProfile(age: 44, heightCm: 172, weightKg: 70),
      );
      expect(
        await coche(c, SujetDePreparation.faisabilite),
        PlanningStepStatus.completed,
      );
    });
  });

  group('PROGRAMME — ouvert, ou seulement une duree retenue', () {
    test('VIDE : rien -> a faire', () async {
      expect(
        await coche(conteneur(), SujetDePreparation.programme),
        PlanningStepStatus.notStarted,
      );
    });

    test('PARTIEL : une duree retenue en Faisabilite, Programme jamais ouvert '
        '-> entame', () async {
      SharedPreferences.setMockInitialValues({
        retainedDurationPrefsKey(trailId): 9,
      });
      expect(
        await coche(conteneur(), SujetDePreparation.programme),
        PlanningStepStatus.inProgress,
      );
    });

    test('COMPLET : ecran Programme ouvert -> fait', () async {
      SharedPreferences.setMockInitialValues({
        'prepare_core_steps_$trailId': ['programme'],
      });
      expect(
        await coche(conteneur(), SujetDePreparation.programme),
        PlanningStepStatus.completed,
      );
    });
  });

  group('DEUX ETATS SEULEMENT — Itineraire et Calendrier', () {
    test('ITINERAIRE : jamais ouvert -> a faire, ouvert -> fait', () async {
      expect(
        await coche(conteneur(), SujetDePreparation.itineraire),
        PlanningStepStatus.notStarted,
      );
      SharedPreferences.setMockInitialValues({
        'prepare_core_steps_$trailId': ['itinerary'],
      });
      expect(
        await coche(conteneur(), SujetDePreparation.itineraire),
        PlanningStepStatus.completed,
      );
    });

    test('CALENDRIER : pas de date -> a faire, date posee -> fait', () async {
      expect(
        await coche(conteneur(), SujetDePreparation.calendrier),
        PlanningStepStatus.notStarted,
      );
      SharedPreferences.setMockInitialValues({
        'departure_date_$trailId': '2031-06-01T00:00:00.000',
      });
      expect(
        await coche(conteneur(), SujetDePreparation.calendrier),
        PlanningStepStatus.completed,
      );
    });
  });

  group('CARTES HORS LIGNE — le fichier sur le telephone', () {
    late Directory dossier;
    late MBTilesManager cartes;

    setUp(() async {
      dossier = await Directory.systemTemp.createTemp('coche_cartes_');
      cartes = MBTilesManager(dossierDocuments: () async => dossier);
    });

    tearDown(() => dossier.delete(recursive: true));

    ProviderContainer avecDisque() =>
        conteneur(plus: [mbtilesManagerProvider.overrideWithValue(cartes)]);

    test('VIDE : aucun fichier -> a faire', () async {
      expect(
        await coche(avecDisque(), SujetDePreparation.cartesHorsLigne),
        PlanningStepStatus.notStarted,
      );
    });

    test('PARTIEL : une descente interrompue -> entame', () async {
      await File(await cartes.cheminPartiel(trailId)).writeAsBytes([1, 2, 3]);
      expect(
        await coche(avecDisque(), SujetDePreparation.cartesHorsLigne),
        PlanningStepStatus.inProgress,
      );
    });

    test('COMPLET : la carte sous son nom definitif -> fait', () async {
      await File(await cartes.getMbtilesPath(trailId)).writeAsBytes([1]);
      expect(
        await coche(avecDisque(), SujetDePreparation.cartesHorsLigne),
        PlanningStepStatus.completed,
      );
    });

    test('le cockpit relit le disque quand on l invalide', () async {
      final c = avecDisque();
      expect(
        await coche(c, SujetDePreparation.cartesHorsLigne),
        PlanningStepStatus.notStarted,
      );
      await File(await cartes.getMbtilesPath(trailId)).writeAsBytes([1]);
      c.invalidate(cartesSurLeTelephoneProvider(trailId));
      expect(
        await coche(c, SujetDePreparation.cartesHorsLigne),
        PlanningStepStatus.completed,
      );
    });
  });

  group('RIEN DE PERSISTE -> PAS DE COCHE, quoi qu il arrive', () {
    for (final sujet in [
      SujetDePreparation.transport,
      SujetDePreparation.ravitaillement,
      SujetDePreparation.resume,
    ]) {
      test('${sujet.name} : jamais de coche', () async {
        expect(await coche(conteneur(), sujet), isNull);
      });
    }
  });

  group('LA PORTE « DEMARRER » ET LES QUATRE COCHES DISENT LA MEME CHOSE', () {
    // Les seize combinaisons des quatre signaux de la porte : elle est ouverte
    // EXACTEMENT quand Itineraire, Programme, Calendrier et Fiche medicale
    // sont tous coches « fait ». Deux lectures du meme fait ne divergent pas.
    for (var masque = 0; masque < 16; masque++) {
      final itineraire = masque & 1 != 0;
      final programme = masque & 2 != 0;
      final date = masque & 4 != 0;
      final fiche = masque & 8 != 0;
      test('itineraire=$itineraire programme=$programme date=$date '
          'fiche=$fiche', () async {
        SharedPreferences.setMockInitialValues({
          'prepare_core_steps_$trailId': [
            if (itineraire) 'itinerary',
            if (programme) 'programme',
          ],
          if (date) 'departure_date_$trailId': '2031-06-01T00:00:00.000',
          if (fiche) kHealthPrepareStepsKey: ['filled', 'adviceRead'],
        });
        final c = conteneur();
        final coches = [
          for (final s in [
            SujetDePreparation.itineraire,
            SujetDePreparation.programme,
            SujetDePreparation.calendrier,
            SujetDePreparation.ficheMedicale,
          ])
            await coche(c, s),
        ];
        final porte = c.read(prepareCoreDoneProvider(trailId));
        expect(
          coches.every((s) => s == PlanningStepStatus.completed),
          porte,
          reason: 'coches $coches, porte $porte',
        );
      });
    }
  });
}
