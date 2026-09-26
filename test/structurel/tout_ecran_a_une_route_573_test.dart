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
import 'registre_des_dormants.dart';

/// LES ECRANS SANS ROUTE PAR CONCEPTION SONT DESORMAIS DANS LEUR PROPRE
/// REGISTRE (tache 580, Y2), avec pour chacun sa RAISON et ce qui le
/// REVEILLERA : voir `registre_des_dormants.dart`.
///
/// CE QUI A CHANGE, ET POURQUOI. Cette liste-ci etait une liste d'exceptions :
/// un nom, une phrase, et rien qui empeche de la laisser pourrir. Elle l'avait
/// d'ailleurs fait — `NavPiloteScreen` y figurait encore alors que le fichier
/// a ete SUPPRIME de `lib/` le 20/09/2026 (correctif L0-1) et qu'un garde
/// interdit depuis ce nom de classe partout dans `lib/`. Une exception pour un
/// ecran qui n'existe plus ne protege rien : elle entretient l'illusion qu'on
/// sait de quoi on parle.
///
/// Le registre, lui, est VERIFIE dans les deux sens par le groupe « V2-c » plus
/// bas : chaque dormant doit etre un ecran qui EXISTE et qui est REELLEMENT
/// orphelin, et chacun doit porter une raison et un reveil ecrits.

void main() {
  late List<File> sources;
  late Map<String, String> classeVersFichier;
  late List<RouteDeclaree> routes;
  late Map<String, Set<String>> routeVersFichiers;

  /// Les ecrans ECRITS : les classes publiques nommees `...Screen` d'un fichier
  /// `*_screen.dart` de `presentation/`. Ce sont les unites que le routeur est
  /// cense pouvoir construire. Nom -> fichier.
  late Map<String, String> ecrans;

  /// Les fichiers que le routeur construit, directement.
  late Set<String> fichiersRoutes;

  /// Un ecran peut aussi etre ouvert en modale (`showModalBottomSheet`,
  /// `Navigator.push(MaterialPageRoute(builder: ...))`) : cite par un AUTRE
  /// fichier, il n'est pas orphelin — il est atteint autrement.
  late Map<String, Set<String>> citationsAilleurs;

  /// Vrai quand personne ne peut ouvrir [nom] : ni route, ni citation.
  bool estOrphelin(String nom) {
    if (fichiersRoutes.contains(ecrans[nom])) return false;
    return (citationsAilleurs[nom] ?? const <String>{}).isEmpty;
  }

  setUpAll(() {
    sources = fichiersSourceLib();
    classeVersFichier = classesDeWidgetParFichier(sources);
    routes = routesDeclarees();
    routeVersFichiers = routesEtLeursFichiers(routes, classeVersFichier);

    ecrans = <String, String>{};
    for (final entree in classeVersFichier.entries) {
      final f = entree.value;
      if (!f.contains('/presentation/')) continue;
      if (!f.endsWith('_screen.dart')) continue;
      if (!entree.key.endsWith('Screen')) continue;
      if (entree.key.startsWith('_')) continue;
      ecrans[entree.key] = f;
    }

    fichiersRoutes = routeVersFichiers.values.expand((s) => s).toSet();

    citationsAilleurs = <String, Set<String>>{};
    for (final f in sources) {
      // SANS LES COMMENTAIRES (tache 580, Y2) : une phrase de documentation qui
      // NOMME un ecran n'ouvre rien. Lire le fichier entier laissait eteindre
      // cette garde en ecrivant le nom de l'ecran dans un commentaire.
      final src = sansCommentaires(f.readAsStringSync());
      for (final nom in ecrans.keys) {
        if (ecrans[nom] == f.path) continue; // sa propre definition
        if (RegExp('\\b$nom\\b').hasMatch(src)) {
          (citationsAilleurs[nom] ??= <String>{}).add(f.path);
        }
      }
    }
  });

  group('V2-a — tout ecran ecrit a une route', () {
    test('aucun ecran de lib/features/**/presentation n est orphelin', () {
      expect(ecrans, isNotEmpty, reason: 'aucun ecran trouve : lecture cassee');

      final orphelins = <String>[];
      for (final e in ecrans.entries) {
        if (registreDesDormants.containsKey(e.key)) continue;
        if (!estOrphelin(e.key)) continue;
        orphelins.add('${e.key}  (${e.value})');
      }

      expect(
        orphelins,
        isEmpty,
        reason: 'CES ECRANS SONT ECRITS ET PERSONNE NE PEUT LES OUVRIR : ni '
            'route au routeur, ni citation ailleurs dans lib/. Ecrire un ecran '
            'sans route, c est livrer du code mort que la suite de tests '
            'declare vert.\n  ${orphelins.join('\n  ')}\n'
            'SI C EST DELIBERE — une fonction non livree, un ecran supplante — '
            'il ne se tait pas tout seul : inscrivez-le dans '
            '`test/structurel/registre_des_dormants.dart` avec sa RAISON et ce '
            'qui le REVEILLERA. Un ecran declare dormant ne fait plus rougir '
            'cette garde ; un ecran oublie, si.',
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

  group('V2-c — le registre des dormants ne ment pas', () {
    // UNE LISTE D'EXCEPTIONS QUI N'EST PAS VERIFIEE POURRIT. La precedente l'a
    // fait : `NavPiloteScreen` y dormait encore alors que le fichier avait ete
    // SUPPRIME de lib/ six jours plus tot. Ces trois tests sont le prix
    // d'entree du registre — c'est ce qui fait la difference entre une dette
    // ECRITE et une garde desamorcee.

    test('chaque dormant designe un ecran qui EXISTE', () {
      final inconnus = registreDesDormants.keys
          .where((nom) => !ecrans.containsKey(nom))
          .toList();
      expect(
        inconnus,
        isEmpty,
        reason: 'CES ENTREES NE DESIGNENT PLUS RIEN : l ecran a ete supprime '
            'ou renomme, et son entree a survecu. Une exception pour un ecran '
            'qui n existe plus n endort rien — elle entretient l illusion '
            'qu on sait de quoi on parle. Retirez-la.\n'
            '  ${inconnus.join('\n  ')}',
      );
    });

    test('aucun dormant n a ete cable entre-temps', () {
      // LA DETTE DOIT POUVOIR SE REMBOURSER. Le jour ou l'un de ces ecrans
      // recoit sa route, son entree n'a plus lieu d'etre — et si elle reste,
      // elle couvrira en silence le PROCHAIN ecran qui portera ce nom.
      final reveilles = registreDesDormants.keys
          .where(ecrans.containsKey)
          .where((nom) => !estOrphelin(nom))
          .toList();
      expect(
        reveilles,
        isEmpty,
        reason: 'CES ECRANS SONT DESORMAIS ATTEIGNABLES et restent declares '
            'dormants. Le travail est fait : retirez leur entree du registre, '
            'la garde reprend ses droits sur eux.\n  ${reveilles.join('\n  ')}',
      );
    });

    test('chaque dormant porte une RAISON et un REVEIL ecrits', () {
      // Le cout d'endormir un ecran doit rester superieur a celui de lui
      // donner sa porte : une entree se merite en expliquant, pas en nommant.
      final bacles = <String>[];
      registreDesDormants.forEach((nom, dormant) {
        if (dormant.raison.trim().length < 60) {
          bacles.add('$nom : raison trop courte pour expliquer quoi que ce '
              'soit (« ${dormant.raison.trim()} »)');
        }
        if (dormant.reveil.trim().length < 20) {
          bacles.add('$nom : aucun reveil nomme (« ${dormant.reveil.trim()} »)');
        }
      });
      expect(
        bacles,
        isEmpty,
        reason: 'UNE ENTREE DE REGISTRE N EST PAS UNE LIGNE DE TODO. Chaque '
            'dormant doit dire POURQUOI il dort et CE QUI LE REVEILLERA — '
            'sinon la dette redevient muette, et le registre n est qu une '
            'liste d exceptions de plus.\n  ${bacles.join('\n  ')}',
      );
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
