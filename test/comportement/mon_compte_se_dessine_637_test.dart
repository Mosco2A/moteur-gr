// TACHE 637, VOLET 2 — « MON COMPTE : BOUCLE SUR ECRAN NOIR ».
//
// LE RETOUR DE CHRISTOPHE sur le build 7, le 30/09 a 10:13 (DEM-260930-1013),
// verbatim : « clique sur Mon compte -> boucle sur ecran noir ».
//
// POURQUOI CE VOLET EST SEPARE DU PREMIER, ET N'EST PAS ABSORBE DEDANS. L'ecran
// de profil est le SECOND appelant de
// `RefusSauvegardeSystemeDialog.poserSiNecessaire`, donc le soupcon etait
// legitime. Il ne tient pas a la mesure, et ce fichier dit pourquoi au lieu de le
// supposer :
//  * l'appel du profil est dans le `onTap` de la tuile « connexion Google », pas
//    dans un `build` : il ne peut pas noircir un ecran qu'on vient d'ouvrir ;
//  * l'ecran de profil est une ROUTE (`/profile`), donc son contexte est SOUS le
//    `Navigator` — l'exact oppose de la situation qui plantait au volet 1 ;
//  * `/profile` figure dans les routes exemptees du garde de redirection
//    (`redirectForPath`), donc aucune boucle de redirection ne part de la.
//
// CE QUE CE FICHIER VERIFIE : que « Mon compte » se DESSINE, apres un demarrage
// complet, par le geste reel du HUB (`context.push('/profile')`) comme par un
// acces direct, et qu'aucune erreur de rendu n'en sort. Un ecran noir en release
// est presque toujours un `ErrorWidget`, c'est-a-dire une exception levee pendant
// un `build` : ce test l'attraperait.
//
// LE TROU DE HARNAIS EST FERME EN PASSANT. Le socle `parcours_reel.dart` montait
// `MaterialApp.router(routerConfig: appRouter)` SANS le `builder` de `main.dart` :
// ni cadre demo (634), ni porte de consentement (617), ni reprise orpheline. Il
// disait « application reelle » et il lui manquait les trois widgets dont un
// cassait. Ce fichier ouvre « Mon compte » DANS LES DEUX MONTAGES —
// `avecEnveloppesDeMain` compris — pour que la question soit tranchee des deux
// cotes.
//
// CE QUI RESTE HORS DE PORTEE, ET IL FAUT LE DIRE : la garde d'amorce
// (`_BootstrapGate`) est privee a `main.dart`, donc aucun test de `test/` ne peut
// la monter. Son loader peint le vert sombre du splash (#1F3D2B) : s'il bouclait,
// cela ressemblerait de pres a « boucle sur ecran noir ». C'est la seule
// hypothese que ce fichier ne peut pas fermer.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/routing/app_router.dart';
import 'package:moteur_gr/features/auth/presentation/profile_screen.dart';
import 'package:moteur_gr/features/safety/presentation/refus_sauvegarde_systeme_dialog.dart';

import '../structurel/parcours_reel.dart';

void main() {
  /// Les erreurs de rendu qui comptent : un debordement de texte n'est pas un
  /// ecran noir, et le confondre avec un plantage rendrait ce test illisible.
  List<String> erreursQuiComptent(WidgetTester tester) =>
      erreursDeRendu(tester).where((e) => !estDebordement(e)).toList();

  group('637/2 — « Mon compte » se dessine apres un demarrage complet', () {
    testWidgets('par le GESTE DU HUB (push), l ecran de profil se dessine et '
        'aucune erreur n en sort', (tester) async {
      await monterAppliReelle(tester, etat: EtatAppli.enRoute);

      // LE GESTE REEL, pas un `go` de test : `hub_screen.dart` fait
      // `context.push('/profile')`.
      appRouter.push('/profile');
      await stabiliser(tester);

      final dessine = find.byType(ProfileScreen).evaluate().isNotEmpty;
      final erreurs = erreursQuiComptent(tester);
      await demonterAppli(tester);

      expect(
        erreurs,
        isEmpty,
        reason:
            'ECRAN NOIR : une exception pendant un `build` donne un '
            'ErrorWidget, c est-a-dire un ecran noir en release. Erreurs '
            'vues : $erreurs',
      );
      expect(
        dessine,
        isTrue,
        reason: 'ECRAN NOIR : l ecran de profil doit etre dans l arbre',
      );
    });

    testWidgets('par un acces direct, on se POSE sur /profile et on y RESTE', (
      tester,
    ) async {
      // « BOUCLE » EST LE MOT DE CHRISTOPHE : on verifie que la route ne repart
      // pas ailleurs toute seule, en laissant passer plusieurs frames de plus.
      await monterAppliReelle(tester, etat: EtatAppli.enRoute);
      await allerA(tester, '/profile');
      final aussitot = cheminAffiche();
      await stabiliser(tester, coups: 10);
      final plusTard = cheminAffiche();

      final dessine = find.byType(ProfileScreen).evaluate().isNotEmpty;
      final erreurs = erreursQuiComptent(tester);
      await demonterAppli(tester);

      expect(aussitot, '/profile');
      expect(
        plusTard,
        '/profile',
        reason: 'BOUCLE : la route ne doit pas repartir ailleurs seule',
      );
      expect(dessine, isTrue);
      expect(erreurs, isEmpty, reason: 'erreurs vues : $erreurs');
    });

    testWidgets('on y va et on en revient DEUX FOIS, sans rien qui boucle', (
      tester,
    ) async {
      await monterAppliReelle(tester, etat: EtatAppli.enRoute);
      final accueil = cheminAffiche();

      final vues = <bool>[];
      final retours = <String>[];
      for (var i = 0; i < 2; i++) {
        appRouter.push('/profile');
        await stabiliser(tester);
        vues.add(find.byType(ProfileScreen).evaluate().isNotEmpty);
        await tester.binding.handlePopRoute();
        await stabiliser(tester, coups: 3);
        retours.add(cheminAffiche());
      }
      final erreurs = erreursQuiComptent(tester);
      await demonterAppli(tester);

      expect(vues, [
        true,
        true,
      ], reason: 'le second passage doit dessiner comme le premier : $vues');
      expect(
        retours,
        [accueil, accueil],
        reason: 'le retour doit ramener au meme endroit deux fois : $retours',
      );
      expect(erreurs, isEmpty, reason: 'erreurs vues : $erreurs');
    });

    testWidgets('SOUS LES ENVELOPPES REELLES DE main.dart, « Mon compte » se '
        'dessine encore', (tester) async {
      // LE MONTAGE QUI MANQUAIT. Cadre demo + porte de consentement + reprise
      // orpheline, dans l'ordre de `main.dart`, donc AU-DESSUS du `Navigator` :
      // c'est la configuration qui plantait en production. La preuve rouge du
      // plantage lui-meme est dans
      // `plantage_null_check_refus_sauvegarde_637_test.dart` ; ici on verifie
      // qu'avec ces trois enveloppes en place, « Mon compte » se dessine.
      RefusSauvegardeSystemeDialog.reinitialiserLeVerrou();
      await monterAppliReelle(
        tester,
        etat: EtatAppli.enRoute,
        avecEnveloppesDeMain: true,
      );

      // La question de sauvegarde est posee au premier rendu (aucune decision
      // enregistree) : on y repond, comme le randonneur, avant de continuer.
      if (find
          .byKey(RefusSauvegardeSystemeDialog.cleValider)
          .evaluate()
          .isNotEmpty) {
        await tester.tap(find.byKey(RefusSauvegardeSystemeDialog.cleValider));
        await stabiliser(tester);
      }

      appRouter.push('/profile');
      await stabiliser(tester);

      final dessine = find.byType(ProfileScreen).evaluate().isNotEmpty;
      final erreurs = erreursQuiComptent(tester);
      await demonterAppli(tester);

      expect(
        erreurs,
        isEmpty,
        reason:
            'c est le montage qui plantait avant le correctif 637 : '
            '$erreurs',
      );
      expect(
        dessine,
        isTrue,
        reason:
            'ECRAN NOIR : sous les enveloppes reelles aussi, « Mon '
            'compte » doit se dessiner',
      );
    });

    testWidgets('meme SANS sentier telecharge, « Mon compte » reste atteignable', (
      tester,
    ) async {
      // `/profile` est une donnee de COMPTE : le garde l'exempte explicitement
      // (`redirectForPath`). Si cette exemption disparaissait, le geste tomberait
      // sur /catalog ou /no-data — ce qui, vu du telephone, ressemble a une
      // boucle.
      await monterAppliReelle(tester, etat: EtatAppli.sansSentier);
      await allerA(tester, '/profile');

      final chemin = cheminAffiche();
      final dessine = find.byType(ProfileScreen).evaluate().isNotEmpty;
      final erreurs = erreursQuiComptent(tester);
      await demonterAppli(tester);

      expect(chemin, '/profile');
      expect(dessine, isTrue);
      expect(erreurs, isEmpty, reason: 'erreurs vues : $erreurs');
    });
  });
}
