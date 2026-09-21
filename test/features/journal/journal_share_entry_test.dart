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
import 'package:moteur_gr/features/journal/domain/models/journal_entry.dart';
import 'package:moteur_gr/features/journal/presentation/journal_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// CORRECTIF L4-4 — PARTAGE D'UNE ENTREE DE JOURNAL.
///
/// La feuille de partage du systeme n'est pas jouable en test unitaire ;
/// ce qui est verifie ici est ce qui PEUT casser sans qu'on le voie : le
/// texte partage, et la presence de l'action dans le menu de l'entree.
void main() {
  const trailId = 'sentier-bleu';

  setUp(() => LocaleSettings.setLocaleRaw('fr'));

  group('L4-4 — texte partage', () {
    test('en-tete date + etape, puis la note', () {
      final entry = JournalEntryModel(
        id: 1,
        trailId: trailId,
        stageNumber: 3,
        text: 'Le col de Laparo sous la grele.',
        createdAt: DateTime(2026, 6, 12, 17, 30),
      );

      final text = journalShareText(entry, t.journal);

      expect(text, contains('2026'));
      expect(text, contains(t.journal.stage));
      expect(text, contains('3'));
      expect(text, contains('Le col de Laparo sous la grele.'));
    });

    test('entree photo sans texte : en-tete seul, jamais une chaine vide', () {
      final entry = JournalEntryModel(
        id: 2,
        trailId: trailId,
        stageNumber: 1,
        text: '   ',
        photoPath: '/inexistant/photo.jpg',
        createdAt: DateTime(2026, 6, 10, 9),
      );

      final text = journalShareText(entry, t.journal);

      expect(text.trim(), isNotEmpty);
      expect(text, contains(t.journal.stage));
      // Pas de double saut de ligne suivi du vide.
      expect(text.endsWith('\n'), isFalse);
    });
  });

  group('L4-4 — action de partage dans le menu de l entree', () {
    testWidgets('le menu propose Partager en plus de Supprimer',
        (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await db.journalDao.insertEntry(
        JournalEntriesCompanion.insert(
          trailId: trailId,
          stageNumber: 1,
          content: const Value('Une note a partager'),
          createdAt: DateTime(2026, 6, 10, 9),
        ),
      );

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
                  GoRoute(
                      path: '/my-treks', builder: (_, __) => const SizedBox()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text(t.journal.share), findsOneWidget);
      expect(find.text(t.journal.delete), findsOneWidget);
    });
  });
}
