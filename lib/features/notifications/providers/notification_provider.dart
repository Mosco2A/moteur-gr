import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/notification_service.dart';

/// Provider singleton du service de notifications
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// État des paramètres de notification
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

/// Notifier pour les paramètres de notification
class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier(this._service)
      : super(const NotificationSettings()) {
    _checkPermissions();
  }

  final NotificationService _service;

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
        title: 'Bonne randonnée !',
        body: 'N\'oubliez pas de vérifier la météo avant de partir.',
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

/// Provider des paramètres de notification
final notificationSettingsProvider = StateNotifierProvider<
    NotificationSettingsNotifier, NotificationSettings>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return NotificationSettingsNotifier(service);
});
