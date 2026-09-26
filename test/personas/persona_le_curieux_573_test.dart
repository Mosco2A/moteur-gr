// PERSONA — LE CURIEUX (tache 573, LOT V).
//
// CE QU'IL FAIT. Il cherche a atteindre CHAQUE fonction depuis l'accueil. Pas le
// chemin qu'on lui indique : TOUS les chemins. Il ouvre ce qui n'est pas sur le
// parcours normal, et il n'accepte aucun cul-de-sac. Quand une fonction existe
// dans l'application, il veut la trouver avec son doigt.
//
// CE QU'IL AURAIT ATTRAPE, retour 15 de Chris du 26/09, verbatim : « SOS Fiche
// medicale ne fonctionne pas == je ne sais pas ou saisir les donnees de sante et
// ON NE ME LE PROPOSE NUL PART ... pas plus que le telechargement des cartes
// offline ». Trois fonctions ecrites et introuvables. Un curieux les aurait
// cherchees en dix minutes — et il aurait trouve le VIDE, ce qui est precisement
// l'information.
//
// POURQUOI AUCUN PERSONA NE L'A VU. C'est LE trou principal de la campagne :
// aucun persona ne cherche a ATTEINDRE une fonction depuis l'accueil. Les
// scenarios partent tous d'un ecran donne et jouent un parcours prevu. Et les
// 2 760 tests du depot font pire : ils CONSTRUISENT l'ecran (`pumpWidget(
// MaterialApp(home: EmergencyScreen()))`), ce qui prouve que la classe se peint
// et rien d'autre.
//
// LE PARTAGE DU TRAVAIL, ET IL EST ASSUME. Prouver l'atteignabilite de 49 routes
// en tapant reellement tous les chemins possibles serait un balayage
// combinatoire. L'invariante 1 le fait par LECTURE du graphe de navigation,
// exhaustivement. Ce persona fait l'autre moitie, celle que la lecture ne peut
// pas faire : il verifie a l'EXECUTION que les premieres portes existent
// vraiment et qu'aucun ecran n'est un cul-de-sac. Les deux ensemble tiennent ; ni
// l'un ni l'autre seul.
//
// LES TROUS DE GRILLE QU'IL FERME : (F) on ne cherche pas a ATTEINDRE une
// fonction depuis l'accueil ; (H) des ecrans entiers ne sont JAMAIS ouverts —
// entrainement, peaux, SOS.
library;

import 'package:flutter_test/flutter_test.dart';

import '../structurel/graphe_navigation.dart';
import '../structurel/parcours_reel.dart';

/// Les fonctions qu'un randonneur CHERCHE, et la route qui les porte.
///
/// Ce sont les trois que Chris n'a pas trouvees, plus les deux ecrans que la
/// campagne n'a jamais ouverts. Un curieux ne se demande pas si la route existe :
/// il se demande s'il peut y arriver.
const fonctionsQueLUtilisateurCherche = <String, String>{
  'les contacts d urgence': '/emergency',
  'la fiche medicale (ou saisir mes donnees de sante)': '/health',
  'le programme d entrainement': '/training',
  'le signalement terrain': '/signalement',
  'la meteo du sentier': '/trail/:id/weather',
  'le risque incendie': '/trail/:id/fire-risk',
};

/// Les ecrans sans sortie ADMIS, et la raison de chacun.
///
/// Ce sont des ecrans ouverts par un LIEN venu de l'exterieur, jamais depuis
/// l'application : il n'y a donc rien derriere eux ou revenir. Une exception dit
/// pourquoi ; sans raison ecrite, une exception n'a pas sa place ici.
const ecransSansSortieAdmis = <String, String>{
  '/follow/:code':
      'Suivi web temps reel ouvert par un lien partage (E4.12a) : la personne '
          'qui suit n a pas d application derriere, il n y a rien ou revenir.',
  '/group/:id':
      'Groupe ouvert par un lien d invitation. ATTENTION : la fonction GROUPE a '
          'ete RETIREE du perimetre par Chris le 07/09 (partage de position '
          'live, code Firestore de demonstration). Cette exception doit '
          'disparaitre avec la route elle-meme.',
};

void main() {
  group('LE CURIEUX — je cherche cette fonction depuis l accueil', () {
    test('chaque fonction que l utilisateur cherche est atteignable', () {
      final routes = routesDeclarees();
      final sources = fichiersSourceLib();
      final classes = classesDeWidgetParFichier(sources);
      final routeVersFichiers = routesEtLeursFichiers(routes, classes);
      final importeurs = importeursParFichier(sources);
      final aretes = aretesDeNavigation(sources).aretes;
      final portes = portesDEntree(routes);

      String? cibleDe(AreteNavigation a) {
        for (final r in routes) {
          if (a.parNom ? r.nom == a.cible : memeRoute(r.gabarit, a.cible)) {
            return r.gabarit;
          }
        }
        return null;
      }

      final sortantes = <String, Set<String>>{
        for (final r in routes) r.gabarit: <String>{},
      };
      for (final a in aretes) {
        final cible = cibleDe(a);
        if (cible == null) continue;
        for (final d
            in routesPorteusesDuGeste(a.fichier, routeVersFichiers, importeurs)) {
          sortantes[d]?.add(cible);
        }
      }
      final atteintes = <String>{};
      final file = <String>[...portes];
      while (file.isNotEmpty) {
        final r = file.removeLast();
        if (!atteintes.add(r)) continue;
        file.addAll(sortantes[r] ?? const <String>{});
      }

      final introuvables = <String>[];
      for (final e in fonctionsQueLUtilisateurCherche.entries) {
        if (atteintes.contains(e.value)) continue;
        introuvables.add('${e.key} (${e.value})');
      }
      expect(introuvables, isEmpty,
          reason: 'FONCTIONS INTROUVABLES DEPUIS L ACCUEIL : elles sont '
              'ecrites, elles ont une route, et aucun enchainement de gestes '
              'n y mene.\n  ${introuvables.join('\n  ')}');
    });
  });

  group('LE CURIEUX — les premieres portes existent vraiment', () {
    testWidgets('depuis l accueil, les gestes visibles menent quelque part',
        (tester) async {
      // ANCRAGE A L EXECUTION. L'invariante 1 raisonne sur un graphe lu dans le
      // source ; si ce graphe etait faux, tout son verdict serait faux. On verifie
      // donc a l'ecran que les gestes du premier niveau ouvrent bien des routes
      // DIFFERENTES de celle d'ou l'on part.
      await monterAppliReelle(tester);
      final depart = cheminAffiche();
      final gestes = gestesDisponibles(tester)
          .where((g) => !estGesteEvite(g.libelle))
          .toList();
      expect(gestes, isNotEmpty,
          reason: 'l accueil n offre aucun geste : il n y a pas de porte');

      final ouvertes = <String>{};
      for (final g in gestes) {
        await revenirSurLaRoute(tester, depart);
        try {
          await tester.tap(g.finder, warnIfMissed: false);
        } catch (_) {
          continue;
        }
        await stabiliser(tester, coups: 4);
        final arrivee = cheminAffiche();
        if (arrivee != depart) ouvertes.add(arrivee);
      }
      await demonterAppli(tester);
      erreursDeRendu(tester);

      expect(ouvertes, isNotEmpty,
          reason: 'AUCUN geste de l accueil n ouvre une autre route : le '
              'premier niveau du graphe de navigation est une illusion.');
    });

    testWidgets('aucun ecran n est un cul-de-sac : on peut toujours en sortir',
        (tester) async {
      // Un ecran sans sortie est un piege : l'utilisateur doit tuer
      // l'application. On exige de chaque ecran atteignable soit un geste retour
      // du systeme qui recule, soit un geste visible qui mene ailleurs.
      final pieges = <String>[];
      for (final r in routesDeclarees()) {
        final concret = cheminConcret(r.gabarit);
        if (concret == null) continue;
        if (ecransSansSortieAdmis.containsKey(r.gabarit)) continue;
        await monterAppliReelle(tester, depart: concret);
        final ici = cheminAffiche();
        await tester.binding.handlePopRoute();
        await stabiliser(tester, coups: 3);
        final apresRetour = cheminAffiche();
        if (apresRetour != ici) continue; // il y a une sortie : bien

        // Pas de recul : reste-t-il un geste qui emmene ailleurs ?
        await allerA(tester, concret);
        final gestes = gestesDisponibles(tester)
            .where((g) => !estGesteEvite(g.libelle))
            .toList();
        var sortie = false;
        for (final g in gestes) {
          await revenirSurLaRoute(tester, concret);
          try {
            await tester.tap(g.finder, warnIfMissed: false);
          } catch (_) {
            continue;
          }
          await stabiliser(tester, coups: 3);
          if (cheminAffiche() != ici) {
            sortie = true;
            break;
          }
        }
        if (!sortie) {
          pieges.add('$concret : ni retour arriere, ni geste qui mene ailleurs');
        }
      }
      await demonterAppli(tester);
      erreursDeRendu(tester);
      expect(pieges, isEmpty,
          reason: 'ECRANS SANS SORTIE :\n  ${pieges.join('\n  ')}');
    });
  });
}
