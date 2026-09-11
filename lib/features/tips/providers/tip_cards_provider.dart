import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/trail_engine.dart';
import '../data/tip_cards_loader.dart';
import '../domain/models/tip_card.dart';
import '../domain/models/tip_theme.dart';

/// Fiches conseil du sentier ACTIF (socle commun + specifiques), LOT 5 (C).
///
/// Charge le SOCLE (`general_tips.json`) + les fiches propres au sentier
/// (`TrailConfig.tipAssetPaths`) via [TipCardsLoader]. Disponible en PREPA ET en
/// RANDO (l'ecran Fiches conseils est atteignable depuis les deux phases du
/// cockpit). Offline : contenu embarque, chargement local (aucun reseau).
final tipCardsProvider = FutureProvider<List<TipCard>>((ref) async {
  final trail = ref.watch(trailConfigProvider);
  return TipCardsLoader.load(trailTipAssetPaths: trail.tipAssetPaths);
});

/// Une section de fiches conseil regroupees par THEME (LOT 5, C).
class TipThemeSection {
  const TipThemeSection({required this.theme, required this.cards});

  /// Cle stable du theme (voir [TipTheme]).
  final String theme;

  /// Fiches du theme, triees par priorite decroissante.
  final List<TipCard> cards;
}

/// Fiches conseil RANGEES PAR THEME (decision Chris #99615), LOT 5 (C).
///
/// Regroupe [tipCardsProvider] par [TipCard.resolvedTheme], trie les sections
/// selon l'ordre d'affichage stable ([TipTheme.displayOrder]) et les fiches de
/// chaque section par priorite decroissante. C'est la source de l'ecran Fiches
/// conseils (sections par theme), en remplacement de la liste a plat.
final tipCardsByThemeProvider = Provider<List<TipThemeSection>>((ref) {
  final cardsAsync = ref.watch(tipCardsProvider);
  final cards = cardsAsync.value ?? const <TipCard>[];
  if (cards.isEmpty) return const <TipThemeSection>[];

  final byTheme = <String, List<TipCard>>{};
  for (final card in cards) {
    byTheme.putIfAbsent(card.resolvedTheme, () => <TipCard>[]).add(card);
  }

  final themes = byTheme.keys.toList()..sort(TipTheme.compare);
  return [
    for (final theme in themes)
      TipThemeSection(
        theme: theme,
        cards: byTheme[theme]!
          ..sort((a, b) => b.priority.compareTo(a.priority)),
      ),
  ];
});
