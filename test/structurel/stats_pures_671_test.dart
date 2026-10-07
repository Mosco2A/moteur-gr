import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// GARDE STRUCTURELLE — LE MOTEUR DE CHIFFRES ET LA TRANCHE RESTENT PURS
/// (lot 671-06).
///
/// Le moteur ([computeTrackStatsOn] et son type leger [StatsPoint], dans
/// `track_segment_stats.dart`) et la decoupe de la tranche de trace
/// (`track_slice.dart`) sont de la GEOMETRIE : ni Flutter, ni greffon, ni
/// feature, ni base. La garde suit aussi les fichiers du socle qu'ils
/// importent. Et depuis le lot 671-06, le moteur n'importe PLUS la base : la
/// surcharge qui lit les points enregistres vit a cote, dans
/// `recorded_track_stats.dart`. Sa liste d'imports en est la preuve.
void main() {
  const pureFiles = [
    'lib/core/geo/track_segment_stats.dart',
    'lib/core/geo/track_slice.dart',
  ];

  /// Les imports interdits, et pourquoi.
  final forbidden = <RegExp, String>{
    RegExp(r'^package:flutter'): 'Flutter',
    RegExp(
      r'^package:(geolocator|sensors_plus|pedometer|battery_plus|'
      r'flutter_background_service|shared_preferences|permission_handler)',
    ): 'un greffon',
    RegExp(r'^package:drift'): 'Drift',
    RegExp(r'(^|/)data/'): 'la base',
    RegExp(r'features/'): 'une feature',
    RegExp(r'^package:moteur_gr/'):
        'un import de paquet (le socle est relatif)',
  };

  List<String> importsOf(String path) => [
    for (final m in RegExp(
      r'''^import\s+'([^']+)';''',
      multiLine: true,
    ).allMatches(File(path).readAsStringSync()))
      m.group(1)!,
  ];

  test('le moteur, son type leger et la tranche n importent ni Flutter, ni '
      'greffon, ni feature, ni Drift, ni la base', () {
    final toVisit = [...pureFiles];
    final seen = <String>{};
    final faults = <String>[];
    while (toVisit.isNotEmpty) {
      final file = toVisit.removeLast();
      if (!seen.add(file)) continue;
      for (final imp in importsOf(file)) {
        for (final entry in forbidden.entries) {
          if (entry.key.hasMatch(imp)) {
            faults.add('$file importe $imp (${entry.value})');
          }
        }
        if (!imp.contains(':') &&
            !imp.endsWith('.g.dart') &&
            !imp.endsWith('.freezed.dart')) {
          toVisit.add(File(file).parent.uri.resolve(imp).toFilePath());
        }
      }
    }
    expect(seen, containsAll(pureFiles));
    expect(faults, isEmpty, reason: faults.join('\n'));
  });

  test('LE MOTEUR A CESSE D IMPORTER LA BASE : sa liste d imports est '
      'reduite a la geometrie', () {
    // Avant le lot 671-06 : ['../data/database.dart', 'geo_utils.dart'].
    expect(importsOf('lib/core/geo/track_segment_stats.dart'), [
      'geo_utils.dart',
    ]);
  });
}
