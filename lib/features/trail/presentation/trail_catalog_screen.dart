import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/connectivity_monitor.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/catalog_provider.dart';
import '../widgets/download_progress_indicator.dart';
import '../widgets/trail_catalog_card.dart';

/// Libelles i18n pour l'ecran catalogue.
///
/// A remplacer par Slang quand le systeme i18n sera en place.
class _ScreenLabels {
  static const title = 'Catalogue';
  static const offlineTitle = 'Hors ligne';
  static const offlineSubtitle =
      'Connectez-vous pour parcourir le catalogue complet.';
  static const emptyTitle = 'Aucun sentier disponible';
  static const emptySubtitle = 'Tirez vers le bas pour rafraichir.';
  static const errorTitle = 'Impossible de charger le catalogue';
  static const offlineBanner = 'Mode hors ligne — sentiers telecharges uniquement';
}

/// Ecran catalogue des sentiers disponibles.
///
/// Affiche la liste des sentiers du manifeste distant avec
/// leur statut de telechargement local. Permet de telecharger,
/// mettre a jour ou supprimer les donnees de chaque sentier.
/// Pull-to-refresh pour recharger le manifeste.
/// En mode hors ligne, affiche uniquement les sentiers deja telecharges.
class TrailCatalogScreen extends ConsumerWidget {
  const TrailCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(catalogStateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(_ScreenLabels.title),
      ),
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: _ScreenLabels.errorTitle,
          subtitle: error.toString(),
          action: TextButton.icon(
            onPressed: () =>
                ref.read(catalogStateProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('Reessayer'),
          ),
        ),
        data: (catalog) => _CatalogBody(catalog: catalog),
      ),
    );
  }
}

/// Corps du catalogue (data state).
class _CatalogBody extends ConsumerWidget {
  const _CatalogBody({required this.catalog});

  final CatalogState catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Aucun sentier et hors ligne
    if (catalog.entries.isEmpty && catalog.isOffline) {
      return EmptyState(
        icon: Icons.wifi_off,
        title: _ScreenLabels.offlineTitle,
        subtitle: _ScreenLabels.offlineSubtitle,
      );
    }

    // Aucun sentier en ligne
    if (catalog.entries.isEmpty) {
      return EmptyState(
        icon: Icons.explore_off,
        title: _ScreenLabels.emptyTitle,
        subtitle: _ScreenLabels.emptySubtitle,
      );
    }

    return Column(
      children: [
        // Bandeau hors ligne
        if (catalog.isOffline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingBase,
              vertical: AppTheme.spacingSm,
            ),
            color: AppTheme.jauneModere.withAlpha(40),
            child: Row(
              children: [
                Icon(Icons.wifi_off, size: 16, color: AppTheme.jauneModere),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    _ScreenLabels.offlineBanner,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.jauneModere,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Liste scrollable avec pull-to-refresh
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(catalogStateProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.only(
                top: AppTheme.spacingSm,
                bottom: AppTheme.spacingXl,
              ),
              itemCount: catalog.entries.length,
              itemBuilder: (context, index) {
                final entry = catalog.entries[index];
                return _CatalogEntryItem(entry: entry);
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Item individuel du catalogue avec carte + indicateur de progression.
class _CatalogEntryItem extends ConsumerWidget {
  const _CatalogEntryItem({required this.entry});

  final CatalogEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(catalogStateProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TrailCatalogCard(
          entry: entry,
          onDownload: () => notifier.downloadTrail(entry.trailId),
          onUpdate: () => notifier.downloadTrail(entry.trailId),
          onDelete: () => _confirmDelete(context, ref, entry.trailId),
        ),
        // Indicateur de progression si telechargement en cours
        if (entry.localStatus == TrailLocalStatusValues.downloading)
          _DownloadProgressSection(trailId: entry.trailId),
      ],
    );
  }

  /// Dialogue de confirmation avant suppression.
  void _confirmDelete(BuildContext context, WidgetRef ref, String trailId) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer les donnees ?'),
        content: Text(
          'Les donnees du sentier $trailId seront supprimees. '
          'Vous pourrez les retelecharger plus tard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(true);
              ref
                  .read(catalogStateProvider.notifier)
                  .deleteTrailData(trailId);
            },
            child: Text(
              'Supprimer',
              style: TextStyle(color: AppTheme.rougeUrgence),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section affichant la progression du telechargement.
class _DownloadProgressSection extends ConsumerWidget {
  const _DownloadProgressSection({required this.trailId});

  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(downloadProgressProvider(trailId));

    return progressAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (progress) {
        if (progress == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingBase + AppTheme.spacingBase,
            vertical: AppTheme.spacingSm,
          ),
          child: DownloadProgressIndicator(progress: progress),
        );
      },
    );
  }
}
