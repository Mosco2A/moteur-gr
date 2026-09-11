import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../domain/season.dart';
import 'checklist_template.dart';

/// Adapte le Sac au TREK + a la SAISON (StepWays LOT 5, sous-ensemble B).
///
/// Couche ADDITIVE au template de base (parite GR20 : les 84 articles de
/// [defaultChecklistTemplate] restent intacts). Pour un sentier + une saison
/// donnes, on AJOUTE des articles pertinents (comptes dans la jauge). AUCUN
/// article n'est retire (jamais de regression de parite) : quand aucune donnee
/// saison/sentier ne s'applique, le Sac est EXACTEMENT le template de base.
///
/// Donnees EXTERNALISEES : `assets/data/checklist_seasonal.json` (bloc `default`
/// par saison + `trails.<trailId>.<saison>`). Reutilise le patron de cache de
/// [ChecklistTemplateLoader]. Robuste : toute erreur de donnee -> aucun ajout
/// (le Sac reste le template de base, jamais casse).
class ChecklistSeasonalAdapter {
  ChecklistSeasonalAdapter._();

  /// Chemin de l'asset des adaptations saisonnieres.
  static const String assetPath = 'assets/data/checklist_seasonal.json';

  static Map<String, dynamic>? _cachedJson;

  static Future<Map<String, dynamic>> _loadJson() async {
    if (_cachedJson != null) return _cachedJson!;
    final raw = await rootBundle.loadString(assetPath);
    _cachedJson = json.decode(raw) as Map<String, dynamic>;
    return _cachedJson!;
  }

  /// Articles saisonniers a AJOUTER pour [trailId] + [season] (jamais null).
  ///
  /// Union du bloc `default.<season>` et de `trails.<trailId>.<season>`. Un
  /// article specifique au sentier REMPLACE (par id) son homonyme du bloc
  /// default. Ne lance jamais : toute erreur -> liste vide.
  static Future<List<ChecklistTemplateItem>> seasonalItems({
    required String trailId,
    required String season,
  }) async {
    try {
      final data = await _loadJson();

      final defaultBySeason = data['default'] as Map<String, dynamic>?;
      final defaultList = _parseList(defaultBySeason?[season]);

      final trails = data['trails'] as Map<String, dynamic>?;
      final trailBySeason = trails?[trailId] as Map<String, dynamic>?;
      final trailList = _parseList(trailBySeason?[season]);

      // Fusion par id : le specifique sentier prime sur le default.
      final byId = <String, ChecklistTemplateItem>{
        for (final item in defaultList) item.id: item,
        for (final item in trailList) item.id: item,
      };
      return byId.values.toList(growable: false);
    } catch (_) {
      return const <ChecklistTemplateItem>[];
    }
  }

  /// Template RESOLU = base (parite) + ajouts saison/sentier (dedupliques par id).
  ///
  /// L'ordre preserve la base (parite GR20 : ordre des 84 articles inchange) ;
  /// les ajouts saisonniers sont appendus a la fin (jamais inseres au milieu).
  /// Un ajout dont l'id existe deja dans la base est ignore (pas de doublon).
  static Future<List<ChecklistTemplateItem>> resolveTemplate({
    required String trailId,
    required String season,
    List<ChecklistTemplateItem> base = defaultChecklistTemplate,
  }) async {
    final additions = await seasonalItems(trailId: trailId, season: season);
    if (additions.isEmpty) return base;

    final baseIds = base.map((i) => i.id).toSet();
    final extras = additions
        .where((i) => !baseIds.contains(i.id))
        .toList(growable: false);
    if (extras.isEmpty) return base;

    return [...base, ...extras];
  }

  /// Reinitialise le cache (tests).
  static void clearCache() => _cachedJson = null;

  static List<ChecklistTemplateItem> _parseList(Object? raw) {
    if (raw is! List) return const <ChecklistTemplateItem>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ChecklistTemplateItem.fromJson)
        .toList(growable: false);
  }
}

/// Saison courante par defaut (hemisphere nord, date du jour) — repli quand
/// aucune date de depart n'est posee. Exposee pour l'UI/les providers.
String currentSeasonNow() => Season.fromDate(DateTime.now());
