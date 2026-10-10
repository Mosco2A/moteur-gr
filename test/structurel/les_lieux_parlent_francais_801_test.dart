/// LA GARDE QUI REFUSE UN TEXTE DE LIEU ECRIT SANS SES ACCENTS (tache 801).
///
/// CE QU ELLE FERME. La fiche du point d eau « Funtana di Croce » s affichait,
/// mot pour mot : « Source d eau potable le long du sentier entre Cozzano et
/// Guitera. Debit regulier. » Trois manques dans une phrase de douze mots :
/// l apostrophe de « d'eau », l accent de « Débit », celui de « régulier ». Et
/// ce n etait pas une fiche malheureuse : 171 des 337 textes affiches du
/// sentier etaient dans cet etat.
///
/// LA CAUSE, ET ELLE N EST PAS CELLE QU ON CROIT. Aucun outil du depot ne
/// translittere. Les scripts de publication ecrivent tous `ensure_ascii=False`,
/// et le seul repli de diacritiques du code (`tri_alphabetique_localise.dart`)
/// sert a TRIER, jamais a afficher. La preuve que la saisie etait editoriale
/// est dans le fichier lui-meme : le champ `source` de `pois.json` porte seize
/// guillemets « » et cinq apostrophes — des caracteres non-ASCII — pendant que
/// les champs AFFICHES voisins n en ont aucun. Un filtre aurait tout aplati, y
/// compris la source. Ce qui a ete tape sans accents, c est ce qui se voit.
///
/// ---------------------------------------------------------------------------
/// QUATRE REGLES DE LANGUE, AUCUN DICTIONNAIRE DE CAS PARTICULIERS
/// ---------------------------------------------------------------------------
///
/// Une liste de mots interdits aurait ferme les 171 cas d hier et rien de
/// demain. Chacune des regles ci-dessous est une regle de francais ou une
/// mesure sur le depot : elles valent donc pour des mots que personne n a
/// encore ecrits.
///
/// REGLE A — UNE LETTRE SEULE N EST PAS UN MOT FRANCAIS. `d`, `l`, `c`, `j`,
/// `n`, `s`, `t` et `qu` ne s ecrivent jamais seuls : devant une voyelle ou un
/// h, ce sont des elisions, et une elision porte une apostrophe. « d eau »,
/// « l Antiquite », « jusqu a » tombent sans qu aucun de ces mots figure dans
/// une liste. Trois lettres en sont exclues, chacune pour une raison : `a` et
/// `y` SONT des mots francais, et `m` est le symbole du metre — « 757 m entre
/// les deux cols » n est pas une elision ratee.
///
/// REGLE B — `a` ISOLE EST LA PREPOSITION `à`. Avec deux exceptions nommees et
/// mesurees : le verbe avoir derriere un pronom elide (« n'a », « l'a »), que
/// le motif laisse passer, et les noms propres de [kNomsPropresDuSentier].
///
/// REGLE C — L APPLICATION EST SON PROPRE LEXIQUE. Les textes francais livres
/// (`assets/i18n/fr.i18n.json`) sont relus et accentues : ils forment un
/// vocabulaire que ce fichier n ecrit pas, il le MESURE. Un mot de fiche est
/// refuse quand l application ecrit sa forme accentuee ET n ecrit jamais sa
/// forme nue. Cette seconde condition est ce qui rend la regle utilisable :
/// « ou » et « où », « sur » et « sûr », « la » et « là » existent TOUS LES
/// DEUX en francais, l application ecrit les deux, et la regle se tait. Alors
/// que « étape » s ecrit toujours avec son accent : « etape » est donc faux a
/// coup sur. Le lexique grandit a chaque traduction ajoutee, sans entretien.
///
/// REGLE D — LA FINALE QUE LE FRANCAIS N ECRIT JAMAIS NUE. Un mot francais ne
/// se termine pas par `-ee` ni `-ees` sans accent : c est toujours `-ée` ou
/// `-ées`. « traversee », « relevee », « degagee », « equipee », « vallee »
/// tombent par cette seule regle d orthographe, meme quand le lexique de la
/// regle C ne les connait pas. Elle ne touche aucun nom corse du sentier : ni
/// Catastaghju, ni Funtana di Croce, ni Bocca di Lera, ni Scanciatella ne
/// finissent ainsi.
///
/// CE QUE CES QUATRE REGLES N ATTRAPENT PAS, ET POURQUOI CA SUFFIT. Prises
/// mot a mot, elles laissent passer « regulier » ou « espece » : ces mots-la
/// ne sont ni dans le lexique livre ni en `-ee`. Mais la garde juge un TEXTE,
/// pas un mot — et un texte tape sans accents en contient toujours au moins un
/// qui tombe. Mesure sur le temoin : 100 des 202 textes d avant ce lot sont
/// refuses, dont les 20 fiches de la carte et les 7 etapes, SANS EXCEPTION. Le
/// filet n est pas parfait sur le mot ; il est complet sur la fiche.
///
/// ---------------------------------------------------------------------------
/// CE QUE LA GARDE NE MESURE PAS, ET POURQUOI
/// ---------------------------------------------------------------------------
///
/// LE CHAMP `source` EST HORS PORTEE, ET C EST VOLONTAIRE. Il cite des valeurs
/// OpenStreetMap litterales — « Gite d'etape de Catastaghju » est le nom tel
/// qu OSM le porte, pas une phrase de l application. Lui ajouter des accents
/// serait pretendre qu OSM ecrit autre chose : on ne retouche pas une citation.
/// C est aussi pourquoi la correction du lot 801 ne l a pas touche.
///
/// LES NOMS CORSES ET ITALIENS NE SONT PAS DU FRANCAIS. « Mare a Mare » est le
/// nom du sentier, pas une preposition mal ecrite ; [kNomsPropresDuSentier] les
/// nomme un par un, avec leur raison. Une liste nommee se lit dans un diff ; un
/// seuil permissif, non. Et un test refuse d y laisser une entree morte.
///
/// LE TEMOIN, SANS QUOI LA GARDE N AFFIRMERAIT RIEN. Les trois fichiers
/// d avant ce lot sont conserves dans `test/fixtures/lieux/*_avant_801.json` et
/// le dernier test prouve qu ils ROUGISSENT, et de combien. Sans ce temoin, les
/// regles pourraient etre relachees jusqu a ce que plus rien ne les franchisse.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Les fichiers de donnees dont les textes s affichent dans l application.
const List<String> kFichiersDeLieux = <String>[
  'assets/data/mare_a_mare_centre/pois.json',
  'assets/data/mare_a_mare_centre/stages.json',
  'assets/data/mare_a_mare_centre.json',
  'publication/sources/mare-a-mare-centre/sentier.json',
  'publication/contenu/mare-a-mare-centre.json',
];

/// Les champs AFFICHES en francais.
///
/// `source` en est absent : il cite OpenStreetMap mot pour mot (cf. en-tete).
final RegExp kChampsAffichesFr = RegExp(
  r'^(name_?[Ff]r|description_?[Ff]r|address|nameFr|descriptionFr'
  r'|departureName|arrivalName|name|displayName|tagline)$',
);

/// REGLE A — les lettres qui s elident, et celles qui n en sont pas.
///
/// `a` et `y` sont des mots a eux seuls ; `m` est le symbole du metre. Les
/// formes longues (`jusqu`, `lorsqu`, `puisqu`, `quoiqu`) s elident comme `qu`,
/// et `Sant` fait de meme en corse (Sant'Antonu).
final RegExp kElisionRatee = RegExp(
  r"(?<![A-Za-zÀ-ÿ'])"
  r'([Jj]usqu|[Ll]orsqu|[Pp]uisqu|[Qq]uoiqu|Sant|[Qq]u|[dlcjnstDLCJNST])'
  r'\s+(?=[aeiouyhAEIOUYHéèêàâîôûÉÈÊÀÂÎÔÛ])',
);

/// REGLE B — un `a` isole, hors verbe avoir derriere un pronom elide.
final RegExp kAIsole = RegExp(
  r"(?<![A-Za-zÀ-ÿ])(?<![nmtsljNMTSLJ]')a(?![A-Za-zÀ-ÿ])",
);

/// REGLE D — la finale que le francais n ecrit jamais sans accent.
final RegExp kFinaleSansAccent = RegExp(
  r'(?<![A-Za-zÀ-ÿ])[A-Za-z]*[bcdfgjklmnpqrstvwxz]ees?(?![A-Za-zÀ-ÿ])',
);

/// Un mot, au sens du francais ecrit.
final RegExp kMot = RegExp(r'[A-Za-zÀ-ÿœŒ]+');

/// LES NOMS PROPRES QUI NE SONT PAS DU FRANCAIS, chacun avec sa raison.
///
/// Ils traversent les regles sans etre mesures parce qu ils n obeissent pas a
/// l orthographe francaise. La liste est NOMMEE, donc relisible dans un diff.
const Map<String, String> kNomsPropresDuSentier = <String, String>{
  'Mare a Mare':
      'LE NOM DU SENTIER, en corse « de mer a mer ». Son `a` n est pas la '
      'preposition francaise `à` : c est le nom officiel du reseau de '
      'sentiers du Parc naturel regional de Corse.',
  'A Vuterra':
      'LE NOM CORSE DU VILLAGE DE GUITERA, tel que la ligne d autocar C6 le '
      'dessert. L article corse `A` ne s accentue pas.',
  'u Cataru':
      'LE NOM CORSE DU COL (OSM node 9537582199, natural=saddle, ele=779). '
      'L article corse `u` n est pas une lettre elidee.',
  'Bocca di u Grecu':
      'NOM CORSE DE COL (469 m, etape 7) : `u` y est l article, pas une '
      'lettre elidee.',
  'Dolc Elina':
      'RAISON SOCIALE DE LA BOULANGERIE DE GHISONACCIA, relevee telle quelle. '
      'Aucune source publique ne dit si elle porte une apostrophe : on ne '
      'devine pas le nom d un commerce.',
};

/// Unites et abreviations : ni accents ni lexique ne les concernent.
const Set<String> kMotsHorsLexique = <String>{
  'm',
  'km',
  'h',
  'er',
  'eur',
  'cs',
};

/// Depouille un mot de ses accents, pour comparer les deux graphies.
String sansAccents(String mot) {
  const Map<String, String> replis = <String, String>{
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'á': 'a',
    'å': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'í': 'i',
    'ô': 'o',
    'ö': 'o',
    'ó': 'o',
    'û': 'u',
    'ü': 'u',
    'ù': 'u',
    'ú': 'u',
    'ç': 'c',
    'ñ': 'n',
    'œ': 'oe',
    'æ': 'ae',
    'ÿ': 'y',
    'À': 'A',
    'Â': 'A',
    'Ä': 'A',
    'Á': 'A',
    'Å': 'A',
    'É': 'E',
    'È': 'E',
    'Ê': 'E',
    'Ë': 'E',
    'Î': 'I',
    'Ï': 'I',
    'Í': 'I',
    'Ô': 'O',
    'Ö': 'O',
    'Ó': 'O',
    'Û': 'U',
    'Ü': 'U',
    'Ù': 'U',
    'Ú': 'U',
    'Ç': 'C',
    'Ñ': 'N',
    'Œ': 'OE',
    'Æ': 'AE',
  };
  final tampon = StringBuffer();
  for (final c in mot.split('')) {
    tampon.write(replis[c] ?? c);
  }
  return tampon.toString();
}

/// LE LEXIQUE DE L APPLICATION (regle C) : mesure, pas liste.
///
/// Deux ensembles tires des memes textes livres : les mots que l application
/// ecrit AVEC accents, et ceux qu elle ecrit SANS. Un mot nu n est fautif que
/// s il appartient au premier et jamais au second — sans quoi « ou » serait
/// refuse au nom de « où ».
class LexiqueFrancais {
  LexiqueFrancais(this.accentues, this.nus);

  /// Forme depouillee et minuscule -> la forme accentuee rencontree.
  final Map<String, String> accentues;

  /// Les mots que l application ecrit SANS accent : graphies legitimes.
  final Set<String> nus;

  /// Lit les textes francais livres a l utilisateur.
  factory LexiqueFrancais.duDepot() {
    final fichier = File('assets/i18n/fr.i18n.json');
    final accentues = <String, String>{};
    final nus = <String>{};
    if (!fichier.existsSync()) return LexiqueFrancais(accentues, nus);

    void marche(Object? o) {
      if (o is Map) {
        o.forEach((_, v) => marche(v));
      } else if (o is List) {
        for (final v in o) {
          marche(v);
        }
      } else if (o is String) {
        for (final m in kMot.allMatches(o)) {
          final mot = m.group(0)!.toLowerCase();
          final nu = sansAccents(mot);
          if (nu != mot) {
            accentues[nu] = mot;
          } else {
            nus.add(mot);
          }
        }
      }
    }

    marche(jsonDecode(fichier.readAsStringSync()));
    return LexiqueFrancais(accentues, nus);
  }

  /// La forme accentuee attendue pour [mot] nu, ou null s il est legitime.
  String? formeAttendue(String mot) {
    final l = mot.toLowerCase();
    if (kMotsHorsLexique.contains(l)) return null;
    if (nus.contains(l)) return null; // graphie nue attestee : on se tait
    return accentues[l];
  }
}

/// Un texte affiche, avec de quoi dire OU il se trouve quand il rougit.
class TexteDeLieu {
  const TexteDeLieu(this.fichier, this.chemin, this.valeur);

  /// Le fichier de donnees qui le porte.
  final String fichier;

  /// Le chemin de la clef dans ce fichier, pour le retrouver a la main.
  final String chemin;

  /// Le texte lui-meme.
  final String valeur;

  @override
  String toString() => '$fichier $chemin : « $valeur »';
}

/// Recolte tous les textes affiches en francais de [racine].
List<TexteDeLieu> textesAffiches(String fichier, Object? racine) {
  final out = <TexteDeLieu>[];
  void marche(Object? o, String chemin) {
    if (o is Map) {
      o.forEach((clef, valeur) {
        final sous = '$chemin/$clef';
        if (valeur is String && kChampsAffichesFr.hasMatch('$clef')) {
          out.add(TexteDeLieu(fichier, sous, valeur));
        } else {
          marche(valeur, sous);
        }
      });
    } else if (o is List) {
      for (var i = 0; i < o.length; i++) {
        marche(o[i], '$chemin/$i');
      }
    }
  }

  marche(racine, '');
  return out;
}

/// Retire d un texte les noms propres nommes : on ne mesure que du francais.
String sansNomsPropres(String texte) {
  var t = texte;
  for (final nom in kNomsPropresDuSentier.keys) {
    t = t.replaceAll(nom, ' ');
  }
  return t;
}

/// Les reproches qu un texte merite, vides s il est juste.
List<String> reproches(String texte, LexiqueFrancais lexique) {
  final out = <String>[];
  final propre = sansNomsPropres(texte);

  for (final m in kElisionRatee.allMatches(propre)) {
    out.add('elision sans apostrophe : « ${m.group(1)} »');
  }
  if (kAIsole.hasMatch(propre)) {
    out.add('« a » isole : la preposition francaise s ecrit « à »');
  }
  for (final m in kFinaleSansAccent.allMatches(propre)) {
    out.add('finale -ee sans accent : « ${m.group(0)} »');
  }
  for (final m in kMot.allMatches(propre)) {
    final mot = m.group(0)!;
    if (mot != sansAccents(mot)) continue; // deja accentue
    final attendue = lexique.formeAttendue(mot);
    if (attendue != null) {
      out.add('mot sans accent : « $mot » (l application ecrit « $attendue »)');
    }
  }
  return out;
}

void main() {
  final lexique = LexiqueFrancais.duDepot();

  group('LES LIEUX PARLENT FRANCAIS (801)', () {
    test('le lexique de l application est mesure, pas suppose', () {
      // Sans lexique, la regle C serait muette et la garde mentirait.
      expect(
        lexique.accentues.length,
        greaterThan(300),
        reason:
            'Le lexique vient de assets/i18n/fr.i18n.json. S il est vide ou '
            'maigre, la regle C ne garde rien.',
      );
      expect(lexique.accentues['etape'], 'étape');
      expect(lexique.accentues['debit'], 'débit');
      // Et la condition qui evite les faux proces : « ou » s ecrit aussi nu.
      expect(lexique.nus, contains('ou'));
      expect(lexique.formeAttendue('ou'), isNull);
      expect(lexique.formeAttendue('etape'), 'étape');
    });

    for (final fichier in kFichiersDeLieux) {
      test('$fichier : chaque texte affiche porte ses accents', () {
        final f = File(fichier);
        expect(f.existsSync(), isTrue, reason: '$fichier introuvable');
        final textes = textesAffiches(
          fichier,
          jsonDecode(f.readAsStringSync()),
        );
        expect(
          textes,
          isNotEmpty,
          reason:
              '$fichier ne livre aucun texte affiche : la garde serait verte '
              'parce qu elle ne mesure rien.',
        );

        final fautes = <String>[];
        for (final t in textes) {
          final r = reproches(t.valeur, lexique);
          if (r.isNotEmpty) fautes.add('$t\n      -> ${r.join(' ; ')}');
        }
        expect(
          fautes,
          isEmpty,
          reason:
              'Textes francais prives d accents ou d apostrophes '
              '(${fautes.length}) :\n   ${fautes.join('\n   ')}',
        );
      });
    }

    test('la liste des noms propres ne contient aucune entree morte', () {
      // Un nom dispense qui n apparait plus nulle part est une ligne que
      // personne ne relira : la garde le dit plutot que de la garder.
      final corpus = StringBuffer();
      for (final fichier in kFichiersDeLieux) {
        final f = File(fichier);
        if (!f.existsSync()) continue;
        for (final t in textesAffiches(
          fichier,
          jsonDecode(f.readAsStringSync()),
        )) {
          corpus.writeln(t.valeur);
        }
      }
      final tout = corpus.toString();
      final mortes = kNomsPropresDuSentier.keys
          .where((n) => !tout.contains(n))
          .toList();
      expect(
        mortes,
        isEmpty,
        reason: 'Noms propres dispenses qui n apparaissent plus : $mortes',
      );
    });

    // ----------------------------------------------------------------------
    // LE TEMOIN : ces regles ROUGISSAIENT sur les donnees d avant le lot 801.
    // ----------------------------------------------------------------------
    test('les donnees d avant le lot 801 sont REFUSEES par ces regles', () {
      // fichier temoin -> nombre minimal de textes fautifs attendus.
      const temoins = <String, int>{
        'test/fixtures/lieux/pois_mare_a_mare_centre_avant_801.json': 20,
        'test/fixtures/lieux/stages_mare_a_mare_centre_avant_801.json': 7,
        'test/fixtures/lieux/sentier_mare_a_mare_centre_avant_801.json': 70,
      };
      temoins.forEach((chemin, minimum) {
        final f = File(chemin);
        expect(f.existsSync(), isTrue, reason: '$chemin introuvable');
        final textes = textesAffiches(chemin, jsonDecode(f.readAsStringSync()));
        final fautifs = textes
            .where((t) => reproches(t.valeur, lexique).isNotEmpty)
            .length;
        expect(
          fautifs,
          greaterThanOrEqualTo(minimum),
          reason:
              'Le temoin $chemin devait rougir sur au moins $minimum textes '
              'et n en a donne que $fautifs : les regles sont devenues trop '
              'laches, ou le temoin a ete reecrit.',
        );
      });
    });

    test('la fiche que Christophe a vue est le cas de reference', () {
      // « Source d eau potable ... Debit regulier. » — le texte exact de la
      // capture. Il doit rougir AVANT et se taire APRES : sans ce couple, on
      // ne saurait pas que la garde vise bien ce defaut-la.
      const avant =
          'Source d eau potable le long du sentier entre Cozzano et '
          'Guitera. Debit regulier.';
      const apres =
          "Source d'eau potable le long du sentier entre Cozzano et "
          'Guitera. Débit régulier.';
      expect(reproches(avant, lexique), isNotEmpty);
      expect(reproches(apres, lexique), isEmpty);
    });
  });
}
