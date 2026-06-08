import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/app_haptics.dart';
import '../../../i18n/translations.g.dart';
import '../domain/share_card_generator.dart';
import '../domain/share_card_template.dart';

/// Ecran de previsualisation et partage d'une carte trek.
///
/// Affiche la carte 1080x1080 avec branding dynamique,
/// selection de template et bouton de partage via share_plus.
/// Tous les textes viennent de Slang (t.share.*).
class ShareCardScreen extends ConsumerStatefulWidget {
  const ShareCardScreen({super.key, required this.data});

  final ShareCardData data;

  @override
  ConsumerState<ShareCardScreen> createState() => _ShareCardScreenState();
}

class _ShareCardScreenState extends ConsumerState<ShareCardScreen> {
  final _repaintKey = GlobalKey();
  bool _isGenerating = false;
  ShareCardTemplate _selectedTemplate = ShareCardTemplate.stats;

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(trailConfigProvider);
    final branding = ShareCardGenerator.brandingFromConfig(config);
    final theme = Theme.of(context);
    final t = Translations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.share.title)),
      body: Column(
        children: [
          // Selecteur de template
          _buildTemplateSelector(t, theme, branding),
          // Label apercu
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingBase,
              vertical: AppTheme.spacingXs,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                t.share.preview,
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
          // Preview de la carte
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: _buildCardPreview(theme, branding),
                ),
              ),
            ),
          ),
          // Bouton partager
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _shareCard,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share),
              label: Text(
                _isGenerating ? t.share.generating : t.share.share,
              ),
            ),
          ),
        ],
      ),
    );
  }
  /// Construit le selecteur horizontal de templates.
  /// Chaque chip correspond a un [ShareCardTemplate].
  Widget _buildTemplateSelector(
    Translations t,
    ThemeData theme,
    ShareCardBranding branding,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.share.chooseTemplate,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Wrap(
            spacing: AppTheme.spacingSm,
            children: ShareCardTemplate.values.map((template) {
              final isSelected = template == _selectedTemplate;
              return ChoiceChip(
                  label: Text(_templateLabel(t, template)),
                  selected: isSelected,
                  selectedColor: branding.primaryColor.withAlpha(180),
                  onSelected: (_) {
                    setState(() => _selectedTemplate = template);
                  },
                );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Retourne le label Slang pour un template donne.
  String _templateLabel(Translations t, ShareCardTemplate template) {
    switch (template) {
      case ShareCardTemplate.stats:
        return t.share.templateStats;
      case ShareCardTemplate.journey:
        return t.share.templateJourney;
      case ShareCardTemplate.stage:
        return t.share.templateStage;
    }
  }
  /// Construit l'apercu de la carte avec branding dynamique
  /// et layout adapte au template selectionne.
  Widget _buildCardPreview(ThemeData theme, ShareCardBranding branding) {
    final dateFormat = DateFormat('d MMMM yyyy', 'fr_FR');
    final data = widget.data;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: branding.gradientColors,
        ),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Carte miniature (template journey uniquement)
          if (_selectedTemplate == ShareCardTemplate.journey &&
              data.mapSnapshotBytes != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingLg),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                child: Image.memory(
                  data.mapSnapshotBytes!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          // Nom du sentier (dynamique depuis branding)
          Text(
            branding.trailName,
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          // Region du sentier
          Text(
            branding.region,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withAlpha(180),
              fontWeight: FontWeight.w400,
            ),
          ),
          // Etape (template stage uniquement si hasStageInfo)
          if (_selectedTemplate == ShareCardTemplate.stage &&
              data.hasStageInfo) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingBase,
                vertical: AppTheme.spacingSm,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
              ),
              child: Text(
                '${data.stageNumber} — ${data.stageName}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacingXl),
          // Statistiques km / denivele (tous les templates)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statItem(
                Icons.straighten,
                '${data.distanceKm.toStringAsFixed(1)} km',
              ),
              const SizedBox(width: AppTheme.spacingXl),
              _statItem(
                Icons.trending_up,
                '${data.elevationGain} m D+',
              ),
            ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          // Date
          Text(
            dateFormat.format(data.date),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withAlpha(200),
            ),
          ),
          // Message personnalise
          if (data.customMessage != null) ...[
            const SizedBox(height: AppTheme.spacingBase),
            Text(
              data.customMessage!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withAlpha(220),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
  Widget _statItem(IconData icon, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Genere l'image et lance le partage via share_plus.
  Future<void> _shareCard() async {
    // E5.5a : retour haptique moyen a la confirmation du partage.
    AppHaptics.medium();
    setState(() => _isGenerating = true);

    final bytes = await ShareCardGenerator.generateCard(
      repaintKey: _repaintKey,
    );

    if (bytes == null) {
      setState(() => _isGenerating = false);
      if (mounted) {
        final t = Translations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.share.error)),
        );
      }
      return;
    }

    // Sauvegarde temporaire et partage via share_plus
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/share_card.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(file.path)]);
    } catch (_) {
      if (mounted) {
        final t = Translations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.share.errorShare)),
        );
      }
    }

    setState(() => _isGenerating = false);
  }
}
