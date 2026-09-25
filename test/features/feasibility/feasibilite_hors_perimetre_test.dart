import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_formula.dart';
import 'package:moteur_gr/features/feasibility/presentation/trek_feasibility_screen.dart';
import 'package:moteur_gr/features/feasibility/providers/trek_feasibility_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// CE QUE LE VERDICT NE REGARDE PAS — LA MENTION A ETE SUPPRIMEE (tache 552).
///
/// CE TEST A ETE RETOURNE, PAS SUPPRIME. Il verrouillait la PRESENCE de la
/// mention hors-perimetre sous le feu tricolore (« le poids de ton sac n'entre
/// pas dans ce feu, et c'est mesure : de 0 a 45 kg de charge, le verdict ne
/// bouge pas d'un cran »). Il verrouille desormais son ABSENCE — a l'ecran ET
/// dans les cinq fichiers de traduction, pour qu'elle ne puisse pas revenir par
/// la porte de l'i18n.
///
/// POURQUOI ELLE PART. Retour Chris du 25/09 : la phrase EXPLIQUE UNE ABSENCE
/// SANS RIEN CHANGER AU RESULTAT AFFICHE. C'est le compte rendu d'un test de
/// sensibilite interne (de 0 a 45 kg, verdict stable), pas une information de
/// randonneur — et elle ouvrait l'ecran sur du jargon. La regle posee, qui vaut
/// pour toute l'application : ON SE TAIT SUR CE QU'ON N'A PAS, ON PARLE DE CE
/// QUE CA CHANGE. Une absence qui MODIFIE un resultat reste affichee — c'est le
/// cas du bandeau hiver, qui declare le verdict non valide, et il est toujours
/// la, verifie ci-dessous. Une simple information absente disparait.
///
/// LE SAC N'A PAS DISPARU POUR AUTANT : il vit la ou il sert, dans le Sac (sac
/// conseille + alerte descente `ChecklistDescentAlert`), la ou le randonneur
/// peut agir dessus.
void main() {
  setUpAll(() => LocaleSettings.setLocaleRaw('fr'));

  StageEffort etape(int i, String nom, double dist, int elev) => StageEffort(
        index: i,
        name: nom,
        distanceKm: dist,
        elevationGainM: elev,
      );

  /// Trek exigeant : la pire journee depasse largement le plafond debutant.
  FeasibilityAssessment evaluationDure(HikerLevel niveau) =>
      FeasibilityFormula.evaluate(
        stages: [
          etape(0, 'Depart -> Col', 24, 1600),
          etape(1, 'Col -> Refuge', 12, 400),
        ],
        level: niveau,
      );

  /// Trek facile : toutes les etapes sont vertes, meme loin du plafond.
  FeasibilityAssessment evaluationFacile(HikerLevel niveau) =>
      FeasibilityFormula.evaluate(
        stages: [
          etape(0, 'Vallee', 10, 300),
          etape(1, 'Plateau', 8, 200),
        ],
        level: niveau,
      );

  Future<void> pumpEcran(
    WidgetTester tester,
    FeasibilityAssessment evaluation,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feasibilityAssessmentProvider.overrideWith((ref) async => evaluation),
          // Correctif N2 / D1 : le verdict n'est atteint qu'avec les criteres
          // au complet. Ce test porte sur la MENTION hors-perimetre, pas sur
          // la regle de declenchement (testee dans
          // faisabilite_correction_n2_test.dart) : on se place donc au complet.
          feasibilityCriteriaProvider.overrideWith((ref) async =>
              const FeasibilityCriteria(
                  profileComplete: true,
                  hasPastHike: true,
                  hasWalkTest: true)),
          hasObjectiveProfileProvider.overrideWith((ref) async => true),
        ],
        child: MaterialApp.router(
          locale: const Locale('fr'),
          routerConfig: GoRouter(
            initialLocation: '/',
            routes: [
              GoRoute(path: '/', builder: (_, __) => const TrekFeasibilityScreen()),
            ],
          ),
        ),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  /// Temoin d'ecran de la mention supprimee : son icone, unique dans l'ecran
  /// Faisabilite (`Icons.visibility_off_outlined` n'y servait qu'a elle).
  final temoinMention = find.byIcon(Icons.visibility_off_outlined);

  testWidgets('AUCUNE mention hors-perimetre sous un feu ROUGE',
      (tester) async {
    final rouge = evaluationDure(HikerLevel.beginner);
    expect(rouge.worstStageVerdict, FeasibilityVerdict.red);
    await pumpEcran(tester, rouge);
    expect(temoinMention, findsNothing);
    // Et rien n'est venu la remplacer par une autre formulation : aucun texte
    // de l'ecran ne parle plus de la charge mesuree hors perimetre.
    expect(find.textContaining('45 kg'), findsNothing);
  });

  testWidgets('AUCUNE mention hors-perimetre sous un feu VERT non plus',
      (tester) async {
    // C'etait le cas qu'on croyait dangereux : on pensait qu'un feu vert
    // obligeait a dire que le sac n'avait pas ete compte. Mesure faite, cette
    // phrase ne changeait AUCUN resultat — elle n'informait pas, elle se
    // couvrait. Elle part aussi d'ici.
    final verte = evaluationFacile(HikerLevel.expert);
    expect(verte.worstStageVerdict, FeasibilityVerdict.green);
    await pumpEcran(tester, verte);
    expect(temoinMention, findsNothing);
    expect(find.textContaining('45 kg'), findsNothing);
  });

  testWidgets('CE QUI MODIFIE un resultat, LUI, reste affiche : l hiver',
      (tester) async {
    // La contre-epreuve de la regle. « On se tait sur ce qu'on n'a pas, on
    // parle de ce que ca change » n'autorise pas a tout retirer : le depart en
    // hiver INVALIDE le verdict, donc il continue de s'afficher. Si ce test
    // tombe en meme temps que les deux precedents, c'est qu'on a confondu
    // « supprimer une promesse creuse » et « se taire sur un resultat ».
    expect(
      const TrekConditions(season: FeasibilitySeason.winter).isWinterDeparture,
      isTrue,
    );
    expect(t.feasibility.formula.winterInvalid.trim(), isNotEmpty);
  });

  test('la mention a quitte les CINQ fichiers de traduction', () {
    // GARDE-FOU DE NON-RETOUR. La cle `feasibility.formula.outOfScopeNotice`
    // est supprimee des cinq langues : ce test lit les fichiers eux-memes, donc
    // il tombe si quelqu'un la remet, meme sans la rebrancher a l'ecran.
    for (final langue in <String>['fr', 'en', 'de', 'es', 'it']) {
      final brut = File('assets/i18n/$langue.i18n.json').readAsStringSync();
      final racine = jsonDecode(brut) as Map<String, dynamic>;
      final formula = (racine['feasibility'] as Map<String, dynamic>)['formula']
          as Map<String, dynamic>;
      expect(formula.containsKey('outOfScopeNotice'), isFalse,
          reason: '$langue : la mention hors-perimetre est revenue dans '
              'assets/i18n/$langue.i18n.json');
    }
  });
}
