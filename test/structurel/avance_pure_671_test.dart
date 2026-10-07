import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// GARDE STRUCTURELLE — LA FONCTION PURE D'AVANCE RESTE PURE (lot 671-03).
///
/// `lib/core/geo/track_projection.dart` est lue par l'isolate de l'interface
/// ET par l'isolate de fond, et le socle ne lit aucune feature. Elle ne
/// doit donc importer QUE de la geometrie : ni Flutter, ni greffon, ni
/// feature. La garde suit aussi les fichiers du socle qu'elle importe.
void main() {
  const pureFile = 'lib/core/geo/track_projection.dart';

  /// Les imports interdits, et pourquoi.
  final forbidden = <RegExp, String>{
    RegExp(r'^package:flutter'): 'Flutter',
    RegExp(
      r'^package:(geolocator|sensors_plus|pedometer|battery_plus|'
      r'flutter_background_service|shared_preferences|permission_handler)',
    ): 'un greffon',
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

  test('la fonction pure d avance n importe ni Flutter, ni greffon, ni '
      'feature', () {
    final toVisit = [pureFile];
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
    expect(seen, contains(pureFile));
    expect(faults, isEmpty, reason: faults.join('\n'));
  });
}
