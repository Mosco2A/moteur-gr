import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/share_card_generator.dart';

/// Écran de prévisualisation et partage d'une carte trek.
///
/// Affiche la carte 1080x1080 avec aperçu et bouton de partage.
class ShareCardScreen extends StatefulWidget {
  const ShareCardScreen({super.key, required this.data});

  final ShareCardData data;

  @override
  State<ShareCardScreen> createState() => _ShareCardScreenState();
}

class _ShareCardScreenState extends State<ShareCardScreen> {
  final _repaintKey = GlobalKey();
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Partager')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: _buildCardPreview(theme),
                ),
              ),
            ),
          ),
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
              label: Text(_isGenerating ? 'Génération...' : 'Partager'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPreview(ThemeData theme) {
    final dateFormat = DateFormat('d MMMM yyyy', 'fr_FR');
    final data = widget.data;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primary.withAlpha(200),
          ],
        ),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Nom du sentier
          Text(
            data.trailName,
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          // Étape
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
              'Étape ${data.stageNumber} — ${data.stageName}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),
          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statItem(Icons.straighten, '${data.distanceKm.toStringAsFixed(1)} km'),
              const SizedBox(width: AppTheme.spacingXl),
              _statItem(Icons.trending_up, '${data.elevationGain} m D+'),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),
          // Date
          Text(
            dateFormat.format(data.date),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withAlpha(200),
            ),
          ),
          // Message personnalisé
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

  Future<void> _shareCard() async {
    setState(() => _isGenerating = true);

    final bytes = await ShareCardGenerator.generateCard(
      repaintKey: _repaintKey,
    );

    setState(() => _isGenerating = false);

    if (bytes == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la génération')),
      );
    }
    // Note: l'intégration share_plus sera activée quand le package sera ajouté
  }
}
