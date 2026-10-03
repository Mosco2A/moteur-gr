// GARDE DE PLAFOND — ECR-23 : LE SENS DES DEPENDANCES (tache 645-01).
//
// CE QUE LA REGLE DIT. Trois interdits, et ils vont tous dans le meme sens :
//
//   (a) LE SOCLE NE CONNAIT PAS SES CLIENTS. `core/` et `shared/` sont ce sur
//       quoi les features reposent ; une fleche qui repart du socle vers une
//       feature ferme le cycle et rend le socle inextractible. On ne peut plus
//       lire `core/` sans lire la feature, ni livrer l'un sans l'autre.
//
//   (b) DEUX FEATURES NE SE CONNAISSENT PAS AUTREMENT QUE PAR UNE FACADE. Ce
//       qu'elles partagent monte dans `shared/` ou `core/` ; ce que l'une
//       EXPOSE a ses voisines passe par un fichier unique et nomme,
//       `lib/features/<f>/<f>_facade.dart` (ARB-645-05-b, decision B du
//       03/10/2026). Une fleche directe vers l'INTERIEUR d'une autre feature
//       fait de la paire un seul bloc : on n'en touche plus une sans ouvrir
//       l'autre, et le detail d'implementation de l'une devient l'interface de
//       l'autre.
//
//   (c) LE SOCLE NE CONNAIT PAS LE METIER. `lib/domain/` est AU-DESSUS de
//       `core/` et de `shared/` (ARB-645-05-c, decision B du 03/10/2026) : le
//       metier a le droit de lire le socle, jamais l'inverse. Ce plafond-ci
//       est a ZERO, et il y est arrive — voir [plafondSocleVersMetier].
//
// POURQUOI UN PLAFOND ET PAS ZERO, APRES LES LOTS 645-05 ET 645-05b. Il y avait
// 301 fleches interdites au 02/10/2026, 254 au 03/10 apres le rangement du
// 645-05, et 233 apres les facades du 645-05b. Le 645-05 a fait ce que le
// RANGEMENT pouvait faire ; le 645-05b a fait ce qu'une FRONTIERE pouvait
// faire. Ce qui reste n'est ni l'un ni l'autre, et c'est la mesure qui le dit :
//
//   - 51 des 72 fleches socle -> feature sortent d'UN SEUL fichier,
//     `lib/core/routing/app_router.dart`, qui importe un ecran par route. Ce
//     n'est pas un modele mal range, c'est la forme d'un routeur central :
//     GoRouter demande la liste des routes en un point, et une route cite
//     l'ecran qu'elle monte. Les ramener a zero demande d'INVERSER le routeur
//     (chaque feature declare ses routes, le socle ne connait qu'un registre),
//     ce qui touche les 30 ecrans, les gardes de route et l'ordre de
//     declaration dont depend la resolution des deeplinks.
//   - 130 des 182 croisements visaient un `providers/`, c'est-a-dire de l'ETAT
//     RIVERPOD partage. Deplacer un provider n'est pas un deplacement de type :
//     c'est un recablage du graphe, et SPEC-06 interdit de changer un
//     comportement en deplacant. LE LOT 645-05b LES A TOUS PAYES SANS RIEN
//     DEPLACER : chacun passe desormais par la facade de la feature lue, donc
//     par un contrat nomme au lieu d'un fichier interne. Il reste 52
//     croisements, et aucun n'est un provider.
//
//   - CE QUE CES 52 SONT, mesure du 03/10/2026 : 19 visent un `domain/` de
//     feature, 15 une `presentation/`, 10 un `widgets/`, 5 un `data/` et 3 un
//     `models/`. Les 20 de `presentation/` et de `data/` sont l'arbitrage
//     SUIVANT de Christophe (un ecran qui monte le widget d'une autre feature
//     n'est pas le meme probleme qu'un provider lu de loin) ; les 32 autres
//     sont des emprunts bilateraux de type, dont ARB-645-05-b a deja etabli
//     qu'AUCUN n'est lu par deux features ou plus.
//
// Le routeur est inscrit en ARB-645-05-a, les croisements restants en
// ARB-645-05-b, dans `docs/assainissement/644-03-decoupage-et-plan.md`. En
// attendant la suite, cette garde fait la seule chose utile : elle empeche les
// chiffres d'AUGMENTER. Un plafond qui exigerait zero aujourd'hui serait rouge
// en permanence, donc desarme en une semaine — mais celui de (c) EST a zero,
// parce que la mesure y est.
//
// ---------------------------------------------------------------------------
// L'ECART AVEC L'AUDIT EST RESORBE DEPUIS LE 03/10/2026 (lot 645-05)
// ---------------------------------------------------------------------------
//
// CE QUI SUIT EST CONSERVE PARCE QUE C'EST LA MEMOIRE DU DEFAUT, mais il est
// CORRIGE : `tool/audit_global.py` resout desormais les imports relatifs comme
// cette garde (`cible_de_l_import`, `feature_de`), et les deux mesures
// annoncent le MEME chiffre — socle vers feature 72, croisements 182. La dette
// que l'ancien en-tete inscrivait ici (« Le chiffre de l'audit sera corrige
// avec son outil, lot 645-05 ») est payee.
//
// `tool/audit_global.py` annonce 243 croisements (#I65). CETTE GARDE EN MESURE
// 223, ET C'EST LE CHIFFRE JUSTE. L'ecart est entier imputable a la facon dont
// l'audit traite les imports relatifs : il cherche `\.\./\.\./(<nom>)/` DANS LE
// TEXTE de l'import et prend `<nom>` pour une feature voisine des qu'il n'est
// ni `core`, ni `shared`, ni `i18n`. Or depuis
// `lib/features/trek/presentation/map/map_screen.dart`, l'import
// `../../domain/models/stage.dart` designe
// `lib/features/trek/domain/models/stage.dart` : LA MEME feature. L'audit y lit
// une fleche `trek -> domain`, qui n'existe pas.
//
// Les 20 fleches fantomes ainsi comptees sont toutes de cette forme, verifiees
// une par une le 02/10/2026 : 2 dans `hub/`, 15 dans `trek/`, 3 dans `treks/`,
// chacune un `../../providers/`, `../../domain/` ou `../../../domain/` INTERNE
// a sa propre feature. Aucune fleche reelle n'est perdue dans l'autre sens :
// l'ensemble mesure ici est un SUR-ensemble strict de l'ensemble de l'audit
// prive de ces 20.
//
// INSCRIRE 243 AURAIT DESARME LA GARDE. Un plafond de 243 face a une mesure de
// 223 laisse vingt croisements de marge : on pourrait en ajouter dix-neuf sans
// que rien ne rougisse. Un plafond ne vaut que serre contre la mesure — c'est
// toute la difference entre une dette ECRITE et une garde endormie. Le chiffre
// de l'audit sera corrige avec son outil (lot 645-05) ; il n'est pas corrige
// ici, car ce lot ne touche pas `tool/`.
library;

import 'package:flutter_test/flutter_test.dart';

import 'mesure_des_sources_645.dart';

/// Mesure du 03/10/2026, APRES le lot 645-05 : le socle (`core/`, `shared/` et
/// desormais `domain/`) tire 72 fleches vers une feature, contre 78 au 02/10.
///
/// Les six payees par ce lot : `trek_sessions_dao` et `privacy_data_policy` et
/// `track_segment_stats` ne traversent plus une feature pour lire un modele
/// (il est dans `lib/domain/`), `bouton_rafraichir_depuis_la_base` est rentre
/// chez `planning`, et l'amorcage a ete INVERSE (cas K1) : il ne connait plus
/// ni l'ecran de la fiche sante ni le depot du profil.
///
/// IL NE RESTE PRESQUE QUE LE ROUTEUR : 51 des 72 sortent de
/// `lib/core/routing/app_router.dart`. Voir l'en-tete, et ARB-645-05-a.
///
/// ARB-645-05-a, DECISION A DE CHRISTOPHE (03/10/2026) : LE ROUTEUR EST EXCLU
/// DE CE COMPTAGE. Un routeur connait tous les ecrans PAR CONSTRUCTION — c'est
/// sa definition meme : une table qui associe une route a un ecran ne peut pas
/// ignorer les ecrans. Lui compter ces fleches, c'est compter un fait de
/// structure comme une faute, et c'est ce qui gardait le plafond a 72 sans que
/// personne puisse jamais le baisser. Le plafond ci-dessous est donc la mesure
/// APRES exclusion : il ne surveille plus que les fleches qu'on peut REELLEMENT
/// payer, celles d'un fichier du socle qui n'a aucune raison de connaitre une
/// feature. L'exception porte sur CE SEUL fichier, nomme en clair ; tout autre
/// fichier de `core/`, `shared/` ou `domain/` reste compte.
///
/// MESURE DU 03/10/2026, APRES exclusion du routeur et APRES le lot 645-06 :
/// 21 fleches, contre 72 avec le routeur. Les 51 retirees sortaient toutes du
/// seul `app_router.dart`. Les 21 restantes ne sont pas du rangement : neuf
/// sont l'amorcage et le pilote de demo (`app_bootstrap_provider`,
/// `pilote_demo`) qui orchestrent des features par nature, et les autres sont
/// des services du socle qui tirent un depot ou un provider de feature.
const plafondSocleVersFeature = 21;

/// Le routeur, seul fichier du socle autorise a connaitre les features.
///
/// Decision ARB-645-05-a (voir [plafondSocleVersFeature]) : un routeur connait
/// tous les ecrans par construction. Ecrit aussi dans `docs/conventions.md`.
const routeurExclu = 'lib/core/routing/app_router.dart';

/// Mesure du 03/10/2026, APRES le lot 645-05b : 52 fleches vers l'INTERIEUR
/// d'une autre feature, imports relatifs RESOLUS — contre 182 apres le 645-05
/// et 223 au 02/10.
///
/// LES 130 PAYEES PAR LE 645-05b SONT TOUTES DU MEME GESTE, ET AUCUN CODE N'A
/// BOUGE. Les 130 croisements qui visaient un `providers/` passent par la
/// FACADE de la feature lue (ARB-645-05-b, decision B de Christophe) : un
/// fichier unique par feature, `lib/features/<f>/<f>_facade.dart`, qui
/// re-exporte avec un `show` explicite les seuls symboles que les autres
/// utilisent reellement. Vingt features en ont recu une. Un import qui vise
/// cette porte NE COMPTE PLUS comme croisement : c'est tout le sens de la
/// decision — ce n'est pas la fleche qu'on interdit, c'est qu'elle atterrisse
/// n'importe ou dans la feature voisine.
///
/// L'EXCLUSION EST ETROITE, ET ELLE EST GARDEE. Seul
/// `lib/features/<f>/<f>_facade.dart` compte comme facade ([estUneFacade]) :
/// un fichier qui s'appellerait `_facade.dart` ailleurs dans l'arborescence ne
/// vaut pas exemption. Et parce qu'une facade ne contient que des `export`, que
/// cette garde ne compterait pas, le test
/// « une facade ne re-exporte que SA feature » ferme le dernier trou : sans
/// lui, `export '../autre/x.dart'` dans une facade blanchirait un croisement.
///
/// CE QUI RESTE N'EST PLUS DE L'ETAT PARTAGE : aucun des 52 ne vise un
/// `providers/`. Voir l'en-tete pour leur repartition, et ARB-645-05-b.
const plafondCroisementsEntreFeatures = 52;

/// LE SOCLE NE CONNAIT PAS LE METIER : ZERO, ET PAS UN PLAFOND DE COMPLAISANCE.
///
/// ARB-645-05-c, DECISION B DE CHRISTOPHE (03/10/2026) : `lib/domain/` est
/// AU-DESSUS de `core/` et de `shared/`. Le metier a le droit de lire le socle
/// — c'est meme ainsi que `TrekStats` relit le seuil de bruit de l'altimetre —
/// mais le socle ne remonte jamais vers le metier. Tant que `mesurer_couches`
/// rangeait `core`, `shared` et `domain` dans UN SEUL sac appele « le socle »,
/// une fleche dans l'un ou l'autre sens ne comptait NULLE PART : il y en avait
/// trois de chaque cote, et rien ne les voyait.
///
/// POURQUOI ZERO EST TENABLE ICI, ALORS QUE (a) ET (b) GARDENT UN PLAFOND. Les
/// trois fleches existaient, et le lot 645-05b les a payees une par une — c'est
/// la seule raison. Le seuil de bruit de l'altimetre est DESCENDU dans
/// `GeoUtils` (c'est une propriete d'instrument, pas une regle de randonnee) ;
/// `privacy_data_policy.dart` est MONTE dans `lib/domain/` (c'est une regle de
/// conformite, typee sur [TrackPoint] de bout en bout) ; et le mapping
/// `TrekSession` <-> Drift a quitte le DAO pour
/// `lib/domain/trek_session_mapping.dart`, en extension, pour que les appelants
/// gardent le meme appel. Un plafond au-dessus de zero, ici, serait une
/// autorisation de recommencer.
const plafondSocleVersMetier = 0;

/// Une fleche interdite : le fichier qui importe, et ce qu'il atteint.
class Fleche {
  Fleche(this.depuis, this.import, this.vers);

  final String depuis;
  final String import;
  final String vers;

  @override
  String toString() => '$depuis -> $import  (= $vers)';
}

/// La feature a laquelle appartient [fichier], ou `null` hors `lib/features/`.
///
/// Une feature est le 3e segment du chemin : `lib/features/<nom>/...`.
String? featureDe(String fichier) {
  final parts = fichier.split('/');
  if (parts.length < 4) return null;
  if (parts[0] != 'lib' || parts[1] != 'features') return null;
  return parts[2];
}

/// Le chemin de la facade publique de [feature] (ARB-645-05-b).
///
/// UN SEUL nom possible par feature, et il est calcule, jamais devine : c'est
/// ce qui rend l'exclusion verifiable. `lib/features/trek/trek_facade.dart` est
/// la porte de `trek` ; `lib/features/trek/providers/trek_facade.dart` n'en
/// serait pas une.
String facadeDe(String feature) =>
    'lib/features/$feature/${feature}_facade.dart';

/// Vrai si [cible] est la facade publique de SA PROPRE feature.
bool estUneFacade(String cible) {
  final f = featureDe(cible);
  return f != null && cible == facadeDe(f);
}

void main() {
  late List<Fleche> socleVersFeature;
  late List<Fleche> croisements;
  late List<Fleche> socleVersMetier;

  setUpAll(() {
    final paquet = nomDuPaquet();
    final fichiers = sourcesLib();
    expect(
      fichiers,
      isNotEmpty,
      reason:
          'aucun source dans lib/ : la garde doit tourner a la racine du '
          'paquet Flutter, sinon elle mesure le vide et passe au vert',
    );

    socleVersFeature = <Fleche>[];
    croisements = <Fleche>[];
    socleVersMetier = <Fleche>[];

    for (final f in fichiers) {
      final zone = f.split('/').length > 1 ? f.split('/')[1] : '';
      final maFeature = featureDe(f);
      for (final imp in importsDe(lireSource(f))) {
        final cible = cibleDeLImport(f, imp, paquet);
        if (cible == null) continue;

        // (a) le socle ne connait pas ses clients. `domain` EST DU SOCLE
        // depuis la voie A (lot 645-05) : c'est la maison des modeles que
        // plusieurs features lisent, donc la couche la plus basse de
        // toutes. L'y oublier aurait ouvert un angle mort exactement la ou
        // ce lot deplace du code — un modele partage aurait pu importer une
        // feature sans que rien ne rougisse.
        if ((zone == 'core' || zone == 'shared' || zone == 'domain') &&
            cible.startsWith('lib/features/') &&
            f != routeurExclu) {
          socleVersFeature.add(Fleche(f, imp, cible));
        }

        // (b) deux features ne se connaissent pas AUTREMENT QUE PAR UNE
        // FACADE. Depuis ARB-645-05-b (decision B du 03/10/2026), un import
        // qui vise `lib/features/<f>/<f>_facade.dart` n'est plus un
        // croisement : c'est la lecture d'un contrat publie. Ce qui reste
        // compte, c'est la fleche qui atterrit DANS la feature voisine, sur un
        // `providers/`, un `domain/` ou une `presentation/` — l'interieur.
        if (maFeature != null) {
          final autre = featureDe(cible);
          if (autre != null && autre != maFeature && !estUneFacade(cible)) {
            croisements.add(Fleche(f, imp, cible));
          }
        }

        // (c) le socle ne connait pas le metier. `domain` est AU-DESSUS de
        // `core` et de `shared` (ARB-645-05-c) : le metier lit le socle,
        // jamais l'inverse. Le routeur n'est PAS exempte ici — son exception
        // porte sur les ecrans, pas sur les modeles.
        if ((zone == 'core' || zone == 'shared') &&
            cible.startsWith('lib/domain/')) {
          socleVersMetier.add(Fleche(f, imp, cible));
        }
      }
    }
  });

  group('645-01 / ECR-23 — le sens des dependances ne se degrade plus', () {
    test('ECR-23 (a) : pas plus de fleches du socle vers une feature '
        'qu au 03/10', () {
      expect(
        socleVersFeature.length,
        lessThanOrEqualTo(plafondSocleVersFeature),
        reason:
            'LE SOCLE SE MET A CONNAITRE SES CLIENTS. `core/` et `shared/` '
            'tirent desormais ${socleVersFeature.length} fleches vers une '
            'feature, contre $plafondSocleVersFeature au 03/10/2026 (mesure '
            'APRES exclusion du routeur, ARB-645-05-a). Une '
            'fleche qui repart du socle vers une feature ferme le cycle : on '
            'ne peut plus lire ni extraire `core/` sans embarquer la feature. '
            'Ce qu une feature doit au socle descend dans le socle ; le socle '
            'ne remonte jamais.\n  ${socleVersFeature.join('\n  ')}',
      );
    });

    test('ECR-23 (b) : pas plus de croisements vers l interieur d une autre '
        'feature qu au 03/10', () {
      expect(
        croisements.length,
        lessThanOrEqualTo(plafondCroisementsEntreFeatures),
        reason:
            'DEUX FEATURES SE SONT MISES A SE CONNAITRE SANS PASSER PAR LA '
            'PORTE. On compte ${croisements.length} imports qui visent '
            'l INTERIEUR d une autre feature, contre '
            '$plafondCroisementsEntreFeatures au 03/10/2026, APRES les facades '
            'du lot 645-05b. Une fleche directe vers un `providers/`, un '
            '`domain/` ou une `presentation/` voisine soude la paire : on n en '
            'touche plus une sans ouvrir l autre. Trois issues, dans cet '
            'ordre : lire la feature voisine par SA facade '
            '(`lib/features/<f>/<f>_facade.dart`, ARB-645-05-b) en y ajoutant '
            'le symbole au `show` si besoin — c est une decision, elle elargit '
            'son contrat ; ou faire monter dans `shared/`, `core/` ou '
            '`lib/domain/` ce que PLUSIEURS features lisent ; ou constater que '
            'les deux features n en font qu une. Relever ce plafond n est pas '
            'une issue (#P07).\n  ${croisements.join('\n  ')}',
      );
    });

    test('ECR-23 (c) : le socle ne connait pas le metier — ZERO fleche de '
        '`core/` ou `shared/` vers `lib/domain/`', () {
      expect(
        socleVersMetier.length,
        lessThanOrEqualTo(plafondSocleVersMetier),
        reason:
            'LE SOCLE SE MET A CONNAITRE LE METIER. `core/` ou `shared/` tirent '
            '${socleVersMetier.length} fleche(s) vers `lib/domain/`, contre '
            '$plafondSocleVersMetier exige depuis ARB-645-05-c (decision B de '
            'Christophe, 03/10/2026). `lib/domain/` est AU-DESSUS du socle : le '
            'metier a le droit de lire `core/` et `shared/`, le socle ne '
            'remonte JAMAIS vers le metier. Ce plafond est a zero parce que la '
            'mesure y est — les trois fleches qui existaient ont ete payees une '
            'par une par le lot 645-05b, pas tolerees. Deux issues, et une '
            'seule est bonne : faire DESCENDRE dans le socle ce qui n est pas '
            'du metier (le seuil de bruit de l altimetre est parti dans '
            '`GeoUtils`), ou faire MONTER dans `lib/domain/` ce qui l est '
            '(`privacy_data_policy.dart`, et le mapping Drift des sessions de '
            'trek). Baisser la regle n en est pas une.'
            '\n  ${socleVersMetier.join('\n  ')}',
      );
    });

    test('une facade ne re-exporte que SA feature — sans quoi l exclusion de '
        '(b) serait un trou', () {
      // POURQUOI CE TEST EXISTE. (b) n'est mesure que sur les `import`, et une
      // facade ne contient que des `export`. Si une facade re-exportait un
      // fichier d'une AUTRE feature, tous ses lecteurs atteindraient cette
      // feature sans qu'une seule fleche soit comptee : le croisement serait
      // blanchi par la porte censee le rendre visible. Une garde negative qui
      // se laisse contourner est pire qu'une garde absente, parce qu'elle
      // rassure.
      final paquet = nomDuPaquet();
      final fautes = <String>[];
      var facadesVues = 0;
      for (final f in sourcesLib()) {
        if (!estUneFacade(f)) continue;
        facadesVues++;
        final maFeature = featureDe(f)!;
        for (final exp in exportsDe(lireSource(f))) {
          final cible = cibleDeLImport(f, exp, paquet);
          if (cible == null) continue;
          if (!cible.startsWith('lib/features/$maFeature/')) {
            fautes.add('$f re-exporte $cible');
          }
        }
      }
      expect(
        fautes,
        isEmpty,
        reason:
            'UNE FACADE BLANCHIT UN CROISEMENT. Une facade publie le contrat de '
            'SA feature, et rien d autre. Re-exporter un fichier d une autre '
            'feature donne a tous ses lecteurs un acces que la garde (b) ne '
            'compte pas, puisqu elle ne lit que les `import` : le croisement '
            'disparait de la mesure sans disparaitre du code. Ce qui est '
            'partage par plusieurs features monte dans `shared/`, `core/` ou '
            '`lib/domain/` ; ce qui appartient a une voisine se lit par SA '
            'facade.\n  ${fautes.join('\n  ')}',
      );
      expect(
        facadesVues,
        greaterThan(0),
        reason:
            'AUCUNE FACADE TROUVEE, DONC CE TEST NE MESURE RIEN. Vingt features '
            'en ont recu une au lot 645-05b ; si le compte tombe a zero, c est '
            'que la convention de nom a change ou que les facades ont ete '
            'retirees — et alors l exclusion de (b) ne protege plus rien.',
      );
    });

    test('la resolution des imports relatifs fonctionne — sans quoi les trois '
        'plafonds ci-dessus ne mesurent rien', () {
      // UNE GARDE QUI NE SAIT PLUS RESOUDRE PASSE AU VERT EN SILENCE. Si
      // `cibleDeLImport` se mettait a rendre `null` ou un chemin tronque, les
      // deux mesures tomberaient a zero et cette garde declarerait le depot
      // sain. On verifie donc la resolution elle-meme, sur les trois formes
      // qui comptent, dont celle des 20 fleches fantomes de l'audit 644.
      const depuis = 'lib/features/trek/presentation/map/map_screen.dart';
      expect(
        cibleDeLImport(depuis, '../../domain/models/stage.dart', 'moteur_gr'),
        'lib/features/trek/domain/models/stage.dart',
        reason: 'un `../../` INTERNE a la feature doit rester dans la feature',
      );
      expect(
        cibleDeLImport(depuis, '../../../hub/widgets/x.dart', 'moteur_gr'),
        'lib/features/hub/widgets/x.dart',
        reason: 'un `../../../` vers une voisine doit bien la designer',
      );
      expect(
        cibleDeLImport(
          depuis,
          'package:moteur_gr/core/theme/t.dart',
          'moteur_gr',
        ),
        'lib/core/theme/t.dart',
        reason: 'un import `package:` du depot doit se ramener a lib/',
      );
      expect(
        cibleDeLImport(depuis, 'package:flutter/material.dart', 'moteur_gr'),
        isNull,
        reason: 'un paquet tiers ne designe aucun fichier du depot',
      );
      expect(
        nomDuPaquet(),
        'moteur_gr',
        reason: 'le nom du paquet est lu dans pubspec.yaml, jamais devine',
      );
    });
  });
}
