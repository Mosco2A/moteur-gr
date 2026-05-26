import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/tips_data.dart';

/// Ecran principal des fiches conseils.
///
/// Affiche les 6 categories sous forme de grille,
/// chaque categorie mene a la liste de ses conseils.
class TipsScreen extends StatelessWidget {
  const TipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conseils trek'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: AppTheme.spacingMd,
          mainAxisSpacing: AppTheme.spacingMd,
        ),
        itemCount: tipsCategories.length,
        itemBuilder: (context, index) {
          final category = tipsCategories[index];
          return _CategoryCard(
            category: category,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _TipListScreen(category: category),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Carte de categorie dans la grille.
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.onTap,
  });

  final TipCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingBase),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _resolveIcon(category.icon),
                size: 36,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                category.nameKey,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                '${category.tips.length} conseils',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(150),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _resolveIcon(String iconName) {
    switch (iconName) {
      case 'checklist':
        return Icons.checklist;
      case 'backpack':
        return Icons.backpack;
      case 'restaurant':
        return Icons.restaurant;
      case 'health_and_safety':
        return Icons.health_and_safety;
      case 'forest':
        return Icons.forest;
      case 'self_improvement':
        return Icons.self_improvement;
      default:
        return Icons.info;
    }
  }
}

/// Ecran liste des conseils d une categorie.
class _TipListScreen extends StatelessWidget {
  const _TipListScreen({required this.category});

  final TipCategory category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category.nameKey),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        itemCount: category.tips.length,
        itemBuilder: (context, index) {
          final tip = category.tips[index];
          return _TipCard(tip: tip);
        },
      ),
    );
  }
}

/// Carte expandable pour un conseil.
class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});

  final Tip tip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: ExpansionTile(
        title: Text(
          tip.titleKey,
          style: theme.textTheme.titleMedium,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingBase,
              0,
              AppTheme.spacingBase,
              AppTheme.spacingBase,
            ),
            child: Text(
              tip.contentKey,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
