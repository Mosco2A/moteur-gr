import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/branding/app_branding.dart';

/// TACHE 632 — LE FILET DU CHANGEMENT DE FAMILLE DE LOGO.
///
/// Christophe a livre trois familles completes. Changer de famille tient en une
/// commande (`python tool/set_branding.py <famille> <splash>`), mais cette
/// commande touche QUATRE endroits : la constante Dart, la couche avant de
/// l'icone adaptative, et les deux fichiers de configuration a la racine.
///
/// Oublier d'en relancer une partie donnerait le pire des resultats : l'ecran
/// afficherait un logo, le lanceur en afficherait un AUTRE, et rien ne
/// planterait. Ces tests refusent cet ecart.
///
/// Ils lisent les fichiers sur le DISQUE plutot que par le paquet d'assets :
/// c'est justement la coherence entre le depot et le code qu'on verifie, et les
/// fichiers de configuration a la racine ne sont pas des assets.
void main() {
  final familles = ['sentier', 'marches', 'courbes'];
  final formes = [
    'picto',
    'picto-clair',
    'logo-vertical',
    'logo-horizontal',
    'logo-horizontal-clair',
    'icone-app',
  ];

  group('Les trois familles sont completes et rangees dans le depot', () {
    for (final famille in familles) {
      test('$famille : les six traces SVG sont la', () {
        for (final forme in formes) {
          final fichier = File(
            'assets/branding/svg/$famille/'
            '$famille-$forme.svg',
          );
          expect(
            fichier.existsSync(),
            isTrue,
            reason:
                'manque ${fichier.path} — changer de famille pour '
                '$famille echouerait a moitie',
          );
        }
      });

      test('$famille : le PNG 1024 source de l\'icone est la', () {
        expect(
          File('assets/branding/png/$famille-icone-app-1024.png').existsSync(),
          isTrue,
          reason:
              'sans ce PNG, tool/set_branding.py ne peut pas fabriquer '
              'l\'icone ni la couche avant Android',
        );
      });
    }
  });

  group('La famille active est coherente de bout en bout', () {
    test('AppBranding designe des fichiers qui existent vraiment', () {
      for (final chemin in [
        AppBranding.picto,
        AppBranding.pictoClair,
        AppBranding.logoVertical,
        AppBranding.logoHorizontal,
        AppBranding.logoHorizontalClair,
        AppBranding.iconeApp,
      ]) {
        expect(File(chemin).existsSync(), isTrue, reason: 'absent : $chemin');
      }
    });

    test('la famille active est l\'une des trois livrees', () {
      expect(familles, contains(AppBranding.family));
    });

    test('flutter_launcher_icons.yaml a ete regenere pour la famille active', () {
      final config = File('flutter_launcher_icons.yaml').readAsStringSync();
      expect(
        config,
        contains('famille active : ${AppBranding.family}'),
        reason:
            'la constante Dart dit ${AppBranding.family} mais la config '
            'de l\'icone dit autre chose : relancer '
            'tool/set_branding.py puis dart run flutter_launcher_icons',
      );
      // Le fond de l'icone doit etre celui de la famille, sinon le picto se
      // detache sur la mauvaise couleur une fois masque par le lanceur.
      final fond =
          '#${AppBranding.couleurFondIcone.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
      expect(config, contains('adaptive_icon_background: "$fond"'));
    });

    test('la couche avant de l\'icone adaptative a ete fabriquee', () {
      expect(
        File('assets/branding/icons/adaptive-foreground.png').existsSync(),
        isTrue,
        reason:
            'sans elle, Android 8+ rogne l\'icone pleine n\'importe '
            'comment selon le lanceur',
      );
      expect(
        File('assets/branding/icons/app-icon-1024.png').existsSync(),
        isTrue,
      );
    });

    test(
      'flutter_native_splash.yaml a ete regenere pour la variante active',
      () {
        final config = File('flutter_native_splash.yaml').readAsStringSync();
        expect(
          config,
          contains('variante active : ${AppBranding.splashVariant}'),
        );
        // Android 12+ ne montre QUE cette image sur la couleur unie : si la
        // ligne android_12 disparaissait, le demarrage retomberait sur l'icone
        // du lanceur par defaut, sans qu'aucun ecran ne le signale.
        expect(
          config,
          contains('assets/splash/${AppBranding.splashVariant}-android12.png'),
        );
        expect(
          File(
            'assets/splash/${AppBranding.splashVariant}-android12.png',
          ).existsSync(),
          isTrue,
        );
        expect(
          File(
            'assets/splash/${AppBranding.splashVariant}-logo.png',
          ).existsSync(),
          isTrue,
        );
        expect(
          File(
            'assets/splash/${AppBranding.splashVariant}-background.png',
          ).existsSync(),
          isTrue,
        );
      },
    );
  });

  group('L\'ancien logo bouche-trou ne traine plus nulle part', () {
    test('les deux vecteurs placeholder Android sont supprimes', () {
      // Montagne grise sur #37474F, posee en E5.7b comme « a remplacer par le
      // logo produit final ». C'est exactement ce que la tache 632 fait.
      expect(
        File(
          'android/app/src/main/res/drawable/ic_launcher_foreground.xml',
        ).existsSync(),
        isFalse,
      );
      expect(
        File(
          'android/app/src/main/res/drawable/ic_launcher_background.xml',
        ).existsSync(),
        isFalse,
      );
    });

    test('la variante ronde ne pointe plus sur l\'ancien fond', () {
      final rond = File(
        'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml',
      ).readAsStringSync();
      expect(rond, contains('@color/ic_launcher_background'));
      expect(rond, isNot(contains('@drawable/ic_launcher_background')));
    });

    test('la couleur de fond de l\'icone Android suit la famille active', () {
      final couleurs = File(
        'android/app/src/main/res/values/colors.xml',
      ).readAsStringSync();
      final fond = AppBranding.couleurFondIcone
          .toARGB32()
          .toRadixString(16)
          .substring(2)
          .toUpperCase();
      expect(couleurs, contains('#$fond'));
    });
  });
}
