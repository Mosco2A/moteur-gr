import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/leaderboard/data/segment_ranking_repository.dart';
import 'package:moteur_gr/features/leaderboard/domain/segment_ranking.dart';
import 'package:moteur_gr/features/leaderboard/presentation/leaderboard_screen.dart';
import 'package:moteur_gr/features/leaderboard/providers/leaderboard_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Tests widget du leaderboard "Roi de l etape" (F7A-04).
///
/// Verifie : affichage par tranche depuis le cache (offline-first), masquage
/// k-anonymat (<5), libelles pseudonymes, et ZERO occurrence du mot "anonyme".
void main() {
  Widget wrap(SegmentRankingRepository repo, {String segmentId = 'seg-1'}) {
    return ProviderScope(
      overrides: [
        segmentRankingRepositoryProvider.overrideWithValue(repo),
      ],
      child: TranslationProvider(
        child: MaterialApp(home: LeaderboardScreen(segmentId: segmentId)),
      ),
    );
  }

  SegmentRanking ranking({
    required bool published,
    int entries = 6,
    String tranche = 'all',
  }) {
    return SegmentRanking(
      segmentId: 'seg-1',
      tranches: [
        RankingTranche(
          tranche: tranche,
          participantCount: published ? entries : 3,
          published: published,
          entries: published
              ? [
                  for (var i = 0; i < entries; i++)
                    RankingEntry(
                      rank: i + 1,
                      pseudonym: 'rndr-${i.toString().padLeft(8, '0')}',
                      durationSeconds: 600 + i,
                    ),
                ]
              : const [],
        ),
      ],
    );
  }

  testWidgets('tranche publiee : affiche les pseudonymes par tranche',
      (tester) async {
    final repo = InMemorySegmentRankingRepository()
      ..put(ranking(published: true));
    await tester.pumpWidget(wrap(repo));
    await tester.pumpAndSettle();

    // Entete pseudonyme + 1 entree pseudonyme au moins.
    expect(find.text(t.leaderboard.pseudonymNotice), findsOneWidget);
    expect(find.text('rndr-00000000'), findsOneWidget);
    // Pas de message k-anonymat quand publie.
    expect(find.text(t.leaderboard.notEnoughParticipants), findsNothing);
  });

  testWidgets('tranche < 5 : message k-anonymat, aucune entree',
      (tester) async {
    final repo = InMemorySegmentRankingRepository()
      ..put(ranking(published: false));
    await tester.pumpWidget(wrap(repo));
    await tester.pumpAndSettle();

    expect(find.text(t.leaderboard.notEnoughParticipants), findsOneWidget);
    expect(find.text('rndr-00000000'), findsNothing);
  });

  testWidgets('segment inconnu (cache vide) : etat vide', (tester) async {
    final repo = InMemorySegmentRankingRepository();
    await tester.pumpWidget(wrap(repo, segmentId: 'inconnu'));
    await tester.pumpAndSettle();

    expect(find.text(t.leaderboard.empty), findsOneWidget);
  });

  testWidgets('AUCUN texte visible ne contient le mot "anonyme" (R1)',
      (tester) async {
    final repo = InMemorySegmentRankingRepository()
      ..put(ranking(published: true));
    await tester.pumpWidget(wrap(repo));
    await tester.pumpAndSettle();

    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((w) => (w.data ?? '').toLowerCase());
    for (final s in texts) {
      expect(s.contains('anonym'), isFalse,
          reason: 'Texte interdit (R1): "$s"');
    }
  });
}
