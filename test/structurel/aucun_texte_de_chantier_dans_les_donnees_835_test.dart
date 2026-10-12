/// AUCUN TEXTE DE CHANTIER DANS LES DONNEES (tache 835, lot A2).
///
/// LE DEFAUT. La fiche de ravitaillement de Ghisonaccia finissait par
/// « Adresses précises : à compléter. » — un aveu d'editeur, dans une phrase
/// destinee au randonneur. Et il n'etait pas seul : la mesure du 12/10 en a
/// trouve HUIT de la meme famille dans le contenu editorial, dont DEUX dans des
/// TITRES (« Santa-Maria-Siché : ravitaillement à compléter »), chacun decline
/// dans les cinq langues.
///
/// POURQUOI LA GARDE QUI EXISTAIT NE POUVAIT PAS LE VOIR. Le depot avait deja
/// `test/structurel/aucune_valeur_a_completer_645_test.dart` (« VAC-01 »), a
/// zero marqueur depuis le 03/10. Mais elle ne balaie que le CODE SOURCE de
/// `lib/`. Le defaut de ce lot est entierement porte par la DONNEE : il etait
/// donc hors de sa portee par construction, pas par negligence. Cette garde-ci
/// balaie les donnees, et les deux se completent sans se recouvrir.
///
/// LE POINT LE PLUS IMPORTANT DE CE FICHIER : LE FILTRE DE L'APPLICATION EST
/// ANCRE, ET C'EST EXACTEMENT PAR LA QUE LA FUITE PASSAIT.
///
/// `LieuCliquable.aUneAdresse` (lib/shared/widgets/maps_link.dart) masque les
/// adresses qui avouent leur ignorance, avec un motif ANCRE (`^...$`). Il
/// masque donc « à compléter » tout seul — treize fiches en vivent, et c'est
/// voulu : le marqueur est destine a l'editeur. Mais il ne masque RIEN qui
/// contienne autre chose : « 20148 Cozzano, adresse précise à compléter »
/// traversait le filtre et s'affichait mot pour mot. Six adresses etaient dans
/// ce cas. Le test « le champ adresse ne porte QUE la sentinelle que l app
/// masque » exige donc que `address` ne porte QUE la sentinelle exacte, jamais
/// une variante composee — c'est la regle que le filtre suppose sans pouvoir la
/// verifier lui-meme.
///
/// ET LE MOTIF EST RELU DANS LE CODE, PAS RECOPIE DE MEMOIRE : un test compare
/// la sentinelle d'ici au littera du fichier de l'application. Si quelqu'un
/// elargit ou retire le filtre, cette garde le dit au lieu de continuer a
/// mesurer une regle qui n'existe plus.
///
/// CE QUI N'EST PAS JUGE, ET POURQUOI.
///
/// — `publication/publie/` : des INSTANTANES HORODATES. Ce sont des archives de
///   publications passees, et le plus recent gele l'etat d'AVANT le correctif
///   du lot 801 (0 accent sur 58 noms). Les retoucher serait reecrire
///   l'histoire d'une publication deja faite.
///
/// — `test/fixtures/` : des temoins FIGES, dont certains existent precisement
///   pour etre fautifs (les `*_avant_801.json` servent a prouver qu'une garde
///   rougit). Les juger retournerait la garde contre ses propres preuves.
///
/// — les champs prefixes `_` : des notes d'editeur (`_pourquoi`, `_comment`),
///   jamais chargees par un ecran. L'une d'elles explique justement la regle
///   maison (« Un numero de telephone faux, en montagne, coute plus cher qu un
///   champ vide ») et contient donc le mot qu'on traque : la juger
///   condamnerait la doctrine en croyant condamner un defaut.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Les marqueurs de chantier qu'on refuse dans un texte destine a l'ecran.
///
/// Les cinq langues du depot y sont, parce que le contenu editorial est traduit
/// et qu'un aveu traduit reste un aveu : `zu erganzen`, `da completare` et
/// `por completar` ne sont PAS dans le filtre de l'application (qui ne connait
/// que trois formes) — raison de plus pour qu'ils n'atteignent jamais la
/// donnee.
final RegExp kMarqueursDeChantier = RegExp(
  r'a\s+completer'
  r'|à\s+compléter'
  r'|to\s+be\s+completed'
  r'|zu\s+erganzen'
  r'|zu\s+ergänzen'
  r'|da\s+completare'
  r'|por\s+completar'
  r'|lorem\s+ipsum'
  r'|\bbouchon\b'
  r'|\bplaceholder\b'
  r'|\bdummy\b'
  r'|example\.(com|org)'
  r'|à\s+définir'
  r'|a\s+definir'
  r'|non\s+renseigné',
  caseSensitive: false,
);

/// LES MARQUEURS D'INGENIEUR, ET ILS SONT SENSIBLES A LA CASSE — PIEGE MESURE.
///
/// `TODO` cherche en ignorant la casse attrape le mot espagnol « todo », qui
/// est un mot ordinaire : la premiere version de cette garde a ainsi condamne
/// « Todo el ano, una salida por hora » et « donde todo esta abierto », deux
/// phrases parfaitement justes. Ces marqueurs-la sont une CONVENTION DE CODE,
/// toujours ecrite en capitales ; les chercher en capitales est donc plus juste
/// ET plus sur.
final RegExp kMarqueursEnMajuscules = RegExp(
  r'\bTODO\b|\bFIXME\b|\bTBD\b|\bXXX\b|\bHACK\b|CHANGEME|\bWIP\b',
);

/// Le premier marqueur de chantier d'un texte, ou `null` s'il est propre.
String? marqueurDeChantier(String texte) =>
    kMarqueursDeChantier.firstMatch(texte)?.group(0) ??
    kMarqueursEnMajuscules.firstMatch(texte)?.group(0);

/// LA SENTINELLE TOLEREE, et seulement dans le champ `address`.
///
/// Copie fidele du motif de `LieuCliquable._aveuDIgnorance`. Un test verifie
/// que les deux ne divergent pas.
final RegExp kSentinelleMasquee = RegExp(
  r'^\s*(a\s+completer|à\s+compléter|to\s+be\s+completed)\s*$',
  caseSensitive: false,
);

/// Les champs dont la valeur peut ATTEINDRE L'ECRAN.
final RegExp kChampsAffichesDesDonnees = RegExp(
  r'^(name|name_[a-z]{2}|nameFr|displayName|tagline'
  r'|description|description_[a-z]{2}|descriptionFr'
  r'|title|titleFr|subtitleFr|labelFr|contentFr|pointsFr'
  r'|departureName|arrivalName|openingHours|address)$',
);

/// Le champ qui a droit a la sentinelle, et lui seul.
const String kChampAdresse = 'address';

/// Un texte de donnee, avec de quoi le retrouver a la main.
class TexteDeDonnee {
  const TexteDeDonnee(this.fichier, this.chemin, this.clef, this.valeur);

  final String fichier;
  final String chemin;
  final String clef;
  final String valeur;

  @override
  String toString() => '$fichier $chemin : « $valeur »';
}

/// Recolte les textes affiches d'un arbre JSON.
List<TexteDeDonnee> textesAffichesDeDonnee(String fichier, Object? racine) {
  final out = <TexteDeDonnee>[];
  void marche(Object? o, String chemin) {
    if (o is Map) {
      o.forEach((clef, valeur) {
        final nom = '$clef';
        // Note d'editeur, prefixee `_` : aucun ecran ne la charge.
        if (nom.startsWith('_')) return;
        final sous = '$chemin/$nom';
        if (kChampsAffichesDesDonnees.hasMatch(nom)) {
          if (valeur is String) {
            out.add(TexteDeDonnee(fichier, sous, nom, valeur));
            return;
          }
          if (valeur is List) {
            for (var i = 0; i < valeur.length; i++) {
              final item = valeur[i];
              if (item is String) {
                out.add(TexteDeDonnee(fichier, '$sous/$i', nom, item));
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

/// Les fichiers JSON d'un dossier, en profondeur, tries pour un diff stable.
///
/// L'enumeration est DYNAMIQUE a dessein : un fichier de donnees ajoute demain
/// est couvert sans que personne ait a l'inscrire dans une liste.
List<String> jsonsDe(String dossier, {List<String> sauf = const <String>[]}) {
  final d = Directory(dossier);
  if (!d.existsSync()) return <String>[];
  final out =
      d
          .listSync(recursive: true)
          .whereType<File>()
          .map((f) => f.path.replaceAll(r'\', '/'))
          .where((p) => p.endsWith('.json'))
          .where((p) => !sauf.any(p.contains))
          .toList()
        ..sort();
  return out;
}

List<TexteDeDonnee> _textesDe(Iterable<String> fichiers) {
  final out = <TexteDeDonnee>[];
  for (final p in fichiers) {
    final Object? racine;
    try {
      racine = jsonDecode(File(p).readAsStringSync()) as Object?;
    } on FormatException {
      continue; // la validite JSON est le sujet d'autres gardes
    }
    out.addAll(textesAffichesDeDonnee(p, racine));
  }
  return out;
}

void main() {
  group('Aucun texte de chantier dans les donnees LIVREES (835)', () {
    test('les donnees embarquees ne contiennent aucun marqueur', () {
      final fichiers = jsonsDe('assets');
      expect(
        fichiers,
        isNotEmpty,
        reason: 'aucun JSON trouve sous assets/ : la garde serait aveugle',
      );

      final fautes = <String>[];
      for (final t in _textesDe(fichiers)) {
        final m = marqueurDeChantier(t.valeur);
        if (m != null) fautes.add('\$t -> « \$m »');
      }
      expect(
        fautes,
        isEmpty,
        reason:
            'Du texte de chantier est EMBARQUE dans l application :\n'
            '${fautes.join('\n')}',
      );
    });
  });

  group('Aucun texte de chantier dans le contenu editorial (835)', () {
    // `publie/` est exclu : instantanes horodates, cf. en-tete.
    List<String> fichiers() => <String>[
      ...jsonsDe('publication/contenu'),
      ...jsonsDe('publication/sources'),
    ];

    test('le contenu editorial existe bien la ou on le cherche', () {
      expect(fichiers(), isNotEmpty);
    });

    // LE TEST QUI DONNE SON NOM AU LOT A2.
    test('aucun champ affiche n avoue un chantier, hors adresse', () {
      final fautes = <String>[];
      for (final t in _textesDe(fichiers())) {
        if (t.clef == kChampAdresse) continue; // traite au test suivant
        final m = marqueurDeChantier(t.valeur);
        if (m != null) fautes.add('\$t -> « \$m »');
      }
      expect(
        fautes,
        isEmpty,
        reason:
            'Un texte destine au randonneur avoue un travail inachevé. Si la '
            'valeur est inconnue, on ne l ecrit PAS : un champ vide se masque, '
            'une phrase ne se masque pas.\n${fautes.join('\n')}',
      );
    });

    // LE TEST QUI AURAIT ATTRAPE LA FUITE DES SIX ADRESSES.
    test('le champ adresse ne porte QUE la sentinelle que l app masque', () {
      final fautes = <String>[];
      for (final t in _textesDe(fichiers())) {
        if (t.clef != kChampAdresse) continue;
        if (marqueurDeChantier(t.valeur) == null) continue;
        if (kSentinelleMasquee.hasMatch(t.valeur)) continue;
        fautes.add('$t');
      }
      expect(
        fautes,
        isEmpty,
        reason:
            'Ces adresses avouent leur ignorance SANS etre masquables : le '
            'filtre de LieuCliquable est ANCRE (^...\$), donc il ne masque que '
            'la sentinelle seule. Une adresse composee s affiche mot pour mot '
            'au randonneur.\n${fautes.join('\n')}',
      );
    });
  });

  group('La garde est accrochee au vrai filtre de l application (835)', () {
    test('le motif de maps_link.dart est bien celui que ce test suppose', () {
      final source = File(
        'lib/shared/widgets/maps_link.dart',
      ).readAsStringSync();
      expect(
        source,
        contains(
          r"r'^\s*(a\s+completer|à\s+compléter|to\s+be\s+completed)\s*$'",
        ),
        reason:
            'Le filtre d adresse de l application a change. Mets a jour '
            'kSentinelleMasquee DANS LE MEME COMMIT : sans cela, cette garde '
            'mesure une regle qui n existe plus.',
      );
    });
  });

  group('La garde a des dents (835)', () {
    test('les textes REELS d avant le correctif sont refuses', () {
      const avant = <String>[
        'Ghisonaccia est la dernière ville avant la montagne. La liste et les '
            'horaires sont tenus par l office de tourisme de la Corse '
            'orientale, 04 95 56 12 38. Adresses précises : à compléter.',
        'Emplacement exact de l arrêt à Ghisonaccia : à compléter.',
        'Santa-Maria-Siché : ravitaillement à compléter',
        'Coti-Chiavari: resupply to be completed',
        'Genaue Haltestelle: zu erganzen.',
        'Posizione esatta della fermata: da completare.',
        'Ubicacion exacta de la parada: por completar.',
      ];
      for (final texte in avant) {
        expect(
          marqueurDeChantier(texte),
          isNotNull,
          reason: 'La garde laisse passer « $texte »',
        );
      }
    });

    test('les adresses composees d avant sont refusees, la sentinelle non', () {
      const composees = <String>[
        '20148 Cozzano, adresse précise à compléter',
        '20240 Ghisonaccia, numéro de rue à compléter',
        '20243 Serra-di-Fiumorbo, adresse précise à compléter',
      ];
      for (final a in composees) {
        expect(marqueurDeChantier(a), isNotNull);
        expect(
          kSentinelleMasquee.hasMatch(a),
          isFalse,
          reason: '« $a » n est PAS masquable : le filtre est ancre',
        );
      }
      // La sentinelle seule, elle, reste toleree : elle est masquee a l ecran.
      for (final s in <String>[
        'à compléter',
        '  à compléter  ',
        'À COMPLÉTER',
      ]) {
        expect(
          kSentinelleMasquee.hasMatch(s),
          isTrue,
          reason: '« $s » devrait etre reconnue comme la sentinelle masquee',
        );
      }
    });

    test('les textes d apres le correctif sont acceptes', () {
      const apres = <String>[
        'Ghisonaccia est la dernière ville avant la montagne. La liste et les '
            'horaires sont tenus par l office de tourisme de la Corse '
            'orientale, 04 95 56 12 38.',
        'Santa-Maria-Siché : aucun commerce confirmé',
        'Coti-Chiavari: no shop confirmed',
        '20148 Cozzano',
        '1395 avenue du 9 Septembre, 20240 Ghisonaccia',
      ];
      for (final texte in apres) {
        expect(
          marqueurDeChantier(texte),
          isNull,
          reason: 'La garde refuse « $texte », qui est pourtant propre',
        );
      }
    });
  });
}
