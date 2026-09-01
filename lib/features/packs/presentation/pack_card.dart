import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../i18n/translations.g.dart';
import '../data/pack_purchase_service.dart';
import '../domain/pack_download_progress.dart';
import '../domain/pack_manifest.dart';
import '../domain/sentier_pack.dart';
import '../providers/pack_providers.dart';

/// Carte d'un pack sentier A LA CARTE dans le store (F8B-03, regle metier R2).
///
/// Affiche le nom, la description, la TAILLE (Mo), l'ETAT (non telecharge /
/// telecharge / mise a jour dispo), le bouton TELECHARGER avec PROGRESSION
/// ([PackDownloadService] via le controleur Riverpod), la SUPPRESSION (gestion
/// de l'espace) et — UNIQUEMENT si la monetisation est activee par Christophe —
/// un bouton ACHETER ce pack (NON-CONSOMMABLE, jamais un abo, R2).
///
/// AUCUNE logique reseau dans le widget : tout passe par le controleur. a11y
/// Semantics + Slang 5 langues (aucune chaine en dur).
class PackCard extends ConsumerWidget {
  const PackCard({
    super.key,
    required this.pack,
    required this.manifest,
    this.updateAvailable = false,
  });

  /// Pack a afficher (libelles deja localises, F8B-01).
  final SentierPack pack;

  /// Manifeste du pack (taille + contenu offline, F8B-01).
  final PackManifest manifest;

  /// Vrai si une mise a jour du pack est disponible (etat « update »).
  final bool updateAvailable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(packDownloadControllerProvider(pack.id));
    final controller = ref.read(
      packDownloadControllerProvider(pack.id).notifier,
    );
    final purchase = ref.watch(packPurchaseServiceProvider);

    // Libelle + couleur de l'etat (telecharge / maj dispo / non telecharge).
    final (String stateLabel, Color stateColor) = _stateLabel(t, theme, state);

    return Semantics(
      container: true,
      label: t.packs.a11y.packCard(nom: pack.nom, state: stateLabel),
      // SW-SKIN-L3e : Card -> AppCard. key + margin conserves ; padding md
      // porte par AppCard (iso-rendu de la carte pack). Semantics(container)
      // preservee au-dessus.
      child: AppCard(
        key: ValueKey('pack-card-${pack.id}'),
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre + chip d'etat.
            Row(
              children: [
                Expanded(
                  child: Text(
                    pack.nom,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _StateChip(
                  key: ValueKey('pack-state-${pack.id}'),
                  label: stateLabel,
                  color: stateColor,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              pack.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.grisGranite,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            // Taille (Mo).
            Text(
              t.packs.size(mo: manifest.tailleMo),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.grisGranite,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            // Progression OU actions.
            if (state.isDownloading)
              _PackProgress(state: state)
            else
              _PackActions(
                pack: pack,
                manifest: manifest,
                state: state,
                updateAvailable: updateAvailable,
                purchaseEnabled: purchase.purchaseEnabled,
                onDownload: () => controller.download(manifest),
                onDelete: () => _confirmDelete(context, ref, t),
              ),
            if (state.isError) ...[
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                t.packs.progress.error,
                key: ValueKey('pack-error-${pack.id}'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.rougeUrgence,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (String, Color) _stateLabel(
    Translations t,
    ThemeData theme,
    PackDownloadState state,
  ) {
    if (state.downloaded && updateAvailable) {
      return (t.packs.states.updateAvailable, AppTheme.jauneModere);
    }
    if (state.downloaded) {
      return (t.packs.states.downloaded, AppTheme.vertFacile);
    }
    return (t.packs.states.notDownloaded, AppTheme.grisGranite);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Translations t,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.packs.delete.confirmTitle),
        content: Text(t.packs.delete.confirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.packs.delete.cancel),
          ),
          TextButton(
            key: const ValueKey('pack-delete-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.packs.delete.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final freed = await ref
        .read(packDownloadControllerProvider(pack.id).notifier)
        .delete();
    if (!context.mounted) return;
    if (freed >= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.packs.delete.freed)));
    }
  }
}

/// Chip d'etat (telecharge / maj / non telecharge).
class _StateChip extends StatelessWidget {
  const _StateChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Barre de progression du telechargement d'un pack.
class _PackProgress extends StatelessWidget {
  const _PackProgress({required this.state});

  final PackDownloadState state;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final verifying = state.status == PackDownloadStatus.verifying;
    final label = verifying
        ? t.packs.progress.verifying
        : t.packs.progress.downloading(
            done: state.filesDone,
            total: state.filesTotal,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          child: LinearProgressIndicator(
            key: const ValueKey('pack-progress-bar'),
            value: verifying || state.filesTotal == 0 ? null : state.fraction,
            minHeight: 8,
            backgroundColor: AppTheme.grisGranite.withAlpha(60),
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
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

/// Boutons d'action (telecharger / mettre a jour / supprimer / acheter).
class _PackActions extends StatelessWidget {
  const _PackActions({
    required this.pack,
    required this.manifest,
    required this.state,
    required this.updateAvailable,
    required this.purchaseEnabled,
    required this.onDownload,
    required this.onDelete,
  });

  final SentierPack pack;
  final PackManifest manifest;
  final PackDownloadState state;
  final bool updateAvailable;
  final bool purchaseEnabled;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final downloaded = state.downloaded;

    // Libelle du bouton principal selon l'etat.
    final String primaryLabel;
    if (state.isError) {
      primaryLabel = t.packs.actions.retry;
    } else if (downloaded && updateAvailable) {
      primaryLabel = t.packs.actions.update;
    } else {
      primaryLabel = t.packs.actions.download;
    }

    return Wrap(
      spacing: AppTheme.spacingSm,
      runSpacing: AppTheme.spacingXs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Bouton telecharger / mettre a jour / reessayer.
        if (!downloaded || updateAvailable || state.isError)
          Semantics(
            button: true,
            label: t.packs.a11y.downloadButton(nom: pack.nom),
            // SW-SKIN-L3e : FilledButton.icon -> AppButton primary (arbitrage
            // #A5). isFullWidth:false : bouton dimensionne au contenu dans le
            // Wrap (iso-rendu). key/Semantics conserves.
            child: AppButton(
              key: ValueKey('pack-download-${pack.id}'),
              isFullWidth: false,
              icon: Icons.download,
              label: primaryLabel,
              onPressed: onDownload,
            ),
          ),
        // Bouton supprimer (gestion de l'espace) si telecharge.
        if (downloaded)
          Semantics(
            button: true,
            label: t.packs.a11y.deleteButton(nom: pack.nom),
            // SW-SKIN-L3e : OutlinedButton.icon -> AppButton outline.
            // isFullWidth:false : dimensionne au contenu dans le Wrap (iso).
            child: AppButton(
              key: ValueKey('pack-delete-${pack.id}'),
              variant: AppButtonVariant.outline,
              isFullWidth: false,
              icon: Icons.delete_outline,
              label: t.packs.actions.delete,
              onPressed: onDelete,
            ),
          ),
        // Bouton acheter — UNIQUEMENT si la monetisation est activee (R2).
        // Tant que Christophe ne l'active pas, AUCUN bouton d'achat, AUCUN abo.
        if (purchaseEnabled && !downloaded)
          TextButton(
            key: ValueKey('pack-buy-${pack.id}'),
            onPressed: () {}, // branche au purchaseStream quand active (R2)
            child: Text(t.packs.actions.buy),
          ),
      ],
    );
  }
}
