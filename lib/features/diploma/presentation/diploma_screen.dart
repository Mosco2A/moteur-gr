import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/trail_config.dart';
import '../../../core/engine/trail_engine.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/app_haptics.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../journal/domain/models/journal_entry.dart';
import '../../journal/providers/journal_providers.dart';
import '../../trek/domain/trek_completion.dart';
import '../domain/diploma_generator.dart';
import '../domain/diploma_pdf_service.dart';
import '../providers/session_trace_provider.dart';
import 'widgets/session_trace_painter.dart';
import '../../after/providers/adventure_recap_provider.dart';
import '../../after/providers/in_app_review_provider.dart';

/// Ecran diplome de fin de trek avec recap aventure.
///
/// Affiche : photos journal, statistiques, carte trace, bouton PDF.
/// Tous les textes via Slang (t.diploma.*) -- zero texte en dur.
/// Photos journal integrees via journal_repository existant.
/// E5.17: Declenche la demande d'avis store post-diplome (1 fois par trek).
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
  void initState() {
    super.initState();
    // E5.17: Demander un avis store apres affichage du diplome (trek termine).
    // PostFrameCallback pour laisser le build se terminer avant la dialog native.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestInAppReviewIfEligible();
    });
  }

  /// E5.17: Demande d'avis store — 1 seule fois par trek.
  ///
  /// PARITE GR20, LOT 3 : ne se declenche que si le diplome est reellement
  /// ACCESSIBLE (finisher reel ou vitrine). Sur un diplome verrouille, aucun
  /// avis n'est demande (on ne felicite pas un trek non fini).
  Future<void> _requestInAppReviewIfEligible() async {
    if (!ref.read(isDiplomaUnlockedProvider)) return;
    final config = ref.read(trailConfigProvider);
    final trailId = config.id;
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

    // PARITE GR20, LOT 3 (#99433), point 3.B(1) — GATE FINISHER + exception
    // vitrine. Le diplome est VERROUILLE tant que le parcours n'a pas ete
    // reellement parcouru en entier (session `parcoursFullyWalked`), SAUF sur un
    // sentier VITRINE ou il est deverrouille pour la demonstration (comme le
    // diplome GR20 en mode demo). Gate porte par [isDiplomaUnlockedProvider].
    final isUnlocked = ref.watch(isDiplomaUnlockedProvider);
    if (!isUnlocked) {
      return Scaffold(
        appBar: AppBar(title: Text(diplomaT.title)),
        body: _LockedState(
          title: diplomaT.lockedTitle,
          message: diplomaT.lockedMessage,
        ),
      );
    }

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

    // PARITE GR20, LOT 3 (#99433), point 3.B(2) — CHIFFRES REELS. Les stats du
    // diplome refletent la SESSION REELLE (etapes REELLEMENT marchees,
    // distance/D+ parcourus), pas les totaux statiques du sentier. On resout les
    // stats reelles ([adventureStatsProvider]) ; en leur absence (vitrine sans
    // session enregistree, demo), on retombe sur les totaux du sentier pour que
    // la demonstration reste parlante — parite avec la demo GR20.
    final realStats = ref.watch(adventureStatsProvider).value;

    // PARITE GR20, LOT 3 (#99433), point 3.B(3) — LIBELLE Integral/partiel,
    // branche sur [TrekCongratulations] du parcours reel.
    final congrats = ref.watch(adventureCongratulationsProvider);

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

            // Libelle parcours integral / partiel (parite GR20, 3.B.3).
            _ParcoursLabel(congrats: congrats, stats: realStats),
            const SizedBox(height: AppTheme.spacingLg),

            // Section photos journal
            _JournalPhotosSection(
              photoEntries: photoEntries,
              isLoading: isJournalLoading,
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Section statistiques REELLES de la session (fallback config).
            _StatsSection(config: config, stats: realStats),
            const SizedBox(height: AppTheme.spacingLg),

            // Section carte trace (trace GPS reel de la session — F3)
            const _MapTraceSection(),
            const SizedBox(height: AppTheme.spacingLg),

            // Section journal count
            _JournalCountSection(count: journalEntries.length),
            const SizedBox(height: AppTheme.spacingLg),

            // Saisie du nom
            Text(
              diplomaT.yourName,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(hintText: diplomaT.namePlaceholder),
              onChanged: (_) => _generateDiploma(config, realStats),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Apercu du diplome
            if (_diplomaData != null) _buildDiplomaPreview(Theme.of(context)),
            const SizedBox(height: AppTheme.spacingLg),

            // Bouton PDF
            AppButton(
              label: diplomaT.downloadPdf,
              icon: Icons.picture_as_pdf,
              onPressed: _diplomaData != null && !_isGeneratingPdf
                  ? () => _generatePdf(config, realStats)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _generateDiploma(TrailConfig config, AdventureStats? stats) {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _diplomaData = null);
      return;
    }

    setState(() {
      // Chiffres REELS de la session si disponibles (etapes marchees,
      // distance/D+ parcourus, duree/date reelles), sinon fallback totaux du
      // sentier (demo/vitrine sans session). Parite GR20, 3.B.2.
      final useReal = stats != null && stats.hasWalkedStages;
      _diplomaData = DiplomaGenerator.createDiploma(
        hikerName: name,
        trailName: config.displayName,
        trailRegion: config.region,
        totalStages: useReal ? stats.stagesWalked : config.totalStages,
        totalDistanceKm: useReal ? stats.distanceKm : config.totalDistanceKm,
        totalElevationGain:
            useReal ? stats.elevationGainM : config.totalElevationGain,
        completionDate:
            useReal ? (stats.endDate ?? DateTime.now()) : DateTime.now(),
        durationDays: useReal ? stats.durationDays : config.defaultDuration,
      );
    });
  }

  Widget _buildDiplomaPreview(ThemeData theme) {
    final data = _diplomaData!;

    return AppCard(
      padding: EdgeInsets.zero,
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
            Icon(
              Icons.emoji_events,
              size: 48,
              color: theme.colorScheme.primary,
            ),
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
  Future<void> _generatePdf(TrailConfig config, AdventureStats? stats) async {
    if (_diplomaData == null) return;
    // E5.5a : retour haptique moyen a la generation du diplome.
    AppHaptics.medium();
    setState(() => _isGeneratingPdf = true);

    try {
      final diplomaT = t.diploma;
      // Chiffres REELS de la session si disponibles, sinon totaux du sentier
      // (demo/vitrine). Meme regle que l'apercu (parite GR20, 3.B.2).
      final useReal = stats != null && stats.hasWalkedStages;
      final endDate =
          useReal ? (stats.endDate ?? DateTime.now()) : DateTime.now();
      final startDate = useReal
          ? (stats.startDate ??
              endDate.subtract(Duration(days: stats.durationDays)))
          : DateTime.now().subtract(Duration(days: config.defaultDuration));
      final data = DiplomaPdfData(
        hikerName: _diplomaData!.hikerName,
        trailName: config.displayName,
        trailRegion: config.region,
        totalStages: useReal ? stats.stagesWalked : config.totalStages,
        totalDistanceKm: useReal ? stats.distanceKm : config.totalDistanceKm,
        totalElevationGain:
            useReal ? stats.elevationGainM : config.totalElevationGain,
        startDate: startDate,
        endDate: endDate,
        durationDays: useReal ? stats.durationDays : config.defaultDuration,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(diplomaT.generatePdf)));
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
          AppCard(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Center(
              child: Text(
                diplomaT.recapNoPhotos,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.grisTexteSecondaire,
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
///
/// PARITE GR20, LOT 3 (#99433), point 3.B(2) : affiche les chiffres de la
/// SESSION REELLE ([stats]) — etapes REELLEMENT marchees, distance/D+
/// parcourus, duree reelle — quand ils existent. En leur absence (vitrine sans
/// session enregistree / demo), retombe sur les totaux du sentier ([config])
/// pour une demonstration parlante (parite avec la demo GR20).
class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.config, required this.stats});
  final TrailConfig config;
  final AdventureStats? stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diplomaT = t.diploma;

    final useReal = stats != null && stats!.hasWalkedStages;
    final stagesText =
        useReal ? '${stats!.stagesWalked}' : '${config.totalStages}';
    final distanceText = useReal
        ? stats!.distanceKm.toStringAsFixed(0)
        : config.totalDistanceKm.toStringAsFixed(0);
    final elevationText =
        useReal ? '${stats!.elevationGainM}' : '${config.totalElevationGain}';
    final durationText =
        useReal ? '${stats!.durationDays}' : '${config.defaultDuration}';

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
        AppCard(
          child: Column(
            children: [
              _StatRow(
                icon: Icons.flag,
                label: diplomaT.recapStages.replaceAll('{count}', stagesText),
              ),
              const Divider(height: AppTheme.spacingBase),
              _StatRow(
                icon: Icons.straighten,
                label:
                    diplomaT.recapDistance.replaceAll('{km}', distanceText),
              ),
              const Divider(height: AppTheme.spacingBase),
              _StatRow(
                icon: Icons.trending_up,
                label: diplomaT.recapElevation
                    .replaceAll('{meters}', elevationText),
              ),
              const Divider(height: AppTheme.spacingBase),
              _StatRow(
                icon: Icons.calendar_today,
                label:
                    diplomaT.recapDuration.replaceAll('{days}', durationText),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Libelle « Parcours integral / partiel » derive du parcours reel.
///
/// PARITE GR20, LOT 3 (#99433), point 3.B(3) : branche
/// [TrekCongratulations.partialLabel]/[TrekCompletionKind] -> libelle i18n.
/// « Integral » quand le parcours reel est ENTIER et fini (finisher) ;
/// « partiel » sinon. Sans plan (pas d'etapes chargees), rien n'est affiche.
class _ParcoursLabel extends StatelessWidget {
  const _ParcoursLabel({required this.congrats, required this.stats});
  final TrekCongratulations? congrats;
  final AdventureStats? stats;

  @override
  Widget build(BuildContext context) {
    final congrats = this.congrats;
    if (congrats == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final diplomaT = t.diploma;

    // Integral = parcours ENTIER reellement fini (finisher). Un parcours partiel
    // (portion) OU non entierement marche -> libelle « partiel ».
    final isIntegral = congrats.isFull && (stats?.fullyWalked ?? false);
    final label = isIntegral ? diplomaT.labelIntegral : diplomaT.labelPartial;

    return Semantics(
      label: label,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingBase,
            vertical: AppTheme.spacingSm,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(30),
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isIntegral ? Icons.verified : Icons.terrain,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Etat verrouille du diplome (trek non fini, hors vitrine) — parite GR20.
class _LockedState extends StatelessWidget {
  const _LockedState({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 64,
              color: AppTheme.grisTexteSecondaire,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppTheme.grisTexteSecondaire,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.grisTexteSecondaire,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
        Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
      ],
    );
  }
}

/// Section carte du trace — trace GPS reel de la session (F3).
///
/// Lit le trace persiste de la derniere session de tracking du
/// sentier actif (session_track_points) et le dessine via
/// [SessionTracePainter]. Fallback : message recapNoMap si aucun
/// trace enregistre.
class _MapTraceSection extends ConsumerWidget {
  const _MapTraceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final diplomaT = t.diploma;
    final traceAsync = ref.watch(sessionTraceProvider);

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
        AppCard(
          padding: EdgeInsets.zero,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            ),
            child: traceAsync.when(
              data: (points) {
                if (points.length < 2) {
                  return _NoTracePlaceholder(message: diplomaT.recapNoMap);
                }
                return CustomPaint(
                  painter: SessionTracePainter(
                    points: [for (final p in points) Offset(p.lng, p.lat)],
                    color: theme.colorScheme.primary,
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  _NoTracePlaceholder(message: diplomaT.recapNoMap),
            ),
          ),
        ),
      ],
    );
  }
}

/// Placeholder affiche quand aucun trace de session n'est disponible.
class _NoTracePlaceholder extends StatelessWidget {
  const _NoTracePlaceholder({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
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
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.grisTexteSecondaire,
            ),
          ),
        ],
      ),
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

    return AppCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(Icons.menu_book, color: theme.colorScheme.primary),
        title: Text(
          diplomaT.recapJournalEntries.replaceAll('{count}', '$count'),
          style: theme.textTheme.bodyLarge,
        ),
      ),
    );
  }
}
