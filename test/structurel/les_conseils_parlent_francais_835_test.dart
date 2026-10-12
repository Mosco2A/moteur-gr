/// LES FICHES CONSEILS PARLENT FRANCAIS (tache 835, lot A1).
///
/// LE DEFAUT QUE CETTE GARDE FERME. Sur le meme ecran, le randonneur lisait
/// « Preparation, materiel, securite, sante » en titre — un libelle
/// d'interface, correctement accentue parce qu'il vient de
/// `assets/i18n/fr.i18n.json` — puis « Chaussures rodees avant le depart »
/// juste dessous, parce que celui-la vient d'un fichier de DONNEES tape a la
/// main sans accents. Mesure du 12/10 avant
/// correctif : 214 chaines francaises, ZERO accent, dans les cinq fichiers de
/// [kFichiersDeConseils]. Les apostrophes manquaient avec les accents
/// (« jusqu a », « N attends pas », « D ou la formule »).
///
/// POURQUOI UNE SECONDE GARDE ET PAS UN AJOUT A CELLE DU LOT 801. La garde
/// `les_lieux_parlent_francais_801_test.dart` ne pouvait pas voir ce defaut,
/// pour DEUX raisons independantes : ses cinq fichiers sont les donnees de
/// LIEUX du Mare a Mare, et ses clefs attendues (`name_fr`, `description_fr`,
/// `address`…) ne couvrent AUCUN des champs employes ici (`titleFr`,
/// `pointsFr`, `contentFr`, `subtitleFr`, `labelFr`).
///
/// ET POURQUOI SON JUGE N'A PAS ETE REPRIS TEL QUEL — C'EST LE POINT DELICAT
/// DE CE FICHIER, ET IL A ETE MESURE, PAS SUPPOSE. Branchee d'abord sur
/// `reproches()` du lot 801, cette garde a rendu ONZE REPROCHES SUR DU TEXTE
/// JUSTE. Deux de ses regles ne survivent pas au changement de corpus :
///
///   — SA REGLE B (« un `a` isole est la preposition `à` ») suppose un corpus
///     de noms de lieux. Les fiches conseils sont de la PROSE, donc elles
///     emploient le VERBE avoir : « il n'y a pas de refuge », « le PGHM a sa
///     base principale a Ajaccio », « dès qu'il y a du vent », « une étude
///     d'Innsbruck a mesuré ». La regle n'excepte que `n'a` et `l'a` : elle ne
///     sait pas voir « y a » ni « Nom + a + participe ». Cinq faux proces.
///
///   — SON LEXIQUE (regle C) refuse un mot nu quand l'application ecrit sa
///     forme accentuee et jamais sa forme nue. Sur de la prose a l'imperatif et
///     au present, cela condamne des mots JUSTES : « arrive » (« arrive avant
///     18 heures ») parce que `fr.i18n.json` ecrit « arrivé » ; de meme « tu
///     marches », « le corps s'adapte », « l'étape cumule ». Six faux proces.
///     Et le lexique est muet la ou on l'attendait : il ne dit RIEN de
///     « reguliere », donc il aurait laisse passer tout
///     `assets/data/training_plans.json`.
///
/// CE QUI EST DONC REPRIS, ET C'EST LA PART QUI NE SE TROMPE PAS : les regles
/// A (elision sans apostrophe) et D (finale `-ee` sans accent), verifiees sans
/// AUCUN faux positif sur les 246 textes de ce corpus. A quoi s'ajoutent deux
/// regles ecrites pour CE defaut-ci :
///
///   — UN DICTIONNAIRE DE MOTS DONT LA FORME NUE N'EST PAS UN MOT FRANCAIS
///     (« etape », « depart », « reguliere », « velo »…). Aucune ambiguite
///     possible : contrairement a « arrive » ou « cote », ces graphies
///     n'existent pas. La liste est NOMMEE, donc relisible dans un diff.
///
///   — UN PLANCHER DE DENSITE PAR FICHIER. C'est la regle qui attrape le
///     defaut POUR CE QU'IL EST : non pas une faute ici ou la, mais un fichier
///     entier tape en ASCII. Elle est posee au FICHIER et jamais a la chaine,
///     parce que le francais ecrit legitimement de longues phrases sans aucun
///     diacritique — ce corpus en contient quatre, dont « Dis bonjour dans la
///     langue du lieu. Trois mots appris valent mieux qu'une phrase parfaite en
///     anglais. » Une regle a la chaine les condamnerait a tort.
///
/// CE QUE CETTE GARDE NE JUGE PAS, ET POURQUOI.
///
/// — LES AUTRES LANGUES. Les champs `De`/`It`/`Es` portent le MEME defaut
///   (l'allemand est translittere : « Fluessigkeitszufuhr » pour
///   « Flüssigkeitszufuhr », « franzoesischer » pour « französischer »), et
///   l'anglais n'a legitimement aucun diacritique. Les juger demanderait un
///   lexique par langue que le depot n'a pas, et ces regles-ci sont
///   FRANCAISES. Trois langues restent a reparer ; le compte est au compte
///   rendu de la tache 835 pour qu'il ne se perde pas.
///
/// — LES CHAMPS TECHNIQUES. `tags`, `id`, `scope`, `season`, `category` et
///   `theme` sont des clefs machine : elles FILTRENT les fiches. Un
///   `tags: ["prefecture"]` devenu `["préfecture"]` casserait le filtre en
///   silence. Un test exige donc l'inverse du reste du fichier : qu'ils
///   restent en ASCII.
///
/// — TROIS FICHIERS DE DONNEES MORTS. `assets/data/sample_trail.json`,
///   `test_pois.json` et `test_stages.json` sont embarques (le pubspec declare
///   `assets/data/` en entier) et portent du francais sans accents (53
///   chaines), mais AUCUN code de `lib/` ne les charge : verifie par balayage
///   le 12/10. Les accentuer serait soigner un texte que personne ne lit ; la
///   vraie question est leur presence dans le binaire, et elle n'appartient pas
///   a ce lot.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'les_lieux_parlent_francais_801_test.dart'
    show TexteDeLieu, kElisionRatee, kFinaleSansAccent, kMot, sansAccents;

/// Les fiches conseils livrees avec l'application, toutes declarees au pubspec.
const List<String> kFichiersDeConseils = <String>[
  'assets/tips/general_tips.json',
  'assets/tips/mare_a_mare_tips.json',
  'assets/tips/securite_incendie.json',
  'assets/tips/securite_neige.json',
  'assets/data/training_plans.json',
];

/// Les champs AFFICHES en francais dans les fiches conseils.
///
/// La convention du depot est le suffixe de langue : `titleFr` a pour voisins
/// `titleEn`, `titleDe`, `titleIt`, `titleEs`. On ne retient que `Fr`.
final RegExp kChampsConseilsFr = RegExp(
  r'^(titleFr|pointsFr|contentFr|subtitleFr|labelFr)$',
);

/// Les champs qui sont des CLEFS MACHINE et doivent rester en ASCII.
final RegExp kChampsTechniques = RegExp(
  r'^(id|scope|season|category|theme|tags|icon|nameKey|requirement)$',
);

/// Tout caractere hors ASCII imprimable.
final RegExp kHorsAscii = RegExp(r'[^\x20-\x7E]');

/// Un diacritique francais, ligature comprise.
final RegExp kDiacritique = RegExp(r'[À-ÿœŒ]');

/// MOTS DONT LA FORME NUE N'EST PAS UN MOT FRANCAIS.
///
/// Chacun a ete choisi parce que sa graphie sans accent N'EXISTE PAS. C'est ce
/// qui les distingue de « arrive », « cote », « tache », « mur » ou « du », qui
/// sont des mots a part entiere et que cette garde ne doit donc jamais
/// condamner. Valeur = la forme attendue, pour que le message dise quoi ecrire.
const Map<String, String> kFormesNuesFautives = <String, String>{
  'etape': 'étape',
  'etapes': 'étapes',
  'depart': 'départ',
  'securite': 'sécurité',
  'materiel': 'matériel',
  'journee': 'journée',
  'journees': 'journées',
  'randonnee': 'randonnée',
  'randonnees': 'randonnées',
  'reguliere': 'régulière',
  'regulier': 'régulier',
  'regional': 'régional',
  'velo': 'vélo',
  'denivele': 'dénivelé',
  'metres': 'mètres',
  'metre': 'mètre',
  'temperature': 'température',
  'temperatures': 'températures',
  'numero': 'numéro',
  'numeros': 'numéros',
  'europeen': 'européen',
  'europeenne': 'européenne',
  'europeennes': 'européennes',
  'prefecture': 'préfecture',
  'prefectoral': 'préfectoral',
  'operateur': 'opérateur',
  'gite': 'gîte',
  'gites': 'gîtes',
  'epicerie': 'épicerie',
  'hebergement': 'hébergement',
  'rechaud': 'réchaud',
  'rechauds': 'réchauds',
  'especes': 'espèces',
  'espece': 'espèce',
  'deshydratation': 'déshydratation',
  'systeme': 'système',
  'etirements': 'étirements',
  'recuperation': 'récupération',
  'preparation': 'préparation',
  'hygiene': 'hygiène',
  'reseau': 'réseau',
  'echappatoire': 'échappatoire',
  'echappatoires': 'échappatoires',
  'interieur': 'intérieur',
  'exterieur': 'extérieur',
  'tres': 'très',
  'meme': 'même',
  'etre': 'être',
  'foret': 'forêt',
  'forets': 'forêts',
  'crete': 'crête',
  'cretes': 'crêtes',
  'aout': 'août',
  'difficulte': 'difficulté',
  'proteines': 'protéines',
  'electrolytes': 'électrolytes',
  'categorie': 'catégorie',
  'impermeabilite': 'imperméabilité',
  'synthetique': 'synthétique',
  'merinos': 'mérinos',
  'itineraire': 'itinéraire',
  'itinerance': 'itinérance',
  'telephone': 'téléphone',
  'extreme': 'extrême',
  'affutage': 'affûtage',
  'periode': 'période',
  'vallonne': 'vallonné',
  'detresse': 'détresse',
  'secheresse': 'sécheresse',
  'vetements': 'vêtements',
  'pietinement': 'piétinement',
  'decennies': 'décennies',
  'energie': 'énergie',
  'eclair': 'éclair',
};

/// PIEGE EVITE, ET IL A ETE RENCONTRE. Un dictionnaire de ce genre attire les
/// mots qui n'ont PAS d'accent : la premiere version listait « orage » et
/// « enneigement » avec eux-memes en forme attendue, ce qui condamnait du texte
/// juste en lui demandant de s'ecrire exactement comme il etait deja ecrit. Le
/// test ci-dessous interdit a cette liste de contenir une entree dont la forme
/// attendue n'ajoute aucun diacritique.

/// Le compte de chaines francaises MESURE le 12/10, fichier par fichier.
///
/// Canari : si quelqu'un vide un fichier ou renomme ses champs, le test tombe
/// au lieu de passer en silence sur zero texte.
const Map<String, int> kChainesFrancaisesAttendues = <String, int>{
  'assets/tips/general_tips.json': 156,
  'assets/tips/mare_a_mare_tips.json': 42,
  'assets/tips/securite_incendie.json': 8,
  'assets/tips/securite_neige.json': 8,
  'assets/data/training_plans.json': 32,
};

/// LE PLANCHER DE DENSITE. Part minimale des textes francais d'un fichier qui
/// doivent porter au moins un diacritique.
///
/// Mesure du 12/10 APRES correctif : general 139/156 (89 %), mare_a_mare 36/42
/// (86 %), incendie 7/8, neige 6/8 (75 %), training 26/32 (81 %). Le plancher
/// est pose a 60 % : assez bas pour qu'une redaction legitime ne le franchisse
/// pas, assez haut pour qu'un fichier re-aplati en ASCII (0 %) tombe aussitot.
const double kPlancherDeDensite = 0.60;

/// Recolte les textes francais d'un fichier de conseils.
///
/// Un champ retenu porte soit une chaine (`titleFr`), soit une LISTE de chaines
/// (`pointsFr`) : les deux formes existent dans le depot, les deux comptent.
List<TexteDeLieu> textesDeConseils(String fichier, Object? racine) =>
    _recolte(fichier, racine, kChampsConseilsFr);

/// Recolte les valeurs des champs techniques.
List<TexteDeLieu> valeursTechniques(String fichier, Object? racine) =>
    _recolte(fichier, racine, kChampsTechniques);

List<TexteDeLieu> _recolte(String fichier, Object? racine, RegExp clefs) {
  final out = <TexteDeLieu>[];
  void marche(Object? o, String chemin) {
    if (o is Map) {
      o.forEach((clef, valeur) {
        final sous = '$chemin/$clef';
        if (clefs.hasMatch('$clef')) {
          if (valeur is String) {
            out.add(TexteDeLieu(fichier, sous, valeur));
            return;
          }
          if (valeur is List) {
            for (var i = 0; i < valeur.length; i++) {
              final item = valeur[i];
              if (item is String) {
                out.add(TexteDeLieu(fichier, '$sous/$i', item));
              }
            }
            return;
          }
        }
        marche(valeur, sous);
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

/// Les reproches qu'un texte de conseil merite, vides s'il est juste.
///
/// Trois regles, toutes sans faux positif mesure sur ce corpus : l'elision sans
/// apostrophe et la finale `-ee` viennent du lot 801 ; le dictionnaire est
/// propre a ce lot.
List<String> reprochesDeConseil(String texte) {
  final out = <String>[];

  for (final m in kElisionRatee.allMatches(texte)) {
    out.add('elision sans apostrophe : « ${m.group(1)} »');
  }
  for (final m in kFinaleSansAccent.allMatches(texte)) {
    out.add('finale -ee sans accent : « ${m.group(0)} »');
  }
  for (final m in kMot.allMatches(texte)) {
    final mot = m.group(0)!;
    if (mot != sansAccents(mot)) continue; // deja accentue
    final attendue = kFormesNuesFautives[mot.toLowerCase()];
    if (attendue != null) {
      out.add('mot sans accent : « $mot » (il s ecrit « $attendue »)');
    }
  }
  return out;
}

Object? _lire(String chemin) =>
    jsonDecode(File(chemin).readAsStringSync()) as Object?;

void main() {
  group('Les fiches conseils parlent francais (835)', () {
    test('les cinq fichiers existent et se relisent', () {
      for (final chemin in kFichiersDeConseils) {
        expect(
          File(chemin).existsSync(),
          isTrue,
          reason: '$chemin est introuvable',
        );
        expect(
          () => _lire(chemin),
          returnsNormally,
          reason: '$chemin n est pas du JSON valide',
        );
      }
    });

    test('chaque fichier porte le compte de textes francais mesure', () {
      for (final chemin in kFichiersDeConseils) {
        expect(
          textesDeConseils(chemin, _lire(chemin)).length,
          kChainesFrancaisesAttendues[chemin],
          reason:
              'Le nombre de textes francais de $chemin a change. Si c est '
              'voulu (une fiche ajoutee), mets a jour '
              'kChainesFrancaisesAttendues DANS LE MEME COMMIT, sans quoi la '
              'garde devient aveugle.',
        );
      }
    });

    // LE TEST QUI DONNE SON NOM AU LOT.
    test('AUCUN texte de conseil ne merite de reproche de francais', () {
      final fautes = <String>[];
      for (final chemin in kFichiersDeConseils) {
        for (final texte in textesDeConseils(chemin, _lire(chemin))) {
          final r = reprochesDeConseil(texte.valeur);
          if (r.isNotEmpty) fautes.add('$texte -> ${r.join(' | ')}');
        }
      }
      expect(
        fautes,
        isEmpty,
        reason:
            'Des fiches conseils sont ecrites sans accents ou sans '
            'apostrophes :\n${fautes.join('\n')}',
      );
    });

    // LA REGLE QUI ATTRAPE LE DEFAUT POUR CE QU IL EST : un fichier aplati.
    test('chaque fichier garde une densite de diacritiques credible', () {
      for (final chemin in kFichiersDeConseils) {
        final textes = textesDeConseils(chemin, _lire(chemin));
        final avec = textes
            .where((t) => kDiacritique.hasMatch(t.valeur))
            .length;
        final part = avec / textes.length;
        expect(
          part,
          greaterThanOrEqualTo(kPlancherDeDensite),
          reason:
              '$chemin : seulement $avec de ses ${textes.length} textes '
              'francais portent un accent (${(part * 100).round()} %). Un '
              'fichier de prose francaise n a pas cette allure : il a '
              'probablement ete re-tape sans accents.',
        );
      }
    });

    test('le dictionnaire ne contient que de vraies fautes', () {
      final bancales = <String>[];
      kFormesNuesFautives.forEach((nue, attendue) {
        if (!kDiacritique.hasMatch(attendue)) {
          bancales.add('« $nue » -> « $attendue » n ajoute aucun accent');
        } else if (sansAccents(attendue).toLowerCase() != nue) {
          bancales.add(
            '« $nue » -> « $attendue » : depouillee, la forme attendue donne '
            '« ${sansAccents(attendue).toLowerCase()} », pas « $nue »',
          );
        }
      });
      expect(
        bancales,
        isEmpty,
        reason:
            'Une entree du dictionnaire condamnerait du texte juste :\n'
            '${bancales.join('\n')}',
      );
    });

    test('les champs techniques restent en ASCII (ils servent a filtrer)', () {
      final fautes = <String>[];
      for (final chemin in kFichiersDeConseils) {
        for (final v in valeursTechniques(chemin, _lire(chemin))) {
          if (kHorsAscii.hasMatch(v.valeur)) fautes.add('$v');
        }
      }
      expect(
        fautes,
        isEmpty,
        reason:
            'Une clef machine a recu un accent : le filtrage des fiches '
            'tomberait en silence.\n${fautes.join('\n')}',
      );
    });
  });

  // LA GARDE A-T-ELLE DES DENTS ? Prouve sur les textes REELS d'avant le
  // correctif, releves dans le depot, pas sur des exemples inventes.
  group('La garde rougit sur les textes d avant le correctif (835)', () {
    const avant = <String>[
      'Chaussures rodees avant le depart',
      'Periode a haut risque incendie',
      '112 : Urgences europeennes (fonctionne meme sans reseau operateur).',
      "Gites d'etape du Mare a Mare",
      'Cardio et marche reguliere',
      'Cardio 1 h (velo, course ou natation)',
      'Le sentier traverse le Parc naturel regional de Corse : 440 200 '
          'hectares, environ 51 % du territoire de l ile.',
      'Tu perds 0,5 a 1 litre par heure en transpirant, et jusqu a 3 litres '
          'par heure par forte chaleur avec un effort intense (FFRandonnee).',
    ];

    const apres = <String>[
      'Chaussures rodées avant le départ',
      'Période à haut risque incendie',
      '112 : Urgences européennes (fonctionne même sans réseau opérateur).',
      "Gîtes d'étape du Mare a Mare",
      'Cardio et marche régulière',
      'Cardio 1 h (vélo, course ou natation)',
      'Le sentier traverse le Parc naturel régional de Corse : 440 200 '
          "hectares, environ 51 % du territoire de l'île.",
      "Tu perds 0,5 à 1 litre par heure en transpirant, et jusqu'à 3 litres "
          'par heure par forte chaleur avec un effort intense (FFRandonnée).',
    ];

    test('les huit textes d avant sont TOUS refuses', () {
      for (final texte in avant) {
        expect(
          reprochesDeConseil(texte),
          isNotEmpty,
          reason: 'La garde laisse passer « $texte », elle est sans dents',
        );
      }
    });

    test('les huit textes d apres sont TOUS acceptes', () {
      for (final texte in apres) {
        expect(
          reprochesDeConseil(texte),
          isEmpty,
          reason: 'La garde refuse « $texte », qui est pourtant juste',
        );
      }
    });

    // LES FAUX PROCES QUE LA GARDE DU LOT 801 FAISAIT, ET QU ON NE REFAIT PAS.
    // Chacune de ces phrases est JUSTE : le `a` y est le verbe avoir, et
    // « arrive », « marches », « adapte », « cumule » sont des mots francais.
    test('la prose au present et a l imperatif n est PAS condamnee', () {
      const justes = <String>[
        "Sur le Mare a Mare on dort en gîte d'étape et dans les villages : il "
            "n'y a pas de refuge de haute montagne sur ce sentier.",
        'Secours en montagne : le PGHM de Corse a sa base principale à Ajaccio '
            'et un détachement de Haute-Corse basé à Corte.',
        "Arrive avant 18 heures, chaussures à l'entrée, drap-sac ou duvet "
            'selon la maison, silence après 22 heures.',
        'En dévers, raccourcis le bâton amont et rallonge le bâton aval. Tu '
            'marches droit au lieu de te pencher.',
        'Les trois premiers jours, marche à 70 % de ce que tu peux : le corps '
            "s'adapte, il ne se force pas.",
        "L'étape Guitera - Quasquara cumule 1 055 mètres de montée et 860 de "
            "descente : c'est la plus exigeante du parcours.",
        'Dis bonjour dans la langue du lieu. Trois mots appris valent mieux '
            "qu'une phrase parfaite en anglais.",
      ];
      for (final texte in justes) {
        expect(
          reprochesDeConseil(texte),
          isEmpty,
          reason:
              'Faux proces sur « $texte » : c est exactement l erreur que les '
              'regles B et C du lot 801 commettaient sur ce corpus.',
        );
      }
    });

    test(
      'le nom du sentier garde son « a » : Mare a Mare, pas Mare à Mare',
      () {
        // Ce `a` est corse (« de mer a mer »), pas la preposition francaise.
        expect(reprochesDeConseil("Gîtes d'étape du Mare a Mare"), isEmpty);
      },
    );
  });
}
