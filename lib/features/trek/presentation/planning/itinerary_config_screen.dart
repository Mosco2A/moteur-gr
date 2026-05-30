import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/itinerary_config.dart';
import '../../domain/models/itinerary_day.dart';
import '../../providers/itinerary_providers.dart';

/// Ecran de configuration de l'itineraire.
///
/// Permet a l'utilisateur de definir :
/// - Distance max par jour (slider 10-30 km)
/// - Duree max par jour (slider 4-10 h)
/// - Date de depart (date picker Material 3)
///
/// Met a jour itineraryConfigProvider en temps reel.
/// Affiche un apercu du nombre de jours calcule.
class ItineraryConfigScreen extends ConsumerWidget {
  const ItineraryConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(
      itineraryConfigProvider.select((c) => c),
    );
    final itineraryAsync = ref.watch(
      itineraryProvider.select((async) => async),
    );

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration itineraire'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Distance max par jour ---
          _SectionCard(
            icon: Icons.straighten,
            title: 'Distance maximale par jour',
            subtitle: '${config.maxKmPerDay.round()} km',
            colorScheme: colorScheme,
            child: Slider(
              value: config.maxKmPerDay,
              min: 10,
              max: 30,
              divisions: 20,
              label: '${config.maxKmPerDay.round()} km',
              onChanged: (value) {
                ref.read(itineraryConfigProvider.notifier).state =
                    config.copyWith(maxKmPerDay: value);
              },
            ),
          ),

          const SizedBox(height: 12),

          // --- Duree max par jour ---
          _SectionCard(
            icon: Icons.schedule,
            title: 'Duree maximale par jour',
            subtitle: '${config.maxHoursPerDay.toStringAsFixed(1)} h',
            colorScheme: colorScheme,
            child: Slider(
              value: config.maxHoursPerDay,
              min: 4,
              max: 10,
              divisions: 12,
              label: '${config.maxHoursPerDay.toStringAsFixed(1)} h',
              onChanged: (value) {
                ref.read(itineraryConfigProvider.notifier).state =
                    config.copyWith(maxHoursPerDay: value);
              },
            ),
          ),

          const SizedBox(height: 12),

          // --- Date de depart ---
          _SectionCard(
            icon: Icons.calendar_today,
            title: 'Date de depart',
            subtitle: _formatDate(config.startDate),
            colorScheme: colorScheme,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonal(
                onPressed: () => _pickStartDate(context, ref, config),
                child: Text(_formatDate(config.startDate)),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // --- Apercu itineraire ---
          _ItinerarySummary(
            itineraryAsync: itineraryAsync,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  /// Ouvre le date picker Material 3.
  Future<void> _pickStartDate(
    BuildContext context,
    WidgetRef ref,
    ItineraryConfig config,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: config.startDate.isBefore(now) ? now : config.startDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      ref.read(itineraryConfigProvider.notifier).state =
          config.copyWith(startDate: picked);
    }
  }

  /// Formate une date en dd/MM/yyyy.
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

/// Carte section avec icone, titre et sous-titre.
///
/// Design Material 3 : Card avec leading icon + header + child widget.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colorScheme,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final ColorScheme colorScheme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

/// Apercu du resultat de l'itineraire.
///
/// Affiche le nombre de jours calcule, ou un indicateur de chargement,
/// ou un message d'erreur selon l'etat de itineraryProvider.
class _ItinerarySummary extends StatelessWidget {
  const _ItinerarySummary({
    required this.itineraryAsync,
    required this.colorScheme,
  });

  final AsyncValue<List<ItineraryDay>> itineraryAsync;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: itineraryAsync.when(
          loading: () => const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Calcul en cours...'),
            ],
          ),
          error: (_, __) => Row(
            children: [
              Icon(Icons.warning_amber, color: colorScheme.error),
              const SizedBox(width: 8),
              const Expanded(
                child: Text("Impossible de calculer l'itineraire"),
              ),
            ],
          ),
          data: (days) {
            if (days.isEmpty) {
              return const Row(
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 8),
                  Text('Aucune etape chargee'),
                ],
              );
            }

            final totalKm = days.fold<double>(
              0,
              (sum, d) => sum + d.totalDistance,
            );
            final totalElevation = days.fold<int>(
              0,
              (sum, d) => sum + d.totalElevation,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Itineraire : ${days.length} jours',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${totalKm.toStringAsFixed(1)} km total  '
                  'D+ $totalElevation m',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
