import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/trail_config.dart';
import '../../../core/config/trail_selection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../i18n/translations.g.dart';

/// Ecran de selection / bascule de sentier (F8D-02, Phase 8 P8-D, #84627).
///
/// Liste les sentiers du catalogue ([availableTrailsProvider]) et permet d'en
/// activer un. Selectionner un sentier ecrit dans [selectedTrailIdProvider] :
/// TOUT le contexte de l'app suit automatiquement (carte, etapes, POI, packs,
/// guides, waypoints), car ces modules derivent du sentier actif via
/// `trailConfigProvider`. Le MOTEUR reste GENERIQUE — aucune localite hardcodee.
///
/// a11y Semantics + Slang 5 langues (aucune chaine en dur). Riverpod 2.6.
class TrailSelectionScreen extends ConsumerWidget {
  const TrailSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final trails = ref.watch(availableTrailsProvider);
    final selectedId = ref.watch(selectedTrailIdProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.trailSelection.title)),
      body: ListView(
        key: const ValueKey('trail-selection-list'),
        padding: const EdgeInsets.only(bottom: AppTheme.spacingLg),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Text(
              t.trailSelection.subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          for (final trail in trails)
            _TrailChoiceCard(
              trail: trail,
              selected: trail.id == selectedId,
              onSelect: () => _selectTrail(ref, trail.id),
            ),
        ],
      ),
    );
  }

  /// Active le sentier [trailId] : ecrit la selection, le reste de l'app suit.
  void _selectTrail(WidgetRef ref, String trailId) {
    final notifier = ref.read(selectedTrailIdProvider.notifier);
    if (notifier.state == trailId) return; // deja actif, no-op
    notifier.state = trailId;
  }
}

/// Carte d'un sentier du catalogue : nom, region, stats, etat actif/selectionnable.
class _TrailChoiceCard extends StatelessWidget {
  const _TrailChoiceCard({
    required this.trail,
    required this.selected,
    required this.onSelect,
  });

  final TrailConfig trail;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      selected: selected,
      button: !selected,
      label: t.trailSelection.a11y.trailCard(
        nom: trail.displayName,
        region: trail.region,
      ),
      // SW-SKIN-L3e : Card -> AppCard. key + margin conserves. La bordure d'ETAT
      // (sentier actif = liseré vert 2px) est portee par borderColor/borderWidth
      // d'AppCard (param declaratif reutilisable, cf. cas alerte weather L3b),
      // active uniquement quand selected -> iso-rendu de la mise en avant.
      // padding md porte par AppCard.
      child: AppCard(
        key: ValueKey('trail-choice-${trail.id}'),
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingXs,
        ),
        borderColor: selected ? AppTheme.vertFacile : null,
        borderWidth: selected ? 2 : null,
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre + badge « actif » si c'est le sentier courant.
            Row(
              children: [
                Expanded(
                  child: Text(
                    trail.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (selected)
                  Semantics(
                    label: t.trailSelection.a11y.currentBadge,
                    child: Container(
                      key: ValueKey('trail-current-${trail.id}'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingSm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.vertFacile.withAlpha(40),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusCard,
                        ),
                      ),
                      child: Text(
                        t.trailSelection.current,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.vertFacile,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingXs),
            // Region + pays.
            Text(
              '${trail.region}, ${trail.country}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.grisGranite,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            // Stats principales (etapes + distance) — donnees du sentier.
            Text(
              t.trailSelection.stagesDistance(
                stages: trail.totalStages,
                km: trail.totalDistanceKm.toStringAsFixed(0),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.grisGranite,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            // Action : activer ce sentier (desactivee si deja actif).
            // SW-SKIN-L3e : FilledButton.icon -> AppButton primary (arbitrage
            // #A5). isFullWidth:false : FilledButton n'est pas force pleine
            // largeur par le theme, il restait dimensionne au contenu et aligne
            // a droite dans l'Align (iso-rendu). Icone et libelle basculent
            // selon l'etat actif. key/Semantics(button+enabled+label) gardees.
            Align(
              alignment: Alignment.centerRight,
              child: Semantics(
                button: true,
                enabled: !selected,
                label: t.trailSelection.a11y.selectButton(
                  nom: trail.displayName,
                ),
                child: AppButton(
                  key: ValueKey('trail-select-${trail.id}'),
                  isFullWidth: false,
                  icon: selected ? Icons.check : Icons.swap_horiz,
                  label: selected
                      ? t.trailSelection.selected
                      : t.trailSelection.select,
                  onPressed: selected ? null : onSelect,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
