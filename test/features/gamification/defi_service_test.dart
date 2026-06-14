import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/gamification/data/defi_service.dart';
import 'package:moteur_gr/features/gamification/domain/defi_ranking.dart';
import 'package:moteur_gr/features/gamification/domain/defi_saisonnier.dart';
import 'package:moteur_gr/features/gamification/domain/user_stats.dart';

/// Tests du DefiService (F7C-02) — progression LOCALE + classement cache.
void main() {
  DefiSaisonnier defi({
    String type = DefiObjectif.denivele,
    double cible = 3000,
  }) {
    return DefiSaisonnier(
      id: 'defi-printemps',
      titre: 'Defi',
      description: 'Desc',
      debut: DateTime.utc(2026, 3, 1),
      fin: DateTime.utc(2026, 5, 31),
      typeObjectif: type,
      cible: cible,
    );
  }

  group('localProgress — calcul LOCAL offline-first', () {
    test('denivele : progression depuis le cumul des stats', () {
      final service =
          DefiService(rankingRepository: InMemoryDefiRankingRepository());
      final p = service.localProgress(
        defi(type: DefiObjectif.denivele, cible: 3000),
        const UserStats(totalElevationGainM: 1500),
      );
      expect(p.current, 1500);
      expect(p.target, 3000);
      expect(p.ratio, 0.5);
      expect(p.isComplete, isFalse);
    });

    test('segments : progression depuis le nombre de segments', () {
      final service =
          DefiService(rankingRepository: InMemoryDefiRankingRepository());
      final p = service.localProgress(
        defi(type: DefiObjectif.segments, cible: 5),
        const UserStats(segmentsCompleted: 5),
      );
      expect(p.current, 5);
      expect(p.isComplete, isTrue);
      expect(p.ratio, 1.0);
    });

    test('ratio borne a 1 meme au-dela de la cible', () {
      final service =
          DefiService(rankingRepository: InMemoryDefiRankingRepository());
      final p = service.localProgress(
        defi(type: DefiObjectif.denivele, cible: 1000),
        const UserStats(totalElevationGainM: 5000),
      );
      expect(p.ratio, 1.0);
    });
  });

  group('isActiveAt — periode du defi', () {
    test('dans la periode = actif, hors periode = inactif', () {
      final d = defi();
      expect(d.isActiveAt(DateTime.utc(2026, 4, 15)), isTrue);
      expect(d.isActiveAt(DateTime.utc(2026, 1, 1)), isFalse);
      expect(d.isActiveAt(DateTime.utc(2026, 7, 1)), isFalse);
    });
  });

  group('ranking — lecture cache (calcul serveur, R2)', () {
    test('retourne le classement par tranche depuis le cache', () async {
      final repo = InMemoryDefiRankingRepository()
        ..put(const DefiRanking(
          defiId: 'defi-printemps',
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
      final service = DefiService(rankingRepository: repo);
      final r = await service.ranking('defi-printemps');
      expect(r, isNotNull);
      expect(r!.tranches.first.published, isTrue);
      expect(r.tranches.first.entries.first.pseudonym, 'rndr-aaaa');
    });

    test('defi inconnu -> null (cache vide hors-ligne)', () async {
      final service =
          DefiService(rankingRepository: InMemoryDefiRankingRepository());
      expect(await service.ranking('inconnu'), isNull);
    });
  });
}
