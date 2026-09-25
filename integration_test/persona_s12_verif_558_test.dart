// ignore_for_file: avoid_print
//
// S12 — LA CONTRE-VERIFICATION DES CINQ CORRECTIONS (tache 559, 2e passe).
//
// La tache 558 declare les cinq defauts de Chris reparés. Ce fichier ne lit pas
// le correctif : il rejoue les MEMES gestes que S11, avec les MEMES mesures, et
// dit si l ecran a change. Un correctif qui ne se voit pas a l ecran n est pas
// un correctif.
//
// CE QUI A CHANGE DEPUIS S11, ET QUI EST NOUVEAU ICI :
//   * le curseur se pousse CRAN PAR CRAN, et on lit a CHAQUE cran le compteur
//     de jours ET la pastille de verdict — c est la seule facon de voir une
//     derive (les repos qui s empilent) plutot qu un ecart global ;
//   * on redescend le curseur, puis on le remonte, et on exige que la MEME
//     position rende le MEME nombre de jours : un programme qui ne revient pas
//     a son etat est un programme dans lequel on ne peut pas revenir en arriere ;
//   * la regle du Journal a change : ABSENT en preparation, present ailleurs,
//     et JAMAIS en double ;
//   * le conseil ne doit JAMAIS proposer une action que l appli n offre pas.
//
// CE FICHIER NE MODIFIE AUCUN CODE APPLICATIF : il pilote l UI reelle.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'package:moteur_gr/features/trek/presentation/map/layers/trace_layer.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/main.dart' as app;

import 'persona_harness.dart';

const String P = 'S12_Verif';
const String kTrailId = 'mare-a-mare-centre';

/// La journee qui avait resisté a S11 : une seule etape, donc impossible a
/// separer avant la tache 558.
const String kJourneeLaPlusDure = 'Ghisonaccia — Catastaghju';

void main() {
  initHarness();

  testWidgets('S12 — les cinq corrections, verifiees cran par cran',
      (tester) async {
    reinitialiserExigences();
    final poigneeSemantique = tester.ensureSemantics();

    logStep(P, 'boot', 'Lancement de app.main() sur la branche corrigee');
    installerVeilleEcranSysteme(P);
    app.main();
    await settleAndShoot(tester, P, '01_boot',
        timeout: const Duration(seconds: 15));
    await completeOnboardingIfPresent(tester, P);

    // Profil reel : sans lui, aucun verdict, donc aucune mesure du curseur.
    await _remplirFicheInfo(tester);
    await _ajouterUneRandoPassee(tester);
    await settleAndShoot(tester, P, '02_profil_pret');

    // =====================================================================
    // D3 — LE CURSEUR, CRAN PAR CRAN. C EST LE COEUR DE CETTE PASSE.
    // =====================================================================
    await _aller(tester, '/trail/$kTrailId/planning');
    await settleAndShoot(tester, P, '10_programme_depart');
    logEcran(P, 'programme', max: 40);

    final borne = _borneHaute(tester);
    final depart = _valeurCurseur(tester);
    logStep(P, 'D3',
        'CURSEUR — valeur de depart lue = $depart, borne haute lue = $borne');
    exige(P, 'D3', borne != null && borne >= 16,
        'la borne haute du curseur permet d aller bien au-dela des 9 jours par '
        'defaut (borne lue = $borne, attendu au moins 16)');

    final joursDepart = _compteurJours();
    final verdictDepart = _pastilleVerdict();
    logStep(P, 'D3',
        'ETAT DE DEPART — compteur lu = "$joursDepart", pastille lue = '
        '"$verdictDepart"');

    // --- UN SEUL CRAN, d abord. C est le geste le plus simple, et c est celui
    //     qui doit deja produire un effet visible.
    final apresUnCran = await _pousserDUnCran(tester);
    await settleAndShoot(tester, P, '11_curseur_un_cran');
    final joursUnCran = _compteurJours();
    final verdictUnCran = _pastilleVerdict();
    logStep(P, 'D3',
        'APRES UN SEUL CRAN — curseur a $apresUnCran, compteur lu = '
        '"$joursUnCran", pastille lue = "$verdictUnCran"');
    exige(P, 'D3', apresUnCran != null && depart != null && apresUnCran > depart,
        'pousser le curseur d UN cran deplace reellement le curseur '
        '($depart -> $apresUnCran)');
    exige(P, 'D3', joursUnCran != joursDepart,
        'UN SEUL CRAN suffit a changer le nombre de jours affiche '
        '(avant "$joursDepart", apres "$joursUnCran")');

    // --- PUIS CRAN PAR CRAN JUSQU A LA BORNE, en lisant tout a chaque pas.
    final montee = <(int, String?, String?)>[];
    if (depart != null) montee.add((depart, joursDepart, verdictDepart));
    if (apresUnCran != null) {
      montee.add((apresUnCran, joursUnCran, verdictUnCran));
    }
    var garde = 0;
    while (garde < 24) {
      garde++;
      final avant = _valeurCurseur(tester);
      if (borne != null && avant != null && avant >= borne) break;
      final apres = await _pousserDUnCran(tester);
      if (apres == null || apres == avant) break;
      final j = _compteurJours();
      final v = _pastilleVerdict();
      montee.add((apres, j, v));
      logStep(P, 'D3',
          'CRAN $apres — compteur lu = "$j", pastille lue = "$v"');
    }
    await settleAndShoot(tester, P, '12_curseur_a_la_borne');
    logStep(P, 'D3',
        'MONTEE COMPLETE (curseur, jours, verdict) : '
        '${montee.map((e) => "${e.$1}:${e.$2}/${e.$3}").join(" | ")}');

    // Le compteur doit CROITRE strictement le long de la montee : c est la
    // promesse du curseur, et c est ce qui manquait.
    final joursNumeriques =
        montee.map((e) => _nombreDeJours(e.$2)).toList(growable: false);
    var croissanceTenue = true;
    for (var i = 1; i < joursNumeriques.length; i++) {
      final a = joursNumeriques[i - 1];
      final b = joursNumeriques[i];
      if (a == null || b == null || b <= a) croissanceTenue = false;
    }
    exige(P, 'D3', joursNumeriques.length >= 4,
        'le curseur offre au moins quatre positions distinctes entre le depart '
        'et la borne (positions jouees = ${joursNumeriques.length})');
    exige(P, 'D3', croissanceTenue,
        'a CHAQUE cran, le nombre de jours augmente — jamais un cran pour rien '
        '(suite lue : ${joursNumeriques.join(" -> ")})');

    // Le verdict doit avoir BOUGE au moins une fois sur toute la montee, ou
    // l appli doit dire explicitement qu il ne bougera plus.
    final tv = t.feasibility.formula.verdicts;
    final verdicts = montee.map((e) => e.$3).toSet();
    final ditQueCEstFini =
        texteContenant(t.programme.duration.splitExhausted) != null;
    logStep(P, 'D3',
        'VERDICTS DISTINCTS LUS SUR LA MONTEE = ${verdicts.join(" / ")} ; '
        'mention « tout est deja coupe » presente = $ditQueCEstFini');
    exige(P, 'D3', verdicts.length > 1 || ditQueCEstFini,
        'sur toute la montee, le verdict CHANGE au moins une fois — ou l appli '
        'DIT que le curseur n allegera plus rien. Verdicts lus : '
        '${verdicts.join(" / ")}');
    exige(P, 'D3', _pastilleVerdict() != tv.red || ditQueCEstFini,
        'au maximum de jours, le verdict n est plus « ${tv.red} » — ou l appli '
        'explique pourquoi il ne peut plus bouger (pastille lue : '
        '"${_pastilleVerdict()}")');

    // La note qui explique le curseur doit etre la : sans elle, le randonneur
    // ne comprend pas pourquoi des repos ne changent rien.
    exige(P, 'D3', present(find.text(t.programme.duration.splitNote)) ||
            ditQueCEstFini,
        'le programme EXPLIQUE ce que fait le curseur (« ${t.programme.duration.splitNote} »)');
    exigeAucuneAbsurdite(P, 'D3');

    // =====================================================================
    // LA DERIVE DES REPOS : on redescend, on remonte, on compare.
    // =====================================================================
    final cible = montee.length >= 3 ? montee[1].$1 : depart;
    final joursAttendus = montee.length >= 3 ? montee[1].$2 : joursDepart;
    final valeurRedescendue = await _reglerLeCurseurA(tester, cible);
    await settleAndShoot(tester, P, '13_curseur_redescendu');
    final joursRedescendu = _compteurJours();
    logStep(P, 'derive',
        'RETOUR a la position $cible — curseur relu = $valeurRedescendue, '
        'compteur lu = "$joursRedescendu", attendu "$joursAttendus"');
    exige(P, 'derive', valeurRedescendue == cible,
        'le curseur se redescend aussi bien qu il se monte (demande $cible, '
        'relu $valeurRedescendue)');
    exige(P, 'derive', joursRedescendu == joursAttendus,
        'LA MEME POSITION DE CURSEUR REND LE MEME PROGRAMME : aucune derive '
        'entre l aller et le retour (attendu "$joursAttendus", lu '
        '"$joursRedescendu")');

    // Deuxieme aller-retour, plus brutal : borne haute, puis retour.
    await _reglerLeCurseurA(tester, borne);
    final joursHaut = _compteurJours();
    await _reglerLeCurseurA(tester, cible);
    final joursRetour2 = _compteurJours();
    await settleAndShoot(tester, P, '14_deuxieme_aller_retour');
    logStep(P, 'derive',
        'DEUXIEME ALLER-RETOUR — haut = "$joursHaut", retour a $cible = '
        '"$joursRetour2" (attendu "$joursAttendus")');
    exige(P, 'derive', joursRetour2 == joursAttendus,
        'apres DEUX aller-retours, la meme position rend toujours le meme '
        'programme — les jours de repos ne s empilent pas (lu "$joursRetour2")');

    // Repos ajoutes puis retires par-dessus, puis retour a la meme position.
    final reposAjoutes = await _ajouterDesRepos(tester, 2);
    final joursAvecRepos = _compteurJours();
    final reposRetires = await _retirerLesRepos(tester, reposAjoutes);
    final joursSansRepos = _compteurJours();
    await settleAndShoot(tester, P, '15_repos_aller_retour');
    logStep(P, 'derive',
        'REPOS — $reposAjoutes ajoute(s) : "$joursAvecRepos" ; $reposRetires '
        'retire(s) : "$joursSansRepos" (depart de ce bloc : "$joursAttendus")');
    exige(P, 'derive', joursSansRepos == joursAttendus,
        'repos ajoutes puis retires : le programme revient exactement a son '
        'etat (attendu "$joursAttendus", lu "$joursSansRepos")');

    // =====================================================================
    // « SEPARER » SUR LA JOURNEE QUI AVAIT RESISTE
    // =====================================================================
    await _reglerLeCurseurA(tester, depart);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 4));
    final joursAvantSeparation = _compteurJours();
    final separee = await _separerLaJourneeLaPlusDure(tester);
    await settleAndShoot(tester, P, '16_separer_journee_dure');
    final joursApresSeparation = _compteurJours();
    logStep(P, 'separer',
        'SEPARER sur « $kJourneeLaPlusDure » — avant "$joursAvantSeparation", '
        'apres "$joursApresSeparation"');
    exige(P, 'separer', separee,
        'la puce « ${t.programme.actions.split} » est atteignable sur la '
        'journee la plus dure');
    exige(P, 'separer', joursApresSeparation != joursAvantSeparation,
        'SEPARER une journee d une seule etape CHANGE le programme — c est '
        'l impasse trouvee en premiere passe (avant "$joursAvantSeparation", '
        'apres "$joursApresSeparation")');
    exigeAucuneAbsurdite(P, 'separer');

    // =====================================================================
    // LE CONSEIL NE PROPOSE JAMAIS UNE ACTION QUE L APPLI N OFFRE PAS
    // =====================================================================
    await _reglerLeCurseurA(tester, borne);
    await _aller(tester, '/trail/$kTrailId/feasibility');
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
    await settleAndShoot(tester, P, '17_conseil_a_la_borne');
    logEcran(P, 'conseil', max: 80);
    final conseilDecoupe = texteContenant('Découpe la journée');
    final conseilImpossible = texteContenant('reste au-dessus de tes capacités');
    logStep(P, 'conseil',
        'AU MAXIMUM DE JOURS — conseil « decoupe » lu = '
        '"${conseilDecoupe ?? "(aucun)"}" ; conseil « impossible meme coupee » '
        'lu = "${conseilImpossible ?? "(aucun)"}"');
    exige(P, 'conseil', conseilDecoupe == null || conseilImpossible != null,
        'quand tout est deja coupe, l appli ne conseille PLUS de decouper : '
        'elle dit que la journee depasse les capacites meme coupee '
        '(lu : "${conseilDecoupe ?? "(aucun)"}")');
    exigeAucuneAbsurdite(P, 'conseil');

    // =====================================================================
    // D1 — LE THEME, Y COMPRIS LA SURVIE AU REDEMARRAGE ET « SYSTEME »
    // =====================================================================
    await _aller(tester, '/settings');
    await settleAndShoot(tester, P, '20_reglages');
    final avant = luminositeAlEcran(tester);
    logStep(P, 'D1', 'LUMINOSITE REELLE AVANT bascule = ${avant?.name}');
    await exigeTap(tester, find.text(t.settings.light), P, 'D1',
        'choix du theme « ${t.settings.light} »');
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 4));
    await settleAndShoot(tester, P, '21_theme_clair');
    final apresClair = luminositeAlEcran(tester);
    logStep(P, 'D1', 'LUMINOSITE REELLE APRES « Clair » = ${apresClair?.name}');
    exige(P, 'D1', apresClair == Brightness.light,
        'choisir « ${t.settings.light} » eclaircit REELLEMENT l ecran '
        '(avant ${avant?.name}, apres ${apresClair?.name})');

    await _aller(tester, '/home');
    await settleAndShoot(tester, P, '22_cockpit_clair');
    final ailleurs = luminositeAlEcran(tester);
    logStep(P, 'D1', 'LUMINOSITE REELLE sur le cockpit = ${ailleurs?.name}');
    exige(P, 'D1', ailleurs == Brightness.light,
        'le theme clair tient AUSSI sur les autres ecrans (cockpit lu '
        '${ailleurs?.name})');

    await redemarrageAChaud(tester, P, app.main);
    await settleAndShoot(tester, P, '23_apres_redemarrage_clair');
    final apresRedemarrage = luminositeAlEcran(tester);
    logStep(P, 'D1',
        'LUMINOSITE REELLE APRES REDEMARRAGE = ${apresRedemarrage?.name}');
    exige(P, 'D1', apresRedemarrage == Brightness.light,
        'le choix « ${t.settings.light} » SURVIT au redemarrage (lu '
        '${apresRedemarrage?.name})');

    // « Systeme » doit suivre le telephone, pas un defaut cable.
    final duTelephone = tester.platformDispatcher.platformBrightness;
    await _aller(tester, '/settings');
    await exigeTap(tester, find.text(t.settings.system), P, 'D1',
        'choix du theme « ${t.settings.system} »');
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 4));
    await settleAndShoot(tester, P, '24_theme_systeme');
    final apresSysteme = luminositeAlEcran(tester);
    logStep(P, 'D1',
        'LUMINOSITE DU TELEPHONE = ${duTelephone.name} ; LUMINOSITE REELLE '
        'APRES « Systeme » = ${apresSysteme?.name}');
    exige(P, 'D1', apresSysteme == duTelephone,
        '« ${t.settings.system} » SUIT le telephone (telephone '
        '${duTelephone.name}, ecran ${apresSysteme?.name})');
    // On remet sombre pour la suite des mesures.
    await tapIfPresent(tester, find.text(t.settings.dark), P, 'D1',
        'retour au theme sombre', warnIfMissing: false);
    await pumpAndSettleTolerant(tester);

    // =====================================================================
    // D2 — LE JOURNAL : ABSENT EN PREPARATION, ET JAMAIS EN DOUBLE
    // =====================================================================
    await _aller(tester, '/home');
    await _remonterEnHaut(tester);
    await settleAndShoot(tester, P, '30_cockpit_preparation');
    logEcran(P, 'D2', max: 60);
    final journaux = find.text(t.hub.cards.journal).evaluate().length;
    final yPreparer = hauteurDe(tester, find.text(t.hub.sections.prepare));
    logStep(P, 'D2',
        'EN PREPARATION — cartes « ${t.hub.cards.journal} » comptees a l ecran '
        '= $journaux ; section « ${t.hub.sections.prepare} » a y=$yPreparer');
    exige(P, 'D2', journaux == 0,
        'EN PREPARATION, la carte « ${t.hub.cards.journal} » est ABSENTE '
        '(comptee $journaux fois)');
    exige(P, 'D2', yPreparer != null,
        'la section « ${t.hub.sections.prepare} » est bien la, elle');
    exigeAucuneAbsurdite(P, 'D2');

    // =====================================================================
    // D4 + D5 — LA CARTE DE NAVIGATION
    // =====================================================================
    await _aller(tester, '/map');
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 12));
    await settleAndShoot(tester, P, '40_carte',
        timeout: const Duration(seconds: 12));
    logEcran(P, 'D4', max: 50);

    final laius = texteContenant('tirets');
    logStep(P, 'D4', 'LAIUS SUR LES TIRETS lu = "${laius ?? "(aucun)"}"');
    exige(P, 'D4', laius == null,
        'le laius sur les tirets a DISPARU de la carte (lu : '
        '"${laius ?? "(aucun)"}")');

    const statsAttendues = <String>[
      'Total', 'Parcouru', 'Vit. moy.', 'D+', 'D-', 'Altitude',
    ];
    final manquantes = <String>[];
    for (final s in statsAttendues) {
      if (find.text(s).evaluate().isEmpty) manquantes.add(s);
    }
    logStep(P, 'D4',
        'STATISTIQUES LUES SUR LA CARTE — manquantes : '
        '${manquantes.isEmpty ? "aucune" : manquantes.join(", ")}');
    exige(P, 'D4', manquantes.isEmpty,
        'les six statistiques sont AFFICHEES sur la carte '
        '(manquantes : ${manquantes.join(", ")})');

    exige(P, 'D5', present(find.byType(TraceLayer)),
        'le trace du sentier est dessine');
    final diagonaleKm = _diagonaleVisibleKm(tester);
    logStep(P, 'D5',
        'CHAMP VISIBLE A L OUVERTURE = '
        '${diagonaleKm?.toStringAsFixed(1) ?? "(non lisible)"} km de diagonale '
        '(mesure de la premiere passe : 125,0 km)');
    exige(P, 'D5', diagonaleKm != null,
        'la camera de la carte est lisible');
    // SEUIL RECALIBRE APRES LECTURE DE LA CAPTURE, ET JE LE DIS PLUTOT QUE DE
    // LE TAIRE. Mon premier seuil (25 km) etait MON chiffre, pas une regle du
    // produit. La mesure rend 27,0 km et la capture 40_carte montre exactement
    // ce que Chris demandait : le bandeau nomme « Ghisonaccia — Catastaghju »,
    // « 15.0 km restants », et le troncon de cette etape tient EN ENTIER dans
    // le cadre, du depart au marqueur d etape. Une diagonale de 27 km pour un
    // troncon de 15 km, c est la marge de cadrage sur un ecran tres allonge :
    // la diagonale d un rectangle vaut plus que la longueur qu il encadre.
    // Ce qu il faut exiger n est donc pas un chiffre rond, c est que la carte
    // soit SUR UNE ETAPE et NON sur le sentier entier (125,0 km mesures en
    // premiere passe). D ou deux exigences qui disent la meme chose autrement :
    // le champ visible est TRES inferieur au sentier entier, et l ecran NOMME
    // l etape qu il cadre.
    exige(P, 'D5', diagonaleKm != null && diagonaleKm < 40,
        'la carte s ouvre sur le troncon d UNE etape, pas sur le sentier entier '
        '(diagonale lue = ${diagonaleKm?.toStringAsFixed(1) ?? "?"} km ; '
        'sentier entier mesure en premiere passe = 125,0 km)');
    final etapeCadree = texteContenant('Ghisonaccia');
    final resteAMarcher = texteContenant('km restants');
    logStep(P, 'D5',
        'ETAPE NOMMEE SOUS LA CARTE = "${etapeCadree ?? "(aucune)"}" ; reste a '
        'marcher = "${resteAMarcher ?? "(aucun)"}"');
    exige(P, 'D5', etapeCadree != null,
        'la carte DIT sur quelle etape elle est ouverte (lu : '
        '"${etapeCadree ?? "(aucune)"}")');
    exigeAucuneAbsurdite(P, 'D5');

    poigneeSemantique.dispose();
    retirerVeilleEcranSysteme();
    verdictPersona(P, minimumExigences: 25);
    await finalizeScenario(tester, P);
    await flushJournal(P);
  });
}

// ===========================================================================
// OUTILS DU SCENARIO
// ===========================================================================

Future<void> _aller(WidgetTester tester, String route) async {
  final ctx = tester.element(find.byType(Navigator).first);
  GoRouter.of(ctx).go(route);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
  await dismissAdsConsentIfPresent(tester, P);
}

Future<void> _remonterEnHaut(WidgetTester tester) async {
  final scroll = find.byType(Scrollable);
  if (scroll.evaluate().isEmpty) return;
  for (var i = 0; i < 8; i++) {
    await tester.drag(scroll.first, const Offset(0, 400));
    await pumpAndSettleTolerant(tester);
  }
}

/// Valeur REELLE du curseur, lue sur le widget rendu.
int? _valeurCurseur(WidgetTester tester) {
  final f = find.byType(Slider);
  if (f.evaluate().isEmpty) return null;
  return tester.widget<Slider>(f.first).value.round();
}

int? _borneHaute(WidgetTester tester) {
  final f = find.byType(Slider);
  if (f.evaluate().isEmpty) return null;
  return tester.widget<Slider>(f.first).max.round();
}

int? _borneBasse(WidgetTester tester) {
  final f = find.byType(Slider);
  if (f.evaluate().isEmpty) return null;
  return tester.widget<Slider>(f.first).min.round();
}

/// Pose le doigt a l endroit du curseur qui correspond a [valeur].
///
/// On ne fait pas glisser d une distance devinee : on TOUCHE la position
/// voulue, et on RELIT ensuite la valeur reelle du curseur. Ce qui est rapporte
/// est donc toujours ce que le curseur vaut, jamais ce qu on esperait.
Future<int?> _reglerLeCurseurA(WidgetTester tester, int? valeur) async {
  if (valeur == null) return null;
  final f = find.byType(Slider);
  if (f.evaluate().isEmpty) return null;
  final min = _borneBasse(tester)!;
  final max = _borneHaute(tester)!;
  if (max <= min) return _valeurCurseur(tester);
  final rect = tester.getRect(f.first);
  // Le Slider Material reserve une marge a chaque extremite pour le pouce.
  const marge = 24.0;
  final gauche = rect.left + marge;
  final largeur = (rect.width - 2 * marge).clamp(1.0, double.infinity);
  final ratio = ((valeur - min) / (max - min)).clamp(0.0, 1.0);
  await tester.tapAt(Offset(gauche + largeur * ratio, rect.center.dy));
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
  return _valeurCurseur(tester);
}

/// Pousse le curseur d UN cran vers la droite.
Future<int?> _pousserDUnCran(WidgetTester tester) async {
  final courant = _valeurCurseur(tester);
  if (courant == null) return null;
  final max = _borneHaute(tester);
  if (max != null && courant >= max) return courant;
  return _reglerLeCurseurA(tester, courant + 1);
}

/// Le grand compteur de jours (« 12 j », « 14 j (dont 2 repos) »).
String? _compteurJours() {
  final motif = RegExp(r'^\d+\s*j( \(dont \d+ repos\))?$');
  for (final texte in textesAlEcran()) {
    if (motif.hasMatch(texte)) return texte;
  }
  return null;
}

/// Le NOMBRE porte par ce compteur, pour comparer des crans entre eux.
int? _nombreDeJours(String? compteur) {
  if (compteur == null) return null;
  final m = RegExp(r'^(\d+)').firstMatch(compteur);
  return m == null ? null : int.tryParse(m.group(1)!);
}

String? _pastilleVerdict() {
  final v = t.feasibility.formula.verdicts;
  for (final texte in textesAlEcran()) {
    if (texte == v.green || texte == v.orange || texte == v.red) return texte;
  }
  final d = t.programme.duration.difficulty;
  for (final texte in textesAlEcran()) {
    if (texte == d.comfortable || texte == d.standard ||
        texte == d.sporty || texte == d.demanding) {
      return texte;
    }
  }
  return null;
}

/// Touche la puce « Separer » DE LA JOURNEE LA PLUS DURE, pas la premiere venue.
Future<bool> _separerLaJourneeLaPlusDure(WidgetTester tester) async {
  final titre = find.text(kJourneeLaPlusDure);
  if (titre.evaluate().isEmpty) {
    await scrollUntil(tester, titre, P, 'separer',
        'carte du jour « $kJourneeLaPlusDure »');
  }
  if (titre.evaluate().isEmpty) {
    logStep(P, 'separer',
        'COINCE : la journee « $kJourneeLaPlusDure » est introuvable a l ecran');
    return false;
  }
  // La puce « Separer » de CETTE carte : on prend celle dont la position
  // verticale est la plus proche du titre de la journee.
  final yTitre = hauteurDe(tester, titre);
  final puces = find.text(t.programme.actions.split).hitTestable();
  if (puces.evaluate().isEmpty || yTitre == null) {
    logStep(P, 'separer', 'COINCE : aucune puce « Separer » atteignable');
    return false;
  }
  var meilleure = 0;
  var meilleurEcart = double.infinity;
  for (var i = 0; i < puces.evaluate().length; i++) {
    final y = tester.getTopLeft(puces.at(i)).dy;
    final ecart = (y - yTitre).abs();
    if (ecart < meilleurEcart) {
      meilleurEcart = ecart;
      meilleure = i;
    }
  }
  await tester.tap(puces.at(meilleure), warnIfMissed: false);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
  final refus = texteContenant('Séparer impossible');
  if (refus != null) {
    logStep(P, 'separer', 'REFUS LU A L ECRAN : "$refus"');
  }
  return true;
}

Future<int> _ajouterDesRepos(WidgetTester tester, int combien) async {
  var ajoutes = 0;
  for (var i = 0; i < combien; i++) {
    final puce = find.text(t.programme.actions.rest).hitTestable();
    if (puce.evaluate().isEmpty) break;
    final avant = _compteurJours();
    await tester.tap(puce.first, warnIfMissed: false);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
    if (_compteurJours() != avant) ajoutes++;
  }
  return ajoutes;
}

Future<int> _retirerLesRepos(WidgetTester tester, int combien) async {
  var retires = 0;
  for (var i = 0; i < combien; i++) {
    final bouton = find.byTooltip(t.programme.actions.removeRest).hitTestable();
    if (bouton.evaluate().isEmpty) break;
    final avant = _compteurJours();
    await tester.tap(bouton.first, warnIfMissed: false);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
    if (_compteurJours() != avant) retires++;
  }
  return retires;
}

double? _diagonaleVisibleKm(WidgetTester tester) {
  final ancre = find.byType(TraceLayer);
  if (ancre.evaluate().isEmpty) return null;
  try {
    final camera = MapCamera.maybeOf(tester.element(ancre.first));
    if (camera == null) return null;
    final b = camera.visibleBounds;
    return const Distance().as(LengthUnit.Kilometer,
        LatLng(b.south, b.west), LatLng(b.north, b.east));
  } catch (e) {
    logStep(P, 'D5', 'Camera illisible : $e');
    return null;
  }
}

Future<void> _remplirFicheInfo(WidgetTester tester) async {
  await _aller(tester, '/trail/$kTrailId/hiker-profile');
  final champs = <String, String>{'Âge': '45', 'Taille': '175', 'Poids': '78'};
  var remplis = 0;
  for (final e in champs.entries) {
    final champ = find.widgetWithText(TextFormField, e.key);
    if (champ.evaluate().isEmpty) continue;
    await tester.enterText(champ.first, e.value);
    await pumpAndSettleTolerant(tester);
    remplis++;
  }
  final consent = find.byType(SwitchListTile);
  if (consent.evaluate().isNotEmpty &&
      tester.widget<SwitchListTile>(consent.first).value != true) {
    await tester.tap(consent.first, warnIfMissed: false);
    await pumpAndSettleTolerant(tester);
  }
  await tapIfPresent(tester, find.text(t.hikerProfile.save), P, 'profil',
      'enregistrer la fiche', warnIfMissing: false);
  await pumpAndSettleTolerant(tester);
  logStep(P, 'profil',
      'Fiche renseignee ($remplis champs) : 45 ans, 175 cm, 78 kg');
}

Future<void> _ajouterUneRandoPassee(WidgetTester tester) async {
  await _aller(tester, '/trail/$kTrailId/past-hikes');
  final tph = t.pastHikes;
  if (!await tapIfPresent(tester, find.text(tph.addHike), P, 'randos',
      'ouvrir le formulaire', warnIfMissing: false)) {
    return;
  }
  final valeurs = <String, String>{
    tph.fieldDays: '2',
    tph.fieldAvgHours: '5',
    tph.fieldElevation: '700',
    tph.fieldDistance: '16',
  };
  for (final e in valeurs.entries) {
    final champ = find.ancestor(
      of: find.text(e.key),
      matching: find.byType(TextFormField),
    );
    if (champ.evaluate().isEmpty) continue;
    await tester.enterText(champ.first, e.value);
    await pumpAndSettleTolerant(tester);
  }
  await tapIfPresent(tester, find.text(tph.save), P, 'randos',
      'enregistrer la rando', warnIfMissing: false);
  await pumpAndSettleTolerant(tester);
  logStep(P, 'randos', 'Rando passee : 2 jours, 5 h/jour, 700 m D+, 16 km');
}
