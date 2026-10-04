// T1 (VOLET ECRANS) — AVEC UNE OBSERVABILITE EN PANNE, CHAQUE ECRAN DE
// L'APPLICATION S'AFFICHE QUAND MEME (lot 645-09).
//
// POURQUOI CE TEST MONTE L'APPLICATION REELLE ET NE CONSTRUIT PAS LES ECRANS A
// LA MAIN. C'est la lecon du LOT V, ecrite en tete de `parcours_reel.dart` :
// un test qui instancie un ecran prouve que la classe compile, pas qu'un
// randonneur l'atteint. Le lot 645-09 a pose une miette a l'ENTREE de 63
// ecrans, c'est-a-dire exactement sur le chemin que prend un doigt. On
// balaie donc les routes du VRAI routeur, avec les VRAIS providers.
//
// LA PANNE SIMULEE EST CELLE D'AUJOURD'HUI, EN PIRE. Sur un telephone,
// Firebase est indisponible 100 pct du temps : le service est alors inerte et
// ne leve rien. Ici on fait PIRE que la realite — un puits qui leve a chaque
// geste, sur chaque cle et chaque miette — parce qu'une garde doit tenir au
// cas defavorable, pas au cas courant. C'est la panne qu'on verrait avec des
// services Google Play trop vieux, ou une application native injoignable.
//
// COMMENT IL ROUGIRAIT. Retirez un `try` du raccord `observeScreenEntry`, ou
// mettez un `await` bloquant sur le chemin d'un `build()`, et les ecrans
// cessent de s'afficher — ou l'exception du faux puits remonte dans l'arbre
// et se retrouve dans les erreurs de rendu, que ce test lit.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/analytics/analytics_service.dart';

import '../structurel/parcours_reel.dart';

/// Le cri du faux puits. Il est reconnaissable EXPRES : le test verifie qu'il
/// n'apparait dans AUCUNE erreur de rendu, donc qu'il n'a jamais traverse.
const criDuFauxPuits = 'OBSERVABILITE EN PANNE (garde 645-09)';

/// Un puits crash qui leve a chaque geste, sur chaque cle et chaque miette.
class _PuitsEnPanne implements CrashSink {
  @override
  Future<void> log(String message) async => throw StateError(criDuFauxPuits);
  @override
  Future<void> setCustomKey(String key, String value) async =>
      throw StateError(criDuFauxPuits);
  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required bool fatal,
  }) async => throw StateError(criDuFauxPuits);
  @override
  Future<void> setCollectionEnabled(bool enabled) async =>
      throw StateError(criDuFauxPuits);
}

/// La surcharge qui met l'observabilite en panne pour tout l'arbre.
///
/// `List<Object>` et non `List<Override>` : le type `Override` n'est pas
/// exporte par l'API publique de Riverpod 3.3.2 (meme contrainte que le socle).
List<Object> get _observabiliteEnPanne => [
  analyticsServiceProvider.overrideWithValue(
    AnalyticsService(
      analytics: const NoOpAnalyticsSink(),
      crash: _PuitsEnPanne(),
    ),
  ),
];

void main() {
  testWidgets(
    'T1 — toutes les routes de l application s affichent, observabilite en panne',
    (tester) async {
      final muets = <String>[];
      final traversees = <String>[];
      var visitees = 0;

      for (final r in routesDeclarees()) {
        final concret = cheminConcret(r.gabarit);
        if (concret == null)
          continue; // trou de parametre, declare par le socle
        visitees++;

        await monterAppliReelle(
          tester,
          depart: concret,
          surcharges: _observabiliteEnPanne,
        );

        // L ECRAN S EST-IL AFFICHE ? Un ecran de cette application porte un
        // `Scaffold` : son absence veut dire que rien ne s est peint.
        if (find.byType(Scaffold).evaluate().isEmpty) {
          muets.add(concret);
        }

        // LE CRI DU FAUX PUITS A-T-IL TRAVERSE JUSQU A L ARBRE ?
        final erreurs = erreursDeRendu(
          tester,
        ).where((e) => e.contains(criDuFauxPuits)).toList();
        if (erreurs.isNotEmpty) {
          traversees.add('$concret : ${erreurs.first.split('\n').first}');
        }
      }

      await demonterAppli(tester);
      erreursDeRendu(tester);

      expect(
        visitees,
        greaterThanOrEqualTo(30),
        reason:
            'ce balayage ne visite presque plus rien : la lecture des routes '
            'est cassee, et la garde serait devenue muette',
      );
      expect(
        muets,
        isEmpty,
        reason:
            'CES ECRANS NE SE SONT PAS AFFICHES avec une observabilite en '
            'panne. Une miette qui coute un ecran est un defaut permanent : '
            'Firebase est indisponible 100 pct du temps aujourd hui.\n  '
            '${muets.join('\n  ')}',
      );
      expect(
        traversees,
        isEmpty,
        reason:
            'L EXCEPTION DU PUITS EST REMONTEE DANS L ARBRE. Elle doit etre '
            'avalee et journalisee localement, jamais propagee a l ecran.\n  '
            '${traversees.join('\n  ')}',
      );
    },
  );
}
