import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/config/mare_a_mare_centre_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/providers/app_bootstrap_provider.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/trek/providers/stage_providers.dart';

/// PARITE GR20 — LOT 1 (#99423) : preuve que le boot peuple reellement le fil
/// d'etapes.
///
/// On rejoue la chaine de production : [appBootstrapProvider] force le seed du
/// sentier actif (assets reels Mare a Mare Centre) dans une base Drift
/// in-memory partagee, puis [stagesProvider] doit renvoyer les 7 etapes seedees
/// (Ghisonaccia -> Porticcio). Sans le cablage du boot (garde dans main.dart),
/// ce provider renvoyait une liste vide -> carte/etapes vides.
void main() {
  // rootBundle.loadString (assets de seed) exige un binding initialise.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Boot -> stagesProvider (seed reel Mare a Mare Centre)', () {
    test('apres seed, stagesProvider renvoie les 7 etapes du sentier', () async {
      SharedPreferences.setMockInitialValues({});

      // Base in-memory UNIQUE, partagee entre le seed (appBootstrapProvider)
      // et la lecture (stagesProvider via trailDataProvider) : les deux lisent
      // databaseProvider, donc l'override garantit qu'ils voient la meme DB.
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          // Sentier actif = la config reelle (id/assets Mare a Mare Centre).
          trailConfigProvider.overrideWithValue(mareAMareCentreTrailConfig),
        ],
      );
      addTearDown(container.dispose);

      // Declenche et attend le boot (seed reel depuis les assets).
      await container.read(appBootstrapProvider.future);

      // Le fil d'etapes doit refleter le sentier seede : 7 etapes triees.
      final stages = await container.read(stagesProvider.future);
      expect(stages.length, 7);
      expect(stages.first.stageNumber, 1);
      expect(stages.last.stageNumber, 7);
      expect(stages.first.name, contains('Ghisonaccia'));
      expect(stages.last.name, contains('Porticcio'));
    });

    test('le boot synchronise currentTrailIdProvider sur le sentier actif',
        () async {
      SharedPreferences.setMockInitialValues({});

      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          trailConfigProvider.overrideWithValue(mareAMareCentreTrailConfig),
        ],
      );
      addTearDown(container.dispose);

      await container.read(appBootstrapProvider.future);

      expect(
        container.read(currentTrailIdProvider),
        mareAMareCentreTrailConfig.id,
      );
    });
  });
}
