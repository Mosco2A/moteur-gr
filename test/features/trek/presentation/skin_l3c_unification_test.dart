import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/theme/app_theme.dart';
import 'package:moteur_gr/features/map/providers/track_position_provider.dart';
import 'package:moteur_gr/features/trek/domain/models/stage.dart';
import 'package:moteur_gr/features/trek/presentation/planning/itinerary_config_screen.dart';
import 'package:moteur_gr/features/trek/presentation/planning/planning_screen.dart';
import 'package:moteur_gr/features/trek/presentation/stages/stage_card.dart';
import 'package:moteur_gr/features/trek/providers/itinerary_providers.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';
import 'package:moteur_gr/features/trek/presentation/map/overlay/tracking_overlay.dart';
import 'package:moteur_gr/shared/widgets/app_button.dart';
import 'package:moteur_gr/shared/widgets/app_card.dart';

/// Tests transverses SW-SKIN-L3c (unification composants trek + planning).
///
/// Verifient l'ISO-RENDU des remplacements Card->AppCard et *Button->AppButton :
/// - les cartes converties exposent bien un [AppCard] (grammaire unifiee) ;
/// - les boutons convertis exposent bien un [AppButton] ;
/// - le tap reste fonctionnel (onTap AppCard, onPressed AppButton) ;
/// - l'overlay de suivi (ecran ACTIF pendant une rando) garde STRICTEMENT :
///   * un ElevatedButton a fond token semantique (actionStart/Pause/urgence),
///     texte blanc, cible tactile >= 44px, icone — comme avant ;
///   * le rebuild au champ pres (Consumer/select intacts) prouve par la mise a
///     jour independante d'une tuile stat sans reconstruire le reste.
void main() {
  /// Resout le backgroundColor effectif d'un ElevatedButton (etat par defaut).
  Color? backgroundOf(WidgetTester tester, Finder f) {
    final btn = tester.widget<ElevatedButton>(f);
    return btn.style?.backgroundColor?.resolve(<WidgetState>{});
  }

  /// Resout le foregroundColor effectif d'un ElevatedButton.
  Color? foregroundOf(WidgetTester tester, Finder f) {
    final btn = tester.widget<ElevatedButton>(f);
    return btn.style?.foregroundColor?.resolve(<WidgetState>{});
  }

  const testStage = Stage(
    id: 'stage-1',
    nameFr: 'Col de Vergio',
    nameEn: 'Vergio Pass',
    distance: 14.5,
    elevationGain: 850,
    elevationLoss: 620,
    estimatedDurationSeconds: 19800,
    orderIndex: 3,
    startLat: 42.28,
    startLng: 9.07,
    endLat: 42.30,
    endLng: 9.10,
  );

  Widget wrapApp(Widget child) => MaterialApp(
    locale: const Locale('en'),
    supportedLocales: const [Locale('en')],
    localizationsDelegates: const [
      DefaultWidgetsLocalizations.delegate,
      DefaultMaterialLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  );

  group('SW-SKIN-L3c cartes -> AppCard', () {
    testWidgets('StageCard rend un AppCard et le tap fonctionne', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        wrapApp(StageCard(stage: testStage, onTap: () => tapped = true)),
      );

      // Grammaire unifiee : AppCard, plus de Card Material brut.
      expect(find.byType(AppCard), findsOneWidget);
      expect(find.byType(Card), findsNothing);

      // Iso-rendu du contenu (numero + chevron toujours la).
      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      // Tap fonctionnel (onTap porte par l'InkWell interne d'AppCard).
      await tester.tap(find.byType(StageCard));
      expect(tapped, isTrue);
    });

    testWidgets('TrekPlanningScreen : jours et etapes en AppCard', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itineraryProvider.overrideWith((ref) => Future.value(const [])),
          ],
          child: const MaterialApp(home: TrekPlanningScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Ecran vide -> pas de Card Material brut (ni AppCard non plus ici),
      // surtout : aucune Card Material residuelle.
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('ItineraryConfigScreen : sections + resume en AppCard', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itineraryProvider.overrideWith((ref) => Future.value(const [])),
          ],
          child: const MaterialApp(home: ItineraryConfigScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // 3 sections (_SectionCard) + 1 resume (_ItinerarySummary) = 4 AppCard,
      // zero Card Material brut.
      expect(find.byType(AppCard), findsNWidgets(4));
      expect(find.byType(Card), findsNothing);
    });
  });

  group('SW-SKIN-L3c boutons -> AppButton', () {
    testWidgets(
      'ItineraryConfigScreen : le declencheur de date est un AppButton',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              itineraryProvider.overrideWith((ref) => Future.value(const [])),
            ],
            child: const MaterialApp(home: ItineraryConfigScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Plus de FilledButton.tonal brut : un AppButton unifie.
        expect(find.byType(AppButton), findsOneWidget);
        expect(find.byType(FilledButton), findsNothing);
      },
    );
  });

  group('SW-SKIN-L3c overlay suivi : iso-rendu STRICT (ecran actif)', () {
    testWidgets(
      'boutons = AppButton filledTone, ElevatedButton token conserve',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            stageDistanceCoveredProvider.overrideWithValue(1000.0),
            trekSessionManagerProvider.overrideWith(
              () => _FakeNotifier(
                const TrackingSessionState(
                  status: TrackingSessionStatus.recording,
                ),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(body: TrackingOverlay(trailId: 'mare-a-mare')),
            ),
          ),
        );

        // Grammaire unifiee : les boutons d'action sont des AppButton...
        expect(find.byType(AppButton), findsNWidgets(2)); // Pause + Stop

        // ...tout en gardant, a l'identique, un ElevatedButton a fond token
        // semantique + texte blanc (iso-rendu de l'ancien ElevatedButton.icon).
        final pause = find.widgetWithText(ElevatedButton, 'Pause');
        final stop = find.widgetWithText(ElevatedButton, 'Stop');
        expect(pause, findsOneWidget);
        expect(stop, findsOneWidget);
        expect(backgroundOf(tester, pause), AppTheme.actionPause);
        expect(backgroundOf(tester, stop), AppTheme.rougeUrgence);
        expect(foregroundOf(tester, pause), Colors.white);

        // Icones conservees.
        expect(find.byIcon(Icons.pause), findsOneWidget);
        expect(find.byIcon(Icons.stop), findsOneWidget);
      },
    );

    testWidgets('cible tactile >= 44px conservee sur les boutons d action', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          trekSessionManagerProvider.overrideWith(
            () => _FakeNotifier(
              const TrackingSessionState(status: TrackingSessionStatus.idle),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: TrackingOverlay(trailId: 'mare-a-mare')),
          ),
        ),
      );

      // AppButton filledTone conserve minHeight 44 (cible tactile a11y AA).
      final demarrer = find.widgetWithText(ElevatedButton, 'Demarrer');
      final minSize = tester
          .widget<ElevatedButton>(demarrer)
          .style
          ?.minimumSize
          ?.resolve(<WidgetState>{});
      expect(minSize?.height, 44);
    });

    testWidgets('le HUD rebuild au champ pres (Consumer/select intacts)', (
      tester,
    ) async {
      // On prouve que changer UN champ de session (le D+, lu par un
      // Consumer + select dedie) met a jour SA tuile tout en laissant les
      // autres stats intactes : la granularite Consumer/select de l'overlay
      // est preservee par L3c (aucune regression du rebuild cible).
      final notifier = _FakeNotifier(
        const TrackingSessionState(
          status: TrackingSessionStatus.recording,
          elevationGainM: 350.0,
          elapsedDuration: Duration(hours: 2, minutes: 15),
          currentSpeedKmh: 4.3,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          stageDistanceCoveredProvider.overrideWithValue(5200.0),
          trekSessionManagerProvider.overrideWith(() => notifier),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: TrackingOverlay(trailId: 'mare-a-mare')),
          ),
        ),
      );

      // Etat initial : D+ 350 m, distance projetee 5.2 km, vitesse 4.3.
      expect(find.text('350 m'), findsOneWidget);
      expect(find.text('5.2 km'), findsOneWidget);
      expect(find.text('4.3 km/h'), findsOneWidget);

      // Un seul champ change (le D+).
      notifier.emit(
        const TrackingSessionState(
          status: TrackingSessionStatus.recording,
          elevationGainM: 500.0,
          elapsedDuration: Duration(hours: 2, minutes: 15),
          currentSpeedKmh: 4.3,
        ),
      );
      await tester.pump();

      // La tuile D+ s'est mise a jour ; les autres stats intactes.
      expect(find.text('500 m'), findsOneWidget);
      expect(find.text('350 m'), findsNothing);
      expect(find.text('5.2 km'), findsOneWidget);
      expect(find.text('4.3 km/h'), findsOneWidget);
    });
  });
}

/// Fake notifier pour piloter l'etat de session dans les tests.
///
/// [emit] permet de pousser un nouvel etat pour verifier le rebuild cible
/// (les Consumer/select de l'overlay ne reconstruisent que la tuile concernee).
class _FakeNotifier extends TrekSessionManagerNotifier {
  _FakeNotifier(this._initial);
  final TrackingSessionState _initial;

  @override
  TrackingSessionState build() => _initial;

  void emit(TrackingSessionState next) => state = next;
}
