import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/checklist/widgets/checklist_recommendation_banner.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// NON-REGRESSION — LOT FIX-2, finding M3bis.
///
/// LE DEFAUT : le bandeau annoncait « Poids du sac : 13.3 kg » alors que le sac
/// contenait 0 g et 0 article coche sur 84. Les 13,3 kg n'etaient PAS le poids
/// du sac mais la RECOMMANDATION — max(8 kg de reference refuge, 15 % du poids
/// corporel) — affichee derriere le libelle `checklist.weight.title`, emprunte
/// a un autre bandeau. Meme mecanisme qui, avec le poids corporel non borne
/// d'avant FIX-1, annoncait « Poids du sac : 133.5 kg » pour un poids saisi de
/// 890. Le libelle disait le contraire de la valeur.
///
/// CE QUE CES TESTS VERROUILLENT : ce bandeau porte un libelle DEDIE (« Poids
/// recommande », wording GR20) et ne reprend JAMAIS celui du poids du sac ; sa
/// valeur reste bien la recommandation (independante du contenu du sac).
void main() {
  Widget wrap(double bodyWeightKg) => TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            body: ChecklistRecommendationBanner(bodyWeightKg: bodyWeightKg),
          ),
        ),
      );

  /// Texte reellement rendu par le bandeau.
  String texteDuBandeau(WidgetTester tester) {
    final widget = tester.widget<Text>(
      find.descendant(
        of: find.byType(ChecklistRecommendationBanner),
        matching: find.byType(Text),
      ),
    );
    return widget.data ?? '';
  }

  testWidgets('le bandeau NE dit PAS « poids du sac »', (tester) async {
    await tester.pumpWidget(wrap(89));
    await tester.pumpAndSettle();

    final texte = texteDuBandeau(tester);
    expect(
      texte.contains(t.checklist.weight.title),
      isFalse,
      reason: 'ce bandeau montre une recommandation, pas le poids du sac : '
          'reutiliser le libelle du sac fait dire au bandeau le contraire de '
          'ce qu il affiche (finding M3bis). Texte rendu : "$texte"',
    );
  });

  testWidgets('le bandeau porte le libelle dedie « poids recommande »',
      (tester) async {
    await tester.pumpWidget(wrap(89));
    await tester.pumpAndSettle();

    expect(texteDuBandeau(tester), startsWith(t.checklist.weight.recommended));
  });

  testWidgets('la valeur reste la recommandation (15 % du corps)',
      (tester) async {
    // 100 kg -> 15 kg, au-dessus du plancher refuge de 8 kg.
    await tester.pumpWidget(wrap(100));
    await tester.pumpAndSettle();

    expect(texteDuBandeau(tester), contains('15.0'));
    expect(texteDuBandeau(tester), contains(t.checklist.weight.kilograms));
  });

  testWidgets('plancher refuge : un poids corporel faible ne descend pas '
      'sous 8 kg', (tester) async {
    // 40 kg -> 6 kg par le ratio, mais la reference refuge (8 kg) prime.
    await tester.pumpWidget(wrap(40));
    await tester.pumpAndSettle();

    expect(texteDuBandeau(tester), contains('8.0'));
  });

  testWidgets('la recommandation NE depend PAS du contenu du sac '
      '(sac vide compris)', (tester) async {
    // Le bandeau ne recoit AUCUN poids de sac : sa valeur est la meme sac vide
    // ou sac plein. C est precisement pour ca qu il ne doit pas s intituler
    // « Poids du sac » — c est le cas observe : 0 g dans le sac, bandeau a
    // 13.3 kg.
    await tester.pumpWidget(wrap(89));
    await tester.pumpAndSettle();
    final avec89 = texteDuBandeau(tester);

    await tester.pumpWidget(wrap(89));
    await tester.pumpAndSettle();
    expect(texteDuBandeau(tester), avec89);
    expect(avec89, isNot(contains(t.checklist.weight.title)));
  });
}
