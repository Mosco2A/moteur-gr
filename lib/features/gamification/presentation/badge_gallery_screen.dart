/// Les badges obtenus face aux verrouilles, avec leur condition : l'evaluation
/// est locale, donc lisible sans reseau.
library;

import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/screen_entry.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/mesure_de_texte.dart';
import '../domain/badge.dart';
import '../domain/badge_catalog.dart';
import '../domain/badge_engine.dart';
import '../providers/gamification_providers.dart';
import '../../../core/branding/stepways_icons.dart';

/// Galerie de badges (F7C-03, Phase 7 gamification).
///
/// Affiche les badges OBTENUS vs VERROUILLES, avec leur condition d'obtention.
/// Le catalogue (libelles localises via Slang) est evalue LOCALEMENT par
/// [BadgeEngine] contre les stats de l'utilisateur (offline-first, R2). Le
/// widget NE FAIT AUCUNE evaluation : il rend le resultat du moteur. a11y via
/// [Semantics], Slang t.gamification.* (aucune cle "anonyme").
class BadgeGalleryScreen extends ConsumerWidget {
  const BadgeGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // LA MIETTE D ENTREE D ECRAN (lot 645-09). Cet ecran n a pas
    // d etat : le service deduplique, donc une miette part par
    // ENTREE et non par reconstruction. Rien n est attendu ici.
    observeScreenEntry(ref, ScreenBreadcrumb.badgeGallery);
    final t = Translations.of(context);
    final stats = ref.watch(userStatsProvider);
    final catalog = BadgeCatalog.build(t);
    final badges = const BadgeEngine().evaluateBadges(stats, catalog);

    return Scaffold(
      appBar: AppBar(title: Text(t.gamification.galleryTitle)),
      body: SafeArea(
        // LA TUILE DE BADGE GRANDIT AVEC SON TEXTE (tache 749).
        //
        // Elle disait `childAspectRatio: 0.85` : la hauteur de cellule etait
        // deduite de sa LARGEUR, donc totalement independante du texte a y
        // ecrire. Le titre etait coupe a deux lignes et la description a
        // trois, pour tenir dans cette hauteur-la. C'est exactement le defaut
        // de la grille du cockpit, et il se corrige de la meme facon : on
        // MESURE le texte au lieu de lui imposer un budget.
        //
        // Le rapport de forme d'origine devient le PLANCHER
        // (`largeurCellule / 0.85`) : la ou le texte tenait deja, la galerie
        // garde exactement l'allure qu'elle avait, et la hauteur ne peut que
        // monter.
        child: LayoutBuilder(
          builder: (context, contraintes) {
            final largeurCellule = contraintes.maxWidth.isFinite
                ? (contraintes.maxWidth -
                          AppTheme.spacingBase * 2 -
                          AppTheme.spacingMd) /
                      2
                : double.infinity;
            return GridView.builder(
              padding: const EdgeInsets.all(AppTheme.spacingBase),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppTheme.spacingMd,
                crossAxisSpacing: AppTheme.spacingMd,
                mainAxisExtent: _hauteurDeTuileDeBadge(
                  context,
                  badges: badges,
                  largeurCellule: largeurCellule,
                ),
              ),
              itemCount: badges.length,
              itemBuilder: (context, i) => _BadgeTile(badge: badges[i]),
            );
          },
        ),
      ),
    );
  }
}

/// LA HAUTEUR DE CELLULE QU'IL FAUT POUR ECRIRE LES BADGES EN ENTIER (749).
///
/// Mesure le titre et la description de CHAQUE badge a la largeur reelle de la
/// cellule, et rend la hauteur du badge le plus bavard — dans une grille,
/// toutes les cellules ont la meme hauteur et c'est la plus exigeante qui la
/// decide. Jamais moins que le rapport de forme d'origine.
double _hauteurDeTuileDeBadge(
  BuildContext context, {
  required List<Badge> badges,
  required double largeurCellule,
}) {
  final theme = Theme.of(context);
  final styleTitre = theme.textTheme.titleSmall;
  final styleDescription = theme.textTheme.bodySmall;
  final styleEtiquette = theme.textTheme.labelSmall;
  // Rapport de forme d'avant le lot : il reste le plancher.
  final plancher = largeurCellule.isFinite
      ? largeurCellule / _rapportDeFormeDOrigine
      : 0.0;
  if (styleTitre == null ||
      styleDescription == null ||
      styleEtiquette == null) {
    return plancher;
  }
  return hauteurDeCelluleMesuree(
    tuiles: [
      for (final badge in badges)
        [
          (texte: badge.titre, style: styleTitre, maxLignes: null),
          (texte: badge.description, style: styleDescription, maxLignes: null),
          // La ligne du bas porte le palier a gauche et l'etat a droite. Les
          // mesurer separement a la pleine largeur SURESTIME un peu la
          // hauteur, et c'est le bon sens de l'erreur : on reserve trop plutot
          // que de couper.
          (texte: badge.titre, style: styleEtiquette, maxLignes: 1),
        ],
    ],
    largeurTexte: largeurCellule - _paddingDeTuileDeBadge * 2,
    hauteurHorsTexte:
        _paddingDeTuileDeBadge * 2 +
        _hauteurDeLIconeDeBadge +
        AppTheme.spacingSm +
        AppTheme.spacingXs,
    plancher: plancher,
  );
}

/// Rapport largeur/hauteur de la grille d'avant le lot 749, garde en plancher.
const double _rapportDeFormeDOrigine = 0.85;

/// Padding de la tuile, de chaque cote.
const double _paddingDeTuileDeBadge = AppTheme.spacingMd;

/// L'icone du badge, en haut de la tuile.
const double _hauteurDeLIconeDeBadge = 32;

/// Tuile d'un badge : icone, titre, etat (obtenu/verrouille), description.
class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge});

  final Badge badge;

  String get _icon {
    switch (badge.iconRef) {
      case 'hiking':
        return StepwaysIcons.chaussure;
      case 'timeline':
        return StepwaysIcons.statistiques;
      case 'terrain':
        return StepwaysIcons.sommet;
      case 'military_tech':
        return StepwaysIcons.diploma;
      case 'emoji_events':
        return StepwaysIcons.diploma;
      case 'flag':
      default:
        return StepwaysIcons.depart;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final obtained = badge.isObtained;
    final stateLabel = obtained
        ? t.gamification.obtained
        : t.gamification.locked;
    final tierLabel = badge.tier == BadgeTier.expert
        ? t.gamification.tierExpert
        : t.gamification.tierDebutant;

    return Semantics(
      label: '${badge.titre}, $tierLabel, $stateLabel',
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: obtained
              ? theme.colorScheme.primaryContainer.withAlpha(60)
              : theme.colorScheme.surfaceContainerHighest.withAlpha(40),
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(
            color: obtained
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StepIcon(
                  _icon,
                  size: 32,
                  color: obtained
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
                const Spacer(),
                StepIcon(
                  obtained
                      ? StepwaysIcons.cochePleine
                      : StepwaysIcons.cadenas, // laisse en Material :
                  // les deux etats passent par le MEME Icon, on ne peut pas
                  // en remplacer un seul sans dedoubler le widget.
                  size: 18,
                  color: obtained
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            // Titre et description ECRITS EN ENTIER (tache 749). Le titre
            // etait coupe a deux lignes, la description a trois.
            Text(badge.titre, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppTheme.spacingXs),
            // L'`Expanded` est parti avec les plafonds : il donnait a la
            // description la hauteur RESTANTE de la cellule, c'est-a-dire une
            // boite, alors que c'est desormais la cellule qui suit le texte.
            // La ligne du bas est repoussee par le contenu, plus par un vide.
            Text(
              badge.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.grisTexteSecondaire,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  tierLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  stateLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: obtained
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
