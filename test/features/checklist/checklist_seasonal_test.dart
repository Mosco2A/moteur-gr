import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/checklist/data/checklist_seasonal_adapter.dart';
import 'package:moteur_gr/features/checklist/data/checklist_template.dart';
import 'package:moteur_gr/features/checklist/domain/season.dart';

/// Tests du SAC ADAPTATIF trek + saison (StepWays LOT 5, sous-ensemble B).
///
/// Verifie : la derivation de saison (date -> saison), les suggestions
/// externalisees par trek/saison, et surtout que la couche est ADDITIVE et
/// ne casse JAMAIS la parite (le template de base reste identique quand aucune
/// suggestion ne s'applique / est deja dans la base).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(ChecklistSeasonalAdapter.clearCache);

  group('Season.fromDate', () {
    test('mois -> saison hemisphere nord', () {
      expect(Season.fromDate(DateTime(2026, 1, 15)), Season.winter);
      expect(Season.fromDate(DateTime(2026, 4, 15)), Season.spring);
      expect(Season.fromDate(DateTime(2026, 7, 15)), Season.summer);
      expect(Season.fromDate(DateTime(2026, 10, 15)), Season.autumn);
      expect(Season.fromDate(DateTime(2026, 12, 25)), Season.winter);
    });
  });

  group('ChecklistSeasonalAdapter.seasonalItems', () {
    test('sentier + saison connus -> suggestions (mare-a-mare, ete)', () async {
      final items = await ChecklistSeasonalAdapter.seasonalItems(
        trailId: 'mare-a-mare-centre',
        season: Season.summer,
      );
      expect(items, isNotEmpty);
      // Le specifique sentier (eau renforcee) prime sur le default (par id).
      expect(items.any((i) => i.id == 'seasonalMamExtraWater'), isTrue);
    });

    test('sentier sans config -> uniquement le default de la saison', () async {
      final winter = await ChecklistSeasonalAdapter.seasonalItems(
        trailId: 'sentier-inconnu',
        season: Season.winter,
      );
      // Le bloc default hiver contient les microspikes.
      expect(winter.any((i) => i.id == 'seasonalMicrospikes'), isTrue);
    });
  });

  group('ChecklistSeasonalAdapter.resolveTemplate (parite preservee)', () {
    test('additive : base + extras, base jamais amputee', () async {
      final resolved = await ChecklistSeasonalAdapter.resolveTemplate(
        trailId: 'mare-a-mare-centre',
        season: Season.summer,
        base: defaultChecklistTemplate,
      );
      // Tous les articles de base sont conserves (aucun retrait = parite).
      for (final baseItem in defaultChecklistTemplate) {
        expect(resolved.any((i) => i.id == baseItem.id), isTrue);
      }
      // Et au moins un extra saisonnier a ete ajoute.
      expect(resolved.length, greaterThan(defaultChecklistTemplate.length));
    });

    test('saison sans donnee -> template de base identique (84 inchange)',
        () async {
      // 'spring' du bloc default n'a qu'un item, mais un sentier+saison sans
      // aucune donnee (ex. auton inexistant) doit rendre la base telle quelle.
      final resolved = await ChecklistSeasonalAdapter.resolveTemplate(
        trailId: 'sentier-inconnu',
        season: 'saison-inexistante',
        base: defaultChecklistTemplate,
      );
      expect(resolved.length, defaultChecklistTemplate.length);
      expect(identical(resolved, defaultChecklistTemplate), isTrue);
    });
  });
}
