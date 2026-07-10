import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:timezone/timezone.dart' as tz;

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

const _morningBaseId = 1000;
const _weatherBaseId = 2000;
const _countdownBaseId = 3000;
const _trainingBaseId = 4000;

/// Id fixe de l'alerte hors-trace : UNE seule notification a la fois,
/// remplacable / annulable au retour sur le trace. En dehors des plages de base
/// des rappels planifies (matin/meteo/J-2/entrainement).
const _offTrackId = 5000;

class NotificationService {
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;


  static const String channelMorning = 'morning_reminder';
  static const String channelWeather = 'weather_alert';
  static const String channelCountdown = 'countdown';
  static const String channelTraining = 'training_reminder';

  /// Canal dedie a l'alerte de securite hors-trace. Generique (aucun sentier
  /// particulier). Importance HAUTE + visibilite publique -> la notification
  /// surgit meme ecran verrouille (telephone en poche).
  static const String channelOffTrack = 'offtrack_alert';
  static const String channelMorningDesc = 'Morning departure reminders';
  static const String channelWeatherDesc = 'Weather alerts for the trail';
  static const String channelCountdownDesc = 'D-2 countdown before departure';
  static const String channelTrainingDesc = 'Pre-trek training session reminders';
  static const String channelOffTrackDesc =
      'Alerts when you move away from the trail';

  Future<void> initialize() async {
    if (_initialized) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(settings);
    _initialized = true;
    _log.d('[NotificationService] Plugin initialise');
  }

  Future<int> scheduleMorningReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _ensureInitialized();
    const id = _morningBaseId;
    final scheduledTime = _nextInstanceOfTime(hour, minute);
    await _plugin.zonedSchedule(
      id, title, body, scheduledTime,
      _notificationDetails(channelMorning, channelMorningDesc),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    _log.d('[NotificationService] Rappel matin planifie a $hour:$minute (id=$id)');
    return id;
  }

  Future<int> scheduleWeatherAlert({
    required DateTime dateTime,
    required String title,
    required String body,
    int alertIndex = 0,
  }) async {
    await _ensureInitialized();
    final id = _weatherBaseId + alertIndex;
    if (dateTime.isBefore(DateTime.now())) {
      _log.d('[NotificationService] Alerte meteo ignoree (date passee: $dateTime)');
      return id;
    }
    final scheduledTime = tz.TZDateTime.from(dateTime, tz.local);
    await _plugin.zonedSchedule(
      id, title, body, scheduledTime,
      _notificationDetails(channelWeather, channelWeatherDesc),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
    _log.d('[NotificationService] Alerte meteo planifiee pour $dateTime (id=$id)');
    return id;
  }

  Future<int> scheduleCountdown({
    required DateTime departureDate,
    required String title,
    required String body,
  }) async {
    await _ensureInitialized();
    final notifDate = departureDate.subtract(const Duration(days: 2));
    final scheduledDateTime = DateTime(notifDate.year, notifDate.month, notifDate.day, 18, 0);
    final id = _countdownBaseId + (departureDate.hashCode.abs() % 500);
    if (scheduledDateTime.isBefore(DateTime.now())) {
      _log.d('[NotificationService] J-2 ignoree (date passee: $scheduledDateTime)');
      return id;
    }
    final scheduledTime = tz.TZDateTime.from(scheduledDateTime, tz.local);
    await _plugin.zonedSchedule(
      id, title, body, scheduledTime,
      _notificationDetails(channelCountdown, channelCountdownDesc),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
    _log.d('[NotificationService] J-2 planifiee pour $scheduledDateTime (id=$id)');
    return id;
  }

  /// Planifie un rappel LOCAL pour une séance d'entraînement (F6E-02).
  ///
  /// Notification 100 % LOCALE (aucun push serveur, aucun identifiant/tracking).
  /// Ignorée si [dateTime] est déjà passée. [sessionIndex] sépare les ids.
  Future<int> scheduleTrainingReminder({
    required DateTime dateTime,
    required String title,
    required String body,
    int sessionIndex = 0,
  }) async {
    await _ensureInitialized();
    final id = _trainingBaseId + sessionIndex;
    if (dateTime.isBefore(DateTime.now())) {
      _log.d('[NotificationService] Rappel entrainement ignore (date passee: $dateTime)');
      return id;
    }
    final scheduledTime = tz.TZDateTime.from(dateTime, tz.local);
    await _plugin.zonedSchedule(
      id, title, body, scheduledTime,
      _notificationDetails(channelTraining, channelTrainingDesc),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
    _log.d('[NotificationService] Rappel entrainement planifie pour $dateTime (id=$id)');
    return id;
  }

  /// Affiche IMMEDIATEMENT l'alerte hors-trace (F-OT, securite randonneur).
  ///
  /// Notification 100 % LOCALE, id fixe [_offTrackId] : une seule a la fois,
  /// remplacee si rappelee. Canal dedie importance HAUTE + visibilite publique
  /// pour surgir ecran verrouille (le randonneur a le telephone en poche).
  /// Ne planifie rien : l'alerte est declenchee a la sortie du trace.
  Future<void> showOffTrackAlert({
    required String title,
    required String body,
  }) async {
    await _ensureInitialized();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelOffTrack,
        channelOffTrack,
        channelDescription: channelOffTrackDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        visibility: NotificationVisibility.public,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    await _plugin.show(_offTrackId, title, body, details);
    _log.d('[NotificationService] Alerte hors-trace affichee (id=$_offTrackId)');
  }

  /// Leve l'alerte hors-trace (retour sur le trace).
  Future<void> cancelOffTrackAlert() async {
    await _ensureInitialized();
    await _plugin.cancel(_offTrackId);
    _log.d('[NotificationService] Alerte hors-trace levee (id=$_offTrackId)');
  }

  Future<void> cancelAll() async {
    await _ensureInitialized();
    await _plugin.cancelAll();
    _log.d('[NotificationService] Toutes les notifications annulees');
  }

  Future<void> cancel(int id) async {
    await _ensureInitialized();
    await _plugin.cancel(id);
    _log.d('[NotificationService] Notification $id annulee');
  }

  Future<bool> checkPermissions() async => true;

  Future<bool> requestPermissions() async {
    await _ensureInitialized();
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      return await androidPlugin.requestNotificationsPermission() ?? false;
    }
    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      return await iosPlugin.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    return true;
  }

  Future<List<PendingNotificationRequest>> pendingNotifications() async {
    await _ensureInitialized();
    return _plugin.pendingNotificationRequests();
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) await initialize();
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  NotificationDetails _notificationDetails(String channelId, String channelDescription) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId, channelId,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}
