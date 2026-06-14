import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/community/data/waypoint_service.dart';
import 'package:moteur_gr/features/community/presentation/waypoint_contribution_screen.dart';
import 'package:moteur_gr/features/map/providers/location_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Position fixe pour les tests (pas de GPS reel).
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

/// Tests widget du formulaire de contribution communautaire offline (F8A-05).
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  final locationOverride =
      locationProvider.overrideWith((ref) => Stream.value(_fakePosition()));

  Widget wrap(Widget child) => ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          locationOverride,
        ],
        child: TranslationProvider(child: MaterialApp(home: child)),
      );

  group('WaypointContributionScreen — nouveau waypoint offline', () {
    testWidgets('affiche le choix de type, le champ titre et le bandeau latence',
        (tester) async {
      await tester.pumpWidget(wrap(const WaypointContributionScreen()));
      await tester.pumpAndSettle();

      expect(find.text(t.waypoints.contribution.titleWaypoint), findsWidgets);
      expect(find.byKey(const ValueKey('contribution-type-eau')), findsOneWidget);
      expect(find.byKey(const ValueKey('contribution-title-field')),
          findsOneWidget);
      expect(find.text(t.waypoints.contribution.latencyBanner), findsOneWidget);
    });

    testWidgets('enregistre un waypoint EN LOCAL (offline) et bascule la vue',
        (tester) async {
      await tester.pumpWidget(wrap(const WaypointContributionScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('contribution-title-field')),
        'Source trouvee',
      );
      await tester.tap(
          find.byKey(const ValueKey('waypoint-contribution-submit')));
      await tester.pumpAndSettle();

      // Vue de confirmation affichee.
      expect(find.text(t.waypoints.contribution.savedTitle), findsOneWidget);
      expect(
          find.text(t.waypoints.contribution.savedPendingSync), findsOneWidget);

      // Le waypoint est bien en cache local avec source communaute.
      final service = WaypointService(
        database: db,
        remoteSink: const _NoopSink(),
      );
      final wps = await service.waypointsForTrail('mare_a_mare_centre');
      expect(wps.length, 1);
      expect(wps.first.titre, 'Source trouvee');
      expect(wps.first.source, WaypointSource.communaute);
    });

    testWidgets('titre vide : refus avec message, pas de bascule',
        (tester) async {
      await tester.pumpWidget(wrap(const WaypointContributionScreen()));
      await tester.pumpAndSettle();

      await tester.tap(
          find.byKey(const ValueKey('waypoint-contribution-submit')));
      await tester.pumpAndSettle();

      // Reste sur le formulaire (pas de vue de confirmation).
      expect(find.text(t.waypoints.contribution.savedTitle), findsNothing);
    });
  });

  group('WaypointContributionScreen — commentaire de condition offline', () {
    testWidgets('affiche les champs commentaire + condition', (tester) async {
      await tester.pumpWidget(
        wrap(const WaypointContributionScreen(targetWaypointId: 'wp-1')),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.waypoints.contribution.titleComment), findsWidgets);
      expect(find.byKey(const ValueKey('contribution-comment-field')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('contribution-condition-field')),
          findsOneWidget);
    });

    testWidgets('enregistre un commentaire pending (offline) et bascule la vue',
        (tester) async {
      await tester.pumpWidget(
        wrap(const WaypointContributionScreen(targetWaypointId: 'wp-1')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('contribution-comment-field')),
        'Source a sec',
      );
      await tester.enterText(
        find.byKey(const ValueKey('contribution-condition-field')),
        'eau_a_sec',
      );
      await tester.tap(
          find.byKey(const ValueKey('waypoint-contribution-submit')));
      await tester.pumpAndSettle();

      expect(find.text(t.waypoints.contribution.savedTitle), findsOneWidget);

      // Le commentaire est en file pending (offline-first).
      final service = WaypointService(
        database: db,
        remoteSink: const _NoopSink(),
      );
      expect(await service.pendingCount(), 1);
      final comments = await service.visibleComments('wp-1');
      expect(comments.single.texte, 'Source a sec');
      expect(comments.single.condition, 'eau_a_sec');
      expect(comments.single.syncState, 'pending');
    });

    testWidgets('commentaire vide : refus, pas de bascule', (tester) async {
      await tester.pumpWidget(
        wrap(const WaypointContributionScreen(targetWaypointId: 'wp-1')),
      );
      await tester.pumpAndSettle();

      await tester.tap(
          find.byKey(const ValueKey('waypoint-contribution-submit')));
      await tester.pumpAndSettle();

      expect(find.text(t.waypoints.contribution.savedTitle), findsNothing);
    });
  });
}

/// Sink no-op : la contribution reste locale (offline-first) dans ces tests.
class _NoopSink implements WaypointRemoteSink {
  const _NoopSink();

  @override
  Future<WaypointPushResult> pushWaypoint(WaypointData waypoint) async =>
      const WaypointPushResult.failure('noop');

  @override
  Future<WaypointPushResult> pushComment(WaypointCommentData comment) async =>
      const WaypointPushResult.failure('noop');

  @override
  Future<WaypointRemotePull> pull({
    required String trailId,
    DateTime? since,
  }) async =>
      const WaypointRemotePull();
}
