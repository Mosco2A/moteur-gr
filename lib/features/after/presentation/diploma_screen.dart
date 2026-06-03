import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/trail_config.dart';
import '../../../core/engine/trail_engine.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../diploma/domain/diploma_generator.dart';
import '../../diploma/domain/diploma_pdf_service.dart';
import '../../journal/domain/models/journal_entry.dart';
import '../../journal/providers/journal_providers.dart';
import '../providers/in_app_review_provider.dart';

/// E5.17 : Ecran diplome post-trek avec declenchement in-app review.
///
/// Reprend le DiplomaScreen existant et ajoute la demande d'avis store
/// apres affichage du diplome (1 seule fois par trek, via Drift).
class DiplomaAfterScreen extends ConsumerStatefulWidget {
  const DiplomaAfterScreen({super.key});

  @override
  ConsumerState<DiplomaAfterScreen> createState() => _DiplomaAfterScreenState();
}

class _DiplomaAfterScreenState extends ConsumerState<DiplomaAfterScreen> {
  final _nameController = TextEditingController();
  DiplomaData? _diplomaData;
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    // E5.17: Demander un avis store apres affichage du diplome (trek termine).
    // PostFrameCallback pour laisser le build se terminer avant la dialog native.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestInAppReviewIfEligible();
    });
  }

  /// E5.17: Demande d'avis store — 1 seule fois par trek.
  Future<void> _requestInAppReviewIfEligible() async {
    final config = ref.read(trailConfigProvider);
    // Utiliser le trailId comme identifiant unique pour la review
    final trailId = config.trailId;
    final reviewService = ref.read(inAppReviewServiceProvider);
    await reviewService.requestReviewIfEligible(trailId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diplomaT = t.diploma;
    final config = ref.watch(trailConfigProvider);

    return Scaffold(
      appBar: AppBar(title: Text(diplomaT.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Titre recap
            Row(
              children: [
                Icon(Icons.landscape,
                    color: Theme.of(context).colorScheme.primary, size: 28),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    diplomaT.recapTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Saisie du nom
            Text(diplomaT.yourName,
                style: Theme.of(context).textTheme.labelLarge),
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
