import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/catalog_provider.dart';

/// Libelles i18n pour les statuts de telechargement.
///
/// A remplacer par Slang quand le systeme i18n sera en place.
class _CatalogLabels {
  static const download = 'Telecharger';
  static const update = 'Mettre a jour';
  static const delete = 'Supprimer';
  static const downloaded = 'Telecharge';
  static const downloading = 'En cours...';
  static const notDownloaded = 'Non telecharge';
  static const updateAvailable = 'MAJ disponible';
}

/// Carte representant un sentier dans le catalogue.
///
/// Affiche le nom (trailId en fallback), la taille du fichier,
/// un badge de statut colore et un bouton d'action contextuel
/// (telecharger, mettre a jour, supprimer).
class TrailCatalogCard extends StatelessWidget {
  const TrailCatalogCard({
    super.key,
    required this.entry,
    this.onDownload,
    this.onUpdate,
    this.onDelete,
  });

  /// Entree du catalogue a afficher
  final CatalogEntry entry;

  /// Callback telechargement
  final VoidCallback? onDownload;

  /// Callback mise a jour
  final VoidCallback? onUpdate;

  /// Callback suppression
  final VoidCallback? onDelete;

  /// Formate une taille en octets en chaine lisible.
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} Ko';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }

  /// Retourne la couleur du badge selon le statut.
  static Color statusColor(TrailLocalStatus status) {
    switch (status) {
      case TrailLocalStatusValues.notDownloaded:
        return AppTheme.grisGranite;
      case TrailLocalStatusValues.downloading:
        return AppTheme.jauneModere;
      case TrailLocalStatusValues.downloaded:
        return AppTheme.vertFacile;
      case TrailLocalStatusValues.updateAvailable:
        return AppTheme.orangeDifficile;
      default:
        return AppTheme.grisGranite;
    }
  }

  /// Retourne le libelle du badge selon le statut.
  static String statusLabel(TrailLocalStatus status) {
    switch (status) {
      case TrailLocalStatusValues.notDownloaded:
        return _CatalogLabels.notDownloaded;
      case TrailLocalStatusValues.downloading:
        return _CatalogLabels.downloading;
      case TrailLocalStatusValues.downloaded:
        return _CatalogLabels.downloaded;
      case TrailLocalStatusValues.updateAvailable:
        return _CatalogLabels.updateAvailable;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = statusColor(entry.localStatus);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingSm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne titre + badge
            Row(
              children: [
                Icon(Icons.terrain, color: theme.colorScheme.primary),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    entry.trailId,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                _StatusBadge(
                  label: statusLabel(entry.localStatus),
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            // Infos secondaires
            Row(
              children: [
                const Icon(Icons.storage, size: 14, color: AppTheme.grisGranite),
                const SizedBox(width: 4),
                Text(
                  formatFileSize(entry.fileSize),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.grisGranite,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingBase),
                const Icon(Icons.update, size: 14, color: AppTheme.grisGranite),
                const SizedBox(width: 4),
                Text(
                  'v${entry.dataVersion}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.grisGranite,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            // Bouton action contextuel
            _buildActionButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(ThemeData theme) {
    switch (entry.localStatus) {
      case TrailLocalStatusValues.notDownloaded:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onDownload,
            icon: const Icon(Icons.download),
            label: const Text(_CatalogLabels.download),
          ),
        );
      case TrailLocalStatusValues.downloading:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: null,
            icon: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            label: const Text(_CatalogLabels.downloading),
          ),
        );
      case TrailLocalStatusValues.downloaded:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: AppTheme.rougeUrgence),
            label: const Text(
              _CatalogLabels.delete,
              style: TextStyle(color: AppTheme.rougeUrgence),
            ),
          ),
        );
      case TrailLocalStatusValues.updateAvailable:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onUpdate,
            icon: const Icon(Icons.system_update_alt),
            label: const Text(_CatalogLabels.update),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

/// Badge de statut colore (chip arrondi).
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
