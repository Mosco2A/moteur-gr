import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// GARDE STRUCTURELLE — LES CLES D USAGE iOS SONT COMPLETES (tache 740).
///
/// POURQUOI CETTE GARDE EXISTE. Le 08/10/2026, Apple a REFUSE la livraison
/// 0.1.7 build 9 de StepWays (App Apple ID 6817011266) avec l erreur
/// ITMS-90683 « Missing purpose string in Info.plist » : le Info.plist de
/// Runner.app devait porter NSHealthUpdateUsageDescription, et ne le portait
/// pas. Rien, dans le depot, ne pouvait le voir venir : la cle manquait depuis
/// le jour ou `health` est entre au pubspec, et c est le televersement chez
/// Apple — apres la compilation, la signature et l envoi — qui l a dit.
///
/// CE QUE LE CONTROLE D APPLE REGARDE, ET QUI SURPREND. Il ne regarde pas ce
/// que l application FAIT : il regarde les API que le BINAIRE REFERENCE. Un
/// greffon qui nomme une API gardee oblige a poser sa cle, meme si aucune
/// ligne de `lib/` ne l appelle jamais. Trois cles de ce depot sont dans ce
/// cas, et Info.plist le dit en toutes lettres : l ecriture Sante, la
/// bibliotheque musicale et Face ID.
///
/// COMMENT LE TABLEAU SE TIENT A JOUR. Chaque entree est une MESURE faite
/// dans le code du greffon, pas une lecture de sa documentation : on y nomme
/// le fichier et la ligne qui referencent l API. Quand une dependance entre
/// au pubspec ou en sort, le tableau bouge DANS LE MEME COMMIT — le test
/// « toute dependance du tableau est encore declaree » le refuse autrement.
///
/// CE QUE CETTE GARDE NE FAIT PAS. Elle ne verifie pas les traductions : les
/// cinq langues de chaque cle sont tenues par
/// test/structurel/fiche_magasin_et_apple_test.dart, qui lit les cles dans
/// Info.plist et exige chacune dans les cinq InfoPlist.strings.

/// TABLEAU DEPENDANCE -> CLES D USAGE EXIGEES PAR iOS.
///
/// Une dependance declaree dans `dependencies:` du pubspec exige TOUTES les
/// cles de sa liste. Les references sont celles des versions resolues au
/// 08/10/2026 (pubspec.lock) ; une montee de version se verifie a nouveau.
const clesExigees = <String, List<String>>{
  // `health` 13.3.1 — ios/Classes/HealthDataOperations.swift ligne 180 :
  // `healthStore.requestAuthorization(toShare: typesToWrite, read:)`, SANS
  // condition de compilation. L API d ECRITURE est donc referencee par le
  // binaire alors que l application ne fait que LIRE
  // (lib/core/services/health_reader_service.dart, `readTypes` seul).
  // C EST CETTE LIGNE QUI A FAIT REJETER LE BUILD 9 (ITMS-90683).
  'health': ['NSHealthShareUsageDescription', 'NSHealthUpdateUsageDescription'],
  // `pedometer` 4.2.0 — CMPedometer, qui vit derriere CoreMotion.
  'pedometer': ['NSMotionUsageDescription'],
  // `sensors_plus` 6.1.2 — CMMotionManager, meme famille CoreMotion.
  'sensors_plus': ['NSMotionUsageDescription'],
  // `geolocator` 11.x (geolocator_apple 2.3.13) — CLLocationManager. La
  // seconde cle est exigee par le suivi ecran eteint, declare aussi par
  // UIBackgroundModes = location.
  'geolocator': [
    'NSLocationWhenInUseUsageDescription',
    'NSLocationAlwaysAndWhenInUseUsageDescription',
  ],
  // `image_picker` 1.x (image_picker_ios 0.8.13+6) — UIImagePickerController
  // pour la galerie, AVCaptureDevice pour l appareil photo. Le micro n est
  // PAS reference : l application ne prend pas de video.
  'image_picker': [
    'NSCameraUsageDescription',
    'NSPhotoLibraryUsageDescription',
  ],
  // `flutter_blue_plus` 1.x (flutter_blue_plus_darwin 7.0.3) —
  // CBCentralManager. La ceinture cardiaque passe par la.
  'flutter_blue_plus': ['NSBluetoothAlwaysUsageDescription'],
  // `google_mobile_ads` 9.1.0 — ATTrackingManager. Sans cette cle, la
  // demande de suivi est impossible et la revue refuse le binaire.
  'google_mobile_ads': ['NSUserTrackingUsageDescription'],
  // `file_picker` 8.3.7 — MediaPlayer/MediaPlayer.h est importe dans son
  // EN-TETE PUBLIC (include/file_picker/FilePickerPlugin.h ligne 3) et un
  // MPMediaPickerController est instancie (FilePickerPlugin.m ligne 369),
  // sans condition. L APPLICATION N OUVRE JAMAIS CE SELECTEUR : son seul
  // appel est `FileType.custom` pour une trace .gpx
  // (lib/features/after/presentation/gpx_import_screen.dart ligne 517).
  // La cle est posee pour l API referencee, pas pour un usage.
  'file_picker': [
    'NSAppleMusicUsageDescription',
    'NSPhotoLibraryUsageDescription',
  ],
  // `flutter_secure_storage` 10.x (flutter_secure_storage_darwin 0.3.2) —
  // `import LocalAuthentication` et `LAContext()`
  // (FlutterSecureStorageDarwinPlugin.swift ligne 197). Ce chemin ne
  // s execute que si l appelant demande `useSecureEnclave` ou un
  // `accessControlFlags` biometrique, et le depot ne passe NI l un NI
  // l autre : Face ID n est jamais demande. Cle posee, meme raison.
  'flutter_secure_storage': ['NSFaceIDUsageDescription'],
};

/// PERMISSION ALLUMEE DANS LE PODFILE -> CLE QUE CELA RENDRAIT OBLIGATOIRE.
///
/// `permission_handler_apple` compile ses strategies derriere `#if
/// PERMISSION_X`. En C, une macro NON DEFINIE vaut 0 dans un `#if` : sans
/// `GCC_PREPROCESSOR_DEFINITIONS` dans ios/Podfile, CHAQUE strategie tombe
/// dans sa branche `#else` et se reduit a UnknownPermissionStrategy — aucun
/// framework sensible n est importe, aucune cle n est exigee. C est l etat du
/// depot au 08/10/2026, et c est pourquoi Apple n a rien reproche d autre que
/// Sante au build 9.
///
/// Le jour ou une permission sera allumee, elle importera son framework et
/// Apple exigera la cle. Ce tableau fait rougir ce test AVANT le rejet.
/// PERMISSION_NOTIFICATIONS et PERMISSION_CRITICAL_ALERTS n y figurent pas :
/// UserNotifications ne demande aucun texte d usage.
const clesDesPermissions = <String, String>{
  'PERMISSION_EVENTS': 'NSCalendarsUsageDescription',
  'PERMISSION_EVENTS_FULL_ACCESS': 'NSCalendarsFullAccessUsageDescription',
  'PERMISSION_REMINDERS': 'NSRemindersUsageDescription',
  'PERMISSION_CONTACTS': 'NSContactsUsageDescription',
  'PERMISSION_CAMERA': 'NSCameraUsageDescription',
  'PERMISSION_MICROPHONE': 'NSMicrophoneUsageDescription',
  'PERMISSION_SPEECH_RECOGNIZER': 'NSSpeechRecognitionUsageDescription',
  'PERMISSION_PHOTOS': 'NSPhotoLibraryUsageDescription',
  'PERMISSION_PHOTOS_ADD_ONLY': 'NSPhotoLibraryAddUsageDescription',
  'PERMISSION_LOCATION': 'NSLocationWhenInUseUsageDescription',
  'PERMISSION_LOCATION_WHENINUSE': 'NSLocationWhenInUseUsageDescription',
  'PERMISSION_LOCATION_ALWAYS': 'NSLocationAlwaysAndWhenInUseUsageDescription',
  'PERMISSION_MEDIA_LIBRARY': 'NSAppleMusicUsageDescription',
  'PERMISSION_SENSORS': 'NSMotionUsageDescription',
  'PERMISSION_BLUETOOTH': 'NSBluetoothAlwaysUsageDescription',
  'PERMISSION_APP_TRACKING_TRANSPARENCY': 'NSUserTrackingUsageDescription',
  'PERMISSION_ASSISTANT': 'NSSiriUsageDescription',
};

void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final plist = File('ios/Runner/Info.plist').readAsStringSync();

  // Le bloc `dependencies:` SEUL : une dependance de TEST ne part pas dans
  // le paquet iPhone et n exige donc aucune cle.
  final debut = pubspec.indexOf(RegExp(r'^dependencies:', multiLine: true));
  final fin = pubspec.indexOf(RegExp(r'^dev_dependencies:', multiLine: true));
  final blocDependances = pubspec.substring(debut, fin);

  bool declaree(String nom) =>
      RegExp('^  $nom:', multiLine: true).hasMatch(blocDependances);

  String? texteDe(String cle) => RegExp(
    '<key>$cle</key>\\s*<string>(.*?)</string>',
    dotAll: true,
  ).firstMatch(plist)?.group(1)?.trim();

  group('les cles d usage iOS sont completes (740)', () {
    for (final entree in clesExigees.entries) {
      test('${entree.key} : ses cles d usage sont posees et remplies', () {
        if (!declaree(entree.key)) {
          markTestSkipped('${entree.key} n est plus au pubspec');
          return;
        }
        for (final cle in entree.value) {
          expect(
            texteDe(cle),
            isNotNull,
            reason:
                'ios/Runner/Info.plist : $cle manque, et ${entree.key} '
                'reference l API qu elle garde. C est exactement ce que '
                'Apple refuse avec ITMS-90683.',
          );
          expect(
            texteDe(cle),
            isNotEmpty,
            reason: 'ios/Runner/Info.plist : $cle est vide',
          );
        }
      });
    }

    test('la cle d ecriture Sante est posee — c est elle qui a fait '
        'rejeter le build 9', () {
      expect(
        texteDe('NSHealthUpdateUsageDescription'),
        isNotNull,
        reason:
            'ITMS-90683 sur la livraison 0.1.7 build 9 : `health` 13.3.1 '
            'appelle requestAuthorization(toShare:) sans condition, donc '
            'la cle est exigee meme si l application ne fait que lire.',
      );
    });

    test('aucune cle d usage ne traine dans le plist sans raison inscrite '
        'au tableau', () {
      final posees = RegExp(
        r'<key>(NS[A-Za-z]+UsageDescription)</key>',
      ).allMatches(plist).map((m) => m.group(1)!).toSet();
      final justifiees = clesExigees.values.expand((l) => l).toSet();
      expect(
        posees.difference(justifiees),
        isEmpty,
        reason:
            'une cle d usage sans dependance qui l exige est soit un '
            'copier-coller, soit une dependance oubliee au tableau : dans '
            'les deux cas il faut trancher, pas laisser.',
      );
    });

    test('aucun entitlement HealthKit n est declare', () {
      final droits = File('ios/Runner/Runner.entitlements').readAsStringSync();
      expect(
        droits.contains('healthkit'),
        isFalse,
        reason:
            'lire et ecrire dans Sante passent par la cle d usage, pas par '
            'un droit signe. Un entitlement HealthKit ajoute ici exigerait '
            'la capacite correspondante sur le profil, et la signature '
            'tomberait.',
      );
    });

    test('toute dependance du tableau est encore declaree au pubspec', () {
      final disparues = clesExigees.keys.where((d) => !declaree(d)).toList();
      expect(
        disparues,
        isEmpty,
        reason:
            'ce tableau decrit des dependances qui ne sont plus la : le '
            'nettoyer dans le commit qui les retire, sinon il raconte un '
            'depot qui n existe plus.',
      );
    });

    test('chaque permission allumee dans le Podfile a sa cle d usage', () {
      final podfile = File('ios/Podfile').readAsStringSync();
      final manquantes = <String>[];
      for (final entree in clesDesPermissions.entries) {
        final allumee = RegExp('${entree.key}\\s*=\\s*1').hasMatch(podfile);
        if (allumee && texteDe(entree.value) == null) {
          manquantes.add('${entree.key} -> ${entree.value}');
        }
      }
      expect(
        manquantes,
        isEmpty,
        reason:
            'allumer une permission dans le Podfile fait importer son '
            'framework par permission_handler_apple : la cle devient '
            'obligatoire et Apple rejette le paquet sans elle.',
      );
    });
  });
}
