/// LES PLURIELS BRUTS ET LE SENS DE PARCOURS EN CODE (tache 835, lot A5).
///
/// CE QUI S'AFFICHAIT, MESURE LE 12/10 :
///
///   * « 1 etape(s) » dans le recapitulatif — la cle `recap.dayStages` valait
///     « $count étape(s) », le pluriel etant ECRIT EN DUR avec ses parentheses ;
///   * « 9 nuit(s) restante(s) » dans les nuitees, meme patron, et substitue a
///     la main par `replaceAll('{count}', …)` ;
///   * « 1 jours de repos » dans l'itineraire — celui-la etait le plus
///     insidieux : aucun « (s) » pour avertir, le mot « jours » etait
///     simplement au pluriel en dur, donc TOUJOURS faux au singulier ;
///   * « Direction NS » dans le Resume du plan — pas un pluriel, un CODE
///     MACHINE pose tel quel dans un `Text`.
///
/// CE QUI EST TESTE : LE MECANISME, PAS UNE CHAINE. Le depot avait deja prouve
/// a la tache 560 (`accord_pluriel_etapes_test.dart`) que Slang sait accorder
/// par resolveur CLDR ; ce lot etend ce mecanisme deja eprouve a trois cles qui
/// ne l'avaient jamais recu. On verifie donc ce que seul le mecanisme garantit :
/// la forme CHANGE entre 1 et plusieurs, DANS LES CINQ LANGUES.
///
/// POURQUOI « jours de marche + jours de repos » A ETE COUPE EN DEUX CLES. Une
/// cle Slang ne porte qu'UN cardinal. La phrase en demandait deux, accordes
/// independamment (« 6 jours de marche + 1 jour de repos »). Elle est donc
/// devenue une JOINTURE (« $walk + $rest ») nourrie par deux cles au pluriel —
/// ce qui laisse en plus chaque langue libre de l'ordre de ses deux moities.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/utils/libelle_de_direction.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleRaw('fr'));
  tearDown(() => LocaleSettings.setLocaleRaw('fr'));

  group('Les pluriels s accordent, dans les cinq langues (835)', () {
    test('recap.dayStages : la forme change entre 1 et plusieurs', () {
      for (final locale in AppLocale.values) {
        LocaleSettings.setLocaleRaw(locale.languageCode);
        final un = t.recap.dayStages(n: 1);
        final deux = t.recap.dayStages(n: 2);
        expect(
          un,
          isNot(deux),
          reason:
              'en ${locale.languageCode}, « 1 etape » et « 2 etapes » '
              's ecrivent pareil : le pluriel n est pas accorde',
        );
        expect(un, contains('1'));
        expect(deux, contains('2'));
        // Et le marqueur de chantier typographique a disparu.
        expect(un, isNot(contains('(s)')));
        expect(deux, isNot(contains('(s)')));
      }
    });

    test('nuitees.summary.remaining : plus de « nuit(s) restante(s) »', () {
      for (final locale in AppLocale.values) {
        LocaleSettings.setLocaleRaw(locale.languageCode);
        final un = t.nuitees.summary.remaining(n: 1);
        final neuf = t.nuitees.summary.remaining(n: 9);
        expect(
          un,
          isNot(neuf),
          reason: 'non accorde en ${locale.languageCode}',
        );
        expect(un, isNot(contains('(s)')));
        expect(neuf, isNot(contains('(s)')));
        // L italien ecrivait « notte/i rimasta/e », l allemand « Nacht/Nachte ».
        expect(un, isNot(contains('/')));
        expect(neuf, isNot(contains('/')));
      }
    });

    test('itinerary : jour(s) de marche et jour(s) de repos s accordent', () {
      for (final locale in AppLocale.values) {
        LocaleSettings.setLocaleRaw(locale.languageCode);
        expect(
          t.itinerary.walkDays(n: 1),
          isNot(t.itinerary.walkDays(n: 6)),
          reason: 'jours de marche non accordes en ${locale.languageCode}',
        );
        expect(
          t.itinerary.restDays(n: 1),
          isNot(t.itinerary.restDays(n: 2)),
          reason: 'jours de repos non accordes en ${locale.languageCode}',
        );
      }
    });

    // LE TEST QUI DONNE SON NOM AU DEFAUT.
    test('« 1 jours de repos » n existe plus en francais', () {
      LocaleSettings.setLocaleRaw('fr');
      expect(t.itinerary.restDays(n: 1), '1 jour de repos');
      expect(t.itinerary.restDays(n: 3), '3 jours de repos');
      expect(t.itinerary.walkDays(n: 1), '1 jour de marche');
      expect(t.itinerary.walkDays(n: 6), '6 jours de marche');
      expect(t.recap.dayStages(n: 1), '1 étape');
      expect(t.recap.dayStages(n: 7), '7 étapes');
      expect(t.nuitees.summary.remaining(n: 1), '1 nuit restante');
      expect(t.nuitees.summary.remaining(n: 9), '9 nuits restantes');
    });

    test('la phrase assemblee reste lisible : 6 jours + 1 jour', () {
      LocaleSettings.setLocaleRaw('fr');
      final phrase = t.itinerary.daysBreakdown(
        walk: t.itinerary.walkDays(n: 6),
        rest: t.itinerary.restDays(n: 1),
      );
      expect(phrase, '6 jours de marche + 1 jour de repos');
    });

    test('LE ZERO SUIT LA REGLE DE LA LANGUE, pas celle du code', () {
      // Le francais accorde 0 comme 1, l anglais comme plusieurs : c est la
      // regle CLDR, et c est exactement ce qu on gagne a ne pas l ecrire nous.
      LocaleSettings.setLocaleRaw('fr');
      expect(t.itinerary.restDays(n: 0), '0 jour de repos');
      LocaleSettings.setLocaleRaw('en');
      expect(t.itinerary.restDays(n: 0), '0 rest days');
    });
  });

  group('Le sens de parcours s ecrit en clair (835)', () {
    test('NS et SN deviennent des phrases, dans les cinq langues', () {
      for (final locale in AppLocale.values) {
        LocaleSettings.setLocaleRaw(locale.languageCode);
        final ns = libelleDeDirection('NS', t);
        final sn = libelleDeDirection('SN', t);
        expect(
          ns,
          isNot('NS'),
          reason: 'en ${locale.languageCode}, le code brut remonte a l ecran',
        );
        expect(sn, isNot('SN'));
        expect(ns, isNot(sn));
        expect(ns.length, greaterThan(2));
      }
    });

    test('en francais, c est Nord-Sud et Sud-Nord', () {
      LocaleSettings.setLocaleRaw('fr');
      expect(libelleDeDirection('NS', t), 'Nord-Sud');
      expect(libelleDeDirection('SN', t), 'Sud-Nord');
    });

    test('un code inconnu ne fait PAS reapparaitre un code brut', () {
      // Le depot ne declare que NS et SN ; si un troisieme apparaissait, il ne
      // doit surtout pas ressortir tel quel dans la phrase du Resume.
      LocaleSettings.setLocaleRaw('fr');
      final libelle = libelleDeDirection('EW', t);
      expect(libelle, isNot('EW'));
      expect(libelle, 'Sud-Nord');
    });
  });
}
