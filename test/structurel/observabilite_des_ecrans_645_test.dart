// GARDE DE PLAFOND — OBS-01 : AUCUN ECRAN SANS MIETTE D'OBSERVABILITE
// (lot 645-09).
//
// CE QUE CETTE GARDE MESURE. Les 63 ecrans de `lib/` (`*_screen.dart`), et
// pour chacun : une miette d'entree, UNE SEULE, posee au point d'ENTREE de
// l'ecran, et qui nomme le BON ecran.
//
// POURQUOI LE PLAFOND EST A ZERO ET PAS A 54. La fiche 645-09 annoncait
// « 54 ecrans nus » sur 63, les 9 autres etant deja equipes. LES 9 ETAIENT UN
// FAUX POSITIF, et il faut le dire parce que la mesure du lot en depend : la
// liste des marqueurs de l'audit 644 contient `log(`, qui est CONTENU DANS
// `AlertDialog(`. Les 9 « ecrans equipes » du 02/10 etaient donc 9 ecrans qui
// ouvraient un dialogue. Mesure reelle au 03/10/2026, avant ce lot : ZERO
// ecran instrumente sur 63, et aucun rapport de plantage ne pouvait dire ou
// se trouvait le randonneur. Le 9e ecran annonce avait meme disparu de la
// mesure entre-temps (8 sur 63), par un simple renommage.
//
// ---------------------------------------------------------------------------
// CETTE GARDE NE SE CONTENTE PAS DE COMPTER, ET C'EST VOULU
// ---------------------------------------------------------------------------
//
// Un lot qui touche 63 fichiers a la main a deux defauts probables, et ils
// sont silencieux tous les deux :
//
//   1. LA MIETTE QUI NOMME LE VOISIN. Un copier-coller, et l'ecran meteo
//      annonce `screen:tips`. Le rapport de plantage serait alors FAUX, ce
//      qui est pire que muet : il enverrait chercher le defaut ailleurs. La
//      garde verifie donc que la miette d'un ecran porte SON nom.
//   2. LA MIETTE QUI GLISSE DANS `build()`. Un `build()` tourne des dizaines
//      de fois par ecran. La garde verifie donc OU la miette est posee :
//      `initState` pour un ecran a etat, `build` pour un ecran qui n'en a
//      pas — ou le service deduplique, et c'est la raison pour laquelle cet
//      emplacement est acceptable la et pas ailleurs.
//
// ZERO EST UN PLAFOND, PAS UN RESULTAT ACQUIS : le prochain ecran ecrit sans
// miette fera rougir cette garde, et c'est exactement ce qu'on lui demande.
library;

import 'package:flutter_test/flutter_test.dart';

import 'mesure_des_sources_645.dart';

/// PLAFOND A ZERO DEPUIS LE 03/10/2026 (lot 645-09).
const plafondEcransSansMiette = 0;

/// Le nombre d'ecrans attendu : 63 au 03/10/2026.
const ecransAttendus = 63;

final _classeDEcran = RegExp(
  r'class\s+(\w+Screen)\s+extends\s+'
  r'(ConsumerStatefulWidget|StatefulWidget|ConsumerWidget|StatelessWidget)\b',
);
final _appel = RegExp(r'observeScreenEntry\(');
final _miette = RegExp(r'ScreenBreadcrumb\.(\w+)');

/// Le nom de constante attendu pour la classe [cls] (`WeatherScreen` ->
/// `weather`).
String constanteAttendue(String cls) {
  final base = cls.substring(0, cls.length - 'Screen'.length);
  return base[0].toLowerCase() + base.substring(1);
}

void main() {
  late List<String> ecrans;
  late List<String> sansMiette;
  late List<String> malNommees;
  late List<String> malPlacees;
  late List<String> enDouble;

  setUpAll(() {
    ecrans = sourcesLib().where((f) => f.endsWith('_screen.dart')).toList();
    sansMiette = <String>[];
    malNommees = <String>[];
    malPlacees = <String>[];
    enDouble = <String>[];

    for (final f in ecrans) {
      // LOT 645-06b : PLUS AUCUN ECRAN N'EST SCINDE EN `part` (regle 12). La
      // carte et la fiche medicale portaient leur classe dans un morceau, et
      // cette garde lisait la racine AVEC ses morceaux. Desormais la classe de
      // chaque ecran ET sa miette vivent dans le fichier `*_screen.dart`
      // lui-meme : c'est lui, et lui seul, qu'on lit. Lire aussi ses voisines
      // laisserait un ecran nu se cacher derriere la miette d'un autre fichier.
      final complet = lireSource(f);

      final appels = _appel.allMatches(complet).length;
      if (appels == 0) {
        sansMiette.add(f);
        continue;
      }
      if (appels > 1) enDouble.add('$f: $appels appels');

      // LA MIETTE PORTE-T-ELLE LE NOM DE SON ECRAN ?
      final cls = _classeDEcran.firstMatch(complet)?.group(1);
      final posees = _miette.allMatches(complet).map((m) => m.group(1)).toSet();
      if (cls == null || !posees.contains(constanteAttendue(cls))) {
        malNommees.add(
          '$f: attendu ${cls == null ? '?' : constanteAttendue(cls)}'
          ', trouve ${posees.join(', ')}',
        );
      }

      // LA MIETTE EST-ELLE POSEE A L ENTREE DE L ECRAN ?
      // L ETAT DE L ECRAN, PAS CELUI D UN SOUS-WIDGET. Trois fichiers
      // (wallet_recharge, training, trek_stage_detail) portent un
      // `ConsumerState` pour une tuile ou une feuille modale alors que
      // l ECRAN, lui, est un `ConsumerWidget`. Chercher `ConsumerState<`
      // sans le nom de la classe les declarait a tort « ecrans a etat », et
      // la garde reclamait un `initState` qui n existe pas.
      final aUnEtat = cls != null && complet.contains('ConsumerState<$cls>');
      final pos = complet.indexOf('observeScreenEntry(');
      final avant = complet.substring(0, pos);
      final dernierInitState = avant.lastIndexOf('void initState()');
      final dernierBuild = avant.lastIndexOf('Widget build(');
      final dansInitState = dernierInitState > dernierBuild;
      if (aUnEtat && !dansInitState) {
        malPlacees.add('$f: hors de initState alors que l ecran a un etat');
      }
      if (!aUnEtat && dansInitState) {
        malPlacees.add('$f: dans un initState introuvable');
      }
    }
  });

  group('645-09 / OBS-01 — pas un ecran nu de plus', () {
    test('la garde mesure bien les 63 ecrans du depot', () {
      expect(
        ecrans,
        hasLength(ecransAttendus),
        reason:
            'le depot ne compte plus 63 ecrans : si un ecran a ete ajoute, il '
            'lui faut sa miette ET une mise a jour de ce compte',
      );
    });

    test('aucun ecran sans miette d observabilite', () {
      expect(
        sansMiette.length,
        lessThanOrEqualTo(plafondEcransSansMiette),
        reason:
            'ces ecrans ne diraient rien a un rapport de plantage : '
            '${sansMiette.join(', ')}',
      );
    });

    test('une seule miette par ecran', () {
      expect(
        enDouble,
        isEmpty,
        reason:
            'deux appels dans le meme ecran posent deux miettes pour une '
            'entree, et le budget de 64 ko est compte : ${enDouble.join(', ')}',
      );
    });

    test('chaque miette nomme SON ecran', () {
      expect(
        malNommees,
        isEmpty,
        reason:
            'une miette qui nomme le voisin est pire qu une miette absente : '
            'elle envoie chercher le defaut ailleurs. ${malNommees.join(' | ')}',
      );
    });

    test('chaque miette est posee a l ENTREE de l ecran', () {
      expect(
        malPlacees,
        isEmpty,
        reason:
            'la miette d un ecran a etat va dans initState ; dans build elle '
            'repartirait a chaque reconstruction. ${malPlacees.join(' | ')}',
      );
    });

    test('la mesure de l audit 644 voit bien chaque ecran equipe', () {
      // L audit cherche un marqueur TEXTUEL dans le fichier compte comme
      // ecran (la RACINE, pas ses morceaux). Sans ce test, un ecran pourrait
      // etre instrumente et compte comme nu — ou l inverse.
      final invisibles = ecrans
          .where((f) => !lireSource(f).contains('ScreenBreadcrumb'))
          .toList();
      expect(
        invisibles,
        isEmpty,
        reason:
            'ces ecrans sont instrumentes mais l audit les comptera nus : '
            '${invisibles.join(', ')}',
      );
    });
  });
}
