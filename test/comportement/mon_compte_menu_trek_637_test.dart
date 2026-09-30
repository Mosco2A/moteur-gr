// TACHE 637, VOLET 2 — « MON COMPTE DEPUIS LE MENU TREK = ECRAN NOIR ».
//
// LE RETOUR DE CHRISTOPHE, 30/09 11:02 (DEM-260930-1103), verbatim : « Mon compte
// depuis le menu trek = ecran noir ; depuis la demo ca fonctionne ».
//
// ---------------------------------------------------------------------------
// LA CAUSE, MESUREE
// ---------------------------------------------------------------------------
//
// `BootstrapGate` (`main.dart`) enveloppe TOUS les ecrans, et son `build` armait
// cinq services de fond par de simples `ref.watch`. Trois d'entre eux sont des
// `Provider<void>` SYNCHRONES : quand leur creation leve, `ref.watch` releve la
// meme erreur DANS le `build` de la garde. Flutter remplace alors l'arbre ENTIER
// par un `ErrorWidget` — en debug un cadre rouge qui nomme la panne, en RELEASE un
// rectangle gris-noir SANS UN MOT. Et comme la garde se reconstruit a chaque
// changement de provider qu'elle observe, elle releve : le noir revient. « Boucle
// sur ecran noir », mot pour mot.
//
// CE QUI LEVAIT, MESURE DANS CE FICHIER MEME : `monteeEnBaseDemarreeProvider`
// (tache 635) lisait `authServiceProvider` de facon SYNCHRONE, et ce provider
// CONSTRUIT `FirebaseAuthService`, donc touche `FirebaseAuth.instance`. Tout ce qui
// leve la — Firebase non initialise, services Google Play absents ou trop vieux,
// authentification non activee sur le projet — noircissait l'application entiere.
// La mesure exacte obtenue en montant l'arbre reel : « ProviderException: Tried to
// use a provider that is in error state » … « thrown building BootstrapGate(...) ».
//
// ET C'EST POURQUOI LA DEMO MARCHAIT. Le mode demo n'arme ni la montee en base ni
// les ecritures du trek (gardes `enDemoProvider`) : les providers qui levaient
// n'etaient jamais construits. Le meme geste, hors demo, les construisait — d'ou
// « depuis le menu trek » et pas « depuis la demo ».
//
// CHACUN DE CES CINQ ARMEMENTS PROMETTAIT « NON BLOQUANT » DANS SON PROPRE
// COMMENTAIRE. C'etait faux, et c'est la lecon : une promesse de non-blocage que le
// code ne tient pas est un piege, pas une garantie.
//
// ---------------------------------------------------------------------------
// CE QUE CE FICHIER MESURE
// ---------------------------------------------------------------------------
//
// LE GESTE DE CHRISTOPHE EN ENTIER, trek REEL demarre, dans l'arbre de
// `main.dart` — `BootstrapGate` compris.
//
// IL EST SEUL DANS SON FICHIER, ET C'EST MESURE : les autres tests du volet 2
// construisent de vrais services de fond (base locale, ordonnanceur, identite) et
// l'etat qu'ils laissent derriere eux empechait ce geste-ci de monter le cockpit.
// `flutter test` isole les FICHIERS, pas les tests : un fichier, un isolat, aucune
// contagion. La CAUSE et le FILET sont mesures dans
// `services_de_fond_ne_levent_pas_637_test.dart`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/branding/stepways_icons.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/features/auth/presentation/profile_screen.dart';
import 'package:moteur_gr/features/hub/presentation/hub_screen.dart';
import 'package:moteur_gr/features/safety/presentation/refus_sauvegarde_systeme_dialog.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';

import '../structurel/parcours_reel.dart';

void main() {
  /// Les erreurs de rendu QUI COMPTENT.
  ///
  /// Deux exclusions, et toutes deux assumees :
  ///  * un debordement de texte n'est pas un ecran noir ;
  ///  * `FlutterBackgroundService` n'existe QUE sur Android et iOS. Demarrer un
  ///    trek reel sur la machine de test l'appelle forcement, et il se plaint a la
  ///    destruction de l'arbre. C'est une limite de l'environnement de test, pas un
  ///    defaut de l'application — et c'est nomme ici plutot que tu.
  List<String> erreursQuiComptent(WidgetTester tester) => erreursDeRendu(tester)
      .where((e) => !estDebordement(e))
      .where((e) => !e.contains('FlutterBackgroundService'))
      .toList();

  group('637/2 — le geste de Christophe, trek REEL en cours', () {
    testWidgets('« Mon compte » depuis le menu du trek se dessine, sans une '
        'seule erreur', (tester) async {
      RefusSauvegardeSystemeDialog.reinitialiserLeVerrou();
      await monterAppliReelle(
        tester,
        etat: EtatAppli.enRoute,
        avecEnveloppesDeMain: true,
      );

      // La question de sauvegarde est posee au premier rendu : on y repond comme
      // le randonneur, avant de continuer.
      if (find
          .byKey(RefusSauvegardeSystemeDialog.cleValider)
          .evaluate()
          .isNotEmpty) {
        await tester.tap(find.byKey(RefusSauvegardeSystemeDialog.cleValider));
        await stabiliser(tester);
      }

      await allerA(tester, '/home');
      expect(
        find.byType(HubScreen),
        findsOneWidget,
        reason: 'le cockpit du trek doit etre a l ecran avant le geste',
      );

      // ON DEMARRE UN TREK REEL, PAS LA DEMO : c'est la condition de Christophe,
      // et c'est ce qui arme les services que le mode demo laisse dormir.
      final conteneur = ProviderScope.containerOf(
        tester.element(find.byType(HubScreen)),
      );
      final trailId = conteneur.read(trailConfigProvider).id;
      await conteneur.read(trekSessionManagerProvider.notifier).start(trailId);
      await stabiliser(tester);
      expect(
        conteneur.read(trekSessionManagerProvider).status,
        TrackingSessionStatus.recording,
        reason: 'le trek doit VRAIMENT etre en cours',
      );

      // `start` emmene sur la carte : le randonneur revient a son menu de trek.
      await allerA(tester, '/home');
      await stabiliser(tester);

      // LE GESTE : le bouton « Mon compte » du menu du trek.
      final monCompte = find.byWidgetPredicate(
        (w) => w is StepIcon && w.asset == StepwaysIcons.monCompte,
      );
      expect(
        monCompte,
        findsOneWidget,
        reason: 'le menu du trek doit porter « Mon compte »',
      );
      await tester.tap(monCompte.first);
      // ON POMPE LONGTEMPS : les armements de fond d'un trek reel (identite,
      // montee en base, cadence) se resolvent APRES la premiere frame du profil.
      await stabiliser(tester, coups: 40);

      final dessine = find.byType(ProfileScreen).evaluate().isNotEmpty;
      final erreurs = erreursQuiComptent(tester);
      await demonterAppli(tester);

      expect(erreurs, isEmpty, reason: 'erreurs vues : $erreurs');
      expect(
        dessine,
        isTrue,
        reason:
            'ECRAN NOIR : « Mon compte » depuis le menu du trek doit se '
            'dessiner',
      );
    });
  });
}
