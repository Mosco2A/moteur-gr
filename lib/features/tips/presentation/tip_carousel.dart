import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/theme/app_theme.dart';
import '../data/tip_card_repository.dart';
import '../data/tip_category_config.dart';
import '../domain/models/tip_card.dart';
import 'tip_detail_sheet.dart';

/// Provider des fiches conseil filtrees par categorie.
///
/// null = toutes categories. Sinon filtre par la categorie selectionnee.
/// Tri par priorite decroissante (via TipCardRepository).
final tipCategoryFilterProvider = StateProvider<String?>((ref) => null);

/// Provider de la liste de fiches conseil filtrees.
///
/// Combine le filtre categorie avec le repository pour retourner
/// les fiches pertinentes triees par priorite.
final filteredTipCardsProvider = Provider<List<TipCard>>((ref) {
  final category = ref.watch(tipCategoryFilterProvider);
  final repo = ref.watch(tipCardRepositoryProvider);
  if (category == null) {
    return repo.filterCards();
  }
  return repo.filterByCategory(category);
});

/// Provider du repository de fiches conseil.
///
/// A surcharger dans l arbre widget avec les donnees chargees
/// depuis les fichiers JSON (assets/tips/*.json).
final tipCardRepositoryProvider = Provider<TipCardRepository>((ref) {
  return TipCardRepository(allCards: const []);
});

/// Carrousel swipeable de fiches conseil avec filtrage par categorie.
///
/// Affiche un PageView.builder horizontal avec les fiches pertinentes.
/// Les chips en haut permettent de filtrer par categorie dynamiquement.
/// Tap sur une fiche ouvre le bottom sheet de detail.
class TipCarousel extends ConsumerWidget {
  const TipCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(filteredTipCardsProvider);
    final selectedCategory = ref.watch(tipCategoryFilterProvider);
    final repo = ref.watch(tipCardRepositoryProvider);
    final categories = repo.availableCategories.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CategoryChips(
          categories: categories,
          selectedCategory: selectedCategory,
          onCategorySelected: (cat) {
            ref.read(tipCategoryFilterProvider.notifier).state = cat;
          },
        ),
        const SizedBox(height: AppTheme.spacingMd),
        if (cards.isEmpty)
          const _EmptyState()
        else
          _CarouselView(cards: cards),
      ],
    );
  }
}

/// Chips filtrables par categorie avec couleurs dynamiques.
///
/// Affiche un chip par categorie presente dans les donnees.
/// La categorie selectionnee est mise en surbrillance.
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingBase),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacingSm),
            child: FilterChip(
              label: const Text("Toutes"),
              selected: selectedCategory == null,
              onSelected: (_) => onCategorySelected(null),
              selectedColor: theme.colorScheme.primary.withAlpha(50),
              checkmarkColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
              ),
            ),
          ),
          ...categories.map((cat) {
            final meta = TipCategoryConfig.getConfig(cat);
            final color = categoryColor(cat, theme);
            return Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingSm),
              child: FilterChip(
                avatar: Icon(
                  resolveIcon(meta.icon),
                  size: 16,
                  color: selectedCategory == cat
                      ? color
                      : theme.colorScheme.onSurface.withAlpha(150),
                ),
                label: Text(meta.labelKey),
                selected: selectedCategory == cat,
                onSelected: (_) => onCategorySelected(
                  selectedCategory == cat ? null : cat,
                ),
                selectedColor: color.withAlpha(40),
                checkmarkColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Vue carrousel PageView.builder swipeable.
///
/// Affiche les fiches conseil en pages horizontales.
/// Tap sur une carte ouvre le bottom sheet de detail.
class _CarouselView extends StatelessWidget {
  const _CarouselView({required this.cards});

  final List<TipCard> cards;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 220,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.85),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          final meta = TipCategoryConfig.getConfig(card.category);
          final color = categoryColor(card.category, theme);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm),
            child: GestureDetector(
              onTap: () => TipDetailSheet.show(context, card),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  side: BorderSide(color: color.withAlpha(80), width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingBase),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(resolveIcon(meta.icon), color: color, size: 20),
                          const SizedBox(width: AppTheme.spacingSm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingSm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withAlpha(30),
                              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                            ),
                            child: Text(
                              card.category,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (card.priority >= 8)
                            const Icon(
                              Icons.priority_high,
                              color: AppTheme.rougeUrgence,
                              size: 18,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      Text(
                        card.titleFr,
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Expanded(
                        child: Text(
                          card.contentFr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(180),
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Icon(
                          Icons.swipe,
                          size: 16,
                          color: theme.colorScheme.onSurface.withAlpha(100),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Etat vide quand aucune fiche ne correspond au filtre.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 48,
              color: theme.colorScheme.onSurface.withAlpha(100),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              "Aucun conseil disponible",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(150),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Fonctions utilitaires partagees (carousel + detail) ---

/// Couleur par categorie (coherente entre chips et cartes).
Color categoryColor(String category, ThemeData theme) {
  switch (category) {
    case "preparation":
      return const Color(0xFF42A5F5);
    case "equipment":
      return const Color(0xFFFF7043);
    case "nutrition":
      return const Color(0xFF66BB6A);
    case "safety":
      return const Color(0xFFEF5350);
    case "nature":
      return const Color(0xFF26A69A);
    case "recovery":
      return const Color(0xFFAB47BC);
    default:
      return theme.colorScheme.primary;
  }
}

/// Resout un nom d icone Material en IconData.
IconData resolveIcon(String iconName) {
  switch (iconName) {
    case "checklist":
      return Icons.checklist;
    case "backpack":
      return Icons.backpack;
    case "restaurant":
      return Icons.restaurant;
    case "health_and_safety":
      return Icons.health_and_safety;
    case "forest":
      return Icons.forest;
    case "self_improvement":
      return Icons.self_improvement;
    default:
      return Icons.info;
  }
}
