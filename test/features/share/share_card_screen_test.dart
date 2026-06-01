import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/features/share/domain/share_card_generator.dart';
import 'package:moteur_gr/features/share/domain/share_card_template.dart';
import 'package:moteur_gr/features/share/presentation/share_card_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Test E3.6b : ecran de partage avec preview + templates.
///
/// Verifie que le ShareCardScreen affiche la preview image,
/// le selecteur de templates et le bouton partager.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  group("E3.6b ShareCardScreen", () {
    late ShareCardData testData;

    setUp(() {
      testData = ShareCardData(
        trailName: 'Volcans Trail',
        distanceKm: 72.0,
        elevationGain: 2420,
        date: DateTime(2026, 7, 15),
      );
    });

    testWidgets('affiche preview, templates et bouton partager',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
          ],
          child: TranslationProvider(
            child: MaterialApp(
              home: ShareCardScreen(data: testData),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verifie que le titre AppBar est present (Slang t.share.title)
      expect(find.text('Partager'), findsWidgets);

      // Verifie que le label apercu est present (Slang t.share.preview)
      expect(find.text('Aperçu'), findsOneWidget);

      // Verifie que les 3 templates sont affiches via ChoiceChip
      expect(find.text('Statistiques'), findsOneWidget);
      expect(find.text('Parcours'), findsOneWidget);
      expect(find.text('Étape'), findsOneWidget);

      // Verifie que le bouton partager est present
      expect(find.byIcon(Icons.share), findsOneWidget);

      // Verifie que le label choix template est present
      expect(find.text('Choisir un template'), findsOneWidget);

      // Verifie que le nom du sentier est affiche dans la preview
      expect(find.text('Volcans Trail'), findsOneWidget);

      // Verifie que la region est affichee
      expect(find.text('Auvergne'), findsOneWidget);

      // Verifie que les 3 ChoiceChip sont presents
      expect(find.byType(ChoiceChip), findsNWidgets(3));
    });

    test('ShareCardTemplate a 3 valeurs', () {
      expect(ShareCardTemplate.values.length, 3);
      expect(ShareCardTemplate.values, contains(ShareCardTemplate.stats));
      expect(ShareCardTemplate.values, contains(ShareCardTemplate.journey));
      expect(ShareCardTemplate.values, contains(ShareCardTemplate.stage));
    });
  });
}
