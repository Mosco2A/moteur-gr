import 'package:country_picker/country_picker.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/feasibility/data/hiker_profile_repository.dart';
import 'package:moteur_gr/features/feasibility/domain/hiker_input_bounds.dart';
import 'package:moteur_gr/features/feasibility/domain/hiker_profile.dart';
import 'package:moteur_gr/features/feasibility/presentation/hiker_profile_screen.dart';
import 'package:moteur_gr/features/feasibility/presentation/past_hikes_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// NON-REGRESSION FIX-1 — saisie bornee cote faisabilite.
///
/// Findings couverts (rapport personas cycle4, fiche #100167) :
///  - M5 : « Ajouter une rando » tous champs vides creait une rando
///    1 jour / 0 km / 0 D+ SANS MESSAGE, alors que l'ecran annonce
///    « On en deduit votre niveau » — une rando vide pesait sur la deduction ;
///  - m1 : la taille « 1280 » devenait « 128 » SILENCIEUSEMENT (maxLength 3) ;
///  - m3 : le code pays « ZZ » (inexistant) etait accepte sans controle.
void main() {
  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Widget wrap(String path, Widget screen) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        hikerProfileRepositoryProvider
            .overrideWithValue(HikerProfileRepository(db: db, prefs: prefs)),
      ],
      // L'ecran est atteint par un push depuis /home (comme en prod) : le
      // `Navigator.pop()` de la sauvegarde a bien une page ou revenir.
      child: TranslationProvider(
        child: MaterialApp.router(
          // MEME LOCALISATION QU'EN PRODUCTION (tache 553) : sans le delegue
          // `CountryLocalizations`, les noms de pays retomberaient en anglais et
          // le test ne prouverait rien de la langue de l'application. La locale
          // est calee sur la langue de base de Slang (fr), pour que le nom du
          // pays et les libelles `t.*` parlent la meme langue.
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            CountryLocalizations.delegate,
          ],
          routerConfig: GoRouter(
            initialLocation: '/home/screen',
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const Scaffold(body: SizedBox()),
                routes: [
                  GoRoute(path: 'screen', builder: (_, __) => screen),
                ],
              ),
              GoRoute(path: '/my-treks', builder: (_, __) => const SizedBox()),
              GoRoute(path: '/consent', builder: (_, __) => const SizedBox()),
            ],
          ),
        ),
      ),
    );
  }

  group('M5 — une rando vide ne peut plus fausser la deduction de niveau', () {
    testWidgets('tous champs vides : refus avec message, rien enregistre',
        (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap('screen', const PastHikesScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.pastHikes.addHike));
      await tester.pumpAndSettle();

      // Enregistrer sans rien saisir.
      await tester.tap(find.text(t.pastHikes.save).last);
      await tester.pumpAndSettle();

      // Message explicite (le nombre de jours manque ET aucun effort n'est
      // renseigne) et la feuille RESTE ouverte : rien n'a ete invente.
      expect(find.text(t.pastHikes.errorDays), findsOneWidget);
      expect(find.byKey(const ValueKey('past-hike-form-error')), findsOneWidget);
      expect(find.text(t.pastHikes.fieldDays), findsOneWidget);
      // Aucune rando n'a ete ajoutee (l'ecran affiche toujours l'etat vide).
      expect(find.text(t.pastHikes.saved), findsNothing);
    });

    testWidgets('jours seuls ne suffisent pas : il faut D+ ou distance',
        (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap('screen', const PastHikesScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.pastHikes.addHike));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, t.pastHikes.fieldDays), '3');
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.pastHikes.save).last);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('past-hike-form-error')), findsOneWidget);
      expect(find.text(t.pastHikes.errorEffort), findsOneWidget);
    });

    testWidgets('jours + distance : la rando est acceptee', (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap('screen', const PastHikesScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.pastHikes.addHike));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, t.pastHikes.fieldDays), '3');
      await tester.enterText(
          find.widgetWithText(TextFormField, t.pastHikes.fieldDistance), '42');
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.pastHikes.save).last);
      await tester.pumpAndSettle();

      // La feuille se ferme et la rando apparait dans la liste (3 jours).
      expect(find.byKey(const ValueKey('past-hike-form-error')), findsNothing);
      expect(find.textContaining('42'), findsWidgets);
    });
  });

  group('m1 — la troncature de la taille ne se fait plus en silence', () {
    testWidgets('« 1280 » est coupe a « 128 » ET signale', (tester) async {
      tester.view.physicalSize = const Size(390, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap('screen', const HikerProfileScreen()));
      await tester.pumpAndSettle();

      final height =
          find.widgetWithText(TextFormField, t.hikerProfile.fieldHeight);
      await tester.enterText(height, '1280');
      await tester.pumpAndSettle();

      // La barriere physique tient (128), mais elle PARLE.
      expect(find.text(t.hikerProfile.errorHeight), findsOneWidget);
      final field = tester.widget<TextField>(
          find.descendant(of: height, matching: find.byType(TextField)));
      expect(field.controller!.text, '128');
    });

    testWidgets('une saisie qui tient dans le champ n affiche rien',
        (tester) async {
      tester.view.physicalSize = const Size(390, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap('screen', const HikerProfileScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, t.hikerProfile.fieldHeight),
          '175');
      await tester.pumpAndSettle();
      expect(find.text(t.hikerProfile.errorHeight), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // m3 (FIX-1) PUIS RETOUR CHRIS #2 (tache 553) — LE PAYS SE CHOISIT.
  //
  // m3 avait bouche un trou : « ZZ » etait accepte sans controle. Le correctif
  // gardait la SAISIE LIBRE d'un code a deux lettres et se contentait de la
  // refuser quand elle etait fausse. Chris, mot pour mot : « Pourquoi on ne peut
  // pas choisir un pays au lieu de mettre un code FR c'est tout pourri ».
  //
  // Le champ est devenu un SELECTEUR : on ne tape plus rien, donc plus une seule
  // saisie invalide n'est possible — le refus « Code pays invalide » est devenu
  // inatteignable DEPUIS L'ECRAN. Les deux tests qui tapaient « ZZ » puis « FR »
  // n'ont donc plus de geste a jouer ; ils sont remplaces par les preuves de ce
  // qui compte maintenant : aucune saisie libre, un nom de pays LISIBLE et
  // LOCALISE, et une validation qui accepte tout ce que le selecteur propose.
  // -------------------------------------------------------------------------
  group('m3 + retour Chris #2 — le pays se CHOISIT, il ne se tape plus', () {
    test('la validation refuse toujours l inexistant, et accepte tout ce que le '
        'selecteur propose', () {
      expect(isValidIsoCountryCode('FR'), isTrue);
      expect(isValidIsoCountryCode('fr'), isTrue, reason: 'casse ignoree');
      expect(isValidIsoCountryCode(' IT '), isTrue, reason: 'espaces ignores');
      // Les codes du rapport personas / non attribues : toujours refuses.
      expect(isValidIsoCountryCode('ZZ'), isFalse);
      expect(isValidIsoCountryCode('XX'), isFalse);
      expect(isValidIsoCountryCode('QQ'), isFalse);
      expect(kIsoCountryCodes.length, greaterThan(200));

      // TACHE 553 — CE QUE LE SELECTEUR PROPOSE, LA VALIDATION L ACCEPTE. Le
      // selecteur offre deux codes que l ISO n attribue pas officiellement (le
      // Kosovo et l ile de l Ascension) : sans cette regle, l application
      // refusait a quelqu un le pays qu elle venait elle-meme de lui proposer.
      for (final code in kSelectableNonIsoCountryCodes) {
        expect(Country.tryParse(code), isNotNull,
            reason: '$code doit bien etre propose par le selecteur');
        expect(isValidIsoCountryCode(code), isTrue,
            reason: '$code est proposable, il doit donc etre enregistrable');
      }
    });

    testWidgets('AUCUNE SAISIE LIBRE : le champ pays n est plus un champ de '
        'texte, et il dit « non precise » tant que rien n est choisi',
        (tester) async {
      tester.view.physicalSize = const Size(390, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap('screen', const HikerProfileScreen()));
      await tester.pumpAndSettle();

      final field = find.byKey(const ValueKey('hiker-profile-country-field'));
      expect(field, findsOneWidget);

      // Plus aucun clavier a l interieur du champ : rien ne peut plus y etre
      // tape, donc aucun « ZZ » ne peut plus y naitre.
      expect(
        find.descendant(of: field, matching: find.byType(EditableText)),
        findsNothing,
        reason: 'le pays se choisit dans une liste, il ne se tape plus',
      );

      // Etat vide d un champ OPTIONNEL : on le dit, on ne laisse pas un blanc.
      expect(
        find.descendant(
          of: field,
          matching: find.text(t.hikerProfile.sexUnspecified),
        ),
        findsOneWidget,
      );
    });

    testWidgets('un pays deja enregistre s affiche avec son NOM LOCALISE, '
        'jamais avec son code', (tester) async {
      tester.view.physicalSize = const Size(390, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Fiche deja saisie, pays = Allemagne.
      await HikerProfileRepository(db: db, prefs: prefs).saveProfile(
        const HikerProfile(
            age: 40, heightCm: 178, weightKg: 75, countryIso: 'DE'),
      );

      await tester.pumpWidget(wrap('screen', const HikerProfileScreen()));
      await tester.pumpAndSettle();

      final field = find.byKey(const ValueKey('hiker-profile-country-field'));
      // « Allemagne », pas « DE » : c est tout l objet du retour #2. Le nom vient
      // du delegue `CountryLocalizations` pose sur l application (langue fr).
      expect(find.descendant(of: field, matching: find.text('Allemagne')),
          findsOneWidget);
      expect(find.descendant(of: field, matching: find.text('DE')),
          findsNothing);
    });

    testWidgets('un code illisible venu d ailleurs (sauvegarde restauree) n est '
        'PAS affiche comme un pays', (tester) async {
      tester.view.physicalSize = const Size(390, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // L ecran ne peut plus PRODUIRE « ZZ », mais il peut encore en LIRE un :
      // la restauration d une sauvegarde et le miroir cloud rendent la valeur
      // telle qu elle est stockee, sans la verifier.
      await HikerProfileRepository(db: db, prefs: prefs).saveProfile(
        const HikerProfile(
            age: 40, heightCm: 178, weightKg: 75, countryIso: 'ZZ'),
      );

      await tester.pumpWidget(wrap('screen', const HikerProfileScreen()));
      await tester.pumpAndSettle();

      final field = find.byKey(const ValueKey('hiker-profile-country-field'));
      expect(
          find.descendant(of: field, matching: find.text('ZZ')), findsNothing);
      // Le champ repart a « non precise » : deux taps suffisent a rechoisir.
      expect(
        find.descendant(
          of: field,
          matching: find.text(t.hikerProfile.sexUnspecified),
        ),
        findsOneWidget,
      );
    });

    testWidgets('CHOISIR dans la liste : le pays selectionne remplace « non '
        'precise » et l enregistrement passe sans message', (tester) async {
      tester.view.physicalSize = const Size(390, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap('screen', const HikerProfileScreen()));
      await tester.pumpAndSettle();

      final field = find.byKey(const ValueKey('hiker-profile-country-field'));
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await tester.tap(field);
      await tester.pumpAndSettle();

      // La feuille de selection est ouverte : sa barre de recherche est le
      // dernier champ de texte monte (elle vit dans une route posee AU-DESSUS
      // de l ecran).
      await tester.enterText(find.byType(TextField).last, 'Allemagne');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Allemagne').last);
      await tester.pumpAndSettle();

      // Le champ porte desormais le pays choisi, ecrit en clair.
      expect(find.descendant(of: field, matching: find.text('Allemagne')),
          findsOneWidget);
      expect(
        find.descendant(
          of: field,
          matching: find.text(t.hikerProfile.sexUnspecified),
        ),
        findsNothing,
      );

      // Et l enregistrement ne peut plus buter sur un code pays : il n y a plus
      // de code pays a se tromper.
      await tester.enterText(
          find.widgetWithText(TextFormField, t.hikerProfile.fieldAge), '40');
      final save = find.text(t.hikerProfile.save);
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(find.text(t.hikerProfile.errorCountry), findsNothing);
    });
  });
}
