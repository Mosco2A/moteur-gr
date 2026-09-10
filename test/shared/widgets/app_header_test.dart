import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/widgets/app_header.dart';

/// Tests widget dédiés de l'[AppHeader] (StepWays LOT 3, Ph1).
///
/// Couvre le contrat du composant : Retour (pop si `canPop`, sinon go accueil),
/// Accueil (go accueil, ne quitte jamais l'app), bascule showBack/showHome, et
/// le back Android centralisé via `PopScope` (confirmation de sortie À LA RACINE,
/// pile vide) — comportement clé non couvert ailleurs.
void main() {
  /// Routeur minimal : `/start` (bouton PUSH) -> `/page` (héberge l'AppHeader,
  /// donc `canPop` vrai). `/my-treks` = cible du bouton Accueil / fallback.
  Widget wrap({required Widget headerHost}) {
    final router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, __) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.push('/page'),
                child: const Text('PUSH'),
              ),
            ),
          ),
        ),
        GoRoute(path: '/page', builder: (_, __) => headerHost),
        GoRoute(
          path: '/my-treks',
          builder: (_, __) => const Scaffold(body: Text('MY_TREKS_STUB')),
        ),
      ],
    );
    return TranslationProvider(
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('AppHeader — contenu & boutons', () {
    testWidgets('rend le titre + Retour + Accueil', (tester) async {
      await tester.pumpWidget(wrap(
        headerHost: const Scaffold(
          appBar: AppHeader(title: 'Titre'),
          body: SizedBox(),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PUSH'));
      await tester.pumpAndSettle();

      expect(find.text('Titre'), findsOneWidget);
      expect(find.byTooltip(t.nav.back), findsOneWidget);
      expect(find.byTooltip(t.nav.home), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    });

    testWidgets('showBack=false : pas de bouton Retour', (tester) async {
      await tester.pumpWidget(wrap(
        headerHost: const Scaffold(
          appBar: AppHeader(title: 'Racine', showBack: false),
          body: SizedBox(),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PUSH'));
      await tester.pumpAndSettle();

      expect(find.byTooltip(t.nav.back), findsNothing);
      expect(find.byTooltip(t.nav.home), findsOneWidget);
    });

    testWidgets('showHome=false : pas de bouton Accueil', (tester) async {
      await tester.pumpWidget(wrap(
        headerHost: const Scaffold(
          appBar: AppHeader(title: 'Titre', showHome: false),
          body: SizedBox(),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PUSH'));
      await tester.pumpAndSettle();

      expect(find.byTooltip(t.nav.home), findsNothing);
      expect(find.byTooltip(t.nav.back), findsOneWidget);
    });

    testWidgets('actions additionnelles rendues avant l\'Accueil',
        (tester) async {
      await tester.pumpWidget(wrap(
        headerHost: Scaffold(
          appBar: AppHeader(
            title: 'Titre',
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {},
              ),
            ],
          ),
          body: const SizedBox(),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PUSH'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    });
  });

  group('AppHeader — navigation', () {
    testWidgets('Retour dépile quand canPop (retour à l\'écran précédent)',
        (tester) async {
      await tester.pumpWidget(wrap(
        headerHost: const Scaffold(
          appBar: AppHeader(title: 'Titre'),
          body: SizedBox(),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PUSH'));
      await tester.pumpAndSettle();
      expect(find.text('Titre'), findsOneWidget);

      await tester.tap(find.byTooltip(t.nav.back));
      await tester.pumpAndSettle();
      expect(find.text('PUSH'), findsOneWidget);
      expect(find.text('Titre'), findsNothing);
    });

    testWidgets('Accueil route vers /my-treks (ne quitte pas l\'app)',
        (tester) async {
      await tester.pumpWidget(wrap(
        headerHost: const Scaffold(
          appBar: AppHeader(title: 'Titre'),
          body: SizedBox(),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PUSH'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(t.nav.home));
      await tester.pumpAndSettle();
      expect(find.text('MY_TREKS_STUB'), findsOneWidget);
    });

    testWidgets('onBack surcharge le geste retour', (tester) async {
      var custom = false;
      await tester.pumpWidget(wrap(
        headerHost: Scaffold(
          appBar: AppHeader(title: 'Titre', onBack: () => custom = true),
          body: const SizedBox(),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PUSH'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(t.nav.back));
      await tester.pumpAndSettle();
      expect(custom, isTrue, reason: 'onBack fourni -> appelé au lieu de pop');
      // Le pop n'a PAS eu lieu : on est toujours sur la page à AppHeader.
      expect(find.text('Titre'), findsOneWidget);
    });

    testWidgets('à la racine (pile vide), Retour route vers l\'accueil',
        (tester) async {
      // AppHeader monté à la RACINE (initialLocation) : canPop faux -> le bouton
      // Retour route vers l'accueil (homeLocation), jamais de cul-de-sac.
      final router = GoRouter(
        initialLocation: '/root',
        routes: [
          GoRoute(
            path: '/root',
            builder: (_, __) => const Scaffold(
              appBar: AppHeader(title: 'Racine'),
              body: SizedBox(),
            ),
          ),
          GoRoute(
            path: '/my-treks',
            builder: (_, __) => const Scaffold(body: Text('MY_TREKS_STUB')),
          ),
        ],
      );
      await tester.pumpWidget(TranslationProvider(
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(t.nav.back));
      await tester.pumpAndSettle();
      expect(find.text('MY_TREKS_STUB'), findsOneWidget);
    });
  });

  group('AppHeader — back Android (PopScope)', () {
    testWidgets('à la racine, PopScope garde la main (canPop=false)',
        (tester) async {
      // À la racine (pile vide), le back Android ne doit PAS quitter en silence :
      // l'AppHeader installe un PopScope(canPop:false) qui intercepte le geste
      // système pour demander confirmation (fixed start destination, AUDIT §M-3).
      // Le callback onPopInvokedWithResult porte la logique de confirmation.
      final router = GoRouter(
        initialLocation: '/root',
        routes: [
          GoRoute(
            path: '/root',
            builder: (_, __) => const Scaffold(
              appBar: AppHeader(title: 'Accueil'),
              body: SizedBox(),
            ),
          ),
        ],
      );
      await tester.pumpWidget(TranslationProvider(
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();

      final popScope = tester.widget<PopScope<Object?>>(
        find.descendant(
          of: find.byType(AppHeader),
          matching: find.byType(PopScope<Object?>),
        ),
      );
      expect(popScope.canPop, isFalse,
          reason: 'racine -> PopScope garde la main (pas de sortie silencieuse)');
      expect(popScope.onPopInvokedWithResult, isNotNull);
    });

    testWidgets('hors racine, PopScope laisse dépiler (canPop=true)',
        (tester) async {
      // Hors racine (une page empilée), le retour est normal : PopScope(canPop:
      // true) laisse le Navigator dépiler (animation predictive Android préservée).
      await tester.pumpWidget(wrap(
        headerHost: const Scaffold(
          appBar: AppHeader(title: 'Titre'),
          body: SizedBox(),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PUSH'));
      await tester.pumpAndSettle();

      final popScope = tester.widget<PopScope<Object?>>(
        find.descendant(
          of: find.byType(AppHeader),
          matching: find.byType(PopScope<Object?>),
        ),
      );
      expect(popScope.canPop, isTrue,
          reason: 'hors racine -> le Navigator dépile normalement');
    });
  });
}
