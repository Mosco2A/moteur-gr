import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../i18n/translations.g.dart';
import '../models/programme_entrainement.dart';
import '../providers/training_providers.dart';

/// Écran du programme d'entraînement pré-trek (F6E-02, F6.5).
///
/// Affiche le plan par semaine/séance, permet de marquer une séance faite, et
/// de planifier des RAPPELS via notifications LOCALES (flutter_local_notifications).
/// Notifications 100 % locales (aucun push serveur, donc aucun tracking).
/// Le calcul et la persistance (séances faites) sont LOCAUX (minimisation RGPD).
/// Textes via Slang, accessibilité via [Semantics].
class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  Future<void> _scheduleReminders(BuildContext context, WidgetRef ref) async {
    final t = Translations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(trainingProvider.notifier);
    final count = await notifier.scheduleReminders(
      startDate: DateTime.now(),
      titleBuilder: (_) => t.training.reminderTitle,
      bodyBuilder: (s) => _seanceLabel(t, s.type),
    );
    messenger.showSnackBar(
      SnackBar(content: Text(t.training.remindersScheduled(n: count))),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(trainingProvider);

    // Regroupe les séances par semaine (jourOffset ~/ 7).
    final byWeek = <int, List<SeanceEntrainement>>{};
    for (final s in state.programme.seances) {
      byWeek.putIfAbsent(s.jourOffset ~/ 7, () => []).add(s);
    }
    final weeks = byWeek.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: Text(t.training.title)),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingBase),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _LocalNoticeBanner(message: t.training.localNotice),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    t.training.progress(
                      done: state.doneCount,
                      total: state.programme.nbSeances,
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingBase,
                ),
                itemCount: weeks.length,
                itemBuilder: (context, i) {
                  final week = weeks[i];
                  final seances = byWeek[week]!;
                  return _WeekSection(
                    weekLabel: t.training.week(n: week + 1),
                    seances: seances,
                    isDone: state.isDone,
                    typeLabel: (type) => _seanceLabel(t, type),
                    intensityLabel: (it) => _intensityLabel(t, it),
                    minutesLabel: (m) => t.training.minutes(n: m),
                    onToggle: (offset) =>
                        ref.read(trainingProvider.notifier).toggleDone(offset),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingBase),
              child: Semantics(
                button: true,
                label: t.training.scheduleReminders,
                // SW-SKIN-L3e : ElevatedButton.icon -> AppButton primary, pleine
                // largeur (minimumSize infinie conservee) ; minHeight 52 = meme
                // cible tactile. Semantics(button+label) preservee au-dessus.
                child: AppButton(
                  minHeight: 52,
                  icon: Icons.notifications_active_outlined,
                  label: t.training.scheduleReminders,
                  onPressed: () => _scheduleReminders(context, ref),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _seanceLabel(Translations t, TypeSeance type) {
    switch (type) {
      case TypeSeance.marche:
        return t.training.types.marche;
      case TypeSeance.cardio:
        return t.training.types.cardio;
      case TypeSeance.renforcement:
        return t.training.types.renforcement;
    }
  }

  String _intensityLabel(Translations t, IntensiteSeance intensite) {
    switch (intensite) {
      case IntensiteSeance.faible:
        return t.training.intensity.faible;
      case IntensiteSeance.moderee:
        return t.training.intensity.moderee;
      case IntensiteSeance.elevee:
        return t.training.intensity.elevee;
    }
  }
}

/// Section d'une semaine du programme.
class _WeekSection extends StatelessWidget {
  const _WeekSection({
    required this.weekLabel,
    required this.seances,
    required this.isDone,
    required this.typeLabel,
    required this.intensityLabel,
    required this.minutesLabel,
    required this.onToggle,
  });

  final String weekLabel;
  final List<SeanceEntrainement> seances;
  final bool Function(int jourOffset) isDone;
  final String Function(TypeSeance type) typeLabel;
  final String Function(IntensiteSeance intensite) intensityLabel;
  final String Function(int minutes) minutesLabel;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
          child: Text(
            weekLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ...seances.map((s) {
          final done = isDone(s.jourOffset);
          // SW-SKIN-L3e : Card -> AppCard. key conservee ; padding zero car le
          // CheckboxListTile porte son padding interne (iso-rendu). AppCard
          // fournit le Material transparent requis par l'encre de la case.
          return AppCard(
            key: ValueKey('seance-${s.jourOffset}'),
            padding: EdgeInsets.zero,
            child: CheckboxListTile(
              value: done,
              onChanged: (_) => onToggle(s.jourOffset),
              title: Text('${typeLabel(s.type)} · ${minutesLabel(s.dureeMin)}'),
              subtitle: Text(
                '${intensityLabel(s.intensite)} — ${s.description}',
              ),
              secondary: Icon(_iconFor(s.type)),
              controlAffinity: ListTileControlAffinity.trailing,
            ),
          );
        }),
      ],
    );
  }

  IconData _iconFor(TypeSeance type) {
    switch (type) {
      case TypeSeance.marche:
        return Icons.directions_walk;
      case TypeSeance.cardio:
        return Icons.favorite_outline;
      case TypeSeance.renforcement:
        return Icons.fitness_center;
    }
  }
}

/// Bandeau rappelant que les notifications sont locales (pas de tracking).
class _LocalNoticeBanner extends StatelessWidget {
  const _LocalNoticeBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: message,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer.withAlpha(60),
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lock_outline,
              size: 20,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
