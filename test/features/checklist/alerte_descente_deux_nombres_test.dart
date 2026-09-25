import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moteur_gr/features/checklist/data/checklist_template.dart';
import 'package:moteur_gr/features/checklist/providers/checklist_provider.dart';
import 'package:moteur_gr/features/checklist/widgets/checklist_descent_alert.dart';
import 'package:moteur_gr/features/feasibility/providers/trek_feasibility_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// L'ALERTE DESCENTE DIT DEUX NOMBRES, PLUS JAMAIS UN TOTAL (tache 552).
///
/// RETOUR DE CHRIS, MOT POUR MOT : « 10/ Descente et poid du sac, je ne
/// comprends pas le texte ». Et il avait une raison mecanique de ne pas
/// comprendre : le texte affichait UN SEUL chiffre, `excessLoadKg`, qui
/// ADDITIONNE les kilos du sac et les kilos au-dessus du poids de forme. Chris
/// lisait « 50,8 kg » sans savoir ce qui venait de son sac — or c'est la SEULE
/// part sur laquelle il peut agir.
///
/// CE QUI EST VERROUILLE ICI :
///   1. les DEUX nombres sont enonces separement, et le total a disparu ;
///   2. quand il n'y a rien au-dessus du poids de forme, on n'ecrit pas
///      « 0,0 kg » — le texte bascule sur la variante sac seul (« on se tait sur
///      ce qu'on n'a pas ») ;
///   3. UN SEUL chiffre mecanique, et c'est le chiffre source #S23-a (Kutzner
///      2010 : 3,46 fois le poids en descente contre 2,61 a plat) ;
///   4. LE GARDE-FOU DE REDACTION, dans les cinq langues : le texte parle de
///      masse transportee et de charge au genou, JAMAIS d'IMC, JAMAIS du corps
///      de la personne, JAMAIS de pronostic de blessure. Fondement : #S14
///      (Zwolinski 2025, 162 randonneurs, p = 0,708) ne montre AUCUNE relation
///      entre categorie d'IMC et blessure en randonnee.
void main() {
  setUpAll(() => LocaleSettings.setLocaleRaw('fr'));

  /// Etat de Sac fabrique de toutes pieces : un seul article coche, dont le
  /// poids fait le poids du sac.
  ChecklistState etat({
    required int heightCm,
    required double bodyWeightKg,
    required int packGrams,
  }) {
    const modele = ChecklistTemplateItem(
      id: 'backpack',
      category: 'carrying',
      nameKey: 'backpack',
    );
    return ChecklistState(
      items: [
        ChecklistItemState(
          template: modele,
          isChecked: true,
          weightGrams: packGrams,
        ),
      ],
      checkedCount: 1,
      totalCount: 1,
      bodyWeightKg: bodyWeightKg,
      bodyHeightCm: heightCm,
    );
  }

  Future<void> pumpAlerte(WidgetTester tester, ChecklistState etatSac) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          checklistProvider.overrideWith(() => _FauxSac(etatSac)),
          // L'alerte classe les etapes par denivele negatif : sans evaluation,
          // elle n'en cite aucune et le texte reste seul. C'est le texte qui est
          // teste ici.
          feasibilityAssessmentProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ChecklistDescentAlert()),
        ),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  /// Le texte affiche par l'alerte (unique Text de plus de 40 caracteres).
  String texteAffiche(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((w) => w.data ?? '')
      .firstWhere((s) => s.length > 40, orElse: () => '');

  group('a l ecran', () {
    testWidgets('120 kg a 1,78 m, sac 10 kg : DEUX nombres, pas leur somme',
        (tester) async {
      // Reference a 1,78 m = 79,2 kg. Au-dessus du poids de forme : 40,8 kg.
      // Sac : 10,0 kg. L ancien texte affichait 50,8 — et c est precisement ce
      // total que Chris ne pouvait pas interpreter.
      await pumpAlerte(
        tester,
        etat(heightCm: 178, bodyWeightKg: 120, packGrams: 10000),
      );

      final texte = texteAffiche(tester);
      expect(texte, contains('10,0 kg'),
          reason: 'les kilos de SAC doivent etre nommes tels quels');
      expect(texte, contains('40,8 kg'),
          reason: 'les kilos au-dessus du poids de forme doivent etre nommes '
              'a part');
      expect(texte, isNot(contains('50,8')),
          reason: 'le TOTAL est exactement ce que le retour de Chris reproche : '
              'il ne doit plus apparaitre');
    });

    testWidgets('70 kg a 1,78 m, sac 8 kg : on n ecrit pas « 0,0 kg »',
        (tester) async {
      // Sous la reference : il n y a RIEN au-dessus du poids de forme. Enoncer
      // « 0,0 kg au-dessus de ton poids de forme » serait un nombre nul presente
      // comme un fait.
      await pumpAlerte(
        tester,
        etat(heightCm: 178, bodyWeightKg: 70, packGrams: 8000),
      );

      final texte = texteAffiche(tester);
      expect(texte, contains('8,0 kg'));
      expect(texte, isNot(contains('0,0 kg')));
      expect(texte, isNot(contains('poids de forme')),
          reason: 'sans kilos au-dessus du poids de forme, on n en parle pas');
    });

    testWidgets('sac vide et poids sous la reference : AUCUNE alerte',
        (tester) async {
      // Comportement inchange : une alerte qui se declenche toujours n alerte
      // plus.
      await pumpAlerte(
        tester,
        etat(heightCm: 178, bodyWeightKg: 70, packGrams: 0),
      );
      expect(find.byKey(const ValueKey('checklist-descent-alert')),
          findsNothing);
    });
  });

  group('les textes, dans les cinq langues', () {
    test('DEUX reperes distincts dans le texte complet, UN dans la variante',
        () {
      for (final langue in AppLocale.values) {
        final w = langue.buildSync().checklist.weight;
        expect(w.descentAlertBody, contains('{pack}'),
            reason: '${langue.languageCode} : les kilos de sac ne sont pas '
                'nommes');
        expect(w.descentAlertBody, contains('{above}'),
            reason: '${langue.languageCode} : les kilos au-dessus du poids de '
                'forme ne sont pas nommes a part');
        // L ancien repere unique — le total — ne doit plus exister.
        expect(w.descentAlertBody, isNot(contains('{kg}')),
            reason: '${langue.languageCode} : le total est revenu');
        expect(w.descentAlertBodyPackOnly, contains('{pack}'));
        expect(w.descentAlertBodyPackOnly, isNot(contains('{above}')),
            reason: '${langue.languageCode} : la variante sac seul parle quand '
                'meme du poids de forme');
      }
    });

    test('UN SEUL chiffre mecanique, et c est #S23-a Kutzner 2010', () {
      const attendus = <AppLocale, List<String>>{
        AppLocale.fr: ['3,46', '2,61'],
        AppLocale.en: ['3.46', '2.61'],
        AppLocale.de: ['3,46', '2,61'],
        AppLocale.es: ['3,46', '2,61'],
        AppLocale.it: ['3,46', '2,61'],
      };
      for (final entree in attendus.entries) {
        final w = entree.key.buildSync().checklist.weight;
        for (final texte in [
          w.descentAlertBody,
          w.descentAlertBodyPackOnly,
        ]) {
          for (final chiffre in entree.value) {
            expect(texte, contains(chiffre),
                reason: '${entree.key.languageCode} : le chiffre source '
                    '$chiffre manque');
          }
        }
      }
    });

    test('LE GARDE-FOU : ni IMC, ni corps, ni pronostic de blessure', () {
      // Liste NOMMEE, langue par langue. Une forme est interdite parce qu elle
      // est ecrite ici, jamais parce qu un algorithme la trouve suspecte.
      const interdits = <AppLocale, List<String>>{
        AppLocale.fr: [
          'imc',
          'obésit',
          'surpoids',
          'corpulence',
          'pronostic',
          'blessure',
          'poids de référence',
        ],
        AppLocale.en: [
          'bmi',
          'obes',
          'overweight',
          'forecast',
          'injur',
          'reference weight',
        ],
        AppLocale.de: [
          'bmi',
          'adiposit',
          'übergewicht',
          'prognose',
          'verletzung',
          'referenzgewicht',
        ],
        AppLocale.es: [
          'imc',
          'obesidad',
          'sobrepeso',
          'pronóstico',
          'lesión',
          'peso de referencia',
        ],
        AppLocale.it: [
          'imc',
          'obesit',
          'sovrappeso',
          'pronostico',
          'infortun',
          'peso di riferimento',
        ],
      };
      for (final entree in interdits.entries) {
        final w = entree.key.buildSync().checklist.weight;
        for (final texte in [
          w.descentAlertBody,
          w.descentAlertBodyPackOnly,
        ]) {
          for (final mot in entree.value) {
            expect(texte.toLowerCase(), isNot(contains(mot)),
                reason: '${entree.key.languageCode} : l alerte descente dit '
                    '« $mot » — elle parle du corps ou pose un pronostic');
          }
        }
      }
    });

    test('le SAC est nomme, et UNE action est demandee', () {
      for (final entree in _motSac.entries) {
        final w = entree.key.buildSync().checklist.weight;
        expect(w.descentAlertBody.toLowerCase(), contains(entree.value));
        expect(
            w.descentAlertBodyPackOnly.toLowerCase(), contains(entree.value));
      }
    });

    test('LE TITRE est neutre : il n annonce pas un seul des deux poids', () {
      // DEFAUT ATTRAPE PAR SKYNET A LA RELECTURE DU COMMIT 3f3d1dd — ce test
      // est son garde-fou. Le corps annonce DEUX poids, mais le titre francais
      // disait encore « Descentes : le poids de ton sac » : il n'en annoncait
      // qu'un. Les quatre autres langues etaient deja neutres (« what you
      // carry », « was du tragst », « lo que llevas », « cio che porti ») ; le
      // francais etait le seul reste sur l'ancien cadrage, donc le seul faux —
      // et dans la langue de Chris. Un titre qui annonce le sac au-dessus d'un
      // corps qui parle de deux poids, c'est la demi-coherence qui fait dire
      // « je ne comprends pas le texte ».
      //
      // LA REGLE, TESTEE : le titre ne NOMME NI l'un NI l'autre des deux poids.
      // Il cadre ce qui descend, le corps chiffre. C'est aussi ce qui permet au
      // MEME titre de coiffer la variante sac seul sans mentir — donc pas de
      // second titre a maintenir, et la parite des cles reste intacte.
      for (final entree in _motSac.entries) {
        final titre =
            entree.key.buildSync().checklist.weight.descentAlertTitle;
        expect(titre.trim(), isNotEmpty);
        expect(titre.toLowerCase(), isNot(contains(entree.value)),
            reason: '${entree.key.languageCode} : le titre n annonce que le sac '
                '(« $titre ») alors que le corps annonce deux poids');
      }
      // Et il ne bascule pas dans l'autre exces : il ne parle pas davantage du
      // corps de la personne — le garde-fou de redaction vaut pour le titre.
      const autrePoids = <AppLocale, List<String>>{
        AppLocale.fr: ['poids de forme', 'imc', 'surpoids'],
        AppLocale.en: ['fit weight', 'bmi', 'overweight'],
        AppLocale.de: ['wohlfuhlgewicht', 'bmi', 'ubergewicht'],
        AppLocale.es: ['peso de forma', 'imc', 'sobrepeso'],
        AppLocale.it: ['peso di forma', 'imc', 'sovrappeso'],
      };
      for (final entree in autrePoids.entries) {
        final titre = entree.key
            .buildSync()
            .checklist
            .weight
            .descentAlertTitle
            .toLowerCase();
        for (final mot in entree.value) {
          expect(titre, isNot(contains(mot)),
              reason: '${entree.key.languageCode} : le titre dit « $mot »');
        }
      }
    });
  });
}

/// Le mot qui designe le SAC dans chaque langue. Sert deux fois : le corps doit
/// le nommer (c'est la seule part sur laquelle Chris peut agir), le titre ne
/// doit PAS le nommer (il coiffe les deux poids, pas un seul).
const _motSac = <AppLocale, String>{
  AppLocale.fr: 'sac',
  AppLocale.en: 'pack',
  AppLocale.de: 'rucksack',
  AppLocale.es: 'mochila',
  AppLocale.it: 'zaino',
};

/// Sac fabrique : le [ChecklistNotifier] reel lit la base, celui-ci rend l etat
/// qu on lui donne.
class _FauxSac extends ChecklistNotifier {
  _FauxSac(this._etat);

  final ChecklistState _etat;

  @override
  ChecklistState build() => _etat;
}
