import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/feedback/presentation/feedback_bottom_sheet.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Tests du bottom sheet de feedback.
///
/// Verifie la structure du formulaire (categories, champ texte,
/// etoiles, bouton envoyer) et les interactions utilisateur.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  /// Construit le widget sous test avec Riverpod, overrides et traductions.
  Widget buildSheet(AppDatabase database) {
    return ProviderScope(
      overrides: [
        trailConfigProvider.overrideWithValue(testTrailConfig),
        databaseProvider.overrideWithValue(database),
        connectivityProvider.overrideWith(
          (ref) => Stream.value(ConnectivityStatusValues.online),
        ),
      ],
      child: TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => FeedbackBottomSheet.show(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Ouvre le bottom sheet via le bouton declencheur.
  Future<void> openSheet(WidgetTester tester, AppDatabase database) async {
    await tester.pumpWidget(buildSheet(database));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('FeedbackBottomSheet', () {
    testWidgets('affiche le titre et les 3 categories', (tester) async {
      await openSheet(tester, db);

      // Titre visible
      expect(find.text('Feedback'), findsOneWidget);

      // Les 3 categories sont presentes (textes Slang fr par defaut)
      expect(find.widgetWithText(ChoiceChip, 'Bug / Problème'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Suggestion'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Compliment'), findsOneWidget);
    });

    testWidgets('affiche le champ message et le bouton envoyer', (tester) async {
      await openSheet(tester, db);

      // Champ de saisie du message
      expect(find.byType(TextFormField), findsOneWidget);

      // Bouton envoyer avec icone send
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('affiche 5 etoiles pour la note', (tester) async {
      await openSheet(tester, db);

      // 5 boutons etoile (toutes vides au depart)
      final starIcons = find.byIcon(Icons.star_border);
      expect(starIcons, findsNWidgets(5));
    });

    testWidgets('tap sur une etoile la remplit', (tester) async {
      await openSheet(tester, db);

      // Cliquer sur la 3e etoile
      final stars = find.byIcon(Icons.star_border);
      await tester.tap(stars.at(2));
      await tester.pump();

      // 3 etoiles pleines, 2 vides
      expect(find.byIcon(Icons.star), findsNWidgets(3));
      expect(find.byIcon(Icons.star_border), findsNWidgets(2));
    });

    testWidgets('selection de categorie change le chip actif', (tester) async {
      await openSheet(tester, db);

      // Par defaut Suggestion est selectionnee
      final suggestionChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Suggestion'),
      );
      expect(suggestionChip.selected, isTrue);

      // Tapper sur Bug
      await tester.tap(find.widgetWithText(ChoiceChip, 'Bug / Problème'));
      await tester.pump();

      // Bug est maintenant selectionnee
      final bugChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Bug / Problème'),
      );
      expect(bugChip.selected, isTrue);

      // Suggestion n est plus selectionnee
      final updatedSuggestion = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Suggestion'),
      );
      expect(updatedSuggestion.selected, isFalse);
    });

    testWidgets('show() ouvre un ModalBottomSheet', (tester) async {
      await openSheet(tester, db);

      // Le bottom sheet est affiche avec un FeedbackBottomSheet widget
      expect(find.byType(FeedbackBottomSheet), findsOneWidget);
    });
  });
}
