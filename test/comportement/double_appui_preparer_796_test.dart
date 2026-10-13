// GARDE — TACHE 796 : « PREPARER » NE PART QU'UNE FOIS.
//
// LE GESTE SURVEILLE. Le bouton « Preparer » d'une carte du catalogue fait deux
// choses qui ne se defont pas : il BASCULE le sentier actif, puis il CHANGE
// D'ECRAN. Le randonneur, lui, appuie deux fois — parce qu'une transition dure
// trois cents millisecondes et que, pendant ce temps, la carte reste sous
// son doigt. Le persona MALADROIT (tache 573) joue exactement ce doigt-la.
//
// POURQUOI LA GARDE APPELLE LE GESTIONNAIRE AU LIEU DE TAPER DES PIXELS, ET
// C'EST LA LECON DE MESURE DE CE LOT. `tester.tap` tape des COORDONNEES : il
// demande au `Finder` ou est le bouton, puis frappe ce point. Pendant la
// transition d'ecran, l'ecran ENTRANT est dessine PAR-DESSUS l'ecran sortant ;
// le point du bouton « Preparer » est couvert par une carte du cockpit, et
// c'est ELLE qui recoit le second coup. Mesure faite sur ce depot : le second
// `tester.tap` sur « Preparer » atterrissait sur la carte « Faisabilite » du
// cockpit et ouvrait `/trail/<sentier>/feasibility`. Un test ecrit comme ca ne
// mesure pas le double appui : il mesure un appui sur deux boutons differents.
//
// On appelle donc le gestionnaire du bouton DEUX FOIS, dans le meme geste
// synchrone. C'est le pire cas reel — deux appuis avant la moindre image — et
// c'est sans ambiguite : c'est bien CE bouton qu'on appuie deux fois.
//
// CE QUE CHACUNE DES DEUX GARDES PROUVE, ET IL FAUT LE DIRE SANS LE FLATTER.
// Mesure faite sur le commit d'avant ce lot (2123c5a8) :
//
//   * « PREPARER » : le double appui ne cassait RIEN, deja. Cette garde-ci ne
//     rougit donc PAS sur le code d'avant — elle VERROUILLE un contrat (un
//     geste, une navigation) qui n'etait vrai que par coincidence, les deux
//     effets du geste se trouvant etre des no-op repetes. C'est une garde de
//     non-regression, pas la preuve d'un defaut.
//   * LE BOUTON DEMO : le double appui PERDAIT le sentier d'avant, et cette
//     garde-la ROUGIT bien sur le code d'avant (elle notait « le sentier de la
//     demo » au lieu du vrai). C'est le seul defaut de double appui que ce lot
//     ait trouve sur cet ecran, et il rouvrait un bug ferme (bug 19).
//
// Le rouge du persona MALADROIT, lui, n'est AUCUN des deux : il vient d'une
// VRAIE bascule de sentier apres qu'un cockpit a deja ete construit. Le rapport
// de la tache 796 porte les trois experiences de controle qui l'etablissent.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/trail_selection.dart';
import 'package:moteur_gr/core/routing/app_router.dart';
import 'package:moteur_gr/core/services/session_demo.dart';
import 'package:moteur_gr/shared/widgets/app_button.dart';

import '../structurel/parcours_reel.dart';

/// Le conteneur de providers de l'application montee, pour LIRE un etat sans
/// passer par un pixel.
ProviderContainer _conteneur(WidgetTester tester) => ProviderScope.containerOf(
  tester.element(find.byType(MaterialApp).first),
  listen: false,
);

void main() {
  group('796 — le second appui sur « Preparer » ne declenche rien', () {
    testWidgets('deux appuis dans le meme geste ne lancent qu UNE navigation', (
      tester,
    ) async {
      await monterAppliReelle(tester, depart: '/catalog');

      final bouton = find.byKey(
        const ValueKey('catalog-enter-mare-a-mare-centre'),
      );
      expect(
        bouton,
        findsOneWidget,
        reason:
            'LE DECOR DE LA GARDE A CHANGE : la carte du sentier '
            'mare-a-mare-centre ne porte plus de « Preparer » sous cette '
            'cle. Ce n est pas le defaut de la tache 796 qui est en cause, '
            'c est ce test qui ne pointe plus rien — repointe-le avant de '
            'conclure quoi que ce soit.',
      );
      final appuyer = tester.widget<AppButton>(bouton).onPressed;
      expect(
        appuyer,
        isNotNull,
        reason:
            'Le bouton « Preparer » est desactive : hors demo il doit toujours '
            'etre appuyable (tache 639 avenant, la preparation sans achat est '
            'un etat legitime).',
      );

      // ON COMPTE LES ANNONCES DU ROUTEUR, ET SEULEMENT PENDANT LES DEUX
      // APPUIS. Une navigation = une annonce. L'ecoute est retiree AVANT de
      // pomper, pour que la transition d'ecran — qui annonce aussi — ne se
      // melange pas a la mesure. Ce qu'on compte est donc exactement : combien
      // de fois le GESTE a navigue.
      var annonces = 0;
      void compter() => annonces++;
      appRouter.routerDelegate.addListener(compter);
      appuyer!();
      appuyer();
      appRouter.routerDelegate.removeListener(compter);

      await stabiliser(tester, coups: 4);
      final erreurs = erreursDeRendu(
        tester,
      ).where((e) => !estDebordement(e)).toList();
      final arrivee = cheminAffiche();
      await demonterAppli(tester);
      erreursDeRendu(tester);

      expect(
        annonces,
        1,
        reason:
            'LE SECOND APPUI A RELANCE LA NAVIGATION ($annonces annonces du '
            'routeur pour UN SEUL geste). « Preparer » bascule le sentier '
            'actif PUIS change d ecran : le rejouer rebascule et renavigue, '
            'alors qu on ne peut pas entrer deux fois dans le meme sentier. Le '
            'geste doit etre IDEMPOTENT — des qu on est a destination, il n a '
            'plus d objet (cf. la garde de `_enterTrail`, '
            'trail_catalog_screen.dart).',
      );
      expect(
        erreurs,
        isEmpty,
        reason: 'LE DOUBLE APPUI A CASSE :\n  ${erreurs.join("\n  ")}',
      );
      expect(
        arrivee,
        '/home',
        reason:
            'Le double appui doit mener ou le simple appui mene : le '
            'cockpit du sentier choisi. Arrivee constatee : $arrivee.',
      );
    });
  });

  // LE DEFAUT QUE LE DOUBLE APPUI PRODUIT VRAIMENT, ET IL N'EST PAS SUR
  // « PREPARER » (tache 796).
  //
  // « Preparer » rejoue le MEME ordre, MEMES valeurs : rebasculer sur le
  // sentier qu'on vient de choisir et renaviguer vers l'ecran ou l'on est deja
  // ne change rien. Mesure a l'appui : sur le code d'avant, le double appui sur
  // « Preparer » ne leve rien et ne duplique rien.
  //
  // LE BOUTON DEMO, LUI, MEMORISE. [entrerEnDemo] note LE SENTIER D'AVANT pour
  // le restaurer a la sortie — c'est le correctif du bug 19 (tache 638,
  // DEM-260930-1028, « on est toujours en mode demo sans le savoir »). Il lit
  // ce « sentier d'avant » dans l'etat COURANT, et le premier appui a deja
  // bascule sur le sentier de demo. Un second appui note LE SENTIER DE DEMO
  // comme sentier a restaurer : en quittant la demo, le randonneur est
  // « restaure » DANS la demo. Le double appui RE-OUVRE un bug ferme.
  group('796 — le second appui sur le bouton demo ne perd pas le sentier', () {
    testWidgets('deux appuis gardent en memoire le VRAI sentier d avant', (
      tester,
    ) async {
      await monterAppliReelle(tester, depart: '/catalog');

      // LE DECOR : UN RANDONNEUR DONT LE SENTIER ACTIF N'EST PAS CELUI DE LA
      // DEMO. Il le faut, et ce n'est pas un detail de confort : la demo porte
      // sur le MARE A MARE CENTRE COMPLET (tache 638, bug 8), qui est aussi le
      // sentier par defaut du catalogue. Parti de la, « le sentier d avant » et
      // « le sentier de la demo » sont le MEME, et l ecrasement qu on traque
      // serait invisible. On choisit donc d abord un autre sentier du
      // catalogue — pourvu qu il ne soit pas celui de la demo.
      final conteneur = _conteneur(tester);
      final autre = conteneur
          .read(availableTrailsProvider)
          .map((t) => t.id)
          .firstWhere(
            (id) => id != kSentierDeDemo,
            orElse: () => throw StateError(
              'LE CATALOGUE N A QU UN SENTIER, ET C EST CELUI DE LA DEMO : '
              'ce test ne distingue plus le sentier d avant du sentier de '
              'demo. Ce n est pas un defaut de l app, c est ce test qui '
              'perd son decor — donne-lui un second sentier.',
            ),
          );
      conteneur.read(selectedTrailIdProvider.notifier).state = autre;
      await stabiliser(tester, coups: 2);
      erreursDeRendu(tester);
      final sentierReel = conteneur.read(selectedTrailIdProvider);
      expect(sentierReel, autre);

      final bouton = find.byKey(const ValueKey('catalog-demo-button'));
      expect(
        bouton,
        findsOneWidget,
        reason:
            'Le bouton demo orange n est plus en tete du catalogue sous cette '
            'cle (tache 634) : repointe ce test avant de conclure.',
      );
      final appuyer = tester.widget<InkWell>(bouton).onTap!;

      // Deux appuis dans le meme geste, comme un pouce presse.
      appuyer();
      appuyer();
      await stabiliser(tester, coups: 4);

      final session = conteneur.read(sessionDemoProvider);
      final erreurs = erreursDeRendu(
        tester,
      ).where((e) => !estDebordement(e)).toList();
      await demonterAppli(tester);
      erreursDeRendu(tester);

      expect(
        session.active,
        isTrue,
        reason: 'Le double appui doit laisser la demo ACTIVE, comme un appui.',
      );
      expect(
        session.sentierAvant,
        sentierReel,
        reason:
            'LE SECOND APPUI A ECRASE LA MEMOIRE DU SENTIER D AVANT. Il a note '
            '« ${session.sentierAvant} » au lieu de « $sentierReel » — '
            'c est-a-dire le sentier de la DEMO : le premier appui avait '
            'deja bascule. Consequence a la sortie de demo : `quitterLaDemo` '
            'restaure ce qu il croit etre le sentier d avant et replace le '
            'randonneur DANS la demo. C est le bug 19 (tache 638, '
            'DEM-260930-1028) rouvert par un pouce qui appuie deux fois. '
            'L entree en demo doit etre IDEMPOTENTE : deja en demo, on n y '
            'entre pas une seconde fois.',
      );
      expect(
        erreurs,
        isEmpty,
        reason: 'LE DOUBLE APPUI A CASSE :\n  ${erreurs.join("\n  ")}',
      );
    });
  });
}
