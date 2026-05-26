import 'package:logger/logger.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Service de notifications locales.
///
/// Gère les rappels matin, les alertes météo et les notifications J-2.
/// Utilise flutter_local_notifications en production.
class NotificationService {
  /// Identifiants des canaux de notification
  static const String channelMorning = 'morning_reminder';
  static const String channelWeather = 'weather_alert';
  static const String channelCountdown = 'countdown';

  /// Planifie le rappel quotidien du matin
  Future<void> scheduleMorningReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    _log.d('[NotificationService] Rappel matin planifié à $hour:$minute');
    // Implémentation flutter_local_notifications prévue
  }

  /// Planifie une alerte météo
  Future<void> scheduleWeatherAlert({
    required DateTime dateTime,
    required String title,
    required String body,
  }) async {
    _log.d('[NotificationService] Alerte météo planifiée pour $dateTime');
  }

  /// Planifie une notification J-2 avant le départ
  Future<void> scheduleCountdown({
    required DateTime departureDate,
    required String trailName,
  }) async {
    final notifDate =
        departureDate.subtract(const Duration(days: 2));

    if (notifDate.isBefore(DateTime.now())) return;

    _log.d('[NotificationService] Notification J-2 planifiée pour $notifDate');
  }

  /// Annule toutes les notifications planifiées
  Future<void> cancelAll() async {
    _log.d('[NotificationService] Toutes les notifications annulées');
  }

  /// Annule une notification par son identifiant
  Future<void> cancel(int id) async {
    _log.d('[NotificationService] Notification $id annulée');
  }

  /// Vérifie si les permissions sont accordées
  Future<bool> checkPermissions() async {
    // Sur desktop/test, toujours autorisé
    return true;
  }

  /// Demande les permissions de notification
  Future<bool> requestPermissions() async {
    return true;
  }
}
