// TACHE 649 — LE « QUITTER » MUET DU BUILD 8, REPRODUIT PUIS FERME.
//
// CE QUE CHRISTOPHE A VU (build 8, AAB 0.1.4+8, passage emulateur du 30/09
// 17:37) : la pastille orange « MODE DEMO ... Quitter » recouvre le titre de la
// barre sur TOUS les ecrans, et son « Quitter » ne repond a AUCUN appui — trois
// appuis, deux positions, deux ecrans, alors que tous les autres appuis de la
// session fonctionnent.
//
// LA CAUSE, MESUREE ET NON SUPPOSEE. A chaque appui, l'emulateur ecrit UNE seule
// ligne : « FirebaseCrashlytics: Timeout exceeded while awaiting app exception
// callback from Analytics listener ». Autrement dit : l'appui ARRIVE, une
// exception est levee, Crashlytics l'enregistre, et rien ne s'affiche. C'est le
// MEME defaut que la tache 637, au meme endroit de l'arbre :
//
//     Navigator operation requested with a context that does not include a
//     Navigator.
//       Navigator.of         (navigator.dart:2936)  -> return navigator!
//       showDialog           (dialog.dart:1504)
//       afficherSortieDeDemo (cadre_demo.dart:169)
//       _PastilleDeSortie.build.<anonymous>  (cadre_demo.dart:117)
//       _InkResponseState.handleTap
//
// `CadreDemo` est pose dans le `builder` de `MaterialApp.router` (`main.dart`,
// ligne 549). `WidgetsApp` passe le `Router` EN ARGUMENT de ce `builder` : tout
// ce que le `builder` enveloppe est donc AU-DESSUS du `Navigator` de GoRouter.
// `showDialog` remonte les ANCETRES a la recherche d'un `Navigator` ; au-dessus
// du `Router` il n'y en a aucun. Le dialogue de sortie ne pouvait donc JAMAIS
// s'ouvrir — et comme l'exception part d'un callback de geste, le filet
// d'erreurs de Flutter l'avale : bouton mort, aucun message.
//
// POURQUOI LES TESTS DU LOT 638 DISAIENT VERT, ET C'EST LA MEME LECON QU'EN 637 :
// ils montaient `CadreDemo` dans `MaterialApp(home:)`, c'est-a-dire DESSOUS un
// `Navigator` — a l'exact oppose de sa place reelle. Les tests de ce fichier
// montent l'arbre de `main.dart`, `builder` compris.
//
// CE QUE LE CORRECTIF CHANGE.
//   1. LA SORTIE SE FAIT EN UN APPUI, SANS DIALOGUE. Plus de `showDialog` depuis
//      un contexte sans navigateur : l'appui appelle directement `quitterLaDemo`,
//      qui est deja atomique (six gestes, lot 638) et finit par `go` vers
//      « Mes treks ». Le choix « cacher le bouton demo » n'est pas perdu : il est
//      propose APRES coup, sans bloquer, et il reste reversible dans Mon compte.
//   2. LA PASTILLE NE RECOUVRE PLUS RIEN. Elle quitte le `Stack` (ou elle etait
//      peinte PAR-DESSUS la barre de titre) pour un BANDEAU qui prend sa propre
//      place au-dessus de l'ecran : plus un seul pixel de l'application dessous.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/routing/navigateur_racine.dart';
import 'package:moteur_gr/core/services/session_demo.dart';
import 'package:moteur_gr/features/auth/domain/auth_service.dart';
import 'package:moteur_gr/features/auth/presentation/profile_screen.dart';
import 'package:moteur_gr/features/auth/providers/auth_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/widgets/cadre_demo.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  /// L'ARBRE DE `main.dart`, PAS UN ARBRE DE TEST.
  ///
  /// Le point qui compte tient en une ligne : `CadreDemo` enveloppe le `child`
  /// fourni au `builder` de `MaterialApp.router`, donc il est AU-DESSUS du
  /// `Navigator` de GoRouter — exactement comme en production, et a l'inverse de
  /// ce que faisaient les tests du lot 638.
  ({Widget appli, GoRouter routeur}) appliReelle(ProviderContainer c) {
    final routeur = GoRouter(
      navigatorKey: cleNavigateurRacine,
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => Scaffold(
            appBar: AppBar(
              centerTitle: true,
              leading: IconButton(
                key: const ValueKey('test-retour'),
                icon: const Icon(Icons.arrow_back),
                onPressed: () {},
              ),
              title: const Text('Mare a Mare Centre'),
              actions: [
                IconButton(
                  key: const ValueKey('test-action'),
                  icon: const Icon(Icons.info),
                  onPressed: () {},
                ),
              ],
            ),
            body: const Center(child: Text('COCKPIT DEMO')),
          ),
        ),
        GoRoute(
          path: '/my-treks',
          builder: (_, __) => const Scaffold(body: Text('MES TREKS')),
        ),
      ],
    );
    return (
      appli: UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(
          routerConfig: routeur,
          builder: (context, child) =>
              CadreDemo(child: child ?? const SizedBox.shrink()),
        ),
      ),
      routeur: routeur,
    );
  }

  group('649 — le « Quitter » de la demo repond, dans l arbre reel', () {
    testWidgets(
      'UN SEUL APPUI ramene a Mes treks, et AUCUNE exception ne sort',
      (tester) async {
        // CE TEST EST LA REPRODUCTION, ET IL A ECHOUE AVANT LE CORRECTIF sur
        //   Navigator operation requested with a context that does not include
        //   a Navigator.
        //     Navigator.of (navigator.dart:2936) / showDialog (dialog.dart:1504)
        //     afficherSortieDeDemo (cadre_demo.dart:169)
        // c'est-a-dire le bouton muet mesure sur l'emulateur le 30/09 a 15:38.
        //
        // IL COUVRE AUSSI LE SECOND DEFAUT DU MEME CHEMIN : `GoRouter.maybeOf`
        // etait appele sur ce meme contexte pose au-dessus du `Router`, donc il
        // rendait `null` — le retour a « Mes treks » n'avait jamais lieu depuis
        // le bandeau, meme quand la demo, elle, etait bien coupee.
        final c = ProviderContainer();
        addTearDown(c.dispose);
        c.read(sessionDemoProvider.notifier).entrer();

        final (:appli, :routeur) = appliReelle(c);
        addTearDown(routeur.dispose);
        await tester.pumpWidget(appli);
        await tester.pumpAndSettle();

        expect(find.text('COCKPIT DEMO'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('demo-sortie')));
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason:
              'c est le bouton mort du build 8 : showDialog depuis un contexte '
              'pose AU-DESSUS du Navigator finit sur le `!` de Navigator.of, '
              'et le filet de Flutter avale l exception — appui sans effet',
        );
        expect(
          c.read(enDemoProvider),
          isFalse,
          reason: 'un appui, et la demo est coupee',
        );
        expect(
          find.text('MES TREKS'),
          findsOneWidget,
          reason:
              'bug 19 de Christophe : « quand on quitte le mode demo, ca doit '
              'revenir a Mes treks !!! »',
        );
        expect(
          find.text('COCKPIT DEMO'),
          findsNothing,
          reason: 'aucun ecran de la demo ne reste derriere',
        );

        // Le message de fin se ferme tout seul (bug 11 : un bandeau du bas qui
        // reste cache une partie de l'appli).
        await tester.pump(kDureeMessageSortieDemo);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('demo-sortie-faite')), findsNothing);
      },
    );

    testWidgets('le titre de la barre reste VISIBLE et INTACT, a 360 px', (
      tester,
    ) async {
      // LE DEFAUT 1 DU BUILD 8, MESURE SUR L ECRAN LE PLUS ETROIT. La pastille
      // du lot 638 etait centree en haut, a la hauteur de la barre de titre :
      // elle recouvrait donc le titre par construction, et sur le cockpit elle
      // mordait aussi sur l action « infos ». Le bandeau, lui, est AU-DESSUS de
      // la barre : ni le titre, ni le retour, ni les actions ne sont touches.
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(sessionDemoProvider.notifier).entrer();

      final (:appli, :routeur) = appliReelle(c);
      addTearDown(routeur.dispose);
      await tester.pumpWidget(appli);
      await tester.pumpAndSettle();

      final sortie = tester.getRect(find.byKey(const ValueKey('demo-sortie')));
      final titre = tester.getRect(find.text('Mare a Mare Centre'));
      final retour = tester.getRect(find.byKey(const ValueKey('test-retour')));
      final action = tester.getRect(find.byKey(const ValueKey('test-action')));

      expect(
        sortie.overlaps(titre),
        isFalse,
        reason:
            'c est LE defaut que Christophe a vu : « MODE DEMO Quitter » '
            'ecrit par-dessus « Mare a Mare Centre »',
      );
      expect(sortie.overlaps(retour), isFalse);
      expect(
        sortie.overlaps(action),
        isFalse,
        reason:
            'sur le cockpit du build 8, la pastille mordait sur l action '
            '« infos » de l en-tete',
      );
      expect(
        titre.width,
        greaterThan(0),
        reason: 'un titre de largeur nulle serait un titre efface',
      );
    });
  });

  // ===========================================================================
  // MON COMPTE — UNE ATTENTE QUI FINIT PAR DIRE QUELQUE CHOSE
  // ===========================================================================
  //
  // CE QUI A ETE MESURE sur l'emulateur le 30/09 : « Mon compte » ouvert depuis
  // le menu du trek tournait SANS FIN. Le journal repetait des refus Firestore
  // (`permission-denied`), le flux d'identite n'emettait jamais, et l'ecran
  // restait un rond qui tourne — sans jamais dire que quelque chose avait rate.
  //
  // LA CAUSE DU REFUS FIRESTORE N'EST PAS TRAITEE ICI, et c'est volontaire : ce
  // lot ferme le SILENCE, pas le refus.
  group('649 — Mon compte finit par dire que ca a rate', () {
    Widget myAccount(ProviderContainer c) => UncontrolledProviderScope(
      container: c,
      child: TranslationProvider(
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/profile',
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfileScreen(),
              ),
              GoRoute(path: '/my-treks', builder: (_, __) => const SizedBox()),
            ],
          ),
        ),
      ),
    );

    testWidgets('le rond qui tourne devient un message + Reessayer', (
      tester,
    ) async {
      // Un flux qui n'emet JAMAIS : c'est exactement ce que faisait l'identite
      // sur l'emulateur.
      final robinet = StreamController<AuthUser?>();
      addTearDown(robinet.close);
      final c = ProviderContainer(
        overrides: [currentUserProvider.overrideWith((ref) => robinet.stream)],
      );
      addTearDown(c.dispose);

      await tester.pumpWidget(myAccount(c));
      await tester.pump();

      // AVANT LE DELAI, RIEN NE CHANGE : c'est le meme rond qu'avant, et une
      // reponse qui arrive a temps ne doit RIEN faire voir d'autre.
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.byKey(const ValueKey('compte-echec-attente')), findsNothing);

      await tester.pump(kAccountFailureDelay);
      await tester.pump();

      expect(
        find.byKey(const ValueKey('compte-echec-attente')),
        findsOneWidget,
        reason:
            'un rond qui tourne sans fin ne dit rien : ni « patiente », ni '
            '« c est casse ». Le randonneur ne pouvait que tuer l application',
      );
      expect(find.text(t.auth.errorTimeout), findsOneWidget);
      expect(find.byKey(const ValueKey('compte-reessayer')), findsOneWidget);
    });

    testWidgets('Reessayer relance, et un second echec se dit aussi', (
      tester,
    ) async {
      final robinet = StreamController<AuthUser?>.broadcast();
      addTearDown(robinet.close);
      final c = ProviderContainer(
        overrides: [currentUserProvider.overrideWith((ref) => robinet.stream)],
      );
      addTearDown(c.dispose);

      await tester.pumpWidget(myAccount(c));
      await tester.pump(kAccountFailureDelay);
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('compte-reessayer')));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('compte-echec-attente')),
        findsNothing,
        reason: 'on repart pour un tour : le message laisse la place au rond',
      );

      // ET LE MINUTEUR EST REARME : un second echec se dit aussi, sinon
      // « Reessayer » rendrait le silence d'origine.
      await tester.pump(kAccountFailureDelay);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('compte-echec-attente')),
        findsOneWidget,
      );
    });
  });
}
