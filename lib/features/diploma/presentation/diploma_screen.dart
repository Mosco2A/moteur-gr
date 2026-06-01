import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/trail_config.dart';
import '../../../core/engine/trail_engine.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../journal/domain/models/journal_entry.dart';
import '../../journal/providers/journal_providers.dart';
import '../domain/diploma_generator.dart';
import '../domain/diploma_pdf_service.dart';

/// Ecran diplome de fin de trek avec recap aventure.
///
/// Affiche : photos journal, statistiques, carte trace, bouton PDF.
/// Tous les textes via Slang (t.diploma.*) -- zero texte en dur.
/// Photos journal integrees via journal_repository existant.
class DiplomaScreen extends ConsumerStatefulWidget {
  const DiplomaScreen({super.key});

  @override
  ConsumerState<DiplomaScreen> createState() => _DiplomaScreenState();
}

class _DiplomaScreenState extends ConsumerState<DiplomaScreen> {
  final _nameController = TextEditingController();
  DiplomaData? _diplomaData;
  bool _isGeneratingPdf = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diplomaT = t.diploma;
    final config = ref.watch(trailConfigProvider);

    // Journal : entrees avec photos (select pour granularite fine)
    final journalEntries = ref.watch(
      journalScreenProvider.select((s) => s.entries),
    );
    final isJournalLoading = ref.watch(
      journalScreenProvider.select((s) => s.isLoading),
    );

    // Filtrer les entrees ayant une photo
    final photoEntries = journalEntries
        .where((e) => e.photoPath != null && e.photoPath!.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(diplomaT.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Titre recap aventure
            _RecapHeader(title: diplomaT.recapTitle),
            const SizedBox(height: AppTheme.spacingLg),

            // Section photos journal
            _JournalPhotosSection(
              photoEntries: photoEntries,
              isLoading: isJournalLoading,
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Section statistiques
            _StatsSection(config: config),
            const SizedBox(height: AppTheme.spacingLg),

            // Section carte trace
            _MapTraceSection(),
            const SizedBox(height: AppTheme.spacingLg),

            // Section journal count
            _JournalCountSection(count: journalEntries.length),
            const SizedBox(height: AppTheme.spacingLg),

            // Saisie du nom
            Text(diplomaT.yourName, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(hintText: diplomaT.namePlaceholder),
              onChanged: (_) => _generateDiploma(config),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Apercu du diplome
            if (_diplomaData != null) _buildDiplomaPreview(Theme.of(context)),
            const SizedBox(height: AppTheme.spacingLg),

            // Bouton PDF
            ElevatedButton.icon(
              onPressed: _diplomaData != null && !_isGeneratingPdf
                  ? () => _generatePdf(config)
                  : null,
              icon: const Icon(Icons.picture_as_pdf),
              label: Text(diplomaT.downloadPdf),
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
            Icon(Icons.emoji_events, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: AppTheme.spacingBase),
            Text(
              t.diploma.pdfTitle,
              style: theme.textTheme.headlineLarge?.copyWith(letterSpacing: 8),
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

  /// Genere le PDF via DiplomaPdfService.
  Future<void> _generatePdf(TrailConfig config) async {
    if (_diplomaData == null) return;
    setState(() => _isGeneratingPdf = true);

    try {
      final diplomaT = t.diploma;
      final data = DiplomaPdfData(
        hikerName: _diplomaData!.hikerName,
        trailName: config.displayName,
        trailRegion: config.region,
        totalStages: config.totalStages,
        totalDistanceKm: config.totalDistanceKm,
        totalElevationGain: config.totalElevationGain,
        startDate: DateTime.now().subtract(
          Duration(days: config.defaultDuration),
        ),
        endDate: DateTime.now(),
        durationDays: config.defaultDuration,
      );

      final labels = DiplomaPdfLabels(
        title: diplomaT.pdfTitle,
        subtitle: diplomaT.pdfSubtitle,
        certifies: diplomaT.certifies,
        completed: diplomaT.completed,
        stages: diplomaT.pdfStages,
        distance: diplomaT.pdfDistance,
        elevation: diplomaT.pdfElevation,
        duration: diplomaT.pdfDuration,
        from: diplomaT.pdfFrom,
        to: diplomaT.pdfTo,
        issuedOn: diplomaT.pdfIssuedOn,
      );

      await DiplomaPdfService.generatePdf(data: data, labels: labels);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(diplomaT.generatePdf)),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }
}

// ---------------------------------------------------------------------------
// Widgets prives
// ---------------------------------------------------------------------------

/// En-tete de la section recap aventure.
class _RecapHeader extends StatelessWidget {
  const _RecapHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.landscape, color: theme.colorScheme.primary, size: 28),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// Section photos du journal avec carrousel horizontal.
class _JournalPhotosSection extends StatelessWidget {
  const _JournalPhotosSection({
    required this.photoEntries,
    required this.isLoading,
  });

  final List<JournalEntryModel> photoEntries;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diplomaT = t.diploma;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          diplomaT.recapJournalPhotos,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (photoEntries.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Center(
                child: Text(
                  diplomaT.recapNoPhotos,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.grisGranite,
                  ),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photoEntries.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppTheme.spacingSm),
              itemBuilder: (context, index) {
                final entry = photoEntries[index];
                return _PhotoCard(entry: entry);
              },
            ),
          ),
      ],
    );
  }
}

/// Carte individuelle pour une photo du journal.
class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.entry});
  final JournalEntryModel entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final file = File(entry.photoPath!);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      child: SizedBox(
        width: 140,
        height: 160,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image de la photo
            file.existsSync()
                ? Image.file(file, fit: BoxFit.cover)
                : Container(
                    color: AppTheme.grisClair,
                    child: const Icon(Icons.broken_image, size: 40),
                  ),
            // Etiquette etape en bas
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingXs,
                  horizontal: AppTheme.spacingSm,
                ),
                color: Colors.black54,
                child: Text(
                  '${t.journal.stage} ${entry.stageNumber}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section statistiques du trek.
class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.config});
  final TrailConfig config;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diplomaT = t.diploma;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          diplomaT.recapStats,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            child: Column(
              children: [
                _StatRow(
                  icon: Icons.flag,
                  label: diplomaT.recapStages
                      .replaceAll('{count}', '${config.totalStages}'),
                ),
                const Divider(height: AppTheme.spacingBase),
                _StatRow(
                  icon: Icons.straighten,
                  label: diplomaT.recapDistance.replaceAll(
                    '{km}',
                    config.totalDistanceKm.toStringAsFixed(0),
                  ),
                ),
                const Divider(height: AppTheme.spacingBase),
                _StatRow(
                  icon: Icons.trending_up,
                  label: diplomaT.recapElevation.replaceAll(
                    '{meters}',
                    '${config.totalElevationGain}',
                  ),
                ),
                const Divider(height: AppTheme.spacingBase),
                _StatRow(
                  icon: Icons.calendar_today,
                  label: diplomaT.recapDuration
                      .replaceAll('{days}', '${config.defaultDuration}'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Ligne de statistique individuelle avec icone.
class _StatRow extends StatelessWidget {
  const _StatRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 22),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: Text(label, style: theme.textTheme.bodyLarge),
        ),
      ],
    );
  }
}

/// Section carte du trace (placeholder -- rendu reel via MapWidget).
class _MapTraceSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diplomaT = t.diploma;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          diplomaT.recapMapTrace,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Card(
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.map,
                    size: 48,
                    color: theme.colorScheme.primary.withAlpha(120),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    diplomaT.recapNoMap,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.grisGranite,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Section compteur notes journal.
class _JournalCountSection extends StatelessWidget {
  const _JournalCountSection({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diplomaT = t.diploma;

    return Card(
      child: ListTile(
        leading: Icon(
          Icons.menu_book,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          diplomaT.recapJournalEntries
              .replaceAll('{count}', '$count'),
          style: theme.textTheme.bodyLarge,
        ),
      ),
    );
  }
}
