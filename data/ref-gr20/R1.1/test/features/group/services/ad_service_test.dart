import 'package:flutter_test/flutter_test.dart';
import 'package:g20_app/features/group/services/ad_service.dart';

void main() {
  group('AdService - shouldShowAd', () {
    test('retourne false pour index 0 (1er suiveur gratuit)', () {
      expect(
        AdService.shouldShowAd(followerIndex: 0, isPaid: false),
        isFalse,
      );
    });

    test('retourne false pour index 1 (2eme suiveur gratuit)', () {
      expect(
        AdService.shouldShowAd(followerIndex: 1, isPaid: false),
        isFalse,
      );
    });

    test('retourne true pour index 2 (3eme suiveur, pas paye)', () {
      expect(
        AdService.shouldShowAd(followerIndex: 2, isPaid: false),
        isTrue,
      );
    });

    test('retourne true pour index 5 (6eme suiveur, pas paye)', () {
      expect(
        AdService.shouldShowAd(followerIndex: 5, isPaid: false),
        isTrue,
      );
    });

    test('retourne false pour index 2+ si paye', () {
      expect(
        AdService.shouldShowAd(followerIndex: 2, isPaid: true),
        isFalse,
      );
      expect(
        AdService.shouldShowAd(followerIndex: 10, isPaid: true),
        isFalse,
      );
    });

    test('retourne false pour index 0 meme si paye', () {
      expect(
        AdService.shouldShowAd(followerIndex: 0, isPaid: true),
        isFalse,
      );
    });
  });
}
