import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/feasibility/presentation/hiker_profile_screen.dart';

/// Tests du retour QA polish (P1) : l'IMC n'est calcule/affiche QUE lorsque la
/// saisie taille+poids est DANS LES BORNES metier (LOT 1). Toute saisie vide,
/// non numerique ou hors bornes doit rendre `null` (bloc IMC masque cote UI) —
/// fini l'IMC absurde sur une taille de 800.
void main() {
  group('liveBmiWithinBounds — IMC masque tant que la saisie est invalide', () {
    test('null si taille ou poids manquant (saisie vide)', () {
      expect(liveBmiWithinBounds(null, 70), isNull);
      expect(liveBmiWithinBounds(175, null), isNull);
      expect(liveBmiWithinBounds(null, null), isNull);
    });

    test('null si taille hors bornes (100-250 cm)', () {
      // Cas concret rapporte par la QA : taille aberrante -> pas d'IMC.
      expect(liveBmiWithinBounds(800, 70), isNull);
      expect(liveBmiWithinBounds(99, 70), isNull); // juste sous la borne basse
      expect(liveBmiWithinBounds(251, 70), isNull); // juste au-dessus
    });

    test('null si poids hors bornes (30-150 kg)', () {
      expect(liveBmiWithinBounds(175, 29), isNull);
      expect(liveBmiWithinBounds(175, 151), isNull);
      expect(liveBmiWithinBounds(175, 3261), isNull);
    });

    test('IMC calcule des que taille ET poids sont dans les bornes', () {
      // 70 kg / 1.75 m -> 22.857...
      final bmi = liveBmiWithinBounds(175, 70);
      expect(bmi, isNotNull);
      expect(bmi!, closeTo(22.857, 0.01));
    });

    test('bornes incluses (valeurs limites valides)', () {
      expect(liveBmiWithinBounds(100, 30), isNotNull);
      expect(liveBmiWithinBounds(250, 150), isNotNull);
    });
  });
}
