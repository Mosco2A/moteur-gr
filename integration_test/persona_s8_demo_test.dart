// ignore_for_file: avoid_print
//
// S8 — LA DEMO, C'EST-A-DIRE LE NIVEAU GRATUIT DU MODELE (famille 1 + famille 3).
// NOUVEAU — tache 650.
//
// ---------------------------------------------------------------------------
// POURQUOI CE PERSONA N'EXISTAIT PAS, ET POURQUOI IL EXISTE MAINTENANT
// ---------------------------------------------------------------------------
//
// Jusqu'au 29/09, le niveau gratuit de StepWays etait un SENTIER : la « vitrine »
// mare-a-mare-centre, jouable sans achat. Toute la campagne personas reposait sur
// cette premisse — S1 la disait en toutes lettres.
//
// Christophe l'a renversee le 29/09 a 14:17, verbatim : « la prochaine fois que
// j'ouvre l'application je n'ai droit a rien ». Le lot 638 a retire TOUT sentier
// gratuit du catalogue. Le niveau gratuit n'a pas disparu pour autant : il a
// change de nature. CE N'EST PLUS UN SENTIER, C'EST UN MODE — la demo, ouverte
// par le bouton orange en tete du catalogue (lots 634 et 638), qui montre
// l'application de A a Z sur le VRAI Mare a Mare Centre, entier.
//
// PERSONNE NE LE TESTAIT SUR L'APPAREIL. Les tests de comportement
// (`demo_complete_638_test.dart`, `sortie_de_demo_649_test.dart`) le prouvent
// unite par unite, et ils sont verts. Ce qui manquait, c'est le PARCOURS : entrer,
// vivre, sortir, et verifier qu'on ne repart avec rien.
//
// ---------------------------------------------------------------------------
// CE QUE CE SCENARIO EXIGE, ET DANS CET ORDRE
// ---------------------------------------------------------------------------
//
//  1. LA PORTE : le bouton demo est en tete du catalogue, et il y est SEUL —
//     aucun sentier gratuit ne le double (bug 1).
//  2. LE SENTIER : la demo porte sur le Mare a Mare Centre COMPLET, sept etapes,
//     pas sur un sentier ampute (bug 8).
//  3. LE DROIT : la demo n'accorde RIEN. Le sentier n'est pas possede pendant la
//     demo, et il ne le sera pas davantage apres (garde-fou du lot 601).
//  4. LE SIGNAL : le bandeau orange est la, et il POUSSE l'ecran au lieu de le
//     recouvrir — le titre de la barre reste lisible (defaut 1 du build 8,
//     corrige par le lot 649).
//  5. CE QUI EST BARRE LE DIT : les actions du catalogue sont visiblement
//     indisponibles pendant la demo, et un appui l'EXPLIQUE (bug 14).
//  6. LE DEPART PART, ET IL S'ANNONCE SIMULE : « Démarrer » est actif en demo
//     (bug 16) et la ligne sous le bouton dit que rien ne sera enregistre.
//  7. LA RANDO SE JOUE : la simulation avance etape par etape jusqu'a l'arrivee.
//  8. LA SORTIE TIENT EN UN SEUL APPUI, et elle ramene a « Mes treks »
//     (bug 19 + defaut 2 du build 8, corrige par le lot 649).
//  9. ON NE REPART AVEC RIEN : apres la sortie, le sentier n'est toujours pas
//     possede et « Mes treks » est toujours vide.
//
// AUCUN `overrideWith` : tout passe par les ecrans et les providers de
// production. Ce test ne modifie pas l'application.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:moteur_gr/core/config/trail_catalog.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/services/session_demo.dart';
import 'package:moteur_gr/features/hub/presentation/widgets/hub_start_trek_button.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/main.dart' as app;

import 'persona_harness.dart';

const String P = 'S8_Demo';

/// Nombre d'etapes du Mare a Mare Centre complet (bug 8 : « pas un truc avec
/// 2 etapes »). Lu sur la DONNEE du catalogue, jamais recopie.
int get _etapesDuSentierDeDemo =>
    TrailCatalog.byId(kSentierDeProduction)?.totalStages ?? 0;

void main() {
  initHarness();

  testWidgets('S8 — la demo montre tout, et ne donne rien', (tester) async {
    reinitialiserExigences();
    final poigneeSemantique = tester.ensureSemantics();

    logStep(P, 'boot', 'Lancement de app.main() sur emulateur');
    installerVeilleEcranSysteme(P);
    app.main();
    await settleAndShoot(
      tester,
      P,
      '01_boot',
      timeout: const Duration(seconds: 12),
    );

    await completeOnboardingIfPresent(tester, P);
    await settleAndShoot(tester, P, '02_apres_onboarding');

    // =====================================================================
    // 1. LA PORTE — le bouton demo est en tete du catalogue, et il y est SEUL
    // =====================================================================
    await _allerAuCatalogue(tester);
    await settleAndShoot(tester, P, '03_catalogue');
    await exigeVisible(
      tester,
      boutonDemo,
      P,
      'porte',
      'le bouton « ${t.demo.boutonTitre} », en tete du catalogue',
    );
    // Le doublon du lot 601 — un SECOND Mare a Mare, gratuit et ampute — a ete
    // supprime par le bug 1. Sa trace visible etait la pastille « Gratuit ».
    exigeAbsent(
      find.text(t.catalog.freeBadge),
      P,
      'porte',
      'la pastille « Gratuit » : plus aucun sentier n est offert au catalogue',
    );
    exige(
      P,
      'porte',
      present(boutonAcheter(kSentierDeProduction)),
      'le sentier de production porte bien son « Acheter » (il est payant)',
    );

    // AVANT D'ENTRER : on note l'etat des droits. C'est la reference qui rendra
    // le point 9 demontrable — sans elle, « la demo n a rien donne » ne veut
    // rien dire.
    final possedeAvant = await sentierPossede(tester, kSentierDeProduction);
    exige(
      P,
      'porte',
      !possedeAvant,
      'AVANT la demo, le sentier n est pas possede (point de depart neutre)',
    );

    // =====================================================================
    // 2 + 3 + 4. ENTREE : le VRAI sentier, aucun droit, un bandeau qui pousse
    // =====================================================================
    final entre = await exigeTap(
      tester,
      boutonDemo,
      P,
      'entree',
      'le bouton « ${t.demo.boutonTitre} »',
    );
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
    await settleAndShoot(tester, P, '04_entree_demo');
    logStep(
      P,
      'entree',
      'Entree en demo = $entre ; route = ${_route(tester)} ; '
          'sentier actif = ${_sentierActif(tester)}',
    );

    await exigeVisible(
      tester,
      bandeauDemo,
      P,
      'signal',
      'le bandeau « ${t.demo.bandeau} » pendant la demo',
    );
    exige(
      P,
      'signal',
      present(find.text(t.demo.bandeau)),
      'le bandeau porte son libelle en toutes lettres',
    );
    // LE TITRE DE LA BARRE RESTE LISIBLE (defaut 1 du build 8, lot 649). Le
    // bandeau POUSSE l'ecran au lieu de le peindre par-dessus : le titre du
    // cockpit doit donc etre entierement visible, pas recouvert.
    exige(
      P,
      'signal',
      sortieDemo.hitTestable().evaluate().isNotEmpty,
      'le « ${t.demo.quitter} » du bandeau est ATTEIGNABLE au doigt '
          '(il ne repondait a aucun appui sur le build 8 — defaut 2, lot 649)',
    );

    // LE SENTIER EST LE VRAI, ET IL EST ENTIER (bug 8).
    exige(
      P,
      'sentier',
      _sentierActif(tester) == kSentierDeProduction,
      'la demo porte sur le sentier de production ($kSentierDeProduction), '
          'pas sur un sentier de demonstration separe',
    );
    exige(
      P,
      'sentier',
      kSentierDeDemo == kSentierDeProduction,
      'le sentier de demo declare par l application EST le sentier de '
          'production (une seule et meme donnee)',
    );
    exige(
      P,
      'sentier',
      _etapesDuSentierDeDemo >= 7,
      'le sentier parcouru en demo a ses $_etapesDuSentierDeDemo etapes '
          '(« la demo de Mare a Mare, pas un truc avec 2 etapes » — bug 8)',
    );

    // LA DEMO N'ACCORDE AUCUN DROIT (garde-fou du lot 601, regle #100945).
    final possedePendant = await sentierPossede(tester, kSentierDeProduction);
    exige(
      P,
      'droits',
      !possedePendant,
      'PENDANT la demo, le sentier n est toujours PAS possede : la demo '
          'MONTRE, elle ne debloque rien',
    );

    // =====================================================================
    // 5. CE QUI EST BARRE LE DIT (bug 14)
    // =====================================================================
    await _allerAuCatalogue(tester);
    await settleAndShoot(tester, P, '05_catalogue_en_demo');
    // Les deux actions du catalogue sont enveloppees dans `GriseEnDemo` : elles
    // sont visibles, inertes, et un appui EXPLIQUE pourquoi. Un bouton Material
    // simplement desactive serait MUET — c'est ce que le bug 14 refuse.
    final acheterEnDemo = boutonAcheter(kSentierDeProduction);
    if (exige(
      P,
      'grise',
      present(acheterEnDemo),
      'le bouton « Acheter » est toujours AFFICHE pendant la demo',
    )) {
      await tester.tap(acheterEnDemo.first, warnIfMissed: false);
      await pumpAndSettleTolerant(tester);
      await settleAndShoot(tester, P, '06_grise_dit_pourquoi');
      exige(
        P,
        'grise',
        present(find.byKey(const ValueKey('demo-indisponible'))) ||
            present(find.text(t.demo.indisponible)),
        'un appui sur une action barree pendant la demo EXPLIQUE pourquoi '
            '(« ${t.demo.indisponible} ») au lieu de ne rien faire',
      );
    }

    // =====================================================================
    // 6. LE DEPART PART, ET IL S'ANNONCE SIMULE (bug 16)
    // =====================================================================
    _go(tester, '/home');
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
    final startCta = textFrEn('Démarrer la randonnée', 'Start the trek');
    await scrollUntil(
      tester,
      startCta,
      P,
      'depart',
      'CTA « Démarrer la randonnée » (bas du cockpit)',
      maxScrolls: 25,
    );
    await settleAndShoot(tester, P, '07_cta_demarrer_demo');
    exige(
      P,
      'depart',
      present(departSimule),
      'le cockpit ANNONCE que le depart sera simule : « ${t.demo.departSimule} »',
    );
    exige(
      P,
      'depart',
      _ctaActif(tester) == true,
      'en demo, « Démarrer la randonnée » est ACTIF — la porte de preparation '
          'ne peut pas se franchir en demo (la fiche medicale est une ecriture, '
          'barree), donc c est la demo qui l ouvre (bug 16)',
    );

    final marqueSysteme = marqueEcranSysteme();
    await exigeTap(
      tester,
      startCta,
      P,
      'depart',
      'CTA « Démarrer la randonnée » en demo',
    );
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 10));
    await settleAndShoot(tester, P, '08_apres_depart_demo');
    // EN DEMO, AUCUNE QUESTION DE PROXIMITE ET AUCUNE PERMISSION : le GPS n'est
    // meme pas arme. Ni « Démarrer quand même ? », ni pre-vol, ni ecran systeme.
    exigeAbsent(
      find.byKey(const ValueKey('background-tracking-rationale-dialog')),
      P,
      'depart',
      'le pre-vol de permission de suivi : une demo ne demande AUCUNE '
          'permission de localisation',
    );
    exigeAbsent(
      murDeRealisation,
      P,
      'depart',
      'le mur payant : en demo on ne demande pas le droit, on SIMULE',
    );
    final systemePendantDepart = ecransSystemeDepuis(marqueSysteme);
    exige(
      P,
      'depart',
      systemePendantDepart.isEmpty,
      'AUCUN ecran systeme ne recouvre le depart en demo '
          '(detecte : ${systemePendantDepart.isEmpty ? "aucun" : systemePendantDepart.join(", ")})',
    );

    // =====================================================================
    // 7. LA RANDO SE JOUE, ETAPE PAR ETAPE, JUSQU'A L'ARRIVEE
    // =====================================================================
    await exigeVisible(
      tester,
      simulerDemo,
      P,
      'simulation',
      'le bouton de simulation, une fois la rando simulee lancee',
      timeout: const Duration(seconds: 10),
    );
    // On avance d'un cran de plus qu'il n'y a d'etapes : le dernier appui est
    // « Simuler l'arrivée ». On borne large et on s'arrete des que le bouton
    // disparait (le parcours est fini).
    var coups = 0;
    for (var i = 0; i < _etapesDuSentierDeDemo + 3; i++) {
      if (!present(simulerDemo)) break;
      await tester.tap(simulerDemo.first, warnIfMissed: false);
      await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
      coups++;
    }
    await settleAndShoot(tester, P, '09_simulation_terminee');
    logStep(
      P,
      'simulation',
      'Appuis de simulation joues = $coups pour '
          '$_etapesDuSentierDeDemo etapes ; bouton encore visible = '
          '${present(simulerDemo)}',
    );
    exige(
      P,
      'simulation',
      coups >= _etapesDuSentierDeDemo,
      'la simulation a parcouru les $_etapesDuSentierDeDemo etapes du '
          'sentier (joues : $coups)',
    );
    exige(
      P,
      'simulation',
      !present(simulerDemo),
      'une fois l arrivee simulee, le bouton de simulation DISPARAIT : il n y '
          'a plus rien a faire avancer',
    );

    // =====================================================================
    // 8. LA SORTIE TIENT EN UN SEUL APPUI, ET ELLE RAMENE A « MES TREKS »
    // =====================================================================
    // C'est LE defaut n° 2 du build 8 : « son Quitter n'a repondu a AUCUN de mes
    // trois appuis ». Un seul appui, et on verifie les DEUX moities : la demo
    // s'arrete, et on atterrit sur « Mes treks » (bug 19).
    final sorti = await exigeTap(
      tester,
      sortieDemo,
      P,
      'sortie',
      'le « ${t.demo.quitter} » du bandeau — UN SEUL appui',
    );
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 10));
    await settleAndShoot(tester, P, '10_apres_sortie');
    logStep(
      P,
      'sortie',
      'Sortie = $sorti ; route apres sortie = ${_route(tester)} ; '
          'bandeau encore la = ${present(bandeauDemo)}',
    );
    exigeAbsent(
      bandeauDemo,
      P,
      'sortie',
      'le bandeau de demo apres le premier appui sur « ${t.demo.quitter} »',
    );
    exige(
      P,
      'sortie',
      _route(tester).contains('/my-treks'),
      'la sortie ramene a « Mes treks » (route lue = ${_route(tester)}) — '
          '« quand on quitte le mode demo, ca doit revenir a Mes treks !!! »',
    );
    // LE CHOIX « CACHER » N'EST PAS PERDU, ET IL NE BLOQUE RIEN (bug 18 + 649) :
    // il est propose APRES la sortie, dans un message qu'on peut ignorer.
    exige(
      P,
      'sortie',
      present(find.byKey(const ValueKey('demo-sortie-faite'))) ||
          present(find.text(t.demo.sortieFaite)),
      'la fin de demo est ANNONCEE apres coup, sans rien bloquer '
          '(« ${t.demo.sortieFaite} »)',
    );

    // =====================================================================
    // 9. ON NE REPART AVEC RIEN
    // =====================================================================
    final possedeApres = await sentierPossede(tester, kSentierDeProduction);
    exige(
      P,
      'rien_ne_compte',
      !possedeApres,
      'APRES la demo, le sentier n est toujours PAS possede : une demo ne '
          'debloque rien (garde-fou du lot 601)',
    );
    _go(tester, '/my-treks');
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
    await settleAndShoot(tester, P, '11_mes_treks_apres_demo');
    final treks = find.byWidgetPredicate(
      (w) => w.key.toString().contains('trek-summary-'),
    );
    logStep(
      P,
      'rien_ne_compte',
      'Cartes de trek dans « Mes treks » apres la demo = '
          '${treks.evaluate().length} (ATTENDU 0)',
    );
    exige(
      P,
      'rien_ne_compte',
      treks.evaluate().isEmpty,
      '« Mes treks » est toujours VIDE apres la demo : la randonnee simulee '
          'n a rien ecrit',
    );

    // === CLOTURE ===
    exige(
      P,
      'run_valide',
      ecransSystemeBloquants().isEmpty,
      'aucune fenetre systeme n a recouvert l application pendant la demo '
          '(bloquants : ${ecransSystemeBloquants().join(", ")})',
    );
    poigneeSemantique.dispose();
    retirerVeilleEcranSysteme();
    verdictPersona(P, minimumExigences: 20);
    await finalizeScenario(tester, P);
    await flushJournal(P);
  });
}

// ===========================================================================
// OUTILS DU SCENARIO
// ===========================================================================

void _go(WidgetTester tester, String route) {
  try {
    final ctx = tester.element(find.byType(Navigator).first);
    GoRouter.maybeOf(ctx)?.go(route);
  } catch (e) {
    logStep(P, 'nav', 'COINCE : navigation vers $route impossible : $e');
  }
}

Future<void> _allerAuCatalogue(WidgetTester tester) async {
  _go(tester, '/catalog');
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
}

String _route(WidgetTester tester) {
  try {
    final ctx = tester.element(find.byType(Navigator).first);
    return GoRouter.maybeOf(
          ctx,
        )?.routerDelegate.currentConfiguration.uri.toString() ??
        '';
  } catch (_) {
    return '';
  }
}

String? _sentierActif(WidgetTester tester) {
  try {
    final element = tester.element(find.byType(Navigator).first);
    final c = ProviderScope.containerOf(element, listen: false);
    return c.read(trailConfigProvider).id;
  } catch (_) {
    return null;
  }
}

/// Lit l'etat REEL du CTA « Démarrer » : actif (onPressed non nul), grise, ou
/// absent de l'arbre. On ne suppose pas, on lit le widget.
/// On le cherche SOUS [HubStartTrekButton], comme S1 : `FilledButton.icon`
/// construit une Row, pas un Text — chercher le libelle dans `child` ne
/// trouverait jamais rien, et l'exigence echouerait pour la mauvaise raison.
bool? _ctaActif(WidgetTester tester) {
  final bouton = find.descendant(
    of: find.byType(HubStartTrekButton),
    matching: find.byType(FilledButton),
  );
  if (bouton.evaluate().isEmpty) return null;
  return tester.widget<FilledButton>(bouton.first).onPressed != null;
}
