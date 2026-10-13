import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'les_cles_d_usage_ios_sont_completes_740_test.dart'
    show clesDesPermissions;

/// GARDE STRUCTURELLE — LES PERMISSIONS iOS SONT ALLUMEES (tache 741).
///
/// POURQUOI CETTE GARDE EXISTE. Jusqu au 08/10/2026, aucune demande
/// d autorisation ne pouvait s afficher sur iPhone, et la position est le
/// coeur du produit. Ce n etait pas une panne : c etait un DEFAUT SILENCIEUX,
/// qui se lit comme un refus de l utilisateur. La chaine, mesuree dans la
/// version que le depot compile vraiment — `pubspec.lock` resout
/// `permission_handler_apple` en 9.4.7, sources dans `ios/Classes/` :
///
///   1. `Classes/PermissionHandlerEnums.h` lignes 67-68, 73-74, 87-88 :
///      `#ifndef PERMISSION_LOCATION` / `#define PERMISSION_LOCATION 0`. LE
///      DEFAUT DU GREFFON EST ZERO, pas un.
///   2. Son podspec ne porte AUCUN `GCC_PREPROCESSOR_DEFINITIONS` : il ne
///      s allume pas tout seul. Seul `Package.swift` calcule ces macros, et ce
///      chemin — Swift Package Manager — n est pas actif sous Flutter 3.41.5
///      stable, qui passe par CocoaPods.
///   3. `ios/Podfile` n en definissait aucune.
///   4. Donc `Classes/strategies/LocationPermissionStrategy.h` ligne 9 ouvre
///      `#if PERMISSION_LOCATION || ...`, la condition est fausse, et sa
///      branche `#else` ligne 17 fait heriter la classe de
///      `UnknownPermissionStrategy`, qui renvoie `PermissionStatusDenied`
///      (`UnknownPermissionStrategy.m` ligne 12) et
///      `PermissionStatusPermanentlyDenied` (ligne 20). Aucune fenetre
///      systeme, jamais.
///
/// CE QUE LE DEFAUT N ETAIT PAS, ET IL FAUT LE DIRE. Pas un risque d arret
/// par selecteur inconnu : la branche `#else` declare un HERITAGE, donc
/// `[permissionStrategy checkPermissionStatus:]` (`PermissionManager.m`
/// ligne 23, appele sans `respondsToSelector`) resout bien son selecteur.
///
/// CE QUE CETTE GARDE VERIFIE, ET CE QU ELLE NE PEUT PAS VERIFIER. Elle lit
/// le TEXTE de `ios/Podfile`. Elle ne prouve PAS que ces definitions arrivent
/// dans les reglages du pod : `pod install` et Xcode ne tournent pas sous
/// Windows, et aucune gate de ce depot ne peut ouvrir un projet Pods. Seule
/// une compilation sur Mac — la chaine `ios_testflight` de codemagic.yaml — le
/// dira, et seule une installation sur un iPhone montrera la fenetre
/// s ouvrir. Cette garde empeche la REGRESSION DU TEXTE, qui est le seul
/// endroit ou le defaut peut revenir sans qu on le voie.
///
/// CE QU ELLE NE DOUBLE PAS. Le tableau permission vers cle d usage vit dans
/// `les_cles_d_usage_ios_sont_completes_740_test.dart` et est IMPORTE ici :
/// une seule source, pas deux qui divergent.

/// LES SIX DEFINITIONS QUE `lib/` EXIGE, ET CE QUE CHACUNE DEBLOQUE.
///
/// Les references sont celles de `permission_handler_apple` 9.4.7. La valeur
/// est le `#if` que la macro rend vrai, donc la strategie qui cesse de se
/// replier sur `UnknownPermissionStrategy`.
const permissionsAllumees = <String, String>{
  // 2 appels de `Permission.locationWhenInUse` et 4 de
  // `Permission.locationAlways` dans lib/. Les trois macros ouvrent le MEME
  // `#if` (`LocationPermissionStrategy.h` ligne 9, `.m` ligne 8,
  // `PermissionManager.m` ligne 103), et `PERMISSION_LOCATION` commande en
  // plus deux blocs internes (`.m` lignes 65 et 85).
  'PERMISSION_LOCATION': 'LocationPermissionStrategy.h:9 (+ .m:65 et .m:85)',
  'PERMISSION_LOCATION_WHENINUSE': 'LocationPermissionStrategy.h:9',
  'PERMISSION_LOCATION_ALWAYS': 'LocationPermissionStrategy.h:9',
  // 5 appels de `Permission.notification` dans lib/.
  'PERMISSION_NOTIFICATIONS': 'NotificationPermissionStrategy.h:11 et .m:10',
  // 1 appel de `Permission.sensors`, et c est AUSSI le chemin iPhone de la
  // reconnaissance de mouvement : CoreMotion vit derriere cette macro.
  'PERMISSION_SENSORS': 'SensorPermissionStrategy.h:9 et .m:8',
  // INERTE SUR APPLE, ET C EST MESURE : zero occurrence de
  // `PERMISSION_ACTIVITY_RECOGNITION` dans tout `permission_handler_apple`
  // 9.4.7. Sur iPhone la reconnaissance de mouvement EST la permission des
  // capteurs, et le depot le sait deja —
  // `lib/features/trek/data/background_gps_service.dart` demande
  // `Platform.isIOS ? Permission.sensors : Permission.activityRecognition`.
  // Definie ici parce que le mandat la demande et parce qu une definition que
  // nul `#if` ne lit ne change rien au binaire. Elle n AGIT PAS.
  'PERMISSION_ACTIVITY_RECOGNITION': 'INERTE — aucun #if ne la lit cote Apple',
};

/// TOUTES LES MACROS QUE LE GREFFON CONNAIT, MESUREES EN 9.4.7.
///
/// Dix-sept sont declarees avec un defaut a zero dans
/// `Classes/PermissionHandlerEnums.h` ; deux de plus sont CITEES dans un `#if`
/// sans jamais etre declarees (les deux variantes de position), ce qui marche
/// parce qu en C une macro non definie vaut zero dans un `#if`. Ce tableau
/// sert a refuser une macro inventee : une faute de frappe dans le Podfile ne
/// ferait rien du tout, en silence.
const macrosConnues = <String>{
  'PERMISSION_EVENTS',
  'PERMISSION_EVENTS_FULL_ACCESS',
  'PERMISSION_REMINDERS',
  'PERMISSION_CONTACTS',
  'PERMISSION_CAMERA',
  'PERMISSION_MICROPHONE',
  'PERMISSION_SPEECH_RECOGNIZER',
  'PERMISSION_PHOTOS',
  'PERMISSION_PHOTOS_ADD_ONLY',
  'PERMISSION_LOCATION',
  'PERMISSION_LOCATION_WHENINUSE',
  'PERMISSION_LOCATION_ALWAYS',
  'PERMISSION_NOTIFICATIONS',
  'PERMISSION_MEDIA_LIBRARY',
  'PERMISSION_SENSORS',
  'PERMISSION_BLUETOOTH',
  'PERMISSION_APP_TRACKING_TRANSPARENCY',
  'PERMISSION_CRITICAL_ALERTS',
  'PERMISSION_ASSISTANT',
  // Inerte cote Apple, voir `permissionsAllumees`. Admise pour que le mandat
  // puisse l ecrire sans que cette garde la prenne pour une faute de frappe.
  'PERMISSION_ACTIVITY_RECOGNITION',
};

/// La version sur laquelle tout ce qui precede a ete mesure.
const versionMesuree = '9.4.7';

void main() {
  final podfile = File('ios/Podfile').readAsStringSync();
  final plist = File('ios/Runner/Info.plist').readAsStringSync();

  /// LE CODE SEUL, LES COMMENTAIRES RETIRES. Un commentaire n allume rien :
  /// confondre les deux rendrait cette garde verte sur un Podfile qui
  /// n allume aucune permission, du moment qu il en PARLE.
  final lignesDeCode = podfile
      .split('\n')
      .where((ligne) => !ligne.trimLeft().startsWith('#'))
      .toList();
  final code = lignesDeCode.join('\n');

  final allumeeRegex = RegExp(r'(PERMISSION_[A-Z_]+)\s*=\s*1');

  Set<String> allumeesDans(String texte) =>
      allumeeRegex.allMatches(texte).map((m) => m.group(1)!).toSet();

  String? texteDe(String cle) => RegExp(
    '<key>$cle</key>\\s*<string>(.*?)</string>',
    dotAll: true,
  ).firstMatch(plist)?.group(1)?.trim();

  group('les permissions iOS sont allumees (741)', () {
    for (final entree in permissionsAllumees.entries) {
      test('${entree.key} vaut 1 dans ios/Podfile', () {
        expect(
          allumeesDans(code),
          contains(entree.key),
          reason:
              'ios/Podfile : ${entree.key} n est plus definie a 1 dans le '
              'post_install. Sans elle, le greffon retombe sur sa branche '
              '#else (${entree.value}) et repond refuse SANS ouvrir de '
              'fenetre systeme — le defaut du 08/10/2026 revient, et rien '
              'd autre que cette garde ne peut le voir depuis Windows.',
        );
      });
    }

    test('exactement ces six-la, et aucune septieme', () {
      expect(
        allumeesDans(code),
        equals(permissionsAllumees.keys.toSet()),
        reason:
            'allumer une permission de plus fait importer son framework par '
            'permission_handler_apple : Apple exige alors sa cle d usage et '
            'refuse le paquet sans elle (ITMS-90683, deja vu sur le build 9). '
            'Les treize autres macros du greffon doivent rester ETEINTES, et '
            'elles le restent en n etant pas ecrites : leur defaut vaut zero.',
      );
    });

    test('chaque macro allumee a bien sa cle d usage dans le plist', () {
      final manquantes = <String>[];
      for (final macro in allumeesDans(code)) {
        final cle = clesDesPermissions[macro];
        // Absente du tableau 740 = aucune cle exigee par iOS. C est le cas
        // des notifications (UserNotifications ne demande aucun texte) et de
        // la macro inerte.
        if (cle == null) continue;
        if (texteDe(cle) == null) manquantes.add('$macro -> $cle');
      }
      expect(
        manquantes,
        isEmpty,
        reason:
            'une permission allumee sans sa cle d usage, c est le rejet '
            'd Apple garanti. Le tableau vient de la garde 740, qui reste la '
            'seule source.',
      );
    });

    test('les definitions portent \$(inherited)', () {
      expect(
        code.contains(r'$(inherited)'),
        isTrue,
        reason:
            'un reglage pose au niveau de la cible MASQUE celui du .xcconfig '
            'genere par CocoaPods, qui porte GCC_PREPROCESSOR_DEFINITIONS = '
            r'$(inherited) COCOAPODS=1. Ecrire la liste sans $(inherited) '
            'effacerait COCOAPODS=1 pour cette cible.',
      );
    });

    test('le piege du ||= n est pas revenu', () {
      final avecOperateur = lignesDeCode
          .where((ligne) => ligne.contains('||='))
          .toList();
      expect(
        avecOperateur,
        isEmpty,
        reason:
            'la documentation du greffon propose '
            "build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [...]. En "
            'Ruby, ||= n affecte QUE si la clef est absente : le jour ou '
            'CocoaPods, flutter_additional_ios_build_settings ou le '
            'post_install d un autre greffon pose la clef le premier, nos six '
            'definitions disparaissent EN SILENCE. On lit, on ajoute, on '
            'reaffecte — jamais ||=.',
      );
    });

    test('les definitions sont AJOUTEES a la valeur en place, pas '
        'substituees', () {
      expect(
        code.contains("build_settings['GCC_PREPROCESSOR_DEFINITIONS']"),
        isTrue,
        reason: 'ios/Podfile ne touche plus GCC_PREPROCESSOR_DEFINITIONS',
      );
      expect(
        RegExp(
          r"build_settings\['GCC_PREPROCESSOR_DEFINITIONS'\]\s*=\s*\[\s*'PERMISSION",
        ).hasMatch(code),
        isFalse,
        reason:
            'une affectation qui commence directement par nos macros ecrase '
            'ce que CocoaPods avait pose. La forme attendue lit la valeur en '
            r'place, garantit $(inherited), puis ajoute.',
      );
    });

    test('le cas special google_mobile_ads est intact', () {
      expect(
        code.contains("target.name == 'google_mobile_ads'"),
        isTrue,
        reason:
            'le post_install portait deja ce cas (tache 736) : les '
            'permissions s ajoutent a cote, elles ne le remplacent pas.',
      );
      expect(
        code.contains('CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'),
        isTrue,
        reason:
            'sans ce drapeau, la regie publicitaire ne compile plus : deux '
            'erreurs « Include of non-modular header » au build 4 du 08/10.',
      );
    });

    test('aucun commentaire du Podfile n allume une macro', () {
      final dansLesCommentaires = podfile
          .split('\n')
          .where((ligne) => ligne.trimLeft().startsWith('#'))
          .where(allumeeRegex.hasMatch)
          .toList();
      expect(
        dansLesCommentaires,
        isEmpty,
        reason:
            'la garde 740 cherche « MACRO = 1 » dans tout le texte du '
            'Podfile, commentaires compris : une macro ecrite a 1 dans une '
            'phrase lui ferait exiger une cle d usage pour une permission qui '
            'n est pas allumee. On parle des macros eteintes sans les ecrire '
            'avec leur valeur.',
      );
    });

    test('aucune macro inventee : toutes sont connues du greffon', () {
      expect(
        allumeesDans(code).difference(macrosConnues),
        isEmpty,
        reason:
            'une macro que permission_handler_apple ne lit pas ne fait RIEN, '
            'et sans bruit : une faute de frappe laisserait la permission '
            'eteinte en donnant l illusion du contraire.',
      );
    });

    test('la version du greffon est celle sur laquelle tout ceci a ete '
        'mesure', () {
      final lock = File('pubspec.lock').readAsStringSync();
      final version = RegExp(
        r'permission_handler_apple:.*?version:\s*"([^"]+)"',
        dotAll: true,
      ).firstMatch(lock)?.group(1);
      expect(
        version,
        versionMesuree,
        reason:
            'les lignes citees par cette garde et la liste des macros '
            'connues ont ete LUES dans permission_handler_apple '
            '$versionMesuree. Une montee de version peut renommer une macro '
            'ou en ajouter une : refaire la mesure, puis mettre ce fichier a '
            'jour DANS LE MEME COMMIT.',
      );
    });
  });
}
