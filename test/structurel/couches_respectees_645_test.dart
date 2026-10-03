// GARDE DE PLAFOND — ECR-23 : LE SENS DES DEPENDANCES (tache 645-01).
//
// CE QUE LA REGLE DIT. Deux interdits, et ils vont dans le meme sens :
//
//   (a) LE SOCLE NE CONNAIT PAS SES CLIENTS. `core/` et `shared/` sont ce sur
//       quoi les features reposent ; une fleche qui repart du socle vers une
//       feature ferme le cycle et rend le socle inextractible. On ne peut plus
//       lire `core/` sans lire la feature, ni livrer l'un sans l'autre.
//
//   (b) DEUX FEATURES NE SE CONNAISSENT PAS. Ce qu'elles partagent monte dans
//       `shared/` ou `core/`. Une fleche directe entre deux features fait de
//       la paire un seul bloc : on n'en touche plus une sans ouvrir l'autre.
//
// POURQUOI UN PLAFOND ET PAS ZERO, APRES LE LOT 645-05. Il y avait 301 fleches
// interdites au 02/10/2026 ; il en reste 254 au 03/10, et le lot 645-05 a fait
// ce que le RANGEMENT pouvait faire. Ce qui reste n'est PAS du rangement, et
// c'est la mesure qui le dit :
//
//   - 51 des 72 fleches socle -> feature sortent d'UN SEUL fichier,
//     `lib/core/routing/app_router.dart`, qui importe un ecran par route. Ce
//     n'est pas un modele mal range, c'est la forme d'un routeur central :
//     GoRouter demande la liste des routes en un point, et une route cite
//     l'ecran qu'elle monte. Les ramener a zero demande d'INVERSER le routeur
//     (chaque feature declare ses routes, le socle ne connait qu'un registre),
//     ce qui touche les 30 ecrans, les gardes de route et l'ordre de
//     declaration dont depend la resolution des deeplinks.
//   - 130 des 182 croisements visent un `providers/`, c'est-a-dire de l'ETAT
//     RIVERPOD partage. Deplacer un provider n'est pas un deplacement de type :
//     c'est un recablage du graphe, et SPEC-06 interdit de changer un
//     comportement en deplacant.
//
// Les deux sont inscrits en ARB-645-05-a et ARB-645-05-b dans
// `docs/assainissement/644-03-decoupage-et-plan.md` : ils demandent une
// decision de Christophe, pas du code. En attendant, cette garde fait la seule
// chose utile : elle empeche le chiffre d'AUGMENTER. Une garde qui exigerait
// zero aujourd'hui serait rouge en permanence, donc desarmee en une semaine.
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
const plafondSocleVersFeature = 72;

/// Mesure du 03/10/2026, APRES le lot 645-05 : 182 fleches entre deux features
/// differentes, imports relatifs RESOLUS — contre 223 au 02/10. `tool/
/// audit_global.py` annonce le meme 182 depuis que ce lot a corrige sa
/// resolution des imports relatifs.
///
/// Les 41 payees par ce lot sont toutes du MEME geste : onze modeles que
/// plusieurs features lisaient depuis la maison d'une seule sont descendus
/// dans `lib/domain/` (ou `lib/shared/` pour le vocabulaire visuel des POI).
///
/// CE QUI RESTE N'EST PAS DU RANGEMENT : 130 des 182 visent un `providers/`,
/// c'est-a-dire de l'etat Riverpod partage. Voir l'en-tete, et ARB-645-05-b.
const plafondCroisementsEntreFeatures = 182;

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

void main() {
  late List<Fleche> socleVersFeature;
  late List<Fleche> croisements;

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
            cible.startsWith('lib/features/')) {
          socleVersFeature.add(Fleche(f, imp, cible));
        }

        // (b) deux features ne se connaissent pas.
        if (maFeature != null) {
          final autre = featureDe(cible);
          if (autre != null && autre != maFeature) {
            croisements.add(Fleche(f, imp, cible));
          }
        }
      }
    }
  });

  group('645-01 / ECR-23 — le sens des dependances ne se degrade plus', () {
    test('ECR-23 (a) : pas plus de fleches du socle vers une feature '
        'qu au 02/10', () {
      expect(
        socleVersFeature.length,
        lessThanOrEqualTo(plafondSocleVersFeature),
        reason:
            'LE SOCLE SE MET A CONNAITRE SES CLIENTS. `core/` et `shared/` '
            'tirent desormais ${socleVersFeature.length} fleches vers une '
            'feature, contre $plafondSocleVersFeature au 02/10/2026. Une '
            'fleche qui repart du socle vers une feature ferme le cycle : on '
            'ne peut plus lire ni extraire `core/` sans embarquer la feature. '
            'Ce qu une feature doit au socle descend dans le socle ; le socle '
            'ne remonte jamais.\n  ${socleVersFeature.join('\n  ')}',
      );
    });

    test('ECR-23 (b) : pas plus de croisements entre features qu au 02/10', () {
      expect(
        croisements.length,
        lessThanOrEqualTo(plafondCroisementsEntreFeatures),
        reason:
            'DEUX FEATURES SE SONT MISES A SE CONNAITRE. On compte '
            '${croisements.length} imports croises, contre '
            '$plafondCroisementsEntreFeatures au 02/10/2026. Une fleche '
            'directe entre deux features soude la paire : on n en touche plus '
            'une sans ouvrir l autre. Ce qu elles partagent monte dans '
            '`shared/` ou `core/`.\n  ${croisements.join('\n  ')}',
      );
    });

    test('la resolution des imports relatifs fonctionne — sans quoi les deux '
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
