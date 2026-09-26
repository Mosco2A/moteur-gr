// LOT X (tache 579) — CHAQUE GESTE MORT, NOMME, ET CE QU'IL PRODUIT MAINTENANT.
//
// L'invariante V3 (`test/structurel/aucun_geste_mort_573_test.dart`) DECLARE
// qu'un bouton est mort. Elle ne dit pas ce qu'il devrait faire a la place.
// Ces tests-ci le disent, un par un, en termes d'ECRAN : apres l'appui,
// l'utilisateur voit quoi ?
//
// CHACUN A ETE ECRIT ROUGE, AVANT SA CORRECTION. C'est la regle du lot : une
// correction sans test rouge prealable corrige peut-etre autre chose que le
// defaut. Le LOT U l'a prouve le matin meme — ses deux boutons de
// rafraichissement marchaient parfaitement, c'est la DATE affichee qui mentait.
//
// UN GESTE EST TESTE ICI PARCE QUE LE BALAYAGE NE LE TAPE PLUS : le bouton
// d'appel de l'ecran d'urgence (on ne compose pas un numero de secours en
// boucle dans une suite de tests). Le balayage le saute et le DIT ; il est
// couvert nommement ci-dessous.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../structurel/parcours_reel.dart';

/// Amene [f] sous le doigt puis appuie, comme un utilisateur.
Future<void> appuyerSur(WidgetTester tester, Finder f) async {
  expect(f, findsWidgets, reason: 'geste introuvable a l ecran');
  final atteignable = await amenerALEcran(tester, f.first);
  expect(atteignable, isTrue,
      reason: 'le geste ne peut pas etre amene sous le doigt');
  await tester.tap(f.first, warnIfMissed: false);
  await stabiliser(tester, coups: 8);
}

void main() {
  group('LOT X — un bouton qui ne produit rien est un mensonge', () {
    testWidgets(
        '/stages/:id — « Reessayer » sur une etape introuvable DIT qu il a '
        'reessaye', (tester) async {
      await monterAppliReelle(tester, depart: '/stages/mare-a-mare-centre');
      final bouton = find.widgetWithText(ElevatedButton, 'Réessayer');
      expect(bouton, findsWidgets,
          reason: 'le bouton de relance doit porter un libelle traduit');

      final avant = empreinteEcran(tester);
      await tester.tap(bouton.first, warnIfMissed: false);
      // UN SEUL BATTEMENT : l'essai doit se VOIR tout de suite, pas une fois
      // qu'il a echoue. C'est ce que le bouton ne faisait pas.
      await tester.pump(const Duration(milliseconds: 50));
      expect(empreinteEcran(tester) != avant, isTrue,
          reason: 'appuyer sur « Reessayer » ne montre RIEN : l utilisateur ne '
              'sait pas si son appui a ete pris');

      // Et quand le nouvel essai echoue lui aussi, il le DIT.
      await stabiliser(tester, coups: 14);
      expect(messageOuDialogueVisible(tester), isTrue,
          reason: 'un nouvel essai qui echoue doit le dire, sinon le bouton '
              'passe pour casse');
      await demonterAppli(tester);
      erreursDeRendu(tester);
    });

    testWidgets(
        '/trail/:id/transport — sans donnee transport, AUCUN onglet a appuyer',
        (tester) async {
      await monterAppliReelle(
        tester,
        depart: '/trail/mare-a-mare-centre/transport',
      );
      // Le sentier embarque n'a AUCUNE donnee transport. Deux onglets qui
      // ouvrent deux ecrans vides, c'est deux boutons morts : on les retire.
      expect(find.byType(TabBar), findsNothing,
          reason: 'des onglets qui ne montrent rien sont des gestes morts : '
              'sans donnee transport, il ne doit pas y avoir d onglet');
      expect(find.byType(Tab), findsNothing);
      // Et l ecran DIT pourquoi il est vide, au lieu de rester blanc.
      expect(textesVisibles(tester).length, greaterThan(1),
          reason: 'un ecran vide sans un mot laisse l utilisateur devant rien');
      await demonterAppli(tester);
      erreursDeRendu(tester);
    });

    testWidgets(
        '/trail/:id/checklist — « PARTAGER AVEC LE GROUPE » dit quand le '
        'partage echoue', (tester) async {
      await monterAppliReelle(
        tester,
        depart: '/trail/mare-a-mare-centre/checklist',
      );
      await appuyerSur(
        tester,
        find.widgetWithText(OutlinedButton, 'PARTAGER AVEC LE GROUPE'),
      );
      expect(messageOuDialogueVisible(tester), isTrue,
          reason: 'le partage part en fire-and-forget : quand la feuille de '
              'partage ne s ouvre pas, l utilisateur ne voit RIEN');
      await demonterAppli(tester);
      erreursDeRendu(tester);
    });

    testWidgets(
        '/trail/:id/checklist — « EXPORTER LA LISTE » dit quand l export '
        'echoue', (tester) async {
      await monterAppliReelle(
        tester,
        depart: '/trail/mare-a-mare-centre/checklist',
      );
      await appuyerSur(
        tester,
        find.widgetWithText(OutlinedButton, 'EXPORTER LA LISTE'),
      );
      expect(messageOuDialogueVisible(tester), isTrue,
          reason: 'meme defaut que le partage : l echec est invisible');
      await demonterAppli(tester);
      erreursDeRendu(tester);
    });

    testWidgets(
        '/trail/:id/packs — « Telecharger » passe EN COURS des l appui',
        (tester) async {
      await monterAppliReelle(tester, depart: '/trail/mare-a-mare-centre/packs');
      final avant = empreinteEcran(tester);
      await appuyerSur(
        tester,
        find.widgetWithText(ElevatedButton, 'Télécharger'),
      );
      // LE DEFAUT EXACT : le controleur posait « en cours », le premier
      // evenement du flux (`pending`) l'ecrasait aussitot, et la carte
      // retrouvait son etat d'avant l'appui — « Non telecharge / Telecharger ».
      expect(empreinteEcran(tester) != avant, isTrue,
          reason: 'l appui doit se voir tout de suite ; il etait annule par le '
              'premier evenement du flux');
      expect(find.byType(LinearProgressIndicator), findsWidgets,
          reason: 'la carte doit montrer la progression, pas ses boutons');
      // La suite du parcours — echec de la source, etat d erreur, message — ne
      // peut pas etre jouee ici : elle demande des entrees-sorties REELLES, que
      // le temps feint d un test de widgets ne fait jamais revenir. Elle est
      // couverte sans widgets par
      // `test/features/packs/pack_telechargement_579_test.dart`.
      await demonterAppli(tester);
      erreursDeRendu(tester);
    });

    testWidgets(
        '/trail/:id/walk-test — « Demarrer le test » sans GPS explique au lieu '
        'de ne rien faire', (tester) async {
      await monterAppliReelle(
        tester,
        depart: '/trail/mare-a-mare-centre/walk-test',
      );
      final avant = empreinteEcran(tester);
      await appuyerSur(
        tester,
        find.widgetWithText(ElevatedButton, 'Démarrer le test'),
      );
      expect(empreinteEcran(tester) != avant, isTrue,
          reason: 'la demande de permission GPS leve, personne ne rattrape, '
              'et l ecran ne bouge pas d un pixel');
      await demonterAppli(tester);
      erreursDeRendu(tester);
    });

    testWidgets('/trail/:id/feedback — « Envoyer » a vide dit CE QUI MANQUE',
        (tester) async {
      await monterAppliReelle(
        tester,
        depart: '/trail/mare-a-mare-centre/feedback',
      );
      await appuyerSur(tester, find.widgetWithText(ElevatedButton, 'Envoyer'));
      expect(messageOuDialogueVisible(tester), isTrue,
          reason: 'le champ vide fait sortir la fonction par la porte de '
              'derriere, sans un mot : l utilisateur appuie et rien n arrive');
      await demonterAppli(tester);
      erreursDeRendu(tester);
    });

    testWidgets(
        '/trail/:id/feedback — « Envoyer » avec un message le prend et le dit',
        (tester) async {
      await monterAppliReelle(
        tester,
        depart: '/trail/mare-a-mare-centre/feedback',
      );
      await tester.enterText(
        find.byType(TextField).first,
        'Un retour de test',
      );
      await stabiliser(tester, coups: 2);
      await appuyerSur(tester, find.widgetWithText(ElevatedButton, 'Envoyer'));
      expect(messageOuDialogueVisible(tester), isTrue,
          reason: 'un envoi accepte doit se confirmer a l ecran');
      await demonterAppli(tester);
      erreursDeRendu(tester);
    });

    testWidgets(
        '/accommodations-nearby — « Voir le site » dit quand le lien ne s ouvre '
        'pas', (tester) async {
      await monterAppliReelle(tester, depart: '/accommodations-nearby');
      await appuyerSur(
        tester,
        find.widgetWithText(OutlinedButton, 'Voir le site'),
      );
      expect(messageOuDialogueVisible(tester), isTrue,
          reason: 'le lanceur promet de retourner false sans lever ; il leve, '
              'donc le message prevu n est JAMAIS affiche');
      await demonterAppli(tester);
      erreursDeRendu(tester);
    });

    testWidgets(
        '/health — « Sauvegarder » sur un ecran ouvert en direct confirme sans '
        'vider la pile', (tester) async {
      await monterAppliReelle(tester, depart: '/health');
      await appuyerSur(
        tester,
        find.widgetWithText(ElevatedButton, 'Sauvegarder'),
      );
      expect(messageOuDialogueVisible(tester), isTrue,
          reason: 'l enregistrement doit se confirmer');
      expect(cheminAffiche(), isNotEmpty,
          reason: 'l ecran depile le navigateur sans verifier qu il y a '
              'quelque chose a depiler : la pile se vide et l appli n a plus '
              'de page');
      await demonterAppli(tester);
      erreursDeRendu(tester);
    });

    testWidgets(
        '/emergency — le bouton d appel dit quand le telephone ne peut pas '
        'composer (geste evite par le balayage, teste ici nommement)',
        (tester) async {
      await monterAppliReelle(tester, depart: '/emergency');
      final appel = find.widgetWithIcon(IconButton, Icons.phone);
      expect(appel, findsWidgets, reason: 'aucun bouton d appel a l ecran');
      await appuyerSur(tester, appel);
      expect(messageOuDialogueVisible(tester), isTrue,
          reason: 'sur l ecran d URGENCE, un appel qui echoue en silence est '
              'le pire endroit possible pour se taire');
      await demonterAppli(tester);
      erreursDeRendu(tester);
    });
  });
}
