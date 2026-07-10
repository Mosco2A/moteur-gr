import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/map/domain/off_track_detector.dart';

/// Tests du coeur de decision hors-trace (F-OT, securite randonneur).
///
/// Dart pur, aucun binding Flutter : valide l'HYSTERESIS (entree / sortie /
/// retour), la zone morte anti-clignotement, les seuils par defaut et
/// parametrables, et le reset.
void main() {
  group('OffTrackDetector — seuils par defaut', () {
    test('defauts generiques 80 / 50 m', () {
      final d = OffTrackDetector();
      expect(d.exitThresholdMeters, 80.0);
      expect(d.returnThresholdMeters, 50.0);
    });

    test('etat initial = sur le trace', () {
      expect(OffTrackDetector().isOffTrack, isFalse);
    });

    test('assert si seuil retour >= seuil sortie (hysteresis invalide)', () {
      expect(
        () => OffTrackDetector(
          exitThresholdMeters: 50,
          returnThresholdMeters: 80,
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => OffTrackDetector(
          exitThresholdMeters: 60,
          returnThresholdMeters: 60,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('OffTrackDetector — transitions', () {
    late OffTrackDetector d;

    setUp(() => d = OffTrackDetector());

    test('SORTIE : au-dela du seuil de sortie -> enteredOffTrack (une fois)', () {
      expect(d.update(81), OffTrackTransition.enteredOffTrack);
      expect(d.isOffTrack, isTrue);
      // Rester au-dela ne re-declenche pas (UNE seule alerte).
      expect(d.update(120), OffTrackTransition.none);
      expect(d.update(200), OffTrackTransition.none);
    });

    test('pile au seuil de sortie (80 m) ne declenche pas (> strict)', () {
      expect(d.update(80), OffTrackTransition.none);
      expect(d.isOffTrack, isFalse);
    });

    test('RETOUR : sous le seuil de retour -> returnedOnTrack (une fois)', () {
      d.update(90); // hors trace
      expect(d.isOffTrack, isTrue);
      expect(d.update(49), OffTrackTransition.returnedOnTrack);
      expect(d.isOffTrack, isFalse);
      // Rester sous le seuil ne re-declenche pas.
      expect(d.update(10), OffTrackTransition.none);
    });

    test('pile au seuil de retour (50 m) ne repasse pas (< strict)', () {
      d.update(90);
      expect(d.update(50), OffTrackTransition.none);
      expect(d.isOffTrack, isTrue);
    });
  });

  group('OffTrackDetector — zone morte (anti-clignotement)', () {
    test('dans [50, 80] l etat ne bascule pas, quel que soit le sens', () {
      final d = OffTrackDetector();

      // Sur le trace : rester dans la zone morte ne bascule pas.
      expect(d.update(60), OffTrackTransition.none);
      expect(d.update(75), OffTrackTransition.none);
      expect(d.isOffTrack, isFalse);

      // Passer hors trace.
      expect(d.update(85), OffTrackTransition.enteredOffTrack);

      // Redescendre DANS la zone morte : reste hors trace (pas de clignotement).
      expect(d.update(70), OffTrackTransition.none);
      expect(d.update(55), OffTrackTransition.none);
      expect(d.isOffTrack, isTrue);

      // Il faut franchir 50 m pour revenir.
      expect(d.update(40), OffTrackTransition.returnedOnTrack);
      expect(d.isOffTrack, isFalse);
    });

    test('cycle complet sortie -> retour -> sortie', () {
      final d = OffTrackDetector();
      expect(d.update(100), OffTrackTransition.enteredOffTrack);
      expect(d.update(30), OffTrackTransition.returnedOnTrack);
      expect(d.update(95), OffTrackTransition.enteredOffTrack);
      expect(d.update(20), OffTrackTransition.returnedOnTrack);
    });
  });

  group('OffTrackDetector — seuils parametrables', () {
    test('seuils personnalises respectes (ex. sentier plus tolerant)', () {
      final d = OffTrackDetector(
        exitThresholdMeters: 150,
        returnThresholdMeters: 100,
      );
      expect(d.update(120), OffTrackTransition.none); // sous 150
      expect(d.update(160), OffTrackTransition.enteredOffTrack);
      expect(d.update(110), OffTrackTransition.none); // au-dessus de 100
      expect(d.update(90), OffTrackTransition.returnedOnTrack);
    });
  });

  group('OffTrackDetector — reset', () {
    test('reset repasse a sur-le-trace', () {
      final d = OffTrackDetector();
      d.update(100);
      expect(d.isOffTrack, isTrue);
      d.reset();
      expect(d.isOffTrack, isFalse);
      // Apres reset, une nouvelle sortie re-declenche.
      expect(d.update(100), OffTrackTransition.enteredOffTrack);
    });
  });
}
