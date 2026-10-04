// OUTILS PARTAGES DES TROIS FICHIERS temperature_676 (tache 676).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/settings/data/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'persona_harness.dart';

/// L'unite telle que LE MAGASIN DU TELEPHONE la porte, lue a neuf.
///
/// On passe par `SharedPreferences` directement, et non par le service : c'est
/// l'etat qui survit au processus, et c'est lui qu'on veut voir.
Future<String> uniteDansLeMagasin() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final brut = prefs.get(SettingsKeys.temperatureUnit);
  return brut == null ? 'ABSENTE' : '$brut';
}

/// L'unite telle que L'ECRAN la montre comme selectionnee.
///
/// On lit l'etat du `SegmentedButton` de la ligne « Temperature », reconnue
/// par ses deux segments °C et °F — pas par sa position dans la page.
String uniteAffichee(WidgetTester tester) {
  final boutons = find.byType(SegmentedButton<String>);
  for (final element in boutons.evaluate()) {
    final bouton = element.widget as SegmentedButton<String>;
    final valeurs = bouton.segments.map((s) => s.value).toSet();
    if (valeurs.contains('celsius') && valeurs.contains('fahrenheit')) {
      return bouton.selected.join(',');
    }
  }
  return 'BOUTON_INTROUVABLE';
}

/// Tape le segment [symbole] (°C ou °F) de la ligne « Temperature ».
Future<bool> choisirUnite(
  WidgetTester tester,
  String persona,
  String symbole,
) async {
  final boutons = find.byType(SegmentedButton<String>);
  for (final element in boutons.evaluate()) {
    final bouton = element.widget as SegmentedButton<String>;
    final valeurs = bouton.segments.map((s) => s.value).toSet();
    if (!valeurs.contains('celsius') || !valeurs.contains('fahrenheit')) {
      continue;
    }
    final cible = find.descendant(
      of: find.byWidget(bouton),
      matching: find.text(symbole),
    );
    if (cible.evaluate().isEmpty) {
      logStep(persona, 'geste', 'segment $symbole introuvable');
      return false;
    }
    await tester.ensureVisible(cible.first);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 4));
    await tester.tap(cible.first, warnIfMissed: false);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
    logStep(persona, 'geste', 'segment $symbole tape');
    return true;
  }
  logStep(persona, 'geste', 'ligne Temperature introuvable');
  return false;
}
