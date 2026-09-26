import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/trail_config.dart';
import '../../../core/config/trail_selection.dart';
import '../../../core/routing/home_location_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/empty_state.dart';

/// Ecran catalogue des sentiers disponibles.
///
/// Cablage navigation (design #88246) : en P2-P3 (donnees fictives, sans
/// Firebase, #84627) le catalogue affiche la liste des sentiers EMBARQUES
/// ([availableTrailsProvider] = catalogue statique [TrailCatalog]) — toujours
/// presents et resolvables, donc navigables hors ligne. Le manifeste distant
/// Drift ([catalogStateProvider]) reste reserve a la Phase 4 (telechargement
/// reel). Chaque sentier propose un bouton "Entrer" qui ecrit la selection
/// ([selectedTrailIdProvider]) puis ouvre le shell sur /map : c'est l'entree
/// du coeur de l'app (anciennement orpheline).
class TrailCatalogScreen extends ConsumerWidget {
  const TrailCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final trails = ref.watch(availableTrailsProvider);

    return Scaffold(
      // Ph5 (L6d) : AppHeader universel (catalogue — §4 header standard ; barre
      // filtres/tri non prevue concretement -> pas de barre contextuelle).
      //
      // Q2 (tache 568) — LE RETOUR NE DERIVE PLUS VERS UN SENTIER QU'ON N'A PAS
      // CHOISI. Defaut de Chris (26/09 09:48), verbatim : « un retour arriere
      // arrive a mare a mare », a la premiere ouverture de l'application.
      //
      // MECANIQUE DU DEFAUT : on entre ici par `context.go('/catalog')`, qui
      // REMPLACE la pile. Sans historique, `context.canPop()` est faux et
      // l'`AppHeader` retombe sur l'accueil CONTEXTUEL
      // ([homeLocationProvider]) — donc sur le COCKPIT (`/home`) des qu'une
      // rando active existe. Le randonneur atterrissait sur le cockpit d'un
      // sentier qu'il n'avait ni choisi ni telecharge.
      //
      // CORRECTIF : le catalogue FORCE son accueil de repli sur « Mes treks ».
      // C'est le seul ecran ou la derivation maison/terrain n'a pas de sens : on
      // vient ICI pour CHOISIR un sentier, le retour doit donc ramener a la liste
      // des treks, jamais dans un trek. Les portes d'entree de l'accueil maison
      // EMPILENT par ailleurs le catalogue (`push`), si bien qu'en usage nominal
      // le retour DEPILE — ce repli ne sert qu'a l'arrivee depuis l'onboarding,
      // pile vide.
      appBar: AppHeader(
        title: t.catalog.title,
        homeLocation: HomeLocations.maison,
      ),
      body: trails.isEmpty
          ? EmptyState(
              icon: Icons.explore_off,
              title: t.catalog.emptyTitle,
              subtitle: t.catalog.emptySubtitle,
            )
          : ListView(
              key: const ValueKey('trail-catalog-list'),
              padding: const EdgeInsets.only(
                top: AppTheme.spacingSm,
                bottom: AppTheme.spacingXl,
              ),
              children: [
                for (final trail in trails)
                  _AvailableTrailCard(
                    trail: trail,
                    onEnter: () => _enterTrail(context, ref, trail.id),
                  ),
              ],
            ),
    );
  }

  /// Entre dans le sentier [trailId] : ecrit la selection (le moteur entier
  /// suit via trailConfigProvider) puis ouvre le COCKPIT DE PREPARATION.
  ///
  /// FIX CYCLE 2 (issue 1) : « Entrer » ouvrait la CARTE DE NAVIGATION LIVE
  /// (`/map`) — une debutante atterrissait directement sur la carte au lieu de la
  /// fiche/prepa. NOMINAL GR20 : selectionner un sentier ouvre son COCKPIT (hub
  /// Preparer/Randonner/Apres : faisabilite -> itineraire -> prepa), la carte
  /// live restant reservee au DEMARRAGE EFFECTIF du trek. On aligne donc sur le
  /// geste eprouve de l'accueil « Mes treks » ([MyTreksScreen] : selection +
  /// `go('/home')`) : `go` bascule vers l'accueil « terrain » (cockpit), pas un
  /// `push` d'ecran de detail — c'est un changement d'accueil contextuel, tout le
  /// contexte du sentier suit la selection (trailConfigProvider en derive).
  void _enterTrail(BuildContext context, WidgetRef ref, String trailId) {
    ref.read(selectedTrailIdProvider.notifier).state = trailId;
    context.go('/home');
  }
}

/// Carte d'un sentier disponible au catalogue : nom, region, stats + bouton
/// primaire "Entrer". Pas de notion de telechargement en P2-P3 (donnees
/// embarquees) : le sentier est directement utilisable.
class _AvailableTrailCard extends StatelessWidget {
  const _AvailableTrailCard({required this.trail, required this.onEnter});

  final TrailConfig trail;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);

    // SW-SKIN-L3e : Card -> AppCard. key + margin conserves ; padding base porte
    // par AppCard (iso-rendu de la carte sentier du catalogue).
    return AppCard(
      key: ValueKey('catalog-trail-${trail.id}'),
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingSm,
      ),
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre + icone.
          Row(
            children: [
              ExcludeSemantics(
                child: Icon(Icons.terrain, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  trail.displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          // Region + pays.
          Text(
            '${trail.region}, ${trail.country}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.grisTexteSecondaire,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          // Stats principales — Wrap pour ne pas deborder a textScale 2x.
          Wrap(
            spacing: AppTheme.spacingBase,
            runSpacing: AppTheme.spacingXs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _InfoChip(
                icon: Icons.straighten,
                label: '${trail.totalDistanceKm.toStringAsFixed(0)} km',
                theme: theme,
              ),
              _InfoChip(
                icon: Icons.trending_up,
                label: '${trail.totalElevationGain} m D+',
                theme: theme,
              ),
              _InfoChip(
                icon: Icons.flag,
                label: '${trail.totalStages}',
                theme: theme,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          // Action primaire : entrer dans le sentier (cablage nav #88246).
          SizedBox(
            width: double.infinity,
            child: Semantics(
              button: true,
              label: t.catalog.a11y.enterButton(nom: trail.displayName),
              // SW-SKIN-L3e : FilledButton.icon -> AppButton primary (arbitrage
              // #A5), pleine largeur (SizedBox width infinity conserve).
              // key/Semantics(button+label) preserves.
              child: AppButton(
                key: ValueKey('catalog-enter-${trail.id}'),
                icon: Icons.arrow_forward,
                label: t.catalog.enter,
                onPressed: onEnter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Petit chip d'information avec icone (region, distance, etapes).
class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Icon(icon, size: 14, color: AppTheme.grisTexteSecondaire),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.grisTexteSecondaire,
          ),
        ),
      ],
    );
  }
}
