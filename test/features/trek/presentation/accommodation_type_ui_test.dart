import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/domain/models/stage_accommodation.dart';
import 'package:moteur_gr/features/trek/presentation/accommodation_type_ui.dart';
import 'package:moteur_gr/core/branding/stepways_icons.dart';

/// Tests finitions V8 F1 — AccommodationType String parametrique (#81752).
///
/// Contrat : une valeur de type inconnue du moteur est PRESERVEE telle
/// quelle (jamais ecrasee en refuge) ; seul son affichage utilise un
/// fallback generique (icone neutre + valeur brute en libelle).
void main() {
  group('AccommodationType String (#81752)', () {
    test('le modele preserve une valeur inconnue telle quelle', () {
      const accommodation = StageAccommodation(
        id: 'acc-x',
        stageId: 'stage-x',
        stageNumber: 1,
        nameFr: 'Cabane perchee du Sentier Bleu',
        type: 'cabane_perchee',
        lat: 45.0,
        lng: 3.0,
      );
      expect(accommodation.type, 'cabane_perchee');
    });

    test('round-trip JSON : type inconnu non altere', () {
      const accommodation = StageAccommodation(
        id: 'acc-x',
        stageId: 'stage-x',
        stageNumber: 1,
        nameFr: 'Cabane perchee',
        type: 'cabane_perchee',
        lat: 45.0,
        lng: 3.0,
      );
      final decoded =
          StageAccommodation.fromJson(accommodation.toJson());
      expect(decoded.type, 'cabane_perchee');
    });

    test('icone dediee pour chaque type connu', () {
      expect(
        accommodationTypeIcon(AccommodationTypeValues.refuge),
        StepwaysIcons.hebergement,
      );
      expect(
        accommodationTypeIcon(AccommodationTypeValues.bergerie),
        StepwaysIcons.nuitees,
      );
      expect(
        accommodationTypeIcon(AccommodationTypeValues.gite),
        StepwaysIcons.hebergement,
      );
      expect(
        accommodationTypeIcon(AccommodationTypeValues.hotel),
        StepwaysIcons.hebergement,
      );
      expect(
        accommodationTypeIcon(AccommodationTypeValues.camping),
        StepwaysIcons.foret,
      );
      expect(
        accommodationTypeIcon(AccommodationTypeValues.bivouac),
        StepwaysIcons.nuitees,
      );
    });

    test('icone generique pour type inconnu', () {
      expect(accommodationTypeIcon('cabane_perchee'), StepwaysIcons.hebergement);
    });

    test('libelle i18n pour type connu', () {
      expect(
        accommodationTypeLabel(AccommodationTypeValues.refuge),
        isNotEmpty,
      );
      expect(
        accommodationTypeLabel(AccommodationTypeValues.gite),
        isNot('gite'),
      );
    });

    test('libelle fallback = valeur brute pour type inconnu', () {
      expect(accommodationTypeLabel('cabane_perchee'), 'cabane_perchee');
    });
  });
}
