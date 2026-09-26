// INVARIANTE 1 (tache 573, LOT V) — TOUTE ROUTE A UNE PORTE.
//
// L'ENONCE : toute route declaree par l'application est atteignable, par une
// suite de gestes, depuis une porte d'entree REELLE — l'ecran ou l'application
// pose l'utilisateur quand il ouvre l'icone. Une route sans porte n'est pas une
// commodite pour plus tard : c'est un ecran qui n'existe pas pour l'utilisateur.
//
// CE QU'ELLE AURAIT ATTRAPE, retour 15 de Chris du 26/09, verbatim : « SOS Fiche
// medicale ne fonctionne pas == je ne sais pas ou saisir les donnees de sante et
// on ne me le propose nul part ... pas plus que le telechargement des cartes
// offline ». Trois fonctions entieres, ecrites, testees, VERTES, et
// inatteignables :
//
//   * `/emergency` : zero `push('/emergency')` dans tout `lib/` ;
//   * `/health`   : une seule porte, `emergency_screen.dart` — donc une porte
//                   derriere une porte murée ;
//   * la boutique de cartes : `pack_store_screen.dart` ecrit, AUCUNE route
//                   declaree (c'est l'invariante 2 qui le dit).
//
// POURQUOI 2 760 TESTS VERTS NE L'ONT PAS VU. Ils construisent les ecrans
// directement — `pumpWidget(MaterialApp(home: EmergencyScreen()))`. Un test qui
// instancie un ecran prouve que la classe se peint, jamais qu'un doigt peut
// l'atteindre. Le test de routage du depot fait un cran de mieux et un cran de
// pire : il RECOPIE la liste des routes a la main et verifie qu'elle n'a pas
// change. Il aurait donc valide les 24 routes racine, `/emergency` comprise,
// sans jamais se demander qui y mene.
//
// CE QUI REND CETTE INVARIANTE UTILE APRES LE LOT V. Elle ne nomme aucun ecran.
// Elle lit les routes sur le routeur et les gestes dans le source : l'ecran que
// quelqu'un ajoutera le mois prochain est couvert le jour ou il est ecrit, sans
// que personne y pense. C'est la seule facon de ne pas recommencer.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'graphe_navigation.dart';
import 'parcours_reel.dart';

/// Les routes SANS porte par CONCEPTION, et la raison de chacune.
///
/// Une exception est un ENGAGEMENT, pas un contournement : elle dit pourquoi
/// aucun geste de l'application ne mene a cette route. Si la raison tombe, la
/// ligne tombe. Une exception sans raison ecrite n'a pas sa place ici, et une
/// route qu'on n'arrive pas a cabler n'est pas une exception : c'est un defaut.
const exceptionsDocumentees = <String, String>{
  '/follow/:code':
      'Suivi web temps reel : la porte est un LIEN PARTAGE par le randonneur '
          '(hors application, E4.12a). Aucun geste interne ne doit y mener — '
          'suivre sa propre position n a pas de sens.',
  '/onboarding':
      'Accueil du PREMIER lancement : la porte est la garde de redirection '
          'elle-meme, pas un geste. Elle est verifiee par le test des portes '
          'd entree ci-dessous.',
  '/no-data':
      'Ecran bloquant : la porte est la garde de redirection quand aucun '
          'sentier n est telecharge. Verifiee par le test des portes d entree.',
};

void main() {
  late List<RouteDeclaree> routes;
  late List<File> sources;
  late Map<String, Set<String>> routeVersFichiers;
  late Map<String, Set<String>> importeurs;
  late List<AreteNavigation> aretes;
  late List<String> dynamiques;
  late Set<String> portes;

  setUpAll(() {
    routes = routesDeclarees();
    sources = fichiersSourceLib();
    final classes = classesDeWidgetParFichier(sources);
    routeVersFichiers = routesEtLeursFichiers(routes, classes);
    importeurs = importeursParFichier(sources);
    final scan = aretesDeNavigation(sources);
    aretes = scan.aretes;
    dynamiques = scan.nonResolues;
    portes = portesDEntree(routes);
  });

  /// Le gabarit de route vise par une arete (par chemin ou par nom).
  String? cibleDe(AreteNavigation a) {
    if (!a.parNom) {
      for (final r in routes) {
        if (memeRoute(r.gabarit, a.cible)) return r.gabarit;
      }
      return null;
    }
    for (final r in routes) {
      if (r.nom == a.cible) return r.gabarit;
    }
    return null;
  }

  group('V1 — toute route declaree a une porte', () {
    test('AU MOINS UN GESTE de l application mene a chaque route', () {
      final entrantes = <String, List<String>>{};
      for (final r in routes) {
        entrantes[r.gabarit] = <String>[];
      }
      for (final a in aretes) {
        final cible = cibleDe(a);
        if (cible == null) continue;
        entrantes[cible]!.add('${a.fichier}:${a.ligne} (${a.geste})');
      }

      final sansPorte = <String>[];
      for (final r in routes) {
        if (entrantes[r.gabarit]!.isNotEmpty) continue;
        if (exceptionsDocumentees.containsKey(r.gabarit)) continue;
        if (portes.contains(r.gabarit)) continue;
        sansPorte.add(r.gabarit);
      }

      expect(
        sansPorte,
        isEmpty,
        reason: 'CES ROUTES N ONT AUCUNE PORTE : rien dans lib/ ne navigue '
            'vers elles, et la garde ne les impose pas. Un ecran ecrit et '
            'inatteignable est un ecran qui n existe pas.\n'
            '  ${sansPorte.join('\n  ')}\n'
            'Gestes de navigation dont la cible n est pas litterale (donc '
            'invisibles a cette lecture, a verifier a la main si une route '
            'ci-dessus vous parait pourtant atteignable) : '
            '${dynamiques.length}\n  ${dynamiques.take(12).join('\n  ')}',
      );
    });

    test('chaque route est atteignable DEPUIS une porte d entree', () {
      // Le graphe : d'une route vers les routes qu'on peut ouvrir depuis elle.
      final sortantes = <String, Set<String>>{
        for (final r in routes) r.gabarit: <String>{},
      };
      final orphelines = <String>[];
      for (final a in aretes) {
        final cible = cibleDe(a);
        if (cible == null) continue;
        final depuis =
            routesPorteusesDuGeste(a.fichier, routeVersFichiers, importeurs);
        if (depuis.isEmpty) {
          // Geste porte par un fichier qu'aucun ecran n'atteint : l'arete
          // existe, mais personne ne peut la declencher.
          orphelines.add('$a');
          continue;
        }
        for (final d in depuis) {
          sortantes[d]?.add(cible);
        }
      }

      // Parcours en largeur depuis les portes d'entree.
      final atteintes = <String>{};
      final file = <String>[...portes];
      while (file.isNotEmpty) {
        final r = file.removeLast();
        if (!atteintes.add(r)) continue;
        file.addAll(sortantes[r] ?? const <String>{});
      }

      final injoignables = routes
          .map((r) => r.gabarit)
          .where((g) => !atteintes.contains(g))
          .where((g) => !exceptionsDocumentees.containsKey(g))
          .toList();

      expect(
        injoignables,
        isEmpty,
        reason: 'CES ROUTES NE SONT PAS ATTEIGNABLES depuis une porte '
            'd entree. Certaines ont bien un geste qui y mene — mais ce geste '
            'vit sur un ecran qu on ne peut pas atteindre non plus. C est le '
            'cas exact de la fiche medicale, joignable seulement depuis un '
            'ecran d urgence sans porte.\n'
            '  ${injoignables.join('\n  ')}\n'
            'Portes d entree (calculees sur le routeur et sa garde) : '
            '${portes.toList()..sort()}\n'
            'Gestes portes par un fichier inatteignable : '
            '${orphelines.length}\n  ${orphelines.take(10).join('\n  ')}',
      );
    });

    test('les portes d entree existent VRAIMENT a l ecran', () {
      // L'invariante precedente part des portes d'entree. Si elles etaient
      // fausses, tout le raisonnement serait faux : on les verifie donc a
      // l'execution, sur l'application reelle.
      expect(portes, isNotEmpty);
      expect(portes, contains('/my-treks'),
          reason: 'l entree du routeur doit etre une porte');
      expect(portes, contains('/onboarding'),
          reason: 'la garde impose l accueil au premier lancement');
      expect(portes, contains('/catalog'),
          reason: 'la garde impose le catalogue quand aucun sentier n est la');
    });

    testWidgets('l application POSEE sur son entree affiche bien cette entree',
        (tester) async {
      await monterAppliReelle(tester);
      expect(cheminAffiche(), '/my-treks');
      expect(textesVisibles(tester), isNotEmpty,
          reason: 'la porte d entree de l application est un ecran nu');
    });

    testWidgets('au PREMIER lancement, la garde pose sur l accueil',
        (tester) async {
      await monterAppliReelle(tester, etat: EtatAppli.premierLancement);
      expect(cheminAffiche(), '/onboarding',
          reason: 'un utilisateur qui ouvre l appli la premiere fois doit '
              'tomber sur l accueil, pas sur le cockpit d un sentier qu il n a '
              'ni choisi ni telecharge');
    });
  });
}
