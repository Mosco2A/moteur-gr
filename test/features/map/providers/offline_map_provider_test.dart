import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/map/mbtiles_manager.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/features/map/providers/offline_map_provider.dart';

/// Fake MBTilesManager pour les tests sans filesystem.
class FakeMBTilesManager extends MBTilesManager {
  FakeMBTilesManager() : super();

  final Set<String> _available = {};

  void addTrail(String trailId) => _available.add(trailId);
  void removeTrail(String trailId) => _available.remove(trailId);

  @override
  Future<bool> hasMbtiles(String trailId) async => _available.contains(trailId);

  @override
  Future<List<String>> listDownloaded() async => _available.toList();
}

/// Fake ConnectivityMonitor pour controler le statut reseau.
class FakeConnectivityMonitor extends ConnectivityMonitor {
  ConnectivityStatus _status = ConnectivityStatusValues.online;
  void setStatus(ConnectivityStatus s) => _status = s;

  @override
  Future<ConnectivityStatus> checkStatus() async => _status;

  @override
  Stream<ConnectivityStatus> get onStatusChange => Stream.value(_status);
}

void main() {
  group('OfflineMapStatus', () {
    late FakeMBTilesManager fakeMbtiles;
    late FakeConnectivityMonitor fakeConnectivity;
    late ProviderContainer container;

    setUp(() {
      fakeMbtiles = FakeMBTilesManager();
      fakeConnectivity = FakeConnectivityMonitor();

      container = ProviderContainer(
        overrides: [
          mbtilesManagerProvider.overrideWithValue(fakeMbtiles),
          connectivityMonitorProvider.overrideWithValue(fakeConnectivity),
          connectivityProvider.overrideWith((ref) async* {
            yield await fakeConnectivity.checkStatus();
          }),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('online sans tuiles locales -> OfflineMapStatus.online', () async {
      fakeConnectivity.setStatus(ConnectivityStatusValues.online);

      // Materialiser le statut de connectivite avant de lire le provider
      // combine (qui lit connectivityProvider via valueOrNull, non bloquant).
      await container.read(connectivityProvider.future);

      final result = await container.read(
        offlineMapStatusProvider('trail1').future,
      );

      expect(result, OfflineMapStatusValues.online);
    });

    test('online avec tuiles locales -> OfflineMapStatus.offlineAvailable', () async {
      fakeConnectivity.setStatus(ConnectivityStatusValues.online);
      fakeMbtiles.addTrail('trail2');

      await container.read(connectivityProvider.future);

      final result = await container.read(
        offlineMapStatusProvider('trail2').future,
      );

      expect(result, OfflineMapStatusValues.offlineAvailable);
    });

    test('offline avec tuiles locales -> OfflineMapStatus.offlineOnly', () async {
      fakeConnectivity.setStatus(ConnectivityStatusValues.offline);
      fakeMbtiles.addTrail('trail3');

      await container.read(connectivityProvider.future);

      final result = await container.read(
        offlineMapStatusProvider('trail3').future,
      );

      expect(result, OfflineMapStatusValues.offlineOnly);
    });

    test('offline sans tuiles locales -> OfflineMapStatus.noMap', () async {
      fakeConnectivity.setStatus(ConnectivityStatusValues.offline);

      await container.read(connectivityProvider.future);

      final result = await container.read(
        offlineMapStatusProvider('trail4').future,
      );

      expect(result, OfflineMapStatusValues.noMap);
    });
  });

  group('isOfflineMapAvailableProvider', () {
    late FakeMBTilesManager fakeMbtiles;
    late ProviderContainer container;

    setUp(() {
      fakeMbtiles = FakeMBTilesManager();
      container = ProviderContainer(
        overrides: [
          mbtilesManagerProvider.overrideWithValue(fakeMbtiles),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('retourne false sans tuiles locales', () async {
      final result = await container.read(
        isOfflineMapAvailableProvider('absent').future,
      );
      expect(result, isFalse);
    });

    test('retourne true avec tuiles locales', () async {
      fakeMbtiles.addTrail('present');

      final result = await container.read(
        isOfflineMapAvailableProvider('present').future,
      );
      expect(result, isTrue);
    });
  });
}
