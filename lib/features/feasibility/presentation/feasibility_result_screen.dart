import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../domain/feasibility_calculator.dart';

/// Ecran de resultat de faisabilite avec score et recommandations par profil.
/// Tous les textes via Slang (t.feasibility.*) -- zero texte en dur.
class FeasibilityResultScreen extends ConsumerWidget {
  const FeasibilityResultScreen({super.key, required this.result});
  /// Resultat du questionnaire de faisabilite.
  final FeasibilityResult result;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feasibilityT = t.feasibility;
    return Scaffold(
      appBar: AppBar(title: Text(feasibilityT.resultTitle)),
      body: SingleChildScrollView(padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(children: [
          _ScoreGauge(result: result),
          const SizedBox(height: AppTheme.spacingLg),
          _LevelBadge(level: result.level),
          const SizedBox(height: AppTheme.spacingLg),
          _RecommendationCard(level: result.level),
          const SizedBox(height: AppTheme.spacingLg),
          if (result.weakPoints.isNotEmpty) ...[
            _PointsSection(title: feasibilityT.weakPointsTitle, points: result.weakPoints, icon: Icons.warning_amber, color: AppTheme.orangeDifficile),
            const SizedBox(height: AppTheme.spacingBase),
          ],
          if (result.strongPoints.isNotEmpty)
            _PointsSection(title: feasibilityT.strongPointsTitle, points: result.strongPoints, icon: Icons.check_circle, color: AppTheme.vertFacile),
        ]),
      ),
    );
  }
}

/// Jauge circulaire avec score et icone.
class _ScoreGauge extends StatelessWidget {
  const _ScoreGauge({required this.result});
  final FeasibilityResult result;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _levelColor(result.level);
    final icon = _levelIcon(result.level);
    return SizedBox(width: 140, height: 140,
      child: Stack(fit: StackFit.expand, children: [
        CircularProgressIndicator(value: result.percentage, strokeWidth: 12,
          backgroundColor: theme.colorScheme.onSurface.withAlpha(30),
          valueColor: AlwaysStoppedAnimation(color)),
        Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 36, color: color),
          Text('${result.score}/${result.maxScore}', style: theme.textTheme.headlineMedium),
        ])),
      ]),
    );
  }
}

/// Badge colore avec le niveau de recommandation.
class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});
  final String level;
  /// Resout le libelle du niveau via Slang.
  String _resolveLevel(String lvl) {
    final resolved = t['feasibility.levels.$lvl'];
    if (resolved is String) return resolved;
    return lvl;
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _levelColor(level);
    final label = _resolveLevel(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingBase, vertical: AppTheme.spacingSm),
      decoration: BoxDecoration(color: color.withAlpha(40), borderRadius: BorderRadius.circular(AppTheme.radiusChip)),
      child: Text(label, style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
    );
  }
}

/// Carte de recommandations adaptee au profil (via Slang).
class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.level});
  final String level;
  /// Resout un texte de recommandation via Slang dynamique.
  String _resolveRec(String key) {
    final resolved = t['feasibility.recommendations.$level.$key'];
    if (resolved is String) return resolved;
    return key;
  }
  /// Resout un tip via Slang dynamique.
  String _resolveTip(String tipKey) {
    final resolved = t['feasibility.recommendations.$level.tips.$tipKey'];
    if (resolved is String) return resolved;
    return tipKey;
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final feasibilityT = t.feasibility;
    final color = _levelColor(level);
    final recTitle = _resolveRec('title');
    final recSummary = _resolveRec('summary');
    return Card(color: color.withAlpha(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusCard), side: BorderSide(color: color.withAlpha(80))),
      child: Padding(padding: const EdgeInsets.all(AppTheme.spacingBase),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(_levelIcon(level), color: color, size: 24),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(child: Text(recTitle, style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: AppTheme.spacingSm),
          Text(recSummary, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppTheme.spacingBase),
          Text(feasibilityT.tipsTitle, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: AppTheme.spacingSm),
          // Affiche les 3 tips configures via Slang.
          _TipRow(text: _resolveTip('tip1'), color: color),
          _TipRow(text: _resolveTip('tip2'), color: color),
          _TipRow(text: _resolveTip('tip3'), color: color),
        ]),
      ),
    );
  }
}

/// Ligne de conseil avec icone ampoule.
class _TipRow extends StatelessWidget {
  const _TipRow({required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(padding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.lightbulb_outline, size: 18, color: color),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
      ]),
    );
  }
}

/// Section points forts ou faibles.
class _PointsSection extends StatelessWidget {
  const _PointsSection({required this.title, required this.points, required this.icon, required this.color});
  final String title;
  final List<String> points;
  final IconData icon;
  final Color color;
  /// Resout le libelle de la categorie via Slang.
  String _resolveCategory(String key) {
    final resolved = t['feasibility.categories.$key'];
    if (resolved is String) return resolved;
    return key;
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: theme.textTheme.titleMedium),
      const SizedBox(height: AppTheme.spacingSm),
      ...points.map((p) => ListTile(leading: Icon(icon, color: color), title: Text(_resolveCategory(p)), dense: true)),
    ]);
  }
}

/// Couleur associee au niveau de recommandation.
Color _levelColor(String level) {
  switch (level) {
    case FeasibilityCalculator.levelDanger: return AppTheme.rougeUrgence;
    case FeasibilityCalculator.levelCaution: return AppTheme.orangeDifficile;
    case FeasibilityCalculator.levelGood: return AppTheme.jauneModere;
    case FeasibilityCalculator.levelExcellent: return AppTheme.vertFacile;
    default: return AppTheme.grisGranite;
  }
}

/// Icone associee au niveau de recommandation.
IconData _levelIcon(String level) {
  switch (level) {
    case FeasibilityCalculator.levelDanger: return Icons.dangerous;
    case FeasibilityCalculator.levelCaution: return Icons.warning;
    case FeasibilityCalculator.levelGood: return Icons.thumb_up;
    case FeasibilityCalculator.levelExcellent: return Icons.star;
    default: return Icons.help;
  }
}
