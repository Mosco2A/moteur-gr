import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/trail_config.dart';
import '../../../core/engine/trail_engine.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/diploma_generator.dart';

/// Écran de diplôme de fin de trek.
///
/// Affiche un aperçu du diplôme et permet de le partager en PDF.
class DiplomaScreen extends ConsumerStatefulWidget {
  const DiplomaScreen({super.key});

  @override
  ConsumerState<DiplomaScreen> createState() => _DiplomaScreenState();
}

class _DiplomaScreenState extends ConsumerState<DiplomaScreen> {
  final _nameController = TextEditingController();
  DiplomaData? _diplomaData;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = ref.watch(trailConfigProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Diplôme de trek')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Saisie du nom
            Text(
              'Votre nom',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Entrez votre nom...',
              ),
              onChanged: (_) => _generateDiploma(config),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Aperçu du diplôme
            if (_diplomaData != null) _buildDiplomaPreview(theme),

            const SizedBox(height: AppTheme.spacingLg),

            // Bouton partage PDF
            ElevatedButton.icon(
              onPressed: _diplomaData != null ? _sharePdf : null,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Générer le PDF'),
            ),
          ],
        ),
      ),
    );
  }

  void _generateDiploma(TrailConfig config) {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _diplomaData = null);
      return;
    }

    setState(() {
      _diplomaData = DiplomaGenerator.createDiploma(
        hikerName: name,
        trailName: config.displayName,
        trailRegion: config.region,
        totalStages: config.totalStages,
        totalDistanceKm: config.totalDistanceKm,
        totalElevationGain: config.totalElevationGain,
        completionDate: DateTime.now(),
        durationDays: config.defaultDuration,
      );
    });
  }

  Widget _buildDiplomaPreview(ThemeData theme) {
    final data = _diplomaData!;

    return Card(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(
            color: theme.colorScheme.primary.withAlpha(100),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.emoji_events,
                size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: AppTheme.spacingBase),
            Text(
              'DIPLÔME',
              style: theme.textTheme.headlineLarge?.copyWith(
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(data.trailName, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              data.mainText,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              data.formattedDate,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sharePdf() {
    // Intégration pdf+printing prévue quand les packages seront ajoutés
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Génération PDF en cours...')),
    );
  }
}
