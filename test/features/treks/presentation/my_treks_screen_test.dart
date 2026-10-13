import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/core/config/trail_selection.dart';
import 'package:moteur_gr/core/services/session_demo.dart';
import 'package:moteur_gr/features/treks/domain/trek_lifecycle_state.dart';
import 'package:moteur_gr/features/treks/domain/trek_summary.dart';
import 'package:moteur_gr/features/treks/presentation/my_treks_screen.dart';
import 'package:moteur_gr/features/treks/providers/my_treks_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/widgets/contextual_action_bar.dart';
import 'package:moteur_gr/shared/widgets/contextual_bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// StepWays LOT 2, Phase 4 — ecran « Mes treks ».
///
/// Verifie le rendu des sections (En cours / Préparés / Terminés), le bandeau
/// Découvrir/Mon compte, l'etat vide, et le geste de selection (ecrit
/// selectedTrailIdProvider puis navigue vers /home).
TrailConfig _config(String id) => TrailConfig(
  id: id,
  name: id,
  displayName: 'Trek $id',
  tagline: 't',
  totalStages: 10,
  totalDistanceKm: 100,
  totalElevationGain: 5000,
  region: 'Corse',
  country: 'France',
  primaryColorValue: 0xFF2E7D32,
  secondaryColorValue: 0xFF1565C0,
  gpxAssetPath: 'assets/gpx/$id.gpx',
);

TrekSummary _summary(String id, TrekLifecycleState state) =>
    TrekSummary(config: _config(id), state: state);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Construit un container cable sur des [treks] figes (provider override).
  /// Renvoie aussi le container pour lire l'etat apres interaction.
  ProviderContainer makeContainer(List<TrekSummary> treks) {
    final container = ProviderContainer(
      overrides: [myTreksProvider.overrideWith((ref) async => treks)],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Enveloppe [MyTreksScreen] avec un router minimal ; /home rend un marqueur
  /// pour observer la navigation.
  Widget wrap(ProviderContainer container) {
    final router = GoRouter(
      initialLocation: '/my-treks',
      routes: [
        GoRoute(path: '/my-treks', builder: (_, __) => const MyTreksScreen()),
        GoRoute(path: '/home', builder: (_, __) => const Text('HOME_STUB')),
        GoRoute(path: '/catalog', builder: (_, __) => const Text('CATALOG')),
        GoRoute(path: '/profile', builder: (_, __) => const Text('PROFILE')),
      ],
    );
    return UncontrolledProviderScope(
      container: container,
      child: TranslationProvider(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  testWidgets('rend les 3 sections quand chaque etat est present', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        makeContainer([
          _summary('a', TrekLifecycleState.inProgress),
          _summary('b', TrekLifecycleState.prepared),
          _summary('c', TrekLifecycleState.completed),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    // NB : « En cours » apparait AUSSI comme badge d'etat du trek inProgress
    // (meme libelle que le titre de section) -> au moins une occurrence. Les
    // autres titres de section ne collisionnent pas avec leur badge (pluriel).
    expect(find.text(t.myTreks.sectionInProgress), findsAtLeastNWidgets(1));
    expect(find.text(t.myTreks.sectionPrepared), findsOneWidget);
    expect(find.text(t.myTreks.sectionCompleted), findsOneWidget);
    // UN SEUL « Découvrir des sentiers » (tache 837) : il en restait DEUX ici
    // (bandeau du corps + barre contextuelle), plus un troisieme dans l'etat
    // vide. Seul celui de la BARRE subsiste.
    expect(find.text(t.myTreks.discoverTitle), findsOneWidget);
    // « Mon compte » garde, lui, son double acces : le retour de Christophe ne
    // portait que sur Découvrir.
    expect(find.text(t.myTreks.accountTitle), findsNWidgets(2));
  });

  testWidgets('une section vide n affiche pas son en-tete', (tester) async {
    // Seulement des treks « owned » -> section Préparés uniquement.
    await tester.pumpWidget(
      wrap(makeContainer([_summary('a', TrekLifecycleState.owned)])),
    );
    await tester.pumpAndSettle();

    expect(find.text(t.myTreks.sectionPrepared), findsOneWidget);
    expect(find.text(t.myTreks.sectionInProgress), findsNothing);
    expect(find.text(t.myTreks.sectionCompleted), findsNothing);
  });

  testWidgets('etat vide : il DIT qu il n y a pas de sentier, et ou en trouver', (
    tester,
  ) async {
    // TACHE 638 — C EST LE CAS NORMAL DU PREMIER LANCEMENT, pas un cas
    // theorique : il n y a plus aucun sentier gratuit au catalogue (decision de
    // Christophe, scenario d acceptation du 29/09 14:17 : « Donc la prochaine
    // fois que j ouvre l application je n ai droit a rien »). L ecran doit donc
    // EXPLIQUER, pas paraitre casse.
    await tester.pumpWidget(wrap(makeContainer(const [])));
    await tester.pumpAndSettle();

    expect(find.text(t.myTreks.emptyTitle), findsOneWidget);
    expect(
      find.text(t.myTreks.emptyCatalogueOuDemo),
      findsOneWidget,
      reason:
          'le texte renvoie vers le catalogue ET vers la demo, qui est en '
          'tete du catalogue',
    );
  });

  testWidgets('etat vide : le texte NE PROMET PAS la demo si elle est cachee', (
    tester,
  ) async {
    // Le randonneur peut avoir coche « Cacher le mode demo » en quittant la demo
    // (bug 18). Lui promettre une demo « en tete de la liste » serait alors un
    // mensonge — exactement celui que le dialogue de sortie evite deja.
    final container = makeContainer(const []);
    await container.read(boutonDemoCacheProvider.notifier).definir(true);

    await tester.pumpWidget(wrap(container));
    await tester.pumpAndSettle();

    expect(find.text(t.myTreks.emptyCatalogueSeul), findsOneWidget);
    expect(find.text(t.myTreks.emptyCatalogueOuDemo), findsNothing);
  });

  testWidgets('selectionner un trek ecrit selectedTrailId puis va a /home', (
    tester,
  ) async {
    final container = makeContainer([
      _summary('gr20', TrekLifecycleState.prepared),
    ]);
    // Etat initial different pour prouver l'ecriture.
    container.read(selectedTrailIdProvider.notifier).state = 'autre';

    await tester.pumpWidget(wrap(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('trek-summary-gr20')));
    await tester.pumpAndSettle();

    // Navigation vers le cockpit + selection ecrite.
    expect(find.text('HOME_STUB'), findsOneWidget);
    expect(container.read(selectedTrailIdProvider), 'gr20');
  });

  testWidgets('le bandeau du corps ne porte PLUS de Découvrir (tache 837)', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(makeContainer([_summary('a', TrekLifecycleState.owned)])),
    );
    await tester.pumpAndSettle();

    // AVANT la tache 837 ce test tapait le Découvrir du CORPS (carte du
    // bandeau [HubSection]) pour aller a /catalog. Cette carte faisait doublon
    // avec la barre, en bas de ListView donc sous la ligne de flottaison : elle
    // est retiree. Le corps n'en porte plus aucun.
    final bodyDiscover = find.descendant(
      of: find.byType(ListView),
      matching: find.text(t.myTreks.discoverTitle),
    );
    expect(bodyDiscover, findsNothing);

    // Et le bandeau garde ses DEUX autres cartes : on n'a pas vide la section.
    final bodyAccount = find.descendant(
      of: find.byType(ListView),
      matching: find.text(t.myTreks.accountTitle),
    );
    expect(bodyAccount, findsOneWidget);
  });

  testWidgets('l etat vide ne porte PLUS de CTA Découvrir (tache 837)', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(makeContainer(const [])));
    await tester.pumpAndSettle();

    // Le CTA de l'empty-state etait le 3e Découvrir. L'invite ECRITE reste —
    // et c'est celle de la principale, qui dit aussi la demo quand elle n'est
    // pas cachee (tache 843 : la tache 837 ne touchait pas ce texte).
    expect(find.byKey(const ValueKey('my-treks-empty-discover')), findsNothing);
    expect(find.text(t.myTreks.emptyCatalogueOuDemo), findsOneWidget);
    // Liste vide ou pleine, il n'y a QU'UN SEUL Découvrir a l'ecran.
    expect(find.text(t.myTreks.discoverTitle), findsOneWidget);
  });

  testWidgets('le seul Découvrir restant est celui de la barre -> /catalog', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(makeContainer([_summary('a', TrekLifecycleState.owned)])),
    );
    await tester.pumpAndSettle();

    // Il est DANS la barre contextuelle, et il mene bien au catalogue : ce qui
    // a ete retire, c'est le doublon, pas l'acces.
    final barDiscover = find.descendant(
      of: find.byType(ContextualActionBar),
      matching: find.text(t.myTreks.discoverTitle),
    );
    expect(barDiscover, findsOneWidget);
    await tester.tap(barDiscover);
    await tester.pumpAndSettle();
    expect(find.text('CATALOG'), findsOneWidget);
  });

  group('barre contextuelle (SPEC §4, Ph5)', () {
    testWidgets('l accueil maison declare la barre Découvrir / Mon compte', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(makeContainer([_summary('a', TrekLifecycleState.owned)])),
      );
      await tester.pumpAndSettle();

      // La barre contextuelle est presente et porte les 2 actions §4.
      expect(find.byType(ContextualBottomBar), findsOneWidget);
      final barDiscover = find.descendant(
        of: find.byType(ContextualActionBar),
        matching: find.text(t.myTreks.discoverTitle),
      );
      final barAccount = find.descendant(
        of: find.byType(ContextualActionBar),
        matching: find.text(t.myTreks.accountTitle),
      );
      expect(barDiscover, findsOneWidget);
      expect(barAccount, findsOneWidget);
    });

    testWidgets('barre : Découvrir -> /catalog', (tester) async {
      await tester.pumpWidget(
        wrap(makeContainer([_summary('a', TrekLifecycleState.owned)])),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(ContextualActionBar),
          matching: find.text(t.myTreks.discoverTitle),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('CATALOG'), findsOneWidget);
    });
  });
}
