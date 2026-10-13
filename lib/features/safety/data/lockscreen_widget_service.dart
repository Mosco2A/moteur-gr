/// Ce que les secours doivent pouvoir lire SANS deverrouiller le telephone :
/// contacts, sante, position et etape reunis.
library;

// E5.14b — Service widget lockscreen contacts urgence.
// E5.20a — Enrichi avec donnees sante, GPS, etape en cours.
// TACHE 630 — LA FICHE ENTIERE, ET LA MESURE DE CE QU'ON PEUT REELLEMENT
//             MONTRER SANS DEVERROUILLAGE.
//
// ===========================================================================
// CE QU'UN SECOURISTE VOIT REELLEMENT, SYSTEME PAR SYSTEME — MESURE LE 29/09
// SUR LA DOCUMENTATION OFFICIELLE, PAS DE MEMOIRE
// ===========================================================================
//
// La question posee par Christophe est la seule qui compte : « ou la trouver
// quand tu es a terre !!! serieux ». Une fiche qu'il faut deverrouiller pour
// lire ne sert a rien, parce que le seul moment ou elle compte est celui ou le
// randonneur ne peut plus ouvrir son telephone.
//
// --- ANDROID : L'APPLICATION PEUT, ET C'EST CE FICHIER QUI LE FAIT ---
//
//  [a] NOTIFICATION PERSISTANTE — CE QUI EST LIVRE. Avec
//      `VISIBILITY_PUBLIC`, « the notification's full content shows on the lock
//      screen » (documentation Android, « Create a notification »). C'est un
//      chemin REEL, disponible sur le telephone de Christophe aujourd'hui, sans
//      code et sans geste : la fiche s'y lit en clair. Limite : du TEXTE.
//
//  [b] WIDGET D'ECRAN VERROUILLE — INDISPONIBLE SUR TELEPHONE. Google, « Widgets
//      on lock screen: FAQ » (mars 2025) : « Lock screen widgets are already
//      available on Pixel Tablets » et « Lock screen widgets will be available in
//      AOSP for tablets and mobile starting with the release AFTER Android 16
//      (QPR1) ». Donc : tablette Pixel seulement a la date de cette mesure. Ce
//      n'est pas un chemin sur lequel on peut faire reposer un secours.
//      <https://android-developers.googleblog.com/2025/03/widgets-on-lock-screen-faq.html>
//
//  [c] ACTIVITE AFFICHEE PAR-DESSUS LE VERROU — POSSIBLE, PAS BRANCHEE, ET JE
//      DIS POURQUOI. `android:showWhenLocked="true"` « makes your app accessible
//      from the device lock screen » (documentation Android), et la FAQ ci-dessus
//      le confirme pour ce qui est lance depuis l'ecran verrouille : « users must
//      authenticate to launch the activity, OR the activity should declare
//      android:showWhenLocked="true" ». Une activite native dediee, portant la
//      fiche ET LES DEUX PHOTOS DE CARTE, serait donc le seul chemin qui montre
//      les images sans deverrouillage. ELLE N'EST PAS FAITE ICI pour une raison
//      technique nette : `flutter_local_notifications` ne laisse pas choisir
//      l'activite ouverte au toucher de la notification — elle ouvre l'activite
//      de lancement de l'application. Poser `showWhenLocked` sur `MainActivity`
//      rendrait TOUTE l'application atteignable sans code, ce qui est une fuite
//      bien pire que celle qu'on evite. Il faut une activite Kotlin dediee et un
//      chemin de notification natif : c'est un lot a soi, il est chiffre, il
//      n'est pas bricole ici. POINT OUVERT NOMME.
//
// --- IPHONE : L'APPLICATION NE PEUT PAS. C'EST LA FICHE DU SYSTEME OU RIEN ---
//
//  Apple, « Configuration de votre fiche medicale » : « La fiche medicale donne
//  aux premiers intervenants un acces a vos informations medicales essentielles
//  a partir de l'ecran verrouille », et « They can see information like allergies
//  and medical conditions as well as who to contact in case of an emergency ».
//  <https://support.apple.com/fr-fr/105072>
//
//  AUCUNE API N'EXISTE POUR Y ECRIRE DEPUIS UNE APPLICATION TIERCE. Les widgets
//  d'ecran verrouille iOS 16+ (familles `accessory*`) affichent quelques lignes
//  de texte, sont soumis au reglage « Autoriser l'acces en mode verrouille » de
//  Face ID et code, et ne peuvent pas ouvrir l'application sans deverrouillage.
//  Ils ne peuvent pas porter une fiche, encore moins deux photos de carte.
//
//  CONSEQUENCE, ET C'EST ELLE QUI SAUVE SUR IPHONE : le vrai chemin est celui que
//  l'application conseille deja (`health.advice.phoneCard`) — recopier la fiche
//  dans celle du telephone. La tache 630 le sort donc de l'etat de conseil : il
//  devient une ETAPE de preparation (`HealthPrepStep.phoneCardCopied`), rappelee
//  tant qu'elle n'est pas faite.
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

  /// COMPOSE LE CORPS COMPLET DE LA NOTIFICATION — LA FICHE ENTIERE, PLUS TROIS
  /// CHAMPS SUR CINQ (tache 630).
  ///
  /// CE QUE CETTE METHODE FAISAIT, ET C'ETAIT LE DEFAUT MESURE : elle recopiait
  /// SANG, ALLERGIES et TRAITEMENTS. Le medecin traitant et l'assurance
  /// n'y etaient pas — et l'identite, les contacts a prevenir et les antecedents
  /// n'existaient meme pas dans le modele. Un secouriste lisait donc, sur le seul
  /// ecran qu'il peut atteindre sans code, une fiche amputee.
  ///
  /// L'ORDRE EST CELUI DE `HealthInfo` : identite, qui prevenir, vital,
  /// administratif — puis la position et l'etape, qui sont le contexte du
  /// secours et non la fiche. Il n'y a PAS deux ordres dans l'application : celui
  /// de l'ecran et celui-ci sont le meme, et un test le verrouille.
  ///
  /// CE QUI N'Y ENTRE PAS, ET C'EST UNE LIMITE DU SUPPORT, PAS UN CHOIX : LES
  /// DEUX PHOTOS DE CARTE. Une notification Android n'affiche qu'UNE image
  /// (`BigPictureStyle`), et seulement depliee. Deux cartes n'y tiennent pas.
  /// Elles restent atteignables sur l'ecran de la fiche. Mesure ecrite ici pour
  /// que personne ne croie plus tard a un oubli.
  String buildNotificationContent(List<EmergencyContact> contacts) {
    final buffer = StringBuffer();
    _ecrireIdentite(buffer);
    final corpsContacts = _formatContactsForNotification(contacts);
    if (corpsContacts.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.writeln(corpsContacts);
    }
    return _enrichWithSecurityData(buffer.toString().trim());
  }

  /// QUI EST LE PATIENT — LA PREMIERE CHOSE QUE LIT UN SECOURISTE.
  ///
  /// Placee AVANT les numeros a appeler, parce qu'un secouriste qui compose le
  /// numero d'un proche doit pouvoir dire de QUI il parle des la premiere
  /// seconde.
  void _ecrireIdentite(StringBuffer buffer) {
    final health = _securityData.healthInfo;
    if (health == null) return;
    final lignes = <String>[
      if (health.fullName.isNotEmpty) health.fullName,
      if (health.birthDate.isNotEmpty) 'Ne(e) le ${health.birthDate}',
      if (health.address.isNotEmpty) health.address,
    ];
    if (lignes.isEmpty) return;
    for (final ligne in lignes) {
      buffer.writeln(ligne);
    }
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
    if (_isActive) {
      await refresh();
    }
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

  /// CREE LA NOTIFICATION PERSISTANTE ANDROID — LE SEUL CHEMIN MESURE PAR
  /// LEQUEL CETTE APPLICATION MONTRE QUELQUE CHOSE SANS DEVERROUILLAGE.
  ///
  /// E5.20a : inclut donnees sante + GPS + etape. Tache 630 : la fiche ENTIERE.
  ///
  /// `visibility: NotificationVisibility.public` N'EST PAS DECORATIF, ET C'EST LA
  /// LIGNE LA PLUS IMPORTANTE DE CE FICHIER. Documentation Android, « Create a
  /// notification », mot pour mot :
  ///   * `VISIBILITY_PUBLIC` : « the notification's full content shows on the
  ///     lock screen » ;
  ///   * `VISIBILITY_PRIVATE`, QUI EST LE DEFAUT : « only basic information, such
  ///     as the notification's icon and the content title, shows on the lock
  ///     screen. The notification's full content doesn't show » ;
  ///   * le troisieme niveau, le plus ferme : « no part of the notification shows
  ///     on the lock screen ».
  ///   <https://developer.android.com/develop/ui/views/notifications/build-notification>
  ///
  /// Sans elle, un secouriste verrait le titre « Secours <sentier> » et RIEN
  /// d'autre. C'est le contraire exact de ce que Christophe a demande le 29/09 :
  /// « ou la trouver quand tu es a terre !!! serieux ».
  ///
  /// LA MEME PAGE POSE LA LIMITE, ET ELLE NE NOUS APPARTIENT PAS : « the user
  /// always has ultimate control over whether their notifications are visible on
  /// the lock screen ». Un randonneur qui masque les notifications sensibles sur
  /// son ecran verrouille masque celle-ci. C'est pour cela que la recopie dans la
  /// fiche du telephone reste une ETAPE, et pas un conseil.
  Future<void> _showAndroidNotification(List<EmergencyContact> contacts) async {
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
      _notificationId,
      notificationTitle,
      enrichedBody,
      details,
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
      // L'ORDRE EST CELUI DE `HealthInfo` : allergies (ce qui tue au moment du
      // soin), traitements, antecedents, groupe sanguin, don d'organes \u2014 puis
      // l'administratif. Voir la source de l'ordre dans `health_info.dart`.
      final vital = <String>[
        if (health.allergies.isNotEmpty) 'Allergies: ${health.allergies}',
        if (health.treatments.isNotEmpty) 'Traitements: ${health.treatments}',
        if (health.conditions.isNotEmpty) 'Antecedents: ${health.conditions}',
        if (health.bloodType.isNotEmpty) 'Sang: ${health.bloodType}',
        if (health.organDonor.isNotEmpty)
          'Don d\'organes: ${health.organDonor}',
        if (health.doctorContact.isNotEmpty) 'Medecin: ${health.doctorContact}',
        if (health.insuranceNumber.isNotEmpty)
          'Assurance: ${health.insuranceNumber}',
      ];
      if (vital.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('\u2014\u2014 SANTE \u2014\u2014');
        for (final ligne in vital) {
          buffer.writeln(ligne);
        }
      }
    }

    if (_securityData.hasGpsPosition) {
      buffer.writeln();
      buffer.writeln(
        'GPS: ${_securityData.latitude!.toStringAsFixed(5)}, ${_securityData.longitude!.toStringAsFixed(5)}',
      );
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
    final securityPayload = <String, dynamic>{'contacts': contactsJson};
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

  /// COMPOSE LE PAQUET DU WIDGET iOS — ET NE L'ECRIT NULLE PART (mesure de la
  /// tache 615).
  ///
  /// CETTE PHRASE DISAIT « Met a jour le widget iOS via UserDefaults », ET C'ETAIT
  /// FAUX DANS LES DEUX SENS. Rien n'est ecrit dans `UserDefaults` : le paquet
  /// reste dans [_lastIosWidgetData], en MEMOIRE, et disparait avec le processus.
  /// Le widget `ios/TrekWidget/TrekWidget.swift`, lui, ne lit que la progression
  /// du trek — il ne cherche AUCUN champ de sante. Le widget de secours iOS n'est
  /// donc pas branche, et c'est un point ouvert du lot E5.20a, pas de celui-ci.
  ///
  /// POURQUOI CETTE CORRECTION APPARTIENT A LA TACHE 615. Ce lot devait confirmer
  /// que la fiche medicale n'a QU'UN SEUL porteur durable. Un commentaire annoncant
  /// une ecriture dans `UserDefaults` en designait un second — et `UserDefaults`
  /// EST emporte par la sauvegarde iCloud. La verification a montre qu'il n'y a
  /// rien : la phrase mentait, pas le code. Le jour ou quelqu'un branchera
  /// vraiment ce widget, il devra decider ce qu'il fait de la donnee de sante, et
  /// c'est pour cela que la question est ecrite ici plutot qu'effacee.
  Future<void> _updateIosWidget(List<EmergencyContact> contacts) async {
    _lastIosWidgetData = [buildIosSecurityPayload(contacts)];
  }

  Future<void> _clearIosWidget() async {
    _lastIosWidgetData = null;
  }

  List<Map<String, dynamic>>? _lastIosWidgetData;
  List<Map<String, dynamic>>? get lastIosWidgetData => _lastIosWidgetData;
}
