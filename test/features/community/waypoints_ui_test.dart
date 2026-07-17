import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:moteur_gr/core/data/daos/waypoints_dao.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/community/data/waypoint_service.dart';
import 'package:moteur_gr/features/community/presentation/waypoint_detail_sheet.dart';
import 'package:moteur_gr/features/community/presentation/waypoint_filters_panel.dart';
import 'package:moteur_gr/features/community/presentation/waypoints_map_layer.dart';
import 'package:moteur_gr/features/community/providers/waypoint_ui_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Tests widget de l'UI carte waypoints + filtres FarOut + detail (F8A-04).
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  // Override du provider DB par une base in-memory partagee dans le test.
  Widget wrap(Widget child, {List<Override> overrides = const []}) =>
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), ...overrides],
        child: TranslationProvider(
          child: MaterialApp(home: Scaffold(body: child)),
        ),
      );

  WaypointView makeView({
    String id = 'wp-1',
    String type = WaypointType.eau,
    String titre = 'Source',
    DateTime? updatedAt,
    String source = WaypointSource.communaute,
  }) =>
      WaypointView(
        id: id,
        trailId: 'mare_a_mare_centre',
        type: type,
        latitude: 42.0,
        longitude: 9.0,
        titre: titre,
        lastUpdatedAt: updatedAt ?? DateTime.utc(2026, 6, 14, 9),
        source: source,
      );

  group('WaypointsMapLayer — markers par type + filtre FarOut', () {
    Widget mapWith(List<WaypointView> wps, Set<String> visible,
        {void Function(WaypointView)? onTap}) {
      return wrap(
        FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(42.0, 9.0),
            initialZoom: 12,
          ),
          children: [
            WaypointsMapLayer(
              waypoints: wps,
              visibleTypes: visible,
              onTap: onTap,
            ),
          ],
        ),
      );
    }

    testWidgets('affiche un marqueur par waypoint visible', (tester) async {
      await tester.pumpWidget(mapWith(
        [makeView(id: 'wp-1'), makeView(id: 'wp-2', type: WaypointType.danger)],
        {WaypointType.eau, WaypointType.danger},
      ));
      await tester.pump();

      expect(find.byKey(const ValueKey('waypoint-marker-wp-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('waypoint-marker-wp-2')), findsOneWidget);
    });

    testWidgets('le filtre par type masque les waypoints non selectionnes',
        (tester) async {
      await tester.pumpWidget(mapWith(
        [makeView(id: 'wp-1', type: WaypointType.eau),
         makeView(id: 'wp-2', type: WaypointType.danger)],
        {WaypointType.eau}, // seul 'eau' visible
      ));
      await tester.pump();

      expect(find.byKey(const ValueKey('waypoint-marker-wp-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('waypoint-marker-wp-2')), findsNothing);
    });

    testWidgets('tap sur un marqueur declenche le callback', (tester) async {
      WaypointView? tapped;
      await tester.pumpWidget(mapWith(
        [makeView(id: 'wp-1')],
        {WaypointType.eau},
        onTap: (w) => tapped = w,
      ));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('waypoint-marker-wp-1')));
      expect(tapped?.id, 'wp-1');
    });
  });

  group('WaypointFiltersPanel — Comment Filtering FarOut', () {
    testWidgets('affiche un chip par type et le titre', (tester) async {
      await tester.pumpWidget(wrap(const WaypointFiltersPanel()));
      await tester.pumpAndSettle();

      expect(find.text(t.waypoints.filters.title), findsOneWidget);
      for (final type in WaypointType.values) {
        expect(find.byKey(ValueKey('waypoint-filter-type-$type')),
            findsOneWidget);
      }
    });

    testWidgets('toggle d un type met a jour l etat du filtre', (tester) async {
      late WidgetRef ref;
      await tester.pumpWidget(wrap(
        Consumer(builder: (ctx, r, _) {
          ref = r;
          return const WaypointFiltersPanel();
        }),
      ));
      await tester.pumpAndSettle();

      // Etat initial : tous visibles.
      expect(
        ref.read(waypointFilterProvider).isTypeVisible(WaypointType.eau),
        isTrue,
      );

      await tester.tap(
        find.byKey(const ValueKey('waypoint-filter-type-eau')),
      );
      await tester.pumpAndSettle();

      expect(
        ref.read(waypointFilterProvider).isTypeVisible(WaypointType.eau),
        isFalse,
      );
    });

    testWidgets('hideAll puis showAll basculent tous les types',
        (tester) async {
      late WidgetRef ref;
      await tester.pumpWidget(wrap(
        Consumer(builder: (ctx, r, _) {
          ref = r;
          return const WaypointFiltersPanel();
        }),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('waypoint-filter-hide-all')));
      await tester.pumpAndSettle();
      expect(ref.read(waypointFilterProvider).visibleTypes, isEmpty);

      await tester.tap(find.byKey(const ValueKey('waypoint-filter-show-all')));
      await tester.pumpAndSettle();
      expect(
        ref.read(waypointFilterProvider).visibleTypes.length,
        WaypointType.values.length,
      );
    });

    testWidgets('toggle condition recente met a jour l etat', (tester) async {
      late WidgetRef ref;
      await tester.pumpWidget(wrap(
        Consumer(builder: (ctx, r, _) {
          ref = r;
          return const WaypointFiltersPanel();
        }),
      ));
      await tester.pumpAndSettle();

      expect(
        ref.read(waypointFilterProvider).recentConditionOnly,
        isFalse,
      );
      await tester.tap(
        find.byKey(const ValueKey('waypoint-filter-recent-condition')),
      );
      await tester.pumpAndSettle();
      expect(
        ref.read(waypointFilterProvider).recentConditionOnly,
        isTrue,
      );
    });
  });

  group('WaypointDetailSheet — detail + commentaires offline + freshness + signaler', () {
    Future<void> seedComment(String waypointId, String texte,
        {String? condition, String moderationState = 'visible'}) async {
      final dao = WaypointsDao(db);
      await dao.addCommentLocal(WaypointCommentCompanion(
        waypointId: Value(waypointId),
        authorUidHash: const Value('hash-aaa'),
        texte: Value(texte),
        condition: Value(condition),
        createdAt: Value(DateTime.utc(2026, 6, 14, 10)),
        moderationState: Value(moderationState),
      ));
    }

    testWidgets('affiche le titre, la fraicheur et le bouton Signaler',
        (tester) async {
      await tester.pumpWidget(wrap(
        WaypointDetailSheet(
          waypoint: makeView(titre: 'Source du col',
              updatedAt: DateTime.utc(2026, 6, 14, 9)),
          now: DateTime.utc(2026, 6, 14, 11), // 2h plus tard
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Source du col'), findsOneWidget);
      expect(find.text(t.waypoints.freshness.hours(n: 2)), findsOneWidget);
      expect(find.byKey(const ValueKey('waypoint-report-button')),
          findsOneWidget);
      expect(find.text(t.waypoints.detail.report), findsOneWidget);
    });

    testWidgets('affiche les commentaires de condition lus du cache offline',
        (tester) async {
      await seedComment('wp-1', 'Source a sec', condition: 'eau_a_sec');
      await tester.pumpWidget(wrap(
        WaypointDetailSheet(waypoint: makeView(id: 'wp-1')),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Source a sec'), findsOneWidget);
      expect(find.text('eau_a_sec'), findsOneWidget);
    });

    testWidgets('un commentaire removed est masque (DSA)', (tester) async {
      await seedComment('wp-1', 'visible-cmt', moderationState: 'visible');
      await seedComment('wp-1', 'removed-cmt', moderationState: 'removed');
      await tester.pumpWidget(wrap(
        WaypointDetailSheet(waypoint: makeView(id: 'wp-1')),
      ));
      await tester.pumpAndSettle();

      expect(find.text('visible-cmt'), findsOneWidget);
      expect(find.text('removed-cmt'), findsNothing);
    });

    testWidgets('sans commentaire, affiche le message vide', (tester) async {
      await tester.pumpWidget(wrap(
        WaypointDetailSheet(waypoint: makeView(id: 'wp-empty')),
      ));
      await tester.pumpAndSettle();

      expect(find.text(t.waypoints.detail.noComments), findsOneWidget);
    });

    testWidgets('le bouton Signaler declenche le callback onReport',
        (tester) async {
      WaypointView? reported;
      await tester.pumpWidget(wrap(
        WaypointDetailSheet(
          waypoint: makeView(id: 'wp-1'),
          onReport: (w) => reported = w,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('waypoint-report-button')));
      await tester.pump();
      expect(reported?.id, 'wp-1');
    });
  });
}
