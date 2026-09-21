import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/geo/track_segment_stats.dart';
import 'package:moteur_gr/features/after/presentation/adventure_recap_screen.dart';
import 'package:moteur_gr/features/after/providers/adventure_recap_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// CORRECTIF L5-6 — VITESSE MOYENNE, ET LE PIEGE QU'ELLE CACHE.
///
/// AdventureStats.distanceKm est une somme NOMINALE des distances d'etapes
/// completees, pas une distance MESUREE. La diviser par un temps reel ne
/// donne pas une vitesse de marche : elle donne un chiffre faux qui aura
/// l'air vrai. La vitesse affichee se calcule donc sur les MEMES points GPS
/// que la duree, ou ne s'affiche pas du tout.
void main() {
  setUp(() => LocaleSettings.setLocaleRaw('fr'));

  SessionTrackPoint point(DateTime at, double lat) => SessionTrackPoint(
        id: 0,
        trailId: 'sentier',
        lat: lat,
        lng: 9.0,
        altitude: 900,
        recordedAt: at,
      );

  group('L5-6 — la vitesse ne sort que des points mesures', () {
    test('vitesse plausible : elle est rendue', () {
      final base = DateTime(2026, 6, 10, 8);
      // ~2,22 km en 1 h -> environ 2,2 km/h, une allure de montagne.
      final stats = computeTrackStats([
        point(base, 42.000),
        point(base.add(const Duration(hours: 1)), 42.020),
      ]);

      expect(stats.averageSpeedKmh, isNotNull);
      expect(stats.averageSpeedKmh!, closeTo(2.2, 0.2));
    });

    test('duree nulle : AUCUNE vitesse plutot qu une division absurde', () {
      final at = DateTime(2026, 6, 10, 8);
      final stats = computeTrackStats([point(at, 42.0), point(at, 42.02)]);

      expect(stats.duration, Duration.zero);
      expect(stats.averageSpeedKmh, isNull);
    });

    test('saut de position GPS : rien plutot qu une vitesse de voiture', () {
      final base = DateTime(2026, 6, 10, 8);
      // 111 km en 10 minutes : un saut de position, pas de la marche.
      final stats = computeTrackStats([
        point(base, 42.0),
        point(base.add(const Duration(minutes: 10)), 43.0),
      ]);

      expect(stats.averageSpeedKmh, isNull);
    });

    test('moins de deux points : aucune vitesse', () {
      expect(computeTrackStats(const []).averageSpeedKmh, isNull);
      expect(
        computeTrackStats([point(DateTime(2026, 6, 10, 8), 42.0)])
            .averageSpeedKmh,
        isNull,
      );
    });
  });

  group('L5-6 — presentation', () {
    const stats = AdventureStats(
      stagesWalked: 3,
      totalStages: 7,
      distanceKm: 30,
      elevationGainM: 1500,
      elevationLossM: 1200,
      startDate: null,
      endDate: null,
      durationDays: 3,
      fullyWalked: false,
      tracePoints: [],
    );

    test('sans vitesse mesuree, AUCUNE ligne de vitesse n apparait', () {
      final rows = adventureRecapRows(stats, t.recap);
      expect(rows.any((r) => r.label.contains('km/h')), isFalse);
    });

    test('avec vitesse mesuree, la ligne apparait et part au partage', () {
      final rows = adventureRecapRows(stats, t.recap, averageSpeedKmh: 3.4);
      expect(rows.where((r) => r.label.contains('km/h')).length, 1);

      final text = buildAdventureShareText(
        trailName: 'Fra li Monti',
        stats: stats,
        recapT: t.recap,
        averageSpeedKmh: 3.4,
      );
      expect(text, contains('3.4'));
    });
  });
}
