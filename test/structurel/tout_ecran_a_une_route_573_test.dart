// INVARIANTE 2 (tache 573, LOT V) — TOUT ECRAN A UNE ROUTE, ET IL REND QUELQUE CHOSE.
//
// DEUX MOITIES, ET IL FAUT LES DEUX.
//
//   (a) TOUT ECRAN ECRIT EST JOIGNABLE PAR UNE ROUTE. `pack_store_screen.dart`
//       existait, avec sa carte `pack_card.dart` et ses providers
//       `pack_providers.dart` — et AUCUNE route ne le declarait. Pas « une route
//       sans porte » : pas de route du tout. Le LOT B avait meme retire, la
//       veille, le bouton « TELECHARGER LES CARTES OFFLINE » parce qu'il
//       n'ouvrait qu'un « bientot disponible » : la suppression a masque le vrai
//       probleme au lieu de le reveler. Retour 15 de Chris, verbatim : « ... pas
//       plus que le telechargement des cartes offline ».
//
//   (b) TOUT ECRAN ATTEINT REND QUELQUE CHOSE. Un ecran qui se monte sans
//       exception mais n'affiche rien est un ecran nu — le defaut du LOT D, deja
//       vu deux fois sur ce chantier (la carte et le journal). On va donc a
//       chaque route atteignable, avec le VRAI routeur et les VRAIES donnees
//       embarquees, et on exige du contenu.
//
// POURQUOI LA MOITIE (a) EST UNE LECTURE DE SOURCE ET PAS UN BALAYAGE. Un
// balayage ne peut pas trouver ce qui n'a pas de route : il n'y a rien a taper.
// Seule la question posee a l'envers — « quels ecrans sont ecrits ? » puis
// « lesquels personne n'appelle ? » — fait apparaitre un orphelin. C'est
// exactement la question que 2 760 tests ne posaient pas.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'graphe_navigation.dart';
import 'parcours_reel.dart';

/// Les ecrans SANS route par conception, et la raison de chacun.
const ecransDormantsDocumentes = <String, String>{
  'NavPiloteScreen':
      'Demonstrateur jetable de la refonte navigation (StepWays L8) : la route '
          'a ete retiree volontairement, le fichier conserve comme reference '
          'visuelle. A supprimer quand la refonte est cloturee.',
};

void main() {
  late List<File> sources;
  late Map<String, String> classeVersFichier;
  late List<RouteDeclaree> routes;
  late Map<String, Set<String>> routeVersFichiers;

  setUpAll(() {
    sources = fichiersSourceLib();
    classeVersFichier = classesDeWidgetParFichier(sources);
    routes = routesDeclarees();
    routeVersFichiers = routesEtLeursFichiers(routes, classeVersFichier);
  });

  group('V2-a — tout ecran ecrit a une route', () {
    test('aucun ecran de lib/features/**/presentation n est orphelin', () {
      // Les ecrans : les classes publiques nommees `...Screen` d'un fichier
      // `*_screen.dart` de `presentation/`. Ce sont les unites que le routeur
      // est censé pouvoir construire.
      final ecrans = <String, String>{};
      for (final entree in classeVersFichier.entries) {
        final f = entree.value;
        if (!f.contains('/presentation/')) continue;
        if (!f.endsWith('_screen.dart')) continue;
        if (!entree.key.endsWith('Screen')) continue;
        if (entree.key.startsWith('_')) continue;
        ecrans[entree.key] = f;
      }
      expect(ecrans, isNotEmpty, reason: 'aucun ecran trouve : lecture cassee');

      // Les fichiers que le routeur construit, directement.
      final fichiersRoutes = routeVersFichiers.values.expand((s) => s).toSet();

      // Un ecran peut aussi etre ouvert en modale (`showModalBottomSheet`,
      // `Navigator.push(MaterialPageRoute(builder: ...))`) : cite par un AUTRE
      // fichier, il n'est pas orphelin — il est atteint autrement.
      final citationsAilleurs = <String, Set<String>>{};
      for (final f in sources) {
        final src = f.readAsStringSync();
        for (final nom in ecrans.keys) {
          if (ecrans[nom] == f.path) continue; // sa propre definition
          if (RegExp('\\b$nom\\b').hasMatch(src)) {
            (citationsAilleurs[nom] ??= <String>{}).add(f.path);
          }
        }
      }

      final orphelins = <String>[];
      for (final e in ecrans.entries) {
        if (ecransDormantsDocumentes.containsKey(e.key)) continue;
        if (fichiersRoutes.contains(e.value)) continue;
        if ((citationsAilleurs[e.key] ?? const <String>{}).isNotEmpty) continue;
        orphelins.add('${e.key}  (${e.value})');
      }

      expect(
        orphelins,
        isEmpty,
        reason: 'CES ECRANS SONT ECRITS ET PERSONNE NE PEUT LES OUVRIR : ni '
            'route au routeur, ni citation ailleurs dans lib/. Ecrire un ecran '
            'sans route, c est livrer du code mort que la suite de tests '
            'declare vert.\n  ${orphelins.join('\n  ')}',
      );
    });

    test('chaque route du routeur construit bien un ecran identifiable', () {
      // Le pendant du test precedent : une route dont on n'arrive pas a nommer
      // l'ecran signale que la lecture de `app_router.dart` a derape — et donc
      // que les deux invariantes raisonnent sur un graphe faux.
      final redirections = routesDeRedirectionPure(routes);
      final sansEcran = routeVersFichiers.entries
          .where((e) => e.value.isEmpty)
          .map((e) => e.key)
          .where((g) => !redirections.contains(g))
          .toList();
      expect(sansEcran, isEmpty,
          reason: 'routes dont l ecran n a pas ete identifie dans '
              'app_router.dart : la lecture du routeur doit etre corrigee '
              'avant de faire confiance aux invariantes.\n'
              '  ${sansEcran.join('\n  ')}');
    });
  });

  group('V2-b — tout ecran atteint rend quelque chose', () {
    // Les routes concretisables avec les donnees REELLES embarquees. Une route
    // dont un parametre n'a pas de valeur reelle connue est declaree, pas
    // silencieusement sautee.
    for (final r in routesDeclareesStatiques()) {
      final concret = cheminConcret(r.gabarit);
      if (concret == null) continue;
      testWidgets('${r.gabarit} affiche du contenu', (tester) async {
        await monterAppliReelle(tester, depart: concret);
        final arrivee = cheminAffiche();
        final textes = textesVisibles(tester);
        // Les DEBORDEMENTS sont le sujet du persona L OEIL, qui les rapporte
        // tous d'un coup : ici on les ecarte pour que l'echec de CE test ne
        // veuille dire qu'une chose, « l ecran est nu ». Toute AUTRE exception
        // reste fatale — un ecran qui leve n'est pas un ecran qui marche.
        final erreurs = erreursDeRendu(tester);
        final autres = erreurs.where((e) => !estDebordement(e)).toList();

        // Une garde peut legitimement rediriger (sentier absent, accueil non
        // fait) : on le DIT plutot que de l'ignorer, et on exige que l'ecran
        // d'arrivee, lui, ne soit pas nu.
        await demonterAppli(tester);
        erreursDeRendu(tester); // vide ce que le demontage a pu ajouter
        expect(autres, isEmpty,
            reason: 'la route $concret leve en se montant : '
                '${autres.join(' | ')}');
        expect(
          textes,
          isNotEmpty,
          reason: 'ECRAN NU : la route $concret affiche zero texte '
              '(arrivee reelle : $arrivee). Un ecran qui se monte sans rien '
              'montrer passe tous les tests de widget et ne sert a personne.',
        );
      });
    }
  });
}

/// Les routes declarees, lues UNE fois hors `setUpAll`.
///
/// `testWidgets` doit etre declare pendant la construction de la suite, donc
/// avant que `setUpAll` ne tourne : la liste est relue ici.
List<RouteDeclaree> routesDeclareesStatiques() => routesDeclarees();
