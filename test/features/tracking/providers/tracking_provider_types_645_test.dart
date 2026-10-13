// LA CITATION QUI MANQUAIT — tache 645-04, concept C-4.
//
// POURQUOI CE TEST EXISTE. Le lot 645-04 a supprime
// `lib/features/tracking/presentation/tracking_overlay.dart`, un widget que
// RIEN n appelait : ni un fichier de `lib/`, ni un test, ni le routeur. En
// partant, il a emporte les seules citations de `TrackingState` et de
// `TrackingNotifier` hors de leur propre fichier, et la garde du code mort
// (`test/structurel/aucun_code_mort_645_test.dart`) les a aussitot comptes
// morts : 146 au lieu de 144.
//
// ILS NE LE SONT PAS. `trackingProvider` est vivant — `tracking_provider_test`
// l exerce, et l effacement de compte le reinitialise. Or un
// `NotifierProvider<TrackingNotifier, TrackingState>` ne peut pas exister sans
// ces deux types : ce que la garde a releve, ce n est pas qu ils sont inutiles,
// c est que plus personne ne les NOMME. C est exactement le cas que son propre
// message prevoit — « donnez-lui un test qui l appelle : c est la citation qui
// manquait ». Le voici, et il verifie une vraie promesse : le provider rend un
// etat de tracking au repos, pilote par le notifier de tracking.
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/tracking/models/tracking_status.dart';
import 'package:moteur_gr/features/tracking/providers/tracking_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Desactiver l'avertissement multi-database en test
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('645-04 — trackingProvider nomme ses deux types publics', () {
    test('le provider rend un TrackingState au repos, pilote par un '
        'TrackingNotifier', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );

      final TrackingState etat = container.read(trackingProvider);
      final TrackingNotifier notifier = container.read(
        trackingProvider.notifier,
      );

      expect(etat.status, TrackingStatusValues.idle);
      expect(etat.distanceM, 0.0);
      expect(notifier.state.status, TrackingStatusValues.idle);

      container.dispose();
      await db.close();
    });
  });
}
