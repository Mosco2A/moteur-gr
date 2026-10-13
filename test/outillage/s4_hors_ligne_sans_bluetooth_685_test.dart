// LE PARCOURS S4 HORS-LIGNE NE BASCULE PLUS SUR UNE PILE BLUETOOTH VIVANTE —
// tache 685.
//
// CE QUE CE FICHIER EMPECHE DE REVENIR (kaizen #101252). Le 05/10, la bascule
// en mode avion du parcours S4 a fait repartir en boucle la pile Bluetooth de
// l'IMAGE D'EMULATEUR :
//   07:48:32  bt_stack_manager_thread demarre
//   07:48:36  F/libc : Fatal signal 6 (SIGABRT) in tid bt_stack_manage,
//             pid droid.bluetooth (com.google.android.bluetooth)
//   07:48:59  E/ActivityManager : ANR in com.google.android.bluetooth
//   07:50:10  ANR in com.google.android.bluetooth (le second)
// 34 lignes `bt_stack_manage`, 8 reinitialisations de pile. L'ANR du service
// systeme a etouffe l'application : le run S4 a rendu 0 marqueur, 0 capture.
//
// POURQUOI COUPER NE DESARME RIEN, ET POURQUOI CE FICHIER LE PROUVE. On
// pourrait craindre qu'eteindre le Bluetooth rende vert un chemin du produit.
// Il n'y en a pas : la seule fonction qui s'en sert est la ceinture de
// frequence cardiaque (`HeartRateBleService`, phase 6), et AUCUN des huit
// parcours persona ne la traverse. Ce test le VERIFIE au lieu de l'affirmer :
// le jour ou un parcours exercera le Bluetooth, il rougira, et la coupure
// devra redevenir un choix par scenario.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Le pilote de runs, lu une fois.
final String _pilote = File('tool/run_persona.ps1').readAsStringSync();

/// Le script qui bascule le reseau pendant S4, lu une fois.
final String _bascule = File('tool/persona_s4_offline.py').readAsStringSync();

/// Les scenarios persona du depot.
List<File> get _scenarios => Directory('integration_test')
    .listSync()
    .whereType<File>()
    .where((f) => f.path.endsWith('_test.dart'))
    .toList(growable: false);

void main() {
  group('LA PILE BLUETOOTH DE L IMAGE EST ETEINTE AVANT LE RUN', () {
    test('le pilote l eteint, des deux facons documentees', () {
      expect(
        _pilote,
        contains('svc bluetooth disable'),
        reason:
            'COUPURE PERDUE : sans elle, la bascule de mode avion du parcours '
            'S4 relance la boucle SIGABRT bt_stack_manage de l image et le '
            'run rend 0 capture (kaizen #101252).',
      );
      expect(
        _pilote,
        contains('settings put global bluetooth_on 0'),
        reason:
            '`svc bluetooth disable` seul peut rester sans effet selon '
            'l image : le reglage global est la seconde voie',
      );
    });

    test('le pilote VERIFIE que la pile est bien eteinte', () {
      expect(
        _pilote,
        contains('settings get global bluetooth_on'),
        reason:
            'une extinction non verifiee est une esperance : il faut lire le '
            'reglage et le DIRE',
      );
      expect(
        _pilote,
        contains('extinction SANS EFFET'),
        reason:
            'quand la pile reste allumee, la recette doit prevenir avant le '
            'run, pas laisser lire le logcat apres coup',
      );
    });

    test('la coupure est le DEFAUT, et ne se leve que sur demande', () {
      expect(
        _pilote,
        contains(r'[switch]$SansCoupureBluetooth'),
        reason:
            'la levee doit etre un geste nomme ; le defaut doit proteger le '
            'run',
      );
      expect(
        _pilote,
        contains(r'Disable-BluetoothEmulateur $Serial $Tag'),
        reason: 'la fonction doit etre APPELEE, pas seulement definie',
      );
    });

    test('LA COUPURE PASSE AVANT LA PREMIERE BASCULE DE MODE AVION', () {
      final coupure = _bascule.indexOf('couper_bluetooth(serial)');
      final avion = _bascule.indexOf('airplane_mode_on');
      expect(coupure, greaterThan(0), reason: 'coupure absente du basculeur');
      expect(avion, greaterThan(0), reason: 'bascule de mode avion absente');
      expect(
        coupure,
        lessThan(avion),
        reason:
            'ORDRE INVERSE = PARADE ANNULEE : c est la bascule qui reveille '
            'la pile, donc elle doit la trouver deja eteinte.',
      );
    });

    test('la pile n est pas rallumee a la fin du parcours', () {
      expect(
        _bascule,
        contains('Bluetooth laisse eteint'),
        reason:
            'rallumer la pile derriere une bascule est exactement ce qui a '
            'plante : le retablissement ne concerne que le Wi-Fi et les '
            'donnees',
      );
      expect(
        _bascule,
        isNot(contains('svc bluetooth enable')),
        reason: 'la pile ne doit pas etre rallumee par la recette',
      );
    });
  });

  group('COUPER NE PEUT RENDRE VERT AUCUN CHEMIN DU PRODUIT', () {
    test('aucun scenario persona n exerce le Bluetooth', () {
      final coupables = <String>[];
      for (final f in _scenarios) {
        final source = f.readAsStringSync().toLowerCase();
        if (source.contains('bluetooth') ||
            source.contains('flutter_blue') ||
            source.contains('heartrate') ||
            source.contains('heart_rate')) {
          coupables.add(f.uri.pathSegments.last);
        }
      }
      expect(
        coupables,
        isEmpty,
        reason:
            'UN PARCOURS EXERCE DESORMAIS LE BLUETOOTH '
            '(${coupables.join(", ")}) : '
            'la recette l eteint avant le run, donc ce parcours serait juge '
            'sur une pile absente. Rendez la coupure optionnelle PAR '
            'SCENARIO avant d aller plus loin.',
      );
    });

    test('l image en cause est nommee dans la recette, pas devinee', () {
      expect(
        _bascule,
        contains('UE1A.230829.050'),
        reason:
            'l empreinte de build de l image fautive doit etre ecrite : sans '
            'elle, personne ne saura si le probleme est encore la apres une '
            'mise a jour du SDK',
      );
      expect(
        _bascule,
        contains('hw.bluetooth=no'),
        reason:
            'la vraie correction est dans l image : le reglage doit etre '
            'nomme a cote de la parade',
      );
    });
  });
}
