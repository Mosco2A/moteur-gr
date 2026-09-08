import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/feature_flags.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/core/config/trail_selection.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/core/services/wallet_iap_service.dart';
import 'package:moteur_gr/core/services/wallet_store.dart';
import 'package:moteur_gr/features/trek/domain/models/trek_session.dart';
import 'package:moteur_gr/features/treks/domain/trek_lifecycle_state.dart';
import 'package:moteur_gr/features/treks/providers/entitlements_provider.dart';
import 'package:moteur_gr/features/treks/providers/my_treks_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// StepWays LOT 2, Phases 1-2 — providers d'accueil multi-trek.
///
/// Sur la branche WALLET : `ownedTrailIdsProvider` = `TrekEntitlementsDao.owned`
/// ∪ vitrine (PAS le shim). `myTreksProvider` itere les owned -> TrekSummary
/// trie. `activeTrekIdProvider` = trek de la session en cours (C4).
class _FakeConnectivity extends ConnectivityMonitor {
  @override
  Future<ConnectivityStatus> checkStatus() async =>
      ConnectivityStatusValues.online;
}

TrailConfig _config(String id, {bool showcase = false, int stages = 10}) =>
    TrailConfig(
      id: id,
      name: id,
      displayName: id,
      tagline: 't',
      totalStages: stages,
      totalDistanceKm: 100,
      totalElevationGain: 5000,
      region: 'R',
      country: 'France',
      primaryColorValue: 0xFF2E7D32,
      secondaryColorValue: 0xFF1565C0,
      gpxAssetPath: 'assets/gpx/$id.gpx',
      isShowcaseTrail: showcase,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late WalletStore wallet;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FeatureFlags.clearOverrides();
    db = AppDatabase(NativeDatabase.memory());
    wallet = WalletStore(db: db, prefs: await SharedPreferences.getInstance());
    addTearDown(wallet.dispose);
  });

  tearDown(() async {
    FeatureFlags.clearOverrides();
    await db.close();
  });

  Future<MonetizationService> readyService() async {
    final prefs = await SharedPreferences.getInstance();
    final iap = WalletIapService(
      walletStore: wallet,
      noAdsDao: db.noAdsDao,
      testMode: true,
    );
    addTearDown(iap.stopListening);
    final svc = MonetizationService(
      walletStore: wallet,
      entitlementsDao: db.trekEntitlementsDao,
      noAdsDao: db.noAdsDao,
      iapService: iap,
      connectivityMonitor: _FakeConnectivity(),
      prefs: prefs,
      showcaseTrailIds: const {},
    );
    await svc.load();
    return svc;
  }

  /// Container cable sur la DB in-memory. Le catalogue (availableTrailsProvider)
  /// est injecte pour maitriser vitrine + presence au catalogue.
  ProviderContainer makeContainer(List<TrailConfig> catalog) {
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      availableTrailsProvider.overrideWithValue(catalog),
      // Seul le fait que le boot soit "pret" compte : on court-circuite la
      // chaine ST4 en fournissant un service deja charge.
      monetizationReadyProvider.overrideWith((ref) => readyService()),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  Future<void> markOwned(String trailId) async {
    await db.trekEntitlementsDao.upsert(
      TrekEntitlementsCompanion.insert(
        trailId: trailId,
        owned: const Value(true),
        updatedAt: DateTime.utc(2026, 6, 1),
      ),
    );
  }

  TrekSession session(
    String trailId, {
    required String id,
    String status = 'active',
    DateTime? startedAt,
    DateTime? finishedAt,
    List<String> completed = const [],
  }) =>
      TrekSession(
        id: id,
        trailId: trailId,
        startedAt: startedAt ?? DateTime.utc(2026, 6, 15, 8),
        finishedAt: finishedAt,
        status: status,
        completedStages: completed,
      );

  group('ownedTrailIdsProvider — owned ∪ vitrine (branche wallet)', () {
    test('union des droits owned et des sentiers vitrine', () async {
      await markOwned('gr20');
      // gr10 non owned -> exclu ; vitrine incluse sans achat.
      final container = makeContainer([
        _config('gr20'),
        _config('gr10'),
        _config('demo', showcase: true),
      ]);

      final ids = await container.read(ownedTrailIdsProvider.future);
      expect(ids, {'gr20', 'demo'});
    });

    test('trek abandonne (owned=false, acquis>0) N EST PAS possede', () async {
      // Simule un abandon : owned repasse false mais acquiredStages conserve.
      await db.trekEntitlementsDao.upsert(
        TrekEntitlementsCompanion.insert(
          trailId: 'gr20',
          owned: const Value(false),
          acquiredStages: const Value(3),
          updatedAt: DateTime.utc(2026, 6, 1),
        ),
      );
      final container = makeContainer([_config('gr20')]);

      final ids = await container.read(ownedTrailIdsProvider.future);
      expect(ids, isEmpty, reason: 'owned=false -> pas dans Mes treks.');
    });
  });

  group('myTreksProvider — TrekSummary trie', () {
    test('derive l etat de chaque trek possede', () async {
      await markOwned('gr20'); // en cours
      await markOwned('gr10'); // termine
      await markOwned('tmb'); // owned vierge

      await db.trekSessionsDao.upsertSession(
        session('gr20', id: 'a', status: 'active'),
      );
      await db.trekSessionsDao.upsertSession(session(
        'gr10',
        id: 'b',
        status: 'completed',
        finishedAt: DateTime.utc(2026, 5, 20, 17),
      ));

      final container = makeContainer([
        _config('gr20'),
        _config('gr10'),
        _config('tmb'),
      ]);

      final treks = await container.read(myTreksProvider.future);
      final byId = {for (final t in treks) t.trailId: t};

      expect(byId['gr20']!.state, TrekLifecycleState.inProgress);
      expect(byId['gr10']!.state, TrekLifecycleState.completed);
      expect(byId['tmb']!.state, TrekLifecycleState.owned);
    });

    test('tri : en cours d abord, puis termines en fin de liste', () async {
      await markOwned('gr20');
      await markOwned('gr10');
      await markOwned('tmb');

      await db.trekSessionsDao
          .upsertSession(session('gr20', id: 'a', status: 'active'));
      await db.trekSessionsDao.upsertSession(session(
        'gr10',
        id: 'b',
        status: 'completed',
        finishedAt: DateTime.utc(2026, 5, 20, 17),
      ));
      // tmb : prepared (progression sans session).
      await db.progressDao.upsert(
        UserProgressEntriesCompanion.insert(
          trailId: 'tmb',
          startedAt: Value(DateTime.utc(2026, 6, 10)),
        ),
      );

      final container = makeContainer([
        _config('gr20'),
        _config('gr10'),
        _config('tmb'),
      ]);

      final treks = await container.read(myTreksProvider.future);
      expect(treks.first.trailId, 'gr20',
          reason: 'La rando en cours est en tete.');
      expect(treks.last.state, TrekLifecycleState.completed,
          reason: 'Les termines ferment la liste.');
    });

    test('id possede absent du catalogue -> ignore', () async {
      await markOwned('retire'); // pas dans le catalogue
      await markOwned('gr20');
      final container = makeContainer([_config('gr20')]);

      final treks = await container.read(myTreksProvider.future);
      expect(treks.map((t) => t.trailId), ['gr20']);
    });
  });

  group('activeTrekIdProvider — invariant C4', () {
    test('null si aucune session en cours', () async {
      final container = makeContainer([_config('gr20')]);
      expect(await container.read(activeTrekIdProvider.future), isNull);
    });

    test('renvoie le trek de la session active OU paused', () async {
      await db.trekSessionsDao
          .upsertSession(session('gr20', id: 'a', status: 'paused'));
      final container = makeContainer([_config('gr20')]);
      expect(await container.read(activeTrekIdProvider.future), 'gr20');
    });

    test('ignore les sessions completed/abandoned', () async {
      await db.trekSessionsDao.upsertSession(
          session('gr20', id: 'a', status: 'completed'));
      await db.trekSessionsDao.upsertSession(
          session('gr10', id: 'b', status: 'abandoned'));
      final container = makeContainer([_config('gr20'), _config('gr10')]);
      expect(await container.read(activeTrekIdProvider.future), isNull);
    });
  });
}
