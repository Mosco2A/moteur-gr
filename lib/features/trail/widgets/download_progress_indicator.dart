import 'package:flutter/material.dart';

import '../../../core/models/download_progress.dart';
import '../../../core/theme/app_theme.dart';

/// Libelles i18n pour les etapes du pipeline.
///
/// A remplacer par Slang quand le systeme i18n sera en place.
class _ProgressLabels {
  static const downloading = 'Telechargement...';
  static const trailMeta = 'Metadonnees...';
  static const itineraries = 'Itineraires...';
  static const stages = 'Etapes...';
  static const accommodations = 'Hebergements...';
  static const pois = "Points d'interet...";
  static const gpxTracks = 'Traces GPX...';
  static const gpxPoints = 'Points GPX...';
  static const completed = 'Termine !';
  static const paused = 'En pause';
  static const error = 'Erreur';

  /// Traduit le currentStep technique en libelle lisible.
  static String forStep(String step) {
    switch (step) {
      case 'downloading':
        return downloading;
      case 'downloaded':
        return downloading;
      case 'trail_meta':
        return trailMeta;
      case 'itineraries':
        return itineraries;
      case 'stages':
        return stages;
      case 'accommodations':
        return accommodations;
      case 'pois':
        return pois;
      case 'gpx_tracks':
        return gpxTracks;
      case 'gpx_points':
        return gpxPoints;
      case 'completed':
        return completed;
      default:
        return step;
    }
  }
}

/// Indicateur de progression du telechargement d'un sentier.
///
/// Affiche une barre de progression animee avec le pourcentage
/// et le libelle de l'etape en cours du pipeline d'insertion.
class DownloadProgressIndicator extends StatelessWidget {
  const DownloadProgressIndicator({
    super.key,
    required this.progress,
  });

  /// Progression courante du telechargement
  final DownloadProgress progress;

  /// Calcule le ratio de progression (0.0 a 1.0).
  static double progressRatio(DownloadProgress p) {
    if (p.totalBytes == 0) return 0.0;
    return (p.bytesDownloaded / p.totalBytes).clamp(0.0, 1.0);
  }

  /// Formate le pourcentage en chaine lisible.
  static String progressPercent(DownloadProgress p) {
    return '${(progressRatio(p) * 100).toInt()}%';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = progressRatio(progress);
    final stepLabel = _ProgressLabels.forStep(progress.currentStep);

    Color barColor;
    switch (progress.status) {
      case DownloadStatus.downloading:
        barColor = theme.colorScheme.primary;
      case DownloadStatus.completed:
        barColor = AppTheme.vertFacile;
      case DownloadStatus.error:
        barColor = AppTheme.rougeUrgence;
      case DownloadStatus.paused:
        barColor = AppTheme.jauneModere;
      case DownloadStatus.pending:
        barColor = AppTheme.grisGranite;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Barre de progression
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                backgroundColor: AppTheme.grisGranite.withAlpha(60),
                valueColor: AlwaysStoppedAnimation(barColor),
                minHeight: 8,
              );
            },
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        // Ligne texte : etape + pourcentage
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                stepLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.grisGranite,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              progressPercent(progress),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: barColor,
              ),
            ),
          ],
        ),
        // Message d'erreur si present
        if (progress.error != null) ...[
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            progress.error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.rougeUrgence,
            ),
          ),
        ],
      ],
    );
  }
}
