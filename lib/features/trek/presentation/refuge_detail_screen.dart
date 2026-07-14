import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../domain/models/stage_accommodation.dart';
import '../providers/stage_providers.dart';
import 'accommodation_type_ui.dart';
import '../../trail/providers/trail_providers.dart';

/// Provider des hebergements d'une etape du sentier actif.
///
/// Source : base Drift seedee par le seeder generique (par trailId).
/// Aucune donnee d'hebergement n'est hardcodee dans le moteur.
final accommodationsByStageProvider =
    FutureProvider.family<List<StageAccommodation>, int>((ref, stage) async {
  final trailId = ref.watch(currentTrailIdProvider);
  if (trailId.isEmpty) return [];
  final dataProvider = ref.watch(trailDataProvider);
  return dataProvider.getAccommodations(trailId, stageNumber: stage);
});

/// TREK-06 : Fiche hebergement sur place.
///
/// Informations pratiques de l'hebergement principal de l'etape
/// (capacite, tarifs, contact), bouton appeler / email / site web,
/// et liste des autres hebergements de l'etape.
/// Donnees chargees depuis la base du sentier actif (par trailId).
class RefugeDetailScreen extends ConsumerWidget {
  const RefugeDetailScreen({super.key, this.stageNumber});

  /// Numero d'etape de l'hebergement a afficher.
  /// Si null, utilise la premiere etape.
  final int? stageNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stage = stageNumber ?? 1;
    final accommodationsAsync =
        ref.watch(accommodationsByStageProvider(stage));

    return Scaffold(
      appBar: AppBar(
        title: accommodationsAsync.maybeWhen(
          data: (accommodations) => Text(
            _mainAccommodation(accommodations)?.name ??
                'Hebergements etape $stage',
          ),
          orElse: () => Text('Hebergements etape $stage'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: accommodationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Erreur de chargement des hebergements',
            style: theme.textTheme.bodyLarge,
          ),
        ),
        data: (accommodations) =>
            _buildContent(context, theme, stage, accommodations),
      ),
    );
  }

  /// Hebergement principal de l'etape : premier refuge,
  /// sinon premier hebergement disponible.
  StageAccommodation? _mainAccommodation(
    List<StageAccommodation> accommodations,
  ) {
    if (accommodations.isEmpty) return null;
    return accommodations.firstWhere(
      (a) => a.type == AccommodationTypeValues.refuge,
      orElse: () => accommodations.first,
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    int stage,
    List<StageAccommodation> accommodations,
  ) {
    final mainAccommodation = _mainAccommodation(accommodations);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mainAccommodation != null) ...[
            _buildHeader(theme, mainAccommodation),
            const SizedBox(height: AppTheme.spacingLg),
            _buildPracticalInfo(theme, mainAccommodation),
            const SizedBox(height: AppTheme.spacingLg),
            _buildBookingSection(context, mainAccommodation),
            const SizedBox(height: AppTheme.spacingLg),
          ] else ...[
            _buildNoAccommodationInfo(theme, stage),
            const SizedBox(height: AppTheme.spacingLg),
          ],
          if (accommodations.length > 1) ...[
            _buildOtherAccommodations(
              theme,
              accommodations,
              mainAccommodation?.id,
            ),
            const SizedBox(height: AppTheme.spacingXl),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, StageAccommodation accommodation) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(40),
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                ),
                child: Icon(
                  accommodationTypeIcon(accommodation.type),
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppTheme.spacingBase),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      accommodation.name,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _badge(
                          theme,
                          accommodationTypeLabel(accommodation.type)
                              .toUpperCase(),
                          theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        _badge(
                          theme,
                          'Etape ${accommodation.stageNumber}',
                          theme.colorScheme.secondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingBase),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (accommodation.capacity != null)
                _quickStat(
                  theme,
                  Icons.people,
                  '${accommodation.capacity} places',
                  'Capacite',
                ),
              _quickStat(
                theme,
                Icons.euro,
                accommodation.priceRange ?? 'N/A',
                'Tarifs',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(ThemeData theme, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _quickStat(
    ThemeData theme,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.secondary, size: 20),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildPracticalInfo(
    ThemeData theme,
    StageAccommodation accommodation,
  ) {
    final rows = <Widget>[
      if (accommodation.phone != null)
        _infoRow(theme, Icons.phone, 'Telephone', accommodation.phone!),
      if (accommodation.email != null)
        _infoRow(theme, Icons.email, 'Email', accommodation.email!),
      if (accommodation.website != null)
        _infoRow(theme, Icons.language, 'Site web', accommodation.website!),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Informations pratiques',
          icon: Icons.info_outline,
        ),
        AppCard(
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(height: 16),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.secondary),
        const SizedBox(width: AppTheme.spacingMd),
        Text(label, style: theme.textTheme.bodyMedium),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  /// Section "Reserver" avec boutons CTA (appeler, email, site web).
  /// Boutons affiches uniquement si les donnees sont presentes.
  /// E5.12b — Design #83560.
  Widget _buildBookingSection(
    BuildContext context,
    StageAccommodation accommodation,
  ) {
    final hasPhone =
        accommodation.phone != null && accommodation.phone!.isNotEmpty;
    final hasEmail =
        accommodation.email != null && accommodation.email!.isNotEmpty;
    final website = accommodation.bookingUrl ?? accommodation.website;
    final hasWebsite = website != null && website.isNotEmpty;

    // Pas de donnees de contact → pas de section
    if (!hasPhone && !hasEmail && !hasWebsite) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Reserver',
          icon: Icons.bookmark_add_outlined,
        ),
        if (hasPhone)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
            child: AppButton(
              label: 'Appeler',
              icon: Icons.phone,
              variant: AppButtonVariant.secondary,
              onPressed: () async {
                _logBookingAttempt('phone', accommodation.name);
                final phoneNumber =
                    accommodation.phone!.replaceAll(' ', '');
                final uri = Uri(scheme: 'tel', path: phoneNumber);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Appeler : ${accommodation.phone}'),
                      ),
                    );
                  }
                }
              },
            ),
          ),
        if (hasEmail)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
            child: AppButton(
              label: 'Email',
              icon: Icons.email,
              variant: AppButtonVariant.outline,
              onPressed: () async {
                _logBookingAttempt('email', accommodation.name);
                final uri = Uri(
                  scheme: 'mailto',
                  path: accommodation.email!,
                  queryParameters: {
                    'subject': 'Reservation ${accommodation.name}',
                  },
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Email : ${accommodation.email}'),
                      ),
                    );
                  }
                }
              },
            ),
          ),
        if (hasWebsite)
          AppButton(
            label: 'Site web',
            icon: Icons.language,
            variant: AppButtonVariant.outline,
            onPressed: () async {
              _logBookingAttempt('web', accommodation.name);
              final uri = Uri.parse(website);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Site : $website'),
                    ),
                  );
                }
              }
            },
          ),
      ],
    );
  }

  /// Logue un evenement analytics booking_attempt.
  /// Type: phone, email ou web. POI: nom de l'hebergement.
  /// E5.12b — Design #83560.
  void _logBookingAttempt(String type, String poiName) {
    // TODO(E5.13): remplacer par FirebaseAnalytics.logEvent quand
    // firebase_analytics sera ajoute au pubspec.yaml.
    debugPrint('[analytics] booking_attempt: type=$type, poi=$poiName');
  }

  Widget _buildNoAccommodationInfo(ThemeData theme, int stage) {
    return AppCard(
      child: Row(
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.secondary),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Text(
              'Pas d\'hebergement reference a l\'etape $stage. '
              'Les donnees du sentier seront completees '
              'dans une prochaine mise a jour.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherAccommodations(
    ThemeData theme,
    List<StageAccommodation> accommodations,
    String? mainAccommodationId,
  ) {
    // Exclure l'hebergement principal s'il est deja affiche
    final others = accommodations
        .where((a) => a.id != mainAccommodationId)
        .toList();

    if (others.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Autres hebergements',
          icon: Icons.hotel,
        ),
        ...others.map((accom) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
            child: AppCard(
              child: Row(
                children: [
                  Icon(
                    accommodationTypeIcon(accom.type),
                    color: theme.colorScheme.secondary,
                    size: 24,
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          accom.name,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          [
                            accommodationTypeLabel(accom.type),
                            if (accom.priceRange != null) accom.priceRange!,
                          ].join(' | '),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (accom.phone != null)
                    IconButton(
                      icon: const Icon(Icons.phone, size: 20),
                      color: theme.colorScheme.primary,
                      onPressed: () async {
                        final uri = Uri(
                          scheme: 'tel',
                          path: accom.phone!.replaceAll(' ', ''),
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

}
