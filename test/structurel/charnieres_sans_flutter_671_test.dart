import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// GARDE STRUCTURELLE — LES CHARNIERES RESTENT DE LA GEOMETRIE (lot 671-04).
///
/// `lib/core/geo/charnieres_du_trace.dart` est lue par l'isolate de
/// l'interface (qui calcule la liste au chargement du sentier) ET par
/// l'isolate de fond (qui y compare l'abscisse du randonneur), et le socle ne
/// lit aucune feature. Elle ne doit donc importer QUE de la geometrie : ni
/// Flutter, ni greffon, ni feature. La garde suit aussi les fichiers du socle
/// qu'elle importe, et nomme le fichier fautif dans son message d'echec.
void main() {
  const fichierPur = 'lib/core/geo/charnieres_du_trace.dart';

  /// Les imports interdits, et pourquoi.
  final interdits = <RegExp, String>{
    RegExp(r'^package:flutter'): 'Flutter',
    RegExp(
      r'^package:(geolocator|sensors_plus|pedometer|battery_plus|'
      r'flutter_background_service|shared_preferences|permission_handler|'
      r'drift|flutter_riverpod)',
    ): 'un greffon',
    RegExp(r'features/'): 'une feature',
    RegExp(r'^package:moteur_gr/'):
        'un import de paquet (le socle est relatif)',
  };

  List<String> importsDe(String chemin) => [
    for (final m in RegExp(
      r'''^import\s+'([^']+)';''',
      multiLine: true,
    ).allMatches(File(chemin).readAsStringSync()))
      m.group(1)!,
  ];

  test('la fonction pure des charnieres n importe ni Flutter, ni greffon, '
      'ni feature', () {
    final aVisiter = [fichierPur];
    final vus = <String>{};
    final fautes = <String>[];
    while (aVisiter.isNotEmpty) {
      final fichier = aVisiter.removeLast();
      if (!vus.add(fichier)) continue;
      for (final imp in importsDe(fichier)) {
        for (final interdit in interdits.entries) {
          if (interdit.key.hasMatch(imp)) {
            fautes.add('$fichier importe $imp (${interdit.value})');
          }
        }
        if (!imp.contains(':') &&
            !imp.endsWith('.g.dart') &&
            !imp.endsWith('.freezed.dart')) {
          aVisiter.add(File(fichier).parent.uri.resolve(imp).toFilePath());
        }
      }
    }
    expect(vus, contains(fichierPur));
    expect(fautes, isEmpty, reason: fautes.join('\n'));
  });
}
