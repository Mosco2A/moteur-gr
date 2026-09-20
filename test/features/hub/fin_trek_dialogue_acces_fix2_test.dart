import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/features/hub/presentation/widgets/finish_trek_button.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';
import 'package:moteur_gr/features/treks/providers/my_treks_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// NON-REGRESSION — LOT FIX-2, finding M4 (volet « acces au dialogue »).
///
/// OBSERVE AU ROUND 1 (capture `S3_Steve_11_apres_terminer`) : la confirmation
/// « Terminer le trek ? » est restee OUVERTE. Sa barriere modale a alors avale
/// tous les appuis suivants — d'ou la cascade de symptomes rapportee : Diplome
/// introuvable, Journal « present dans l'arbre mais non tapable » (hit-test
/// vide), Recapitulatif non atteint, champ de note introuvable. Les artefacts
/// n'etaient pas casses : ils etaient derriere une barriere.
///
/// POURQUOI LE DIALOGUE NE SE REFERMAIT PAS : trois libelles commencent par le
/// meme mot — le bouton du cockpit « Terminer le trek », le titre « Terminer le
/// trek ? » et l'action « Terminer ». Designer la confirmation par son libelle
/// vise donc potentiellement le bouton RESTE SOUS la barriere, et l'appui ne
/// produit rien.
///
/// CE QUE CES TESTS VERROUILLENT : chaque action du parcours de fin est
/// atteignable par une CLE stable, et la confirmation par la cle ferme bien le
/// dialogue et enchaine sur le recapitulatif.
class _FakeTrek extends TrekSessionManagerNotifier {
  _FakeTrek(this._initial);
  final TrackingSessionState _initial;

  int stopCount = 0;

  @override
  TrackingSessionState build() => _initial;

  /// Neutralise la finalisation reelle (services GPS/base) : ce test porte sur
  /// l'ACCES aux actions, pas sur la machine de session (couverte par
  /// `test/features/treks/providers/fin_trek_acces_apres_fix2_test.dart`).
  @override
  Future<void> stop() async {
    stopCount++;
    state = state.copyWith(status: TrackingSessionStatus.stopped);
  }
}

void main() {
  late _FakeTrek fake;

  Widget wrap() {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(
            body: SingleChildScrollView(child: FinishTrekButton()),
          ),
        ),
        GoRoute(
          path: '/trail/:id/recap',
          builder: (_, __) => const Text('RECAP_STUB'),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        trailConfigProvider.overrideWithValue(_config),
        trekSessionManagerProvider.overrideWith(() => fake),
        currentTrailSummaryProvider.overrideWith((ref) async => null),
      ],
      child: TranslationProvider(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  setUp(() {
    fake = _FakeTrek(
      const TrackingSessionState(status: TrackingSessionStatus.recording),
    );
  });

  testWidgets('le bouton de fin et les deux actions portent une cle stable',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey(kFinishTrekButtonKey)), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey(kFinishTrekButtonKey)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey(kFinishTrekDialogKey)), findsOneWidget);
    expect(find.byKey(const ValueKey(kFinishTrekConfirmKey)), findsOneWidget);
    expect(find.byKey(const ValueKey(kFinishTrekCancelKey)), findsOneWidget);
  });

  testWidgets('le libelle seul est AMBIGU — c est pourquoi il faut les cles',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey(kFinishTrekButtonKey)));
    await tester.pumpAndSettle();

    // Le mot « Terminer » designe a lui seul PLUSIEURS cibles a l'ecran : le
    // bouton du cockpit (sous la barriere), le titre, et l'action. Viser par le
    // libelle, c est risquer de taper dans le vide et de laisser la barriere en
    // place. Ce test fige la raison d etre des cles.
    expect(
      find.textContaining(t.hub.finishTrek.confirm),
      findsAtLeast(2),
      reason: 'si un jour ce libelle devient unique, les cles restent la bonne '
          'facon de designer les actions, mais le piege aura disparu',
    );
  });

  testWidgets('confirmer par la cle ferme le dialogue ET ouvre le recap',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey(kFinishTrekButtonKey)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey(kFinishTrekConfirmKey)));
    await tester.pumpAndSettle();

    // Plus de barriere modale : c est ce qui bloquait TOUT le post-trek.
    expect(find.byKey(const ValueKey(kFinishTrekDialogKey)), findsNothing);
    expect(fake.stopCount, 1);
    expect(find.text('RECAP_STUB'), findsOneWidget);
  });

  testWidgets('annuler par la cle ferme le dialogue sans terminer',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey(kFinishTrekButtonKey)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey(kFinishTrekCancelKey)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey(kFinishTrekDialogKey)), findsNothing);
    expect(fake.stopCount, 0);
    expect(find.text('RECAP_STUB'), findsNothing);
  });
}

/// Sentier de test neutre — aucun toponyme reel (cloisonnement #326).
const _config = TrailConfig(
  id: 'sentier-test',
  name: 'sentier-test',
  displayName: 'Sentier de test',
  tagline: 'parcours de test',
  totalStages: 5,
  totalDistanceKm: 50,
  totalElevationGain: 2000,
  region: 'Region de test',
  country: 'Pays de test',
  primaryColorValue: 0xFF2E7D32,
  secondaryColorValue: 0xFF1565C0,
  gpxAssetPath: 'assets/gpx/test.gpx',
);
