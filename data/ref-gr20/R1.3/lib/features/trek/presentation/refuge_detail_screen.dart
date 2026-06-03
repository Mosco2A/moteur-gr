import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/data/gr20_accommodations.dart';
import '../../../core/data/gr20_refuges.dart';
import '../../../core/data/gr20_stages.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../providers/trek_providers.dart';

/// TREK-06 : Fiche refuge sur place.
///
/// Informations pratiques du refuge (capacite, équipements, tarifs,
/// horaires repas), bouton appeler, activites proches.
/// Utilise les donnees de gr20_refuges.dart et gr20_accommodations.dart.
class RefugeDetailScreen extends ConsumerWidget {
  const RefugeDetailScreen({super.key, this.stageNumber});

  /// Numero d'étape du refuge a afficher.
  /// Si null, utilise l'étape active.
  final int? stageNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeStage = ref.watch(activeStageProvider);

    // Determiner l'étape
    final stage = stageNumber ?? activeStage?.number ?? 1;

    // Trouver le refuge PNRC principal de cette étape
    final refuges = gr20RefugesPNRC
        .where((r) => r.stageNumber == stage)
        .toList();
    final mainRefuge = refuges.isNotEmpty ? refuges.first : null;

    // Tous les hébergements de l'étape
    final allAccom = accommodationsForStage(stage);

    // Données de l'étape
    final stageData =
        stage > 0 && stage <= gr20Stages.length ? gr20Stages[stage - 1] : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(mainRefuge?.name ?? 'Refuge étape $stage'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- En-tete refuge ---
            if (mainRefuge != null) ...[
              _buildRefugeHeader(theme, mainRefuge),
              const SizedBox(height: AppTheme.spacingLg),

              // --- Équipements ---
              _buildEquipments(theme, mainRefuge),
              const SizedBox(height: AppTheme.spacingLg),

              // --- Horaires / Infos pratiques ---
              _buildPracticalInfo(theme, mainRefuge),
              const SizedBox(height: AppTheme.spacingLg),

              // --- Section Réserver (deeplinks) ---
              _buildBookingSection(context, mainRefuge),
              const SizedBox(height: AppTheme.spacingLg),
            ] else ...[
              _buildNoRefugeInfo(theme, stage),
              const SizedBox(height: AppTheme.spacingLg),
            ],

            // --- Autres hébergements ---
            if (allAccom.length > 1) ...[
              _buildOtherAccommodations(theme, allAccom, mainRefuge?.name),
              const SizedBox(height: AppTheme.spacingLg),
            ],

            // --- Activites proches ---
            _buildNearbyActivities(theme, stageData),
            const SizedBox(height: AppTheme.spacingXl),
          ],
        ),
      ),
    );
  }

  Widget _buildRefugeHeader(ThemeData theme, Gr20Refuge refuge) {
    return AppCard(
      backgroundColor: AppTheme.vertMaquis.withAlpha(30),
      borderColor: AppTheme.vertMaquisLight.withAlpha(60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icone type
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: _typeColor(refuge.type).withAlpha(40),
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                ),
                child: Icon(
                  _typeIcon(refuge.type),
                  color: _typeColor(refuge.type),
                  size: 32,
                ),
              ),
              const SizedBox(width: AppTheme.spacingBase),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      refuge.name,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _badge(
                          refuge.type.name.toUpperCase(),
                          _typeColor(refuge.type),
                        ),
                        const SizedBox(width: 8),
                        _badge(
                          'Étape ${refuge.stageNumber}',
                          AppTheme.bleuMed,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingBase),
          // Stats rapides
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _quickStat(theme, Icons.landscape, '${refuge.altitude}m',
                  'Altitude'),
              _quickStat(theme, Icons.people, '${refuge.capacity} places',
                  'Capacite'),
              _quickStat(
                theme,
                Icons.euro,
                refuge.pricePerNight != null
                    ? '${refuge.pricePerNight!.toStringAsFixed(0)}EUR'
                    : 'N/A',
                'Par nuit',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
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
        Icon(icon, color: AppTheme.bleuLight, size: 20),
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

  Widget _buildEquipments(ThemeData theme, Gr20Refuge refuge) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Équipements',
          icon: Icons.check_circle_outline,
        ),
        Wrap(
          spacing: AppTheme.spacingMd,
          runSpacing: AppTheme.spacingMd,
          children: [
            _equipmentChip(Icons.bed, 'Dortoir', true),
            _equipmentChip(
                Icons.shower, 'Douche', refuge.hasShower),
            _equipmentChip(
                Icons.restaurant, 'Repas', refuge.hasMeals),
            _equipmentChip(
                Icons.bolt, 'Électricité', refuge.hasElectricity),
            _equipmentChip(Icons.wc, 'WC', true),
            _equipmentChip(Icons.water_drop, 'Eau', true),
          ],
        ),
      ],
    );
  }

  Widget _equipmentChip(IconData icon, String label, bool available) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: available
            ? AppTheme.vertMaquis.withAlpha(120)
            : AppTheme.rougeUrgence.withAlpha(80),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(
          color: available
              ? AppTheme.vertMaquis
              : AppTheme.rougeUrgence,
          width: 2.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 32,
            color: available ? Colors.white : AppTheme.rougeUrgence,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: available ? Colors.white : AppTheme.rougeUrgence,
              decoration: available ? null : TextDecoration.lineThrough,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticalInfo(ThemeData theme, Gr20Refuge refuge) {
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
              _infoRow(theme, Icons.calendar_today, 'Ouverture',
                  refuge.openingPeriod),
              const Divider(height: 16),
              _infoRow(theme, Icons.restaurant_menu, 'Diner',
                  '19h00 (unique service)'),
              const Divider(height: 16),
              _infoRow(theme, Icons.free_breakfast, 'Petit-dejeuner',
                  '6h30 - 7h30'),
              const Divider(height: 16),
              _infoRow(theme, Icons.access_time, 'Pique-nique',
                  'Commande la veille'),
              if (refuge.distanceFromTrail > 0) ...[
                const Divider(height: 16),
                _infoRow(theme, Icons.directions_walk, 'Distance sentier',
                    '${refuge.distanceFromTrail}m'),
              ],
              if (refuge.website != null) ...[
                const Divider(height: 16),
                _infoRow(theme, Icons.language, 'Réservation',
                    refuge.website!),
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
        Icon(icon, size: 20, color: AppTheme.bleuLight),
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

  /// Section "Réserver" avec boutons CTA (appeler, email, site web).
  /// Boutons affiches uniquement si les donnees sont presentes.
  /// E5.12b — Design #83560.
  Widget _buildBookingSection(BuildContext context, Gr20Refuge refuge) {
    final hasPhone = refuge.phone != null && refuge.phone!.isNotEmpty;
    final hasEmail = refuge.email != null && refuge.email!.isNotEmpty;
    final hasWebsite = refuge.website != null && refuge.website!.isNotEmpty;

    // Pas de donnees de contact → pas de section
    if (!hasPhone && !hasEmail && !hasWebsite) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Réserver',
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
                _logBookingAttempt('phone', refuge.name);
                final phoneNumber = refuge.phone!.replaceAll(' ', '');
                final uri = Uri(scheme: 'tel', path: phoneNumber);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Appeler : ${refuge.phone}'),
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
                _logBookingAttempt('email', refuge.name);
                final uri = Uri(
                  scheme: 'mailto',
                  path: refuge.email!,
                  queryParameters: {
                    'subject': 'Réservation ${refuge.name}',
                  },
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Email : ${refuge.email}'),
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
              _logBookingAttempt('web', refuge.name);
              final uri = Uri.parse(refuge.website!);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Site : ${refuge.website}'),
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
  /// Type: phone, email ou web. POI: nom du refuge.
  /// E5.12b — Design #83560.
  void _logBookingAttempt(String type, String poiName) {
    // TODO(E5.13): remplacer par FirebaseAnalytics.logEvent quand
    // firebase_analytics sera ajoute au pubspec.yaml.
    debugPrint('[analytics] booking_attempt: type=$type, poi=$poiName');
  }

  Widget _buildNoRefugeInfo(ThemeData theme, int stage) {
    return AppCard(
      backgroundColor: AppTheme.orangeTerre.withAlpha(20),
      borderColor: AppTheme.orangeTerre.withAlpha(60),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.orangeLight),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Text(
              'Pas de refuge PNRC a l\'étape $stage. '
              'Consultez les hébergements alternatifs ci-dessous.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherAccommodations(
    ThemeData theme,
    List<Gr20Accommodation> accommodations,
    String? mainRefugeName,
  ) {
    // Exclure le refuge principal s'il est déjà affiche
    final others = accommodations
        .where((a) => a.name != mainRefugeName)
        .toList();

    if (others.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Autres hébergements',
          icon: Icons.hotel,
        ),
        ...others.map((accom) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
            child: AppCard(
              child: Row(
                children: [
                  Icon(
                    _accommodationIcon(accom.type),
                    color: AppTheme.bleuLight,
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
                          '${accom.priceRange} | ${accom.altitude}m',
                          style: theme.textTheme.bodySmall,
                        ),
                        Wrap(
                          spacing: 4,
                          children: accom.amenities.take(3).map((a) {
                            return Text(
                              a,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.bleuLight,
                                fontSize: 14,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  if (accom.phone != null)
                    IconButton(
                      icon: const Icon(Icons.phone, size: 20),
                      color: AppTheme.vertMaquisLight,
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

  IconData _accommodationIcon(AccommodationType type) {
    switch (type) {
      case AccommodationType.refuge:
        return Icons.house;
      case AccommodationType.bergerie:
        return Icons.cabin;
      case AccommodationType.gite:
        return Icons.cottage;
      case AccommodationType.hotel:
        return Icons.hotel;
      case AccommodationType.camping:
        return Icons.park;
      case AccommodationType.bivouac:
        return Icons.nights_stay;
    }
  }

  Widget _buildNearbyActivities(ThemeData theme, Gr20Stage? stage) {
    // Activites génériques basees sur l'étape
    final activities = <_NearbyActivity>[
      if (stage != null && stage.number >= 9)
        const _NearbyActivity(
          icon: Icons.pool,
          title: 'Baignade',
          description: 'Vasques naturelles à proximité',
        ),
      const _NearbyActivity(
        icon: Icons.photo_camera,
        title: 'Point de vue',
        description: 'Panorama montagne et mer',
      ),
      if (stage != null && stage.number <= 8)
        const _NearbyActivity(
          icon: Icons.hiking,
          title: 'Sommet accessible',
          description: 'Aller-retour possible depuis le refuge',
        ),
      const _NearbyActivity(
        icon: Icons.local_florist,
        title: 'Flore endemique',
        description: 'Pins laricio, genets, maquis corse',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'A proximité',
          icon: Icons.explore,
        ),
        ...activities.map((activity) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.vertMaquis.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    activity.icon,
                    color: AppTheme.vertMaquisLight,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        style: theme.textTheme.bodyLarge,
                      ),
                      Text(
                        activity.description,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Color _typeColor(RefugeType type) {
    switch (type) {
      case RefugeType.refuge:
        return AppTheme.orangeTerre;
      case RefugeType.bergerie:
        return AppTheme.orangeLight;
      case RefugeType.gite:
        return AppTheme.bleuMed;
      case RefugeType.hotel:
        return const Color(0xFF7B1FA2);
      case RefugeType.camping:
        return AppTheme.vertMaquis;
    }
  }

  IconData _typeIcon(RefugeType type) {
    switch (type) {
      case RefugeType.refuge:
        return Icons.house;
      case RefugeType.bergerie:
        return Icons.cabin;
      case RefugeType.gite:
        return Icons.cottage;
      case RefugeType.hotel:
        return Icons.hotel;
      case RefugeType.camping:
        return Icons.park;
    }
  }
}

/// Activite à proximité du refuge.
class _NearbyActivity {
  const _NearbyActivity({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
