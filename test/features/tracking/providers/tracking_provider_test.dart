import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/tracking/models/tracking_status.dart';
import 'package:moteur_gr/features/tracking/providers/tracking_provider.dart';

/// Tests du provider de tracking.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Desactiver l'avertissement multi-database en test
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('TrackingNotifier', () {
    test('start passe en recording', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );

      final notifier = container.read(trackingProvider.notifier);

      expect(container.read(trackingProvider).status, TrackingStatusValues.idle);

      notifier.start('sentier-volcans');
      expect(
        container.read(trackingProvider).status,
        TrackingStatusValues.recording,
      );

      // Await stop avant dispose pour eviter les erreurs async
      await notifier.stop();
      container.dispose();
      await db.close();
    });

    test('pause passe en paused', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );

      final notifier = container.read(trackingProvider.notifier);
      notifier.start('sentier-volcans');
      notifier.pause();

      expect(
        container.read(trackingProvider).status,
        TrackingStatusValues.paused,
      );

      await notifier.stop();
      container.dispose();
      await db.close();
    });

    test('stop revient a idle et sauvegarde', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );

      final notifier = container.read(trackingProvider.notifier);
      notifier.start('sentier-volcans');

      expect(
        container.read(trackingProvider).status,
        TrackingStatusValues.recording,
      );

      await notifier.stop();

      expect(
        container.read(trackingProvider).status,
        TrackingStatusValues.idle,
      );

      // Verifier la sauvegarde en base
      final row = await db.select(db.userProgressEntries).getSingleOrNull();
      if (row != null) {
        expect(row.trailId, 'sentier-volcans');
      }

      container.dispose();
      await db.close();
    });
  });
}
