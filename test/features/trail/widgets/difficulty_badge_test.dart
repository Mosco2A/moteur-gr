import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/theme/app_theme.dart';
import 'package:moteur_gr/domain/echelle_de_difficulte.dart';
import 'package:moteur_gr/features/trail/widgets/difficulty_badge.dart';

/// Tests de la pastille de difficulte — QUATRE niveaux depuis la tache 852.
///
/// CE QUE CE FICHIER A FIGE TOUR A TOUR, ET POURQUOI IL A FALLU LE REECRIRE
/// DEUX FOIS.
///
///  - AVANT LA 848 il verifiait quatre cles de chaine (`easy`, `moderate`,
///    `hard`, `expert`) et, en dernier cas, que la cle `extreme` affichait
///    « extreme » en GRIS — c'est-a-dire qu'il figeait un TROU comme un
///    comportement attendu : la valeur que `tool/gr20_dans_stepways.py` produit
///    au-dela de 1 500 m de montee n'avait pas de couleur.
///  - LA 848 l'a porte a CINQ bandes, dont une « expert » en violet.
///  - LA 852 la supprime : Christophe, 17/10 17:25, verbatim
///    « facile/moyen/Difficile/tres difficile ». Quatre bandes, quatre
///    couleurs, et plus aucune cle du socle au-dessus de `hard`.
void main() {
  group('DifficultyBadge', () {
    Widget buildBadge(NiveauDeDifficulte niveau) {
      return MaterialApp(
        home: Scaffold(body: DifficultyBadge(niveau: niveau)),
      );
    }

    testWidgets('affiche le libelle de chacun des QUATRE niveaux', (
      tester,
    ) async {
      expect(NiveauDeDifficulte.values.length, 4);
      for (final niveau in NiveauDeDifficulte.values) {
        await tester.pumpWidget(buildBadge(niveau));
        expect(find.text(niveau.libelle), findsOneWidget);
      }
    });

    test('les quatre libelles sont ceux de la decision du 17/10 17:25', () {
      expect(NiveauDeDifficulte.facile.libelle, 'Facile');
      expect(NiveauDeDifficulte.moyen.libelle, 'Moyen');
      expect(NiveauDeDifficulte.difficile.libelle, 'Difficile');
      expect(NiveauDeDifficulte.tresDifficile.libelle, 'Tres difficile');
      expect(NiveauDeDifficulte.values.map((n) => n.libelle), <String>[
        'Facile',
        'Moyen',
        'Difficile',
        'Tres difficile',
      ]);
    });

    test(
      'la rampe de couleurs est celle du DENIVELE, et elle est monotone',
      () {
        // LES QUATRE COULEURS DU DESIGN DE LA FICHE SENTIER, exactement :
        // « vertFacile / jauneModere / orangeDifficile / rougeExtreme ». Le
        // violet du cinquieme cran est parti avec la bande expert.
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
      },
    );

    test('AUCUN niveau ne partage sa couleur avec un autre', () {
      // C'est la garantie qu'une jauge a quatre bandes se LIT : deux niveaux de
      // la meme couleur rendraient deux des quatre cases indistinguables.
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
      // « Tres difficile » n'existe pas dans le vocabulaire du socle : elle
      // tombe sur le cran du DESSOUS (`hard`). ET PLUS AUCUN NIVEAU NE DEMANDE
      // `expert` NI `extreme` : c'est la cle `extreme` qui s'affichait en gris
      // avec son mot brut a l'ecran, et la bande qui y menait n'existe plus.
      expect(NiveauDeDifficulte.facile.cleDuSocleApprochante, 'easy');
      expect(NiveauDeDifficulte.moyen.cleDuSocleApprochante, 'moderate');
      expect(NiveauDeDifficulte.difficile.cleDuSocleApprochante, 'hard');
      expect(NiveauDeDifficulte.tresDifficile.cleDuSocleApprochante, 'hard');
      final cles = NiveauDeDifficulte.values
          .map((n) => n.cleDuSocleApprochante)
          .toSet();
      expect(cles, <String>{'easy', 'moderate', 'hard'});
    });

    test('les rangs ordonnent du plus facile au plus dur', () {
      final rangs = NiveauDeDifficulte.values.map((n) => n.rang).toList();
      expect(rangs, <int>[0, 1, 2, 3]);
    });
  });
}
