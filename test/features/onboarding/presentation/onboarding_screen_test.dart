import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/features/onboarding/presentation/onboarding_screen.dart';
import 'package:moteur_gr/features/onboarding/providers/onboarding_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests de l'ecran d'onboarding (E5.1a).
///
/// Couvre le flow complet des 3 pages et le bouton « Passer ». Les libelles
/// sont resolus via Slang (`t.onboarding.*`) pour rester agnostiques de la
/// marque : aucun nom de sentier en dur (le titre de bienvenue est construit
/// a partir de [TrailConfig.displayName], ici le sentier fictif de test).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Traductions de la locale de base (fr) pour resoudre les libelles attendus.
  final Translations tr = AppLocale.fr.buildSync();
  final String appName = testTrailConfig.displayName;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  /// Construit le widget sous test : Riverpod + Slang + GoRouter.
  Widget buildApp({required void Function(String) onNavigate}) {
    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/catalog',
          builder: (context, state) {
            onNavigate('/catalog');
            return const Scaffold(body: Text('CATALOG'));
          },
        ),
      ],
    );

    return ProviderScope(
      overrides: [trailConfigProvider.overrideWithValue(testTrailConfig)],
      child: TranslationProvider(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  group('OnboardingScreen', () {
    // TACHE 568 (LOT Q, Q1) — CE TEST A CHANGE DE BOUTON, ET C'EST VOULU.
    //
    // La 3e page portait DEUX commandes vers le MEME endroit : « Parcourir le
    // catalogue » dans le contenu et « Commencer » en bas. Elles ne faisaient
    // pas la meme chose (l'une posait le drapeau d'onboarding, l'autre non),
    // donc l'une marchait et l'autre paraissait morte — defaut trouve par Chris
    // le 26/09. Decision de Skynet : on garde le geste EXPLICITE (celui du
    // contenu) et le doublon du bas DISPARAIT sur cette page. Ce test suit donc
    // le bouton conserve ; le detail du contrat est verrouille par
    // `parcourir_catalogue_568_test.dart`.
    testWidgets('parcourt les 3 pages via « Suivant » puis le geste explicite', (
      tester,
    ) async {
      String? navigatedTo;
      await tester.pumpWidget(buildApp(onNavigate: (p) => navigatedTo = p));
      await tester.pumpAndSettle();

      // Page 1 : bienvenue (titre parametrique, sans marque de sentier en dur).
      expect(
        find.text(tr.onboarding.welcomeTitle(appName: appName)),
        findsOneWidget,
      );
      expect(find.text(tr.onboarding.skip), findsOneWidget);
      expect(find.text(tr.onboarding.next), findsOneWidget);

      // -> Page 2 : choix de la langue (5 ChoiceChip).
      await tester.tap(find.text(tr.onboarding.next));
      await tester.pumpAndSettle();
      expect(find.text(tr.onboarding.languageTitle), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNWidgets(5));

      // -> Page 3 : telechargement.
      await tester.tap(find.text(tr.onboarding.next));
      await tester.pumpAndSettle();
      expect(find.text(tr.onboarding.downloadTitle), findsOneWidget);
      // Le doublon du bas a disparu (tache 568) : seul le geste explicite reste.
      expect(find.text(tr.onboarding.getStarted), findsNothing);
      expect(find.text(tr.onboarding.browseCatalog), findsOneWidget);

      // Le geste explicite termine l'onboarding et navigue vers le catalogue.
      await tester.tap(find.text(tr.onboarding.browseCatalog));
      await tester.pumpAndSettle();
      expect(navigatedTo, '/catalog');
    });

    testWidgets('le bouton « Passer » termine et navigue vers le catalogue', (
      tester,
    ) async {
      String? navigatedTo;
      await tester.pumpWidget(buildApp(onNavigate: (p) => navigatedTo = p));
      await tester.pumpAndSettle();

      await tester.tap(find.text(tr.onboarding.skip));
      await tester.pumpAndSettle();

      expect(navigatedTo, '/catalog');

      // Le flag de completion est persiste apres le skip.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(kOnboardingCompletedKey), isTrue);
    });
  });
}
