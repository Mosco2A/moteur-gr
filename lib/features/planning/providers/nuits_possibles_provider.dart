/// Les nuits qu'un sentier offre au decoupage, lues dans SA donnee — et le
/// decoupage que le curseur de duree en tire.
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../domain/nuit_possible.dart';

/// LES NUITS POSSIBLES DU SENTIER COURANT (tache 839).
///
/// Lues dans `TrailConfig.possibleNightsAssetPath`, donc dans la DONNEE du
/// sentier : aucun lieu n'est ecrit dans le moteur. Un sentier qui n'en fournit
/// pas rend [DecoupageDeNuits.aucun] et rien ne change pour lui — le curseur de
/// duree se comporte comme avant.
///
/// REPLI GRACIEUX ASSUME. Un fichier absent ou illisible rend « aucun » plutot
/// que de faire tomber l'ecran : le decoupage sur les nuits est un
/// ENRICHISSEMENT, et un enrichissement qui casse l'application quand il manque
/// n'en est pas un.
final decoupageDeNuitsProvider = FutureProvider<DecoupageDeNuits>((ref) async {
  final chemin = ref.watch(
    trailConfigProvider.select((c) => c.possibleNightsAssetPath),
  );
  if (chemin == null) return DecoupageDeNuits.aucun;
  try {
    final texte = await rootBundle.loadString(chemin);
    return DecoupageDeNuits.fromJson(
      json.decode(texte) as Map<String, dynamic>,
    );
  } catch (_) {
    return DecoupageDeNuits.aucun;
  }
});

/// Le decoupage charge, ou « aucun » tant qu'il n'est pas la (jamais d'attente
/// bloquante : l'ecran affiche le programme en etapes, puis s'enrichit).
///
/// Le decoupage REPARTI sur la duree choisie vit dans `planning_provider.dart`
/// (`journeesSurLesNuitsProvider`), aupres du curseur dont il depend : le
/// mettre ici aurait rendu les deux fichiers mutuellement dependants.
final decoupageDeNuitsChargeProvider = Provider<DecoupageDeNuits>((ref) {
  return ref
      .watch(decoupageDeNuitsProvider)
      .maybeWhen(data: (d) => d, orElse: () => DecoupageDeNuits.aucun);
});
