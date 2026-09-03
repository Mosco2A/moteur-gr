import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/checklist/presentation/checklist_screen.dart';
import 'package:moteur_gr/features/checklist/widgets/checklist_bottom_actions.dart';
import 'package:moteur_gr/features/checklist/widgets/checklist_recommendation_banner.dart';
import 'package:moteur_gr/features/checklist/widgets/checklist_weight_banner.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Tests UI de PARITE : l'ecran StepWays reprend le NOM et les blocs de
/// l'ecran GR20 « Materiel & Sac ».
void main() {
  Widget wrap(AppDatabase db) => ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          trailConfigProvider.overrideWithValue(testTrailConfig),
        ],
        child: TranslationProvider(
          child: const MaterialApp(home: ChecklistScreen()),
        ),
      );

  testWidgets('le NOM de l ecran est celui de GR20 (Materiel & Sac)',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() async => db.close());

    await tester.pumpWidget(wrap(db));
    await tester.pumpAndSettle();

    // Titre GR20 dans l'AppBar (via Slang, base fr = « Materiel & Sac »).
    expect(find.text(t.checklist.title), findsOneWidget);
    expect(t.checklist.title.toLowerCase().contains('sac'), true,
        reason: 'le titre doit reprendre le nom GR20 « Sac »');
    // Aucun libelle « checklist » (ancien nom) visible a l'ecran.
    expect(find.textContaining('Checklist mat', findRichText: true),
        findsNothing);
  });

  testWidgets('les blocs GR20 sont presents (banniere poids, reco, actions)',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() async => db.close());

    await tester.pumpWidget(wrap(db));
    await tester.pumpAndSettle();

    expect(find.byType(ChecklistWeightBanner), findsOneWidget);
    expect(find.byType(ChecklistRecommendationBanner), findsOneWidget);
    expect(find.byType(ChecklistWeightGauge), findsOneWidget);
    expect(find.byType(ChecklistBottomActions), findsOneWidget);
    // Bouton de validation du sac (clone GR20 « VALIDER MON SAC »).
    expect(find.text(t.checklist.ui.validateBag), findsOneWidget);
    // Liste d'achat + partage groupe + export (boutons du bas GR20).
    expect(find.text(t.checklist.ui.shoppingListButton), findsOneWidget);
    expect(find.text(t.checklist.ui.shareGroup), findsOneWidget);
    expect(find.text(t.checklist.ui.exportList), findsOneWidget);
  });

  testWidgets('les 12 categories GR20 sont affichees', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() async => db.close());

    await tester.pumpWidget(wrap(db));
    await tester.pumpAndSettle();

    // Chaque nom de categorie (via Slang) apparait au moins une fois.
    for (final key in [
      'carrying',
      'sleeping',
      'clothing',
      'cooking',
      'foodWater',
      'hygiene',
      'firstAid',
      'electronics',
      'women',
      'men',
      'misc',
      'dog',
    ]) {
      final name = t['checklist.categories.$key'];
      expect(name is String, true);
      expect(find.text(name as String), findsWidgets,
          reason: 'categorie $key ($name) absente');
    }
  });
}
