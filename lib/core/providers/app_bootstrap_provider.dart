import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/trail_engine.dart';
import '../../features/trek/data/seed_data_loader.dart';
import '../../features/trek/providers/stage_providers.dart';
import 'database_provider.dart';

/// Amorce de l'application — chargement initial des donnees (PARITE GR20, LOT 1).
///
/// Probleme corrige (#99423 §4.1) : `SeedDataLoader.seedIfNeeded()` n'etait
/// appele NULLE PART, donc les tables Drift (etapes/POI/trace) restaient vides
/// (carte vide, etapes vides, meteo « introuvable »). Ce provider est le point
/// de boot unique qui declenche le seed du sentier actif AVANT le rendu des
/// ecrans data (voir la garde dans `main.dart`).
///
/// DB in-memory (`NativeDatabase.memory()`, volatile) : le seed doit tourner
/// A CHAQUE lancement. On force donc le seed en effacant d'abord le flag
/// `data_seeded` (rendant `seedIfNeeded()` reellement idempotent DANS la session
/// mais rejoue au demarrage suivant). Le moteur reste generique : le sentier
/// seede est celui de `trailConfigProvider` (une donnee), aucune localite ici.
final appBootstrapProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(databaseProvider);
  final config = ref.watch(trailConfigProvider);

  final prefs = await SharedPreferences.getInstance();

  // DB volatile -> forcer un seed frais a chaque lancement : on repart d'un
  // flag `data_seeded` a false pour que seedIfNeeded() recharge les assets.
  await prefs.remove(SeedDataLoader.kDataSeededPrefsKey);

  final loader = SeedDataLoader(db: db, prefs: prefs, trailConfig: config);
  await loader.seedIfNeeded();

  // Synchronise le fil d'etapes sur le sentier seede. `currentTrailIdProvider`
  // derive deja de `trailConfigProvider.id` (defaut), mais on l'ecrit
  // explicitement au cas ou une lecture prealable l'aurait fige a vide.
  ref.read(currentTrailIdProvider.notifier).state = config.id;
});
