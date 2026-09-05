import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../trek/domain/models/stage.dart';
import '../data/gpx_import_service.dart';
import '../providers/gpx_import_provider.dart';

/// Import GPX — permet d'importer une trace GPS externe (parite GR20).
///
/// PARITE GR20 (`features/after/presentation/gpx_import_screen.dart`) : clone du
/// flux (accueil -> picker -> preview carte+stats+etapes+warnings -> valider),
/// mais GENERALISE (data-driven par sentier via [importTrailConfigProvider] :
/// bornes/points d'etapes/nb etapes venant des DONNEES du sentier, aucune borne
/// « Corse » ni refuge GR20 en dur) et i18n 5 langues (tous les libelles via
/// Slang `t.import.*`). Post-validation : navigation vers le recap « Mon
/// aventure » du sentier (route existante `/trail/:id/recap`).
class GpxImportScreen extends ConsumerStatefulWidget {
  const GpxImportScreen({super.key, required this.trailId});

  /// Identifiant du sentier actif (pour la navigation post-validation).
  final String trailId;

  @override
  ConsumerState<GpxImportScreen> createState() => _GpxImportScreenState();
}

class _GpxImportScreenState extends ConsumerState<GpxImportScreen> {
  ImportedTrekData? _importedData;
  bool _isImporting = false;

  /// Message d'erreur deja traduit (bandeau rouge). Null = pas d'erreur.
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.import.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImportButton(theme),
            const SizedBox(height: AppTheme.spacingLg),
            if (_errorMessage != null) ...[
              _buildErrorBanner(theme, _errorMessage!),
              const SizedBox(height: AppTheme.spacingLg),
            ],
            if (_importedData != null && _importedData!.isValid) ...[
              _buildPreview(theme, _importedData!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImportButton(ThemeData theme) {
    return AppCard(
      child: Column(
        children: [
          Icon(Icons.upload_file, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: AppTheme.spacingMd),
          Text(t.import.headerTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            t.import.headerBody,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          AppButton(
            label: t.import.pickButton,
            icon: Icons.folder_open,
            isLoading: _isImporting,
            onPressed: _isImporting ? null : _pickAndImportGpx,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(ThemeData theme, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      decoration: BoxDecoration(
        color: AppTheme.rougeUrgence.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.rougeUrgence.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.rougeUrgence),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.rougeUrgence),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(ThemeData theme, ImportedTrekData data) {
    final durationHours = data.totalDuration.inHours;
    final durationMinutes = data.totalDuration.inMinutes % 60;
    final durationStr =
        '${durationHours}h${durationMinutes.toString().padLeft(2, '0')}';
    final directionLabel =
        data.direction == 'NS' ? t.import.directionNS : t.import.directionSN;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: t.import.traceSection, icon: Icons.route),
        const SizedBox(height: AppTheme.spacingSm),
        _buildTraceMap(theme, data),
        const SizedBox(height: AppTheme.spacingLg),
        SectionHeader(title: t.import.statsSection, icon: Icons.bar_chart),
        const SizedBox(height: AppTheme.spacingSm),
        Row(children: [
          Expanded(
            child: _buildStatCard(
              theme,
              icon: Icons.straighten,
              label: t.import.statDistance,
              value: '${data.totalDistanceKm.toStringAsFixed(1)} km',
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: _buildStatCard(
              theme,
              icon: Icons.trending_up,
              label: t.import.statElevationGain,
              value: '${data.totalElevationGain} m',
              color: theme.colorScheme.secondary,
            ),
          ),
        ]),
        const SizedBox(height: AppTheme.spacingSm),
        Row(children: [
          Expanded(
            child: _buildStatCard(
              theme,
              icon: Icons.trending_down,
              label: t.import.statElevationLoss,
              value: '${data.totalElevationLoss} m',
              color: AppTheme.orangeDifficile,
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: _buildStatCard(
              theme,
              icon: Icons.timer,
              label: t.import.statDuration,
              value: durationStr,
              color: theme.colorScheme.primary,
            ),
          ),
        ]),
        const SizedBox(height: AppTheme.spacingSm),
        Row(children: [
          Expanded(
            child: _buildStatCard(
              theme,
              icon: Icons.explore,
              label: t.import.statDirection,
              value: directionLabel,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: _buildStatCard(
              theme,
              icon: Icons.gps_fixed,
              label: t.import.statPoints,
              value: '${data.trackPoints.length}',
              color: theme.colorScheme.primary,
            ),
          ),
        ]),
        const SizedBox(height: AppTheme.spacingLg),
        if (data.stagesDetected.isNotEmpty) ...[
          SectionHeader(
            title: t.import.stagesSection,
            icon: Icons.flag,
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
              ),
              child: Text(
                // Convention Slang du projet : les {param} sont LITTERAUX,
                // substitues via replaceAll (comme t.recap.stages, cf.
                // adventure_recap_screen). Pas d'interpolation Slang activee.
                t.import.stagesCount
                    .replaceAll('{done}', '${data.stagesDetected.length}')
                    .replaceAll('{total}', '${data.totalStages}'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          ...data.stagesDetected.map((stage) => _buildStageRow(theme, stage)),
          const SizedBox(height: AppTheme.spacingLg),
        ],
        if (data.warnings.isNotEmpty) ...[
          SectionHeader(
            title: t.import.warningsSection,
            icon: Icons.warning_amber,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          ...data.warnings.map((w) => _buildWarningRow(theme, _warningText(w))),
          const SizedBox(height: AppTheme.spacingLg),
        ],
        AppButton(
          label: t.import.validateButton,
          icon: Icons.check_circle,
          onPressed: () => _validateImport(context, data),
        ),
        const SizedBox(height: AppTheme.spacingBase),
      ],
    );
  }

  Widget _buildTraceMap(ThemeData theme, ImportedTrekData data) {
    final points =
        data.trackPoints.map((tp) => LatLng(tp.lat, tp.lng)).toList();
    if (points.isEmpty) return const SizedBox.shrink();
    final bounds = LatLngBounds.fromPoints(points);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      child: SizedBox(
        height: 250,
        child: FlutterMap(
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(30),
            ),
            interactionOptions:
                const InteractionOptions(flags: InteractiveFlag.none),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.moteur-gr.app',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: points,
                  strokeWidth: 3,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: points.first,
                  width: 24,
                  height: 24,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.play_arrow,
                        size: 14, color: Colors.white),
                  ),
                ),
                Marker(
                  point: points.last,
                  width: 24,
                  height: 24,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.orangeDifficile,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.flag, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return AppCard(
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            value,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildStageRow(ThemeData theme, Stage stage) {
    // Nom de l'etape localise (fr par defaut, replis sur les autres langues).
    final locale = LocaleSettings.currentLocale.languageCode;
    final name = _stageName(stage, locale);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        child: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            ),
            child: Center(
              child: Text(
                t.import.stageBadge.replaceAll('{number}', '${stage.orderIndex}'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.check_circle, size: 18, color: AppTheme.vertFacile),
        ]),
      ),
    );
  }

  Widget _buildWarningRow(ThemeData theme, String warning) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: AppCard(
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber,
                size: 18, color: AppTheme.orangeDifficile),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Text(
                warning,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppTheme.orangeDifficile),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Traduit un [ImportWarning] typé en libelle localise (Slang).
  ///
  /// Convention du projet : {param} litteral -> replaceAll (cf. recap screen).
  String _warningText(ImportWarning warning) {
    switch (warning.type) {
      case ImportWarningType.outOfBounds:
        return t.import.warningOutOfBounds
            .replaceAll('{count}', '${warning.value}');
      case ImportWarningType.offTrail:
        return t.import.warningOffTrail
            .replaceAll('{percent}', '${warning.value}');
    }
  }

  /// Nom d'etape dans la langue courante, avec repli sur le francais.
  String _stageName(Stage stage, String locale) {
    final localized = switch (locale) {
      'en' => stage.nameEn,
      'de' => stage.nameDe,
      'it' => stage.nameIt,
      'es' => stage.nameEs,
      _ => stage.nameFr,
    };
    return localized.isNotEmpty ? localized : stage.nameFr;
  }

  Future<void> _pickAndImportGpx() async {
    setState(() {
      _isImporting = true;
      _errorMessage = null;
      _importedData = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['gpx'],
      );
      // Annulation gracieuse (silencieuse).
      if (result == null || result.files.isEmpty) {
        if (mounted) setState(() => _isImporting = false);
        return;
      }
      final filePath = result.files.single.path;
      if (filePath == null) {
        if (mounted) {
          setState(() {
            _isImporting = false;
            _errorMessage = t.import.errorUnreadable;
          });
        }
        return;
      }
      final gpxContent = await File(filePath).readAsString();
      final config = ref.read(importTrailConfigProvider);
      final service = ref.read(gpxImportServiceProvider);
      final data = service.importGpxFile(gpxContent, config);
      if (!mounted) return;
      setState(() {
        _isImporting = false;
        _importedData = data;
        if (!data.isValid) _errorMessage = _invalidText(data);
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isImporting = false;
          _errorMessage = t.import.errorParsing;
        });
      }
    }
  }

  /// Traduit le motif d'invalidite d'une trace en bandeau localise.
  String _invalidText(ImportedTrekData data) {
    switch (data.invalidReason) {
      case ImportInvalidReason.tooFewPoints:
        return t.import.invalidTooFewPoints
            .replaceAll('{count}', '${data.invalidValue ?? 0}');
      case ImportInvalidReason.outOfBounds:
        return t.import.invalidOutOfBounds;
      case null:
        return t.import.errorParsing;
    }
  }

  void _validateImport(BuildContext context, ImportedTrekData data) {
    if (!data.isValid) return;
    final directionLabel =
        data.direction == 'NS' ? t.import.directionNS : t.import.directionSN;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          const Icon(Icons.check_circle, color: AppTheme.vertFacile),
          const SizedBox(width: 8),
          Text(t.import.confirmTitle),
        ]),
        content: Text(
          t.import.confirmBody
              .replaceAll('{points}', '${data.trackPoints.length}')
              .replaceAll('{km}', data.totalDistanceKm.toStringAsFixed(1))
              .replaceAll('{stages}', '${data.stagesDetected.length}')
              .replaceAll('{direction}', directionLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.import.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Parite GR20 : navigation vers le recap d'aventure du sentier
              // (route existante) + SnackBar de confirmation. GR20 ne PERSISTE
              // pas la trace importee (stub) — StepWays conserve ce comportement
              // (pas d'ecriture de session ici).
              context.go('/trail/${widget.trailId}/recap');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.import.importedSnack)),
              );
            },
            child: Text(t.import.validate),
          ),
        ],
      ),
    );
  }
}

/// Ecran d'import GPX resolu sur le sentier actif (fallback si trailId absent).
///
/// Le HUB passe `trailId` en parametre de route ; ce wrapper garantit un id non
/// vide (repli sur le sentier actif [trailConfigProvider]) pour la navigation
/// post-validation, a l'image des autres ecrans « scopes sentier » du routeur.
class GpxImportRouteScreen extends ConsumerWidget {
  const GpxImportRouteScreen({super.key, this.trailId});

  final String? trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fallbackId = ref.watch(trailConfigProvider.select((c) => c.id));
    final id = (trailId != null && trailId!.isNotEmpty) ? trailId! : fallbackId;
    return GpxImportScreen(trailId: id);
  }
}
