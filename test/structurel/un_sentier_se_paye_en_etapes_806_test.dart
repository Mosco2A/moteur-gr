// GARDE — UN SENTIER SE PAYE EN ETAPES, JAMAIS EN EUROS (tache 806).
//
// CE QUE CETTE GARDE EMPECHE DE REVENIR. Le 11/10/2026, la carte du catalogue
// affichait « Acheter — 6.93 € » sur le Mare a Mare Centre, alors que la
// pastille juste au-dessus annoncait deja « 7 ». Les deux disaient le meme
// prix, et un seul des deux etait vrai.
//
// POURQUOI LE MONTANT EN EUROS EST FAUX PAR CONSTRUCTION, et pas seulement mal
// ecrit. Il valait `nombre d'etapes x kStepTierEur`, donc il supposait que le
// randonneur achete ses etapes A L'UNITE — le tarif le plus DEFAVORABLE de la
// grille. Or le prix d'une etape en euros n'existe pas dans l'absolu : il
// depend de la facon dont CHAQUE randonneur a rempli sa cagnotte. A l'unite,
// 0,99 EUR ; par pack, 0,91 puis 0,80 puis 0,70 l'etape selon la taille ; par
// le cagnotage de l'abonnement, autre chose encore. Un prix en euros sur une
// carte de sentier decrit donc L'ACHETEUR, pas le sentier — et il annonce a
// tout le monde le tarif de celui qui paie le plus cher.
//
// LA LOI, DE CHRISTOPHE, LE 11/10 : « tu ne paye pas en argent mais en ETAPES »
// et « Le prix est affiche en etape, le prix de l etape depend de ce que tu as
// choisi en achetant, unite, pack cagnotage ».
//
// ---------------------------------------------------------------------------
// CE QUE LA GARDE LIT, ET POURQUOI ELLE LIT DU TEXTE
// ---------------------------------------------------------------------------
//
// Elle lit le SOURCE des fichiers, pas un rendu. Un test de rendu dirait que la
// carte d'AUJOURD'HUI est juste ; celui-ci dit qu'aucune des trois portes
// d'achat ne peut RE-DEVENIR fausse, y compris sur un sentier qu'aucun test de
// rendu n'exerce. C'est le meme choix que `les_lieux_parlent_francais_801` et
// `aucun_bouton_brut_645` : une regle d'ecriture se tient a la lecture.
//
// LES DEUX PORTES DU COMPTOIR NE SONT PAS VISEES, ET C'EST VOULU. Quand il
// manque des etapes, la vitrine propose le complement exact ou un pack : la,
// on paye VRAIMENT avec de l'argent, et les deux montants cote a cote SONT
// l'arbitrage que Christophe veut montrer. L'euro est chez lui au comptoir ;
// il n'a rien a faire sur un sentier.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Le caractere interdit sur un sentier.
const String euro = '€';

/// Les CARTES DE SENTIER : elles annoncent le prix d'un sentier et rien
/// d'autre. Aucune des deux n'a de raison de parler d'argent.
///
/// La vitrine (`paywall_sheet.dart`) n'est PAS dans cette liste : elle porte
/// aussi le comptoir des deux portes, ou l'euro est legitime. Son bouton
/// d'achat est tenu autrement, par [clesComptantDesEtapes].
const List<String> cartesDeSentier = <String>[
  'lib/features/trail/presentation/trail_catalog_screen.dart',
  'lib/features/hub/presentation/widgets/hub_buy_trek_button.dart',
];

/// Ce qu'une carte de sentier ne doit APPELER sous aucune forme.
///
/// `eurPrice...` et `priceEur` sont les deux familles de noms par lesquelles un
/// montant en euros entrait dans un ecran ; `kStepTierEur` est le palier a 0,99
/// dont on les derivait ; `montantEnEuros` est le formateur du comptoir, qui
/// n'a rien a faire sur un sentier.
///
/// `toStringAsFixed` N'Y FIGURE PAS, ET C'EST MESURE. La carte du catalogue
/// l'emploie legitimement pour une DISTANCE (« 87 km »). L'interdire ferait
/// tomber la garde sur un usage juste — et le caractere euro suffit a attraper
/// l'usage fautif, puisqu'un montant finit toujours par porter son symbole.
const List<String> motsInterditsSurUnSentier = <String>[
  euro,
  'eurPrice',
  'priceEur',
  'kStepTierEur',
  'montantEnEuros',
];

/// Les cles i18n qui affichent un NOMBRE D'ETAPES au randonneur.
///
/// Toutes les trois doivent etre declarees en `(plural)` : elles accolent un
/// nombre a un nom, et ce nom s'accorde. Le nom de la cle est donne SANS le
/// modificateur `(plural)`, que le test ajoute lui-meme.
const List<String> clesComptantDesEtapes = <String>[
  'buyCtaWithSteps',
  'complementDoorExact',
  'complementDoorPack',
];

/// Les cinq langues du depot.
const List<String> langues = <String>['fr', 'en', 'de', 'it', 'es'];

/// La seule citation du caractere euro admise dans `lib/` hors du formateur.
///
/// `StepPack.toString()` ecrit « 9.99€ » dans un journal de mise au point. Ce
/// n'est pas un affichage : aucun ecran ne montre un `toString` de modele, et
/// la garde `observabilite_des_ecrans_645` le verifie de son cote. On la NOMME
/// plutot que de l'ignorer : une exception ecrite se discute, une exception
/// tacite se multiplie.
const String exceptionToStringDeDebug =
    'lib/core/services/monetization_models.dart';

/// Le formateur unique : le seul endroit du depot qui ecrit de l'argent.
const String formateurUnique = 'lib/core/utils/montant_en_euros.dart';

List<File> _fichiersDart(String racine) => Directory(racine)
    .listSync(recursive: true)
    .whereType<File>()
    .where((File f) => f.path.endsWith('.dart'))
    .toList();

/// Chemin en barres obliques, pour comparer sur Windows comme ailleurs.
String _chemin(File f) => f.path.replaceAll(r'\', '/');

/// Le CODE seul : commentaires de ligne et de bloc retires.
///
/// POURQUOI, ET LE DEPOT L'A DEJA PAYE UNE FOIS. Sans cela, cette garde
/// s'eteindrait en lisant sa propre explication : les commentaires de la tache
/// 806 CITENT « 6.93 € » et `eurPriceForTrail` pour raconter ce qui a ete
/// retire. Un commentaire qui NOMME un symbole ne l'appelle pas, il en parle —
/// c'est le mot de `aucun_code_mort_645`, et c'est le defaut exact qu'avait
/// connu `tout_ecran_a_une_route_573` (tache 580), ou une phrase de doc
/// suffisait a declarer joignable un ecran que personne ne pouvait ouvrir.
///
/// LA LIMITE EST ECRITE : un `//` a l'interieur d'une chaine de caracteres
/// coupe la ligne trop tot. Le risque est donc de MANQUER une faute, jamais
/// d'en inventer une — c'est le bon sens pour une garde.
String _codeSeul(String source) {
  final StringBuffer sortie = StringBuffer();
  bool dansUnBloc = false;
  for (final String ligne in const LineSplitter().convert(source)) {
    final StringBuffer gardee = StringBuffer();
    String? guillemet;
    for (int i = 0; i < ligne.length; i++) {
      final String c = ligne[i];
      final String deux = i + 1 < ligne.length ? ligne.substring(i, i + 2) : '';
      if (dansUnBloc) {
        if (deux == '*/') {
          dansUnBloc = false;
          i++;
        }
        continue;
      }
      if (guillemet == null && deux == '//') break;
      if (guillemet == null && deux == '/*') {
        dansUnBloc = true;
        i++;
        continue;
      }
      if (guillemet == null && (c == "'" || c == '"')) {
        guillemet = c;
      } else if (guillemet == c && (i == 0 || ligne[i - 1] != r'\')) {
        guillemet = null;
      }
      gardee.write(c);
    }
    sortie.writeln(gardee);
  }
  return sortie.toString();
}

/// Vrai pour les traductions engendrees par `dart run slang` : elles recopient
/// les fichiers d'`assets/i18n/`, qui sont deja tenus par leur propre test.
bool _estTraductionEngendree(String chemin) => chemin.contains('/lib/i18n/');

void main() {
  group('Un sentier se paye en etapes (806)', () {
    test('aucune carte de sentier ne nomme un montant en euros', () {
      final List<String> trouvailles = <String>[];
      for (final String chemin in cartesDeSentier) {
        final File fichier = File(chemin);
        expect(
          fichier.existsSync(),
          isTrue,
          reason:
              '$chemin a disparu : si la carte a demenage, deplace aussi la '
              'garde, ne la laisse pas verte sur un fichier absent',
        );
        final String source = _codeSeul(fichier.readAsStringSync());
        for (final String interdit in motsInterditsSurUnSentier) {
          if (source.contains(interdit)) {
            trouvailles.add('$chemin nomme [$interdit]');
          }
        }
      }
      expect(
        trouvailles,
        isEmpty,
        reason:
            'Le prix d un sentier est un NOMBRE D ETAPES, pas un montant. Un '
            'montant en euros depend de la facon dont l acheteur a rempli sa '
            'cagnotte, donc de l acheteur et non du sentier :\n'
            '${trouvailles.join('\n')}',
      );
    });

    test('les libelles comptes en etapes sont au PLURIEL, en 5 langues', () {
      // CE QUE CETTE VERIFICATION FERME. Les trois libelles concatenaient le
      // nombre et un « etapes » toujours au pluriel : un complement d UNE
      // etape s ecrivait « Acheter le complement — 1 etapes ». Et le
      // complement d une seule etape n est pas un cas limite, c est le cas le
      // plus FREQUENT du modele — celui du randonneur a qui il manque juste
      // de quoi finir.
      //
      // ELLE EXIGE LA FORME PLURIEL DE L OUTIL, pas une chaine. Chaque langue
      // a sa regle (le francais met « 0 etape » au singulier, l anglais dit
      // « 0 steps ») et slang la tient depuis la table CLDR ; une
      // concatenation a la main ne le peut pas. La garde refuse donc une
      // valeur qui serait redevenue une simple chaine.
      final List<String> trouvailles = <String>[];
      for (final String langue in langues) {
        final Map<String, dynamic> bloc =
            (jsonDecode(
                      File('assets/i18n/$langue.i18n.json').readAsStringSync(),
                    )
                    as Map<String, dynamic>)['monetization']
                as Map<String, dynamic>;
        for (final String cle in clesComptantDesEtapes) {
          final Object? valeur = bloc['$cle(plural)'];
          if (valeur is! Map<String, dynamic>) {
            trouvailles.add(
              '$langue : $cle n est pas declaree en (plural) — '
              'un nombre colle a un mot invariable dira « 1 etapes »',
            );
            continue;
          }
          final Object? singulier = valeur['one'];
          final Object? pluriel = valeur['other'];
          if (singulier is! String || pluriel is! String) {
            trouvailles.add('$langue : $cle manque sa forme one ou other');
            continue;
          }
          if (singulier == pluriel) {
            trouvailles.add(
              '$langue : $cle a le MEME texte au singulier et au pluriel '
              '[$singulier] — la forme plurielle a ete recopiee',
            );
          }
          for (final String forme in <String>[singulier, pluriel]) {
            if (forme.contains(euro)) {
              trouvailles.add('$langue : $cle [$forme] porte un symbole euro');
            }
            if (!forme.contains(r'$n')) {
              trouvailles.add('$langue : $cle [$forme] ne compte pas');
            }
          }
        }
      }
      expect(
        trouvailles,
        isEmpty,
        reason:
            'Les libelles qui comptent des etapes annoncent des ETAPES, au '
            'bon nombre, dans les cinq langues :\n${trouvailles.join('\n')}',
      );
    });

    test('la vitrine ne vend plus un « premium » qui n existe pas', () {
      // CE QUE LE TEXTE DISAIT, et il contredisait le modele de Christophe :
      // « Le mode gratuit permet de preparer ta randonnee avec publicite. Le
      // premium debloque tout, sans pub. » IL N Y A PAS DE PREMIUM. Il y a la
      // cagnotte, les packs et l abonnement — et c est en ETAPES que l on
      // paye. Vendre une offre qui n existe pas est pire qu un mot mal
      // choisi : le randonneur cherche un bouton qu il ne trouvera jamais.
      //
      // `premium` RESTE UN NOM DE CODE INTERNE (`hasPremium`,
      // `getPremiumFeatures`) et ce n est pas vise ici : la garde ne regarde
      // que ce que le randonneur LIT.
      final List<String> trouvailles = <String>[];
      for (final String langue in langues) {
        final List<String> lignes = File(
          'assets/i18n/$langue.i18n.json',
        ).readAsLinesSync();
        for (int i = 0; i < lignes.length; i++) {
          if (lignes[i].toLowerCase().contains('premium')) {
            trouvailles.add('$langue.i18n.json:${i + 1} | ${lignes[i].trim()}');
          }
        }
      }
      expect(
        trouvailles,
        isEmpty,
        reason:
            'Aucun texte lu par le randonneur ne nomme une offre « premium » : '
            'le modele est cagnotte, packs et abonnement.\n'
            '${trouvailles.join('\n')}',
      );
    });

    test('aucun symbole euro dans les cinq fichiers de traduction', () {
      // LE SYMBOLE APPARTIENT AU FORMATEUR, qui le place du bon cote et avec
      // l espace INSECABLE que les traductions n avaient pas. Tant qu il
      // vivait dans les cinq fichiers, sa place pouvait diverger du separateur
      // decimal — et elle divergeait.
      final List<String> trouvailles = <String>[];
      for (final String langue in langues) {
        final List<String> lignes = File(
          'assets/i18n/$langue.i18n.json',
        ).readAsLinesSync();
        for (int i = 0; i < lignes.length; i++) {
          if (lignes[i].contains(euro)) {
            trouvailles.add('$langue.i18n.json:${i + 1} | ${lignes[i].trim()}');
          }
        }
      }
      expect(
        trouvailles,
        isEmpty,
        reason:
            'Le symbole monetaire est pose par `montantEnEuros`, pas recopie '
            'dans les traductions :\n${trouvailles.join('\n')}',
      );
    });

    test('le prix en euros d un SENTIER n existe plus nulle part', () {
      // `eurPriceForTrail` etait le « point d entree unique du prix affiche ».
      // C est elle qui mettait 6,93 EUR sur une carte. Elle a ete retiree ; ce
      // test refuse qu une main la reecrive, sous ce nom ou un autre.
      final List<String> trouvailles = <String>[];
      for (final String racine in <String>['lib', 'test', 'tool']) {
        if (!Directory(racine).existsSync()) continue;
        for (final File fichier in _fichiersDart(racine)) {
          final String chemin = _chemin(fichier);
          if (chemin.endsWith('un_sentier_se_paye_en_etapes_806_test.dart')) {
            continue;
          }
          if (_codeSeul(
            fichier.readAsStringSync(),
          ).contains('eurPriceForTrail')) {
            trouvailles.add(chemin);
          }
        }
      }
      expect(
        trouvailles,
        isEmpty,
        reason:
            'Un sentier n a pas de prix en euros : il a un prix en ETAPES '
            '(`stagesOfTrail`). Fichiers fautifs :\n'
            '${trouvailles.join('\n')}',
      );
    });

    test('un seul fichier de lib ecrit le symbole euro', () {
      final List<String> trouvailles = <String>[];
      for (final File fichier in _fichiersDart('lib')) {
        final String chemin = _chemin(fichier);
        if (_estTraductionEngendree(chemin)) continue;
        if (chemin.endsWith(formateurUnique)) continue;
        if (chemin.endsWith(exceptionToStringDeDebug)) continue;
        if (_codeSeul(fichier.readAsStringSync()).contains(euro)) {
          trouvailles.add(chemin);
        }
      }
      expect(
        trouvailles,
        isEmpty,
        reason:
            'L argent s ecrit a UN seul endroit, `montantEnEuros`, qui prend '
            'le montant et la LANGUE. Trois ecritures differentes cohabitaient '
            'avant la tache 806, et aucune ne regardait la langue active. '
            'Fichiers fautifs :\n${trouvailles.join('\n')}',
      );
    });

    test('aucun separateur decimal remplace a la main au comptoir', () {
      // `toStringAsFixed(2).replaceAll('.', ',')` imposait la virgule
      // FRANCAISE a tout le monde : juste pour quatre langues sur cinq, faux
      // pour l anglais, et faux d avance pour toute langue qu on ajouterait.
      final List<String> trouvailles = <String>[];
      for (final File fichier in _fichiersDart('lib/features/monetization')) {
        final String source = _codeSeul(fichier.readAsStringSync());
        if (source.contains("replaceAll('.', ',')") ||
            source.contains('replaceAll(".", ",")')) {
          trouvailles.add(_chemin(fichier));
        }
      }
      expect(
        trouvailles,
        isEmpty,
        reason:
            'Le separateur decimal se LIT dans la langue, il ne se remplace '
            'pas a la main :\n${trouvailles.join('\n')}',
      );
    });
  });
}
