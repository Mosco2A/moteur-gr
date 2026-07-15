import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moteur_gr/features/map/providers/location_provider.dart';
import 'package:moteur_gr/features/safety/data/signalement_service.dart';
import 'package:moteur_gr/features/safety/presentation/signalement_screen.dart';
import 'package:moteur_gr/features/safety/providers/signalement_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Position fixe pour les tests (pas de GPS réel).
Position _fakePosition() => Position(
      latitude: 42.1,
      longitude: 9.1,
      timestamp: DateTime.utc(2026, 6, 14),
      accuracy: 5,
      altitude: 1000,
      altitudeAccuracy: 5,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

/// Tests widget de l'écran de signalement terrain (F6C-03).
///
/// Vérifie : les 3 types proposés, le bandeau de latence (pas de promesse temps
/// réel), la confirmation 1 geste qui crée un signalement local et bascule sur
/// la vue « enregistré », et le changement de type sélectionné.
void main() {
  Widget wrap(List<Override> overrides) => ProviderScope(
        overrides: overrides,
        child: TranslationProvider(
          child: const MaterialApp(home: SignalementScreen()),
        ),
      );

  final locationOverride =
      locationProvider.overrideWith((ref) => Stream.value(_fakePosition()));

  group('SignalementScreen', () {
    testWidgets('affiche le titre et les 3 types', (tester) async {
      await tester.pumpWidget(wrap([locationOverride]));
      await tester.pumpAndSettle();

      expect(find.text(t.signalement.title), findsWidgets);
      expect(find.text(t.signalement.types.obstacle), findsOneWidget);
      expect(find.text(t.signalement.types.eauASec), findsOneWidget);
      expect(find.text(t.signalement.types.danger), findsOneWidget);
    });

    testWidgets('affiche le bandeau de latence (pas de temps réel)',
        (tester) async {
      await tester.pumpWidget(wrap([locationOverride]));
      await tester.pumpAndSettle();

      expect(find.text(t.signalement.latencyBanner), findsOneWidget);
    });

    testWidgets('la confirmation crée un signalement local et bascule la vue',
        (tester) async {
      await tester.pumpWidget(wrap([locationOverride]));
      await tester.pumpAndSettle();

      // Geste unique de confirmation.
      await tester.tap(find.text(t.signalement.confirm));
      await tester.pumpAndSettle();

      // Vue « enregistré » affichée (état en attente de sync).
      expect(find.text(t.signalement.savedTitle), findsOneWidget);
      expect(find.text(t.signalement.savedPendingSync), findsOneWidget);
    });

    testWidgets('le signalement créé est bien en file locale pending',
        (tester) async {
      final container = ProviderContainer(overrides: [locationOverride]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: TranslationProvider(
            child: const MaterialApp(home: SignalementScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.signalement.confirm));
      await tester.pumpAndSettle();

      final service = container.read(signalementServiceProvider);
      final pending = await service.pendingCount();
      expect(pending, 1);

      final reports = await service.localReports();
      expect(reports.single.type, SignalementType.obstacle);
      expect(reports.single.synced, isFalse);
    });

    testWidgets('change le type sélectionné au tap', (tester) async {
      await tester.pumpWidget(wrap([locationOverride]));
      await tester.pumpAndSettle();

      // Sélectionne « danger », puis confirme.
      await tester.tap(find.text(t.signalement.types.danger));
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.signalement.confirm));
      await tester.pumpAndSettle();

      expect(find.text(t.signalement.savedTitle), findsOneWidget);
    });
  });
}
