import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/theme/app_skin.dart';
import 'package:moteur_gr/core/theme/app_theme.dart';
import 'package:moteur_gr/shared/widgets/app_data_stat.dart';

/// Tests widget d'AppDataStat (SW-SKIN-L5).
///
/// Couvre : le role data tabular (chiffres a chasse fixe), l'unite optionnelle,
/// la semantique ("label : value unit" + ExcludeSemantics du visuel), et la
/// bascule mono pilotee par la peau (Topographique).
void main() {
  Widget wrap({
    required Widget child,
    AppSkin skin = AppSkin.sentierVivant,
  }) {
    return MaterialApp(
      theme: AppTheme.buildLightTheme(
        primaryColor: const Color(0xFF2E7D32),
        secondaryColor: const Color(0xFF1565C0),
        skin: skin,
      ),
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('valeur en role data tabular (FontFeature tabularFigures)',
      (tester) async {
    await tester.pumpWidget(
      wrap(child: const AppDataStat(value: '12.4', unit: 'km', label: 'Distance')),
    );

    expect(find.text('12.4'), findsOneWidget);
    expect(find.text('km'), findsOneWidget);
    expect(find.text('Distance'), findsOneWidget);

    final valueText = tester.widget<Text>(find.text('12.4'));
    expect(
      valueText.style?.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
    expect(valueText.style?.fontWeight, FontWeight.w700);
  });

  testWidgets('valeur sans unite separee (unite incluse dans value)',
      (tester) async {
    await tester.pumpWidget(
      wrap(child: const AppDataStat(value: '350 m', label: 'D+')),
    );
    // Iso-rendu HUD : la valeur formatee "350 m" reste UN seul Text.
    expect(find.text('350 m'), findsOneWidget);
    expect(find.text('D+'), findsOneWidget);
  });

  testWidgets('semantique : un noeud "label : value unit", visuel exclu',
      (tester) async {
    await tester.pumpWidget(
      wrap(child: const AppDataStat(value: '840', unit: 'm', label: 'D+')),
    );

    // Le label semantique combine label + valeur + unite.
    expect(
      find.bySemanticsLabel('D+ : 840 m'),
      findsOneWidget,
    );
  });

  testWidgets('icone optionnelle rendue (teintee accent) — cas HUD',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        child: const AppDataStat(
          icon: Icons.straighten,
          value: '5.2 km',
          label: 'Distance',
        ),
      ),
    );
    expect(find.byIcon(Icons.straighten), findsOneWidget);
  });

  testWidgets('peau Topographique -> valeur en fonte monospace (cockpit)',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        skin: AppSkin.topographique,
        child: const AppDataStat(value: '2559', unit: 'm', label: 'Alt'),
      ),
    );

    final valueText = tester.widget<Text>(find.text('2559'));
    expect(valueText.style?.fontFamily, 'monospace');
    // Tabular conserve meme en mono.
    expect(
      valueText.style?.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  testWidgets('peau Sentier Vivant -> PAS de monospace (role data L1)',
      (tester) async {
    await tester.pumpWidget(
      wrap(child: const AppDataStat(value: '2559', unit: 'm', label: 'Alt')),
    );
    final valueText = tester.widget<Text>(find.text('2559'));
    expect(valueText.style?.fontFamily, isNot('monospace'));
  });
}
