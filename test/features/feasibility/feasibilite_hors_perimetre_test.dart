import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_formula.dart';
import 'package:moteur_gr/features/feasibility/presentation/trek_feasibility_screen.dart';
import 'package:moteur_gr/features/feasibility/providers/trek_feasibility_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// CE QUE LE VERDICT NE REGARDE PAS — decision Chris #100279 (21/09),
/// MENTION COUPEE EN DEUX LE 22/09 (#8-a de la spec finale).
///
/// La campagne personas a mesure sur l'appareil que le poids du sac (de 0 a
/// 45 kg, soit 58 % du poids du corps) n'a AUCUN effet sur le verdict ni sur le
/// plafond d'effort. StepWays est une application de securite en montagne —
/// croire qu'un sac de 20 kg a ete pris en compte dans un feu vert est un
/// risque reel : la mention reste, et elle est devenue PERMANENTE.
///
/// LA MOITIE « SAISON » EST PARTIE, ET C'EST LE POINT DU JOUR. La saison entre
/// desormais dans le calcul : l'ete rabote la capacite de 7 % (source mesuree),
/// l'hiver rend le verdict NON VALIDE. Continuer a ecrire que « la saison
/// n'entre pas dans le calcul » ferait mentir l'ecran dans l'autre sens. Ces
/// tests verrouillent donc que la mention parle du SAC, ne parle PLUS de la
/// saison, et existe dans les cinq langues.
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

  testWidgets('la mention est affichee sous un feu ROUGE', (tester) async {
    final rouge = evaluationDure(HikerLevel.beginner);
    expect(rouge.worstStageVerdict, FeasibilityVerdict.red);
    await pumpEcran(tester, rouge);
    expect(find.text(t.feasibility.formula.outOfScopeNotice), findsOneWidget);
  });

  testWidgets('la mention est affichee AUSSI sous un feu VERT', (tester) async {
    // C'est le cas dangereux : un feu vert rassure, et c'est precisement la
    // qu'il faut dire que le sac n'a pas ete compte.
    final verte = evaluationFacile(HikerLevel.expert);
    expect(verte.worstStageVerdict, FeasibilityVerdict.green);
    await pumpEcran(tester, verte);
    expect(find.text(t.feasibility.formula.outOfScopeNotice), findsOneWidget);
  });

  test('la mention nomme le SAC dans les cinq langues', () {
    // Mots temoins par langue : la mention doit reellement parler du SAC, pas
    // se contenter d'exister.
    const temoins = <AppLocale, String>{
      AppLocale.fr: 'sac',
      AppLocale.en: 'pack',
      AppLocale.de: 'Rucksack',
      AppLocale.it: 'zaino',
      AppLocale.es: 'mochila',
    };
    for (final entree in temoins.entries) {
      final texte =
          entree.key.buildSync().feasibility.formula.outOfScopeNotice;
      expect(texte.trim(), isNotEmpty,
          reason: '${entree.key.languageCode} : mention vide');
      expect(texte.toLowerCase(), contains(entree.value.toLowerCase()),
          reason: '${entree.key.languageCode} : la mention ne parle pas du '
              'sac');
    }
  });

  test('la mention NE PARLE PLUS de la saison : elle entre dans le calcul',
      () {
    // Garde-fou de non-retour (#8-a). La saison est cablee depuis le 22/09 :
    // ete 0,93 (mesure), hiver verdict declare non valide. Reintroduire
    // « la saison n'entre pas dans le calcul » ferait mentir l'ecran.
    const interdits = <AppLocale, String>{
      AppLocale.fr: 'saison',
      AppLocale.en: 'season',
      AppLocale.de: 'Jahreszeit',
      AppLocale.it: 'stagione',
      AppLocale.es: 'estaci',
    };
    for (final entree in interdits.entries) {
      final texte =
          entree.key.buildSync().feasibility.formula.outOfScopeNotice;
      expect(texte.toLowerCase(), isNot(contains(entree.value.toLowerCase())),
          reason: '${entree.key.languageCode} : la mention parle encore de la '
              'saison alors que la saison entre dans le calcul');
    }
    // Et la saison est bien cablee, des deux cotes.
    expect(
      const TrekConditions(season: FeasibilitySeason.summer).heatFactor,
      closeTo(0.93, 1e-9),
    );
    expect(
      const TrekConditions(season: FeasibilitySeason.winter).isWinterDeparture,
      isTrue,
    );
  });
}
