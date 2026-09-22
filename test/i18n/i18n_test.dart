import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/i18n/i18n_setup.dart';

/// Aplatit un fichier de traduction en chemins de cles (`a.b.c`).
Set<String> _cles(Object? noeud, [String chemin = '']) {
  if (noeud is Map) {
    final out = <String>{};
    noeud.forEach((k, v) => out.addAll(_cles(v, '$chemin.$k')));
    return out;
  }
  return {chemin};
}

Map<String, dynamic> _charge(String langue) => jsonDecode(
      File('assets/i18n/$langue.i18n.json').readAsStringSync(),
    ) as Map<String, dynamic>;

void main() {
  group('Slang i18n', () {
    test('5 locales sont supportees (fr, en, de, it, es)', () {
      // Verifier que AppLocale contient bien 5 valeurs
      expect(AppLocale.values.length, equals(5));

      // Verifier les codes de langue
      final localeTags = AppLocale.values.map((l) => l.languageTag).toList();
      expect(localeTags, contains('fr'));
      expect(localeTags, contains('en'));
      expect(localeTags, contains('de'));
      expect(localeTags, contains('it'));
      expect(localeTags, contains('es'));
    });

    test('les constantes i18n_setup matchent les locales generees', () {
      // Verifier la coherence entre la config et le code genere
      expect(supportedLocales.length, equals(AppLocale.values.length));
      expect(defaultLocale, equals('fr'));

      // Chaque locale de la config doit exister dans le code genere
      for (final code in supportedLocales) {
        final found = AppLocale.values.any(
          (l) => l.languageTag == code,
        );
        expect(found, isTrue,
            reason: 'Locale $code doit exister dans AppLocale');
      }
    });

    test('LES 5 LANGUES PORTENT EXACTEMENT LES MEMES CLES', () {
      // GATE DE PARITE. Slang se rabat silencieusement sur la langue de base
      // quand une cle manque : un ecran traduit en francais s afficherait en
      // francais a un randonneur allemand, sans qu aucun test ne bronche et
      // sans qu aucune erreur ne soit levee. Le seul moyen de le voir est de
      // comparer les fichiers eux-memes.
      //
      // Le message d echec NOMME les cles, dans les deux sens : celles qui
      // manquent a une langue, et celles qu elle porte en trop (typiquement
      // une cle renommee ailleurs et laissee morte ici).
      final base = _cles(_charge('fr'));
      final ecarts = <String>[];
      for (final langue in ['en', 'de', 'es', 'it']) {
        final autres = _cles(_charge(langue));
        final manquantes = base.difference(autres).toList()..sort();
        final enTrop = autres.difference(base).toList()..sort();
        if (manquantes.isNotEmpty) {
          ecarts.add('$langue : ${manquantes.length} cle(s) manquante(s) -> '
              '${manquantes.take(10).join(', ')}');
        }
        if (enTrop.isNotEmpty) {
          ecarts.add('$langue : ${enTrop.length} cle(s) en trop -> '
              '${enTrop.take(10).join(', ')}');
        }
      }
      expect(ecarts, isEmpty, reason: ecarts.join('\n'));
    });

    test('la locale de base est FR (pas EN)', () {
      // Verifier que strings.g.dart (base_locale en) a ete supprime
      // et que seul translations.g.dart (base_locale fr) est utilise
      final baseLocale = AppLocale.values.first;
      expect(baseLocale.languageTag, equals('fr'),
          reason: 'La base locale doit etre FR, pas EN');
    });
  });
}
