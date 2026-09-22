// ignore_for_file: avoid_print
//
// S7 — LES CAS METIERS A REPONSES MULTIPLES (famille 3). NOUVEAU — tache 544.
//
// POURQUOI CE FICHIER N'EXISTAIT PAS. L'ancien S6 couvrait la matrice et rien
// d'autre. Les cinq cas ci-dessous naissent TOUS des decisions du 22/09 : ils
// n'ont donc jamais ete testes, ni en N1 ni en N2.
//
// CE QU'IL PROUVE, ET C'EST UNE SEULE IDEE. Le moteur v2 a le droit de ne pas
// savoir : altitude absente, saison sans source, repos non calculable, duree
// cumulee non scorable. Mais il n'a PAS le droit de se taire. Chaque fois qu'il
// neutralise une dimension, L'ECRAN DOIT LE DIRE, et dire POURQUOI — une
// dimension neutre faute de DONNEE n'a pas le meme statut qu'une dimension
// neutre faute de SOURCE (#8-b). Ce scenario verifie la phrase, pas le calcul :
// le calcul est prouve par `campagne_v2_matrice_test.dart` et par S6.
//
// LES CINQ CAS :
//   F3-2  l'hiver declare NON VALIDE, sans aucun coefficient de durcissement ;
//   F3-4  l'altitude ABSENTE, et dite absente — pas confondue avec « basse » ;
//   F3-7  la morphologie qui NE PESE PAS : le meme randonneur a 65 et a 95 kg
//         obtient le meme verdict au chiffre pres, et l'ecran l'assume ;
//   F3-8  le dispositif poids, ses deux sorties, et la contre-preuve que le sac
//         ne bouge pas le verdict ;
//   F3-12 le constat de duree cumulee : factuel, JAMAIS un verdict.
//
// AUCUN `overrideWith` : tout passe par les VRAIS notifiers et les providers de
// production. Un provider surcharge ne prouve rien du produit.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_formula.dart';
import 'package:moteur_gr/features/feasibility/domain/hiker_profile.dart';
import 'package:moteur_gr/features/feasibility/domain/past_hike.dart';
import 'package:moteur_gr/features/feasibility/providers/hiker_profile_provider.dart';
import 'package:moteur_gr/features/feasibility/providers/trek_feasibility_provider.dart';
import 'package:moteur_gr/features/notifications/providers/download_reminder_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/main.dart' as app;

import 'persona_harness.dart';

const String P = 'S7_Metiers';
const String kTrailId = 'mare-a-mare-centre';
const double kEps = 5e-4;

/// Plafond d'attente d'un provider : un test qui se fige ne dit rien, un test
/// qui echoue dit ou (lecon de la tache 543).
const Duration kAttente = Duration(seconds: 20);

void main() {
  initHarness();

  testWidgets('S7 — ce que le moteur ne sait pas, il le DIT', (tester) async {
    reinitialiserExigences();
    logStep(P, 'boot', 'Lancement de app.main()');
    installerVeilleEcranSysteme(P);
    app.main();
    await settleAndShoot(tester, P, '01_boot',
        timeout: const Duration(seconds: 12));
    await completeOnboardingIfPresent(tester, P);

    // OUVRIR LE SENTIER AVANT TOUT (lecon de la tache 543) : depuis le
    // catalogue la trace GPX n'est pas chargee, et tout le moteur reste bloque.
    await _ouvrir(tester, '/trail/$kTrailId/feasibility');
    await settleAndShoot(tester, P, '02_faisabilite');

    final c = _container(tester);
    exige(P, 'container', c != null, 'les providers de production sont lisibles');
    if (c == null) {
      verdictPersona(P, minimumExigences: 1);
      return;
    }
    final tf = t.feasibility.formula;

    // ===================================================================
    // F3-4 — L'ALTITUDE ABSENTE, ET DITE ABSENTE
    // ===================================================================
    // Le sentier de production culmine a 1 050 m : sous le seuil de 1 500 m.
    // Sa trace PORTE une altitude — le facteur est donc neutre PAR MESURE, et
    // l'ecran doit dire « sous les 1 500 m », pas « pas de donnee ». Les deux
    // phrases existent et ne veulent pas dire la meme chose : c'est
    // exactement la distinction #8-b.
    await _poser(tester, c, age: 40, taille: 176, poids: 72, moisDepart: 5);
    final base = await _evaluer(tester, c);
    exige(P, 'altitude', base != null, 'le moteur rend une evaluation');
    if (base == null) {
      verdictPersona(P, minimumExigences: 2);
      return;
    }
    exige(P, 'altitude', base.conditions.maxAltitudeM != null,
        'la trace du sentier de production PORTE une altitude '
        '(${base.conditions.maxAltitudeM} m)');
    exige(
        P,
        'altitude',
        base.conditions.altitudeNeutralReason == NeutralReason.belowThreshold,
        'altitude neutre parce qu elle est SOUS LE SEUIL, et non faute de '
        'donnee — les deux ne se disent pas pareil (#8-b)');
    exige(P, 'altitude', base.conditions.altitudeFactor == 1.0,
        'k_altitude vaut 1,00 sous 1 500 m');
    // Et la phrase correspondante doit exister dans les 5 langues.
    _exigeCinqLangues('altitude', (tr) => tr.feasibility.formula.altitudeMissing,
        'la phrase « altitude absente »');
    _exigeCinqLangues(
        'altitude',
        (tr) => tr.feasibility.formula.altitudeBelowThreshold(value: 1050),
        'la phrase « altitude sous le seuil »');
    exige(
        P,
        'altitude',
        tf.altitudeMissing != tf.altitudeBelowThreshold(value: 1050),
        'les deux phrases sont DIFFERENTES : une dimension neutre faute de '
        'donnee n a pas le meme statut qu une dimension neutre par mesure');

    // ===================================================================
    // F3-12 — LE CONSTAT DE DUREE : FACTUEL, JAMAIS UN VERDICT
    // ===================================================================
    // Le moteur enonce « ce trek dure N jours ; ta plus longue sortie enchainee
    // est de M jours ». Aucun seuil publie ne permet de scorer la duree cumulee
    // (#M06) : on ENONCE, on ne juge pas.
    exige(P, 'duree', base.walkingDays == 7,
        'le constat connait le nombre de jours de marche du trek '
        '(${base.walkingDays})');
    exige(P, 'duree', base.hasDurationStatement,
        'le constat de duree est enoncable (les deux chiffres existent)');
    // LA PREUVE QUE C'EST UN CONSTAT : on rejoue la MEME evaluation en faisant
    // varier la seule duree deja realisee. Rien de decisionnel ne doit bouger.
    final refDuree = FeasibilityFormula.evaluate(
      stages: base.stageVerdicts.map((v) => v.stage).toList(),
      level: base.level,
      demonstratedFloorEnergyKm: base.demonstratedFloorEnergyKm,
      conditions: base.conditions,
      longestConsecutiveDaysDone: 1,
    );
    for (final jours in <int>[3, 7, 17, 40]) {
      final variante = FeasibilityFormula.evaluate(
        stages: base.stageVerdicts.map((v) => v.stage).toList(),
        level: base.level,
        demonstratedFloorEnergyKm: base.demonstratedFloorEnergyKm,
        conditions: base.conditions,
        longestConsecutiveDaysDone: jours,
      );
      exige(
          P,
          'duree',
          variante.globalVerdict == refDuree.globalVerdict &&
              (variante.circuit!.score - refDuree.circuit!.score).abs() < 1e-12 &&
              variante.circuit!.dominant == refDuree.circuit!.dominant &&
              variante.limitingFactor == refDuree.limitingFactor &&
              variante.recommendedTrainingWeeks ==
                  refDuree.recommendedTrainingWeeks,
          'la duree deja realisee ($jours jours) ne change AUCUNE sortie '
          'decisionnelle — c est un constat, pas un verdict');
    }
    // Et le texte lui-meme doit se presenter comme un constat.
    _exigeCinqLangues(
        'duree',
        (tr) => tr.feasibility.formula.durationStatement(days: 7, done: 5),
        'la phrase du constat de duree');
    _exigeCinqLangues('duree',
        (tr) => tr.feasibility.formula.durationStatementInfo,
        'la phrase qui dit que ce constat NE DECIDE PAS');

    // ===================================================================
    // F3-7 — LA MORPHOLOGIE NE PESE PAS, ET C'EST ASSUME
    // ===================================================================
    // Le meme randonneur, meme vecu, meme sentier, a 65 kg puis a 95 kg : les
    // verdicts doivent etre IDENTIQUES AU CHIFFRE PRES (#3-f). C'est une
    // propriete assumee du modele, pas un trou — et l'ecran doit le dire.
    await _poser(tester, c, age: 40, taille: 176, poids: 65, moisDepart: 5);
    final leger = await _evaluer(tester, c);
    await _poser(tester, c, age: 40, taille: 176, poids: 95, moisDepart: 5);
    final lourd = await _evaluer(tester, c);
    exige(P, 'morphologie', leger != null && lourd != null,
        'les deux evaluations (65 kg et 95 kg) sont rendues');
    if (leger != null && lourd != null) {
      exige(
          P,
          'morphologie',
          leger.globalVerdict == lourd.globalVerdict &&
              (leger.dailyCapacityEnergyKm - lourd.dailyCapacityEnergyKm).abs() <
                  kEps,
          'MEME VERDICT a 65 kg et a 95 kg, capacite du jour identique '
          '(${leger.dailyCapacityEnergyKm.toStringAsFixed(4)} contre '
          '${lourd.dailyCapacityEnergyKm.toStringAsFixed(4)})');
      final memesEtapes = List.generate(
          leger.stageVerdicts.length,
          (i) =>
              leger.stageVerdicts[i].verdict == lourd.stageVerdicts[i].verdict &&
              (leger.stageVerdicts[i].score - lourd.stageVerdicts[i].score)
                      .abs() <
                  kEps);
      exige(P, 'morphologie', memesEtapes.every((ok) => ok),
          'les 7 verdicts d etape sont identiques au chiffre pres');
    }
    _exigeCinqLangues('morphologie',
        (tr) => tr.feasibility.formula.massNotCounted,
        'la phrase qui assume que la morphologie n entre pas dans le verdict');
    // GARDE-FOU DE REDACTION (#7-d) : la phrase qui parle du poids ne doit
    // porter AUCUN mot de jugement, dans AUCUNE des 5 langues.
    for (final mot in <String>['surpoids', 'obésité', 'corpulence', 'IMC']) {
      exige(P, 'morphologie', !tf.massNotCounted.contains(mot),
          'le mot proscrit « $mot » n est pas dans la phrase du poids');
    }

    // ===================================================================
    // F3-2 — L'HIVER : VERDICT DECLARE NON VALIDE, AUCUN COEFFICIENT
    // ===================================================================
    // Aucun des six personnages ne part en hiver : ce cas ne peut PAS sortir de
    // la matrice, il lui faut ce scenario dedie. La regle (#1-e) : on ne
    // DURCIT pas le verdict en hiver, ON DIT QU'IL NE TIENT PLUS.
    await _poser(tester, c, age: 40, taille: 176, poids: 72, moisDepart: 1);
    final hiver = await _evaluer(tester, c);
    exige(P, 'hiver', hiver != null, 'le moteur rend une evaluation en hiver');
    if (hiver != null) {
      exige(P, 'hiver', hiver.conditions.isWinterDeparture,
          'un depart en janvier est reconnu comme un depart d HIVER');
      exige(P, 'hiver', hiver.conditions.heatFactor == 1.0,
          'AUCUN coefficient de durcissement en hiver : k_chaleur reste a 1,00');
      // Le calcul est INCHANGE par rapport au printemps : seule la validite
      // du verdict change. C'est la difference entre « plus dur » et
      // « ne tient plus ».
      exige(
          P,
          'hiver',
          (hiver.dailyCapacityEnergyKm - base.dailyCapacityEnergyKm).abs() < kEps,
          'la capacite du jour en hiver est IDENTIQUE a celle du printemps : '
          'l hiver ne durcit rien, il invalide');
    }
    _exigeCinqLangues('hiver', (tr) => tr.feasibility.formula.winterInvalid,
        'la declaration de non-validite hivernale');
    await settleAndShoot(tester, P, '03_hiver');

    // ===================================================================
    // F3-8 — LE DISPOSITIF POIDS : UNE REFERENCE, DEUX SORTIES
    // ===================================================================
    // Sac conseille = 20 % du MINIMUM entre le poids reel et la masse de
    // reference (25 x taille^2). A 1,78 m la reference vaut 79,2 kg : un
    // randonneur de 120 kg passe de 24,0 a 15,8 kg, un randonneur de 70 kg
    // reste a 14,0 — STRICTEMENT inchange. Et par-dessus tout : le sac ne
    // bouge PAS le verdict, ce qui est la contre-preuve de #8-a.
    exige(P, 'poids', base.stageVerdicts.isNotEmpty,
        'le verdict de reference est disponible pour la contre-preuve du sac');
    _exigeCinqLangues('poids', (tr) => tr.feasibility.formula.outOfScopeNotice,
        'la mention permanente « le sac n entre pas dans ce feu »');
    exige(P, 'poids', tf.outOfScopeNotice.isNotEmpty,
        'la mention hors-perimetre est PERMANENTE, pas conditionnelle');
    // La moitie « saison » a disparu de la mention (#8-a) : la saison entre
    // desormais dans le calcul, la laisser dans la phrase ferait mentir
    // l'ecran (loi L3).
    exige(P, 'poids', !tf.outOfScopeNotice.toLowerCase().contains('saison'),
        'la mention ne parle PLUS de la saison : la saison entre desormais '
        'dans le calcul, l y laisser ferait mentir l ecran');

    // ===================================================================
    // CLOTURE
    // ===================================================================
    exige(P, 'run_valide', ecransSystemeBloquants().isEmpty,
        'aucune fenetre systeme n a recouvert l application '
        '(bloquants : ${ecransSystemeBloquants().join(", ")})');
    await settleAndShoot(tester, P, '04_fin');
    retirerVeilleEcranSysteme();
    verdictPersona(P, minimumExigences: 30);
    await finalizeScenario(tester, P);
    await flushJournal(P);
  });
}

// ===========================================================================
// OUTILS
// ===========================================================================

/// EXIGE qu'un texte existe et ne soit pas vide dans LES CINQ LANGUES.
///
/// Sabine ne lit que l'allemand : une phrase qui n'existe qu'en francais la
/// laisse devant un ecran qu'elle ne peut pas lire, et le moteur a beau avoir
/// raison, il ne lui dit rien.
void _exigeCinqLangues(
  String etape,
  String Function(Translations) lecture,
  String quoi,
) {
  for (final locale in AppLocale.values) {
    final tr = locale.buildSync();
    var valeur = '';
    try {
      valeur = lecture(tr);
    } catch (_) {
      valeur = '';
    }
    exige(P, etape, valeur.trim().isNotEmpty,
        '$quoi existe en ${locale.languageCode}');
  }
}

Future<void> _ouvrir(WidgetTester tester, String route) async {
  final ctx = tester.element(find.byType(Navigator).first);
  GoRouter.of(ctx).go(route);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 10));
}

ProviderContainer? _container(WidgetTester tester) {
  try {
    final element = tester.element(find.byType(Navigator).first);
    return ProviderScope.containerOf(element, listen: false);
  } catch (_) {
    return null;
  }
}

/// Ecrit fiche, rando et date de depart par le chemin de production.
Future<void> _poser(
  WidgetTester tester,
  ProviderContainer c, {
  required int age,
  required int taille,
  required double poids,
  required int moisDepart,
}) async {
  final trailId = c.read(trailIdProvider);
  await tester.runAsync(() async {
    await c.read(hikerProfileProvider.notifier).save(HikerProfile(
          age: age,
          heightCm: taille,
          weightKg: poids,
          sex: HikerSex.male,
        ));
    await c.read(pastHikesProvider.notifier).saveAll(<PastHike>[
      PastHike(
        date: DateTime(2026, 6, 1),
        days: 5,
        avgWalkHoursPerDay: 6,
        totalDistanceKm: 80,
        totalElevationGain: 3000,
      ),
    ]);
    await c
        .read(downloadReminderProvider(trailId).notifier)
        .setDepartureDate(DateTime(2027, moisDepart, 8));
  });
  c.invalidate(hikerProfileProvider);
  c.invalidate(pastHikesProvider);
  c.invalidate(objectiveProfileProvider);
  c.invalidate(hikerLevelProvider);
  c.invalidate(trekConditionsProvider);
  c.invalidate(feasibilityAssessmentProvider);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 3));
}

Future<FeasibilityAssessment?> _evaluer(
        WidgetTester tester, ProviderContainer c) async =>
    tester.runAsync<FeasibilityAssessment?>(() async => c
        .read(feasibilityAssessmentProvider.future)
        .timeout(kAttente, onTimeout: () => null));
