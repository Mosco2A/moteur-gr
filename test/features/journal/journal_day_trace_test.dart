import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/features/journal/presentation/journal_screen.dart';
import 'package:moteur_gr/features/journal/providers/journal_day_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// CORRECTIF L4-2 — TRACE GPS DE LA JOURNEE AFFICHEE.
///
/// Le journal ne montrait aucune trace. Ce correctif branche la carte du
/// jour sur le socle L3-1 : c'est ce socle qui rend la trace d'une journee
/// PASSEE encore lisible (avant lui, elle etait effacee au demarrage de la
/// randonnee suivante).
void main() {
  const trailId = 'sentier-bleu';

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

  Future<void> traceAt(AppDatabase db, DateTime at, double lat) {
    return db.sessionTrackPointsDao.insertPoint(
      trailId: trailId,
      sessionId: 'session-a',
      dayIndex: 1,
      lat: lat,
      lng: 9.0,
      altitude: 900,
      recordedAt: at,
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

  group('L4-2 — trace du jour', () {
    test('la trace suit la journee selectionnee, pas le sentier entier',
        () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await noteAt(db, DateTime(2026, 6, 10, 9), 'Jour un');
      await noteAt(db, DateTime(2026, 6, 12, 9), 'Jour trois');
      await traceAt(db, DateTime(2026, 6, 10, 10), 42.10);
      await traceAt(db, DateTime(2026, 6, 10, 11), 42.11);
      await traceAt(db, DateTime(2026, 6, 12, 10), 42.30);

      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        // L7-3 : le journal est verrouille en mode demo ; ces tests
        // regardent le journal OUVERT, on le declare deverrouille.
        isDemoModeProvider(trailId).overrideWith((ref) async => false),
        trailIdProvider.overrideWithValue(trailId),
      ]);
      addTearDown(container.dispose);

      container.read(journalDaysProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Par defaut, la journee la plus recente : 1 point.
      var trace = await container.read(journalDayTraceProvider.future);
      expect(trace.length, 1);
      expect(trace.single.lat, 42.30);

      // On remonte au jour 1 : sa trace est TOUJOURS la (c'est le point du
      // socle L3-1) et elle porte bien 2 points.
      container
          .read(journalSelectedDayRawProvider.notifier)
          .select(DateTime(2026, 6, 10));
      trace = await container.read(journalDayTraceProvider.future);
      expect(trace.length, 2);
      expect(trace.first.lat, 42.10);
    });

    testWidgets('la carte du jour apparait quand la journee porte une trace',
        (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await noteAt(db, DateTime(2026, 6, 10, 9), 'Jour un');
      await traceAt(db, DateTime(2026, 6, 10, 10), 42.10);
      await traceAt(db, DateTime(2026, 6, 10, 11), 42.11);

      await pumpJournal(tester, db);

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.text(t.journal.dayTrace), findsOneWidget);
    });

    testWidgets('aucune carte quand la journee n a pas de trace',
        (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await noteAt(db, DateTime(2026, 6, 10, 9), 'Jour un sans GPS');

      await pumpJournal(tester, db);

      // Une carte vide au-dessus des notes ferait croire a une panne.
      expect(find.byType(FlutterMap), findsNothing);
      expect(find.text('Jour un sans GPS'), findsOneWidget);
    });
  });
}
