import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/share/domain/share_service.dart';

/// Tests du ShareService (F7D-01) — carte pseudonyme, sans PII, opt-in.
void main() {
  const service = ShareService();

  group('opt-in obligatoire (prive par defaut)', () {
    test('sans opt-in : aucune carte generee (null)', () {
      final card = service.buildStageCard(
        optedIn: false,
        authorUidHash: 'deadbeefcafe',
        stageName: 'Etape 3',
        distanceKm: 12.4,
        elevationGainM: 800,
        durationSeconds: 14400,
      );
      expect(card, isNull);
    });

    test('avec opt-in : carte generee', () {
      final card = service.buildStageCard(
        optedIn: true,
        authorUidHash: 'deadbeefcafe',
        stageName: 'Etape 3',
        distanceKm: 12.4,
        elevationGainM: 800,
        durationSeconds: 14400,
      );
      expect(card, isNotNull);
      expect(card!.stageName, 'Etape 3');
      expect(card.distanceKm, 12.4);
    });
  });

  group('pseudonymat / minimisation (pas de PII)', () {
    test('pseudonyme derive du hash, jamais nom reel ni "anonyme"', () {
      final card = service.buildStageCard(
        optedIn: true,
        authorUidHash: 'deadbeefcafe1234',
        stageName: 'Etape 3',
        distanceKm: 10,
        elevationGainM: 500,
        durationSeconds: 3600,
      );
      expect(card!.pseudonym, 'rndr-deadbeef');
      expect(card.pseudonym.toLowerCase().contains('anonym'), isFalse);
    });

    test('un email glisse dans un libelle est neutralise (minimisation)', () {
      final card = service.buildStageCard(
        optedIn: true,
        authorUidHash: 'hash1234',
        stageName: 'Etape de jean.dupont@mail.com',
        distanceKm: 10,
        elevationGainM: 500,
        durationSeconds: 3600,
        badgeTitle: 'contact: a@b.fr Expert',
      );
      expect(card!.stageName.contains('@'), isFalse);
      expect(card.badgeTitle!.contains('@'), isFalse);
    });

    test('la carte ne porte AUCUN champ de trace fine (stats agregees A4-2)',
        () {
      final card = service.buildStageCard(
        optedIn: true,
        authorUidHash: 'hash1234',
        stageName: 'Etape 3',
        distanceKm: 10,
        elevationGainM: 500,
        durationSeconds: 3600,
      );
      // Le modele n'expose que des stats agregees + pseudonyme.
      expect(card, isNotNull);
      expect(card!.distanceKm, 10);
      expect(card.elevationGainM, 500);
      expect(card.durationSeconds, 3600);
    });

    test('hash vide -> pseudonyme de repli neutre', () {
      expect(ShareService.pseudonymFromHash(''), 'rndr-0000');
    });
  });
}
