// LOT 671-01 (E3, E7-9) — L'ECRAN CACHE DE MESURE BATTERIE.
//
// CE QUE CE FICHIER PROUVE :
//  - l'ecran n'est PAS atteignable par un appui court sur le numero de
//    version, et un appui long l'ouvre ;
//  - chaque bouton radio ecrit le bon profil, et l'ecran montre le choix ;
//  - le bloc d'etat montre profil, batterie, fichier, nombre de lignes et les
//    cinq dernieres lignes ; un journal absent est dit, pas un plantage ;
//  - un refus d'autorisation laisse l'ecran utilisable, le dit, et ne
//    redemande rien ; une autorisation deja accordee ne redemande rien.
//
// Le banc de mesure est un faux : aucun capteur, aucun canal de plateforme.
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/gps_cadence.dart';
import 'package:moteur_gr/core/services/journal_de_mesure.dart';
import 'package:moteur_gr/features/settings/presentation/mesure_batterie_screen.dart';
import 'package:moteur_gr/features/settings/presentation/settings_screen.dart';
import 'package:moteur_gr/features/trek/trek_facade.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un journal dont le contenu est donne d'avance, sans disque.
class _JournalFige extends MeasureJournal {
  _JournalFige(this.etat) : super(directory: () async => Directory.systemTemp);

  final MeasureJournalSnapshot etat;

  @override
  Future<MeasureJournalSnapshot> snapshot({int last = 5}) async => etat;
}

/// Un faux banc : note les profils ecrits et les demandes d'autorisation.
class _FauxBanc {
  _FauxBanc({
    this.autorise = false,
    this.accordeALaDemande = false,
    MeasureJournalSnapshot? journal,
  }) : journal =
           journal ??
           const MeasureJournalSnapshot(
             path: '/faux/journal_de_mesure.txt',
             exists: false,
             lineCount: 0,
             lastLines: [],
           );

  PositionProfile profil = PositionProfile.map;
  final ecrits = <PositionProfile>[];
  bool autorise;
  final bool accordeALaDemande;
  int demandes = 0;
  final MeasureJournalSnapshot journal;

  MeasureBench get banc => MeasureBench(
    readProfile: () async => profil,
    chooseProfile: (p) async {
      ecrits.add(p);
      profil = p;
    },
    readBattery: () async => 67,
    journal: _JournalFige(journal),
    stepsAllowed: () async => autorise,
    requestSteps: () async {
      demandes++;
      autorise = accordeALaDemande;
      return accordeALaDemande;
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    db = AppDatabase(NativeDatabase.memory());
    LocaleSettings.setLocaleRaw('fr');
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> ouvrir(
    WidgetTester tester,
    _FauxBanc faux, {
    String depart = '/mesure-batterie',
  }) async {
    tester.view.physicalSize = const Size(900, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          measureBenchProvider.overrideWithValue(faux.banc),
        ],
        child: TranslationProvider(
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: depart,
              routes: [
                GoRoute(
                  path: '/settings',
                  builder: (_, _) => const SettingsScreen(),
                ),
                GoRoute(
                  path: '/mesure-batterie',
                  builder: (_, _) => const MesureBatterieScreen(),
                ),
                for (final autre in [
                  '/consent',
                  '/recovery-code',
                  '/my-treks',
                  '/home',
                ])
                  GoRoute(path: autre, builder: (_, _) => const SizedBox()),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final version = find.byKey(const ValueKey('reglages-numero-de-version'));

  group('671-01 (9) — l ecran n a qu une porte, l appui long', () {
    testWidgets('un appui COURT sur le numero de version n ouvre pas l ecran '
        'de mesure', (tester) async {
      await ouvrir(tester, _FauxBanc(), depart: '/settings');
      await tester.ensureVisible(version);
      await tester.pumpAndSettle();
      await tester.tap(version);
      await tester.pumpAndSettle();
      expect(find.byType(MesureBatterieScreen), findsNothing);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('un appui LONG sur le numero de version ouvre l ecran de '
        'mesure', (tester) async {
      await ouvrir(tester, _FauxBanc(), depart: '/settings');
      await tester.ensureVisible(version);
      await tester.pumpAndSettle();
      await tester.longPress(version);
      await tester.pumpAndSettle();
      expect(find.byType(MesureBatterieScreen), findsOneWidget);
      expect(find.text('Profil en vigueur : GPS continu actuel'), findsOne);
    });
  });

  group('671-01 (9) — les trois profils', () {
    testWidgets('chaque radio ecrit le bon profil, et l ecran montre le '
        'choix', (tester) async {
      final faux = _FauxBanc();
      await ouvrir(tester, faux);
      for (final profil in [
        PositionProfile.batteryFirst,
        PositionProfile.lowBattery,
        PositionProfile.map,
      ]) {
        await tester.tap(find.byKey(ValueKey('mesure-profil-${profil.name}')));
        await tester.pumpAndSettle();
        expect(faux.ecrits.last, profil);
        expect(
          find.text('Profil en vigueur : ${measureProfileTitle(profil)}'),
          findsOneWidget,
        );
        expect(find.byType(SnackBar), findsOneWidget);
        ScaffoldMessenger.of(
          tester.element(find.byType(MesureBatterieScreen)),
        ).removeCurrentSnackBar();
        await tester.pumpAndSettle();
      }
      expect(faux.ecrits, [
        PositionProfile.batteryFirst,
        PositionProfile.lowBattery,
        PositionProfile.map,
      ]);
    });
  });

  group('671-01 (9) — l etat et le partage', () {
    testWidgets('le bloc d etat montre le fichier, le nombre de lignes et les '
        'cinq dernieres lignes telles quelles', (tester) async {
      final dernieres = [
        for (var i = 1; i <= 5; i++)
          '2026-10-06T09:0$i:00;batterieDabord;releve;80;-;42.000000,9.000000;'
              '4.0;-;3.$i',
      ];
      await ouvrir(
        tester,
        _FauxBanc(
          journal: MeasureJournalSnapshot(
            path: '/faux/journal_de_mesure.txt',
            exists: true,
            lineCount: 37,
            lastLines: dernieres,
          ),
        ),
      );
      expect(find.text('Batterie : 67 %'), findsOneWidget);
      expect(find.text('Fichier : journal_de_mesure.txt'), findsOneWidget);
      expect(find.text('Lignes écrites : 37'), findsOneWidget);
      for (final l in dernieres) {
        expect(find.text(l), findsOneWidget);
      }
    });

    testWidgets('sans journal, le partage le dit au lieu de planter', (
      tester,
    ) async {
      final partages = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('dev.fluttercommunity.plus/share'),
            (appel) async {
              partages.add(appel);
              return null;
            },
          );
      await ouvrir(tester, _FauxBanc());
      await tester.tap(find.byKey(const ValueKey('mesure-partager')));
      await tester.pumpAndSettle();
      expect(partages, isEmpty);
      expect(
        find.textContaining('Le journal n’existe pas encore'),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('671-01 (9) — l autorisation de compter les pas', () {
    testWidgets('un refus laisse l ecran utilisable, le dit, et ne redemande '
        'jamais', (tester) async {
      final faux = _FauxBanc();
      await ouvrir(tester, faux);
      final bouton = find.byKey(const ValueKey('mesure-autoriser-pas'));

      await tester.tap(bouton);
      await tester.pumpAndSettle();
      // La phrase de randonneur PRECEDE la demande du systeme.
      expect(find.textContaining('compte vos pas'), findsOneWidget);
      expect(faux.demandes, 0);
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      expect(faux.demandes, 1);
      expect(find.textContaining('sans les pas'), findsOneWidget);
      expect(find.text('Autorisation refusée'), findsOneWidget);
      // Pas de redemande : le bouton est eteint.
      await tester.tap(bouton);
      await tester.pumpAndSettle();
      expect(faux.demandes, 1);
      expect(find.byType(AlertDialog), findsNothing);
      // L'ecran reste utilisable : un profil se choisit encore.
      await tester.tap(find.byKey(const ValueKey('mesure-profil-lowBattery')));
      await tester.pumpAndSettle();
      expect(faux.ecrits, [PositionProfile.lowBattery]);
    });

    testWidgets('accordee a la demande, le bouton l indique et le journal '
        'notera les pas', (tester) async {
      final faux = _FauxBanc(accordeALaDemande: true);
      await ouvrir(tester, faux);
      await tester.tap(find.byKey(const ValueKey('mesure-autoriser-pas')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      expect(faux.demandes, 1);
      expect(find.text('Comptage des pas autorisé'), findsOneWidget);
      expect(find.textContaining('le journal note vos pas'), findsOneWidget);
    });

    testWidgets('deja accordee, le bouton l indique et ne redemande rien', (
      tester,
    ) async {
      final faux = _FauxBanc(autorise: true);
      await ouvrir(tester, faux);
      expect(find.text('Comptage des pas autorisé'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('mesure-autoriser-pas')));
      await tester.pumpAndSettle();
      expect(faux.demandes, 0);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
