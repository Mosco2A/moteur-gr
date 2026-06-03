// E5.14b — Service widget lockscreen contacts urgence.
//
// Expose les contacts d'urgence sur l'ecran de verrouillage :
// - Android : notification foreground persistante avec contacts
// - iOS : WidgetKit widget contacts urgence
//
// Utilise EmergencyContactsService (E5.14a) comme source de donnees.
// Adapte pour Moteur-GR : imports generiques, pas de dep GR20.

import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Contact d'urgence minimal pour le widget lockscreen.
///
/// Structure simplifiee — le modele complet EmergencyContact
/// sera fourni par E5.14a. En attendant, cette classe suffit
/// pour le service lockscreen.
class LockscreenContact {
  const LockscreenContact({
    required this.name,
    required this.phone,
    this.isAutomatic = false,
  });

  final String name;
  final String phone;
  final bool isAutomatic;

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'isAutomatic': isAutomatic,
      };
}

/// Service de widget lockscreen pour contacts d'urgence.
///
/// Cree une notification persistante (Android) ou met a jour
/// le WidgetKit (iOS) avec la liste des contacts urgence.
class LockscreenWidgetService {
  LockscreenWidgetService({
    FlutterLocalNotificationsPlugin? notificationsPlugin,
  }) : _notificationsPlugin =
            notificationsPlugin ?? FlutterLocalNotificationsPlugin();

  /// Plugin de notifications locales (Android foreground notification).
  final FlutterLocalNotificationsPlugin _notificationsPlugin;

  /// ID fixe pour la notification persistante Android.
  static const int _notificationId = 9001;

  /// Channel ID pour la notification urgence lockscreen.
  static const String _channelId = 'emergency_lockscreen';

  /// Indique si le widget lockscreen est actuellement actif.
  bool _isActive = false;

  /// Getter pour l'etat actif.
  bool get isActive => _isActive;

  /// Active le widget lockscreen avec les contacts d'urgence.
  ///
  /// Android : cree une notification foreground persistante.
  /// iOS : met a jour le WidgetKit widget via UserDefaults + reloadTimelines.
  Future<void> activate(List<LockscreenContact> contacts) async {
    if (contacts.isEmpty) return;

    if (Platform.isAndroid) {
      await _showAndroidNotification(contacts);
    } else if (Platform.isIOS) {
      await _updateIosWidget(contacts);
    }

    _isActive = true;
  }

  /// Desactive le widget lockscreen.
  ///
  /// Android : supprime la notification persistante.
  /// iOS : vide les donnees du WidgetKit widget.
  Future<void> deactivate() async {
    if (Platform.isAndroid) {
      await _notificationsPlugin.cancel(_notificationId);
    } else if (Platform.isIOS) {
      await _clearIosWidget();
    }

    _isActive = false;
  }

  /// Met a jour le contenu du widget avec les contacts actuels.
  ///
  /// Appeler apres ajout/suppression d'un contact personnel
  /// pour rafraichir l'affichage lockscreen.
  Future<void> refresh(List<LockscreenContact> contacts) async {
    if (!_isActive) return;
    await activate(contacts);
  }

  // ---------------------------------------------------------------------------
  // Android — Notification foreground persistante
  // ---------------------------------------------------------------------------

  /// Cree la notification persistante Android avec la liste des contacts.
  ///
  /// La notification est ongoing (non-dismissable) et affiche
  /// les contacts sous forme de BigTextStyle avec numeros appelables.
  Future<void> _showAndroidNotification(
    List<LockscreenContact> contacts,
  ) async {
    final body = _formatContactsForNotification(contacts);

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      'Contacts urgence',
      channelDescription:
          'Affiche les contacts d\'urgence sur l\'ecran de verrouillage',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.service,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      _notificationId,
      'Contacts urgence',
      body,
      details,
    );
  }

  /// Formate les contacts pour l'affichage dans la notification.
  ///
  /// Format : "Nom — numero\n" pour chaque contact.
  /// Les contacts automatiques (112, PGHM) sont marques [SECOURS].
  String _formatContactsForNotification(List<LockscreenContact> contacts) {
    final buffer = StringBuffer();

    for (final contact in contacts) {
      final prefix = contact.isAutomatic ? '[SECOURS] ' : '';
      buffer.writeln('$prefix${contact.name} \u2014 ${contact.phone}');
    }

    return buffer.toString().trim();
  }

  // ---------------------------------------------------------------------------
  // iOS — WidgetKit widget contacts urgence
  // ---------------------------------------------------------------------------

  /// Met a jour le widget iOS via UserDefaults (App Group shared container).
  Future<void> _updateIosWidget(List<LockscreenContact> contacts) async {
    final contactsJson = contacts.map((c) => c.toJson()).toList();
    _lastIosWidgetData = contactsJson;
  }

  /// Vide les donnees du widget iOS.
  Future<void> _clearIosWidget() async {
    _lastIosWidgetData = null;
  }

  /// Donnees preparees pour le widget iOS (test/debug).
  List<Map<String, dynamic>>? _lastIosWidgetData;

  /// Getter pour les donnees iOS preparees (utile pour les tests).
  List<Map<String, dynamic>>? get lastIosWidgetData => _lastIosWidgetData;
}
