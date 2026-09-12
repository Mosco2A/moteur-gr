// ignore_for_file: avoid_print
//
// DRIVER host-side des tests PERSONAS (tache 518).
//
// Ce fichier tourne SUR L HOTE (Windows), pas sur l'appareil. Il :
//   * recoit chaque CAPTURE demandee par le test (`takeScreenshot`) et l'ecrit
//     en PNG dans data/captures_personas/ ;
//   * a la fin, ecrit le JOURNAL renvoye via `reportData` (une entree par
//     persona) en fichiers .txt dans le meme dossier.
//
// Lancement : flutter drive --driver test_driver/persona_driver.dart
//   --target integration_test/persona_sX_..._test.dart -d emulator-5554

import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

const String kCapturesDir =
    r'C:\Users\Christophe\claude\data\captures_personas';

Future<void> main() async {
  Directory(kCapturesDir).createSync(recursive: true);

  await integrationDriver(
    // Ecrit chaque capture recue en PNG sur le disque de l'hote.
    onScreenshot:
        (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      try {
        final safe = name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        final file = File('$kCapturesDir\\$safe.png');
        await file.writeAsBytes(bytes);
        print('DRIVER capture ecrite : ${file.path} (${bytes.length} octets)');
        return true;
      } catch (e) {
        print('DRIVER ECHEC ecriture capture $name : $e');
        return false;
      }
    },
    // A la fin, persiste le journal de chaque persona (reportData renvoye par le
    // test via kBinding.reportData). `responseDataCallback` remplace l'ecriture
    // JSON par defaut : on ecrit un .txt lisible par persona.
    responseDataCallback: (Map<String, dynamic>? data) async {
      if (data == null) return;
      for (final entry in data.entries) {
        if (entry.key.startsWith('journal_')) {
          final persona = entry.key.substring('journal_'.length);
          final file = File('$kCapturesDir\\_journal_$persona.txt');
          await file.writeAsString('${entry.value}');
          print('DRIVER journal ecrit : ${file.path}');
        }
      }
    },
  );
}
