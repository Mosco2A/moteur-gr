// GARDE DE PLAFOND — UN SEUL ROBINET GPS PAR ISOLATE (lot 671-00).
//
// CE QUE LA REGLE DIT. Dans `lib/`, un seul endroit par isolate ouvre un flux
// de positions Geolocator : le `PositionController` pour l'isolate
// d'interface (`lib/features/trek/data/position_controller.dart`), et la
// capture de l'isolate de fond
// (`lib/features/trek/data/background_gps_service.dart`).
// Tout le reste DERIVE du controleur : carte, hors-trace, suivi, detection
// d'etape, arrivees, ecran d'urgence.
//
// POURQUOI. Le greffon geolocator ne garde qu'UN flux natif par isolate, regle
// par le premier qui l'ouvre ; les reglages des suivants sont ignores en
// silence. Avant le lot 671-00, cinq endroits de l'interface ouvraient chacun
// le leur, avec des reglages differents (quatre fois precision haute et 10 m,
// une fois un regime adaptatif) : la precision reellement servie dependait de
// l'ordre d'ouverture des ecrans. Un sixieme `getPositionStream` ne serait
// pas un detail : il rouvrirait cette loterie et contournerait le profil que
// la conception « batterie d'abord » pilote depuis le controleur.
//
// LE SECOND PLAFOND, `LocationAccuracy.high`. Chaque litteral est une
// precision choisie hors du controleur. Il en restait 8 avant le lot, il en
// reste 6 apres : 4 dans l'isolate de fond (inchange au lot 00), 1 pour le
// profil carte du controleur, 1 pour le palier `moving` de
// `GpsService.accuracyForMode`. Le plafond est serre contre la mesure : il ne
// remonte JAMAIS ; il ne peut que descendre quand un lot en paie un.
library;

import 'package:flutter_test/flutter_test.dart';

import 'mesure_des_sources_645.dart';

/// Un pour l'interface, un pour l'isolate de fond.
const plafondRobinets = 2;

/// Mesure du 06/10/2026, apres le lot 671-00 (8 avant).
const plafondPrecisionHaute = 6;

/// Les deux fichiers qui ont le droit d'ouvrir un flux Geolocator.
const robinetsAttendus = <String>[
  'lib/features/trek/data/background_gps_service.dart',
  'lib/features/trek/data/position_controller.dart',
];

final motifRobinet = RegExp(r'Geolocator\s*\.\s*getPositionStream\s*\(');
final motifPrecisionHaute = RegExp(r'LocationAccuracy\s*\.\s*high\b');

/// Les occurrences de [motif] dans le CODE de [sources], une par
/// `fichier:ligne`, commentaires exclus.
List<String> occurrences(Iterable<String> sources, RegExp motif) {
  final trouvees = <String>[];
  for (final chemin in sources) {
    final lignes = lignesDe(chemin);
    for (var i = 0; i < lignes.length; i++) {
      if (estLigneDeCommentaire(lignes[i])) continue;
      for (final _ in motif.allMatches(lignes[i])) {
        trouvees.add('$chemin:${i + 1}');
      }
    }
  }
  return trouvees;
}

/// Les fichiers distincts d'une liste de `fichier:ligne`.
Set<String> fichiersDe(List<String> sites) =>
    sites.map((s) => s.substring(0, s.lastIndexOf(':'))).toSet();

void main() {
  group('671-00 — un seul robinet GPS', () {
    test('au plus $plafondRobinets sites appellent '
        'Geolocator.getPositionStream dans lib/', () {
      final sites = occurrences(sourcesLib(), motifRobinet);
      final intrus = fichiersDe(sites).difference(robinetsAttendus.toSet());
      expect(
        intrus,
        isEmpty,
        reason:
            'Geolocator.getPositionStream appele hors du robinet unique : '
            '${intrus.join(', ')}. Abonnez-vous au flux de '
            'positionControllerProvider au lieu d ouvrir une souscription.\n'
            '${sites.join('\n')}',
      );
      expect(
        sites.length,
        lessThanOrEqualTo(plafondRobinets),
        reason:
            '${sites.length} sites appellent Geolocator.getPositionStream, '
            'plafond $plafondRobinets (un par isolate) :\n${sites.join('\n')}',
      );
    });

    test('au plus $plafondPrecisionHaute litteraux LocationAccuracy.high dans '
        'lib/', () {
      final sites = occurrences(sourcesLib(), motifPrecisionHaute);
      expect(
        sites.length,
        lessThanOrEqualTo(plafondPrecisionHaute),
        reason:
            '${sites.length} litteraux LocationAccuracy.high, plafond '
            '$plafondPrecisionHaute : une precision choisie hors du '
            'controleur. Fichiers : ${fichiersDe(sites).join(', ')}\n'
            '${sites.join('\n')}',
      );
    });

    test('LA GARDE MESURE VRAIMENT : les deux robinets attendus sont vus, et '
        'un commentaire ne compte pas', () {
      final sites = occurrences(sourcesLib(), motifRobinet);
      // Si le motif ou le parcours casse, la garde passerait au vert en ne
      // voyant plus rien : les deux robinets legitimes doivent etre vus.
      expect(fichiersDe(sites), containsAll(robinetsAttendus));
      expect(
        occurrences(sourcesLib(), motifPrecisionHaute),
        isNotEmpty,
        reason: 'aucun LocationAccuracy.high vu : le parcours est casse',
      );
      expect(estLigneDeCommentaire('  // Geolocator.getPositionStream('), true);
      expect(
        motifRobinet.hasMatch(
          'Geolocator.getPositionStream(locationSettings: s)',
        ),
        isTrue,
      );
    });
  });
}
