import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/planning/providers/planning_provider.dart';

/// MESURE — TACHE 651, N2-D2 : « LE NOMBRE DE JOURS ECRETE N'EST PAS DANS LES
/// OPTIONS DE `durationBoundsProvider` ».
///
/// C'ETAIT LA PISTE D'ARTEMIS pour expliquer la moitie rouge de la preuve N2 :
/// le bouton « Generer mon programme (N jours) » affiche
/// `bounds.clampDuration(suggestedPlanDays)`, et le harnais de preuve cherche ce
/// libelle en balayant `bounds.options`. Si l'ecretage sortait des options, le
/// harnais ne pourrait jamais reconnaitre le bouton et rapporterait
/// « introuvable » alors qu'il est a l'ecran.
///
/// CE QUE CETTE MESURE ETABLIT : la piste est FAUSSE, par construction, et ce
/// test le prouve au lieu de l'affirmer. `options` est la plage ENTIERE et
/// CONTIGUE `min..max`, et `clampDuration` borne justement a `min..max` : sa
/// sortie appartient donc TOUJOURS aux options, quelle que soit l'entree, y
/// compris negative, nulle ou absurde. Le « bouton introuvable » de N2-D2 a donc
/// une autre cause, qui n'est pas dans cet ecretage.
///
/// Ce test reste : c'est l'invariant sur lequel s'appuient le bouton, le
/// selecteur de duree et le harnais de preuve. Le jour ou `options` deviendrait
/// une liste a trous (durees « rondes », paliers), l'ecretage cesserait de
/// tomber dedans et la piste d'Artemis deviendrait vraie — il vaut mieux que ce
/// soit ce test qui le dise, et pas une campagne personas.
void main() {
  /// Nombres d'etapes couvrant les trois branches de la fabrique, dont 7 — le
  /// decoupage du sentier livre, celui de la preuve N2.
  const nombresDEtapes = <int>[0, 1, 2, 3, 5, 7, 12, 40];

  /// Budgets de repos conseilles par le moteur, y compris 0 et un budget qui
  /// depasse la marge naturelle (le cas ou la borne haute est remontee).
  const reposConseilles = <int>[0, 1, 2, 5, 20];

  test('N2-D2 — l ecretage tombe TOUJOURS dans les options du selecteur', () {
    for (final etapes in nombresDEtapes) {
      for (final repos in reposConseilles) {
        final bornes = DurationBounds.fromStageCount(
          etapes,
          recommendedRestDays: repos,
        );
        final options = bornes.options;

        // Les options sont la plage entiere et contigue min..max.
        expect(options.first, bornes.min);
        expect(options.last, bornes.max);
        expect(options.length, bornes.max - bornes.min + 1);

        // Et l'ecretage tombe dedans, pour toute entree imaginable.
        for (final demande in <int>[
          -5,
          0,
          1,
          bornes.min - 1,
          bornes.min,
          bornes.max,
          bornes.max + 1,
          9999,
        ]) {
          final ecrete = bornes.clampDuration(demande);
          expect(
            options,
            contains(ecrete),
            reason:
                'etapes=$etapes repos=$repos demande=$demande : '
                'l ecretage ($ecrete) doit etre une option du selecteur '
                '[${bornes.min}..${bornes.max}] — sinon le bouton '
                '« Generer mon programme » affiche une duree que le '
                'selecteur refuse d atteindre',
          );
        }
      }
    }
  });

  test(
    'N2-D2 — sentier livre (7 etapes) : les 8 jours conseilles sont proposables',
    () {
      // Le profil de la preuve N2 place le randonneur en debutant ; le moteur
      // conseille alors 8 jours de MARCHE la ou le sentier en compte 7.
      final bornes = DurationBounds.fromStageCount(7, recommendedRestDays: 2);
      expect(bornes.min, 4);
      expect(bornes.max, 9);
      expect(bornes.clampDuration(8), 8);
      expect(
        bornes.options,
        contains(8),
        reason:
            'la duree conseillee par le moteur doit etre atteignable par '
            'le selecteur : un conseil inapplicable serait un geste mort',
      );
    },
  );
}
