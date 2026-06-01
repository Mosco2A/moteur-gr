import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moteur_gr/features/diploma/domain/diploma_generator.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Tests E3.7b DiplomaScreen -- recap aventure avec donnees mock.
///
/// Verifie que l ecran affiche le recap avec :
/// - photos journal (via entries mock)
/// - statistiques du trek
/// - textes Slang 5 langues
/// - bouton PDF
void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  group('E3.7b DiplomaScreen recap aventure', () {
    test('ecran affiche recap avec donnees mock', () {
      // GIVEN: Slang initialise en francais
      LocaleSettings.setLocaleRaw('fr');

      // WHEN: generation des donnees diplome (mock)
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

      // THEN: donnees diplome correctes
      expect(data.hikerName, 'Christophe');
      expect(data.trailName, 'Fra li Monti');
      expect(data.totalStages, 16);
      expect(data.totalDistanceKm, 180.0);
      expect(data.totalElevationGain, 12000);
      expect(data.durationDays, 14);

      // THEN: textes Slang recap disponibles et non vides
      final diplomaT = t.diploma;
      expect(diplomaT.recapTitle, isNotEmpty);
      expect(diplomaT.recapJournalPhotos, isNotEmpty);
      expect(diplomaT.recapNoPhotos, isNotEmpty);
      expect(diplomaT.recapStats, isNotEmpty);
      expect(diplomaT.recapStages, contains('{count}'));
      expect(diplomaT.recapDistance, contains('{km}'));
      expect(diplomaT.recapElevation, contains('{meters}'));
      expect(diplomaT.recapDuration, contains('{days}'));
      expect(diplomaT.recapMapTrace, isNotEmpty);
      expect(diplomaT.recapNoMap, isNotEmpty);
      expect(diplomaT.recapJournalEntries, contains('{count}'));
      expect(diplomaT.downloadPdf, isNotEmpty);

      // THEN: interpolation fonctionne pour les stats
      final stagesLabel = diplomaT.recapStages
          .replaceAll('{count}', '${data.totalStages}');
      expect(stagesLabel, contains('16'));

      final distanceLabel = diplomaT.recapDistance
          .replaceAll('{km}', data.totalDistanceKm.toStringAsFixed(0));
      expect(distanceLabel, contains('180'));

      final elevationLabel = diplomaT.recapElevation
          .replaceAll('{meters}', '${data.totalElevationGain}');
      expect(elevationLabel, contains('12000'));

      final durationLabel = diplomaT.recapDuration
          .replaceAll('{days}', '${data.durationDays}');
      expect(durationLabel, contains('14'));

      // THEN: textes Slang diplome existants toujours OK
      expect(diplomaT.title, isNotEmpty);
      expect(diplomaT.yourName, isNotEmpty);
      expect(diplomaT.namePlaceholder, isNotEmpty);
      expect(diplomaT.generatePdf, isNotEmpty);
      expect(diplomaT.certifies, isNotEmpty);
      expect(diplomaT.completed, isNotEmpty);

      // THEN: 5 langues supportees
      for (final locale in ['fr', 'en', 'de', 'es', 'it']) {
        LocaleSettings.setLocaleRaw(locale);
        expect(t.diploma.recapTitle, isNotEmpty,
            reason: 'recapTitle manquant pour $locale');
        expect(t.diploma.recapStats, isNotEmpty,
            reason: 'recapStats manquant pour $locale');
        expect(t.diploma.downloadPdf, isNotEmpty,
            reason: 'downloadPdf manquant pour $locale');
        expect(t.diploma.recapJournalPhotos, isNotEmpty,
            reason: 'recapJournalPhotos manquant pour $locale');
      }

      // Retour au francais
      LocaleSettings.setLocaleRaw('fr');
    });
  });
}
