import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/features/share/domain/share_card_generator.dart';

/// Tests du générateur de cartes de partage avec branding dynamique.
void main() {
  group('ShareCardGenerator', () {
    test('cardSize vaut 1080 (format carré réseaux sociaux)', () {
      expect(ShareCardGenerator.cardSize, 1080);
    });

    test('pixelRatio vaut 3.0 (qualité retina)', () {
      expect(ShareCardGenerator.pixelRatio, 3.0);
    });
  });

  group('ShareCardBranding', () {
    test('brandingFromConfig extrait les couleurs dynamiquement', () {
      final branding = ShareCardGenerator.brandingFromConfig(testTrailConfig);

      expect(branding.primaryColor, Color(testTrailConfig.primaryColorValue));
      expect(branding.secondaryColor, Color(testTrailConfig.secondaryColorValue));
      expect(branding.trailName, testTrailConfig.displayName);
      expect(branding.region, testTrailConfig.region);
    });

    test('brandingFromConfig fonctionne avec une config arbitraire', () {
      const customConfig = TrailConfig(
        id: 'custom-trail',
        name: 'Custom Trail',
        displayName: 'Mon Sentier',
        tagline: 'Tagline test',
        totalStages: 3,
        totalDistanceKm: 42.0,
        totalElevationGain: 1500,
        region: 'Alps',
        country: 'Suisse',
        primaryColorValue: 0xFF0000FF,
        secondaryColorValue: 0xFFFF0000,
        gpxAssetPath: 'assets/gpx/custom.gpx',
      );

      final branding = ShareCardGenerator.brandingFromConfig(customConfig);

      expect(branding.primaryColor, const Color(0xFF0000FF));
      expect(branding.secondaryColor, const Color(0xFFFF0000));
      expect(branding.trailName, 'Mon Sentier');
      expect(branding.region, 'Alps');
    });

    test('gradientColors contient les 2 couleurs du branding', () {
      final branding = ShareCardGenerator.brandingFromConfig(testTrailConfig);
      final colors = branding.gradientColors;

      expect(colors.length, 2);
      expect(colors[0], Color(testTrailConfig.primaryColorValue));
      // Secondaire avec alpha 200
      expect((colors[1].a * 255.0).round(), 200);
    });

    test('logoAssetPath est null par défaut', () {
      final branding = ShareCardGenerator.brandingFromConfig(testTrailConfig);
      expect(branding.logoAssetPath, isNull);
    });
  });

  group('ShareCardData', () {
    test('constructeur avec champs obligatoires', () {
      final data = ShareCardData(
        trailName: 'Volcans Trail',
        distanceKm: 72.0,
        elevationGain: 2420,
        date: DateTime(2026, 7, 15),
      );

      expect(data.trailName, 'Volcans Trail');
      expect(data.distanceKm, 72.0);
      expect(data.elevationGain, 2420);
      expect(data.hasStageInfo, isFalse);
      expect(data.customMessage, isNull);
      expect(data.mapSnapshotBytes, isNull);
    });

    test('hasStageInfo true quand stageName et stageNumber présents', () {
      final data = ShareCardData(
        trailName: 'Test Trail',
        distanceKm: 12.5,
        elevationGain: 800,
        date: DateTime(2026, 7, 15),
        stageName: 'Col de Bavella',
        stageNumber: 3,
      );

      expect(data.hasStageInfo, isTrue);
    });

    test('hasStageInfo false quand stageName seul', () {
      final data = ShareCardData(
        trailName: 'Test Trail',
        distanceKm: 12.5,
        elevationGain: 800,
        date: DateTime(2026, 7, 15),
        stageName: 'Col de Bavella',
      );

      expect(data.hasStageInfo, isFalse);
    });

    test('dimensions carte respectent 1080x1080', () {
      // Vérifie que la constante cardSize garantit le format carré
      expect(ShareCardGenerator.cardSize, 1080);
      // Le ratio 1:1 est assuré par le AspectRatio(1) dans le screen
      // et la taille fixe de capture
      const expectedPixels = ShareCardGenerator.cardSize *
          ShareCardGenerator.cardSize;
      expect(expectedPixels, 1080 * 1080);
    });
  });
}
