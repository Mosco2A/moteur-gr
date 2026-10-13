// GARDE ANTI-DISPARITION — « IL N Y A PAS DE PUB POSSIBLE EN MODE RANDO !!! »
// (tache 838, volet D1).
//
// POURQUOI CETTE GARDE EXISTE, ET ELLE N'EST PAS DECORATIVE : LA REGLE A DEJA
// DISPARU UNE FOIS, EN SILENCE, LE JOUR MEME OU ELLE A ETE POSEE.
//
// Chronologie mesuree dans l'historique du depot :
//   * 27/09 au matin — la garde « en mode trek jamais » entre dans la DECISION
//     publicitaire (tache 595, volet B6), avec SIX tests de comportement ;
//   * 27/09 a 14:41 — une phrase simplifie le modele a deux exceptions, et la
//     garde est retiree (commit 6030a07f, tache 601). LES SIX TESTS SONT
//     SUPPRIMES AVEC ELLE. Le commit l'ecrit noir sur blanc : « les SIX tests
//     du groupe B6 [...] affirmaient l'inverse de la regle en vigueur : les
//     retourner n'aurait rien mesure » ;
//   * 12/10 — Christophe tranche de nouveau, verbatim : « IL N Y A PAS DE PUB
//     POSSIBLE EN MODE RANDO !!! ». La garde est remise (tache 838, D1).
//
// VOILA LE DEFAUT DE CONCEPTION QUE CE FICHIER FERME. Une regle protegee
// UNIQUEMENT par des tests de comportement peut partir avec eux : celui qui
// retire la regle retire les tests qui l'affirment, tout est vert, et plus rien
// dans le depot ne dit qu'une decision de Christophe a ete defaite. C'est
// exactement ce qui s'est passe, et personne n'a menti — chaque etape etait
// coherente avec la precedente.
//
// CE FICHIER NE MESURE DONC PAS LE COMPORTEMENT, IL MESURE LE SOURCE. Il lit
// `ads_providers.dart` et exige d'y TROUVER la garde. Pour l'eteindre, il faut
// venir ici et effacer une affirmation qui porte le verbatim de Christophe
// et sa date — c'est-a-dire le faire SCIEMMENT, et en laisser la trace
// dans un diff.
// Une suppression silencieuse n'est plus possible.
//
// LE COMPORTEMENT, LUI, RESTE MESURE AILLEURS, ET C'EST VOULU : le groupe B7 de
// `pub_v1_595_test.dart` verifie sur la vraie decision — base de donnees,
// monetisation reelle, regie comptant les demandes REELLEMENT parties —
// qu'aucune banniere ne part en marchant un sentier gratuit. Les deux
// gardes sont complementaires : celle-la dit que la regle EST ECRITE,
// l'autre qu'elle FONCTIONNE.
library;

import 'package:flutter_test/flutter_test.dart';

import 'mesure_des_sources_645.dart';

/// Le fichier qui porte la decision publicitaire.
const _decision = 'lib/features/ads/providers/ads_providers.dart';

/// Le predicat « une rando est en cours », tel que la decision le nomme.
const _predicat = 'enModeTrekProvider';

/// Les lignes de CODE de [rel] : les commentaires ne comptent pas.
///
/// Sans ce filtre, l'en-tete de la garde — qui cite forcement le nom du
/// provider pour s'expliquer — suffirait a la faire passer. Une regle doit etre
/// EXECUTEE, pas evoquee.
List<String> _lignesDeCode(String rel) =>
    lignesDe(rel).where((l) => !estLigneDeCommentaire(l)).toList();

void main() {
  group('838 D1 — la regle « jamais de pub en rando » est ECRITE', () {
    test('le predicat « une rando est en cours » existe dans la decision', () {
      final code = _lignesDeCode(_decision);

      expect(
        code.any((l) => l.contains('final $_predicat')),
        isTrue,
        reason:
            'LE PROVIDER $_predicat A DISPARU DE $_decision.\n'
            'Il porte la regle de Christophe, verbatim : « IL N Y A PAS DE PUB '
            'POSSIBLE EN MODE RANDO !!! ».\n'
            'Cette regle a deja ete retiree une fois, le 27/09, quelques '
            'heures apres avoir ete posee, et ses six tests sont partis '
            'avec elle — '
            'personne n a pu le voir. Si tu la retires de nouveau, ce n est '
            'pas un detail de refactoring : c est defaire une decision de '
            'Christophe. Va le lui demander.',
      );
    });

    test('la decision de banniere CONSULTE ce predicat', () {
      final code = _lignesDeCode(_decision);

      // On cherche la garde elle-meme, pas seulement le nom : un provider
      // declare que personne ne lit est precisement l'etat dans lequel la
      // tache 601 a trouve `enModeTrekProvider` avant de le supprimer
      // (« son provider devenu sans lecteur »).
      expect(
        code.any(
          (l) => l.contains('watch($_predicat)') && l.contains('return false'),
        ),
        isTrue,
        reason:
            'LA GARDE N EST PLUS LUE DANS LA DECISION. Le provider '
            '$_predicat peut exister et ne servir a rien : c est exactement '
            'l etat ou la tache 601 l a trouve avant de le supprimer — '
            '« son provider devenu sans lecteur ». La decision doit rendre '
            '`false` DES QU UNE RANDO EST EN COURS, sinon la regle de '
            'Christophe n est plus appliquee, seulement documentee.',
      );
    });

    test('la garde passe AVANT toute attente : rien ne peut partir', () {
      final code = _lignesDeCode(_decision);
      final garde = code.indexWhere(
        (l) => l.contains('watch($_predicat)') && l.contains('return false'),
      );
      expect(garde, greaterThanOrEqualTo(0), reason: 'garde introuvable');

      // LA PREMIERE ATTENTE DE LA DECISION, QUELLE QU'ELLE SOIT. En mode trek
      // on ne consulte pas le consentement, on ne lit pas la monetisation, on
      // ne demande rien : la regle la plus forte du modele doit etre la
      // premiere evaluee, et elle doit court-circuiter tout le reste.
      final premiereAttente = code.indexWhere((l) => l.contains('await '));
      expect(premiereAttente, greaterThanOrEqualTo(0));

      expect(
        garde,
        lessThan(premiereAttente),
        reason:
            'LA GARDE EST PASSEE APRES UNE ATTENTE (ligne de garde $garde, '
            'premiere attente $premiereAttente). En mode rando, rien ne doit '
            'etre consulte ni demande : ni le consentement publicitaire, ni la '
            'monetisation, ni la regie. Une garde posee apres un `await` '
            'laisse la chaine publicitaire demarrer avant de dire non — et une '
            'banniere masquee mais DEMANDEE compte une impression et envoie '
            'les donnees de l appareil chez Google.',
      );
    });

    test('la consigne perimee qui interdisait cette garde a disparu', () {
      // CE TEST GARDE LA MEMOIRE A JOUR, PAS LE CODE. Le fichier portait une
      // consigne explicite au prochain agent : « QUE LE PROCHAIN AGENT NE
      // REMETTE PAS DE GARDE ICI ». Elle a ete ecrite de bonne foi le 27/09 ;
      // la parole de Christophe du 12/10 la perime. La laisser vivre a cote de
      // la garde qu'elle interdit, c'est preparer le prochain retrait « bien
      // intentionne » — quelqu un lira la consigne, pas l historique.
      final source = lireSource(_decision).toUpperCase();

      expect(
        source.contains('NE REMETTE PAS DE GARDE ICI'),
        isFalse,
        reason:
            'LA CONSIGNE QUI INTERDIT CETTE GARDE EST ENCORE DANS LE FICHIER, '
            'a cote de la garde elle-meme. Deux instructions contraires dans '
            'le meme fichier, c est la garantie que la plus ancienne gagnera '
            'un jour. La parole de Christophe du 12/10 — « IL N Y A PAS DE PUB '
            'POSSIBLE EN MODE RANDO !!! » — est la plus recente : c est elle '
            'qui doit rester ecrite.',
      );
    });
  });
}
