// GARDE — UN MECANISME DE VERSEMENT NE RESTE PAS SANS APPELANT (tache 813).
//
// LA FAUTE QUE CETTE GARDE EMPECHE DE REVENIR, ET ELLE A COUTE DE L'ARGENT A
// DE VRAIS ABONNES. Le 11/10/2026, `grantSubscriberAllowance` etait ecrite EN
// ENTIER et correctement : abonne actif seulement, rien en demo, une seule fois
// par periode, credit du compte-etapes, journal. `kSubscriberStepsAllowance`
// valait bien 2. Et PERSONNE NE L'APPELAIT DANS `lib/` : ses deux seuls
// appelants etaient des tests, plus un reexport de facade qui ne fait que
// passer l'appel. Un abonne payait donc deux euros par mois, ne recevait
// JAMAIS une seule etape, et l'ecran d'abonnement lui annoncait pourtant
// « 2 etapes creditees chaque mois ». L'application promettait ce qu'elle ne
// faisait pas.
//
// POURQUOI AUCUNE DES GARDES EXISTANTES NE L'A VU, ET C'EST LE FOND DU SUJET.
// `aucun_code_mort_645` ne regarde que les declarations de HAUT NIVEAU — une
// METHODE lui est invisible. Et elle compte les citations de `lib/`, `test/`,
// `integration_test/` et `tool/` ensemble : un mecanisme appele par ses seuls
// tests lui parait vivant. C'est exactement le profil du trou. Un versement
// teste mais jamais branche passe donc les deux filtres a la fois.
//
// LA REGLE, ET ELLE NE REGARDE QUE `lib/` :
//
//     UN MECANISME DE VERSEMENT A AU MOINS UN APPELANT DANS `lib/`,
//     HORS SA PROPRE DECLARATION ET HORS SIMPLE DELEGATION.
//
// UN TEST N'EST PAS UN APPELANT DE PRODUCTION. C'est toute la lecon : le
// mecanisme marchait, ses tests passaient au vert, et le randonneur ne touchait
// rien. Un test prouve qu'un mecanisme FONCTIONNE quand on l'appelle ; il ne
// prouve jamais que l'application l'APPELLE.
//
// UNE DELEGATION N'EST PAS UN APPELANT NON PLUS. `MonetizationService` reexpose
// chaque methode de ses collaborateurs par une ligne qui ne fait que passer
// l'appel (`Future<X> truc() => _collab.truc();`). Compter cette ligne
// suffirait a eteindre la garde pour tout mecanisme reexpose par la facade,
// c'est-a-dire pour tous. La garde retire donc la declaration ET le corps en
// fleche qui la suit.
//
// ---------------------------------------------------------------------------
// LA LIMITE EST ASSUMEE, ET ELLE EST ECRITE
// ---------------------------------------------------------------------------
//
// La garde lit du TEXTE, hors commentaires et hors chaines. Elle ne sait donc
// pas si l'appelant qu'elle trouve est lui-meme joignable : brancher un
// versement dans une methode morte la ferait passer au vert. Elle repond a
// « ce versement est-il cable quelque part dans l'application ? », pas a
// « ce cable est-il sous tension ? ». C'est deja la question qui manquait.
//
// Le registre est NOMME A LA MAIN, et c'est voulu : la liste des mecanismes qui
// donnent des etapes ou un droit sans paiement immediat est courte, elle se lit
// dans le modele economique, et la tenir a la main oblige a passer ici quand on
// en ajoute un. Un versement neuf absent du registre n'est pas garde — mais il
// n'est pas garde non plus par les six autres gardes du depot, et celui-ci est
// le seul endroit ou l'oubli se voit.
library;

import 'package:flutter_test/flutter_test.dart';

import 'mesure_des_sources_645.dart';

/// UN MECANISME QUI DONNE DES ETAPES OU UN DROIT SANS PAIEMENT IMMEDIAT.
///
/// Les trois entrees ne sont pas trois exemples : ce sont les trois seuls
/// chemins par lesquels le solde du randonneur ou son sans-pub montent sans
/// qu'un recu du store arrive en meme temps. Chacune porte CE QU'ELLE VERSE,
/// pour que la garde rouge dise au lecteur ce que le randonneur ne recoit pas.
const registreDesVersements = <String, String>{
  // Le trou du 11/10 : 2 etapes par mois promises a l'ecran d'abonnement.
  'grantSubscriberAllowance':
      'les etapes mensuelles de l abonne (kSubscriberStepsAllowance) — '
      'l ecran d abonnement les ANNONCE au randonneur',
  // Deja branche le 11/10 (`ads_providers.dart`) : il tient la garde honnete.
  // Si elle ne trouvait pas CET appelant, elle ne lirait plus rien et
  // passerait au vert sur le trou qu elle est censee voir.
  'grantRewardNoAds': 'le sans-pub de 24 h gagne apres une pub recompensee',
  // Le primitif sous les deux precedents : la seule ecriture qui fait monter
  // le solde. Sa forme est differente (methode d un stockage, pas d un
  // service), donc il prouve que la detection ne tient pas a une forme.
  'credit': 'le credit du compte-etapes lui-meme (WalletStore)',
};

/// LE SOURCE DART PRIVE DE SES COMMENTAIRES ET DE SES CHAINES.
///
/// La ponctuation est GARDEE, contrairement a [identifiants] : la garde doit
/// distinguer une declaration d'un appel, donc voir les parentheses et les
/// fleches. Sans ce nettoyage, documenter la garde en nommant le mecanisme
/// suffirait a l'eteindre — le defaut qu'avait connu
/// `tout_ecran_a_une_route_573`, ou une phrase de doc declarait joignable un
/// ecran que personne ne pouvait ouvrir.
String codeNu(String source) {
  var texte = source.replaceAll(RegExp(r'^\s*///.*$', multiLine: true), '');
  texte = texte.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), ' ');
  texte = texte.replaceAll(RegExp(r'(?<!:)//.*$', multiLine: true), '');
  texte = texte.replaceAll(
    RegExp("'''.*?'''|\"\"\".*?\"\"\"", dotAll: true),
    ' ',
  );
  texte = texte.replaceAll(RegExp(r"'(?:\\.|[^'\\])*'"), ' ');
  return texte.replaceAll(RegExp(r'"(?:\\.|[^"\\])*"'), ' ');
}

/// Vrai si [ligne] DECLARE la methode [nom] (et ne l'appelle donc pas).
bool _declare(String ligne, String nom) => RegExp(
  r'^\s*(?:@override\s+)?(?:Future<[^>]*>|Stream<[^>]*>|void|bool|int)\s+'
  '$nom'
  r'\s*\(',
).hasMatch(ligne);

/// LES LIGNES DE [source] QUI APPELLENT VRAIMENT [nom].
///
/// Retire d'abord les DECLARATIONS de [nom] — et, quand la declaration est
/// suivie d'un corps EN FLECHE, tout ce corps jusqu'au `;`. C'est ce qui
/// empeche la ligne `=> _collab.truc();` d'une facade de compter : elle ne
/// decide rien, elle passe l'appel de quelqu'un d'autre.
List<int> appelsDe(String source, String nom) {
  final lignes = codeNu(source).split('\n');
  final motif = RegExp('\\b$nom\\b');
  final appels = <int>[];
  var i = 0;
  while (i < lignes.length) {
    final ligne = lignes[i];
    if (_declare(ligne, nom)) {
      // Corps en fleche (pas de `{` ouvrant sur la declaration) : on avale
      // jusqu'au `;`, sinon la delegation compterait comme un appel.
      if (!ligne.contains('{')) {
        while (i < lignes.length && !lignes[i].contains(';')) {
          i++;
        }
      }
      i++;
      continue;
    }
    if (motif.hasMatch(ligne)) appels.add(i + 1);
    i++;
  }
  return appels;
}

void main() {
  late Map<String, List<String>> appelantsParMecanisme;

  setUpAll(() {
    final fichiers = sourcesLib();
    expect(
      fichiers,
      isNotEmpty,
      reason:
          'aucun source dans lib/ : la garde mesurerait le vide et '
          'passerait au vert',
    );
    appelantsParMecanisme = <String, List<String>>{
      for (final nom in registreDesVersements.keys) nom: <String>[],
    };
    for (final f in fichiers) {
      final source = lireSource(f);
      for (final nom in registreDesVersements.keys) {
        final lignes = appelsDe(source, nom);
        if (lignes.isNotEmpty) {
          appelantsParMecanisme[nom]!.add('$f:${lignes.join(',')}');
        }
      }
    }
  });

  group('813 — aucun versement sans appelant de production', () {
    for (final entree in registreDesVersements.entries) {
      test('« ${entree.key} » est appele quelque part dans lib/', () {
        expect(
          appelantsParMecanisme[entree.key],
          isNotEmpty,
          reason:
              'LE RANDONNEUR NE RECOIT RIEN : « ${entree.key} » verse '
              '${entree.value}, et aucun fichier de lib/ ne l appelle hors '
              'de sa propre declaration et de ses delegations.\n'
              'UN TEST N EST PAS UN APPELANT DE PRODUCTION : un mecanisme '
              'vert en test et jamais branche promet ce qu il ne fait pas. '
              'C est le trou du 11/10 sur la cagnotte de l abonne, qui a '
              'laisse de vrais abonnes payer sans jamais etre credites.\n'
              'BRANCHEZ-LE sur la chaine reelle (la boucle de completion du '
              'store, ou le chargement au boot) — ne desarmez pas la garde.',
        );
      });
    }

    test('la detection ne compte ni un commentaire, ni une chaine, ni une '
        'delegation — sans quoi les gardes ci-dessus ne mesurent rien', () {
      // UNE GARDE QUI NE RELEVE PLUS RIEN PASSE AU VERT EN SILENCE. Les trois
      // faux appelants ci-dessous sont les trois facons dont celle-ci pourrait
      // s eteindre sans que personne ne branche quoi que ce soit.
      expect(
        appelsDe('// on appelle verser() ici un jour', 'verser'),
        isEmpty,
        reason: 'un commentaire NOMME le mecanisme, il ne l appelle pas',
      );
      expect(
        appelsDe('/// [verser] fait le versement\nvar x = 1;', 'verser'),
        isEmpty,
        reason: 'une doc qui renvoie au mecanisme ne l appelle pas',
      );
      expect(
        appelsDe("var nom = 'verser';", 'verser'),
        isEmpty,
        reason: 'une chaine de caracteres n appelle rien',
      );
      expect(
        appelsDe('  Future<void> verser() => _collab.verser();', 'verser'),
        isEmpty,
        reason:
            'UNE DELEGATION N EST PAS UN APPELANT : la facade reexpose tous '
            'les mecanismes, compter sa ligne eteindrait la garde pour tous',
      );
      expect(
        appelsDe(
          '  Future<int> verser() =>\n      _collab.verser();',
          'verser',
        ),
        isEmpty,
        reason: 'une delegation coupee en deux lignes reste une delegation',
      );
      expect(
        appelsDe(
          '  Future<void> verser() async {\n    await credit(2);\n  }',
          'verser',
        ),
        isEmpty,
        reason: 'le corps de la declaration ne s appelle pas lui-meme',
      );
      // ET ELLE VOIT UN VRAI APPEL, sous ses deux formes.
      expect(
        appelsDe(
          '  Future<void> boot() async {\n    await verser();\n  }',
          'verser',
        ),
        isNotEmpty,
        reason: 'un appel reel dans un corps de methode doit compter',
      );
      expect(
        appelsDe('    _iap.onLivraison = _abo.verser;', 'verser'),
        isNotEmpty,
        reason:
            'un branchement par reference (sans parentheses) est le cablage '
            'd un versement, donc un appelant',
      );
    });
  });
}
