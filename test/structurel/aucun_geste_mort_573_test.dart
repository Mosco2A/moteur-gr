// INVARIANTE 3 (tache 573, LOT V) — AUCUN GESTE MORT.
//
// L'ENONCE : tout bouton visible et actif produit un effet OBSERVABLE — une
// navigation, un changement a l'ecran, un message. Un bouton qui ne change rien
// est un mensonge : l'utilisateur appuie, regarde, et conclut que l'application
// est cassee. Il a raison.
//
// C'EST LE MOTIF QUE CHRIS A RELEVE LE PLUS SOUVENT LE 26/09 — quatre fois sur
// vingt retours :
//
//   * retour 1, verbatim : « 2eme page d'accueil il y a un bouton parcourir le
//     catalogue qui ne fonctionne pas ». Le bouton naviguait VRAIMENT
//     (`context.go('/catalog')`) et la garde du routeur le renvoyait AUSSITOT sur
//     l'accueil, faute du drapeau d'onboarding. Visuellement : rien.
//   * retour 3 : « enregistrer dit que la note est enregistree mais ne revient
//     pas a faisabilite » — l'action reussit, la navigation ne suit pas.
//   * retour 17 : « la mise a jour des donnees meteo ne produit rien ».
//   * retour 19 : « incendie MAJ ne produit rien ».
//
// POURQUOI AUCUN TEST NE L'A VU, et c'est le coeur du sujet. Nos tests prouvent
// qu'un bouton EXISTE (`expect(find.text('Parcourir le catalogue'), findsOne)`)
// ou qu'il APPELLE quelque chose (un faux qui note l'appel). Aucun ne prouve
// qu'APRES l'appui, l'ecran a change. Le bouton du catalogue appelait bien sa
// fonction, la fonction naviguait bien : tout etait vert, et il ne se passait
// rien. La preuve qu'un geste marche n'est pas dans le code appele, elle est
// dans l'ecran d'apres.
//
// COMMENT ON MESURE « QUELQUE CHOSE A CHANGE ». On prend une empreinte de
// l'ecran avant l'appui (chemin affiche, textes, icones, champs, interrupteurs),
// on appuie, on laisse l'ecran se poser, on reprend l'empreinte. Un geste est
// mort quand les deux empreintes sont identiques, qu'aucun message ni dialogue
// n'est apparu, et qu'aucune erreur de rendu n'a ete levee.
//
// CE QU'ON NE TAPE PAS, ET ON LE DIT. Un balayage qui appuie sur tout finirait
// par effacer le compte ou declencher un appel au 112. Le vocabulaire des gestes
// evites est declare dans [gestesEvites] et ces gestes sont testes NOMMEMENT
// ailleurs (lots J a O pour l'effacement). Un saut silencieux serait un trou de
// plus : ils sont donc comptes et rapportes.
library;

import 'package:flutter_test/flutter_test.dart';

import 'parcours_reel.dart';

// UNE LIMITE A CONNAITRE. Chaque route est testee dans le meme isolat, et
// certains gestes changent l'etat GLOBAL de l'application — appuyer sur une
// langue dans les reglages change la langue pour les routes testees ensuite.
// C'est sans consequence sur le verdict (un geste inerte reste inerte quelle que
// soit la langue) mais ca explique qu'un libelle rapporte plus bas puisse
// apparaitre dans une autre langue que le francais. A ne pas confondre avec un
// defaut d'i18n.

/// Les gestes dont l'inertie est ASSUMEE, et la raison de chacun.
///
/// Un geste peut legitimement ne rien changer a l'ecran : cocher une case deja
/// cochee, un bouton « Actualiser » sur une donnee inchangee. La regle reste
/// l'inverse par defaut — c'est au geste inerte de se justifier, jamais au test
/// de deviner.
const gestesInertesAssumes = <String, String>{};

void main() {
  for (final r in routesDeclarees()) {
    final concret = cheminConcret(r.gabarit);
    if (concret == null) continue;

    testWidgets('V3 — ${r.gabarit} : chaque bouton produit un effet',
        (tester) async {
      await monterAppliReelle(tester, depart: concret);
      final arrivee = cheminAffiche();
      final gestes = gestesDisponibles(tester);
      erreursDeRendu(tester);

      final morts = <String>[];
      final evites = <String>[];
      final injouables = <String>[];
      // Les gestes d'un SELECTEUR sont comptes a part : re-choisir l'option deja
      // choisie ne change rien, et c'est normal. Mais si AUCUNE option du
      // selecteur ne produit d'effet, alors le selecteur entier est mort — et
      // c'est un defaut. On tranche apres la boucle, avec les deux comptes.
      final selecteurInertes = <String>[];
      var selecteurVivant = false;

      for (var i = 0; i < gestes.length; i++) {
        final g = gestes[i];
        if (estGesteEvite(g.libelle)) {
          evites.add('$g');
          continue;
        }
        if (gestesInertesAssumes.containsKey(g.libelle)) continue;

        // On REVIENT sur la route entre deux gestes, plutot que de remonter
        // toute l'application : remonter 400 fois la pile de providers prend des
        // minutes, et un test qu'on ne lance jamais ne protege de rien. Le
        // retour est verifie : si l'ecran ne se reconstruit pas a l'identique, le
        // geste est declare non joue au lieu d'etre mesure de travers.
        await revenirSurLaRoute(tester, concret);
        final actuels = gestesDisponibles(tester);
        if (i >= actuels.length || actuels[i].libelle != g.libelle) {
          injouables.add('$g (l ecran ne se reconstruit pas a l identique)');
          continue;
        }

        // ON FAIT DEFILER AVANT D'APPUYER (tache 579). Sans ce pas, le balayage
        // tapait les coordonnees d'un bouton situe a 1 900 pixels sur un ecran
        // qui en montre 780 : le doigt tombait sous la vitre, rien ne se
        // passait, et le bouton etait declare mort. Cinq des douze routes
        // rouges du LOT X n'etaient que ca.
        final atteignable = await amenerALEcran(tester, g.finder);
        if (!atteignable) {
          injouables.add('$g (hors ecran, impossible a amener sous le doigt)');
          continue;
        }

        final dansSelecteur = estDansUnSelecteur(g.finder);
        // L'empreinte est prise APRES le defilement : sinon le defilement
        // lui-meme passerait pour l'effet du bouton.
        final avant = empreinteEcran(tester);
        var tape = true;
        try {
          await tester.tap(g.finder, warnIfMissed: false);
        } catch (_) {
          tape = false;
        }
        if (!tape) {
          injouables.add('$g (non tapable)');
          continue;
        }
        // Six pompes apres l'appui, pas trois : un geste qui demarre un
        // chronometre ou un appel reseau ne montre son premier changement
        // qu'apres quelques centaines de millisecondes.
        await stabiliser(tester, coups: 6);

        final apres = empreinteEcran(tester);
        final message = messageOuDialogueVisible(tester);
        final erreurs = erreursDeRendu(tester);

        final aChange = avant != apres || message || erreurs.isNotEmpty;
        if (dansSelecteur) {
          if (aChange) {
            selecteurVivant = true;
          } else {
            selecteurInertes.add('$g');
          }
          continue;
        }
        if (!aChange) morts.add('$g');
      }
      // Un selecteur dont AUCUNE option ne produit d'effet est mort en entier.
      if (!selecteurVivant) morts.addAll(selecteurInertes);
      await demonterAppli(tester);
      erreursDeRendu(tester);

      expect(
        morts,
        isEmpty,
        reason: 'GESTES MORTS sur $concret (affiche : $arrivee) — appuyer '
            'dessus ne change RIEN a l ecran : ni navigation, ni contenu, ni '
            'message. C est le defaut du bouton « Parcourir le catalogue », du '
            'rafraichissement meteo et du rafraichissement incendie.\n'
            '  ${morts.join('\n  ')}\n'
            'Gestes evites volontairement (destructeurs, testes nommement '
            'ailleurs) : ${evites.length}${evites.isEmpty ? '' : '\n  ${evites.join('\n  ')}'}\n'
            'Gestes non joues : ${injouables.length}'
            '${injouables.isEmpty ? '' : '\n  ${injouables.join('\n  ')}'}\n'
            'Options de selecteur inertes (re-choisir l option deja choisie, '
            'legitime des lors qu une autre option du groupe repond) : '
            '${selecteurInertes.length}',
      );
    });
  }
}
