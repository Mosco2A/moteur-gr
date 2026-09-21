import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/after/presentation/adventure_recap_screen.dart';
import 'package:moteur_gr/features/after/providers/adventure_recap_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// CORRECTIF L5-3 — PARTAGE DU RECAPITULATIF D'AVENTURE.
///
/// Le recap n'offrait aucun partage. Ce qui est verrouille ici est ce qui
/// peut casser sans qu'on le voie : le TEXTE partage, et surtout le fait
/// qu'il reprend EXACTEMENT les lignes affichees a l'ecran.
void main() {
  setUp(() => LocaleSettings.setLocaleRaw('fr'));

  AdventureStats stats({
    int stagesWalked = 7,
    int totalStages = 7,
    double distanceKm = 84.0,
    int elevationGainM = 3750,
    int elevationLossM = 3600,
    int durationDays = 7,
  }) =>
      AdventureStats(
        stagesWalked: stagesWalked,
        totalStages: totalStages,
        distanceKm: distanceKm,
        elevationGainM: elevationGainM,
        elevationLossM: elevationLossM,
        startDate: DateTime(2026, 6, 10),
        endDate: DateTime(2026, 6, 16),
        durationDays: durationDays,
        fullyWalked: true,
        tracePoints: const [],
      );

  group('L5-3 — texte de partage', () {
    test('en-tete nomme le sentier, puis une ligne par chiffre', () {
      final text = buildAdventureShareText(
        trailName: 'Fra li Monti',
        stats: stats(),
        recapT: t.recap,
      );

      expect(text, contains('Fra li Monti'));
      expect(text, contains('84'));
      expect(text, contains('3750'));
      expect(text, contains('3600'));
      // Une ligne d'en-tete + 6 lignes de chiffres (dont les dates).
      expect(text.split('\n').length, 7);
    });

    test('le partage reprend EXACTEMENT les lignes affichees a l ecran', () {
      final s = stats();
      final rows = adventureRecapRows(s, t.recap);
      final text = buildAdventureShareText(
        trailName: 'Fra li Monti',
        stats: s,
        recapT: t.recap,
      );

      // Deux formatages separes finiraient par diverger, et le randonneur
      // partagerait des chiffres differents de ceux qu'il a sous les yeux.
      for (final row in rows) {
        expect(text, contains(row.label));
      }
    });

    test('sans dates de session, le texte reste coherent', () {
      const s = AdventureStats(
        stagesWalked: 0,
        totalStages: 7,
        distanceKm: 0,
        elevationGainM: 0,
        elevationLossM: 0,
        startDate: null,
        endDate: null,
        durationDays: 0,
        fullyWalked: false,
        tracePoints: [],
      );

      final text = buildAdventureShareText(
        trailName: 'Fra li Monti',
        stats: s,
        recapT: t.recap,
      );

      // En-tete + 5 lignes (pas de ligne de dates), et aucune ligne vide.
      expect(text.split('\n').length, 6);
      expect(text.split('\n').any((l) => l.trim().isEmpty), isFalse);
    });
  });
}
