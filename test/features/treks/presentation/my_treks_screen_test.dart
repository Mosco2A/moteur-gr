import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/core/config/trail_selection.dart';
import 'package:moteur_gr/features/treks/domain/trek_lifecycle_state.dart';
import 'package:moteur_gr/features/treks/domain/trek_summary.dart';
import 'package:moteur_gr/features/treks/presentation/my_treks_screen.dart';
import 'package:moteur_gr/features/treks/providers/my_treks_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/widgets/contextual_action_bar.dart';
import 'package:moteur_gr/shared/widgets/contextual_bottom_bar.dart';

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
  /// Construit un container cable sur des [treks] figes (provider override).
  /// Renvoie aussi le container pour lire l'etat apres interaction.
  ProviderContainer makeContainer(List<TrekSummary> treks) {
    final container = ProviderContainer(overrides: [
      myTreksProvider.overrideWith((ref) async => treks),
    ]);
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

  testWidgets('rend les 3 sections quand chaque etat est present',
      (tester) async {
    await tester.pumpWidget(wrap(makeContainer([
      _summary('a', TrekLifecycleState.inProgress),
      _summary('b', TrekLifecycleState.prepared),
      _summary('c', TrekLifecycleState.completed),
    ])));
    await tester.pumpAndSettle();

    // NB : « En cours » apparait AUSSI comme badge d'etat du trek inProgress
    // (meme libelle que le titre de section) -> au moins une occurrence. Les
    // autres titres de section ne collisionnent pas avec leur badge (pluriel).
    expect(find.text(t.myTreks.sectionInProgress), findsAtLeastNWidgets(1));
    expect(find.text(t.myTreks.sectionPrepared), findsOneWidget);
    expect(find.text(t.myTreks.sectionCompleted), findsOneWidget);
    // Découvrir / Mon compte apparaissent DEUX fois : dans le bandeau du corps
    // ([HubSection]) ET dans la barre contextuelle (§4, Ph5). Les deux coexistent
    // (la barre ne retire pas le contenu du corps).
    expect(find.text(t.myTreks.discoverTitle), findsNWidgets(2));
    expect(find.text(t.myTreks.accountTitle), findsNWidgets(2));
  });

  testWidgets('une section vide n affiche pas son en-tete', (tester) async {
    // Seulement des treks « owned » -> section Préparés uniquement.
    await tester.pumpWidget(wrap(makeContainer([
      _summary('a', TrekLifecycleState.owned),
    ])));
    await tester.pumpAndSettle();

    expect(find.text(t.myTreks.sectionPrepared), findsOneWidget);
    expect(find.text(t.myTreks.sectionInProgress), findsNothing);
    expect(find.text(t.myTreks.sectionCompleted), findsNothing);
  });

  testWidgets('etat vide affiche le message dedie', (tester) async {
    await tester.pumpWidget(wrap(makeContainer(const [])));
    await tester.pumpAndSettle();

    expect(find.text(t.myTreks.empty), findsOneWidget);
  });

  testWidgets('selectionner un trek ecrit selectedTrailId puis va a /home',
      (tester) async {
    final container = makeContainer(
      [_summary('gr20', TrekLifecycleState.prepared)],
    );
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

  testWidgets('bandeau du corps : Découvrir -> /catalog', (tester) async {
    await tester.pumpWidget(wrap(makeContainer([
      _summary('a', TrekLifecycleState.owned),
    ])));
    await tester.pumpAndSettle();

    // Découvrir existe en 2 exemplaires (corps + barre §4) : on cible celui du
    // CORPS (hors [ContextualActionBar]) pour tester le bandeau historique.
    final bodyDiscover = find.descendant(
      of: find.byType(ListView),
      matching: find.text(t.myTreks.discoverTitle),
    );
    expect(bodyDiscover, findsOneWidget);
    await tester.tap(bodyDiscover);
    await tester.pumpAndSettle();
    expect(find.text('CATALOG'), findsOneWidget);
  });

  group('barre contextuelle (SPEC §4, Ph5)', () {
    testWidgets('l accueil maison declare la barre Découvrir / Mon compte',
        (tester) async {
      await tester.pumpWidget(wrap(makeContainer([
        _summary('a', TrekLifecycleState.owned),
      ])));
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
      await tester.pumpWidget(wrap(makeContainer([
        _summary('a', TrekLifecycleState.owned),
      ])));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(
        of: find.byType(ContextualActionBar),
        matching: find.text(t.myTreks.discoverTitle),
      ));
      await tester.pumpAndSettle();
      expect(find.text('CATALOG'), findsOneWidget);
    });
  });
}
