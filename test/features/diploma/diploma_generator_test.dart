import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moteur_gr/features/diploma/domain/diploma_generator.dart';

/// Tests du générateur de diplôme.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  group('DiplomaGenerator', () {
    test('createDiploma génère les données correctes', () {
      final data = DiplomaGenerator.createDiploma(
        hikerName: 'Christophe',
        trailName: 'Fra li Monti',
        trailRegion: 'Corse',
        totalStages: 16,
        totalDistanceKm: 180.0,
        totalElevationGain: 12000,
        completionDate: DateTime(2026, 7, 30),
        durationDays: 14,
      );

      expect(data.hikerName, 'Christophe');
      expect(data.trailName, 'Fra li Monti');
      expect(data.trailRegion, 'Corse');
      expect(data.totalStages, 16);
      expect(data.totalDistanceKm, 180.0);
      expect(data.totalElevationGain, 12000);
      expect(data.durationDays, 14);
    });

    test('mainText contient le nom du randonneur', () {
      final data = DiplomaGenerator.createDiploma(
        hikerName: 'Jean',
        trailName: 'GR20',
        trailRegion: 'Corse',
        totalStages: 16,
        totalDistanceKm: 180.0,
        totalElevationGain: 12000,
        completionDate: DateTime(2026, 7, 30),
        durationDays: 14,
      );

      expect(data.mainText, contains('Jean'));
      expect(data.mainText, contains('GR20'));
      expect(data.mainText, contains('14 jours'));
      expect(data.mainText, contains('16 étapes'));
    });

    test('formattedDate est en français', () {
      final data = DiplomaGenerator.createDiploma(
        hikerName: 'Test',
        trailName: 'Test',
        trailRegion: 'Test',
        totalStages: 1,
        totalDistanceKm: 10.0,
        totalElevationGain: 500,
        completionDate: DateTime(2026, 7, 30),
        durationDays: 1,
      );

      expect(data.formattedDate, contains('2026'));
    });
  });
}
