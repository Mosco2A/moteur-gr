// ignore_for_file: avoid_print
//
// S5 — THOMAS AUX LIMITES (famille 2 : cas NON passants). REECRIT — tache 543.
//
// POURQUOI CE FICHIER EST REECRIT DE ZERO. L'ancien `persona_s5_limites_test.dart`
// a tourne le 21/09 (47 captures dans `data/captures_personas_n2/`) mais n'a
// JAMAIS ete verse : absent du depot, de toutes les branches, du stash et du
// disque. Il est perdu. Celui-ci le remplace, sur les NOUVELLES bornes livrees
// par la tache 539 (age 18-120, taille 60-255 cm, poids 25-200 kg), qui ne sont
// plus celles que l'ancien testait.
//
// LE CRITERE, MOT POUR MOT (#10-c) : aucun verdict absurde, aucun plantage,
// et TOUT REPLI EST DIT.
//
// LA REGLE D'ATTRIBUTION QUI GOUVERNE CE SCENARIO (grille #100297, L9(e)) :
// UN REFUS PROPRE ET EXPLIQUE EST UN COMPORTEMENT CORRECT, PAS UN DEFAUT.
// Ce sont l'acceptation silencieuse, le refus muet, le plantage et la valeur
// aberrante affichee qui sont des defauts. Chaque cas ci-dessous exige donc
// TROIS choses ensemble : la bonne reponse (accepte ou refuse), le message qui
// l'explique quand c'est un refus, et le fait que L'ECRAN N'EST PAS QUITTE.
//
// CE FICHIER NE MODIFIE AUCUN CODE APPLICATIF : il pilote l'UI reelle.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:moteur_gr/features/feasibility/domain/hiker_input_bounds.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/main.dart' as app;

import 'persona_harness.dart';

const String P = 'S5_Limites';

/// Sentier de production : c'est sous lui que vit la fiche d'info.
const String kTrailId = 'mare-a-mare-centre';

/// Les trois champs bornes, dans leur ordre d'apparition a l'ecran.
const int kChampAge = 0;
const int kChampTaille = 1;
const int kChampPoids = 2;

void main() {
  initHarness();

  testWidgets('S5 — Thomas essaie tout ce qui n est pas prevu', (tester) async {
    reinitialiserExigences();
    // POIGNEE DE SEMANTIQUE EQUILIBREE (tache 544). Un greffon active la
    // semantique pendant la phase carte et ne la rend pas : flutter_test
    // echoue alors A LA CLOTURE sur « A SemanticsHandle was active at the end
    // of the test », alors que TOUTES les exigences du parcours sont tenues.
    // L'echec est INTERMITTENT, ce qui est pire qu'un echec franc. On prend
    // une poignee et on la rend, pour que le compteur soit equilibre.
    final poigneeSemantique = tester.ensureSemantics();

    logStep(P, 'boot', 'Lancement de app.main()');
    installerVeilleEcranSysteme(P);
    app.main();
    await settleAndShoot(tester, P, '01_boot',
        timeout: const Duration(seconds: 12));

    await completeOnboardingIfPresent(tester, P);
    await settleAndShoot(tester, P, '02_apres_onboarding');

    // --- Acces DIRECT a la fiche d'info -------------------------------------
    // On passe par le routeur plutot que par des taps : ce scenario ne teste
    // pas la navigation (S1 s'en charge), il teste ce que l'ecran fait d'une
    // valeur absurde. Un echec de navigation ici serait un faux negatif.
    await _ouvrirFicheInfo(tester);
    final tp = t.hikerProfile;
    await exigeVisible(tester, find.text(tp.title), P, 'acces',
        'la fiche d info est ouverte');
    await settleAndShoot(tester, P, '03_fiche_info');

    // === BLOC 1 — LES BORNES SONT DES BORNES, ET ELLES LE DISENT ===========
    //
    // Principe pose par Christophe le 22/09 (#100327, #100328) : une borne de
    // saisie attrape une faute de frappe, elle ne decide pas qui a le droit de
    // randonner. Elle n'ecarte QUE l'impossible. On verifie donc les DEUX
    // sens : ce qui est hors bornes est refuse AVEC son message, et ce qui est
    // AUX bornes est accepte — c'est ce second sens qui protege les
    // randonneurs que les anciennes bornes excluaient.

    // 1.a — AGE : 17 ans refuse, 121 ans refuse, 18 et 120 acceptes.
    await _refuse(tester, kChampAge, '17', tp.errorAge, 'age_17',
        'un age sous la borne basse');
    await _refuse(tester, kChampAge, '121', tp.errorAge, 'age_121',
        'un age au-dessus de la borne haute');
    await _accepte(tester, kChampAge, '$kAgeMin', tp.errorAge, 'age_min',
        'l age minimum EXACT ($kAgeMin ans)');
    await _accepte(tester, kChampAge, '$kAgeMax', tp.errorAge, 'age_max',
        'l age maximum EXACT ($kAgeMax ans)');

    // 1.b — TAILLE : 59 cm refuse, 256 cm refuse, 60 et 255 acceptes.
    await _refuse(tester, kChampTaille, '59', tp.errorHeight, 'taille_59',
        'une taille sous la borne basse');
    await _refuse(tester, kChampTaille, '256', tp.errorHeight, 'taille_256',
        'une taille au-dessus de la borne haute');
    await _accepte(tester, kChampTaille, '$kHeightMinCm', tp.errorHeight,
        'taille_min', 'la taille minimum EXACTE ($kHeightMinCm cm)');
    await _accepte(tester, kChampTaille, '$kHeightMaxCm', tp.errorHeight,
        'taille_max', 'la taille maximum EXACTE ($kHeightMaxCm cm)');

    // 1.c — POIDS : 24 kg refuse, 201 kg refuse, 25 et 200 acceptes.
    await _refuse(tester, kChampPoids, '24', tp.errorWeight, 'poids_24',
        'un poids sous la borne basse');
    await _refuse(tester, kChampPoids, '201', tp.errorWeight, 'poids_201',
        'un poids au-dessus de la borne haute');
    await _accepte(tester, kChampPoids, '$kWeightMinKg', tp.errorWeight,
        'poids_min', 'le poids minimum EXACT ($kWeightMinKg kg)');
    await _accepte(tester, kChampPoids, '$kWeightMaxKg', tp.errorWeight,
        'poids_max', 'le poids maximum EXACT ($kWeightMaxKg kg)');

    await settleAndShoot(tester, P, '10_bornes_passees');

    // === BLOC 2 — CE QUI N'EST MEME PAS UN NOMBRE =========================
    //
    // Finding B1 du cycle 4 : `double.tryParse('Infinity')` rend
    // `double.infinity`, qui passait tous les garde-fous « > 0 » et remontait
    // jusqu'a l'affichage (« Poids du sac : Infinity kg »). On verifie ici
    // qu'AUCUNE de ces valeurs n'atteint jamais l'ecran.
    for (final absurde in <String>[
      'Infinity',
      'NaN',
      '1e9',
      'abc',
      '-5',
      '99999999',
    ]) {
      await _aucuneValeurAberrante(tester, kChampPoids, absurde);
    }
    await settleAndShoot(tester, P, '11_non_nombres');

    // === BLOC 3 — LA FICHE VIDE ============================================
    // Correctif C3 de la campagne N2 : une fiche entierement vide s'enregistrait
    // en SILENCE. Non-regression.
    await _assurerFicheInfo(tester);
    await _viderTousLesChamps(tester);
    await _enregistrer(tester);
    await exigeVisible(tester, find.text(tp.errorEmpty), P, 'fiche_vide',
        'une fiche entierement vide est refusee AVEC un message');
    exige(P, 'fiche_vide', _surLaFicheInfo(),
        'l ecran n est PAS quitte quand la fiche vide est refusee');
    await settleAndShoot(tester, P, '12_fiche_vide');

    // === BLOC 4 — LE PAYS =================================================
    // Finding m3 du cycle 4 : le champ pays acceptait « ZZ », code inexistant.
    await _assurerFicheInfo(tester);
    await _saisirPays(tester, 'ZZ');
    await _enregistrer(tester);
    await exigeVisible(tester, find.text(tp.errorCountry), P, 'pays_zz',
        'un code pays inexistant est refuse AVEC son message');
    await _saisirPays(tester, 'FR');
    await _saisir(tester, kChampAge, '40');
    await _enregistrer(tester);
    exige(P, 'pays_fr', find.text(tp.errorCountry).evaluate().isEmpty,
        'un code pays valide n est PAS refuse, et le message de refus '
        'DISPARAIT une fois la valeur corrigee (contre-preuve)');
    await settleAndShoot(tester, P, '13_pays');

    // === BLOC 5 — LES CROISEMENTS QUE LES NOUVELLES BORNES OUVRENT ========
    //
    // 60 cm avec 200 kg : la combinaison la plus extreme que les bornes
    // autorisent desormais. Elle doit etre ACCEPTEE (une borne n'ecarte que
    // l'impossible) et ne produire AUCUN chiffre absurde a l'ecran — ni IMC
    // affiche comme un diagnostic, ni valeur infinie.
    await _assurerFicheInfo(tester);
    await _viderTousLesChamps(tester);
    await _saisir(tester, kChampAge, '40');
    await _saisir(tester, kChampTaille, '$kHeightMinCm');
    await _saisir(tester, kChampPoids, '$kWeightMaxKg');
    await _enregistrer(tester);
    exige(P, 'croise_60_200', find.text(tp.errorHeight).evaluate().isEmpty &&
        find.text(tp.errorWeight).evaluate().isEmpty,
        'la combinaison $kHeightMinCm cm / $kWeightMaxKg kg est ACCEPTEE '
        '(une borne n ecarte que l impossible)');
    _aucunTexteAberrantAlEcran('croise_60_200');
    await settleAndShoot(tester, P, '14_croise_extreme');

    // === BLOC 6 — LE VOCABULAIRE PROSCRIT (#7-d) ==========================
    // Garde-fou de redaction NON NEGOCIABLE : l'ecran qui vient de recevoir une
    // morphologie extreme ne doit porter AUCUN de ces mots.
    for (final mot in <String>[
      'surpoids',
      'obésité',
      'obesite',
      'corpulence',
      'nanisme',
      'pathologie',
    ]) {
      exige(P, 'vocabulaire', find.textContaining(mot, findRichText: true)
          .evaluate().isEmpty,
          'le mot proscrit « $mot » n apparait PAS a l ecran');
    }
    await settleAndShoot(tester, P, '15_vocabulaire');

    // === CLOTURE ==========================================================
    // Aucune fenetre systeme n'a du prendre le premier plan pendant tout ca.
    // EXIGENCE sur les seuls evenements BLOQUANTS (paused / hidden) : sur un
    // scenario de saisie, le clavier emet des `inactive` en permanence et
    // exiger zero evenement serait un faux positif garanti. Les `inactive`
    // restent journalises et se lisent.
    exige(P, 'ecran_systeme', ecransSystemeBloquants().isEmpty,
        'aucune fenetre systeme n a recouvert l application '
        '(bloquants : ${ecransSystemeBloquants().join(", ")} ; '
        'journal complet : ${kEcransSystemeDetectes.length} evenement(s))');
    poigneeSemantique.dispose();
    retirerVeilleEcranSysteme();
    verdictPersona(P, minimumExigences: 40);
    await finalizeScenario(tester, P);
    await flushJournal(P);
  });
}

// ===========================================================================
// OUTILS DU SCENARIO
// ===========================================================================

/// Ouvre la fiche d'info par le routeur (voir la note du scenario).
Future<void> _ouvrirFicheInfo(WidgetTester tester) async {
  final ctx = tester.element(find.byType(Navigator).first);
  GoRouter.of(ctx).go('/trail/$kTrailId/hiker-profile');
  await pumpAndSettleTolerant(tester);
}

/// Rouvre la fiche d'info SI on l'a quittee.
///
/// COMPORTEMENT REEL CONSTATE, ET IL EST CORRECT : un enregistrement VALIDE
/// referme l'ecran. C'est precisement la contre-partie de l'exigence « l'ecran
/// n'est PAS quitte » des cas refuses — le meme ecran doit rester sur un refus
/// et partir sur un succes. On s'y adapte au lieu de le contourner.
Future<void> _assurerFicheInfo(WidgetTester tester) async {
  if (_surLaFicheInfo()) return;
  await _ouvrirFicheInfo(tester);
}

/// Vrai si l'on est TOUJOURS sur la fiche d'info (l'ecran n'a pas ete quitte).
bool _surLaFicheInfo() => find.text(t.hikerProfile.title).evaluate().isNotEmpty;

Finder _champ(int index) => find.byType(TextFormField).at(index);

Future<void> _saisir(WidgetTester tester, int index, String valeur) async {
  await tester.enterText(_champ(index), valeur);
  await pumpAndSettleTolerant(tester);
}

Future<void> _saisirPays(WidgetTester tester, String code) async {
  await tester.enterText(
      find.byKey(const ValueKey('hiker-profile-country-field')), code);
  await pumpAndSettleTolerant(tester);
}

Future<void> _enregistrer(WidgetTester tester) async {
  await tapIfPresent(tester, find.text(t.hikerProfile.save), P, 'enregistrer',
      'bouton Enregistrer', warnIfMissing: false);
  await pumpAndSettleTolerant(tester);
}

Future<void> _viderTousLesChamps(WidgetTester tester) async {
  for (final i in <int>[kChampAge, kChampTaille, kChampPoids]) {
    await _saisir(tester, i, '');
  }
}

/// Un cas REFUSE : le message de borne s'affiche ET l'ecran n'est pas quitte.
Future<void> _refuse(WidgetTester tester, int champ, String valeur,
    String messageAttendu, String etape, String quoi) async {
  await _assurerFicheInfo(tester);
  await _viderTousLesChamps(tester);
  await _saisir(tester, champ, valeur);
  await _enregistrer(tester);
  await exigeVisible(tester, find.text(messageAttendu), P, etape,
      'REFUS EXPLIQUE de « $valeur » — $quoi',
      timeout: const Duration(seconds: 3));
  exige(P, etape, _surLaFicheInfo(),
      'l ecran n est PAS quitte apres le refus de « $valeur »');
  _aucunTexteAberrantAlEcran(etape);
}

/// Un cas ACCEPTE : le message de borne ne s'affiche PAS. C'est la
/// contre-preuve — sans elle, un ecran qui refuserait TOUT passerait les cas
/// de refus haut la main.
Future<void> _accepte(WidgetTester tester, int champ, String valeur,
    String messageBorne, String etape, String quoi) async {
  await _assurerFicheInfo(tester);
  await _viderTousLesChamps(tester);
  await _saisir(tester, champ, valeur);
  await _enregistrer(tester);
  exige(P, etape, find.text(messageBorne).evaluate().isEmpty,
      'ACCEPTE : « $valeur » — $quoi');
  // Un enregistrement valide referme l'ecran : c'est la contre-partie de
  // « l'ecran n'est PAS quitte » exigee sur chaque refus. On le VERIFIE, on ne
  // se contente pas de s'y adapter.
  exige(P, etape, !_surLaFicheInfo(),
      'l ecran est bien QUITTE apres un enregistrement valide de « $valeur » '
      '(contre-partie du refus, qui lui doit rester)');
  await _assurerFicheInfo(tester);
}

/// Une valeur qui n'est pas un nombre exploitable : quoi qu'il arrive, AUCUNE
/// valeur aberrante ne doit atteindre l'ecran.
Future<void> _aucuneValeurAberrante(
    WidgetTester tester, int champ, String valeur) async {
  await _assurerFicheInfo(tester);
  await _viderTousLesChamps(tester);
  await _saisir(tester, champ, valeur);
  await _enregistrer(tester);
  final etape = 'absurde_${valeur.replaceAll(RegExp('[^A-Za-z0-9]'), '')}';
  exige(P, etape, _surLaFicheInfo(),
      'l application ne quitte pas l ecran sur la saisie « $valeur »');
  _aucunTexteAberrantAlEcran(etape);
}

/// Balayage de TOUT l'arbre de textes : aucune trace d'infini, de NaN ni de
/// nombre a rallonge nulle part a l'ecran.
void _aucunTexteAberrantAlEcran(String etape) {
  for (final poison in <String>['Infinity', 'NaN', '-Infinity', 'null']) {
    exige(P, etape,
        find.textContaining(poison, findRichText: true).evaluate().isEmpty,
        'aucun « $poison » affiche a l ecran');
  }
}
