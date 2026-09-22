import 'package:flutter_test/flutter_test.dart';
// Les constantes de bornes sont re-exportees par l'ecran (voir son `export`) :
// un seul import suffit, et l'analyse refuse le doublon.
import 'package:moteur_gr/features/feasibility/presentation/hiker_profile_screen.dart';

/// Tests du retour QA polish (P1) : l'IMC n'est calcule/affiche QUE lorsque la
/// saisie taille+poids est DANS LES BORNES metier (LOT 1). Toute saisie vide,
/// non numerique ou hors bornes doit rendre `null` (bloc IMC masque cote UI) —
/// fini l'IMC absurde sur une taille de 800.
///
/// Les bornes elles-memes ne sont PAS epinglees ici (elles le sont dans
/// `hiker_input_bounds_test.dart`) : ce fichier teste le MASQUAGE, pas les
/// valeurs. Il s'exprime donc en constantes, pour qu'un elargissement des
/// bornes — decisions Chris #100327 / #100328 — ne le fasse pas tomber a tort.
void main() {
  group('liveBmiWithinBounds — IMC masque tant que la saisie est invalide', () {
    test('null si taille ou poids manquant (saisie vide)', () {
      expect(liveBmiWithinBounds(null, 70), isNull);
      expect(liveBmiWithinBounds(175, null), isNull);
      expect(liveBmiWithinBounds(null, null), isNull);
    });

    test('null si taille hors bornes', () {
      // Cas concret rapporte par la QA : taille aberrante -> pas d'IMC.
      expect(liveBmiWithinBounds(800, 70), isNull);
      expect(liveBmiWithinBounds(kHeightMinCm - 1, 70), isNull);
      expect(liveBmiWithinBounds(kHeightMaxCm + 1, 70), isNull);
    });

    test('null si poids hors bornes', () {
      expect(liveBmiWithinBounds(175, kWeightMinKg - 1.0), isNull);
      expect(liveBmiWithinBounds(175, kWeightMaxKg + 1.0), isNull);
      expect(liveBmiWithinBounds(175, 3261), isNull);
    });

    test('IMC calcule des que taille ET poids sont dans les bornes', () {
      // 70 kg / 1.75 m -> 22.857...
      final bmi = liveBmiWithinBounds(175, 70);
      expect(bmi, isNotNull);
      expect(bmi!, closeTo(22.857, 0.01));
    });

    test('bornes incluses (valeurs limites valides)', () {
      expect(
          liveBmiWithinBounds(kHeightMinCm, kWeightMinKg.toDouble()), isNotNull);
      expect(
          liveBmiWithinBounds(kHeightMaxCm, kWeightMaxKg.toDouble()), isNotNull);
    });
  });
}
