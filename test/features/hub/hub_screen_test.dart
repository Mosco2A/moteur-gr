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
/// D1..D5 (arbitrage #94902) : le mode demo est masque (aucun bandeau), la
/// tuile meteo est un stub, aucune section Communaute. Ces tests verifient donc
/// l'ABSENCE de ces elements autant que la presence du socle.
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

    testWidgets('rend la tuile meteo STUB (D3) et la salutation',
        (tester) async {
      await pumpTallHub(tester);

      expect(find.text(t.hub.weather.title), findsOneWidget);
      expect(find.text(t.hub.weather.stub), findsOneWidget);
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
}

/// Notifier factice pilotant l'etat expose du trek (voir tracking_overlay_test).
class _FakeTrekNotifier extends TrekSessionManagerNotifier {
  _FakeTrekNotifier(this._initial);
  final TrackingSessionState _initial;

  @override
  TrackingSessionState build() => _initial;
}
