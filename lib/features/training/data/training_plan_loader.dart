import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/training_plan.dart';

/// Charge et resout le PLAN D'ENTRAINEMENT EXTERNALISE d'un sentier (LOT 5, A).
///
/// Lit `assets/data/training_plans.json` (bloc `default` + `trails.<trailId>`)
/// et retourne le plan du sentier demande, avec repli sur le plan `default`
/// generique si aucun plan specifique n'existe (etat « sentier sans plan
/// specifique » -> plan generique, jamais d'ecran casse). Le plan est une
/// DONNEE (duree/phases/seances/objectif = donnees reglables), jamais du code :
/// on prepare la V2 (plan adaptatif par curseur, L11) sans la figer.
///
/// Meme patron que `ChecklistTemplateLoader` : cache du JSON parse (une lecture),
/// resolution par sentier. Aucune localite en dur (le moteur reste generique).
class TrainingPlanLoader {
  TrainingPlanLoader._();

  /// Chemin de l'asset (unique source de verite des plans).
  static const String assetPath = 'assets/data/training_plans.json';

  /// Cache du JSON parse (charge une seule fois par process).
  static Map<String, dynamic>? _cachedJson;

  static Future<Map<String, dynamic>> _loadJson() async {
    if (_cachedJson != null) return _cachedJson!;
    final raw = await rootBundle.loadString(assetPath);
    _cachedJson = json.decode(raw) as Map<String, dynamic>;
    return _cachedJson!;
  }

  /// Retourne le plan du sentier [trailId], ou le plan `default` si absent.
  ///
  /// Ne lance JAMAIS : toute erreur de donnee retombe sur le plan `default`
  /// (robustesse = jamais d'ecran casse, spec « sentier sans plan »).
  static Future<TrainingPlan> loadForTrail(String trailId) async {
    final data = await _loadJson();

    final trails = data['trails'] as Map<String, dynamic>?;
    final specific = trails?[trailId] as Map<String, dynamic>?;
    if (specific != null) {
      return TrainingPlan.fromJson(specific);
    }

    final fallback = data['default'] as Map<String, dynamic>;
    return TrainingPlan.fromJson(fallback);
  }

  /// Vrai si un plan SPECIFIQUE (non `default`) existe pour [trailId].
  ///
  /// Permet a l'UI de distinguer l'etat « plan generique » (plan default servi
  /// faute de plan dedie) -> invite non bloquante « plan generique ».
  static Future<bool> hasSpecificPlan(String trailId) async {
    final data = await _loadJson();
    final trails = data['trails'] as Map<String, dynamic>?;
    return trails?.containsKey(trailId) ?? false;
  }

  /// Reinitialise le cache (tests).
  static void clearCache() {
    _cachedJson = null;
  }
}
