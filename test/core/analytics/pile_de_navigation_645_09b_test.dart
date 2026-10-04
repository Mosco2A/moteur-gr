// LA CLE `screen` SUIT L'ECRAN VISIBLE, PAS LA PILE (lot 645-09b).
//
// LE DEFAUT QUE CE FICHIER ENFERME, MESURE PAR ARTEMIS SUR L'EMULATEUR 12 FOIS
// SUR 12 (QA du 04/10/2026). `Navigator` reconstruit les ecrans restes vivants
// SOUS celui du dessus. Les 40 ecrans dont la miette est posee en tete de
// `build` la reposaient donc a chaque empilement, et la deduplication du
// service — qui ne retient que la DERNIERE empreinte — les laissait passer a
// tour de role. Apres l'ouverture de `/settings`, le journal portait
// `settings`, puis `trail_stage_detail`, puis `weather`, puis `journal` : la
// cle `screen` au moment d'un plantage designait un ecran que le randonneur ne
// regardait pas.
//
// CE QUI EST MESURE ICI, ET DANS L'ORDRE OU UN DOIGT LE FAIT :
//   1. deux ecrans instrumentes dans `build`, empiles par le VRAI GoRouter ;
//   2. l'ecran du DESSOUS est reconstruit (un provider qu'il lit change) :
//      sa miette ne doit PAS partir ;
//   3. on depile : il doit la REPOSER, puisqu'il redevient l'ecran vu.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/analytics/analytics_service.dart';
import 'package:moteur_gr/core/analytics/screen_entry.dart';

/// Un puits crash qui NOTE ce qu'on lui pose : c'est le journal de ce test.
class _PuitsNoteur implements CrashSink {
  final cles = <String, String>{};
  final miettes = <String>[];

  @override
  Future<void> log(String message) async => miettes.add(message);
  @override
  Future<void> setCustomKey(String key, String value) async =>
      cles[key] = value;
  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required bool fatal,
  }) async {}
  @override
  Future<void> setCollectionEnabled(bool enabled) async {}
}

/// LE THEME DE L'APPLICATION, que le test bascule pendant que les reglages
/// sont ouverts. C'est un changement d'ETAT au-dessus du `Navigator` : il
/// reconstruit tous les ecrans qui lisent le theme, y compris celui qui est
/// cache sous la pile.
///
/// POURQUOI PAS UN PROVIDER. Riverpod 3 MET EN PAUSE les abonnements d'un
/// widget hors de l'ecran (`TickerMode` coupe) : un `ref.watch` ne reconstruit
/// donc pas un ecran cache, et le test ne mesurerait rien. Ce que
/// l'emulateur montre, c'est la reconstruction par l'ARBRE — la pile, le
/// theme, les `MediaQuery` — et c'est elle qu'on provoque ici.
final _modeDuTheme = ValueNotifier(ThemeMode.light);

/// Un ecran SANS ETAT, instrumente comme les 40 vrais : miette en premiere
/// instruction de `build`, et le theme lu.
class _EcranSansEtat extends ConsumerWidget {
  const _EcranSansEtat(this.miette);
  final ScreenBreadcrumb miette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    observeScreenEntry(ref, miette);
    final teinte = Theme.of(context).brightness.name;
    return Scaffold(body: Text('${miette.name} $teinte'));
  }
}

/// Un ecran A ETAT, instrumente comme les 23 vrais : miette dans
/// `initState`, qui ne tourne qu'une fois par montage. Le cockpit et l'accueil
/// « maison » sont de ceux-la.
class _EcranAEtat extends ConsumerStatefulWidget {
  const _EcranAEtat(this.miette);
  final ScreenBreadcrumb miette;

  @override
  ConsumerState<_EcranAEtat> createState() => _EcranAEtatState();
}

class _EcranAEtatState extends ConsumerState<_EcranAEtat> {
  @override
  void initState() {
    super.initState();
    observeScreenEntry(ref, widget.miette);
  }

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Text(widget.miette.name));
}

void main() {
  late _PuitsNoteur puits;
  late GoRouter routeur;

  /// Monte le vrai GoRouter avec [racine] en bas de la pile et les reglages
  /// au-dessus — la paire mesuree par Artemis. [observateurs] : ce que le
  /// routeur de l'application porte, ou rien.
  Future<void> monter(
    WidgetTester tester, {
    Widget racine = const _EcranSansEtat(ScreenBreadcrumb.weather),
    List<NavigatorObserver> observateurs = const [],
  }) async {
    puits = _PuitsNoteur();
    _modeDuTheme.value = ThemeMode.light;
    routeur = GoRouter(
      initialLocation: '/racine',
      observers: observateurs,
      routes: [
        GoRoute(path: '/racine', builder: (_, _) => racine),
        GoRoute(
          path: '/settings',
          builder: (_, _) => const _EcranSansEtat(ScreenBreadcrumb.settings),
        ),
      ],
    );
    addTearDown(routeur.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsServiceProvider.overrideWithValue(
            AnalyticsService(
              analytics: const NoOpAnalyticsSink(),
              crash: puits,
            ),
          ),
        ],
        child: ValueListenableBuilder(
          valueListenable: _modeDuTheme,
          builder: (_, mode, _) => MaterialApp.router(
            routerConfig: routeur,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: mode,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Reconstruit tout ce qui lit le theme, l'ecran cache compris.
  void reconstruire() => _modeDuTheme.value = ThemeMode.dark;

  group('645-09b — la pile de navigation ne vole plus la cle screen', () {
    testWidgets(
      'deux ecrans build empiles : celui du dessous, reconstruit, se tait ; '
      'depile, il repose sa miette',
      (tester) async {
        await monter(tester);
        expect(puits.miettes, ['screen:weather']);

        routeur.push('/settings');
        await tester.pumpAndSettle();
        expect(puits.miettes, [
          'screen:weather',
          'screen:settings',
        ], reason: 'l empilement seul a fait parler l ecran cache');
        expect(puits.cles[AnalyticsKeys.screen], 'settings');

        // L'ECRAN DU DESSOUS EST RECONSTRUIT, ET IL L'EST VRAIMENT : son
        // texte change alors qu'il est cache.
        reconstruire();
        await tester.pumpAndSettle();
        expect(
          find.text('weather dark', skipOffstage: false),
          findsOneWidget,
          reason:
              'l ecran du dessous n a pas ete reconstruit : le test ne '
              'mesurerait rien',
        );
        expect(
          puits.miettes,
          ['screen:weather', 'screen:settings'],
          reason:
              'LA MIETTE DE L ECRAN CACHE EST PARTIE : le journal porte '
              '${puits.miettes}',
        );
        expect(
          puits.cles[AnalyticsKeys.screen],
          'settings',
          reason: 'la cle screen designe un ecran que personne ne regarde',
        );

        // ON DEPILE : la meteo redevient l'ecran vu, elle repose sa miette.
        routeur.pop();
        await tester.pumpAndSettle();
        expect(puits.miettes, [
          'screen:weather',
          'screen:settings',
          'screen:weather',
        ]);
        expect(puits.cles[AnalyticsKeys.screen], 'weather');
      },
    );

    testWidgets(
      'un ecran A ETAT sous la pile : depile, l observateur repose sa miette',
      (tester) async {
        // C'EST LE CAS QUE LE FILTRE SEUL NE PEUT PAS ATTEINDRE : la miette
        // vit dans `initState`, qui ne retourne pas quand on depile. Sans
        // l'observateur, « Reglages » puis retour au cockpit laissait la cle
        // sur `settings`, un ecran qui n'existe plus.
        await monter(
          tester,
          racine: const _EcranAEtat(ScreenBreadcrumb.hub),
          observateurs: [ScreenEntryObserver()],
        );
        expect(puits.miettes, ['screen:hub']);

        routeur.push('/settings');
        await tester.pumpAndSettle();
        reconstruire();
        await tester.pumpAndSettle();
        expect(puits.miettes, ['screen:hub', 'screen:settings']);
        expect(puits.cles[AnalyticsKeys.screen], 'settings');

        routeur.pop();
        await tester.pumpAndSettle();
        expect(
          puits.cles[AnalyticsKeys.screen],
          'hub',
          reason:
              'retour au cockpit : la cle screen nomme encore un ecran '
              'depile',
        );
        expect(puits.miettes, ['screen:hub', 'screen:settings', 'screen:hub']);
      },
    );

    testWidgets(
      'un dialogue ouvert puis ferme sur un ecran ne lui coute pas une '
      'miette de plus',
      (tester) async {
        // Un dialogue est une route : il rend l'ecran du dessous NON courant
        // le temps qu'il est ouvert, puis l'observateur voit son depilement.
        // La miette reposee a ce moment est celle de l'ecran deja nomme :
        // la deduplication du service la laisse sur place.
        await monter(tester, observateurs: [ScreenEntryObserver()]);
        final ecran = tester.element(find.text('weather light'));
        unawaited(
          showDialog<void>(
            context: ecran,
            builder: (_) => const Text('un dialogue'),
          ),
        );
        await tester.pumpAndSettle();
        reconstruire();
        await tester.pumpAndSettle();
        Navigator.of(ecran).pop();
        await tester.pumpAndSettle();

        expect(puits.miettes, ['screen:weather']);
        expect(puits.cles[AnalyticsKeys.screen], 'weather');
      },
    );
  });
}
