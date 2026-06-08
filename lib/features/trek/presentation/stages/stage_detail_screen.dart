import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/error_view.dart';
import '../../../../core/ui/loading_view.dart';
import '../../../trail/providers/stages_provider.dart';
import '../../domain/models/stage.dart';

/// Provider qui charge une etape par son ID (stageNumber) dans un sentier.
///
/// Parametre : record (trailId, stageId) ou stageId = stageNumber.
/// Mappe le StageModel (core) vers le Stage (domain trek) avec i18n.
final stageByIdProvider =
    FutureProvider.family<Stage, ({String trailId, int stageId})>(
  (ref, params) async {
    final stages = await ref.watch(stagesProvider(params.trailId).future);
    final match =
        stages.where((s) => s.stageNumber == params.stageId).firstOrNull;

    if (match == null) {
      throw StateError('Etape ${params.stageId} introuvable');
    }

    return Stage(
      id: '${match.stageNumber}',
      nameFr: match.name,
      distance: match.distanceKm,
      elevationGain: match.elevationGainM,
      elevationLoss: match.elevationLossM,
      orderIndex: match.stageNumber,
      startLat: match.startLat,
      startLng: match.startLng,
      endLat: match.endLat,
      endLng: match.endLng,
      difficulty: match.difficulty,
      descriptionFr: match.description,
    );
  },
);

/// Ecran detail d'une etape de sentier.
///
/// Consumer widget utilisant AsyncValue.when() sur stageByIdProvider.
/// Affiche : nom i18n, description i18n, profil altimetrique (CustomPaint),
/// stats (distance, D+, D-, duree estimee, difficulte).
/// Utilise select() pour eviter un full rebuild.
class StageDetailScreen extends ConsumerWidget {
  const StageDetailScreen({
    super.key,
    required this.trailId,
    required this.stageId,
  });

  /// Identifiant du sentier parent.
  final String trailId;

  /// Numero de l'etape a afficher.
  final int stageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stageAsync = ref.watch(
      stageByIdProvider((trailId: trailId, stageId: stageId)).select(
        (async) => async,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Consumer(
          builder: (context, ref, _) {
            final name = ref.watch(
              stageByIdProvider((trailId: trailId, stageId: stageId)).select(
                (async) => async.valueOrNull?.nameFr ?? 'Etape $stageId',
              ),
            );
            return Text(name);
          },
        ),
      ),
      body: stageAsync.when(
        loading: () => const LoadingView(
          message: 'Chargement...',
        ),
        error: (error, _) => ErrorView(
          message: 'Impossible de charger cette etape',
          onRetry: () => ref.invalidate(
            stageByIdProvider((trailId: trailId, stageId: stageId)),
          ),
        ),
        data: (stage) => _StageDetailContent(stage: stage),
      ),
    );
  }
}

/// Contenu principal de l'ecran detail etape.
///
/// Separe du ConsumerWidget pour isoler les rebuilds.
/// Affiche nom i18n, description, profil altimetrique et stats.
class _StageDetailContent extends StatelessWidget {
  const _StageDetailContent({required this.stage});

  final Stage stage;

  /// Retourne le nom de l'etape selon la locale courante.
  /// Fallback : nameFr si la traduction est vide.
  String _localizedName(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    switch (languageCode) {
      case 'en':
        return stage.nameEn.isNotEmpty ? stage.nameEn : stage.nameFr;
      case 'de':
        return stage.nameDe.isNotEmpty ? stage.nameDe : stage.nameFr;
      case 'it':
        return stage.nameIt.isNotEmpty ? stage.nameIt : stage.nameFr;
      case 'es':
        return stage.nameEs.isNotEmpty ? stage.nameEs : stage.nameFr;
      default:
        return stage.nameFr;
    }
  }

  /// Retourne la description de l'etape selon la locale courante.
  /// Fallback : descriptionFr si la traduction est vide.
  String _localizedDescription(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    switch (languageCode) {
      case 'en':
        return stage.descriptionEn.isNotEmpty
            ? stage.descriptionEn
            : stage.descriptionFr;
      case 'de':
        return stage.descriptionDe.isNotEmpty
            ? stage.descriptionDe
            : stage.descriptionFr;
      case 'it':
        return stage.descriptionIt.isNotEmpty
            ? stage.descriptionIt
            : stage.descriptionFr;
      case 'es':
        return stage.descriptionEs.isNotEmpty
            ? stage.descriptionEs
            : stage.descriptionFr;
      default:
        return stage.descriptionFr;
    }
  }

  /// Formate la duree estimee en heures et minutes.
  String _formattedDuration() {
    final duration = stage.estimatedDuration;
    if (duration.inSeconds == 0) return "--";
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0 && minutes > 0) {
      return '${hours}h${minutes.toString().padLeft(2, "0")}';
    }
    if (hours > 0) return '${hours}h';
    return '${minutes}min';
  }

  /// Retourne le libelle de difficulte.
  String _difficultyLabel() {
    switch (stage.difficulty) {
      case 'easy':
        return 'Facile';
      case 'moderate':
        return 'Modere';
      case 'hard':
        return 'Difficile';
      case 'extreme':
        return 'Extreme';
      default:
        return stage.difficulty;
    }
  }

  /// Retourne la couleur associee a la difficulte.
  Color _difficultyColor() {
    switch (stage.difficulty) {
      case 'easy':
        return AppTheme.vertFacile;
      case 'moderate':
        return AppTheme.jauneModere;
      case 'hard':
        return AppTheme.orangeDifficile;
      case 'extreme':
        return AppTheme.rougeExtreme;
      default:
        return AppTheme.grisGranite;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = _localizedName(context);
    final description = _localizedDescription(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Nom i18n + badge difficulte ---
          Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: Text('${stage.orderIndex}'),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                  vertical: AppTheme.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: _difficultyColor().withAlpha(50),
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  border: Border.all(color: _difficultyColor()),
                ),
                child: Text(
                  _difficultyLabel(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _difficultyColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // --- Description i18n ---
          if (description.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingBase),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(200),
              ),
            ),
          ],

          const SizedBox(height: AppTheme.spacingLg),

          // --- Profil altimetrique ---
          Text(
            'Profil altimetrique',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            ),
            child: CustomPaint(
              painter: _ElevationProfilePainter(
                elevationGain: stage.elevationGain,
                elevationLoss: stage.elevationLoss,
                distance: stage.distance,
                color: theme.colorScheme.primary,
              ),
              size: Size.infinite,
            ),
          ),

          const SizedBox(height: AppTheme.spacingLg),

          // --- Statistiques ---
          Text(
            'Statistiques',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _StatRow(
            icon: Icons.straighten,
            label: 'Distance',
            value: '${stage.distance.toStringAsFixed(1)} km',
          ),
          _StatRow(
            icon: Icons.trending_up,
            label: 'D+',
            value: '${stage.elevationGain} m',
          ),
          _StatRow(
            icon: Icons.trending_down,
            label: 'D-',
            value: '${stage.elevationLoss} m',
          ),
          _StatRow(
            icon: Icons.schedule,
            label: 'Duree estimee',
            value: _formattedDuration(),
          ),
          _StatRow(
            icon: Icons.signal_cellular_alt,
            label: 'Difficulte',
            value: _difficultyLabel(),
          ),
        ],
      ),
    );
  }
}

/// Ligne de statistique avec icone, label et valeur.
class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.grisTexteSecondaire),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.grisTexteSecondaire,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter pour le profil altimetrique simplifie.
///
/// Dessine une courbe de type montagne representant le denivele
/// de l'etape. Utilise un profil synthetique base sur D+ et D-
/// car les points GPX detailles ne sont pas charges ici.
class _ElevationProfilePainter extends CustomPainter {
  _ElevationProfilePainter({
    required this.elevationGain,
    required this.elevationLoss,
    required this.distance,
    required this.color,
  });

  final int elevationGain;
  final int elevationLoss;
  final double distance;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withAlpha(30)
      ..style = PaintingStyle.fill;

    const padding = 16.0;
    final drawWidth = size.width - padding * 2;
    final drawHeight = size.height - padding * 2;

    // Profil synthetique : montee -> sommet -> descente
    final total = elevationGain + elevationLoss;
    final peakRatio = total > 0 ? elevationGain / total : 0.5;

    final path = Path();
    final fillPath = Path();

    const startX = padding;
    final startY = size.height - padding;
    final peakX = padding + drawWidth * peakRatio;
    const peakY = padding;
    final endX = size.width - padding;
    final endRatio = total > 0 ? (elevationGain - elevationLoss) / total : 0.0;
    final endY = size.height - padding - drawHeight * endRatio.clamp(0.0, 0.8);

    path.moveTo(startX, startY);
    path.quadraticBezierTo(
      (startX + peakX) / 2,
      startY - drawHeight * 0.3,
      peakX,
      peakY,
    );
    path.quadraticBezierTo(
      (peakX + endX) / 2,
      peakY + drawHeight * 0.2,
      endX,
      endY,
    );

    fillPath.addPath(path, Offset.zero);
    fillPath.lineTo(endX, size.height - padding);
    fillPath.lineTo(startX, size.height - padding);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Libelles aux extremites
    final textStyle = TextStyle(
      color: color,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    final startLabel = TextPainter(
      text: TextSpan(text: '0 km', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    startLabel.paint(canvas, Offset(startX, startY + 2));

    final endLabel = TextPainter(
      text: TextSpan(
        text: '${distance.toStringAsFixed(1)} km',
        style: textStyle,
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    endLabel.paint(canvas, Offset(endX - endLabel.width, startY + 2));

    final peakLabel = TextPainter(
      text: TextSpan(text: '+$elevationGain m', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    peakLabel.paint(canvas, Offset(peakX - peakLabel.width / 2, peakY - 14));
  }

  @override
  bool shouldRepaint(covariant _ElevationProfilePainter oldDelegate) {
    return oldDelegate.elevationGain != elevationGain ||
        oldDelegate.elevationLoss != elevationLoss ||
        oldDelegate.distance != distance ||
        oldDelegate.color != color;
  }
}
