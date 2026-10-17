/// La fiche d'un sentier — ce qu'il est avant d'etre un programme : ses
/// photos, sa description, sa difficulte deduite et ses etapes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/screen_entry.dart';
import '../../../core/engine/trail_engine.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../providers/fiche_de_sentier_provider.dart';
import '../providers/stages_provider.dart';
import '../widgets/bande_de_photos.dart';
import '../widgets/description_du_sentier.dart';
import '../widgets/difficulte_calculee.dart';
import '../widgets/stage_list_tile.dart';
import '../../../core/branding/stepways_icons.dart';

/// Écran détail d'un sentier — LA FICHE, entre le catalogue et la preparation.
///
/// CE QU'IL MONTRE, ET POURQUOI IL A GROSSI (tache 846, demande de Christophe
/// du 17/10 09:22, verbatim : « Il manque un truc entre le catalogue et le
/// demarrage de la preparation ce sont les infos sur le trek selectionne »).
/// Il portait le nom, la region, la distance, le denivele et la liste des
/// etapes. Il porte desormais, dans cet ordre : les PHOTOS du sentier avec leur
/// mention, sa DESCRIPTION en trois questions, sa DIFFICULTE DEDUITE de trois
/// mesures a l'allure que le randonneur choisit ici meme, puis ses etapes.
///
/// TROIS BLOCS SUR QUATRE PEUVENT ETRE ABSENTS, ET ALORS ILS N'OCCUPENT RIEN.
/// Un sentier sans manifeste n'affiche ni photo ni description — pas un cadre
/// vide, pas un point d'interrogation, pas une hauteur reservee. C'est la
/// quatrieme demande de la tache, et elle se verifie a l'oeil sur le sentier de
/// test, qui n'a pas de fiche.
///
/// LES ETATS DES ETAPES SONT INCHANGES : chargement, erreur, donnee et vide.
class TrailDetailScreen extends ConsumerWidget {
  const TrailDetailScreen({super.key, required this.trailId});

  /// Identifiant du sentier à afficher
  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // LA MIETTE D ENTREE D ECRAN (lot 645-09). Cet ecran n a pas
    // d etat : le service deduplique, donc une miette part par
    // ENTREE et non par reconstruction. Rien n est attendu ici.
    observeScreenEntry(ref, ScreenBreadcrumb.trailDetail, trail: trailId);
    final config = ref.watch(trailConfigProvider);
    final stagesAsync = ref.watch(stagesProvider(trailId));
    final fiche = ref.watch(ficheDeSentierProvider(trailId)).value;
    final theme = Theme.of(context);
    final t = Translations.of(context);
    final stages = stagesAsync.value ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(config.displayName)),
      // TOUTE LA FICHE DEFILE D'UN SEUL MOUVEMENT, et c'est le changement de
      // structure de la tache 846. L'en-tete etait FIXE au-dessus d'une liste
      // qui defilait seule : avec des photos, une description et une difficulte
      // au-dessus des etapes, un en-tete fixe aurait pris la moitie de l'ecran
      // et les etapes auraient defile dans ce qui reste. Un seul defilement.
      //
      // LE CACHE EST GENEREUX, ET C'EST MESURE PLUTOT QUE PRUDENT : la liste
      // d'etapes est COURTE ET BORNEE — seize tuiles au plus sur le plus long
      // sentier du catalogue, legeres et sans image. Les construire toutes
      // evite le bloc blanc d'un defilement rapide sur une liste qui tient de
      // toute facon en memoire.
      body: CustomScrollView(
        cacheExtent: 2000,
        slivers: [
          SliverToBoxAdapter(
            child: _TrailHeader(config: config, theme: theme),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: AppTheme.spacingBase),
          ),
          // LES PHOTOS, LA DESCRIPTION : rien du tout sans manifeste.
          if (fiche != null) ...[
            SliverToBoxAdapter(child: BandeDePhotos(photos: fiche.photos)),
            if (fiche.photos.isNotEmpty)
              const SliverToBoxAdapter(
                child: SizedBox(height: AppTheme.spacingBase),
              ),
            SliverToBoxAdapter(
              child: DescriptionDuSentier(description: fiche.description),
            ),
          ],
          // LA DIFFICULTE, DEDUITE DES ETAPES MESUREES. Elle attend les etapes
          // — sans elles il n'y a pas de journees, donc rien a deduire — et
          // elle disparait proprement quand il n'y en a pas.
          SliverToBoxAdapter(
            child: DifficulteCalculee(
              stages: stages,
              allures: config.availableDurations,
              allureParDefaut: config.defaultDuration,
              altitudeMaxM: config.maxAltitudeM,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTheme.spacingSm)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingBase),
              child: SectionHeader(
                title: 'Étapes',
                icon: StepwaysIcons.chaussure,
              ),
            ),
          ),
          // Liste des étapes (AsyncValue) — les quatre etats d'avant.
          stagesAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacingXl),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, _) => SliverToBoxAdapter(
              child: EmptyState(
                icon: StepwaysIcons.danger,
                title: t.common.cannotLoadStages,
                subtitle: error.toString(),
              ),
            ),
            data: (chargees) {
              if (chargees.isEmpty) {
                return SliverToBoxAdapter(
                  child: EmptyState(
                    icon: StepwaysIcons.chaussure,
                    title: t.common.noStages,
                  ),
                );
              }
              return SliverList.builder(
                itemCount: chargees.length,
                itemBuilder: (context, index) {
                  final stage = chargees[index];
                  return StageListTile(
                    stage: stage,
                    // Ph4 (hub-and-push, SPEC §5) : push -> retour propre.
                    onTap: () => context.push(
                      '/trail/$trailId/stage/${stage.stageNumber}',
                    ),
                  );
                },
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTheme.spacingXl)),
        ],
      ),
      // Boutons d'action en bas
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingBase),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Action primaire : PREPARER le sentier (cablage nav #88246 ;
              // libelle revu par la tache 639, bug 2). Active ce sentier
              // (selectedTrailIdProvider) puis ouvre le cockpit de preparation.
              // Le verbe est le MEME que sur la carte du catalogue : deux mots
              // pour le meme geste, c'etait deux gestes pour le randonneur.
              SizedBox(
                width: double.infinity,
                child: Semantics(
                  button: true,
                  label: t.catalog.a11y.prepareButton(nom: config.displayName),
                  // SW-SKIN-L3e : FilledButton.icon -> AppButton primary
                  // (arbitrage #A5), pleine largeur (SizedBox width infinity
                  // conserve). key/Semantics(button+label) preserves.
                  child: AppButton(
                    key: const ValueKey('trail-detail-enter'),
                    icon: StepwaysIcons.programme,
                    label: t.catalog.prepare,
                    onPressed: () => _enterTrail(context, ref),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              // Actions secondaires cote a cote (compactes) : planifier / carte
              // hors-shell. Disposees en Row pour ne pas allonger la barre.
              // SW-SKIN-L3e : OutlinedButton.icon -> AppButton outline dans
              // chaque Expanded (remplit sa colonne de flex, iso-rendu).
              // Libelles inchanges (i18n = ressort de L10).
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      variant: AppButtonVariant.outline,
                      icon: StepwaysIcons.calendrier,
                      label: 'Planifier',
                      onPressed: () => context.push('/trail/$trailId/planning'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: AppButton(
                      variant: AppButtonVariant.outline,
                      icon: StepwaysIcons.sommet,
                      label: 'Voir la carte',
                      onPressed: () => context.push('/trail/$trailId/map'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Entre dans le sentier affiche : ecrit la selection (le moteur entier suit
  /// via trailConfigProvider) puis ouvre le COCKPIT DE PREPARATION.
  ///
  /// FIX CYCLE 2 (issue 1, coherence avec le catalogue) : « Entrer » ouvrait la
  /// CARTE LIVE (`/map`). NOMINAL GR20 : entrer dans un sentier mene a son
  /// COCKPIT (Preparer/Randonner/Apres), pas a la carte de navigation — celle-ci
  /// reste reservee au demarrage effectif du trek (bouton dedie du cockpit). On
  /// s'aligne sur le geste de « Mes treks » (selection + `go('/home')`). La carte
  /// et la planification restent accessibles ici via les actions SECONDAIRES
  /// « Voir la carte » / « Planifier ».
  void _enterTrail(BuildContext context, WidgetRef ref) {
    // Bascule resolue AVANT la navigation (cf. [chooseTrail]).
    chooseTrail(ref, trailId);
    context.go('/home');
  }
}

/// Header affichant les infos principales du sentier
class _TrailHeader extends StatelessWidget {
  const _TrailHeader({required this.config, required this.theme});

  final dynamic config;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline.withAlpha(60)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nom d'affichage
          Text(config.displayName, style: theme.textTheme.headlineMedium),
          if ((config.tagline as String).isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              config.tagline,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(180),
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacingMd),
          // Infos chiffrées — Wrap pour ne pas déborder à textScale 2x
          Wrap(
            spacing: AppTheme.spacingBase,
            runSpacing: AppTheme.spacingXs,
            children: [
              _InfoChip(
                icon: StepwaysIcons.repere,
                label: config.region,
                theme: theme,
              ),
              _InfoChip(
                icon: StepwaysIcons.distance,
                label: '${config.totalDistanceKm} km',
                theme: theme,
              ),
              _InfoChip(
                icon: StepwaysIcons.denivelePlus,
                label: '${config.totalElevationGain} m D+',
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Petit chip d'information avec icône
class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.theme,
  });

  final String icon;
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: StepIcon(icon, size: 16, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
