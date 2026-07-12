import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/features/auth/domain/auth_service.dart';
import 'package:moteur_gr/features/auth/providers/auth_provider.dart';
import 'package:moteur_gr/features/hub/presentation/hub_screen.dart';
import 'package:moteur_gr/features/hub/presentation/widgets/hub_header.dart';
import 'package:moteur_gr/features/hub/presentation/widgets/hub_trek_card.dart';
import 'package:moteur_gr/features/hub/providers/hub_providers.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Tests du HUB d'accueil E07 (LOT-A, socle structurel).
///
/// Couvre :
///   - la salutation ([HubHeader]) avec pseudonyme et repli localise ;
///   - la derivation [displayNameProvider] (pseudonyme normalise / null) ;
///   - la carte principale trek ([HubTrekCard]) dans ses 2 etats ;
///   - le rendu structurel du HUB (4 sections, cartes cablees) ;
///   - le cloisonnement (aucun libelle GR20 / Fra li Monti dans le HUB).
///
/// D1..D5 (arbitrage #94902) : le mode demo est masque (aucun bandeau), aucune
/// section Communaute. LOT-B : la tuile meteo est desormais REELLE (branchee sur
/// stageWeatherProvider), plus un stub. Ces tests verifient l'ABSENCE des
/// elements masques autant que la presence du socle.
void main() {
  /// Enveloppe un [child] avec un ProviderScope override + Translations + un
  /// GoRouter minimal (les cartes du HUB utilisent context.go/push).
  Widget wrap({
    required Widget child,
    List<Override> overrides = const [],
  }) {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, __) => child),
        // Cibles neutres pour ne casser aucune navigation au tap.
        GoRoute(path: '/map', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/journal', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/catalog', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/profile', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/training', builder: (_, __) => const SizedBox()),
        GoRoute(
          path: '/accommodations-nearby',
          builder: (_, __) => const SizedBox(),
        ),
        GoRoute(path: '/group/:id', builder: (_, __) => const SizedBox()),
        GoRoute(
          path: '/trail/:id/planning',
          builder: (_, __) => const SizedBox(),
        ),
        GoRoute(
          path: '/trail/:id/feasibility',
          builder: (_, __) => const SizedBox(),
        ),
        GoRoute(
          path: '/trail/:id/checklist',
          builder: (_, __) => const SizedBox(),
        ),
        GoRoute(path: '/trail/:id/tips', builder: (_, __) => const SizedBox()),
        GoRoute(
          path: '/trail/:id/diploma',
          builder: (_, __) => const SizedBox(),
        ),
        GoRoute(
          path: '/trail/:id/feedback',
          builder: (_, __) => const SizedBox(),
        ),
      ],
    );

    return ProviderScope(
      overrides: overrides,
      child: TranslationProvider(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  /// Override d'un utilisateur avec un pseudonyme donne (ou null).
  Override userWith(String? pseudonym) {
    return authStateProvider.overrideWithValue(
      pseudonym == null
          ? null
          : AuthUser(
              uid: 'test-uid',
              authMethod: AuthMethodValues.anonymous,
              displayName: pseudonym,
            ),
    );
  }

  /// Override de l'etat du trek.
  Override trekWith(TrackingSessionState state) {
    return trekSessionManagerProvider.overrideWith(
      () => _FakeTrekNotifier(state),
    );
  }

  group('displayNameProvider (RF-3, #F03)', () {
    test('retourne le pseudonyme quand il est non vide', () {
      final container = ProviderContainer(overrides: [userWith('Alex')]);
      addTearDown(container.dispose);
      expect(container.read(displayNameProvider), 'Alex');
    });

    test('retourne null quand aucun pseudonyme (repli UI localise)', () {
      final container = ProviderContainer(overrides: [userWith(null)]);
      addTearDown(container.dispose);
      expect(container.read(displayNameProvider), isNull);
    });

    test('normalise un pseudonyme fait uniquement d espaces en null', () {
      final container = ProviderContainer(overrides: [userWith('   ')]);
      addTearDown(container.dispose);
      expect(container.read(displayNameProvider), isNull);
    });
  });

  group('HubHeader (salutation RF-3)', () {
    testWidgets('affiche le pseudonyme quand present', (tester) async {
      await tester.pumpWidget(
        wrap(child: const HubHeader(), overrides: [userWith('Alex')]),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.hub.greeting(name: 'Alex')), findsOneWidget);
    });

    testWidgets('applique le repli localise « Randonneur » sans pseudonyme',
        (tester) async {
      await tester.pumpWidget(
        wrap(child: const HubHeader(), overrides: [userWith(null)]),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(t.hub.greeting(name: t.hub.greetingFallback)),
        findsOneWidget,
      );
    });
  });

  group('HubTrekCard (RF-4, 2 etats)', () {
    testWidgets('etat « aucun trek » : invite a planifier', (tester) async {
      await tester.pumpWidget(
        wrap(
          child: const HubTrekCard(),
          overrides: [
            userWith(null),
            trekWith(const TrackingSessionState(
              status: TrackingSessionStatus.idle,
            )),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.hub.trekCard.noTrekTitle), findsOneWidget);
      expect(find.text(t.hub.trekCard.plan), findsOneWidget);
      // Pas d'elements de l'etat actif.
      expect(find.text(t.hub.trekCard.activeTitle), findsNothing);
      expect(find.text(t.hub.trekCard.resume), findsNothing);
    });

    testWidgets('etat « trek en cours » : stats + reprise navigation',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          child: const HubTrekCard(),
          overrides: [
            userWith(null),
            trekWith(const TrackingSessionState(
              status: TrackingSessionStatus.recording,
              distanceKm: 12.5,
              elevationGainM: 640.0,
              elapsedDuration: Duration(hours: 3, minutes: 20),
            )),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.hub.trekCard.activeTitle), findsOneWidget);
      expect(find.text(t.hub.trekCard.resume), findsOneWidget);
      // La distance parcourue s'affiche formatee.
      expect(find.text('12.5 km'), findsOneWidget);
      expect(find.text('640 m'), findsOneWidget);
      // Pas d'invitation a planifier en trek actif.
      expect(find.text(t.hub.trekCard.plan), findsNothing);
    });
  });

  group('HubScreen (socle structurel)', () {
    Widget hub({TrackingSessionStatus status = TrackingSessionStatus.idle}) =>
        wrap(
          child: const HubScreen(),
          overrides: [
            userWith('Alex'),
            trekWith(TrackingSessionState(status: status)),
          ],
        );

    /// Rend le HUB sur une surface TRES haute pour que le [ListView] construise
    /// toutes ses sections d'un coup (sinon les cartes sous la ligne de flottaison
    /// ne sont pas montees et introuvables). Reinitialise a la fin du test.
    Future<void> pumpTallHub(
      WidgetTester tester, {
      TrackingSessionStatus status = TrackingSessionStatus.idle,
    }) async {
      tester.view.physicalSize = const Size(1200, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(hub(status: status));
      await tester.pumpAndSettle();
    }

    testWidgets('rend les 4 sections attendues', (tester) async {
      await pumpTallHub(tester);

      expect(find.text(t.hub.sections.prepare), findsOneWidget);
      expect(find.text(t.hub.sections.hike), findsOneWidget);
      expect(find.text(t.hub.sections.info), findsOneWidget);
      expect(find.text(t.hub.sections.after), findsOneWidget);
    });

    testWidgets('rend la tuile meteo reelle (LOT-B) et la salutation',
        (tester) async {
      await pumpTallHub(tester);

      // La tuile meteo est desormais reelle (titre present, plus de stub).
      // Sans donnees (DB de test vide), elle affiche l'etat indisponible.
      expect(find.text(t.hub.weather.title), findsOneWidget);
      expect(find.text(t.hub.weather.stub), findsNothing);
      expect(find.text(t.hub.greeting(name: 'Alex')), findsOneWidget);
    });

    testWidgets('rend un echantillon de cartes cablees (S8)', (tester) async {
      await pumpTallHub(tester);

      expect(find.text(t.hub.cards.feasibility), findsOneWidget);
      expect(find.text(t.hub.cards.programme), findsOneWidget);
      expect(find.text(t.hub.cards.navigation), findsOneWidget);
      expect(find.text(t.hub.cards.accommodations), findsOneWidget);
      expect(find.text(t.hub.cards.diploma), findsOneWidget);
    });

    testWidgets('CTA « Demarrer » present hors trek reel actif', (tester) async {
      await pumpTallHub(tester);
      expect(find.text(t.hub.startCta), findsOneWidget);
    });

    testWidgets('CTA « Demarrer » absent quand un trek reel est actif',
        (tester) async {
      await pumpTallHub(tester, status: TrackingSessionStatus.recording);
      expect(find.text(t.hub.startCta), findsNothing);
    });

    testWidgets('cloisonnement : aucun libelle GR20 / Fra li Monti (S2/S10)',
        (tester) async {
      await pumpTallHub(tester);

      expect(find.textContaining('GR20'), findsNothing);
      expect(find.textContaining('Fra li Monti'), findsNothing);
    });
  });

  // --- Non-regression overflow mobile (#95062, verdict Artemis ROUGE) ---
  //
  // Les tests structurels ci-dessus rendent le HUB a 1200 px de large
  // ([pumpTallHub], Size(1200, 4000)) : a cette largeur AUCUN debordement
  // horizontal n'apparait, ce qui masquait un overflow reel aux largeurs
  // mobiles courantes. Un [childAspectRatio]/[Row] sans [Expanded] sur les
  // titres faisait deborder la Row a droite a 360/390/412 px logiques (Text
  // titleLarge plus large que la cellule).
  //
  // Ce groupe COMBLE le trou : il rend le HUB COMPLET a chaque largeur mobile,
  // sur les 2 etats trek (idle ET recording), et ECHOUE si le moindre RenderFlex
  // signale un overflow. Largeur = physicalSize / devicePixelRatio(1.0), donc
  // px logiques. Hauteur volontairement tres grande pour monter toutes les
  // sections (comme pumpTallHub) sans reintroduire de contrainte verticale.
  group('non-regression overflow largeurs mobiles (#95062)', () {
    // Largeurs logiques des combines Android les plus repandus.
    const mobileWidths = <double>[360, 390, 412];

    Widget hub(TrackingSessionStatus status) => wrap(
          child: const HubScreen(),
          overrides: [
            userWith('Alex'),
            trekWith(TrackingSessionState(
              status: status,
              // Valeurs realistes de l'etat « en cours » pour rendre les stats
              // et le titre a leur pleine largeur.
              distanceKm: 12.5,
              elevationGainM: 640,
              elapsedDuration: const Duration(hours: 3, minutes: 20),
            )),
          ],
        );

    /// Rend le HUB a [width] px logiques et renvoie la liste des messages
    /// d'overflow RenderFlex captures pendant le layout (vide = aucun).
    ///
    /// Les erreurs de layout Flutter (dont le RenderFlex overflow) sont
    /// recuperees par le binding de test comme "pending exceptions" : il faut
    /// les CONSOMMER via [WidgetTester.takeException] avant la fin du test,
    /// sinon le binding fait echouer le test avec une assertion opaque au lieu
    /// du diagnostic d'overflow. On restaure [FlutterError.onError] de maniere
    /// synchrone (pas en tearDown) pour la meme raison. Les erreurs NON liees a
    /// un overflow sont relayees au handler d'origine (non avalees).
    Future<List<String>> overflowsAt(
      WidgetTester tester,
      double width,
      TrackingSessionStatus status,
    ) async {
      final captured = <String>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        final message = details.exceptionAsString();
        if (message.contains('overflowed')) {
          captured.add(message.split('\n').first);
        } else {
          (previous ?? FlutterError.presentError)(details);
        }
      };

      tester.view.physicalSize = Size(width, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      try {
        await tester.pumpWidget(hub(status));
        await tester.pumpAndSettle();
      } finally {
        FlutterError.onError = previous;
      }

      // Draine les exceptions d'overflow que le binding a mises en attente,
      // afin de laisser l'etat propre et de faire porter l'echec par le
      // expect() ci-dessous (message lisible) plutot que par le binding.
      for (var guard = 0; guard < captured.length + 8; guard++) {
        final pending = tester.takeException();
        if (pending == null) break;
        if (!pending.toString().contains('overflowed')) {
          // Exception inattendue : on la re-signale telle quelle.
          throw pending;
        }
      }
      return captured;
    }

    for (final width in mobileWidths) {
      testWidgets('aucun overflow a ${width.toInt()} px — sans trek',
          (tester) async {
        final overflows =
            await overflowsAt(tester, width, TrackingSessionStatus.idle);
        expect(
          overflows,
          isEmpty,
          reason: 'HUB sans trek deborde a ${width.toInt()} px : $overflows',
        );
      });

      testWidgets('aucun overflow a ${width.toInt()} px — trek en cours',
          (tester) async {
        final overflows =
            await overflowsAt(tester, width, TrackingSessionStatus.recording);
        expect(
          overflows,
          isEmpty,
          reason: 'HUB trek en cours deborde a ${width.toInt()} px : $overflows',
        );
      });
    }
  });
}

/// Notifier factice pilotant l'etat expose du trek (voir tracking_overlay_test).
class _FakeTrekNotifier extends TrekSessionManagerNotifier {
  _FakeTrekNotifier(this._initial);
  final TrackingSessionState _initial;

  @override
  TrackingSessionState build() => _initial;
}
