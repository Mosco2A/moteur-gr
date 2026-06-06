// E5.14b — Service widget lockscreen contacts urgence.
// E5.20a — Enrichi avec donnees sante, GPS, etape en cours.
//
// Expose les contacts d'urgence sur l'ecran de verrouillage :
// - Android : notification foreground persistante avec contacts
// - iOS : WidgetKit widget contacts urgence
//
// E5.20a : ajoute au widget lockscreen :
// - Donnees sante (health_info) : groupe sanguin, allergies, traitements
// - Position GPS (latitude, longitude)
// - Etape en cours (stageName, stageIndex)
//
// Utilise EmergencyContactsService (E5.14a) comme source de donnees.

import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../domain/models/emergency_contact.dart';
import '../domain/models/health_info.dart';
import 'emergency_contacts_service.dart';

/// Donnees de secours pour le widget lockscreen (E5.20a).
///
/// Regroupe les informations essentielles a afficher sur
/// l'ecran de verrouillage pour les secours :
/// contacts urgence + sante + position GPS + etape.
class LockscreenSecurityData {
  const LockscreenSecurityData({
    this.healthInfo,
    this.latitude,
    this.longitude,
    this.stageName,
    this.stageIndex,
  });

  /// Donnees sante du randonneur (E5.16 HealthInfo).
  final HealthInfo? healthInfo;

  /// Position GPS actuelle — latitude.
  final double? latitude;

  /// Position GPS actuelle — longitude.
  final double? longitude;

  /// Nom de l'etape en cours.
  final String? stageName;

  /// Index de l'etape en cours (1..totalStages du sentier actif).
  final int? stageIndex;

  /// Verifie si les donnees sante sont presentes.
  bool get hasHealthInfo => healthInfo != null && healthInfo!.hasData;

  /// Verifie si la position GPS est disponible.
  bool get hasGpsPosition => latitude != null && longitude != null;
}

/// Service de widget lockscreen pour contacts d'urgence.
///
/// Cree une notification persistante (Android) ou met a jour
/// le WidgetKit (iOS) avec la liste des contacts urgence.
/// E5.20a : enrichi avec donnees sante + GPS + etape.
class LockscreenWidgetService {
  LockscreenWidgetService({
    required this.contactsService,
    required this.trailName,
    FlutterLocalNotificationsPlugin? notificationsPlugin,
  }) : _notificationsPlugin =
            notificationsPlugin ?? FlutterLocalNotificationsPlugin();

  final EmergencyContactsService contactsService;

  /// Nom du sentier actif (injecte depuis TrailConfig) —
  /// utilise dans le titre de la notification secours.
  final String trailName;
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  static const int _notificationId = 9001;
  static const String _channelId = 'emergency_lockscreen';
  bool _isActive = false;
  bool get isActive => _isActive;

  /// Donnees de secours actuelles (E5.20a).
  LockscreenSecurityData _securityData = const LockscreenSecurityData();
  LockscreenSecurityData get securityData => _securityData;

  /// Titre de la notification secours — base sur le sentier actif.
  String get notificationTitle => 'Secours $trailName';

  /// Compose le corps complet de la notification :
  /// contacts + sante + GPS + etape. Utilise par la notification
  /// Android et expose pour les tests.
  String buildNotificationContent(List<EmergencyContact> contacts) {
    final body = _formatContactsForNotification(contacts);
    return _enrichWithSecurityData(body);
  }

  /// E5.20a : met a jour les donnees de secours.
  Future<void> updateSecurityData({
    HealthInfo? healthInfo,
    double? latitude,
    double? longitude,
    String? stageName,
    int? stageIndex,
  }) async {
    _securityData = LockscreenSecurityData(
      healthInfo: healthInfo,
      latitude: latitude,
      longitude: longitude,
      stageName: stageName,
      stageIndex: stageIndex,
    );
    if (_isActive) { await refresh(); }
  }

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

  Future<void> deactivate() async {
    if (Platform.isAndroid) {
      await _notificationsPlugin.cancel(_notificationId);
    } else if (Platform.isIOS) {
      await _clearIosWidget();
    }
    _isActive = false;
  }

  Future<void> refresh() async {
    if (!_isActive) return;
    await activate();
  }

  /// Cree la notification persistante Android.
  /// E5.20a : inclut donnees sante + GPS + etape.
  Future<void> _showAndroidNotification(
    List<EmergencyContact> contacts,
  ) async {
    final enrichedBody = buildNotificationContent(contacts);

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      'Contacts urgence',
      channelDescription: 'Contacts urgence lockscreen',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.service,
      styleInformation: BigTextStyleInformation(
        enrichedBody,
        contentTitle: notificationTitle,
        summaryText: 'Contacts + info sante',
      ),
    );

    final details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      _notificationId, notificationTitle, enrichedBody, details,
    );
  }

  String _formatContactsForNotification(List<EmergencyContact> contacts) {
    final buffer = StringBuffer();
    for (final contact in contacts) {
      final prefix = contact.isAutomatic ? '[SECOURS] ' : '';
      buffer.writeln('$prefix${contact.name} \u2014 ${contact.phone}');
    }
    return buffer.toString().trim();
  }

  /// E5.20a : enrichit le corps avec les donnees secours.
  String _enrichWithSecurityData(String contactsBody) {
    final buffer = StringBuffer(contactsBody);

    if (_securityData.hasHealthInfo) {
      final health = _securityData.healthInfo!;
      buffer.writeln();
      buffer.writeln('\u2014\u2014 SANTE \u2014\u2014');
      if (health.bloodType.isNotEmpty) {
        buffer.writeln('Sang: ${health.bloodType}');
      }
      if (health.allergies.isNotEmpty) {
        buffer.writeln('Allergies: ${health.allergies}');
      }
      if (health.treatments.isNotEmpty) {
        buffer.writeln('Traitements: ${health.treatments}');
      }
    }

    if (_securityData.hasGpsPosition) {
      buffer.writeln();
      buffer.writeln('GPS: ${_securityData.latitude!.toStringAsFixed(5)}, ${_securityData.longitude!.toStringAsFixed(5)}');
    }

    if (_securityData.stageName != null) {
      final stageStr = _securityData.stageIndex != null
          ? 'Etape ${_securityData.stageIndex}: ${_securityData.stageName}'
          : 'Etape: ${_securityData.stageName}';
      buffer.writeln(stageStr);
    }

    return buffer.toString().trim();
  }

  /// Construit le payload secours du widget iOS.
  /// E5.20a : contacts + sante + GPS + etape. Expose pour les tests.
  Map<String, dynamic> buildIosSecurityPayload(
    List<EmergencyContact> contacts,
  ) {
    final contactsJson = contacts.map((c) => c.toJson()).toList();
    final securityPayload = <String, dynamic>{
      'contacts': contactsJson,
    };
    if (_securityData.hasHealthInfo) {
      securityPayload['health_info'] = _securityData.healthInfo!.toJson();
    }
    if (_securityData.hasGpsPosition) {
      securityPayload['gps'] = {
        'latitude': _securityData.latitude,
        'longitude': _securityData.longitude,
      };
    }
    if (_securityData.stageName != null) {
      securityPayload['stage'] = {
        'name': _securityData.stageName,
        'index': _securityData.stageIndex,
      };
    }
    return securityPayload;
  }

  /// Met a jour le widget iOS via UserDefaults.
  /// E5.20a : inclut les donnees de secours.
  Future<void> _updateIosWidget(List<EmergencyContact> contacts) async {
    _lastIosWidgetData = [buildIosSecurityPayload(contacts)];
  }

  Future<void> _clearIosWidget() async {
    _lastIosWidgetData = null;
  }

  List<Map<String, dynamic>>? _lastIosWidgetData;
  List<Map<String, dynamic>>? get lastIosWidgetData => _lastIosWidgetData;
}
