import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_formula.dart';
import 'package:moteur_gr/features/feasibility/presentation/trek_feasibility_screen.dart';
import 'package:moteur_gr/features/feasibility/providers/trek_feasibility_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// CE QUE LE VERDICT NE REGARDE PAS — decision Chris #100279 (21/09).
///
/// La campagne personas a mesure sur l'appareil que le poids du sac (de 0 a
/// 45 kg, soit 58 % du poids du corps) et la saison n'ont AUCUN effet sur le
/// verdict ni sur le plafond d'effort. Chris a tranche : ces deux dimensions
/// restent hors du calcul pour cette version, mais l'ecran doit le DIRE.
/// StepWays est une application de securite en montagne — croire qu'un sac de
/// 20 kg a ete pris en compte dans un feu vert est un risque reel.
///
/// Ces tests verrouillent : la mention est presente sur le verdict, QUEL QUE
/// SOIT le feu, et elle existe dans les cinq langues.
void main() {
  setUpAll(() => LocaleSettings.setLocaleRaw('fr'));

  StageEffort etape(int i, String nom, double dist, int elev) => StageEffort(
        index: i,
        name: nom,
        distanceKm: dist,
        elevationGainM: elev,
      );

  /// Trek exigeant : 40 km-effort sur la pire journee -> rouge pour un debutant.
  FeasibilityAssessment evaluationDure(HikerLevel niveau) =>
      FeasibilityFormula.evaluate(
        stages: [
          etape(0, 'Depart -> Col', 24, 1600),
          etape(1, 'Col -> Refuge', 12, 400),
        ],
        level: niveau,
      );

  /// Trek facile : 13 km-effort au pire -> vert meme loin du plafond.
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
    expect(rouge.globalVerdict, FeasibilityVerdict.red);
    await pumpEcran(tester, rouge);
    expect(find.text(t.feasibility.formula.outOfScopeNotice), findsOneWidget);
  });

  testWidgets('la mention est affichee AUSSI sous un feu VERT', (tester) async {
    // C'est le cas dangereux : un feu vert rassure, et c'est precisement la
    // qu'il faut dire que le sac n'a pas ete compte.
    final verte = evaluationFacile(HikerLevel.expert);
    expect(verte.globalVerdict, FeasibilityVerdict.green);
    await pumpEcran(tester, verte);
    expect(find.text(t.feasibility.formula.outOfScopeNotice), findsOneWidget);
  });

  test('la mention existe dans les cinq langues et nomme sac et saison', () {
    // Mots temoins par langue : la mention doit reellement parler du SAC et de
    // la SAISON, pas se contenter d'exister.
    const temoins = <AppLocale, List<String>>{
      AppLocale.fr: ['sac', 'saison'],
      AppLocale.en: ['pack', 'season'],
      AppLocale.de: ['Rucksack', 'Jahreszeit'],
      AppLocale.it: ['zaino', 'stagione'],
      AppLocale.es: ['mochila', 'estaci'],
    };
    for (final entree in temoins.entries) {
      final texte =
          entree.key.buildSync().feasibility.formula.outOfScopeNotice;
      expect(texte.trim(), isNotEmpty,
          reason: '${entree.key.languageCode} : mention vide');
      for (final mot in entree.value) {
        expect(texte.toLowerCase(), contains(mot.toLowerCase()),
            reason: '${entree.key.languageCode} : la mention ne parle pas de '
                '« $mot »');
      }
    }
  });
}
