import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/gamification/data/defi_service.dart';
import 'package:moteur_gr/features/gamification/domain/defi_ranking.dart';
import 'package:moteur_gr/features/gamification/domain/defi_saisonnier.dart';
import 'package:moteur_gr/features/gamification/domain/user_stats.dart';
import 'package:moteur_gr/features/gamification/presentation/badge_gallery_screen.dart';
import 'package:moteur_gr/features/gamification/presentation/defi_screen.dart';
import 'package:moteur_gr/features/gamification/providers/gamification_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Tests widget de l'UI gamification (F7C-03) — galerie badges + defis.
void main() {
  Widget wrap(Widget child, {List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: overrides,
      child: TranslationProvider(child: MaterialApp(home: child)),
    );
  }

  void expectNoAnonyme(WidgetTester tester) {
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((w) => (w.data ?? '').toLowerCase());
    for (final s in texts) {
      expect(s.contains('anonym'), isFalse, reason: 'Texte interdit: "$s"');
    }
  }

  group('BadgeGalleryScreen', () {
    testWidgets('affiche badges obtenus et verrouilles selon les stats',
        (tester) async {
      await tester.pumpWidget(wrap(
        const BadgeGalleryScreen(),
        overrides: [
          // 1 etape -> first_stage obtenu ; le reste verrouille.
          userStatsProvider
              .overrideWithValue(const UserStats(stagesCompleted: 1)),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text(t.gamification.galleryTitle), findsOneWidget);
      // Au moins un "Obtenu" et un "Verrouille" coexistent.
      expect(find.text(t.gamification.obtained), findsWidgets);
      expect(find.text(t.gamification.locked), findsWidgets);
      expectNoAnonyme(tester);
    });
  });

  group('DefiScreen', () {
    DefiSaisonnier defi() => DefiSaisonnier(
          id: 'defi-1',
          titre: 'Defi printemps',
          description: 'Cumule du denivele',
          debut: DateTime.utc(2026, 3, 1),
          fin: DateTime.utc(2026, 5, 31),
          typeObjectif: DefiObjectif.denivele,
          cible: 3000,
        );

    testWidgets('affiche la progression locale + classement par tranche',
        (tester) async {
      final repo = InMemoryDefiRankingRepository()
        ..put(const DefiRanking(
          defiId: 'defi-1',
          tranches: [
            DefiRankingTranche(
              tranche: 'all',
              participantCount: 6,
              published: true,
              entries: [
                DefiRankingEntry(rank: 1, pseudonym: 'rndr-aaaa', value: 4200),
              ],
            ),
          ],
        ));
      await tester.pumpWidget(wrap(
        DefiScreen(defi: defi()),
        overrides: [
          userStatsProvider
              .overrideWithValue(const UserStats(totalElevationGainM: 1500)),
          defiRankingRepositoryProvider.overrideWithValue(repo),
        ],
      ));
      await tester.pumpAndSettle();

      // Notice pseudonyme + une entree pseudonyme.
      expect(find.text(t.gamification.defi.pseudonymNotice), findsOneWidget);
      expect(find.text('rndr-aaaa'), findsOneWidget);
      expectNoAnonyme(tester);
    });

    testWidgets('tranche < 5 : message k-anonymat', (tester) async {
      final repo = InMemoryDefiRankingRepository()
        ..put(const DefiRanking(
          defiId: 'defi-1',
          tranches: [
            DefiRankingTranche(
              tranche: 'all',
              participantCount: 3,
              published: false,
              entries: [],
            ),
          ],
        ));
      await tester.pumpWidget(wrap(
        DefiScreen(defi: defi()),
        overrides: [
          defiRankingRepositoryProvider.overrideWithValue(repo),
        ],
      ));
      await tester.pumpAndSettle();

      expect(
        find.text(t.gamification.defi.notEnoughParticipants),
        findsOneWidget,
      );
      expectNoAnonyme(tester);
    });
  });
}
