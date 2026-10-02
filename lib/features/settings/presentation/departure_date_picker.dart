/// La date de depart, retenue des qu'elle est choisie : il n'y a pas de bouton
/// « enregistrer » a oublier.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../notifications/providers/download_reminder_provider.dart';
import '../../../core/branding/stepways_icons.dart';

/// Widget de selection de la date de depart pour un sentier.
///
/// Affiche la date choisie (ou un placeholder), avec un bouton
/// pour ouvrir le DatePicker natif Flutter.
/// Sauvegarde automatiquement en SharedPreferences via le provider.
class DepartureDatePicker extends ConsumerWidget {
  const DepartureDatePicker({super.key, required this.trailId});

  /// Identifiant du sentier associe
  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminderState = ref.watch(downloadReminderProvider(trailId));
    final theme = Theme.of(context);
    // StepWays L7 (A) : date localisee sur la langue de l'app (au lieu de 'fr_FR').
    final dateFormat = DateFormat(
      'dd MMM yyyy',
      LocaleSettings.currentLocale.languageCode,
    );

    return AppCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: StepIcon(
          StepwaysIcons.calendrier,
          color: theme.colorScheme.primary,
        ),
        title: Text(t.settings.departureDate),
        subtitle: Text(
          reminderState.departureDate != null
              ? dateFormat.format(reminderState.departureDate!)
              : t.settings.noDateChosen,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: reminderState.departureDate != null
                ? theme.colorScheme.onSurface
                : AppTheme.grisGranite,
          ),
        ),
        trailing: AppButton(
          variant: AppButtonVariant.text,
          icon: StepwaysIcons.calendrier,
          iconSize: 18,
          label: reminderState.departureDate != null ? 'Modifier' : 'Choisir',
          isFullWidth: false,
          onPressed: () => _pickDate(context, ref, reminderState.departureDate),
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
