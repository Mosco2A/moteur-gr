// LE FICHIER D'ESSAI DE LA QA EST LISIBLE — tache 645-04.
//
// POURQUOI CE TEST. `test/fixtures/gpx/essai_645_04.gpx` existe pour une seule
// raison : que Skynet rejoue a la main, sur l'emulateur, ce que les concepts
// C-1 (`gpx_parser`) et C-3 (`track_point`) touchent. Une fixture de QA qui ne
// se lit plus envoie le testeur chercher un defaut de l'application dans un
// defaut du fichier. Ce test est donc la verification MINIMALE que le fichier
// porte bien ce que la procedure de QA annonce, et rien de plus : il ne juge
// pas l'application, il juge la fixture.
//
// LES DEUX CHEMINS DE LECTURE, CEUX-LA MEMES QUE LA QA EMPRUNTE :
//   - `GpxParser.parse` (features/trek/data) — metadata, multi-tracks,
//     multi-segments, waypoints, distances cumulees PAR segment. C'est C-1 ;
//   - `GpxImportService.importGpxFile` — conversion vers le `TrackPoint` du
//     domaine trek (`elevation` + `timestamp`). C'est C-3.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/after/data/gpx_import_service.dart';
import 'package:moteur_gr/features/trek/data/gpx_parser.dart';

void main() {
  const chemin = 'test/fixtures/gpx/essai_645_04.gpx';
  late String contenu;

  setUpAll(() {
    final f = File(chemin);
    expect(
      f.existsSync(),
      isTrue,
      reason:
          'LA FIXTURE DE QA A DISPARU : $chemin est le fichier que la '
          'procedure d import reel sur emulateur demande de deposer sur '
          'l appareil. Sans lui, la QA de 645-04 ne peut pas etre rejouee.',
    );
    contenu = f.readAsStringSync();
  });

  group('645-04 — la fixture GPX de la QA porte ce que la procedure annonce', () {
    test(
      'C-1 : GpxParser.parse y voit les metadata, 3 segments et 2 waypoints',
      () {
        final resultat = GpxParser.parse(contenu);

        expect(resultat.metadata.name, contains('645-04'));
        expect(resultat.metadata.desc, isNotNull);
        expect(resultat.metadata.author, 'Christophe');

        // Deux trk, dont le premier porte deux trkseg : la mise a plat doit
        // rendre TROIS segments, et non deux tracks.
        expect(resultat.tracks.length, 3);
        expect(resultat.totalPoints, 36);
        expect(resultat.waypoints.length, 2);

        // La distance cumulee repart de zero a chaque segment : c'est le
        // comportement multi-segments que la QA doit pouvoir constater.
        for (final segment in resultat.tracks) {
          expect(segment.first.distanceFromStart, 0.0);
          expect(segment.last.distanceFromStart, greaterThan(0.0));
        }
      },
    );

    test(
      'C-3 : l import construit 36 TrackPoint du domaine, altitude et heure comprises',
      () {
        const service = GpxImportService();
        // bounds null + aucun point de reference : les controles geographiques
        // sont desactives, le test ne juge que la lecture du fichier.
        final data = service.importGpxFile(
          contenu,
          const TrailImportConfig(
            bounds: null,
            referencePoints: [],
            totalStages: 0,
          ),
        );

        expect(data.isValid, isTrue, reason: data.invalidReason?.toString());
        expect(data.trackPoints.length, 36);
        expect(data.trackPoints.first.elevation, 5);
        expect(data.trackPoints.first.timestamp, isNotNull);
        expect(data.totalDuration, greaterThan(Duration.zero));
        expect(data.totalElevationGain, greaterThan(0));
      },
    );
  });
}
