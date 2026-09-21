import 'dart:io';

import 'package:gpx/gpx.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/data/database.dart';

/// Ecriture GPX de la trace reellement marchee (CORRECTIF L5-4).
///
/// StepWays ne savait que LIRE du GPX (`gpx_parser`, `gpx_import_service`) ;
/// aucun ecrivain n'existait, et l'export etait un TODO. Ce service ferme le
/// trou : la trace enregistree pendant la randonnee ressort en fichier .gpx
/// ouvrable dans n'importe quel outil de cartographie.
///
/// Depend du socle L3-1 : c'est lui qui donne aux points leur JOUR DE MARCHE,
/// et donc qui rend l'export honnete (cf. [buildGpx]).
class GpxExportService {
  GpxExportService._();

  /// Construit le contenu d'un fichier GPX a partir d'une trace.
  ///
  /// UN SEGMENT PAR JOUR DE MARCHE, et c'est le point important. Une trace
  /// rendue en un seul segment relierait le dernier point du soir au premier
  /// point du lendemain matin : l'outil de cartographie tracerait une ligne
  /// droite a travers la vallee, souvent des dizaines de kilometres, et le
  /// profil altimetrique serait faux. Les points sans jour connu (trace
  /// anterieure a la migration v26) forment un segment a part, en tete.
  static String buildGpx({
    required List<SessionTrackPoint> points,
    required String trackName,
    String? description,
    DateTime? generatedAt,
  }) {
    final segments = <Trkseg>[];
    // LinkedHashMap implicite : l'ordre d'insertion est conserve, donc les
    // jours sortent dans l'ordre ou ils ont ete marches.
    final byDay = <int?, List<SessionTrackPoint>>{};
    for (final p in points) {
      byDay.putIfAbsent(p.dayIndex, () => <SessionTrackPoint>[]).add(p);
    }
    final keys = byDay.keys.toList()
      ..sort((a, b) {
        if (a == null) return -1;
        if (b == null) return 1;
        return a.compareTo(b);
      });
    for (final day in keys) {
      segments.add(
        Trkseg(
          trkpts: [
            for (final p in byDay[day]!)
              Wpt(
                lat: p.lat,
                lon: p.lng,
                ele: p.altitude,
                time: p.recordedAt.toUtc(),
              ),
          ],
        ),
      );
    }

    final gpx = Gpx()
      ..creator = 'StepWays'
      ..version = '1.1'
      ..metadata = Metadata(
        name: trackName,
        desc: description,
        time: (generatedAt ?? DateTime.now()).toUtc(),
      )
      ..trks = [
        Trk(name: trackName, desc: description, trksegs: segments),
      ];

    return GpxWriter().asString(gpx, pretty: true);
  }

  /// Ecrit le contenu GPX sur le support de stockage et retourne le fichier.
  ///
  /// Dossier de DOCUMENTS de l'app et non le temporaire : une trace que le
  /// randonneur exporte doit survivre a la fermeture de l'app.
  /// [directory] n'existe que pour les tests.
  static Future<File> saveGpx({
    required String content,
    required String trailId,
    DateTime? at,
    Directory? directory,
  }) async {
    final dir = directory ?? await getApplicationDocumentsDirectory();
    final target = Directory('${dir.path}/exports');
    if (!target.existsSync()) {
      await target.create(recursive: true);
    }
    final file = File('${target.path}/${gpxFileName(trailId, at: at)}');
    await file.writeAsString(content, flush: true);
    return file;
  }

  /// Nom de fichier de l'export : lisible, horodate, sans caractere piege.
  static String gpxFileName(String trailId, {DateTime? at}) {
    final when = at ?? DateTime.now();
    final safeTrail = trailId.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9-]'),
          '-',
        );
    String two(int v) => v.toString().padLeft(2, '0');
    final stamp = '${when.year}${two(when.month)}${two(when.day)}'
        '-${two(when.hour)}${two(when.minute)}${two(when.second)}';
    return 'trace-$safeTrail-$stamp.gpx';
  }
}
