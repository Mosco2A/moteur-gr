import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/features/journal/presentation/journal_screen.dart';
import 'package:moteur_gr/features/journal/providers/journal_day_providers.dart';
import 'package:moteur_gr/features/journal/providers/journal_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// CORRECTIF L4-1 — NAVIGATEUR PAR JOUR DU JOURNAL.
///
/// Avant ce correctif, l'ecran deroulait toutes les journees dans une seule
/// liste : il n'avait AUCUNE notion de jour selectionne. Ces tests verifient
/// que le journal se lit desormais UNE journee a la fois, et que les fleches
/// sont bornees aux extremites.
void main() {
  const trailId = 'sentier-bleu';

  /// Insere une note a une date CHOISIE (le repository, lui, horodate a
  /// `now` — inutilisable pour fabriquer trois journees distinctes).
  Future<void> noteAt(AppDatabase db, DateTime at, String text) {
    return db.journalDao.insertEntry(
      JournalEntriesCompanion.insert(
        trailId: trailId,
        stageNumber: 1,
        content: Value(text),
        createdAt: at,
      ),
    );
  }

  Future<void> pumpJournal(WidgetTester tester, AppDatabase db) async {
    LocaleSettings.setLocaleRaw('fr');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          // L7-3 : le journal est verrouille en mode demo ; ces tests
          // regardent le journal OUVERT, on le declare deverrouille.
          isDemoModeProvider(trailId).overrideWith((ref) async => false),
          trailIdProvider.overrideWithValue(trailId),
        ],
        child: TranslationProvider(
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/journal',
              routes: [
                GoRoute(
                  path: '/journal',
                  builder: (_, __) => const JournalScreen(trailId: trailId),
                ),
                GoRoute(path: '/my-treks', builder: (_, __) => const SizedBox()),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
  }

  group('L4-1 — navigateur par jour', () {
    testWidgets('une seule journee est affichee a la fois', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await noteAt(db, DateTime(2026, 6, 10, 9), 'Jour un du Mare a Mare');
      await noteAt(db, DateTime(2026, 6, 11, 9), 'Jour deux sous la pluie');
      await noteAt(db, DateTime(2026, 6, 12, 9), 'Jour trois au col');

      await pumpJournal(tester, db);

      // La journee la PLUS RECENTE ouvre le carnet.
      expect(find.text('Jour trois au col'), findsOneWidget);
      expect(find.text('Jour un du Mare a Mare'), findsNothing);
      expect(find.text('Jour deux sous la pluie'), findsNothing);
    });

    testWidgets('la fleche gauche remonte le temps, jour par jour',
        (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await noteAt(db, DateTime(2026, 6, 10, 9), 'Jour un du Mare a Mare');
      await noteAt(db, DateTime(2026, 6, 11, 9), 'Jour deux sous la pluie');
      await noteAt(db, DateTime(2026, 6, 12, 9), 'Jour trois au col');

      await pumpJournal(tester, db);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(find.text('Jour deux sous la pluie'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(find.text('Jour un du Mare a Mare'), findsOneWidget);

      // C'est LE point du correctif : on relit le jour 1 apres avoir
      // marche le jour 3.
      expect(find.text('Jour trois au col'), findsNothing);
    });

    testWidgets('les fleches sont desactivees aux extremites', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await noteAt(db, DateTime(2026, 6, 10, 9), 'Jour un');
      await noteAt(db, DateTime(2026, 6, 11, 9), 'Jour deux');

      await pumpJournal(tester, db);

      IconButton buttonOf(IconData icon) => tester.widget<IconButton>(
            find.ancestor(
              of: find.byIcon(icon),
              matching: find.byType(IconButton),
            ),
          );

      // Sur la journee la plus recente : suivant mort, precedent vivant.
      expect(buttonOf(Icons.chevron_right).onPressed, isNull);
      expect(buttonOf(Icons.chevron_left).onPressed, isNotNull);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      // Sur la plus ancienne : l'inverse.
      expect(buttonOf(Icons.chevron_left).onPressed, isNull);
      expect(buttonOf(Icons.chevron_right).onPressed, isNotNull);
    });

    testWidgets('journal vide : aucun navigateur, etat vide conserve',
        (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await pumpJournal(tester, db);

      expect(find.byIcon(Icons.chevron_left), findsNothing);
      expect(find.byIcon(Icons.book_outlined), findsOneWidget);
    });
  });

  group('L4-1 — repli de la journee choisie', () {
    test('la journee choisie disparait : repli sur la plus recente', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await noteAt(db, DateTime(2026, 6, 10, 9), 'Jour un');
      await noteAt(db, DateTime(2026, 6, 11, 9), 'Jour deux');

      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        // L7-3 : le journal est verrouille en mode demo ; ces tests
        // regardent le journal OUVERT, on le declare deverrouille.
        isDemoModeProvider(trailId).overrideWith((ref) async => false),
        trailIdProvider.overrideWithValue(trailId),
      ]);
      addTearDown(container.dispose);

      // Laisser le chargement initial aboutir.
      container.read(journalDaysProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(container.read(journalDaysProvider).length, 2);

      // On choisit le jour 1, puis ce jour cesse d'exister.
      container
          .read(journalSelectedDayRawProvider.notifier)
          .select(DateTime(2026, 6, 10));
      expect(container.read(journalSelectedDayProvider), DateTime(2026, 6, 10));

      await db.journalDao.deleteEntry(1);
      await container.read(journalScreenProvider.notifier).refresh();

      // Repli et non ecran blanc.
      expect(container.read(journalSelectedDayProvider), DateTime(2026, 6, 11));
    });
  });
}
