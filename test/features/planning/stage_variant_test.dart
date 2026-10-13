import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/planning/models/stage_variant.dart';

void main() {
  StageVariant sample({
    String id = 'var-1',
    String etapeBaseId = 'etape-3',
    bool officielle = true,
    VariantDifficulty difficulte = VariantDifficulty.moyen,
  }) {
    return StageVariant(
      id: id,
      etapeBaseId: etapeBaseId,
      label: 'Officielle',
      distanceKm: 12.5,
      deniveleM: 650,
      difficulte: difficulte,
      traceGpxRef: 'assets/gpx/etape3_off.gpx',
      isOfficielle: officielle,
    );
  }

  group('StageVariant — serialisation Freezed', () {
    test('round-trip JSON conserve les champs', () {
      final v = sample(difficulte: VariantDifficulty.difficile);
      final json = v.toJson();
      final back = StageVariant.fromJson(json);
      expect(back, v);
      expect(back.difficulte, VariantDifficulty.difficile);
      expect(back.distanceKm, 12.5);
      expect(back.isOfficielle, isTrue);
    });

    test('difficulte serialisee avec le bon JsonValue', () {
      final json = sample(difficulte: VariantDifficulty.facile).toJson();
      expect(json['difficulte'], 'facile');
    });

    test('copyWith modifie un champ sans toucher aux autres', () {
      final v = sample();
      final modifie = v.copyWith(distanceKm: 9.0);
      expect(modifie.distanceKm, 9.0);
      expect(modifie.id, v.id);
      expect(modifie.deniveleM, v.deniveleM);
    });
  });

  group('VariantSelection — choix de variante pour le planning', () {
    test('selection par defaut est vide', () {
      const sel = VariantSelection();
      expect(sel.varianteChoisie('etape-3'), isNull);
    });

    test('selectionner met a jour le planning pour une etape', () {
      const sel = VariantSelection();
      final updated = sel.selectionner('etape-3', 'var-raccourci');
      expect(updated.varianteChoisie('etape-3'), 'var-raccourci');
      // L'etat initial reste immuable.
      expect(sel.varianteChoisie('etape-3'), isNull);
    });

    test('changer de variante remplace le choix precedent', () {
      final sel = const VariantSelection()
          .selectionner('etape-3', 'var-1')
          .selectionner('etape-3', 'var-2');
      expect(sel.varianteChoisie('etape-3'), 'var-2');
    });

    test('selections multiples sur des etapes differentes coexistent', () {
      final sel = const VariantSelection()
          .selectionner('etape-1', 'var-a')
          .selectionner('etape-2', 'var-b');
      expect(sel.varianteChoisie('etape-1'), 'var-a');
      expect(sel.varianteChoisie('etape-2'), 'var-b');
    });

    test('round-trip JSON de la selection', () {
      final sel = const VariantSelection().selectionner('etape-1', 'var-a');
      final back = VariantSelection.fromJson(sel.toJson());
      expect(back.varianteChoisie('etape-1'), 'var-a');
    });
  });
}
