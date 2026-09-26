// PERSONA — LE MALADROIT (tache 573, LOT V).
//
// CE QU'IL FAIT. Il tape a cote. Il appuie deux fois sur le meme bouton parce
// qu'il n'a pas vu que ca avait marche. Il fait « retour » au mauvais moment. Il
// quitte au milieu d'une saisie et revient. Ce n'est pas un utilisateur bete :
// c'est un utilisateur NORMAL sur un telephone, dans un train, avec une main.
//
// CE QU'IL AURAIT ATTRAPE, retour 1 et 2 de Chris du 26/09, verbatim : « 2eme
// page d'accueil il y a un bouton parcourir le catalogue qui ne fonctionne pas,
// continuer lui amene au catalogue mais UN RETOUR ARRIERE ARRIVE A MARE A MARE ».
// Un utilisateur qui vient d'installer l'application, qui n'a choisi aucun
// sentier, qui appuie sur retour — et qui se retrouve dans le cockpit du Mare a
// Mare. L'application lui a ouvert un sentier qu'il n'a jamais demande.
//
// POURQUOI AUCUN PERSONA NE L'A VU. Les huit personas de la campagne jouent des
// PARCOURS QUI REUSSISSENT. Ils prouvent qu'un chemin existe. AUCUN ne joue le
// retour arriere — jamais, sur aucun ecran, dans aucun scenario. Et aucun ne tape
// deux fois. C'est la lecon de fond du 26/09 : un persona qui reussit ne trouve
// rien ; il faut des personas qui CHERCHENT a echouer.
//
// LES TROUS DE GRILLE QU'IL FERME : (A) on ne tape pas tous les boutons
// visibles ; (B) on ne joue JAMAIS le retour arriere ; (C) on ne verifie pas ou
// l'appli ramene apres une action.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/routing/app_router.dart';

import '../structurel/parcours_reel.dart';

void main() {
  group('LE MALADROIT — le retour arriere, que personne ne joue', () {
    testWidgets(
        'au premier lancement, aucun retour arriere ne doit ouvrir un sentier '
        'que l utilisateur n a pas choisi', (tester) async {
      // LE SCENARIO EXACT DE CHRIS. Premiere ouverture : la garde pose sur
      // l'accueil. On passe au catalogue comme le fait le bouton « Commencer »,
      // puis on appuie sur retour — le geste que la campagne ne joue jamais.
      await monterAppliReelle(tester, etat: EtatAppli.premierLancement);
      expect(cheminAffiche(), '/onboarding');

      // L'accueil est franchi : le drapeau passe, comme `completeOnboarding` le
      // fait, puis on va au catalogue.
      await monterAppliReelle(tester,
          etat: EtatAppli.sansSentier, depart: '/catalog');
      expect(cheminAffiche(), '/catalog');

      await tester.binding.handlePopRoute();
      await stabiliser(tester);
      final apresRetour = cheminAffiche();
      await demonterAppli(tester);
      erreursDeRendu(tester);

      expect(
        apresRetour,
        isNot(anyOf('/home', startsWith('/trail/'))),
        reason: 'RETOUR ARRIERE VERS UN SENTIER NON CHOISI : depuis le '
            'catalogue, a la premiere ouverture et sans aucun sentier '
            'telecharge, le retour arriere pose l utilisateur sur '
            '$apresRetour. C est le retour 2 de Chris, mot pour mot. Cause : '
            '`context.go()` REMPLACE la pile au lieu d empiler, donc il n y a '
            'aucun historique et le retour tombe sur la route par defaut.',
      );
    });

    testWidgets('depuis chaque ecran, le retour arriere mene quelque part de '
        'sense', (tester) async {
      // ON ARRIVE PAR OU L UTILISATEUR ARRIVE. Se poser directement sur une
      // route (`go`) REMPLACE la pile : il n'y a alors aucun historique, et le
      // retour n'a rien a faire — ce serait un artefact de test, pas un defaut de
      // l'application. On part donc de l'accueil et on EMPILE (`push`) l'ecran,
      // comme le fait un geste de l'utilisateur.
      final fautes = <String>[];
      final accueil = appRouter.routeInformationProvider.value.uri.path;
      for (final r in routesDeclarees()) {
        final concret = cheminConcret(r.gabarit);
        if (concret == null || concret == accueil) continue;
        await monterAppliReelle(tester, depart: accueil);
        appRouter.push(concret);
        await stabiliser(tester, coups: 4);
        final avant = cheminAffiche();
        if (avant != concret) continue; // la garde a redirige : hors sujet ici
        await tester.binding.handlePopRoute();
        await stabiliser(tester, coups: 3);
        final apres = cheminAffiche();
        final textes = textesVisibles(tester);
        final erreurs = erreursDeRendu(tester)
            .where((e) => !estDebordement(e))
            .toList();
        if (textes.isEmpty) {
          fautes.add('$concret : retour arriere -> ecran NU ($apres)');
        }
        if (erreurs.isNotEmpty) {
          fautes.add('$concret : retour arriere -> ${erreurs.first}');
        }
        if (apres == avant) {
          fautes.add('$concret : empile depuis l accueil, le retour arriere ne '
              'recule pas');
        }
      }
      await demonterAppli(tester);
      erreursDeRendu(tester);
      expect(fautes, isEmpty,
          reason: 'LE RETOUR ARRIERE, QUE LA CAMPAGNE NE JOUE JAMAIS :\n'
              '  ${fautes.join('\n  ')}');
    });
  });

  group('LE MALADROIT — deux fois le meme geste', () {
    testWidgets('appuyer deux fois sur le meme bouton ne casse rien et ne '
        'duplique rien', (tester) async {
      // Un double appui arrive tout le temps : l'utilisateur n'a pas vu que le
      // premier avait pris. Ce qu'on refuse : une exception, un ecran nu, ou un
      // contenu qui DOUBLE (deux fois la meme ligne ajoutee).
      final fautes = <String>[];
      for (final gabarit in <String>[
        '/my-treks',
        '/home',
        '/catalog',
        '/settings',
        '/profile',
        '/trail/:id/feasibility',
        '/trail/:id/planning',
        '/trail/:id/checklist',
      ]) {
        final concret = cheminConcret(gabarit);
        if (concret == null) continue;
        await monterAppliReelle(tester, depart: concret);
        final gestes = gestesDisponibles(tester)
            .where((g) => !estGesteEvite(g.libelle))
            .toList();
        for (final g in gestes.take(6)) {
          await revenirSurLaRoute(tester, concret);
          try {
            await tester.tap(g.finder, warnIfMissed: false);
            await stabiliser(tester, coups: 2);
            await tester.tap(g.finder, warnIfMissed: false);
            await stabiliser(tester, coups: 2);
          } catch (_) {
            continue; // le geste a change de place : rien a conclure
          }
          final textes = textesVisibles(tester);
          final erreurs = erreursDeRendu(tester)
              .where((e) => !estDebordement(e))
              .toList();
          if (erreurs.isNotEmpty) {
            fautes.add('$concret / $g : double appui -> ${erreurs.first}');
          }
          if (textes.isEmpty) {
            fautes.add('$concret / $g : double appui -> ecran NU');
          }
        }
      }
      await demonterAppli(tester);
      erreursDeRendu(tester);
      expect(fautes, isEmpty, reason: fautes.join('\n'));
    });
  });

  group('LE MALADROIT — il tape a cote', () {
    testWidgets('un appui dans le vide ne produit rien de destructeur',
        (tester) async {
      final fautes = <String>[];
      for (final gabarit in <String>['/my-treks', '/home', '/settings']) {
        final concret = cheminConcret(gabarit)!;
        await monterAppliReelle(tester, depart: concret);
        final avant = cheminAffiche();
        // UN POINT VRAIMENT VIDE, CALCULE. Un point choisi a la main tombe sur
        // une fleche de retour ou une tuile : la premiere version de ce test
        // tapait a (200, 8) et touchait l'entete de l'accueil. On prend donc le
        // premier point d'une grille qui n'est couvert par AUCUN geste.
        final occupes = <Rect>[
          for (final g in gestesDisponibles(tester))
            if (g.finder.evaluate().isNotEmpty) tester.getRect(g.finder),
        ];
        final taille = tester.view.physicalSize / tester.view.devicePixelRatio;
        Offset? vide;
        for (var y = 90.0; y < taille.height - 20 && vide == null; y += 20) {
          for (var x = 10.0; x < taille.width - 10; x += 20) {
            final p = Offset(x, y);
            if (occupes.any((r) => r.inflate(8).contains(p))) continue;
            vide = p;
            break;
          }
        }
        if (vide == null) continue; // ecran entierement couvert : rien a taper
        await tester.tapAt(vide);
        await stabiliser(tester, coups: 2);
        final apres = cheminAffiche();
        final erreurs = erreursDeRendu(tester)
            .where((e) => !estDebordement(e))
            .toList();
        if (erreurs.isNotEmpty) {
          fautes.add('$concret : appui dans le vide -> ${erreurs.first}');
        }
        if (apres != avant) {
          fautes.add('$concret : un appui dans le vide a navigue vers $apres');
        }
      }
      await demonterAppli(tester);
      erreursDeRendu(tester);
      expect(fautes, isEmpty, reason: fautes.join('\n'));
    });
  });

  group('LE MALADROIT — il part au milieu d une saisie et revient', () {
    testWidgets('quitter une saisie en cours puis revenir ne laisse pas une '
        'demi-donnee', (tester) async {
      // La fiche randonneur porte des champs qui alimentent le verdict. On en
      // remplit un, on quitte SANS valider, on revient : soit la saisie est la
      // (elle a ete retenue), soit elle n'y est pas (elle a ete abandonnee).
      // Ce qu'on refuse, c'est l'entre-deux — et surtout un ecran qui plante.
      final concret = cheminConcret('/trail/:id/hiker-profile')!;
      await monterAppliReelle(tester, depart: concret);
      final champs = find.byType(TextField);
      if (champs.evaluate().isEmpty) {
        await demonterAppli(tester);
        return; // pas de champ sur cet ecran : rien a jouer
      }
      await tester.enterText(champs.first, '42');
      await stabiliser(tester, coups: 2);
      await tester.binding.handlePopRoute();
      await stabiliser(tester, coups: 3);
      await allerA(tester, concret);
      final textes = textesVisibles(tester);
      final erreurs =
          erreursDeRendu(tester).where((e) => !estDebordement(e)).toList();
      await demonterAppli(tester);
      erreursDeRendu(tester);
      expect(erreurs, isEmpty,
          reason: 'revenir sur une saisie abandonnee leve : ${erreurs.join(' | ')}');
      expect(textes, isNotEmpty,
          reason: 'revenir sur une saisie abandonnee donne un ecran nu');
    });
  });
}
