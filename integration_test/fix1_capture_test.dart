import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/theme/app_theme.dart';
import 'package:moteur_gr/core/theme/skin_provider.dart';
import 'package:moteur_gr/features/checklist/presentation/checklist_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// CAPTURES DE PREUVE FIX-1 — findings B1 (BLOQUANT) et M3.
///
/// Joue SUR L'EMULATEUR le geste exact du rapport personas :
///  - B1 : « Poids corporel » du bandeau Materiel & Sac. AVANT, 890 / 1e9 /
///    Infinity etaient acceptes et l'app AFFICHAIT « Poids du sac : Infinity kg ».
///    APRES, la saisie est refusee avec le message borne de la fiche morpho et
///    la jauge garde le dernier poids valide.
///  - M3 : poids d'article en grammes. AVANT, 99999999 devenait 50 000 g SANS
///    message. APRES, la saisie est physiquement limitee et le depassement est
///    signale — plus aucun clamp silencieux.
///
/// Le test IMPRIME un marqueur puis IMMOBILISE l'ecran : c'est l'hote qui
/// declenche `adb exec-out screencap` sur ce marqueur (meme procedure que L9).
/// Aucun demon, aucune boucle infinie : le test se termine seul.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const hold = Duration(seconds: 30);

  testWidgets('FIX-1 — captures B1 (poids corporel) et M3 (poids article)',
      (tester) async {
    final container = ProviderContainer(
      overrides: [trailConfigProvider.overrideWithValue(testTrailConfig)],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/checklist',
      routes: [
        GoRoute(path: '/checklist', builder: (_, __) => const ChecklistScreen()),
        GoRoute(path: '/my-treks', builder: (_, __) => const SizedBox()),
      ],
    );

    // THEME REEL DE L'APP (lecon des lots precedents) : sans cela la capture
    // montrerait la palette Material par defaut, pas l'application.
    final skin = container.read(effectiveSkinProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TranslationProvider(
          child: MaterialApp.router(
            routerConfig: router,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.buildLightTheme(
              primaryColor: Color(testTrailConfig.primaryColorValue),
              secondaryColor: Color(testTrailConfig.secondaryColorValue),
              skin: skin,
            ),
            darkTheme: AppTheme.buildDarkTheme(
              primaryColor: Color(testTrailConfig.primaryColorValue),
              secondaryColor: Color(testTrailConfig.secondaryColorValue),
              skin: skin,
            ),
            themeMode: ThemeMode.dark,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // --- CAPTURE 1 (B1) : 890 kg refuse, message borne affiche ---
    final weightField =
        find.byKey(const ValueKey('checklist-body-weight-field'));
    expect(weightField, findsOneWidget);
    await tester.enterText(weightField, '890');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('checklist-body-weight-error')),
        findsOneWidget,
        reason: 'le refus doit etre VISIBLE a l ecran, pas seulement en memoire');
    expect(find.textContaining('Infinity'), findsNothing,
        reason: 'plus aucun verdict absurde affiche');

    debugPrint('FIX1_SHOT_B1 poids_corporel_890_refuse');
    await Future<void>.delayed(hold);

    // --- CAPTURE 2 (M3) : 99999999 g impossible a saisir et signale ---
    await tester.tap(find.byType(ExpansionTile).first);
    await tester.pumpAndSettle();

    final addButton = find.text(t.checklist.ui.addItem).first;
    await tester.ensureVisible(addButton);
    await tester.pumpAndSettle();
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextField, t.checklist.ui.fieldName).first,
        'Rechaud');
    await tester.enterText(
        find.byKey(const ValueKey('checklist-add-weight-field')), '99999999');
    await tester.pumpAndSettle();

    expect(find.text(t.checklist.ui.errorWeightGrams), findsOneWidget,
        reason: 'le clamp silencieux est remplace par un refus motive');

    debugPrint('FIX1_SHOT_M3 poids_article_99999999_refuse');
    await Future<void>.delayed(hold);
  });
}
