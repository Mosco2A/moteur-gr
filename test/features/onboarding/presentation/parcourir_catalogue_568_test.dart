import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/routing/app_router.dart' as router;
import 'package:moteur_gr/features/onboarding/presentation/onboarding_screen.dart';
import 'package:moteur_gr/features/onboarding/providers/onboarding_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Q1 (tache 568, LOT Q) — LE BOUTON « PARCOURIR LE CATALOGUE » NE FAISAIT RIEN.
///
/// CE QUE CHRIS A VU, verbatim (26/09 09:48) : « 2eme page d'accueil il y a un
/// bouton parcourir le catalogue qui ne fonctionne pas, continuer lui amene au
/// catalogue mais un retour arriere arrive a mare a mare ».
///
/// LA CAUSE, mesuree : la troisieme page de l'onboarding portait DEUX commandes
/// vers la MEME destination. Le bouton du contenu (« Parcourir le catalogue »)
/// appelait `_goToCatalog()` qui faisait `context.go('/catalog')` SANS poser le
/// drapeau d'onboarding ; la garde du routeur (`redirectForPath` :
/// `if (!hasCompletedOnboarding) return '/onboarding'`) le renvoyait AUSSITOT.
/// Visuellement : rien ne se passe. Le bouton du bas (« Commencer ») faisait,
/// lui, les deux gestes dans le bon ordre.
///
/// DECISION DE SKYNET APPLIQUEE ICI : un ecran qui propose DEUX fois la meme
/// action au meme moment n'a pas choisi. On GARDE « Parcourir le catalogue »,
/// le geste EXPLICITE (icone explore), avec le comportement de `_finish`, et le
/// doublon du bas DISPARAIT sur cette page (il garde son role « Suivant » sur
/// les deux premieres).
///
/// CES DEUX TESTS ONT ETE ECRITS ROUGES : le premier echouait sur le drapeau
/// non persiste, le second sur la presence du doublon.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Translations tr = AppLocale.fr.buildSync();
  final String appName = testTrailConfig.displayName;

  // La garde du routeur lit une GLOBALE : on la remet dans son etat de premier
  // lancement pour chaque test, et on la restaure apres (aucune fuite entre
  // fichiers de test).
  late bool globaleSauvegardee;

  setUp(() {
    globaleSauvegardee = router.hasCompletedOnboarding;
    router.hasCompletedOnboarding = false; // premier lancement
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() {
    router.hasCompletedOnboarding = globaleSauvegardee;
  });

  Widget buildApp({required void Function(String) onNavigate}) {
    final r = GoRouter(
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
        child: MaterialApp.router(routerConfig: r),
      ),
    );
  }

  /// Amene le PageView sur la 3e page (celle du telechargement).
  Future<void> allerPage3(WidgetTester tester) async {
    await tester.tap(find.text(tr.onboarding.next));
    await tester.pumpAndSettle();
    await tester.tap(find.text(tr.onboarding.next));
    await tester.pumpAndSettle();
    expect(find.text(tr.onboarding.downloadTitle), findsOneWidget);
  }

  group('Q1 — « Parcourir le catalogue » est un geste VIVANT', () {
    testWidgets(
      'il TERMINE l onboarding (drapeau persiste + globale de la garde) avant '
      'de partir au catalogue — sans quoi la garde le renvoie aussitot',
      (tester) async {
        String? navigatedTo;
        await tester.pumpWidget(buildApp(onNavigate: (p) => navigatedTo = p));
        await tester.pumpAndSettle();
        await allerPage3(tester);

        await tester.tap(find.text(tr.onboarding.browseCatalog));
        await tester.pumpAndSettle();

        // 1) La navigation a eu lieu.
        expect(navigatedTo, '/catalog');

        // 2) Le drapeau est PERSISTE (contrat du prochain lancement).
        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getBool(kOnboardingCompletedKey),
          isTrue,
          reason: 'sans persistance, le catalogue renverrait a l onboarding au '
              'prochain lancement',
        );

        // 3) La GLOBALE lue par la garde synchrone est alignee : c'est ELLE qui
        //    faisait rebondir le bouton (`redirectForPath`).
        expect(
          router.hasCompletedOnboarding,
          isTrue,
          reason: 'la garde du routeur lit cette globale, pas le provider : '
              'sans elle, /catalog est renvoye sur /onboarding et le bouton '
              'parait mort',
        );
        expect(
          router.redirectForPath('/catalog'),
          isNull,
          reason: 'apres ce geste, le catalogue doit etre atteignable',
        );
      },
    );

    testWidgets(
      'la 3e page ne propose plus DEUX fois la meme action : le bouton du bas '
      'a disparu, « Parcourir le catalogue » reste seul',
      (tester) async {
        await tester.pumpWidget(buildApp(onNavigate: (_) {}));
        await tester.pumpAndSettle();
        await allerPage3(tester);

        expect(
          find.text(tr.onboarding.browseCatalog),
          findsOneWidget,
          reason: 'le geste explicite reste',
        );
        expect(
          find.text(tr.onboarding.getStarted),
          findsNothing,
          reason: 'le doublon du bas disparait sur la page qui porte deja le '
              'geste explicite (decision Skynet, tache 568)',
        );
        // Le bouton « Suivant » n'a plus rien a faire ici non plus.
        expect(find.text(tr.onboarding.next), findsNothing);
      },
    );

    testWidgets(
      'sur les DEUX premieres pages, le bouton du bas garde son role Suivant',
      (tester) async {
        await tester.pumpWidget(buildApp(onNavigate: (_) {}));
        await tester.pumpAndSettle();

        expect(find.text(tr.onboarding.next), findsOneWidget);
        expect(
          find.text(tr.onboarding.welcomeTitle(appName: appName)),
          findsOneWidget,
        );

        await tester.tap(find.text(tr.onboarding.next));
        await tester.pumpAndSettle();
        expect(find.text(tr.onboarding.languageTitle), findsOneWidget);
        expect(find.text(tr.onboarding.next), findsOneWidget);
      },
    );
  });
}
