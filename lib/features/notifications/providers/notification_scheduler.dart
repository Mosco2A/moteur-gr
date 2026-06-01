import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../i18n/translations.g.dart';
import '../domain/notification_service.dart';
import 'notification_provider.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Identifiant de base pour les notifications du scheduler quotidien.
const _dailyReminderBaseId = 4000;

/// Heure d'envoi du rappel J-2 (18h).
const _countdownHour = 18;

/// Heure d'envoi du rappel quotidien pendant le trek (7h).
const _dailyReminderHour = 7;

/// Nombre de jours avant le depart pour le rappel J-2.
const _daysBeforeDeparture = 2;

/// Etat du scheduler de notifications.
class NotificationSchedulerState {
  const NotificationSchedulerState({
    this.departureDate,
    this.trekDurationDays = 0,
    this.countdownScheduled = false,
    this.dailyRemindersCount = 0,
  });

  /// Date de depart du trek.
  final DateTime? departureDate;

  /// Duree du trek en jours.
  final int trekDurationDays;

  /// Indique si la notification J-2 a ete planifiee.
  final bool countdownScheduled;

  /// Nombre de rappels quotidiens planifies.
  final int dailyRemindersCount;

  NotificationSchedulerState copyWith({
    DateTime? departureDate,
    int? trekDurationDays,
    bool? countdownScheduled,
    int? dailyRemindersCount,
  }) {
    return NotificationSchedulerState(
      departureDate: departureDate ?? this.departureDate,
      trekDurationDays: trekDurationDays ?? this.trekDurationDays,
      countdownScheduled: countdownScheduled ?? this.countdownScheduled,
      dailyRemindersCount: dailyRemindersCount ?? this.dailyRemindersCount,
    );
  }
}

/// Planificateur de notifications pour un trek.
///
/// Planifie :
/// - 1 notification J-2 (2 jours avant le depart, a 18h)
/// - N rappels quotidiens pendant le trek (chaque matin a 7h)
///
/// Utilise les textes Slang (5 langues). Aucun texte en dur.
class NotificationSchedulerNotifier extends Notifier<NotificationSchedulerState> {
  late NotificationService _service;

  @override
  NotificationSchedulerState build() {
    _service = ref.read(notificationServiceProvider);
    return const NotificationSchedulerState();
  }

  /// Planifie toutes les notifications pour un trek.
  ///
  /// [departureDate] : date de depart du trek.
  /// [trekDurationDays] : nombre de jours de trek.
  /// [locale] : locale Slang pour les textes.
  Future<void> scheduleAll({
    required DateTime departureDate,
    required int trekDurationDays,
    Translations? locale,
  }) async {
    final t = locale ?? LocaleSettings.instance.currentTranslations;

    state = state.copyWith(
      departureDate: departureDate,
      trekDurationDays: trekDurationDays,
      countdownScheduled: false,
      dailyRemindersCount: 0,
    );

    // Planifier J-2
    await _scheduleCountdown(departureDate, t);

    // Planifier rappels quotidiens pendant le trek
    await _scheduleDailyReminders(departureDate, trekDurationDays, t);

    _log.d(
      '[NotificationScheduler] Planification terminee : '
      'J-2=${state.countdownScheduled}, '
      'quotidiens=${state.dailyRemindersCount}',
    );
  }

  /// Planifie la notification J-2 avant le depart.
  Future<void> _scheduleCountdown(DateTime departureDate, Translations t) async {
    final countdownDate = departureDate.subtract(
      const Duration(days: _daysBeforeDeparture),
    );
    final scheduledDateTime = DateTime(
      countdownDate.year,
      countdownDate.month,
      countdownDate.day,
      _countdownHour,
    );

    if (scheduledDateTime.isBefore(DateTime.now())) {
      _log.d('[NotificationScheduler] J-2 ignoree (date passee)');
      return;
    }

    await _service.scheduleCountdown(
      departureDate: departureDate,
      title: t.notifications.schedulerCountdownTitle,
      body: t.notifications.schedulerCountdownBody,
    );

    state = state.copyWith(countdownScheduled: true);
    _log.d('[NotificationScheduler] J-2 planifiee pour $scheduledDateTime');
  }

  /// Planifie un rappel quotidien a 7h pour chaque jour de trek.
  Future<void> _scheduleDailyReminders(
    DateTime departureDate,
    int trekDurationDays,
    Translations t,
  ) async {
    var count = 0;

    for (var dayIndex = 0; dayIndex < trekDurationDays; dayIndex++) {
      final reminderDate = departureDate.add(Duration(days: dayIndex));
      final scheduledDateTime = DateTime(
        reminderDate.year,
        reminderDate.month,
        reminderDate.day,
        _dailyReminderHour,
      );

      if (scheduledDateTime.isBefore(DateTime.now())) {
        _log.d(
          '[NotificationScheduler] Rappel jour $dayIndex ignore (date passee)',
        );
        continue;
      }

      await _service.scheduleWeatherAlert(
        dateTime: scheduledDateTime,
        title: t.notifications.schedulerDailyTitle,
        body: t.notifications.schedulerDailyBody,
        alertIndex: _dailyReminderBaseId + dayIndex,
      );
      count++;
    }

    state = state.copyWith(dailyRemindersCount: count);
    _log.d('[NotificationScheduler] $count rappels quotidiens planifies');
  }

  /// Annule toutes les notifications planifiees par ce scheduler.
  Future<void> cancelAll() async {
    await _service.cancelAll();
    state = const NotificationSchedulerState();
    _log.d('[NotificationScheduler] Toutes les notifications annulees');
  }
}

/// Provider du scheduler de notifications.
final notificationSchedulerProvider =
    NotifierProvider<NotificationSchedulerNotifier, NotificationSchedulerState>(
  NotificationSchedulerNotifier.new,
);

/// Calcule la date J-2 pour une date de depart donnee.
///
/// Expose en tant que fonction utilitaire pour les tests
/// et les composants qui veulent afficher la date de notification.
DateTime computeCountdownDate(DateTime departureDate) {
  return departureDate.subtract(const Duration(days: _daysBeforeDeparture));
}
