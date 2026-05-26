import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../notifications/providers/download_reminder_provider.dart';

/// Widget de selection de la date de depart pour un sentier.
///
/// Affiche la date choisie (ou un placeholder), avec un bouton
/// pour ouvrir le DatePicker natif Flutter.
/// Sauvegarde automatiquement en SharedPreferences via le provider.
class DepartureDatePicker extends ConsumerWidget {
  const DepartureDatePicker({
    super.key,
    required this.trailId,
  });

  /// Identifiant du sentier associe
  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminderState = ref.watch(downloadReminderProvider(trailId));
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy', 'fr_FR');

    return Card(
      child: ListTile(
        leading: Icon(
          Icons.calendar_today,
          color: theme.colorScheme.primary,
        ),
        title: const Text('Date de depart'),
        subtitle: Text(
          reminderState.departureDate != null
              ? dateFormat.format(reminderState.departureDate!)
              : 'Aucune date choisie',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: reminderState.departureDate != null
                ? theme.colorScheme.onSurface
                : AppTheme.grisGranite,
          ),
        ),
        trailing: TextButton.icon(
          onPressed: () => _pickDate(context, ref, reminderState.departureDate),
          icon: const Icon(Icons.edit_calendar, size: 18),
          label: Text(
            reminderState.departureDate != null ? 'Modifier' : 'Choisir',
          ),
        ),
      ),
    );
  }

  /// Ouvre le DatePicker natif et sauvegarde la date choisie.
  Future<void> _pickDate(
    BuildContext context,
    WidgetRef ref,
    DateTime? currentDate,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Date de depart',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );

    if (picked != null) {
      ref
          .read(downloadReminderProvider(trailId).notifier)
          .setDepartureDate(picked);
    }
  }
}
