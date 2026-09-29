import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/utils/tri_alphabetique_localise.dart';
import 'package:moteur_gr/shared/widgets/selecteur_de_pays.dart';

/// TACHE 634 — RETOUR 2 DE CHRISTOPHE (DEM-260929-1124).
///
/// Verbatim : « l'ordre des pays n'est pas alphabetique ».
///
/// CE QUE CES TESTS PROUVENT. Que la liste des pays est triee sur le libelle
/// AFFICHE, dans la langue courante, et qu'elle l'est dans les CINQ langues —
/// pas seulement en francais. Le defaut d'origine n'etait pas une absence de
/// tri : c'etait un tri fait sur une AUTRE langue que celle qu'on lit.
void main() {
  group(
    'la clef de tri range les accents et la casse la ou on les cherche',
    () {
      test('un accent ne deplace plus le mot', () {
        // C'est le cas qui condamnait `String.compareTo` : « E » accent aigu
        // vaut U+00C9, donc « Egypte » passait APRES « Zimbabwe ».
        expect(clefDeTriLocalisee('Égypte'), 'egypte');
        expect(comparerLibellesLocalises('Égypte', 'Estonie'), lessThan(0));
        expect(comparerLibellesLocalises('Égypte', 'Danemark'), greaterThan(0));
        expect(comparerLibellesLocalises('Égypte', 'Zimbabwe'), lessThan(0));
      });

      test('la casse ne deplace plus le mot', () {
        expect(comparerLibellesLocalises('Allemagne', 'Autriche'), lessThan(0));
        expect(
          comparerLibellesLocalises('autriche', 'Allemagne'),
          greaterThan(0),
        );
      });

      test('les lettres qui se lisent double sont depliees', () {
        // L'eszett allemand se classe « ss », les ligatures « ae » et « oe » :
        // c'est ainsi que les dictionnaires de ces langues les rangent.
        expect(clefDeTriLocalisee('Straße'), 'strasse');
        expect(clefDeTriLocalisee('Œuvre'), 'oeuvre');
        expect(clefDeTriLocalisee('Ærø'), 'aero');
      });

      test(
        'le trema allemand et le tilde espagnol se rangent sur leur lettre',
        () {
          expect(clefDeTriLocalisee('Österreich'), 'osterreich');
          expect(
            comparerLibellesLocalises('Österreich', 'Pakistan'),
            lessThan(0),
          );
          expect(
            comparerLibellesLocalises('Österreich', 'Norwegen'),
            greaterThan(0),
          );
          expect(clefDeTriLocalisee('España'), 'espana');
          expect(clefDeTriLocalisee('Türkiye'), 'turkiye');
        },
      );

      test('deux libelles de meme clef gardent un ordre stable', () {
        // Sans depart sur le libelle d'origine, l'ordre de deux libelles qui ne
        // different que par un accent dependrait de l'implementation du tri.
        expect(comparerLibellesLocalises('Eire', 'Éire'), isNot(0));
        expect(
          comparerLibellesLocalises('Eire', 'Éire'),
          -comparerLibellesLocalises('Éire', 'Eire'),
        );
      });
    },
  );

  group('la liste des pays est triee dans les CINQ langues', () {
    /// Pompe un contexte portant le delegue de traduction des pays pour la
    /// locale demandee, puis rend la liste telle que le selecteur l'affiche.
    Future<List<String>> nomsAffiches(
      WidgetTester tester,
      Locale locale,
    ) async {
      late List<String> noms;
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: const [
            Locale('fr'),
            Locale('en'),
            Locale('de'),
            Locale('es'),
            Locale('it'),
          ],
          localizationsDelegates: const [
            CountryLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) {
              noms = paysTriesPourAffichage(context)
                  .map((p) => nomPaysLocalise(context, p.countryCode))
                  .toList(growable: false);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      return noms;
    }

    for (final langue in ['fr', 'en', 'de', 'es', 'it']) {
      testWidgets('en $langue, chaque pays vient apres le precedent', (
        tester,
      ) async {
        final noms = await nomsAffiches(tester, Locale(langue));

        expect(
          noms.length,
          greaterThan(200),
          reason: 'la liste des pays doit rester complete',
        );

        for (var i = 1; i < noms.length; i++) {
          expect(
            comparerLibellesLocalises(noms[i - 1], noms[i]),
            lessThanOrEqualTo(0),
            reason:
                'en $langue, « ${noms[i]} » est affiche apres '
                '« ${noms[i - 1]} » alors qu il vient avant',
          );
        }
      });
    }

    testWidgets('aucun pays n apparait deux fois', (tester) async {
      final noms = await nomsAffiches(tester, const Locale('fr'));
      expect(noms.toSet().length, noms.length);
    });

    testWidgets('le defaut d origine est bien mort : en francais, la liste '
        'ne commence plus par l ordre anglais', (tester) async {
      final noms = await nomsAffiches(tester, const Locale('fr'));
      // Avant la tache 634, les cinq premieres lignes en francais etaient
      // « Afghanistan, Iles Aland, Albanie, Algerie, Samoa americaines » :
      // l'ordre alphabetique des noms ANGLAIS. « Samoa americaines » ne peut
      // plus figurer dans le haut de la liste francaise.
      final cinqPremiers = noms.take(5).toList();
      expect(
        cinqPremiers.any((n) => n.toLowerCase().startsWith('samoa')),
        isFalse,
        reason: 'debut de liste francais : $cinqPremiers',
      );
      expect(
        comparerLibellesLocalises(noms.first, 'B'),
        lessThan(0),
        reason: 'la liste francaise doit commencer a la lettre A',
      );
    });

    testWidgets('changer de langue REORDONNE la liste', (tester) async {
      // LA PREUVE QUE LE TRI SUIT LA LANGUE AFFICHEE et non une table figee :
      // les memes pays, ranges dans deux langues, ne sortent pas dans le meme
      // ordre. C'est exactement ce que le selecteur du paquet ne faisait pas —
      // il rendait TOUJOURS l'ordre anglais, quelle que soit la langue lue.
      late List<String> codesFr;
      late List<String> codesDe;
      for (final cas in [
        (const Locale('fr'), (List<String> c) => codesFr = c),
        (const Locale('de'), (List<String> c) => codesDe = c),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            locale: cas.$1,
            supportedLocales: const [Locale('fr'), Locale('de')],
            localizationsDelegates: const [
              CountryLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Builder(
              builder: (context) {
                cas.$2(
                  paysTriesPourAffichage(
                    context,
                  ).map((p) => p.countryCode).toList(growable: false),
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      expect(codesFr.toSet(), codesDe.toSet(), reason: 'memes pays');
      expect(
        codesFr,
        isNot(codesDe),
        reason: 'mais un ordre different, parce que les noms different',
      );
    });
  });
}
