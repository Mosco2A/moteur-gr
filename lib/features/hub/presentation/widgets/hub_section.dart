import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'quick_access_card.dart';

/// Section thematique du HUB (RF-6/8/9/10).
///
/// Affiche un en-tete (icone + titre de section) suivi d'une grille de
/// [QuickAccessCard]. La grille est fixe a 2 colonnes (mise en page mobile),
/// avec une hauteur de cellule reglee pour accueillir icone + titre + sous-titre
/// sans debordement. Non scrollable elle-meme : c'est le [ListView] de
/// [HubScreen] qui scrolle (grille en `shrinkWrap`, physique desactivee).
class HubSection extends StatelessWidget {
  const HubSection({
    super.key,
    required this.title,
    required this.icon,
    required this.cards,
  });

  /// Titre de la section (libelle localise).
  final String title;

  /// Icone de la section.
  final IconData icon;

  /// Cartes d'acces rapide de la section.
  final List<QuickAccessCard> cards;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tete de section.
        Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 22),
            const SizedBox(width: AppTheme.spacingSm),
            Text(title, style: theme.textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMd),
        // Grille 2 colonnes non scrollable (le HUB scrolle pour elle).
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppTheme.spacingMd,
          crossAxisSpacing: AppTheme.spacingMd,
          childAspectRatio: 1.5,
          children: cards,
        ),
      ],
    );
  }
}
