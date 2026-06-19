import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/core/config/mare_a_mare_trail_config.dart';
import 'package:moteur_gr/core/config/trail_selection.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/trail/providers/pois_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/features/trek/providers/seed_provider.dart';
import 'package:moteur_gr/features/trek/providers/stage_providers.dart'
    as trek_stages;

/// Tests de cablage du seed (bug GO-62 — onglets Etapes/Planning vides).
///
/// Verifient que, sur le sentier actif par defaut (Mare a Mare Centre),
/// [trailSeedProvider] peuple bien la base et que les providers de lecture
/// (familles + non-famille de l'itineraire) renvoient les 7 etapes et POIs.
void main() {
  // rootBundle.loadString (assets de seed) exige une binding initialisee.
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  /// Container Riverpod cable comme l'app : DB in-memory partagee + prefs mock,
  /// sentier actif = defaut du catalogue (Mare a Mare Centre).
  Future<ProviderContainer> makeContainer() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    db = AppDatabase(NativeDatabase.memory());

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(db.close);
    return container;
  }

  test('le sentier actif par defaut est bien Mare a Mare Centre', () async {
    final container = await makeContainer();
    final id = container.read(selectedTrailIdProvider);
    expect(id, mareAMareTrailConfig.id);
  });

  test('trailSeedProvider seed la base (true au premier appel)', () async {
    final container = await makeContainer();
    final seeded = await container.read(trailSeedProvider.future);
    expect(seeded, isTrue);
  });

  test('onglet Etapes : stagesProvider(family) renvoie 7 etapes', () async {
    final container = await makeContainer();
    final stages = await container.read(
      stagesProvider(mareAMareTrailConfig.id).future,
    );
    expect(stages.length, 7);
    expect(stages.first.name, contains('Ghisonaccia'));
    expect(stages.last.name, contains('Porticcio'));
  });

  test('marqueurs/carte : poisProvider(family) renvoie des POIs', () async {
    final container = await makeContainer();
    final pois = await container.read(
      poisProvider(mareAMareTrailConfig.id).future,
    );
    expect(pois.length, 20);
  });

  test(
    'onglet Planning : stagesProvider(itineraire) suit le sentier actif',
    () async {
      // L'itineraire (onglet Planning) lit le stagesProvider NON-famille de
      // trek/providers/stage_providers.dart. Avant le fix il renvoyait []
      // (currentTrailIdProvider toujours vide). Il doit desormais suivre le
      // sentier actif et renvoyer les 7 etapes seedees.
      final container = await makeContainer();
      final stages = await container.read(trek_stages.stagesProvider.future);
      expect(stages.length, 7);
      expect(stages.first.stageNumber, 1);
      expect(stages.last.stageNumber, 7);
    },
  );

  test('idempotence : second appel ne re-seed pas (false)', () async {
    final container = await makeContainer();
    final first = await container.read(trailSeedProvider.future);
    expect(first, isTrue);

    // Relire apres invalidation doit renvoyer false (etapes deja en base).
    container.invalidate(trailSeedProvider);
    final second = await container.read(trailSeedProvider.future);
    expect(second, isFalse, reason: 'les etapes sont deja en base');
  });
}
