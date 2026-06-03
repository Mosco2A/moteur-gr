// E5.14b — Service widget lockscreen contacts urgence.
//
// Expose les contacts d'urgence sur l'ecran de verrouillage :
// - Android : notification foreground persistante avec contacts
// - iOS : WidgetKit widget contacts urgence
//
// Utilise EmergencyContactsService (E5.14a) comme source de donnees.

import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../domain/models/emergency_contact.dart';
import 'emergency_contacts_service.dart';

/// Service de widget lockscreen pour contacts d'urgence.
///
/// Cree une notification persistante (Android) ou met a jour
/// le WidgetKit (iOS) avec la liste des contacts urgence.
class LockscreenWidgetService {
  LockscreenWidgetService({
    required this.contactsService,
    FlutterLocalNotificationsPlugin? notificationsPlugin,
  }) : _notificationsPlugin =
            notificationsPlugin ?? FlutterLocalNotificationsPlugin();

  /// Source de donnees : contacts d'urgence (E5.14a).
  final EmergencyContactsService contactsService;

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
  Future<void> activate() async {
    final contacts = contactsService.getContacts();
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
  Future<void> refresh() async {
    if (!_isActive) return;
    await activate();
  }

  // ---------------------------------------------------------------------------
  // Android — Notification foreground persistante
  // ---------------------------------------------------------------------------

  /// Cree la notification persistante Android avec la liste des contacts.
  ///
  /// La notification est ongoing (non-dismissable) et affiche
  /// les contacts sous forme de BigTextStyle avec numeros appelables.
  Future<void> _showAndroidNotification(
    List<EmergencyContact> contacts,
  ) async {
    // Construire le corps de la notification avec les contacts
    final body = _formatContactsForNotification(contacts);

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      'Contacts urgence',
      channelDescription:
          'Affiche les contacts d\'urgence sur l\'ecran de verrouillage',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true, // Non-dismissable
      autoCancel: false,
      showWhen: false,
      visibility: NotificationVisibility.public, // Visible sur lockscreen
      category: AndroidNotificationCategory.service,
      // Style BigText pour afficher tous les contacts
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: 'Contacts urgence GR20',
        summaryText: 'Appuyez pour appeler',
      ),
    );

    final details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      _notificationId,
      'Contacts urgence GR20',
      body,
      details,
    );
  }

  /// Formate les contacts pour l'affichage dans la notification.
  ///
  /// Format : "Nom — numero\n" pour chaque contact.
  /// Les contacts automatiques (112, PGHM) sont marques [SECOURS].
  String _formatContactsForNotification(List<EmergencyContact> contacts) {
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
  ///
  /// Les donnees sont ecrites dans le shared UserDefaults avec la cle
  /// 'emergency_contacts' au format JSON. Le widget WidgetKit lit ces
  /// donnees et affiche les contacts sur le lockscreen.
  ///
  /// Note : l'implementation native (Swift) du widget WidgetKit est dans
  /// ios/EmergencyWidget/. Ce code Dart ne fait que pousser les donnees
  /// via le MethodChannel 'lockscreen_widget'.
  Future<void> _updateIosWidget(List<EmergencyContact> contacts) async {
    // Serialiser les contacts pour le widget natif iOS
    final contactsJson = contacts.map((c) => c.toJson()).toList();

    // Le MethodChannel sera configure dans le code natif iOS.
    // Pour l'instant, les donnees sont preparees mais l'appel natif
    // necessite un setup Swift/WidgetKit cote Xcode.
    // Placeholder — sera connecte lors de l'integration native.
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
