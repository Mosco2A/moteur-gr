import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/daos/kudos_feed_dao.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/social/presentation/activity_feed_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Tests widget du fil d'activite (F7B-04).
///
/// Verifie : lecture depuis le cache local (offline-first), pseudonymes (pas
/// de PII), bouton kudos qui appelle le service, bouton "Signaler" present
/// (DSA), et ZERO occurrence du mot "anonyme".
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedActivities() async {
    final dao = KudosFeedDao(db);
    await dao.upsertActivities([
      ActivityFeedCacheCompanion.insert(
        id: 'act-1',
        type: 'segment_effort',
        authorUidHash: 'deadbeefcafe0001',
        createdAt: DateTime.utc(2026, 6, 14, 10),
        moderationState: const Value('visible'),
      ),
      ActivityFeedCacheCompanion.insert(
        id: 'act-removed',
        type: 'badge',
        authorUidHash: 'aaaabbbbcccc0002',
        createdAt: DateTime.utc(2026, 6, 14, 11),
        moderationState: const Value('removed'),
      ),
    ]);
  }

  Widget wrap({void Function(String, String)? onReport}) {
    return ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: TranslationProvider(
        child: MaterialApp(
          home: ActivityFeedScreen(
            currentUserUidHash: 'myhash000000',
            onReport: onReport,
          ),
        ),
      ),
    );
  }

  testWidgets('affiche les activites visibles du cache (pas les removed)',
      (tester) async {
    await seedActivities();
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text(t.social.feedTitle), findsOneWidget);
    // Pseudonyme derive de l UID hache, jamais nom reel.
    expect(find.text('rndr-deadbeef'), findsOneWidget);
    // L activite 'removed' n apparait pas (masquee DSA).
    expect(find.text('rndr-aaaabbbb'), findsNothing);
  });

  testWidgets('bouton kudos present et cliquable (cree un kudo local)',
      (tester) async {
    await seedActivities();
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    final kudosBtn = find.byKey(const ValueKey('kudos-act-1'));
    expect(kudosBtn, findsOneWidget);
    await tester.tap(kudosBtn);
    await tester.pumpAndSettle();

    // Le kudo a ete pose en local.
    final dao = KudosFeedDao(db);
    expect((await dao.pendingKudos()).length, 1);
  });

  testWidgets('bouton Signaler present (DSA art. 16)', (tester) async {
    await seedActivities();
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('report-act-1')), findsOneWidget);
    expect(find.text(t.social.report), findsWidgets);
  });

  testWidgets('le formulaire de signalement renvoie un motif (notice-and-action)',
      (tester) async {
    await seedActivities();
    String? reportedActivity;
    String? reportedReason;
    await tester.pumpWidget(wrap(onReport: (a, r) {
      reportedActivity = a;
      reportedReason = r;
    }));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('report-act-1')));
    await tester.pumpAndSettle();
    // Le formulaire s ouvre avec le bouton d envoi.
    expect(find.text(t.social.reportSend), findsOneWidget);
    await tester.tap(find.text(t.social.reportSend));
    await tester.pumpAndSettle();

    expect(reportedActivity, 'act-1');
    expect(reportedReason, isNotNull);
  });

  testWidgets('AUCUN texte visible ne contient le mot "anonyme" (R1)',
      (tester) async {
    await seedActivities();
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((w) => (w.data ?? '').toLowerCase());
    for (final s in texts) {
      expect(s.contains('anonym'), isFalse, reason: 'Texte interdit: "$s"');
    }
  });
}
