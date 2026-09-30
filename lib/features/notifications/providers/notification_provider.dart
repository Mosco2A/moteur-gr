import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/notification_service.dart';

/// Provider singleton du service de notifications
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Cles SharedPreferences des reglages de notification (596 C3).
///
/// Convention maison `settings_*` / `<domaine>_*` (cf. `SettingsKeys` et
/// `VisibilityKeys`). AUCUNE de ces cles n'existait : le module ne persistait
/// rien du tout, et chaque redemarrage rallumait ce que le randonneur avait
/// coupe.
abstract final class NotificationKeys {
  static const String morningReminder = 'notifications_morning_reminder';
  static const String morningHour = 'notifications_morning_hour';
  static const String morningMinute = 'notifications_morning_minute';
  static const String weatherAlerts = 'notifications_weather_alerts';
  static const String countdown = 'notifications_countdown';
  static const String offTrackAlerts = 'notifications_off_track_alerts';
}

/// Etat des parametres de notification
class NotificationSettings {
  const NotificationSettings({
    this.morningReminderEnabled = true,
    this.morningReminderHour = 7,
    this.morningReminderMinute = 0,
    this.weatherAlertsEnabled = true,
    this.countdownEnabled = true,
    this.offTrackAlerts = true,
    this.permissionGranted = false,
  });

  final bool morningReminderEnabled;
  final int morningReminderHour;
  final int morningReminderMinute;
  final bool weatherAlertsEnabled;
  final bool countdownEnabled;

  /// Alerte de securite hors-trace (notification + vibration). ON par defaut :
  /// c'est une alerte de securite randonneur, l'utilisateur peut la couper.
  final bool offTrackAlerts;
  final bool permissionGranted;

  NotificationSettings copyWith({
    bool? morningReminderEnabled,
    int? morningReminderHour,
    int? morningReminderMinute,
    bool? weatherAlertsEnabled,
    bool? countdownEnabled,
    bool? offTrackAlerts,
    bool? permissionGranted,
  }) {
    return NotificationSettings(
      morningReminderEnabled:
          morningReminderEnabled ?? this.morningReminderEnabled,
      morningReminderHour: morningReminderHour ?? this.morningReminderHour,
      morningReminderMinute:
          morningReminderMinute ?? this.morningReminderMinute,
      weatherAlertsEnabled: weatherAlertsEnabled ?? this.weatherAlertsEnabled,
      countdownEnabled: countdownEnabled ?? this.countdownEnabled,
      offTrackAlerts: offTrackAlerts ?? this.offTrackAlerts,
      permissionGranted: permissionGranted ?? this.permissionGranted,
    );
  }
}

/// Notifier des reglages de notification — PERSISTES (596 C3).
///
/// AVANT : `build()` rendait `const NotificationSettings()` et les cinq
/// mutateurs n'ecrivaient que `state`. Aucun stockage, d'aucune sorte. Le
/// constat de Chris — « on coupe, on relance, tout est revenu » — n'etait pas
/// un bug d'affichage : le reglage n'avait simplement jamais ete ecrit.
///
/// Le chargement suit le patron maison (`VisibilitySettingsNotifier`) : on rend
/// TOUT DE SUITE les valeurs par defaut du produit (lecture synchrone possible
/// des la construction, cf. `off_track_provider`), puis on les remplace par
/// celles du randonneur des que les prefs sont lues. La securite hors-trace
/// reste donc ON pendant le chargement — jamais de trou de securite transitoire.
class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  late NotificationService _service;
  SharedPreferences? _prefs;

  @override
  NotificationSettings build() {
    _service = ref.read(notificationServiceProvider);
    _load();
    _checkPermissions();
    return const NotificationSettings();
  }

  /// Relit les reglages ecrits par le randonneur.
  ///
  /// `ref.mounted` apres le gap async : si le provider a ete dispose pendant
  /// l'attente, ecrire `state` leverait « Ref used after dispose » (Riverpod 3).
  Future<void> _load() async {
    final SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } on Object {
      // Stockage indisponible : on garde les valeurs par defaut du produit.
      // Un reglage illisible ne doit jamais empecher l'appli de demarrer.
      return;
    }
    if (!ref.mounted) return;
    _prefs = prefs;
    state = state.copyWith(
      morningReminderEnabled: prefs.getBool(NotificationKeys.morningReminder),
      morningReminderHour: prefs.getInt(NotificationKeys.morningHour),
      morningReminderMinute: prefs.getInt(NotificationKeys.morningMinute),
      weatherAlertsEnabled: prefs.getBool(NotificationKeys.weatherAlerts),
      countdownEnabled: prefs.getBool(NotificationKeys.countdown),
      offTrackAlerts: prefs.getBool(NotificationKeys.offTrackAlerts),
    );
  }

  /// Ecrit une valeur meme si `_load()` n'est pas encore revenu.
  ///
  /// Sans ca, couper un reglage dans la seconde qui suit l'ouverture de l'ecran
  /// serait perdu : `_prefs` serait encore nul et l'ecriture partirait dans le
  /// vide — exactement le defaut qu'on corrige.
  Future<void> _ecrire(
    Future<void> Function(SharedPreferences) ecriture,
  ) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs ??= prefs;
      await ecriture(prefs);
    } on Object {
      // Ecriture impossible : l'interrupteur a l'ecran reflete deja le choix,
      // il ne survivra simplement pas au redemarrage. On ne casse rien.
    }
  }

  Future<void> _ecrireBool(String cle, bool valeur) =>
      _ecrire((prefs) => prefs.setBool(cle, valeur));

  Future<void> _ecrireInt(String cle, int valeur) =>
      _ecrire((prefs) => prefs.setInt(cle, valeur));

  Future<void> _checkPermissions() async {
    final granted = await _service.checkPermissions();
    if (!ref.mounted) return;
    state = state.copyWith(permissionGranted: granted);
  }

  Future<void> requestPermissions() async {
    final granted = await _service.requestPermissions();
    if (!ref.mounted) return;
    state = state.copyWith(permissionGranted: granted);
  }

  /// Allume ou ETEINT le rappel du matin — les deux, vraiment.
  ///
  /// Couper annule desormais la notification deja posee dans le systeme : sans
  /// ca le randonneur la recevait encore apres avoir eteint l'interrupteur.
  void toggleMorningReminder(bool enabled) {
    state = state.copyWith(morningReminderEnabled: enabled);
    _ecrireBool(NotificationKeys.morningReminder, enabled);
    if (enabled) {
      _service.scheduleMorningReminder(
        hour: state.morningReminderHour,
        minute: state.morningReminderMinute,
        title: 'Bonne randonnee !',
        body: "N'oubliez pas de verifier la meteo avant de partir.",
      );
    } else {
      _service.cancelMorningReminder();
    }
  }

  void setMorningTime(int hour, int minute) {
    state = state.copyWith(
      morningReminderHour: hour,
      morningReminderMinute: minute,
    );
    _ecrireInt(NotificationKeys.morningHour, hour);
    _ecrireInt(NotificationKeys.morningMinute, minute);
    // Re-planifie a la nouvelle heure si le rappel est actif, sinon l'heure
    // affichee et l'heure reellement armee divergeraient.
    if (state.morningReminderEnabled) {
      _service.scheduleMorningReminder(
        hour: hour,
        minute: minute,
        title: 'Bonne randonnee !',
        body: "N'oubliez pas de verifier la meteo avant de partir.",
      );
    }
  }

  void toggleWeatherAlerts(bool enabled) {
    state = state.copyWith(weatherAlertsEnabled: enabled);
    _ecrireBool(NotificationKeys.weatherAlerts, enabled);
  }

  void toggleCountdown(bool enabled) {
    state = state.copyWith(countdownEnabled: enabled);
    _ecrireBool(NotificationKeys.countdown, enabled);
  }

  /// Active / desactive l'alerte de securite hors-trace. ON par defaut. Couper
  /// n'affecte que la notification+vibration ; la surveillance in-screen suit
  /// le meme reglage cote provider off-track.
  void toggleOffTrackAlerts(bool enabled) {
    state = state.copyWith(offTrackAlerts: enabled);
    _ecrireBool(NotificationKeys.offTrackAlerts, enabled);
  }
}

/// Provider des parametres de notification
final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
      NotificationSettingsNotifier.new,
    );
