import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/settings/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TACHE 558 — LE MODE SOMBRE / CLAIR FONCTIONNE.
///
/// Retour de Chris, mot pour mot : « sombrer clair ca ne fonctionne pas ». Et il
/// avait raison sur toute la ligne : les trois choix existaient dans les
/// Reglages, le choix etait PERSISTE, le theme clair etait CONSTRUIT et passe a
/// `MaterialApp`... et `main.dart` ecrivait `themeMode: ThemeMode.dark` EN DUR.
/// Le randonneur choisissait « Clair », son choix survivait au redemarrage, et
/// l'ecran restait sombre. Un seul fil manquait, et rien ne le disait.
///
/// CE QUE CES TESTS VERROUILLENT :
///  1. la traduction reglage -> [ThemeMode], y compris « systeme » et l'inconnu ;
///  2. que le choix SURVIT au redemarrage (il est relu depuis les preferences) ;
///  3. que `main.dart` ne reforce JAMAIS un mode en dur — c'est le garde-fou de
///     non-retour du defaut lui-meme, et il se lit sur la source.
void main() {
  group('AppThemeModeValues.toThemeMode', () {
    test('les trois choix offerts a l ecran sont tous honores', () {
      expect(AppThemeModeValues.toThemeMode(AppThemeModeValues.dark),
          ThemeMode.dark);
      expect(AppThemeModeValues.toThemeMode(AppThemeModeValues.light),
          ThemeMode.light);
      // « Systeme » suit vraiment le telephone : c'est ThemeMode.system qui le
      // fait, pas un choix devine de notre cote.
      expect(AppThemeModeValues.toThemeMode(AppThemeModeValues.system),
          ThemeMode.system);
    });

    test('une valeur inconnue retombe sur le defaut du produit, pas au hasard',
        () {
      expect(AppThemeModeValues.toThemeMode('crepuscule'), ThemeMode.dark);
      expect(AppThemeModeValues.toThemeMode(''), ThemeMode.dark);
    });

    test('les trois modes donnent trois ThemeMode DISTINCTS', () {
      final modes = AppThemeModeValues.values
          .map(AppThemeModeValues.toThemeMode)
          .toSet();
      expect(modes.length, 3,
          reason: 'sans quoi deux choix a l ecran feraient la meme chose');
    });
  });

  group('le choix SURVIT au redemarrage', () {
    test('« Clair » choisi, puis relu au lancement suivant', () async {
      // Lancement 1 : le randonneur choisit « Clair ».
      SharedPreferences.setMockInitialValues({});
      final premier = ProviderContainer();
      addTearDown(premier.dispose);
      premier.read(settingsProvider); // declenche build + load
      await Future<void>.delayed(Duration.zero);
      premier
          .read(settingsProvider.notifier)
          .setThemeMode(AppThemeModeValues.light);
      expect(premier.read(settingsProvider).themeMode,
          AppThemeModeValues.light);
      await Future<void>.delayed(Duration.zero);

      // Lancement 2 : un container NEUF relit les preferences reelles.
      final second = ProviderContainer();
      addTearDown(second.dispose);
      second.read(settingsProvider);
      await Future<void>.delayed(Duration.zero);
      expect(second.read(settingsProvider).themeMode, AppThemeModeValues.light,
          reason: 'le choix de theme doit survivre au redemarrage');
      expect(
          AppThemeModeValues.toThemeMode(
              second.read(settingsProvider).themeMode),
          ThemeMode.light);
    });

    test('« Systeme » aussi : il se relit, il ne se perd pas', () async {
      SharedPreferences.setMockInitialValues({
        'settings_theme_mode': AppThemeModeValues.system,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // Etat initial = defaut produit, puis ecrase par la valeur relue.
      expect(container.read(settingsProvider).themeMode,
          AppThemeModeValues.dark);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(settingsProvider).themeMode,
          AppThemeModeValues.system);
    });
  });

  // ---------------------------------------------------------------------------
  // GARDE-FOU DE NON-RETOUR, LU SUR LA SOURCE.
  //
  // Le defaut n'etait ni dans le modele, ni dans l'ecran, ni dans la
  // persistance : il etait dans UNE ligne de `main.dart`. Aucun test de
  // comportement ne pouvait l'attraper sans lancer l'application entiere. On
  // verrouille donc la ligne elle-meme — c'est le seul endroit ou le defaut peut
  // revenir, et il y est revenu une fois.
  // ---------------------------------------------------------------------------
  group('main.dart ne force plus aucun mode en dur', () {
    test('themeMode est branche sur le reglage, pas ecrit en dur', () {
      final source = File('lib/main.dart').readAsStringSync();
      expect(source.contains('themeMode: ThemeMode.dark'), isFalse,
          reason: 'le mode sombre etait force en dur : Chris a signale '
              '« sombrer clair ca ne fonctionne pas »');
      expect(source.contains('themeMode: ThemeMode.light'), isFalse);
      expect(source.contains('themeMode: ThemeMode.system'), isFalse);
      expect(source.contains('AppThemeModeValues.toThemeMode'), isTrue,
          reason: 'le mode doit venir du reglage persiste');
      expect(source.contains('s.themeMode'), isTrue,
          reason: 'et etre observe sur le seul champ themeMode');
    });
  });
}
