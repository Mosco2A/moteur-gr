import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/feasibility/data/hiker_profile_repository.dart';
import 'package:moteur_gr/features/feasibility/domain/hiker_input_bounds.dart';
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

  group('m3 — code pays : un code inexistant est refuse', () {
    test('la liste ISO 3166-1 alpha-2 fait autorite', () {
      expect(isValidIsoCountryCode('FR'), isTrue);
      expect(isValidIsoCountryCode('fr'), isTrue, reason: 'casse ignoree');
      expect(isValidIsoCountryCode(' IT '), isTrue, reason: 'espaces ignores');
      // Les codes du rapport personas / non attribues.
      expect(isValidIsoCountryCode('ZZ'), isFalse);
      expect(isValidIsoCountryCode('XX'), isFalse);
      expect(isValidIsoCountryCode('QQ'), isFalse);
      expect(kIsoCountryCodes.length, greaterThan(200));
    });

    testWidgets('« ZZ » bloque l enregistrement avec un message',
        (tester) async {
      tester.view.physicalSize = const Size(390, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap('screen', const HikerProfileScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const ValueKey('hiker-profile-country-field')), 'ZZ');
      await tester.pumpAndSettle();

      final save = find.text(t.hikerProfile.save);
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(find.text(t.hikerProfile.errorCountry), findsOneWidget);
      // L'ecran n'a PAS ete quitte : rien n'a ete enregistre.
      expect(find.text(t.hikerProfile.title), findsWidgets);
    });

    testWidgets('« FR » passe sans message', (tester) async {
      tester.view.physicalSize = const Size(390, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap('screen', const HikerProfileScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const ValueKey('hiker-profile-country-field')), 'FR');
      await tester.pumpAndSettle();

      final save = find.text(t.hikerProfile.save);
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(find.text(t.hikerProfile.errorCountry), findsNothing);
    });
  });
}
