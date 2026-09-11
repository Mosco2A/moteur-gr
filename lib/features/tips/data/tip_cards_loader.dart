import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../domain/models/tip_card.dart';

/// Charge les fiches conseil ([TipCard]) depuis les assets JSON (LOT 5, C).
///
/// SOCLE COMMUN (`assets/tips/general_tips.json`, fiches recurrentes tous
/// sentiers) + fiches SPECIFIQUES du sentier (chemins fournis par la config du
/// sentier, `TrailConfig.tipAssetPaths`). Deduplique par id (une fiche
/// specifique remplace son homonyme du socle). Contenu i18n INLINE (5 langues),
/// theme + liens FB/IG portes par la donnee (jamais en dur). Robuste : un asset
/// manquant/invalide est ignore (les autres fiches restent lisibles).
class TipCardsLoader {
  TipCardsLoader._();

  /// Socle commun : fiches recurrentes valables sur tous les sentiers.
  static const String socleAssetPath = 'assets/tips/general_tips.json';

  /// Charge le SOCLE + les fiches specifiques ([trailTipAssetPaths]).
  ///
  /// Ordre : socle d'abord, puis specifiques (qui priment par id). Ne lance
  /// jamais : chaque asset est charge en best-effort.
  static Future<List<TipCard>> load({
    required List<String> trailTipAssetPaths,
  }) async {
    final byId = <String, TipCard>{};

    // 1) Socle commun (recurrentes).
    for (final card in await _loadCards(socleAssetPath)) {
      byId[card.id] = card;
    }
    // 2) Specifiques du sentier (priment par id).
    for (final path in trailTipAssetPaths) {
      for (final card in await _loadCards(path)) {
        byId[card.id] = card;
      }
    }

    return byId.values.toList(growable: false);
  }

  static Future<List<TipCard>> _loadCards(String assetPath) async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final list = json.decode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(TipCard.fromJson)
          .toList(growable: false);
    } catch (_) {
      return const <TipCard>[];
    }
  }
}
