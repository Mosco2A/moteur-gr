import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/theme/app_skin.dart';
import 'package:moteur_gr/core/theme/skin_provider.dart';
import 'package:moteur_gr/features/settings/presentation/skin_selector.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests widget SW-SKIN-L7 — selecteur de peau (3 tuiles, grisage Grand Air,
/// tap -> changement de peau).
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    LocaleSettings.setLocaleRaw('fr');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// Enveloppe le selecteur sous ProviderScope + Slang + MaterialApp.
  Widget harness({bool grandAirEligible = false}) {
    return ProviderScope(
      overrides: [
        trailHasCoverPhotosProvider.overrideWithValue(grandAirEligible),
      ],
      child: TranslationProvider(
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: SkinSelector()),
          ),
        ),
      ),
    );
  }

  testWidgets('affiche les 3 tuiles de peau (noms Slang)', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text(t.appearance.skinSentierVivant), findsOneWidget);
    expect(find.text(t.appearance.skinTopographique), findsOneWidget);
    expect(find.text(t.appearance.skinGrandAir), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Grand Air NON eligible : explication « indisponible » affichee',
      (tester) async {
    await tester.pumpWidget(harness(grandAirEligible: false));
    await tester.pumpAndSettle();

    // L'explication d'inéligibilité est visible (jamais masquer le choix).
    expect(find.text(t.appearance.unavailableOnTrail), findsOneWidget);
  });

  testWidgets('Grand Air eligible : pas d\'explication d\'indisponibilite',
      (tester) async {
    await tester.pumpWidget(harness(grandAirEligible: true));
    await tester.pumpAndSettle();

    expect(find.text(t.appearance.unavailableOnTrail), findsNothing);
  });

  testWidgets('tap sur Topographique change la peau selectionnee',
      (tester) async {
    late WidgetRef capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          trailHasCoverPhotosProvider.overrideWithValue(false),
        ],
        child: TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  capturedRef = ref;
                  return const SingleChildScrollView(child: SkinSelector());
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Etat initial : Sentier Vivant.
    expect(capturedRef.read(skinProvider), AppSkin.sentierVivant);

    // Tap sur la tuile Topographique.
    await tester.tap(find.text(t.appearance.skinTopographique));
    await tester.pumpAndSettle();

    expect(capturedRef.read(skinProvider), AppSkin.topographique);
  });

  testWidgets(
      'tap sur Grand Air NON eligible ne change PAS la peau (desactive)',
      (tester) async {
    late WidgetRef capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          trailHasCoverPhotosProvider.overrideWithValue(false),
        ],
        child: TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  capturedRef = ref;
                  return const SingleChildScrollView(child: SkinSelector());
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.appearance.skinGrandAir));
    await tester.pumpAndSettle();

    // Reste Sentier Vivant : la tuile ineligible n'est pas selectionnable.
    expect(capturedRef.read(skinProvider), AppSkin.sentierVivant);
  });

  testWidgets(
      'tap sur Grand Air eligible change bien la peau selectionnee',
      (tester) async {
    late WidgetRef capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          trailHasCoverPhotosProvider.overrideWithValue(true),
        ],
        child: TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  capturedRef = ref;
                  return const SingleChildScrollView(child: SkinSelector());
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.appearance.skinGrandAir));
    await tester.pumpAndSettle();

    expect(capturedRef.read(skinProvider), AppSkin.grandAir);
  });
}
