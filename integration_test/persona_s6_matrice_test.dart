// ignore_for_file: avoid_print
//
// S6 — LA MATRICE SUR LE PRODUIT REEL (famille 1). REECRIT — tache 543.
//
// POURQUOI CE FICHIER EST REECRIT DE ZERO. L'ancien `persona_s6_matrice_test.dart`
// a tourne le 21/09 mais n'a JAMAIS ete verse : absent du depot, de toutes les
// branches, du stash et du disque. Il est perdu.
//
// CE QU'IL PROUVE, ET CE QU'IL NE PROUVE PAS.
//   * `test/features/feasibility/campagne_v2_matrice_test.dart` prouve que LE
//     MOTEUR calcule ce que dit la spec, sur les 96 combinaisons.
//   * CE FICHIER-CI prouve que LE PRODUIT REEL — fiche d'info, randos passees,
//     test de marche, providers de production — arrive AU MEME RESULTAT que la
//     matrice, sur le sentier que l'application embarque vraiment.
// Les deux se chainent : la spec au moteur, le moteur au produit.
//
// PERIMETRE : les 24 cellules du jeu J1 (6 personnages x 4 rangs de forme).
// J2, J3 et J4 sont des jeux d'etapes que l'application NE CHARGE PAS — ils
// restent couverts au niveau du moteur, et c'est la bonne place pour eux. On ne
// fabrique pas un faux sentier dans l'app pour faire du chiffre.
//
// CE QUI EST EXIGE ICI, ET CE QUI EST SEULEMENT ENREGISTRE.
//   EXIGE   : le niveau derive, les 7 verdicts d'etape, et C1 (la pire etape).
//             Aucun de ces trois ne depend des jours de repos.
//   ENREGISTRE, PAS EXIGE : le verdict de CIRCUIT et C3. La colonne C3 de la
//             matrice a ete calculee AVANT que les jours de repos ne remontent
//             au moteur : c'est un ARTEFACT declare (`meta.C3_PROVISOIRE`).
//             Exiger une valeur qu'on sait fausse serait enregistrer un faux.
//             On IMPRIME donc la valeur reelle, ligne `PERSONA_MATRICE_C3`,
//             pour que la re-mesure parte de donnees et non d'un recalcul.
//
// AUCUN `overrideWith` : tout passe par les VRAIS notifiers, le meme chemin que
// les formulaires. Un provider surcharge ne prouve rien du produit.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moteur_gr/features/feasibility/data/hiker_profile_repository.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_formula.dart';
import 'package:moteur_gr/features/feasibility/domain/hiker_profile.dart';
import 'package:moteur_gr/features/feasibility/domain/past_hike.dart';
import 'package:moteur_gr/features/feasibility/domain/walk_test_norms.dart';
import 'package:moteur_gr/features/feasibility/domain/walk_test_result.dart';
import 'package:moteur_gr/features/feasibility/providers/hiker_profile_provider.dart';
import 'package:moteur_gr/features/feasibility/providers/trek_feasibility_provider.dart';
import 'package:moteur_gr/features/feasibility/providers/walk_test_provider.dart';
import 'package:moteur_gr/features/notifications/providers/download_reminder_provider.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/main.dart' as app;

import 'persona_harness.dart';

const String P = 'S6_Matrice';

/// Tolerance de comparaison (la matrice est arrondie a 1e-4).
const double kEps = 5e-4;

/// Une cellule de la matrice, telle que `matrice_96.json` la fige.
class _Cellule {
  const _Cellule(
    this.id,
    this.persona,
    this.rangForme,
    this.age,
    this.tailleCm,
    this.poidsKg,
    this.sexe,
    this.randoJours,
    this.randoKm,
    this.randoDplus,
    this.moisDepart,
    this.niveauAttendu,
    this.verdictsEtapeAttendus,
    this.c1Attendu,
  );

  final String id;
  final String persona;
  final int rangForme;
  final int age;
  final int tailleCm;
  final double poidsKg;
  final String sexe;
  final int randoJours;
  final double randoKm;
  final int randoDplus;
  final int moisDepart;
  final String niveauAttendu;
  final List<String> verdictsEtapeAttendus;
  final double c1Attendu;
}

/// Les 24 cellules du jeu J1, GENEREES depuis `matrice_96.json` (tache 541).
/// Ne pas les retoucher a la main : elles doivent rester le miroir du JSON.
// ignore: library_private_types_in_public_api
const List<_Cellule> kCellulesJ1 = <_Cellule>[
  _Cellule('P1-J1-R0', 'Marc', 0, 28, 178, 72.0, 'male', 12, 180.0, 10000, 6, 'beginner', <String>['orange', 'green', 'green', 'green', 'orange', 'green', 'green'], 1.0875),
  _Cellule('P1-J1-R1', 'Marc', 1, 28, 178, 72.0, 'male', 12, 180.0, 10000, 6, 'intermediate', <String>['orange', 'green', 'green', 'green', 'green', 'green', 'green'], 0.9799),
  _Cellule('P1-J1-R2', 'Marc', 2, 28, 178, 72.0, 'male', 12, 180.0, 10000, 6, 'intermediate', <String>['orange', 'green', 'green', 'green', 'green', 'green', 'green'], 0.9799),
  _Cellule('P1-J1-R3', 'Marc', 3, 28, 178, 72.0, 'male', 12, 180.0, 10000, 6, 'confirmed', <String>['green', 'green', 'green', 'green', 'green', 'green', 'green'], 0.6818),
  _Cellule('P2-J1-R0', 'Lea', 0, 34, 165, 58.0, 'female', 1, 9.0, 200, 9, 'beginner', <String>['red', 'orange', 'green', 'orange', 'red', 'orange', 'green'], 1.4015),
  _Cellule('P2-J1-R1', 'Lea', 1, 34, 165, 58.0, 'female', 1, 9.0, 200, 9, 'beginner', <String>['red', 'orange', 'green', 'orange', 'red', 'orange', 'green'], 1.4015),
  _Cellule('P2-J1-R2', 'Lea', 2, 34, 165, 58.0, 'female', 1, 9.0, 200, 9, 'beginner', <String>['red', 'orange', 'green', 'orange', 'red', 'orange', 'green'], 1.4015),
  _Cellule('P2-J1-R3', 'Lea', 3, 34, 165, 58.0, 'female', 1, 9.0, 200, 9, 'intermediate', <String>['orange', 'green', 'green', 'green', 'green', 'green', 'green'], 0.9113),
  _Cellule('P3-J1-R0', 'Jean-Pierre', 0, 68, 176, 82.0, 'male', 10, 170.0, 10000, 5, 'beginner', <String>['orange', 'green', 'green', 'green', 'green', 'green', 'green'], 0.8635),
  _Cellule('P3-J1-R1', 'Jean-Pierre', 1, 68, 176, 82.0, 'male', 10, 170.0, 10000, 5, 'beginner', <String>['orange', 'green', 'green', 'green', 'green', 'green', 'green'], 0.8635),
  _Cellule('P3-J1-R2', 'Jean-Pierre', 2, 68, 176, 82.0, 'male', 10, 170.0, 10000, 5, 'beginner', <String>['orange', 'green', 'green', 'green', 'green', 'green', 'green'], 0.8635),
  _Cellule('P3-J1-R3', 'Jean-Pierre', 3, 68, 176, 82.0, 'male', 10, 170.0, 10000, 5, 'intermediate', <String>['orange', 'green', 'green', 'green', 'green', 'green', 'green'], 0.8635),
  _Cellule('P4-J1-R0', 'Ines', 0, 41, 168, 63.0, 'female', 6, 85.0, 6000, 4, 'beginner', <String>['orange', 'green', 'green', 'green', 'green', 'green', 'green'], 0.9279),
  _Cellule('P4-J1-R1', 'Ines', 1, 41, 168, 63.0, 'female', 6, 85.0, 6000, 4, 'beginner', <String>['orange', 'green', 'green', 'green', 'green', 'green', 'green'], 0.9279),
  _Cellule('P4-J1-R2', 'Ines', 2, 41, 168, 63.0, 'female', 6, 85.0, 6000, 4, 'beginner', <String>['orange', 'green', 'green', 'green', 'green', 'green', 'green'], 0.9279),
  _Cellule('P4-J1-R3', 'Ines', 3, 41, 168, 63.0, 'female', 6, 85.0, 6000, 4, 'intermediate', <String>['orange', 'green', 'green', 'green', 'green', 'green', 'green'], 0.9113),
  _Cellule('P5-J1-R0', 'Thomas', 0, 22, 183, 75.0, 'male', 7, 140.0, 1400, 7, 'beginner', <String>['red', 'red', 'green', 'orange', 'red', 'orange', 'green'], 1.5070),
  _Cellule('P5-J1-R1', 'Thomas', 1, 22, 183, 75.0, 'male', 7, 140.0, 1400, 7, 'beginner', <String>['red', 'red', 'green', 'orange', 'red', 'orange', 'green'], 1.5070),
  _Cellule('P5-J1-R2', 'Thomas', 2, 22, 183, 75.0, 'male', 7, 140.0, 1400, 7, 'beginner', <String>['red', 'red', 'green', 'orange', 'red', 'orange', 'green'], 1.5070),
  _Cellule('P5-J1-R3', 'Thomas', 3, 22, 183, 75.0, 'male', 7, 140.0, 1400, 7, 'intermediate', <String>['orange', 'green', 'green', 'green', 'green', 'green', 'green'], 0.9799),
  _Cellule('P6-J1-R0', 'Sabine', 0, 47, 172, 68.0, 'female', 7, 126.0, 6300, 9, 'beginner', <String>['orange', 'green', 'green', 'green', 'green', 'green', 'green'], 0.8937),
  _Cellule('P6-J1-R1', 'Sabine', 1, 47, 172, 68.0, 'female', 7, 126.0, 6300, 9, 'intermediate', <String>['orange', 'green', 'green', 'green', 'green', 'green', 'green'], 0.8937),
  _Cellule('P6-J1-R2', 'Sabine', 2, 47, 172, 68.0, 'female', 7, 126.0, 6300, 9, 'intermediate', <String>['orange', 'green', 'green', 'green', 'green', 'green', 'green'], 0.8937),
  _Cellule('P6-J1-R3', 'Sabine', 3, 47, 172, 68.0, 'female', 7, 126.0, 6300, 9, 'confirmed', <String>['green', 'green', 'green', 'green', 'green', 'green', 'green'], 0.6341),
];

void main() {
  initHarness();

  testWidgets('S6 — les 24 cellules du sentier de production, sur le produit',
      (tester) async {
    reinitialiserExigences();
    logStep(P, 'boot', 'Lancement de app.main()');
    installerVeilleEcranSysteme(P);
    app.main();
    await settleAndShoot(tester, P, '01_boot',
        timeout: const Duration(seconds: 12));
    await completeOnboardingIfPresent(tester, P);
    await settleAndShoot(tester, P, '02_apres_onboarding');

    final container = _container(tester);
    exige(P, 'container', container != null,
        'le conteneur de providers de PRODUCTION est accessible');
    if (container == null) {
      verdictPersona(P, minimumExigences: 1);
      return;
    }

    // PREALABLE — LA SAISON N'EXISTE QUE SI UNE DATE DE DEPART A ETE POSEE.
    // Trouve en rejouant S6 : sans date de depart, `trekConditionsProvider`
    // rend `season: null` et `k_chaleur` vaut 1,00. Ce n'est PAS un defaut,
    // c'est le comportement voulu (#2-h/#8-b : on ne devine pas une saison) —
    // mais il doit etre DECLARE, pas subi. On le verifie avant tout le reste,
    // sinon les 24 cellules tourneraient en silence avec la mauvaise saison.
    {
      final conditionsSansDate =
          await container.read(trekConditionsProvider.future);
      exige(P, 'saison_absente', conditionsSansDate.season == null,
          'sans date de depart, la saison est INCONNUE (et non devinee)');
      exige(P, 'saison_absente', conditionsSansDate.heatFactor == 1.0,
          'sans date de depart, k_chaleur vaut 1,00');
      exige(
          P,
          'saison_absente',
          conditionsSansDate.seasonNeutralReason == NeutralReason.missingData,
          'et la raison est DECLAREE : donnee manquante, pas absence de source');
    }

    var cellulesJouees = 0;
    for (final cellule in kCellulesJ1) {
      final ok = await _jouerCellule(tester, container, cellule);
      if (ok) cellulesJouees++;
    }

    exige(P, 'couverture', cellulesJouees == kCellulesJ1.length,
        'les ${kCellulesJ1.length} cellules ont ete jouees '
        '(jouees : $cellulesJouees)');

    // Aucune fenetre systeme n'a du recouvrir l'app (voir la note du harnais :
    // seuls `paused` et `hidden` sont bloquants, `inactive` est du bruit).
    exige(P, 'ecran_systeme', ecransSystemeBloquants().isEmpty,
        'aucune fenetre systeme pendant le balayage '
        '(bloquants : ${ecransSystemeBloquants().join(", ")})');

    await settleAndShoot(tester, P, '99_fin_matrice');
    retirerVeilleEcranSysteme();
    // 24 cellules x (1 niveau + 7 etapes + 1 C1) = 216, plus les gardes.
    verdictPersona(P, minimumExigences: 200);
    await finalizeScenario(tester, P);
    await flushJournal(P);
  });
}

// ===========================================================================
// UNE CELLULE
// ===========================================================================

Future<bool> _jouerCellule(
  WidgetTester tester,
  ProviderContainer c,
  _Cellule cellule,
) async {
  await _ecrireProfil(tester, c, cellule);

  final FeasibilityAssessment? a =
      await c.read(feasibilityAssessmentProvider.future);
  if (a == null) {
    exige(P, cellule.id, false,
        'le produit rend une evaluation pour ${cellule.id} '
        '(${cellule.persona}, rang ${cellule.rangForme})');
    return false;
  }

  // 1. LE NIVEAU DERIVE — il vient des randos passees et du rang de forme,
  //    donc de tout le chemin fiche -> profil objectif -> niveau.
  exige(P, cellule.id, a.level.name == cellule.niveauAttendu,
      '${cellule.id} niveau : attendu ${cellule.niveauAttendu}, '
      'produit ${a.level.name}');

  // 2. LES SEPT VERDICTS D'ETAPE — ils ne dependent d'aucun jour de repos.
  final n = cellule.verdictsEtapeAttendus.length;
  if (a.stageVerdicts.length != n) {
    exige(P, cellule.id, false,
        '${cellule.id} : ${a.stageVerdicts.length} etapes evaluees contre $n '
        'attendues — le sentier charge n est pas celui de la matrice');
    return false;
  }
  for (var i = 0; i < n; i++) {
    final obtenu = a.stageVerdicts[i].verdict.name;
    exige(P, cellule.id, obtenu == cellule.verdictsEtapeAttendus[i],
        '${cellule.id} etape ${i + 1} : attendu '
        '${cellule.verdictsEtapeAttendus[i]}, produit $obtenu');
  }

  // 2-bis. LA SAISON A BIEN ETE PRISE EN COMPTE. Les six personnages partent
  //    a des mois differents : deux en ete (k_chaleur 0,93), quatre hors ete
  //    (1,00). On l'exige, sinon une cellule d'ete tournerait en silence avec
  //    la mauvaise capacite et C1 serait faux sans que rien ne le dise.
  final chaleurAttendue = _estEnEte(cellule.moisDepart) ? 0.93 : 1.00;
  exige(P, cellule.id,
      (a.conditions.heatFactor - chaleurAttendue).abs() <= kEps,
      '${cellule.id} k_chaleur : attendu $chaleurAttendue '
      '(depart au mois ${cellule.moisDepart}), '
      'produit ${a.conditions.heatFactor}');

  // 3. C1, LA PIRE ETAPE — grandeur chiffree, independante du repos.
  final c1 = a.circuit?.worstStage ?? double.nan;
  exige(P, cellule.id, (c1 - cellule.c1Attendu).abs() <= kEps,
      '${cellule.id} C1 : attendu ${cellule.c1Attendu}, '
      'produit ${c1.toStringAsFixed(4)}');

  // 4. LE CIRCUIT : ENREGISTRE, PAS EXIGE (voir l en-tete). C est cette ligne
  //    que la re-mesure de la colonne C3 lira.
  final circuit = a.circuit;
  print('PERSONA_MATRICE_C3|${cellule.id}|${a.level.name}|'
      'C1=${c1.toStringAsFixed(4)}|'
      'C3=${circuit?.rest?.toStringAsFixed(4) ?? "non-applicable"}|'
      'monotonie=${circuit?.monotony?.toStringAsFixed(4) ?? "non-applicable"}|'
      'repos=${a.restDaysPlanned}|'
      'dominante=${circuit?.dominant.name}|'
      'circuit=${circuit?.verdict.name}');
  logStep(
      P,
      cellule.id,
      'circuit ENREGISTRE (non exige) : ${circuit?.verdict.name}, '
      'dominante ${circuit?.dominant.name}, ${a.restDaysPlanned} repos');

  return true;
}

/// Ecrit fiche, randos et resultat de test de marche par le VRAI chemin.
Future<void> _ecrireProfil(
  WidgetTester tester,
  ProviderContainer c,
  _Cellule cellule,
) async {
  final profil = HikerProfile(
    age: cellule.age,
    heightCm: cellule.tailleCm,
    weightKg: cellule.poidsKg,
    sex: _sexe(cellule.sexe),
  );
  final rando = PastHike(
    date: DateTime(2026, cellule.moisDepart, 1),
    days: cellule.randoJours,
    totalDistanceKm: cellule.randoKm,
    totalElevationGain: cellule.randoDplus,
  );
  await c.read(hikerProfileProvider.notifier).save(profil);
  await c.read(pastHikesProvider.notifier).saveAll(<PastHike>[rando]);
  // Le RANG DE FORME vient du test de marche : on ecrit un resultat DATE par le
  // meme depot que le controleur du test 6 minutes (aucune surcharge).
  await c.read(hikerProfileRepositoryProvider).saveWalkTestResult(
        WalkTestResult(
          distanceMeters: 500,
          level: WalkTestLevel.ordered[cellule.rangForme],
          takenAt: DateTime.now(),
        ),
      );
  // LA DATE DE DEPART — c'est elle, et elle seule, qui porte la SAISON
  // (`trekConditionsProvider` la lit dans `downloadReminderProvider`). Sans
  // elle, `k_chaleur` vaut 1,00 et les cellules d'ete seraient fausses.
  final trailId = c.read(trailIdProvider);
  await c
      .read(downloadReminderProvider(trailId).notifier)
      .setDepartureDate(DateTime(2027, cellule.moisDepart, 8));
  // Delais courts et assumes : ce scenario ne rend AUCUN ecran, il ecrit par
  // les notifiers et lit un provider. Attendre 4 s par cellule couterait
  // 3 minutes pour rien et ferait deborder le run.
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 2));
  _invalider(c);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 2));
}

/// Ete meteorologique, hemisphere nord (juin, juillet, aout) — meme repere que
/// `Season.fromDate` cote application.
bool _estEnEte(int mois) => mois >= 6 && mois <= 8;

String? _sexe(String s) => switch (s) {
      'male' => HikerSex.male,
      'female' => HikerSex.female,
      _ => null,
    };

void _invalider(ProviderContainer c) {
  c.invalidate(hikerProfileProvider);
  c.invalidate(pastHikesProvider);
  c.invalidate(walkTestResultProvider);
  c.invalidate(objectiveProfileProvider);
  c.invalidate(hikerLevelProvider);
  c.invalidate(trekConditionsProvider);
  c.invalidate(feasibilityAssessmentProvider);
}

ProviderContainer? _container(WidgetTester tester) {
  try {
    final element = tester.element(find.byType(Navigator).first);
    return ProviderScope.containerOf(element, listen: false);
  } catch (_) {
    return null;
  }
}
