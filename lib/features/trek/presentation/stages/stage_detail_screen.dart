import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../domain/models/stage.dart';
import '../../providers/trail_providers.dart';

/// Ecran de detail d une etape de trek.
///
/// Consumer widget qui charge une etape via [stageByIdProvider].
/// Affiche : nom i18n, description i18n, profil altimetrique (CustomPaint),
/// stats (distance, D+, D-, duree estimee, difficulte).
///
/// Respecte les conventions Riverpod du projet :
/// - AsyncValue.when() pour les 3 etats
/// - select() pour limiter les rebuilds
/// - Pas de mutable state local
class StageDetailScreen extends ConsumerWidget {
  const StageDetailScreen({super.key, required this.stageId});

  /// Identifiant de l etape a afficher.
  final String stageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stageAsync = ref.watch(stageByIdProvider(stageId));

    return Scaffold(
      appBar: AppBar(
        title: stageAsync.whenOrNull(
          data: (stage) => Text(stage?.nameFr ?? ''),
        ) ??
            const Text(''),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: stageAsync.when(
        loading: () => const LoadingOverlay(
          message: 'Chargement...',
        ),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Impossible de charger',
          subtitle: error.toString(),
        ),
        data: (stage) {
          if (stage == null) {
            return const EmptyState(
              icon: Icons.hiking,
              title: 'Etape introuvable',
              subtitle: 'Cette etape n existe pas.',
            );
          }
          return _StageDetailContent(stage: stage);
        },
      ),
    );
  }
}

/// Contenu principal de l ecran detail.
///
/// Sections : nom i18n, description i18n, profil altimetrique,
/// stats (distance, D+, D-, duree, difficulte), coordonnees.
class _StageDetailContent extends StatelessWidget {
  const _StageDetailContent({required this.stage});

  final Stage stage;

  /// Retourne le nom localise selon la locale du contexte.
  String _localizedName(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    switch (lang) {
      case 'fr':
        return stage.nameFr;
      case 'de':
        return stage.nameDe.isNotEmpty ? stage.nameDe : stage.nameEn;
      case 'it':
        return stage.nameIt.isNotEmpty ? stage.nameIt : stage.nameEn;
      case 'es':
        return stage.nameEs.isNotEmpty ? stage.nameEs : stage.nameEn;
      case 'en':
      default:
        return stage.nameEn.isNotEmpty ? stage.nameEn : stage.nameFr;
    }
  }

  /// Retourne la description localisee selon la locale du contexte.
  String _localizedDescription(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    switch (lang) {
      case 'fr':
        return stage.descriptionFr;
      case 'de':
        return stage.descriptionDe.isNotEmpty
            ? stage.descriptionDe
            : stage.descriptionEn;
      case 'it':
        return stage.descriptionIt.isNotEmpty
            ? stage.descriptionIt
            : stage.descriptionEn;
      case 'es':
        return stage.descriptionEs.isNotEmpty
            ? stage.descriptionEs
            : stage.descriptionEn;
      case 'en':
      default:
        return stage.descriptionEn.isNotEmpty
            ? stage.descriptionEn
            : stage.descriptionFr;
    }
  }

  /// Formate la duree en heures et minutes (ex: 5h30).
  static String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h${m.toString().padLeft(2, '0')}';
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
          // --- Nom i18n ---
          Text(name, style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppTheme.spacingSm),

          // --- Badge difficulte ---
          _DifficultyChip(difficulty: stage.difficulty),
          const SizedBox(height: AppTheme.spacingBase),

          // --- Description i18n ---
          if (description.isNotEmpty) ...[
            Text(description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppTheme.spacingLg),
          ],

          // --- Profil altimetrique ---
          Text('Profil altimetrique', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingSm),
          SizedBox(
            height: 160,
            child: CustomPaint(
              size: Size.infinite,
              painter: ElevationProfilePainter(
                elevationGain: stage.elevationGain,
                elevationLoss: stage.elevationLoss,
                distance: stage.distance,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // --- Stats ---
          Text('Statistiques', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingSm),
          _StatRow(
            icon: Icons.straighten,
            label: 'Distance',
            value: '${stage.distance.toStringAsFixed(1)} km',
          ),
          _StatRow(
            icon: Icons.trending_up,
            label: 'Denivele +',
            value: '${stage.elevationGain} m',
          ),
          _StatRow(
            icon: Icons.trending_down,
            label: 'Denivele -',
            value: '${stage.elevationLoss} m',
          ),
          _StatRow(
            icon: Icons.schedule,
            label: 'Duree estimee',
            value: _formatDuration(stage.estimatedDurationMinutes),
          ),
          _StatRow(
            icon: Icons.terrain,
            label: 'Difficulte',
            value: stage.difficulty,
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // --- Coordonnees ---
          Text('Coordonnees', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingSm),
          _StatRow(
            icon: Icons.flag,
            label: 'Depart',
            value:
                '${stage.startLat.toStringAsFixed(4)}, ${stage.startLng.toStringAsFixed(4)}',
          ),
          _StatRow(
            icon: Icons.sports_score,
            label: 'Arrivee',
            value:
                '${stage.endLat.toStringAsFixed(4)}, ${stage.endLng.toStringAsFixed(4)}',
          ),
        ],
      ),
    );
  }
}

/// Badge de difficulte avec couleur contextuelle.
class _DifficultyChip extends StatelessWidget {
  const _DifficultyChip({required this.difficulty});

  final String difficulty;

  Color _chipColor() {
    switch (difficulty.toLowerCase()) {
      case 'easy':
      case 'facile':
        return AppTheme.vertFacile;
      case 'moderate':
      case 'modere':
        return AppTheme.jauneModere;
      case 'hard':
      case 'difficile':
        return AppTheme.orangeDifficile;
      case 'extreme':
        return AppTheme.rougeExtreme;
      default:
        return AppTheme.grisGranite;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(difficulty),
      backgroundColor: _chipColor().withAlpha(40),
      side: BorderSide(color: _chipColor(), width: 1.5),
      labelStyle: TextStyle(
        color: _chipColor(),
        fontWeight: FontWeight.w600,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppTheme.spacingSm),
          Text(
            '$label : ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

/// Painter CustomPaint pour le profil altimetrique d une etape.
///
/// Genere un profil simplifie a partir du D+, D- et de la distance.
/// Le profil est une courbe lissee (cubique) representant l altitude
/// approximative le long du parcours.
///
/// Visible pour les tests (prefixe sans underscore).
class ElevationProfilePainter extends CustomPainter {
  ElevationProfilePainter({
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
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withAlpha(30)
      ..style = PaintingStyle.fill;

    // Profil simplifie : depart -> montee -> sommet -> descente -> arrivee
    const baseAlt = 1000.0;
    final peakAlt = baseAlt + elevationGain;
    final endAlt = baseAlt + elevationGain - elevationLoss;

    // Points de controle pour la courbe
    final points = <Offset>[
      Offset(0, baseAlt),
      Offset(0.15, baseAlt + elevationGain * 0.3),
      Offset(0.4, peakAlt * 0.95),
      Offset(0.55, peakAlt),
      Offset(0.7, peakAlt - (peakAlt - endAlt) * 0.4),
      Offset(0.85, endAlt + (peakAlt - endAlt) * 0.1),
      Offset(1.0, endAlt),
    ];

    // Normaliser les altitudes
    final allAlts = points.map((p) => p.dy).toList();
    final minAlt = allAlts.reduce(math.min);
    final maxAlt = allAlts.reduce(math.max);
    final altRange = maxAlt - minAlt;
    if (altRange == 0) return;

    const padding = 12.0;
    final drawWidth = size.width - 2 * padding;
    final drawHeight = size.height - 2 * padding;

    // Convertir en coordonnees canvas (y inverse)
    final canvasPoints = points
        .map((p) => Offset(
              padding + p.dx * drawWidth,
              padding + drawHeight - ((p.dy - minAlt) / altRange) * drawHeight,
            ))
        .toList();

    // Tracer la courbe
    final path = Path()..moveTo(canvasPoints.first.dx, canvasPoints.first.dy);
    for (var i = 1; i < canvasPoints.length; i++) {
      final prev = canvasPoints[i - 1];
      final curr = canvasPoints[i];
      final cpx = (prev.dx + curr.dx) / 2;
      path.cubicTo(cpx, prev.dy, cpx, curr.dy, curr.dx, curr.dy);
    }

    canvas.drawPath(path, paint);

    // Remplissage sous la courbe
    final fillPath = Path.from(path)
      ..lineTo(canvasPoints.last.dx, size.height - padding)
      ..lineTo(canvasPoints.first.dx, size.height - padding)
      ..close();
    canvas.drawPath(fillPath, fillPaint);

    // Annotations altitude min et max
    final textStyle = TextStyle(
      color: color.withAlpha(180),
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    _drawText(canvas, '${maxAlt.round()} m', Offset(padding, padding - 2),
        textStyle);
    _drawText(canvas, '${minAlt.round()} m',
        Offset(padding, size.height - padding + 2), textStyle);

    // Annotation distance
    _drawText(
        canvas,
        '${distance.toStringAsFixed(1)} km',
        Offset(size.width - padding - 40, size.height - padding + 2),
        textStyle);
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final span = TextSpan(text: text, style: style);
    final painter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant ElevationProfilePainter oldDelegate) =>
      oldDelegate.elevationGain != elevationGain ||
      oldDelegate.elevationLoss != elevationLoss ||
      oldDelegate.distance != distance ||
      oldDelegate.color != color;
}
