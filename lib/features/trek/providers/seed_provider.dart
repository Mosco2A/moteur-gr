import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/providers/database_provider.dart';
import '../data/seed_data_loader.dart';

/// Instance SharedPreferences exposee a Riverpod.
///
/// Surchargee au demarrage (main.dart) avec l'instance deja resolue afin que
/// le seed (et tout autre consommateur) y accede de facon synchrone via le
/// graphe Riverpod, sans re-attendre `getInstance()`.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider doit etre surcharge au demarrage (main.dart).',
  );
});

/// Charge les donnees du sentier ACTIF dans la base Drift (idempotent).
///
/// Cablage du seed (bug GO-62) : jusqu'ici aucun appelant ne declenchait
/// [SeedDataLoader.seedIfNeeded], laissant les tables `stages`/`pois` vides —
/// d'ou les onglets Etapes et Planning vides. Ce provider relie le sentier
/// actif ([trailConfigProvider]) au seed embarque correspondant.
///
/// Reactif au sentier : si l'utilisateur change de sentier au catalogue
/// ([selectedTrailIdProvider] -> [trailConfigProvider]), ce FutureProvider est
/// recalcule et seed le nouveau sentier. L'idempotence cote DAO evite tout
/// doublon ou re-parse inutile quand le sentier est deja en base.
///
/// La base etant in-memory (recreee a chaque lancement), le seed se rejoue au
/// demarrage : c'est voulu et peu couteux (quelques dizaines de lignes + un
/// parse GPX basse resolution).
final trailSeedProvider = FutureProvider<bool>((ref) async {
  final db = ref.watch(databaseProvider);
  final config = ref.watch(trailConfigProvider);
  final prefs = ref.watch(sharedPreferencesProvider);

  final loader = SeedDataLoader(
    db: db,
    prefs: prefs,
    trailConfig: config,
  );

  return loader.seedIfNeeded();
});
