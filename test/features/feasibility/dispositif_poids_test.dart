import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/feasibility/domain/body_weight_reference.dart';
import 'package:moteur_gr/features/feasibility/domain/hiker_input_bounds.dart';
import 'package:moteur_gr/features/feasibility/domain/hiker_profile.dart';
import 'package:moteur_gr/features/feasibility/domain/walk_test_norms.dart';

/// LE DISPOSITIF POIDS ET LE DOMAINE DE VALIDITE DU TEST DE MARCHE
/// (§3.4, §4 et §5 de la spec finale #SW-FINAL, 22/09/2026).
///
/// C'est ici que vit le poids dans l'application : le moteur de faisabilite
/// n'en porte aucun terme (#1-b, #3-d). Les chiffres attendus ci-dessous sont
/// ceux DE LA SPEC, recopies depuis ses demonstrations — si le code s'en
/// ecarte, c'est le code qui a tort.
void main() {
  group('la reference : 25 x taille² (#4-a)', () {
    test('1,78 m -> 79,2 kg', () {
      expect(BodyWeightReference.referenceMassKg(178), closeTo(79.21, 0.01));
    });

    test('aucune reference sous 147 cm : on NE CALCULE PAS (#5-h)', () {
      expect(BodyWeightReference.referenceMassKg(146), isNull);
      expect(BodyWeightReference.referenceMassKg(130), isNull);
      // 60 cm est la nouvelle borne basse de saisie : elle rendrait 1,8 kg de
      // sac conseille, « un chiffre faux presente avec l autorite d un calcul ».
      expect(BodyWeightReference.referenceMassKg(kHeightMinCm), isNull);
      expect(BodyWeightReference.referenceMassKg(147), isNotNull);
    });

    test('la raison du repli est nommee, pour que l ecran puisse la dire', () {
      expect(BodyWeightReference.fallbackFor(0),
          WeightReferenceFallback.missingHeight);
      expect(BodyWeightReference.fallbackFor(130),
          WeightReferenceFallback.heightBelowReferenceDomain);
      expect(BodyWeightReference.fallbackFor(178), isNull);
    });
  });

  group('sortie 1 — le sac conseille (#4-b, #4-h)', () {
    test('LA DEMONSTRATION DE LA SPEC, a 1,78 m', () {
      // 120 kg : 24,0 kg conseilles avant, 15,8 kg apres. C est le defaut
      // corrige : on conseillait de porter d autant plus qu on portait deja
      // plus.
      expect(
        BodyWeightReference.recommendedBackpackKg(
            heightCm: 178, bodyWeightKg: 120),
        closeTo(15.84, 0.01),
      );
      // 70 kg : 14,0 avant, 14,0 apres — STRICTEMENT INCHANGE.
      expect(
        BodyWeightReference.recommendedBackpackKg(
            heightCm: 178, bodyWeightKg: 70),
        closeTo(14.0, 0.01),
      );
    });

    test('le min() sature proprement : meme plafond de 80 a 200 kg (#5-c)', () {
      final a = BodyWeightReference.recommendedBackpackKg(
          heightCm: 178, bodyWeightKg: 80);
      final b = BodyWeightReference.recommendedBackpackKg(
          heightCm: 178, bodyWeightKg: kWeightMaxKg.toDouble());
      expect(a, closeTo(b, 1e-9));
      expect(b, closeTo(15.84, 0.01));
    });

    test('sans reference, le plafond retombe sur le POIDS REEL (#5-h)', () {
      expect(
        BodyWeightReference.recommendedBackpackKg(
            heightCm: 130, bodyWeightKg: 55),
        closeTo(11.0, 1e-9),
      );
      // Et surtout PAS sur 20 % de 42,25 kg, qui vaudrait 8,5 kg.
      expect(
        BodyWeightReference.recommendedBackpackKg(
            heightCm: 130, bodyWeightKg: 55),
        isNot(closeTo(8.45, 0.01)),
      );
    });

    test('25 kg, nouvelle borne basse : rien ne change (#5-k)', () {
      // Chez un adulte de taille normale, min() rend le poids reel.
      expect(
        BodyWeightReference.recommendedBackpackKg(
            heightCm: 178, bodyWeightKg: kWeightMinKg.toDouble()),
        closeTo(5.0, 1e-9),
      );
    });

    test('le plancher refuge partage LE MEME denominateur (#7-f)', () {
      // Sans quoi la meme page se contredirait : un plafond calcule sur la
      // reference et un plancher calcule sur le poids reel.
      final base =
          BodyWeightReference.loadBaseKg(heightCm: 178, bodyWeightKg: 120);
      expect(
        BodyWeightReference.refugeBackpackKg(
            heightCm: 178, bodyWeightKg: 120),
        closeTo(0.15 * base, 1e-9),
      );
    });
  });

  group('le pourcentage affiche (#7-e)', () {
    test('LE CHIFFRE QUE CHRIS VERRA : 16,7 % -> 25,2 %, deux crans (#4-i)', () {
      // Un sac de 20 kg porte par un randonneur de 120 kg a 1,78 m.
      const avant = 20 / 120; // ancien denominateur : le poids reel
      final apres = BodyWeightReference.backpackRatio(
        heightCm: 178,
        bodyWeightKg: 120,
        backpackKg: 20,
      );
      expect(avant * 100, closeTo(16.7, 0.1));
      expect(apres * 100, closeTo(25.2, 0.1));
      // Orange (15-20 %) -> rouge fonce (>= 25 %) : DEUX crans d un coup.
      expect(avant * 100, lessThan(20));
      expect(apres * 100, greaterThanOrEqualTo(25));
    });

    test('base nulle ou sac non fini -> 0, jamais Infinity ni NaN', () {
      expect(
        BodyWeightReference.backpackRatio(
            heightCm: 178, bodyWeightKg: 0, backpackKg: 10),
        0,
      );
      expect(
        BodyWeightReference.backpackRatio(
            heightCm: 178, bodyWeightKg: 70, backpackKg: double.infinity),
        0,
      );
    });
  });

  group('sortie 2 — l alerte descente (#4-c, #4-l)', () {
    test('charge excedentaire = (poids − reference) + sac', () {
      // 1,78 m, reference 79,2 kg, 120 kg, sac 10 kg -> 40,8 + 10 = 50,8.
      expect(
        BodyWeightReference.excessLoadKg(
            heightCm: 178, bodyWeightKg: 120, backpackKg: 10),
        closeTo(50.79, 0.01),
      );
    });

    test('sous la reference, seul le sac compte', () {
      expect(
        BodyWeightReference.excessLoadKg(
            heightCm: 178, bodyWeightKg: 70, backpackKg: 8),
        closeTo(8.0, 1e-9),
      );
    });

    test('sans reference, AUCUN exces n est calcule — on n en invente pas', () {
      expect(
        BodyWeightReference.excessLoadKg(
            heightCm: 130, bodyWeightKg: 55, backpackKg: 8),
        isNull,
      );
      expect(
        BodyWeightReference.hasDescentAlert(
            heightCm: 130, bodyWeightKg: 55, backpackKg: 8),
        isFalse,
      );
    });

    test('sac vide et poids sous la reference -> pas d alerte', () {
      // Une alerte qui se declenche toujours n alerte plus.
      expect(
        BodyWeightReference.hasDescentAlert(
            heightCm: 178, bodyWeightKg: 70, backpackKg: 0),
        isFalse,
      );
    });
  });

  group('DOMAINE DE VALIDITE DU TEST DE MARCHE (#3-n) — le test est INTACT',
      () {
    HikerProfile profil({
      required int age,
      required int heightCm,
      required double weightKg,
      String? sex,
    }) =>
        HikerProfile(
            age: age, heightCm: heightCm, weightKg: weightKg, sex: sex);

    test('les coefficients d Enright sont INCHANGES (ARB-007 rejete, #3-a)',
        () {
      // 7,57 x taille − 5,02 x age − 1,76 x poids − 309, terme de poids
      // compris. Le test est le test.
      expect(
        WalkTestNorms.predictedMale(age: 50, heightCm: 178, weightKg: 75),
        closeTo(7.57 * 178 - 5.02 * 50 - 1.76 * 75 - 309, 1e-9),
      );
      expect(
        WalkTestNorms.predictedFemale(age: 50, heightCm: 165, weightKg: 62),
        closeTo(2.11 * 165 - 2.29 * 62 - 5.78 * 50 + 667, 1e-9),
      );
    });

    test('un profil du domaine est normalise, comme avant', () {
      final p = profil(age: 50, heightCm: 178, weightKg: 75, sex: HikerSex.male);
      expect(WalkTestNorms.isWithinDerivationDomain(p), isTrue);
      expect(WalkTestNorms.isNormalized(p), isTrue);
      expect(WalkTestNorms.ratioFor(p, 500), isNotNull);
    });

    test('L ABSURDITE QUE LE GARDE-FOU SUPPRIME : 130 cm, 200 kg (#3-m)', () {
      final p =
          profil(age: 50, heightCm: 130, weightKg: 200, sex: HikerSex.male);
      // La prediction brute serait positive et MINUSCULE (72,1 m) : une marche
      // mesuree a 300 m donnerait un rapport de 4,16, donc « excellent », donc
      // un cran de niveau NON MERITE.
      expect(
        WalkTestNorms.predictedMale(age: 50, heightCm: 130, weightKg: 200),
        closeTo(72.1, 0.1),
      );
      // Le garde-fou refuse d appliquer le test hors de son echantillon.
      expect(WalkTestNorms.isWithinDerivationDomain(p), isFalse);
      expect(WalkTestNorms.ratioFor(p, 300), isNull);
      // Repli sur l echelle absolue DEJA CODEE : 300 m -> faible, pas excellent.
      expect(WalkTestNorms.levelFor(p, 300), WalkTestLevel.low);
      // Et l ecran doit pouvoir le dire (#3-o).
      expect(WalkTestNorms.isNormalized(p), isFalse);
    });

    test('IMC > 35 hors domaine, IMC <= 35 dedans — critere PUBLIE d Enright',
        () {
      // 1,78 m : IMC 35 = 110,9 kg.
      final dedans =
          profil(age: 50, heightCm: 178, weightKg: 110, sex: HikerSex.male);
      final dehors =
          profil(age: 50, heightCm: 178, weightKg: 115, sex: HikerSex.male);
      expect(WalkTestNorms.isWithinDerivationDomain(dedans), isTrue);
      expect(WalkTestNorms.isWithinDerivationDomain(dehors), isFalse);
    });

    test('taille adulte < 147 cm hors domaine, meme a IMC normal', () {
      final p =
          profil(age: 50, heightCm: 140, weightKg: 45, sex: HikerSex.male);
      expect(p.bmi, lessThan(WalkTestNorms.maxBmi));
      expect(WalkTestNorms.isWithinDerivationDomain(p), isFalse);
    });

    test('120 ans : l age est CLAMPE a 80, aucun plantage (#5-j)', () {
      final a =
          WalkTestNorms.predictedMale(age: 120, heightCm: 178, weightKg: 75);
      final b =
          WalkTestNorms.predictedMale(age: 80, heightCm: 178, weightKg: 75);
      expect(a, closeTo(b, 1e-9));
      expect(a.isFinite, isTrue);
    });
  });
}
