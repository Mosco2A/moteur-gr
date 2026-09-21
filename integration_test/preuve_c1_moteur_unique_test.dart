// ignore_for_file: avoid_print
//
// PREUVE C1 SUR L'APPAREIL — les deux ecrans disent la meme chose.
//
// Boucle de correction N1 (mandat #100278), defaut MAJEUR-4 du rapport de
// campagne #100277. Mesure du 21/09 sur emulateur : pour LE MEME randonneur et
// LE MEME trek, l'ecran Faisabilite affichait « Faisable » pendant que l'ecran
// Entrainement affichait « Votre faisabilite invite a la prudence », sur trois
// profils sur six — dont les deux plus courants (occasionnel et confirme).
//
// CE FICHIER NE MODIFIE AUCUN CODE APPLICATIF et NE TOUCHE PAS au harnais des
// personas : il le REUTILISE tel quel (persona_harness.dart), comme les suites
// existantes. AUCUN `overrideWith` : la VRAIE application (`app.main()`) tourne
// sur l'appareil, les profils sont ecrits par les VRAIS notifiers, et ce sont
// les DEUX ECRANS REELS qui sont ouverts et lus.
//
// Pour chaque profil :
//   1. ecriture du profil par le vrai chemin (notifier -> repository -> prefs/Drift) ;
//   2. ecran FAISABILITE ouvert, libelle de verdict LU A L'ECRAN, capture ;
//   3. ecran ENTRAINEMENT ouvert, bandeau de prudence cherche A L'ECRAN, capture ;
//   4. confrontation : le bandeau de prudence doit etre present SI ET SEULEMENT
//      SI le libelle affiche n'est pas « Faisable ».
//
// Lignes machine : PREUVE_C1|<profil>|<libelle_faisabilite>|<bandeau_entrainement>|<verdict_moteur>

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_formula.dart';
import 'package:moteur_gr/features/feasibility/domain/hiker_profile.dart';
import 'package:moteur_gr/features/feasibility/domain/past_hike.dart';
import 'package:moteur_gr/features/feasibility/providers/hiker_profile_provider.dart';
import 'package:moteur_gr/features/feasibility/providers/trek_feasibility_provider.dart';
import 'package:moteur_gr/features/training/providers/training_plan_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/main.dart' as app;

import 'persona_harness.dart';

const String P = 'PreuveC1';

final List<String> _contradictions = <String>[];

void _contradiction(String details) {
  _contradictions.add(details);
  print('PREUVE_C1_CONTRADICTION|$details');
  logStep(P, 'contradiction', details);
}

// ===========================================================================
// LES SIX PROFILS DE LA CAMPAGNE (memes chiffres que le rapport #100277)
// ===========================================================================
class Profil {
  const Profil({
    required this.cle,
    required this.libelle,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.hikes,
  });

  final String cle;
  final String libelle;
  final int age;
  final int heightCm;
  final double weightKg;

  /// (jours, heures/j, D+ total m, distance totale km).
  final List<List<num>> hikes;

  List<PastHike> toPastHikes() {
    final now = DateTime.now();
    return [
      for (var i = 0; i < hikes.length; i++)
        PastHike(
          date: now.subtract(Duration(days: 30 * (i + 1))),
          days: hikes[i][0].toInt(),
          avgWalkHoursPerDay: hikes[i][1].toDouble(),
          totalElevationGain: hikes[i][2].toInt(),
          totalDistanceKm: hikes[i][3].toDouble(),
        ),
    ];
  }

  HikerProfile toProfile() => HikerProfile(
        age: age,
        heightCm: heightCm,
        weightKg: weightKg,
        countryIso: 'FR',
        updatedAt: DateTime.now(),
      );
}

/// Les trois premiers etaient coherents, les trois suivants se contredisaient.
const List<Profil> kProfils = <Profil>[
  Profil(
    cle: 'P0_vierge',
    libelle: 'Aucune donnee (premier lancement)',
    age: 0,
    heightCm: 0,
    weightKg: 0,
    hikes: <List<num>>[],
  ),
  Profil(
    cle: 'P1_debutante',
    libelle: 'Debutante 32 ans — 1 sortie de 8 km / 300 D+',
    age: 32,
    heightCm: 165,
    weightKg: 62,
    hikes: <List<num>>[
      [1, 4, 300, 8],
    ],
  ),
  Profil(
    cle: 'P2_occasionnel',
    libelle: 'Occasionnel 45 ans — week-ends 2j, 16 km/j, 550 D+/j',
    age: 45,
    heightCm: 178,
    weightKg: 78,
    hikes: <List<num>>[
      [2, 6, 1100, 32],
      [1, 5, 600, 14],
    ],
  ),
  Profil(
    cle: 'P3_confirme',
    libelle: 'Confirme 38 ans — 4j, 23 km/j, 900 D+/j',
    age: 38,
    heightCm: 182,
    weightKg: 80,
    hikes: <List<num>>[
      [4, 8, 3600, 92],
      [3, 7, 2400, 66],
    ],
  ),
  Profil(
    cle: 'P5_senior_confirme',
    libelle: 'Senior confirme 68 ans — memes randos que le confirme',
    age: 68,
    heightCm: 175,
    weightKg: 76,
    hikes: <List<num>>[
      [4, 8, 3600, 92],
      [3, 7, 2400, 66],
    ],
  ),
  Profil(
    cle: 'P4_expert',
    libelle: 'Expert 34 ans — 6j, 28 km/j, 1400 D+/j',
    age: 34,
    heightCm: 180,
    weightKg: 74,
    hikes: <List<num>>[
      [6, 9, 8400, 168],
      [5, 9, 6500, 140],
    ],
  ),
];

// ===========================================================================
// MAIN
// ===========================================================================
void main() {
  initHarness();

  testWidgets('PREUVE C1 — Faisabilite et Entrainement disent la meme chose',
      (tester) async {
    logStep(P, 'boot', 'Lancement de app.main() — preuve C1 moteur unique');
    app.main();
    await settleAndShoot(tester, P, '01_boot',
        timeout: const Duration(seconds: 14));
    await completeOnboardingIfPresent(tester, P);
    await settleAndShoot(tester, P, '02_apres_onboarding');

    await _entrerPremierSentier(tester);
    final trailId = _trailIdActif(tester) ?? _trailIdDepuisRoute(tester);
    logStep(P, 'contexte', 'Sentier actif = ${trailId ?? "INTROUVABLE"}');
    expect(trailId, isNotNull,
        reason: 'sans sentier actif, aucun des deux ecrans n a de verdict');

    // L'ecran Entrainement est payant : son bandeau de prudence ne s'affiche
    // que debloque. On debloque par le VRAI chemin (portefeuille + achat), pas
    // par une surcharge de provider.
    await _debloquerEntrainement(tester, trailId!);

    for (final profil in kProfils) {
      await _mesurerProfil(tester, trailId, profil);
    }

    logStep(P, 'fin',
        'Preuve terminee — ${_contradictions.length} contradiction(s)');
    await finalizeScenario(tester, P);
    await flushJournal(P);

    expect(_contradictions, isEmpty,
        reason: 'Les deux ecrans se contredisent encore :\n'
            '${_contradictions.join('\n')}');
  });
}

// ===========================================================================
// MESURE D'UN PROFIL : ecriture, puis LES DEUX ECRANS
// ===========================================================================
Future<void> _mesurerProfil(
  WidgetTester tester,
  String trailId,
  Profil profil,
) async {
  final applique = await _appliquerProfil(tester, profil);
  if (!applique) {
    _contradiction('${profil.cle} : profil non applique, mesure impossible');
    return;
  }

  // --- ECRAN 1 : FAISABILITE ---
  await _ouvrirFaisabilite(tester, trailId);
  await settleAndShoot(tester, P, '1_${profil.cle}_faisabilite');
  final libelle = _lireBadgeAffiche(tester);

  // --- ECRAN 2 : ENTRAINEMENT ---
  await _ouvrirEntrainement(tester);
  await settleAndShoot(tester, P, '2_${profil.cle}_entrainement');
  final bandeau = _bandeauPrudenceAffiche(tester);

  // --- Ce que disent les providers REELS de l'application, pour le journal ---
  final assessment = await _lireAssessment(tester);
  final perso = await _lirePersonnalisation(tester);
  final verdictMoteur =
      assessment == null ? '(muet)' : assessment.globalVerdict.name;
  final verdictEntrainement = perso?.verdict?.name ?? '(aucun)';

  print('PREUVE_C1|${profil.cle}|${libelle ?? "AUCUN"}|'
      '${bandeau ? "BANDEAU_PRUDENCE" : "aucun_bandeau"}|$verdictMoteur');
  logStep(
      P,
      'mesure',
      '${profil.cle} (${profil.libelle}) : ecran Faisabilite="'
          '${libelle ?? "AUCUN LIBELLE LU"}" | ecran Entrainement='
          '${bandeau ? "bandeau de prudence AFFICHE" : "aucun bandeau"} | '
          'verdict moteur=$verdictMoteur | verdict lu par l Entrainement='
          '$verdictEntrainement');

  // --- LA CONFRONTATION : un seul moteur, donc une seule reponse ---
  if (libelle == null) {
    _contradiction('${profil.cle} : aucun libelle de verdict lisible sur '
        'l ecran Faisabilite — impossible de confronter');
    return;
  }

  final faisableSansReserve = libelle == _libelleAttendu(FeasibilityVerdict.green);
  if (faisableSansReserve && bandeau) {
    _contradiction('${profil.cle} : la Faisabilite affiche "$libelle" mais '
        'l Entrainement affiche le bandeau de prudence — c est EXACTEMENT le '
        'defaut MAJEUR-4');
  }
  if (!faisableSansReserve && !bandeau) {
    _contradiction('${profil.cle} : la Faisabilite affiche "$libelle" (donc '
        'une reserve) mais l Entrainement n affiche AUCUN bandeau de prudence');
  }

  // Et le verdict porte par les deux lectures doit etre le MEME objet.
  if (assessment != null && perso != null) {
    if (perso.verdict != assessment.globalVerdict) {
      _contradiction('${profil.cle} : verdict Faisabilite='
          '${assessment.globalVerdict.name} mais verdict lu par l Entrainement='
          '$verdictEntrainement — deux sources subsistent');
    }
  }
}

// ===========================================================================
// Helpers
// ===========================================================================
ProviderContainer? _container(WidgetTester tester) {
  try {
    final element = tester.element(find.byType(Navigator).first);
    return ProviderScope.containerOf(element, listen: false);
  } catch (_) {
    return null;
  }
}

String _routeCourante(WidgetTester tester) {
  try {
    final ctx = tester.element(find.byType(Navigator).first);
    return GoRouter.maybeOf(ctx)
            ?.routerDelegate
            .currentConfiguration
            .uri
            .toString() ??
        '';
  } catch (_) {
    return '';
  }
}

String? _trailIdDepuisRoute(WidgetTester tester) =>
    RegExp(r'/trail/([^/?]+)').firstMatch(_routeCourante(tester))?.group(1);

String? _trailIdActif(WidgetTester tester) {
  try {
    return _container(tester)?.read(trailConfigProvider).id;
  } catch (_) {
    return null;
  }
}

Future<void> _entrerPremierSentier(WidgetTester tester) async {
  await tapIfPresent(tester, textFrEn('Découvrir des sentiers', 'Discover trails'),
      P, 'contexte', 'Decouvrir des sentiers', warnIfMissing: false);
  await pumpAndSettleTolerant(tester);
  await tapIfPresent(tester, textFrEn('Entrer', 'Enter'), P, 'contexte',
      'Entrer dans le sentier', warnIfMissing: false);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
}

/// Debloque l'ecran Entrainement par le VRAI chemin : on recharge le
/// portefeuille puis on achete le sentier (le wallet couvre tout -> `owned`).
Future<void> _debloquerEntrainement(WidgetTester tester, String trailId) async {
  final c = _container(tester);
  if (c == null) return;
  try {
    final service = await c
        .read(monetizationReadyProvider.future)
        .timeout(const Duration(seconds: 15));
    final trail = c.read(trailConfigProvider);
    await service.rechargeWallet(const StepPack(
      steps: 999,
      priceEur: 0,
      productId: 'preuve_c1_interne',
    ));
    final outcome =
        await service.buyTrail(trailId, totalStages: trail.totalStages);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
    logStep(P, 'deblocage',
        'Entrainement debloque par le portefeuille : ${outcome.status.name}');
  } catch (e) {
    logStep(P, 'deblocage', 'COINCE : deblocage impossible : $e');
  }
}

/// Ecrit le profil par les VRAIS notifiers, puis invalide la chaine de calcul
/// exactement comme le fait l'ecran (bouton « Recommencer »).
Future<bool> _appliquerProfil(WidgetTester tester, Profil profil) async {
  final c = _container(tester);
  if (c == null) return false;
  try {
    await c.read(hikerProfileProvider.notifier).save(profil.toProfile());
    await c.read(pastHikesProvider.notifier).saveAll(profil.toPastHikes());
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 4));
    c.invalidate(hikerProfileProvider);
    c.invalidate(pastHikesProvider);
    c.invalidate(objectiveProfileProvider);
    c.invalidate(hikerLevelProvider);
    c.invalidate(feasibilityAssessmentProvider);
    c.invalidate(trainingPersonalizationProvider);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 4));
    logStep(P, 'ecriture',
        '${profil.cle} ecrit : ${profil.hikes.length} rando(s), age=${profil.age}');
    return true;
  } catch (e) {
    logStep(P, 'ecriture', 'COINCE : ecriture ${profil.cle} impossible : $e');
    return false;
  }
}

Future<void> _ouvrirFaisabilite(WidgetTester tester, String trailId) async {
  try {
    final ctx = tester.element(find.byType(Navigator).first);
    GoRouter.maybeOf(ctx)?.go('/trail/$trailId/feasibility');
  } catch (e) {
    logStep(P, 'nav', 'Ouverture faisabilite impossible : $e');
    return;
  }
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 10));

  // Flux guide : « Valider et voir mon résultat » mene TOUJOURS au verdict.
  final valider =
      textFrEn('Valider et voir mon résultat', 'Validate and see my result');
  if (present(valider)) {
    await tapIfPresent(tester, valider, P, 'nav', 'valider le flux guide',
        warnIfMissing: false);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
  }
}

Future<void> _ouvrirEntrainement(WidgetTester tester) async {
  try {
    final ctx = tester.element(find.byType(Navigator).first);
    GoRouter.maybeOf(ctx)?.go('/training');
  } catch (e) {
    logStep(P, 'nav', 'Ouverture entrainement impossible : $e');
    return;
  }
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 10));
}

/// Lit le libelle de verdict REELLEMENT affiche sur l'ecran Faisabilite.
///
/// « Faisable » est un PREFIXE de « Faisable avec préparation » : on teste du
/// PLUS LONG au PLUS COURT, sur l'egalite exacte du Text.
String? _lireBadgeAffiche(WidgetTester tester) {
  const candidats = <String>[
    'Au-dessus de tes capacités',
    'Beyond your current ability',
    'Faisable avec préparation',
    'Feasible with preparation',
    'Faisable',
    'Feasible',
  ];
  for (final libelle in candidats) {
    if (find.text(libelle).evaluate().isNotEmpty) return libelle;
  }
  return null;
}

String _libelleAttendu(FeasibilityVerdict v) {
  switch (v) {
    case FeasibilityVerdict.green:
      return 'Faisable';
    case FeasibilityVerdict.orange:
      return 'Faisable avec préparation';
    case FeasibilityVerdict.red:
      return 'Au-dessus de tes capacités';
  }
}

/// Le bandeau « Votre faisabilite invite a la prudence » est-il A L'ECRAN ?
bool _bandeauPrudenceAffiche(WidgetTester tester) =>
    find.text(t.training.cautionVerdictNotice).evaluate().isNotEmpty;

Future<FeasibilityAssessment?> _lireAssessment(WidgetTester tester) async {
  final c = _container(tester);
  if (c == null) return null;
  try {
    return await c
        .read(feasibilityAssessmentProvider.future)
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    logStep(P, 'moteur', 'COINCE : assessment illisible : $e');
    return null;
  }
}

Future<TrainingPersonalization?> _lirePersonnalisation(
    WidgetTester tester) async {
  final c = _container(tester);
  if (c == null) return null;
  try {
    return await c
        .read(trainingPersonalizationProvider.future)
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    logStep(P, 'moteur', 'COINCE : personnalisation illisible : $e');
    return null;
  }
}
