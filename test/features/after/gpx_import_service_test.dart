import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/after/data/gpx_import_service.dart';
import 'package:moteur_gr/features/trek/domain/models/stage.dart';

/// PARITE GR20 (Import GPX) — le service d'import est GENERIQUE et data-driven :
/// bornes geographiques, points de reference (detection d'etapes + hors-trace)
/// et nombre d'etapes proviennent des ETAPES du sentier ([TrailImportConfig]),
/// jamais de constantes GR20 (Corse / refuges 16 en dur).
void main() {
  // --- Sentier de test FICTIF (Auvergne, aucune correspondance reelle) : 3
  // etapes ~ autour de 45.5N / 2.9E. Le service en derive une boite + des points
  // de reference (depart/arrivee de chaque etape). ---
  Stage stage(int n, double lat, double lng, double lat2, double lng2) => Stage(
        id: '$n',
        nameFr: 'Etape $n',
        distance: 12.0,
        elevationGain: 600,
        elevationLoss: 400,
        orderIndex: n,
        startLat: lat,
        startLng: lng,
        endLat: lat2,
        endLng: lng2,
      );

  final stages = <Stage>[
    stage(1, 45.500, 2.900, 45.520, 2.920),
    stage(2, 45.520, 2.920, 45.540, 2.940),
    stage(3, 45.540, 2.940, 45.560, 2.960),
  ];

  final config = TrailImportConfig.fromStages(stages);
  const service = GpxImportService();

  /// Construit un GPX a N points autour d'un point de depart, pas regulier.
  String gpxWith({
    required int count,
    required double baseLat,
    required double baseLng,
    double stepLat = 0.0005,
    double stepLng = 0.0005,
    double baseEle = 800,
    double stepEle = 10,
    bool withTime = true,
    DateTime? start,
  }) {
    final startTime = start ?? DateTime.utc(2026, 7, 1, 8);
    final buf = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<gpx version="1.1" creator="test"><trk><trkseg>');
    for (var i = 0; i < count; i++) {
      final lat = baseLat + stepLat * i;
      final lng = baseLng + stepLng * i;
      final ele = baseEle + stepEle * i;
      final timeTag = withTime
          ? '<time>${startTime.add(Duration(minutes: i * 10)).toIso8601String()}</time>'
          : '';
      buf.writeln(
        '<trkpt lat="$lat" lon="$lng"><ele>$ele</ele>$timeTag</trkpt>',
      );
    }
    buf.writeln('</trkseg></trk></gpx>');
    return buf.toString();
  }

  group('TrailImportConfig.fromStages (data-driven)', () {
    test('derive une boite englobante des etapes + marge (pas de Corse en dur)',
        () {
      expect(config.bounds, isNotNull);
      final b = config.bounds!;
      // La boite couvre bien les coords des etapes (avec marge 0.15deg).
      expect(b.minLat, lessThan(45.500));
      expect(b.maxLat, greaterThan(45.560));
      expect(b.minLon, lessThan(2.900));
      expect(b.maxLon, greaterThan(2.960));
      // Un point EN Corse (42.4N, 9.0E) est HORS de la boite Auvergne (preuve
      // que rien n'est borne sur la Corse).
      expect(b.contains(42.4, 9.0), isFalse);
      // Le coeur du sentier fictif est DANS la boite.
      expect(b.contains(45.53, 2.93), isTrue);
    });

    test('un point de reference par extremite d etape (depart + arrivee)', () {
      // 3 etapes -> 6 points de reference.
      expect(config.referencePoints.length, 6);
    });

    test('totalStages derive du nombre d etapes (jamais 16 en dur)', () {
      expect(config.totalStages, 3);
      final restricted = TrailImportConfig.fromStages(stages, totalStages: 2);
      expect(restricted.totalStages, 2);
    });

    test('aucune etape -> bounds null (hors-zone tolerant)', () {
      final empty = TrailImportConfig.fromStages(const []);
      expect(empty.bounds, isNull);
      expect(empty.referencePoints, isEmpty);
      expect(empty.totalStages, 0);
    });
  });

  group('GpxImportService.importGpxFile', () {
    test('GPX valide dans la zone -> preview coherente (dist/D+/D-/direction)',
        () {
      // 30 points montant vers le nord (lat croissante) le long du sentier.
      final gpx = gpxWith(count: 30, baseLat: 45.500, baseLng: 2.900);
      final data = service.importGpxFile(gpx, config);

      expect(data.isValid, isTrue);
      expect(data.trackPoints.length, 30);
      // Distance > 0 et coherente (points espaces ~0.0007deg -> ~2 km sur 30 pts).
      expect(data.totalDistanceKm, greaterThan(0));
      // Altitude croissante 800 -> 800+29*10 : D+ = 290, D- = 0.
      expect(data.totalElevationGain, 290);
      expect(data.totalElevationLoss, 0);
      // Latitude finale > initiale -> direction 'SN' (premier < dernier).
      expect(data.direction, 'SN');
      // Duree = 29 * 10 min.
      expect(data.totalDuration, const Duration(minutes: 290));
      // totalStages propage la config (3).
      expect(data.totalStages, 3);
    });

    test('< 10 points -> invalide (motif tooFewPoints + valeur)', () {
      final gpx = gpxWith(count: 5, baseLat: 45.500, baseLng: 2.900);
      final data = service.importGpxFile(gpx, config);

      expect(data.isValid, isFalse);
      expect(data.invalidReason, ImportInvalidReason.tooFewPoints);
      expect(data.invalidValue, 5);
    });

    test('> 50% hors zone du sentier -> invalide (motif outOfBounds)', () {
      // 20 points au large de l'Atlantique (loin de la boite Auvergne).
      final gpx = gpxWith(count: 20, baseLat: 10.0, baseLng: -30.0);
      final data = service.importGpxFile(gpx, config);

      expect(data.isValid, isFalse);
      expect(data.invalidReason, ImportInvalidReason.outOfBounds);
      expect((data.invalidValue ?? 0), greaterThan(10));
    });

    test('detecte les etapes dont un point de ref est proche de la trace', () {
      // Trace passant PILE sur les extremites d'etapes -> etapes detectees.
      // On genere une trace dense couvrant depart E1 -> arrivee E3.
      final gpx = gpxWith(
        count: 40,
        baseLat: 45.500,
        baseLng: 2.900,
        stepLat: 0.0015,
        stepLng: 0.0015,
      );
      final data = service.importGpxFile(gpx, config);

      expect(data.isValid, isTrue);
      // Au moins une etape detectee (les extremites sont sur le trajet).
      expect(data.stagesDetected, isNotEmpty);
      // Les etapes detectees sont triees par orderIndex.
      final indices = data.stagesDetected.map((s) => s.orderIndex).toList();
      final sorted = [...indices]..sort();
      expect(indices, sorted);
    });

    test('trace valide MAIS majoritairement hors trace -> warning offTrail', () {
      // Points DANS la boite (marge 0.15deg) mais a >5 km des points de ref :
      // on decale de ~0.1deg (~11 km) au sud-est du coin des etapes, en restant
      // sous le seuil des 50% hors-boite (donc valide) tout en etant > tolerance.
      final gpx = gpxWith(
        count: 20,
        baseLat: 45.60,
        baseLng: 3.02,
        stepLat: 0.0002,
        stepLng: 0.0002,
      );
      final data = service.importGpxFile(gpx, config);

      expect(data.isValid, isTrue);
      final offTrail = data.warnings
          .where((w) => w.type == ImportWarningType.offTrail)
          .toList();
      expect(offTrail, isNotEmpty);
      expect(offTrail.first.value, greaterThan(30));
    });

    test('GPX illisible -> invalide sans crash', () {
      final data = service.importGpxFile('pas du xml valide', config);
      expect(data.isValid, isFalse);
      expect(data.invalidReason, ImportInvalidReason.tooFewPoints);
    });

    test('sans timestamps -> duree zero, pas de crash', () {
      final gpx = gpxWith(
        count: 15,
        baseLat: 45.500,
        baseLng: 2.900,
        withTime: false,
      );
      final data = service.importGpxFile(gpx, config);
      expect(data.isValid, isTrue);
      expect(data.totalDuration, Duration.zero);
    });

    test('config sans bounds (aucune etape) -> pas de rejet hors-zone', () {
      final empty = TrailImportConfig.fromStages(const []);
      // Une trace « n importe ou » reste valide (hors-zone desactive).
      final gpx = gpxWith(count: 15, baseLat: 10.0, baseLng: -30.0);
      final data = service.importGpxFile(gpx, empty);
      expect(data.isValid, isTrue);
      expect(data.stagesDetected, isEmpty);
    });
  });
}
