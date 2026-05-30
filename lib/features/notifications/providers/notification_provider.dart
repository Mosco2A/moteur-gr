import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/notification_service.dart';

/// Provider singleton du service de notifications
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Etat des parametres de notification
class NotificationSettings {
  const NotificationSettings({
    this.morningReminderEnabled = true,
    this.morningReminderHour = 7,
    this.morningReminderMinute = 0,
    this.weatherAlertsEnabled = true,
    this.countdownEnabled = true,
    this.permissionGranted = false,
  });

  final bool morningReminderEnabled;
  final int morningReminderHour;
  final int morningReminderMinute;
  final bool weatherAlertsEnabled;
  final bool countdownEnabled;
  final bool permissionGranted;

  NotificationSettings copyWith({
    bool? morningReminderEnabled,
    int? morningReminderHour,
    int? morningReminderMinute,
    bool? weatherAlertsEnabled,
    bool? countdownEnabled,
    bool? permissionGranted,
  }) {
    return NotificationSettings(
      morningReminderEnabled:
          morningReminderEnabled ?? this.morningReminderEnabled,
      morningReminderHour:
          morningReminderHour ?? this.morningReminderHour,
      morningReminderMinute:
          morningReminderMinute ?? this.morningReminderMinute,
      weatherAlertsEnabled:
          weatherAlertsEnabled ?? this.weatherAlertsEnabled,
      countdownEnabled: countdownEnabled ?? this.countdownEnabled,
      permissionGranted: permissionGranted ?? this.permissionGranted,
    );
  }
}

/// Notifier pour les parametres de notification
class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  late NotificationService _service;

  @override
  NotificationSettings build() {
    _service = ref.watch(notificationServiceProvider);
    _checkPermissions();
    return const NotificationSettings();
  }

  Future<void> _checkPermissions() async {
    final granted = await _service.checkPermissions();
    state = state.copyWith(permissionGranted: granted);
  }

  Future<void> requestPermissions() async {
    final granted = await _service.requestPermissions();
    state = state.copyWith(permissionGranted: granted);
  }

  void toggleMorningReminder(bool enabled) {
    state = state.copyWith(morningReminderEnabled: enabled);
    if (enabled) {
      _service.scheduleMorningReminder(
        hour: state.morningReminderHour,
        minute: state.morningReminderMinute,
        title: 'Bonne randonnee !',
        body: "N'oubliez pas de verifier la meteo avant de partir.",
      );
    }
  }

  void setMorningTime(int hour, int minute) {
    state = state.copyWith(
      morningReminderHour: hour,
      morningReminderMinute: minute,
    );
  }

  void toggleWeatherAlerts(bool enabled) {
    state = state.copyWith(weatherAlertsEnabled: enabled);
  }

  void toggleCountdown(bool enabled) {
    state = state.copyWith(countdownEnabled: enabled);
  }
}

/// Provider des parametres de notification
final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
        NotificationSettingsNotifier.new);
