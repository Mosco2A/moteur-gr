// ignore_for_file: avoid_print
//
// PREUVE SUR L'APPAREIL — CORRECTION N2 (mandat #100293).
//
// Les deux defauts que Chris a trouves a l'ecran en deux minutes :
//   D1 — le verdict tombait des la saisie morphologique, alors que GR20
//        n'annonce rien tant que TOUS les criteres ne sont pas remplis ;
//   D2 — choisir le decoupage propose (« Generer mon programme (N jours) »)
//        ne laissait aucune trace : rien a l'ecran, rien apres redemarrage.
//
// CE FICHIER NE MODIFIE AUCUN CODE APPLICATIF. Il lance la VRAIE application
// (`app.main()`) sur l'emulateur, ecrit les donnees par les VRAIS notifiers
// (meme chemin que les formulaires : notifier -> repository -> prefs/Drift),
// ouvre les VRAIS ecrans et LIT ce qui s'y affiche. Aucun `overrideWith`.
//
// Le parcours, dans l'ordre des captures :
//   01  profil vierge            -> parcours guide, aucun verdict
//   02  MORPHOLOGIE SEULE        -> PREUVE D1 : toujours aucun verdict, et
//                                   l'ecran nomme ce qui manque (les randos)
//   03  criteres au complet      -> le verdict tricolore apparait enfin
//   04  avant le choix           -> PREUVE D2 (avant) : aucun decoupage retenu
//   05  Programme apres le choix -> le programme fait bien N jours
//   06  retour faisabilite       -> PREUVE D2 (apres) : decoupage retenu, ecrit
//   07  apres « redemarrage »    -> le decoupage retenu est relu du stockage
//
// Lignes machine (verifiables dans la sortie) : PREUVE_N2|<etape>|<constat>

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/features/feasibility/domain/hiker_profile.dart';
import 'package:moteur_gr/features/feasibility/domain/past_hike.dart';
import 'package:moteur_gr/features/feasibility/providers/hiker_profile_provider.dart';
import 'package:moteur_gr/features/feasibility/providers/trek_feasibility_provider.dart';
import 'package:moteur_gr/features/planning/data/retained_plan_store.dart';
import 'package:moteur_gr/features/planning/providers/planned_days_provider.dart';
import 'package:moteur_gr/features/planning/providers/planning_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/main.dart' as app;

import 'persona_harness.dart';

const String P = 'PreuveN2';

/// Constats qui invalideraient la correction (vides = preuve faite).
final List<String> _ecarts = <String>[];

void _ecart(String details) {
  _ecarts.add(details);
  print('PREUVE_N2_ECART|$details');
  logStep(P, 'ecart', details);
}

void _constat(String etape, String constat) {
  print('PREUVE_N2|$etape|$constat');
  logStep(P, etape, constat);
}

/// Pose l'ecran, puis DEMANDE une capture au preneur de vue host-side.
///
/// POURQUOI PAS `settleAndShoot` du harnais : son marqueur est relu dans
/// `adb logcat`, ce qui suppose que l'application tourne seule (`flutter
/// drive`). Ici le scenario est joue par `flutter test -d`, dont les `print`
/// partent sur la sortie de l'hote et JAMAIS dans logcat — aucune capture
/// n'etait prise. Le marqueur est donc lu directement sur la sortie du test
/// par le script hote, qui declenche `adb exec-out screencap`. La pause qui
/// suit lui laisse largement le temps : l'ecran ne bouge pas pendant ce temps.
Future<void> _shoot(
  WidgetTester tester,
  String name, {
  Duration timeout = const Duration(seconds: 8),
}) async {
  await pumpAndSettleTolerant(tester, timeout: timeout);
  await dismissAdsConsentIfPresent(tester, P);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 3));
  await Future<void>.delayed(const Duration(milliseconds: 500));
  print('PREUVE_N2_SHOT|${P}_$name');
  logStep(P, 'capture', 'capture demandee : $name');
  await Future<void>.delayed(const Duration(seconds: 4));
}

void main() {
  initHarness();

  testWidgets('PREUVE N2 — D1 le verdict attend, D2 le choix est retenu',
      (tester) async {
    logStep(P, 'boot', 'Lancement de app.main() — preuve correction N2');
    app.main();
    await _shoot(tester, '00_boot',
        timeout: const Duration(seconds: 14));
    await completeOnboardingIfPresent(tester, P);
    await _entrerPremierSentier(tester);

    final trailId = _trailIdActif(tester) ?? _trailIdDepuisRoute(tester);
    expect(trailId, isNotNull,
        reason: 'sans sentier actif, la faisabilite n a rien a evaluer');
    _constat('contexte', 'sentier actif = $trailId');

    // =====================================================================
    // D1 — LE VERDICT ATTEND TOUS LES CRITERES
    // =====================================================================

    // (a) Table rase : aucune fiche, aucune rando, aucun test.
    await _effacerProfil(tester);
    await _ouvrirFaisabilite(tester, trailId!);
    await _shoot(tester, '01_profil_vierge');
    _verifierAucunVerdict(tester, '01_profil_vierge');

    // (b) EXACTEMENT LE GESTE DE CHRIS : age + taille + poids, rien d'autre.
    await _ecrireProfil(
      tester,
      const HikerProfile(age: 45, heightCm: 178, weightKg: 76),
      const <PastHike>[],
    );
    await _ouvrirFaisabilite(tester, trailId);
    await _shoot(tester, '02_morphologie_seule');

    // PREUVE D1 : toujours AUCUN verdict, et l'ecran dit ce qui manque.
    _verifierAucunVerdict(tester, '02_morphologie_seule');
    if (!present(find.text(t.feasibility.flow.missingTitle))) {
      _ecart('02 : l ecran ne dit pas ce qui manque');
    }
    if (!present(find.text(t.feasibility.flow.missingPastHikes))) {
      _ecart('02 : les randos passees ne sont pas nommees comme manquantes');
    }
    if (present(find.text(t.feasibility.flow.missingProfile))) {
      _ecart('02 : la fiche est remplie mais reste annoncee comme manquante');
    }
    _constat('D1_morphologie_seule',
        'aucun verdict + « ${t.feasibility.flow.missingPastHikes} » affiche');

    // (c) Le dernier critere obligatoire arrive : une rando passee.
    //
    // MODESTE, ET C'EST VOULU : une sortie d'une journee de 10 km / 250 D+
    // place le randonneur en DEBUTANT (plafond 21 km-effort/jour). Sur le
    // sentier livre, la 1re etape pese 23,5 km-effort : elle passe au rouge et
    // le moteur conseille alors 8 jours de marche au lieu des 7 du sentier.
    // C'est EXACTEMENT la proposition en 8 jours dont Chris dit qu'elle « ne
    // fait rien » — donc le seul cas ou l'effet est observable a l'ecran.
    await _ecrireProfil(
      tester,
      const HikerProfile(age: 45, heightCm: 178, weightKg: 76),
      [
        PastHike(
          date: DateTime.now().subtract(const Duration(days: 40)),
          days: 1,
          avgWalkHoursPerDay: 4,
          totalElevationGain: 250,
          totalDistanceKm: 10,
        ),
      ],
    );
    await _ouvrirFaisabilite(tester, trailId);
    await _shoot(tester, '03_criteres_complets_verdict');

    if (!present(find.text(t.feasibility.formula.stagesTitle))) {
      _ecart('03 : criteres au complet mais toujours aucun verdict');
    } else {
      _constat('D1_au_complet', 'le verdict tricolore est affiche');
    }
    if (present(find.text(t.feasibility.flow.missingTitle))) {
      _ecart('03 : au complet, l ecran reclame encore quelque chose');
    }

    // =====================================================================
    // D2 — CHOISIR LE DECOUPAGE PRODUIT UN EFFET, VISIBLE ET PERSISTANT
    // =====================================================================
    final joursAvant = _joursDuProgramme(tester, trailId);
    final dureeParDefaut = _dureeParDefaut(tester);
    final propose = _joursProposesParLeBouton(tester);
    _constat(
        'D2_avant',
        'programme = $joursAvant jour(s), duree par defaut du sentier = '
            '$dureeParDefaut, decoupage propose par le bouton = '
            '${propose ?? "INTROUVABLE"}');

    if (propose == null) {
      _ecart('D2 : le bouton « Generer mon programme » est introuvable');
    } else if (propose == joursAvant) {
      // Sans ecart entre le propose et l'existant, « appliquer » et « ne rien
      // faire » donnent le meme ecran : la preuve serait creuse. On le DIT.
      _ecart('D2 : le decoupage propose ($propose) est deja celui du programme '
          '($joursAvant) — ce parcours ne peut rien prouver, il faut un profil '
          'dont la reco differe de la duree du sentier');
    }

    // Capture AVANT : la ligne dit qu'aucun decoupage n'est retenu.
    //
    // `ensureVisible` et NON `scrollUntil` : l'ecran est un
    // `SingleChildScrollView`, donc TOUS ses enfants existent dans l'arbre meme
    // hors champ. `scrollUntil` les trouve sans jamais faire defiler, et la
    // capture montre alors le HAUT de l'ecran — la ligne a prouver reste hors
    // cadre. `ensureVisible` amene reellement la ligne sous les yeux.
    await _amenerSousLesYeux(tester,
        find.text(t.feasibility.formula.retainedPlanNone(days: dureeParDefaut)));
    await _shoot(tester, '04_avant_choix_aucun_decoupage');
    if (!present(find
        .text(t.feasibility.formula.retainedPlanNone(days: dureeParDefaut)))) {
      _ecart('04 : l ecran ne dit pas qu aucun decoupage n est retenu');
    }
    final prefsAvant = await _decoupageStocke(trailId);
    if (prefsAvant != null) {
      _ecart('04 : un decoupage ($prefsAvant) est deja stocke avant tout choix');
    }

    // LE GESTE : choisir le decoupage propose.
    final bouton = find.text(t.feasibility.formula.generateProgram(
        days: propose ?? dureeParDefaut));
    await _amenerSousLesYeux(tester, bouton);
    final tape = await tapIfPresent(
        tester, bouton, P, 'D2_choix', 'choisir le decoupage propose');
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 10));
    await _shoot(tester, '05_programme_apres_choix');
    if (!tape) _ecart('D2 : le bouton n a pas pu etre tape');

    // EFFET 1 — le programme reel a change.
    final joursApres = _joursDuProgramme(tester, trailId);
    _constat('D2_effet_programme',
        'programme : $joursAvant jour(s) avant -> $joursApres apres');
    if (propose != null && joursApres != propose) {
      _ecart('D2 : le programme fait $joursApres jours alors que le decoupage '
          'choisi en annonce $propose');
    }

    // EFFET 2 — c'est ECRIT dans le stockage durable.
    final prefsApres = await _decoupageStocke(trailId);
    _constat('D2_effet_stockage',
        'decoupage ecrit dans le stockage durable = ${prefsApres ?? "RIEN"}');
    if (prefsApres != propose) {
      _ecart('D2 : stockage durable = ${prefsApres ?? "RIEN"}, attendu $propose');
    }

    // EFFET 3 — c'est VISIBLE au retour sur la faisabilite.
    await _ouvrirFaisabilite(tester, trailId);
    final ligneRetenue = find
        .text(t.feasibility.formula.retainedPlan(days: propose ?? joursApres));
    await _amenerSousLesYeux(tester, ligneRetenue);
    await _shoot(tester, '06_retour_decoupage_retenu');
    if (!present(ligneRetenue)) {
      _ecart('D2 : de retour sur la faisabilite, le decoupage retenu ne se '
          'voit nulle part');
    } else {
      _constat('D2_visible',
          '« ${t.feasibility.formula.retainedPlan(days: propose ?? joursApres)} »');
    }

    // EFFET 4 — REDEMARRAGE : un graphe de providers tout neuf, lisant le VRAI
    // stockage de l'appareil, retrouve le decoupage retenu. C'est ce que fait
    // l'application au prochain lancement.
    final relu = await _relireApresRedemarrage(tester);
    _constat('D2_apres_redemarrage',
        'duree relue par un graphe neuf = ${relu ?? "RIEN"}');
    if (relu != propose) {
      _ecart('D2 : apres redemarrage la duree retombe a ${relu ?? "RIEN"} '
          'au lieu de $propose');
    }
    await _shoot(tester, '07_apres_redemarrage');

    logStep(P, 'fin', 'Preuve terminee — ${_ecarts.length} ecart(s)');
    await finalizeScenario(tester, P);
    await flushJournal(P);

    expect(_ecarts, isEmpty,
        reason: 'La correction N2 n est pas prouvee :\n${_ecarts.join('\n')}');
  });
}

// ===========================================================================
// Verifications
// ===========================================================================

/// AUCUN element du verdict ne doit etre a l'ecran.
void _verifierAucunVerdict(WidgetTester tester, String etape) {
  final f = t.feasibility.formula;
  final interdits = <String, Finder>{
    'tableau etape par etape': find.text(f.stagesTitle),
    'conseils de programme': find.text(f.adviceTitle),
    'verdict vert': find.text(f.verdicts.green),
    'verdict orange': find.text(f.verdicts.orange),
    'verdict rouge': find.text(f.verdicts.red),
  };
  for (final entry in interdits.entries) {
    if (present(entry.value)) {
      _ecart('$etape : « ${entry.key} » est affiche alors que les criteres ne '
          'sont pas tous fournis');
    }
  }
}

// ===========================================================================
// Helpers
// ===========================================================================

/// Fait DEFILER l'ecran jusqu'a ce que [cible] soit reellement visible.
///
/// Best effort : une cible absente de l'arbre ne fait pas echouer le scenario,
/// elle sera simplement constatee absente par l'assertion qui suit.
Future<void> _amenerSousLesYeux(WidgetTester tester, Finder cible) async {
  if (cible.evaluate().isEmpty) return;
  try {
    await tester.ensureVisible(cible.first);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 4));
  } catch (e) {
    logStep(P, 'defilement', 'COINCE : impossible d amener la cible : $e');
  }
}

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

int _dureeParDefaut(WidgetTester tester) =>
    _container(tester)?.read(trailConfigProvider).defaultDuration ?? 0;

int _joursDuProgramme(WidgetTester tester, String trailId) =>
    _container(tester)?.read(plannedDaysProvider(trailId)).length ?? -1;

/// Lit le nombre de jours ANNONCE par le bouton, en balayant les durees
/// possibles du sentier : on ne devine rien, on lit le libelle affiche.
int? _joursProposesParLeBouton(WidgetTester tester) {
  final c = _container(tester);
  if (c == null) return null;
  final trailId = c.read(trailConfigProvider).id;
  final bounds = c.read(durationBoundsProvider(trailId));
  for (final jours in bounds.options) {
    if (present(find.text(t.feasibility.formula.generateProgram(days: jours)))) {
      return jours;
    }
  }
  return null;
}

Future<void> _entrerPremierSentier(WidgetTester tester) async {
  await tapIfPresent(
      tester, textFrEn('Découvrir des sentiers', 'Discover trails'), P,
      'contexte', 'Decouvrir des sentiers',
      warnIfMissing: false);
  await pumpAndSettleTolerant(tester);
  await tapIfPresent(tester, textFrEn('Entrer', 'Enter'), P, 'contexte',
      'Entrer dans le sentier',
      warnIfMissing: false);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
}

/// Ouvre l'ecran de faisabilite du sentier courant et laisse l'arbre se poser.
///
/// On NE tape PAS « Valider » ici : c'est justement ce que le correctif D1
/// encadre. L'ecran doit decider seul s'il a de quoi rendre un verdict.
Future<void> _ouvrirFaisabilite(WidgetTester tester, String trailId) async {
  try {
    final ctx = tester.element(find.byType(Navigator).first);
    GoRouter.maybeOf(ctx)?.go('/trail/$trailId/feasibility');
  } catch (e) {
    _ecart('ouverture de la faisabilite impossible : $e');
    return;
  }
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 10));
  // Une fois les criteres complets, le verdict s'affiche tout seul ; s'il
  // reste un bouton « Valider » ACTIF (cas du re-parcours), on le suit.
  final valider =
      textFrEn('Valider et voir mon résultat', 'Confirm and see my result');
  if (present(valider)) {
    final bouton = find.ancestor(
        of: valider.first, matching: find.byType(ElevatedButton));
    final actif = bouton.evaluate().isNotEmpty &&
        tester.widget<ElevatedButton>(bouton.first).onPressed != null;
    if (actif) {
      await tapIfPresent(tester, valider, P, 'nav', 'voir le resultat',
          warnIfMissing: false);
      await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
    }
  }
}

/// Table rase : plus aucune donnee de profil sur l'appareil.
Future<void> _effacerProfil(WidgetTester tester) async {
  final c = _container(tester);
  if (c == null) return;
  try {
    await c.read(hikerProfileProvider.notifier).clear();
    await c.read(pastHikesProvider.notifier).saveAll(const <PastHike>[]);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 4));
    _invalider(c);
  } catch (e) {
    _ecart('effacement du profil impossible : $e');
  }
}

/// Ecrit fiche + randos par le VRAI chemin (notifier -> repository -> prefs).
Future<void> _ecrireProfil(
  WidgetTester tester,
  HikerProfile profil,
  List<PastHike> randos,
) async {
  final c = _container(tester);
  if (c == null) return;
  try {
    await c.read(hikerProfileProvider.notifier).save(profil);
    await c.read(pastHikesProvider.notifier).saveAll(randos);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 4));
    _invalider(c);
    logStep(P, 'ecriture',
        'fiche age=${profil.age} ${profil.heightCm}cm ${profil.weightKg}kg, '
        '${randos.length} rando(s)');
  } catch (e) {
    _ecart('ecriture du profil impossible : $e');
  }
}

void _invalider(ProviderContainer c) {
  c.invalidate(hikerProfileProvider);
  c.invalidate(pastHikesProvider);
  c.invalidate(objectiveProfileProvider);
  c.invalidate(hikerLevelProvider);
  c.invalidate(feasibilityCriteriaProvider);
  c.invalidate(hasObjectiveProfileProvider);
  c.invalidate(feasibilityAssessmentProvider);
}

/// Ce que contient REELLEMENT le stockage durable de l'appareil.
Future<int?> _decoupageStocke(String trailId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getInt(retainedDurationPrefsKey(trailId));
  } catch (e) {
    _ecart('lecture du stockage durable impossible : $e');
    return null;
  }
}

/// « Redemarrage » : un graphe de providers TOUT NEUF, qui n'a jamais vu le
/// choix de l'utilisateur et ne peut le connaitre que par le stockage de
/// l'appareil. C'est exactement ce que fait l'application au lancement.
Future<int?> _relireApresRedemarrage(WidgetTester tester) async {
  final neuf = ProviderContainer();
  try {
    neuf.listen(selectedDurationProvider, (_, __) {});
    // Laisse l'hydratation asynchrone depuis les prefs se faire.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    return neuf.read(selectedDurationProvider);
  } catch (e) {
    _ecart('relecture apres redemarrage impossible : $e');
    return null;
  } finally {
    neuf.dispose();
  }
}
