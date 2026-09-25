// TACHE 562 (LOT K, K1) — LE DROIT A L'EFFACEMENT N'AVAIT AUCUN BOUTON.
//
// POURQUOI CE FICHIER EXISTE. Au terme du LOT J, `deleteAccountData` etait
// CORRECT et prouve par vingt-six tests : il efface vingt-et-une tables et
// cinquante-cinq cles de preferences. Il n'avait AUCUN APPELANT. Aucun ecran,
// aucun bouton, aucun chemin ne l'offrait au randonneur. Un droit qu'on ne peut
// pas exercer n'est pas un droit : on avait repare une porte sans poignee.
//
// CE QUE CES TESTS EXIGENT, ET COMMENT. Ils n'inspectent aucun mock : ils
// branchent l'ecran des Reglages sur une VRAIE base en memoire et de VRAIES
// preferences, remplissent l'appareil comme celui d'un randonneur qui a
// marche, puis passent par les gestes reels (toucher la commande, lire, cocher,
// confirmer) et relisent ce qui reste sur l'appareil. Le premier test etait
// ROUGE avant la correction — l'ecran ne portait pas la commande.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/settings/presentation/settings_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SharedPreferences prefs;

  /// L'appareil d'un randonneur qui a reellement utilise l'application : sa
  /// fiche (donnee de sante), son pseudo, ses reservations, ses points GPS
  /// bruts... et l'etage monetaire, qui doit SURVIVRE (K4).
  const appareilRempli = <String, Object>{
    'hiker.profile': '{"age":72,"heightCm":172,"weightKg":88}',
    'hiker.walkTestResult': '{"distanceMeters":420,"level":"slow"}',
    'auth_display_name': 'Gerard',
    'accommodation_bookings': '[{"refuge":"Ortu"}]',
    'bg_gps_points_buffer': '[[42.1,9.1]]',
    'consent_healthData': '{"granted":true}',
    // Etage monetaire : conserve, et le libelle doit le DIRE au randonneur.
    'wallet.balanceSteps': 12,
    'wallet.deliveredPurchaseIds': <String>['achat-1'],
    'purchased_trail_ids': <String>['gr20'],
    // Reglage d'affichage : conserve (il ne dit rien de la personne).
    'settings_language': 'fr',
  };

  setUp(() async {
    SharedPreferences.setMockInitialValues(appareilRempli);
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'stepways.recovery.code.v1': 'ABCD-EFGH-JKMN-PQRS',
    });
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase(NativeDatabase.memory());
    LocaleSettings.setLocaleRaw('fr');
  });

  tearDown(() async {
    await db.close();
    LocaleSettings.setLocaleRaw('fr');
  });

  Widget wrap() {
    return ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: TranslationProvider(
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/settings',
            routes: [
              GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
              GoRoute(path: '/consent', builder: (_, __) => const SizedBox()),
              GoRoute(path: '/recovery-code', builder: (_, __) => const SizedBox()),
              GoRoute(path: '/my-treks', builder: (_, __) => const SizedBox()),
            ],
          ),
        ),
      ),
    );
  }

  /// Ouvre les Reglages sur un ecran assez haut pour que le ListView paresseux
  /// construise toutes ses sections (l'effacement est en bas de page).
  ///
  /// Largeur 900 et non 400 : la police des tests rend CHAQUE caractere dans un
  /// carre de la taille du texte, donc un titre de section de trente
  /// caracteres y occupe 480 px la ou il en prend 200 sur un telephone reel.
  /// Un viewport etroit ferait deborder des en-tetes qui ne debordent nulle
  /// part en vrai — on ne teste pas une regression imaginaire.
  Future<void> ouvrirReglages(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
  }

  final tr = t.erasure;

  group('K1 — la commande d effacement existe la ou le randonneur la cherche',
      () {
    testWidgets('les REGLAGES portent la commande, a cote de la vie privee',
        (tester) async {
      await ouvrirReglages(tester);

      // LE ROUGE HISTORIQUE : ce libelle n'existait nulle part dans l'app.
      expect(find.text(tr.entry), findsWidgets,
          reason: 'aucun chemin n offre le droit a l effacement au randonneur');

      // Et il est dans le voisinage de la vie privee, pas perdu ailleurs : les
      // deux entrees sont sur le meme ecran.
      expect(find.text(t.consent.settingsEntry), findsWidgets);
    });

    testWidgets('le libelle DIT ce qui part, ce qui reste, et que c est '
        'definitif', (tester) async {
      await ouvrirReglages(tester);
      await tester.tap(find.text(tr.entry).last);
      await tester.pumpAndSettle();

      expect(find.text(tr.dialogTitle), findsOneWidget);
      expect(find.text(tr.goes), findsOneWidget,
          reason: 'ce qui part doit etre ecrit, pas devine');
      expect(find.text(tr.stays), findsOneWidget,
          reason: 'K4 : la conservation des achats doit etre DITE');
      expect(find.text(tr.finalWarning), findsOneWidget,
          reason: 'le caractere definitif doit etre annonce avant le geste');
      // La conservation des achats est bien ce qui est ecrit (et pas une
      // formule creuse) : le texte parle de ce qui a ete paye.
      expect(tr.stays.toLowerCase(), contains('pay'),
          reason: 'le randonneur doit lire que ses achats survivent');
    });

    testWidgets('UN SIMPLE TAP N EFFACE RIEN : la confirmation est explicite',
        (tester) async {
      await ouvrirReglages(tester);
      await tester.tap(find.text(tr.entry).last);
      await tester.pumpAndSettle();

      // La case n'est pas cochee : le bouton definitif refuse de partir.
      await tester.tap(find.text(tr.confirm));
      await tester.pumpAndSettle();

      expect(find.text(tr.dialogTitle), findsOneWidget,
          reason: 'le dialogue ne doit pas se fermer sans confirmation cochee');
      expect((await SharedPreferences.getInstance()).getString('hiker.profile'),
          isNotNull,
          reason: 'RIEN ne doit etre efface sans confirmation explicite');
    });

    testWidgets('ANNULER ne touche a rien', (tester) async {
      await ouvrirReglages(tester);
      await tester.tap(find.text(tr.entry).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(tr.cancel));
      await tester.pumpAndSettle();

      expect(find.text(tr.dialogTitle), findsNothing);
      expect(prefs.getString('hiker.profile'), isNotNull);
    });

    testWidgets('COCHEE PUIS CONFIRMEE : l effacement a REELLEMENT lieu, et '
        'l ecran le dit', (tester) async {
      await ouvrirReglages(tester);
      await tester.tap(find.text(tr.entry).last);
      await tester.pumpAndSettle();

      await tester.tap(find.text(tr.confirmCheckbox));
      await tester.pumpAndSettle();
      await tester.tap(find.text(tr.confirm));
      await tester.pumpAndSettle();

      final apres = await SharedPreferences.getInstance();
      // CE QUI PART, mesure sur l'appareil (pas sur une intention).
      for (final cle in <String>[
        'hiker.profile',
        'hiker.walkTestResult',
        'auth_display_name',
        'accommodation_bookings',
        'bg_gps_points_buffer',
        'consent_healthData',
      ]) {
        expect(apres.get(cle), isNull, reason: '« $cle » a survecu');
      }
      // Le code de reconnexion aussi (K2), puisque c'est le meme geste.
      expect(
        await const FlutterSecureStorage().read(key: 'stepways.recovery.code.v1'),
        isNull,
        reason: 'le code qui ouvre le coffre ailleurs doit partir',
      );
      // CE QUI RESTE : l'etage monetaire et les reglages d'affichage.
      expect(apres.getInt('wallet.balanceSteps'), 12,
          reason: 'K4 : on ne reprend pas au randonneur ce qu il a paye');
      expect(apres.getStringList('purchased_trail_ids'), <String>['gr20']);
      expect(apres.getString('settings_language'), 'fr');

      // LE RETOUR A L ECRAN : le dialogue est ferme et l ecran confirme.
      expect(find.text(tr.dialogTitle), findsNothing);
      expect(find.text(tr.done), findsOneWidget,
          reason: 'le randonneur doit savoir que c est fait');
    });
  });

  group('K1 — le libelle existe dans les cinq langues', () {
    test('aucune cle vide, et les trois annonces sont presentes partout', () {
      for (final locale in AppLocale.values) {
        final loc = locale.languageCode;
        final tl = locale.buildSync().erasure;
        for (final entry in <String, String>{
          'section': tl.section,
          'entry': tl.entry,
          'entryDesc': tl.entryDesc,
          'dialogTitle': tl.dialogTitle,
          'goesTitle': tl.goesTitle,
          'goes': tl.goes,
          'staysTitle': tl.staysTitle,
          'stays': tl.stays,
          'finalWarning': tl.finalWarning,
          'confirmCheckbox': tl.confirmCheckbox,
          'confirm': tl.confirm,
          'cancel': tl.cancel,
          'done': tl.done,
          'error': tl.error,
          'a11yEntry': tl.a11y.entry,
        }.entries) {
          expect(entry.value.trim(), isNotEmpty,
              reason: '$loc : erasure.${entry.key} est vide');
        }
        // Pas de repli silencieux sur le francais : chaque langue a son texte.
        if (loc != 'fr') {
          expect(tl.goes, isNot(AppLocale.fr.buildSync().erasure.goes),
              reason: '$loc : « ce qui part » est reste en francais');
          expect(tl.stays, isNot(AppLocale.fr.buildSync().erasure.stays),
              reason: '$loc : « ce qui reste » est reste en francais');
        }
      }
    });

    test('la note de sauvegarde sante est traduite dans les cinq langues', () {
      for (final locale in AppLocale.values) {
        final note = locale.buildSync().consent.healthBackupNote;
        expect(note.trim(), isNotEmpty,
            reason: '${locale.languageCode} : healthBackupNote est vide');
      }
    });
  });
}
