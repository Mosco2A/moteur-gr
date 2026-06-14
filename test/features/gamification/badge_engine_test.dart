import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/gamification/domain/badge.dart';
import 'package:moteur_gr/features/gamification/domain/badge_engine.dart';
import 'package:moteur_gr/features/gamification/domain/user_stats.dart';

/// Tests du BadgeEngine (F7C-01) — evaluation LOCALE, debutant + expert.
void main() {
  const engine = BadgeEngine();

  Badge cat(String code, String tier) => Badge(
        id: code,
        code: code,
        titre: 'T',
        description: 'D',
        tier: tier,
        iconRef: 'icon',
      );

  final catalog = <Badge>[
    cat(BadgeCode.firstStage, BadgeTier.debutant),
    cat(BadgeCode.firstTrek, BadgeTier.debutant),
    cat(BadgeCode.firstSegment, BadgeTier.debutant),
    cat(BadgeCode.elevation5000, BadgeTier.expert),
    cat(BadgeCode.tenStages, BadgeTier.expert),
    cat(BadgeCode.challenger, BadgeTier.expert),
  ];

  Map<String, Badge> byCode(List<Badge> badges) =>
      {for (final b in badges) b.code: b};

  group('isEarned — regles distinctes debutant / expert', () {
    test('debutant : 1re etape obtient first_stage', () {
      expect(
        BadgeEngine.isEarned(BadgeCode.firstStage,
            const UserStats(stagesCompleted: 1)),
        isTrue,
      );
    });

    test('expert : denivele >= 5000 obtient elevation_5000', () {
      expect(
        BadgeEngine.isEarned(BadgeCode.elevation5000,
            const UserStats(totalElevationGainM: 5000)),
        isTrue,
      );
      expect(
        BadgeEngine.isEarned(BadgeCode.elevation5000,
            const UserStats(totalElevationGainM: 4999)),
        isFalse,
      );
    });

    test('expert : 10 etapes obtient ten_stages', () {
      expect(
        BadgeEngine.isEarned(
            BadgeCode.tenStages, const UserStats(stagesCompleted: 10)),
        isTrue,
      );
      expect(
        BadgeEngine.isEarned(
            BadgeCode.tenStages, const UserStats(stagesCompleted: 9)),
        isFalse,
      );
    });

    test('code inconnu -> jamais attribue', () {
      expect(BadgeEngine.isEarned('inconnu', const UserStats()), isFalse);
    });
  });

  group('evaluateBadges — attribution locale', () {
    test('debutant : stats minimales obtiennent les badges debutant', () {
      const stats = UserStats(
        stagesCompleted: 1,
        treksCompleted: 1,
        segmentsCompleted: 1,
      );
      final result = byCode(
        engine.evaluateBadges(stats, catalog, now: DateTime.utc(2026, 6, 14)),
      );
      expect(result[BadgeCode.firstStage]!.isObtained, isTrue);
      expect(result[BadgeCode.firstTrek]!.isObtained, isTrue);
      expect(result[BadgeCode.firstSegment]!.isObtained, isTrue);
      // Pas encore expert.
      expect(result[BadgeCode.elevation5000]!.isObtained, isFalse);
      expect(result[BadgeCode.tenStages]!.isObtained, isFalse);
    });

    test('expert : gros cumul obtient les badges expert', () {
      const stats = UserStats(
        stagesCompleted: 12,
        totalElevationGainM: 6000,
        challengesWon: 2,
      );
      final result = byCode(
        engine.evaluateBadges(stats, catalog, now: DateTime.utc(2026, 6, 14)),
      );
      expect(result[BadgeCode.elevation5000]!.isObtained, isTrue);
      expect(result[BadgeCode.tenStages]!.isObtained, isTrue);
      expect(result[BadgeCode.challenger]!.isObtained, isTrue);
      // obtainedAt horodate.
      expect(result[BadgeCode.tenStages]!.obtainedAt, DateTime.utc(2026, 6, 14));
    });

    test('aucune realisation : tous verrouilles', () {
      final result = engine.evaluateBadges(const UserStats(), catalog);
      expect(result.every((b) => !b.isObtained), isTrue);
    });

    test('date d obtention anterieure conservee (idempotent)', () {
      final earlier = DateTime.utc(2026, 1, 1);
      final preObtained = [
        cat(BadgeCode.firstStage, BadgeTier.debutant)
            .copyWith(obtainedAt: earlier),
      ];
      final result = engine.evaluateBadges(
        const UserStats(stagesCompleted: 5),
        preObtained,
        now: DateTime.utc(2026, 6, 14),
      );
      // La date d origine est conservee, pas ecrasee.
      expect(result.first.obtainedAt, earlier);
    });

    test('regression : badge perdu repasse verrouille', () {
      final preObtained = [
        cat(BadgeCode.tenStages, BadgeTier.expert)
            .copyWith(obtainedAt: DateTime.utc(2026, 1, 1)),
      ];
      // Stats insuffisantes -> le badge n est plus gagne.
      final result = engine.evaluateBadges(
        const UserStats(stagesCompleted: 2),
        preObtained,
      );
      expect(result.first.isObtained, isFalse);
    });
  });
}
