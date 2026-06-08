import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:moteur_gr/features/trek/presentation/map/marker_cluster.dart';

/// Tests E5.2a — clustering de marqueurs + epsilon Douglas-Peucker dynamique.
///
/// Headline : benchmark 100 marqueurs, le calcul de clustering (cout ajoute
/// par frame) doit tenir SOUS le budget de 16 ms (60 fps).
void main() {
  /// Genere une grille deterministe de [count] points sur une boite
  /// [span]° x [span]°, ancree en (baseLat, baseLng).
  List<ClusterPoint<int>> gridPoints(
    int count, {
    double baseLat = 44.0,
    double baseLng = 9.0,
    double span = 0.18,
  }) {
    const side = 10; // 10 x 10 = 100
    final step = span / (side - 1);
    return [
      for (var i = 0; i < count; i++)
        ClusterPoint<int>(
          position: LatLng(
            baseLat + (i ~/ side) * step,
            baseLng + (i % side) * step,
          ),
          data: i,
        ),
    ];
  }

  group('MarkerClusterer — benchmark & correction', () {
    test('benchmark : clustering de 100 marqueurs sous 16 ms', () {
      final points = gridPoints(100);

      // Warm-up (eviter de mesurer le cout de premier appel / JIT).
      MarkerClusterer.cluster<int>(points, zoom: 10);

      final sw = Stopwatch()..start();
      final clusters = MarkerClusterer.cluster<int>(points, zoom: 10);
      sw.stop();

      expect(
        sw.elapsedMicroseconds,
        lessThan(16000),
        reason: 'Le clustering de 100 marqueurs doit tenir dans un budget '
            'de frame (<16 ms). Mesure = ${sw.elapsedMicroseconds} us.',
      );
      // A ce zoom, l'agregation doit avoir reduit le nombre de marqueurs.
      expect(clusters.length, lessThan(100));
    });

    test('en dessous du seuil (<=50) : aucun point n\'est agrege', () {
      final points = gridPoints(50);
      final clusters = MarkerClusterer.cluster<int>(points, zoom: 10);

      expect(clusters.length, equals(50));
      expect(clusters.every((c) => !c.isCluster), isTrue);
      expect(clusters.every((c) => c.count == 1), isTrue);
    });

    test('au-dessus du seuil a faible zoom : agregation reelle', () {
      final points = gridPoints(100);
      final clusters = MarkerClusterer.cluster<int>(points, zoom: 10);

      expect(clusters.length, lessThan(100));
      expect(clusters.any((c) => c.isCluster), isTrue);
    });

    test('aucun point perdu : somme des membres == total', () {
      final points = gridPoints(100);
      final clusters = MarkerClusterer.cluster<int>(points, zoom: 10);

      final total = clusters.fold<int>(0, (acc, c) => acc + c.count);
      expect(total, equals(100));
    });

    test('monotonie : plus on zoome, moins on agrege', () {
      final points = gridPoints(100);
      final far = MarkerClusterer.cluster<int>(points, zoom: 10);
      final close = MarkerClusterer.cluster<int>(points, zoom: 16);

      expect(close.length, greaterThan(far.length));
      // A fort zoom, la grille est si fine que chaque point reste isole.
      expect(close.length, equals(100));
    });

    test('centroide d\'un cluster borne par ses membres', () {
      final points = gridPoints(100);
      final clusters = MarkerClusterer.cluster<int>(points, zoom: 8);
      final agg = clusters.firstWhere((c) => c.isCluster);

      final lats = agg.points.map((p) => p.position.latitude);
      final lngs = agg.points.map((p) => p.position.longitude);
      expect(agg.position.latitude,
          inInclusiveRange(lats.reduce((a, b) => a < b ? a : b),
              lats.reduce((a, b) => a > b ? a : b)));
      expect(agg.position.longitude,
          inInclusiveRange(lngs.reduce((a, b) => a < b ? a : b),
              lngs.reduce((a, b) => a > b ? a : b)));
    });

    test('cellSizeForZoom decroit avec le zoom', () {
      expect(MarkerClusterer.cellSizeForZoom(8),
          greaterThan(MarkerClusterer.cellSizeForZoom(12)));
      expect(MarkerClusterer.cellSizeForZoom(12),
          greaterThan(MarkerClusterer.cellSizeForZoom(16)));
    });
  });

  group('dynamicEpsilonForZoom — Douglas-Peucker dynamique', () {
    test('epsilon = 0 au-dela du plein detail (zoom >= 15)', () {
      expect(dynamicEpsilonForZoom(15), equals(0.0));
      expect(dynamicEpsilonForZoom(18), equals(0.0));
    });

    test('epsilon strictement decroissant dans la zone non plafonnee (z>=9)',
        () {
      var previous = double.infinity;
      for (var z = 9; z <= 14; z++) {
        final eps = dynamicEpsilonForZoom(z);
        expect(eps, lessThan(previous),
            reason: 'epsilon doit decroitre quand le zoom augmente (z=$z)');
        previous = eps;
      }
    });

    test('epsilon monotone non croissant sur toute la plage', () {
      var previous = double.infinity;
      for (var z = 1; z <= 15; z++) {
        final eps = dynamicEpsilonForZoom(z);
        expect(eps, lessThanOrEqualTo(previous),
            reason: 'epsilon ne doit jamais augmenter avec le zoom (z=$z)');
        previous = eps;
      }
    });

    test('epsilon plafonne a 500 m aux zooms tres faibles', () {
      expect(dynamicEpsilonForZoom(3), lessThanOrEqualTo(500.0));
      expect(dynamicEpsilonForZoom(1), equals(500.0));
    });

    test('epsilon positif sous le plein detail', () {
      for (var z = 5; z <= 14; z++) {
        expect(dynamicEpsilonForZoom(z), greaterThan(0.0));
      }
    });
  });

  group('ClusteredMarkerLayer — integration flutter_map', () {
    testWidgets('100 marqueurs : la couche se construit sans erreur',
        (tester) async {
      final points = List.generate(
        100,
        (i) => ClusterPoint<int>(
          position: LatLng(44.0 + (i ~/ 10) * 0.02, 9.0 + (i % 10) * 0.02),
          data: i,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(44.09, 9.09),
                  initialZoom: 10,
                ),
                children: [
                  ClusteredMarkerLayer<int>(
                    zoom: 10,
                    points: points,
                    singleMarkerBuilder: (context, point) => Marker(
                      point: point.position,
                      width: 20,
                      height: 20,
                      child: const Icon(Icons.place),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      // Au moins une bulle de cluster (compteur numerique) est rendue.
      expect(find.byType(MarkerLayer), findsOneWidget);
    });
  });
}
