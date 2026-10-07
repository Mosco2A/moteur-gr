import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/geo/recorded_track_stats.dart';
import 'package:moteur_gr/core/geo/track_segment_stats.dart';

/// LOT 671-06 — LE MOTEUR DE CHIFFRES N'A PAS CHANGE, SEULE SON ENTREE.
///
/// Le premier test de ce lot, et celui qui prouve qu'il n'a pas touche au
/// calcul : sur la MEME liste de releves reels, les six champs rendus sont
/// ceux que rendait `computeTrackStats` AVANT le lot, mesures sur la tete
/// fabb1ec2 (branche d'integration 671, 07/10/2026) et recopies ici. Le
/// second prouve que la surcharge d'adaptation convertit sans rien calculer.
void main() {
  /// Une journee de soixante releves reels, toutes les trois minutes a
  /// quelques secondes pres : la meme liste que celle de la mesure d'avant.
  List<SessionTrackPoint> journeeReelle() {
    final t0 = DateTime.utc(2026, 7, 14, 7, 30);
    return [
      for (var i = 0; i < 60; i++)
        SessionTrackPoint(
          id: i + 1,
          trailId: 'banc',
          lat: 42.0 + i * 0.0009 + (i % 7) * 0.00013,
          lng: 9.0 + (i % 5) * 0.0004 - (i % 3) * 0.00021,
          altitude: 600 + 80 * sin(i / 6) + (i % 4) * 1.7,
          recordedAt: t0.add(Duration(seconds: 180 * i + (i % 3) * 7)),
          source: 'gps',
        ),
    ];
  }

  group('671-06 (1) — le moteur rend les memes chiffres qu avant le lot', () {
    test('les six champs et la vitesse sont IDENTIQUES a la mesure de la '
        'tete fabb1ec2, au metre, a la seconde et au centieme', () {
      final s = computeTrackStats(journeeReelle());

      // Mesure d'avant, recopiee telle quelle (tete fabb1ec2).
      expect(s.distanceKm, 7.14470581176422);
      expect(s.elevationGainM, 241);
      expect(s.elevationLossM, 271);
      expect(s.duration, const Duration(microseconds: 10634000000));
      expect(s.maxAltitudeM, 685.0829465131377);
      expect(s.pointCount, 60);
      expect(s.averageSpeedKmh, 2.4187456199314648);
    });

    test('un seul releve : le resultat degrade d avant, sans vitesse', () {
      final s = computeTrackStats(journeeReelle().sublist(0, 1));

      expect(s.distanceKm, 0);
      expect(s.elevationGainM, 0);
      expect(s.duration, Duration.zero);
      expect(s.maxAltitudeM, 600);
      expect(s.pointCount, 1);
      expect(s.hasData, isFalse);
      expect(s.averageSpeedKmh, isNull);
    });
  });

  group('671-06 (2) — la surcharge d adaptation convertit, elle ne calcule '
      'rien', () {
    test('les points enregistres rendent EXACTEMENT ce que rend l entree '
        'legere nourrie des memes valeurs et de la meme duree', () {
      final points = journeeReelle();
      final viaAdaptation = computeTrackStats(points);
      final direct = computeTrackStatsOn([
        for (final p in points) (lat: p.lat, lng: p.lng, altitude: p.altitude),
      ], duration: points.last.recordedAt.difference(points.first.recordedAt));

      expect(viaAdaptation.distanceKm, direct.distanceKm);
      expect(viaAdaptation.elevationGainM, direct.elevationGainM);
      expect(viaAdaptation.elevationLossM, direct.elevationLossM);
      expect(viaAdaptation.duration, direct.duration);
      expect(viaAdaptation.maxAltitudeM, direct.maxAltitudeM);
      expect(viaAdaptation.pointCount, direct.pointCount);
      expect(viaAdaptation.averageSpeedKmh, direct.averageSpeedKmh);
    });

    test(
      'LA DUREE VIENT DE L APPELANT : la geometrie seule n en porte pas',
      () {
        const geometry = <StatsPoint>[
          (lat: 42.0, lng: 9.0, altitude: 600),
          (lat: 42.01, lng: 9.0, altitude: 650),
        ];
        final s = computeTrackStatsOn(geometry, duration: Duration.zero);
        final dated = computeTrackStatsOn(
          geometry,
          duration: const Duration(minutes: 30),
        );

        // Meme geometrie, memes metres ; la vitesse n'existe qu'avec un temps.
        expect(s.distanceKm, dated.distanceKm);
        expect(s.elevationGainM, 50);
        expect(s.averageSpeedKmh, isNull);
        expect(dated.duration, const Duration(minutes: 30));
        expect(dated.averageSpeedKmh, closeTo(2.22, 0.01));
      },
    );
  });
}
