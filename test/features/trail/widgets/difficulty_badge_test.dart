import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/theme/app_theme.dart';
import 'package:moteur_gr/core/theme/couleurs_semantiques.dart';
import 'package:moteur_gr/domain/difficulte_du_sentier.dart';
import 'package:moteur_gr/features/trail/widgets/difficulty_badge.dart';

/// Tests de la pastille de difficulte — CINQ niveaux depuis la tache 848.
///
/// CE QUE CE FICHIER FIGEAIT AVANT, ET POURQUOI CA DEVAIT CHANGER. Il verifiait
/// quatre cles de chaine (`easy`, `moderate`, `hard`, `expert`) et, en dernier
/// cas, que la cle `extreme` affichait « extreme » en GRIS — c'est-a-dire qu'il
/// figeait un TROU comme un comportement attendu : la valeur que
/// `tool/gr20_dans_stepways.py` produit au-dela de 1 500 m de montee n'avait
/// pas de couleur. Aucune etape du GR20 ne depasse ce seuil, c'est pourquoi
/// personne ne l'avait vu a l'ecran.
///
/// L'echelle de Christophe (17/10) a cinq bandes, la pastille a donc cinq
/// couleurs, prises dans la famille « universelles pour le trek » du theme.
void main() {
  group('DifficultyBadge', () {
    Widget buildBadge(NiveauDeDifficulte niveau) {
      return MaterialApp(
        home: Scaffold(body: DifficultyBadge(niveau: niveau)),
      );
    }

    testWidgets('affiche le libelle de chacun des CINQ niveaux', (
      tester,
    ) async {
      for (final niveau in NiveauDeDifficulte.values) {
        await tester.pumpWidget(buildBadge(niveau));
        expect(find.text(niveau.libelle), findsOneWidget);
      }
    });

    test('les cinq libelles sont ceux de la decision du 17/10', () {
      expect(NiveauDeDifficulte.facile.libelle, 'Facile');
      expect(NiveauDeDifficulte.moyen.libelle, 'Moyen');
      expect(NiveauDeDifficulte.difficile.libelle, 'Difficile');
      expect(NiveauDeDifficulte.tresDifficile.libelle, 'Tres difficile');
      expect(NiveauDeDifficulte.expert.libelle, 'Expert');
    });

    test(
      'la rampe de couleurs est celle du DENIVELE, et elle est monotone',
      () {
        expect(
          DifficultyBadge.couleurDe(NiveauDeDifficulte.facile),
          AppTheme.vertFacile,
        );
        expect(
          DifficultyBadge.couleurDe(NiveauDeDifficulte.moyen),
          AppTheme.jauneModere,
        );
        expect(
          DifficultyBadge.couleurDe(NiveauDeDifficulte.difficile),
          AppTheme.orangeDifficile,
        );
        expect(
          DifficultyBadge.couleurDe(NiveauDeDifficulte.tresDifficile),
          AppTheme.rougeExtreme,
        );
        expect(
          DifficultyBadge.couleurDe(NiveauDeDifficulte.expert),
          CouleursSemantiques.violetDifficulteExpert,
        );
      },
    );

    test('AUCUN niveau ne partage sa couleur avec un autre', () {
      // C'est la garantie qu'une jauge a cinq bandes se LIT : deux niveaux de
      // la meme couleur rendraient deux des cinq cases indistinguables.
      final couleurs = NiveauDeDifficulte.values
          .map(DifficultyBadge.couleurDe)
          .toSet();
      expect(couleurs.length, NiveauDeDifficulte.values.length);
      expect(
        couleurs.contains(AppTheme.grisGranite),
        isFalse,
        reason: 'plus aucun niveau ne tombe dans le gris du defaut',
      );
    });

    test('la cle du socle APPROXIME, et elle ne sur-classe pas', () {
      // « Tres difficile » n'existe pas dans le vocabulaire a quatre valeurs du
      // socle : elle tombe sur le cran du DESSOUS (`hard`), jamais sur
      // `expert`, qui ferait passer pour expert un sentier qui ne l'est pas.
      expect(NiveauDeDifficulte.facile.cleDuSocleApprochante, 'easy');
      expect(NiveauDeDifficulte.moyen.cleDuSocleApprochante, 'moderate');
      expect(NiveauDeDifficulte.difficile.cleDuSocleApprochante, 'hard');
      expect(NiveauDeDifficulte.tresDifficile.cleDuSocleApprochante, 'hard');
      expect(NiveauDeDifficulte.expert.cleDuSocleApprochante, 'expert');
    });

    test('les rangs ordonnent du plus facile au plus dur', () {
      final rangs = NiveauDeDifficulte.values.map((n) => n.rang).toList();
      expect(rangs, <int>[0, 1, 2, 3, 4]);
    });
  });
}
