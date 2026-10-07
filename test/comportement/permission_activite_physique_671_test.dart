// LOT 671-02 (E2, E7-8) — L'AUTORISATION D'ACTIVITE PHYSIQUE, EXPLIQUEE AVANT
// D'ETRE DEMANDEE, ET LE REFUS QUI NE CASSE RIEN.
//
// CE QUE CE FICHIER PROUVE, sur le VRAI bouton « Démarrer la randonnée » :
//  - l'explication est a l'ecran AVANT que la demande du systeme ne parte ;
//  - un refus laisse l'application PLEINEMENT utilisable : rejoue sur TROIS
//    demarrages de trek d'affilee, le trek demarre trois fois, une phrase dit
//    pourquoi une fois, et le systeme n'est sollicite qu'UNE fois ;
//  - un refus DEFINITIF mene aux reglages du systeme, jamais a une redemande ;
//  - la ligne des reglages, elle, redemande : c'est le seul chemin ;
//  - deux demarrages simultanes ne lancent qu'UNE demande.
//
// Le systeme est un faux : aucun canal de plateforme, aucun capteur.
library;

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/core/services/session_demo.dart';
import 'package:moteur_gr/features/hub/presentation/widgets/hub_start_trek_button.dart';
import 'package:moteur_gr/features/hub/providers/cockpit_start_providers.dart';
import 'package:moteur_gr/features/trek/data/podometre_permission_service.dart';
import 'package:moteur_gr/features/trek/presentation/podometre_autorisation.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/services/location_permission_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Le systeme d'exploitation, en faux : il compte ce qu'on lui demande.
class _Systeme {
  _Systeme(this.statut, {this.reponse = PermissionStatus.denied});

  PermissionStatus statut;
  final PermissionStatus reponse;
  int demandes = 0;
  int reglagesOuverts = 0;
  Completer<void>? retenue;

  PodometerPermissionService service() => PodometerPermissionService(
    readStatus: () async => statut,
    request: () async {
      demandes++;
      await retenue?.future;
      statut = reponse;
      return reponse.isGranted;
    },
    openSettings: () async {
      reglagesOuverts++;
      return true;
    },
  );
}

/// Les droits de realiser : accordes.
class _Droits extends Fake implements MonetizationService {
  @override
  Future<bool> canRealizeTrail(String trailId) async => true;
}

/// La localisation de fond : deja tout accorde, rien a demander.
class _FondAccorde extends Fake implements LocationPermissionService {
  @override
  Future<bool> shouldAskBackgroundRationale() async => false;
}

/// Un gestionnaire de trek qui compte les demarrages, sans base ni GPS.
class _TrekCompte extends TrekSessionManagerNotifier {
  int demarrages = 0;

  @override
  TrackingSessionState build() => const TrackingSessionState();

  @override
  Future<StartOutcome> ensureSingleActiveThenStart(
    String trailId, {
    required ActiveTrekConflictResolver resolve,
  }) async {
    demarrages++;
    return StartOutcome.started;
  }
}

void main() {
  const trailId = 'sentier-671';
  final tr = t.tracking.stepCounting;

  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    LocaleSettings.setLocaleRaw('fr');
  });

  tearDown(() async {
    await db.close();
  });

  /// Le VRAI bouton « Démarrer la randonnée », au point de depart, droits
  /// accordes ; la carte est une page qui dit « CARTE ».
  Future<(GoRouter, _TrekCompte)> monterLeDepart(
    WidgetTester tester,
    _Systeme systeme,
  ) async {
    final trek = _TrekCompte();
    final routeur = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(
            body: SingleChildScrollView(
              child: HubStartTrekButton(trailId: trailId),
            ),
          ),
        ),
        GoRoute(
          path: '/map',
          builder: (_, _) => const Scaffold(body: Text('CARTE')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          enDemoProvider.overrideWithValue(false),
          prepareCoreDoneProvider(trailId).overrideWithValue(true),
          startProximityProvider.overrideWithValue(
            const StartProximity(
              atDeparture: true,
              distanceMeters: 0,
              gpsAvailable: true,
            ),
          ),
          monetizationServiceProvider.overrideWithValue(_Droits()),
          locationPermissionServiceProvider.overrideWithValue(_FondAccorde()),
          podometerPermissionServiceProvider.overrideWithValue(
            systeme.service(),
          ),
          trekSessionManagerProvider.overrideWith(() => trek),
        ],
        child: TranslationProvider(
          child: MaterialApp.router(routerConfig: routeur),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (routeur, trek);
  }

  Future<void> demarrer(WidgetTester tester) async {
    await tester.tap(find.text(t.hub.startCta));
    await tester.pumpAndSettle();
  }

  group('671-02 (8) — l explication precede la demande', () {
    testWidgets('au demarrage d un trek, la phrase est a l ecran AVANT que la '
        'demande du systeme ne parte', (tester) async {
      final systeme = _Systeme(PermissionStatus.denied);
      await monterLeDepart(tester, systeme);
      await demarrer(tester);

      expect(find.text(tr.title), findsOneWidget);
      expect(find.text(tr.body), findsOneWidget);
      expect(find.text(tr.ifRefused), findsOneWidget);
      expect(systeme.demandes, 0, reason: 'une demande seche est partie');

      await tester.tap(find.text(tr.allow));
      await tester.pumpAndSettle();
      expect(systeme.demandes, 1);
    });

    testWidgets('accordee, aucune explication et aucune demande', (
      tester,
    ) async {
      final systeme = _Systeme(PermissionStatus.granted);
      final (_, trek) = await monterLeDepart(tester, systeme);
      await demarrer(tester);
      expect(find.text(tr.title), findsNothing);
      expect(systeme.demandes, 0);
      expect(trek.demarrages, 1);
    });
  });

  group('671-02 (8) — le refus est un etat normal', () {
    testWidgets('TROIS demarrages de trek apres un refus : le trek demarre '
        'trois fois, une phrase dit pourquoi, et le systeme n est sollicite '
        'qu UNE fois', (tester) async {
      final systeme = _Systeme(PermissionStatus.denied);
      final (routeur, trek) = await monterLeDepart(tester, systeme);

      // Premier depart : explication, demande, REFUS au systeme.
      await demarrer(tester);
      await tester.tap(find.text(tr.allow));
      await tester.pumpAndSettle();
      expect(
        trek.demarrages,
        1,
        reason:
            'le refus doit laisser l application utilisable : le trek doit '
            'demarrer quand le randonneur refuse de compter ses pas',
      );
      expect(find.text('CARTE'), findsOneWidget);
      expect(find.text(tr.whyGps), findsOneWidget);

      // Deuxieme et troisieme departs : rien ne se redemande tout seul.
      for (var depart = 2; depart <= 3; depart++) {
        routeur.go('/home');
        await tester.pumpAndSettle();
        await demarrer(tester);
        expect(find.text(tr.title), findsNothing, reason: 'depart $depart');
        expect(
          trek.demarrages,
          depart,
          reason:
              'le refus doit laisser l application utilisable : depart '
              '$depart bloque',
        );
      }
      expect(systeme.demandes, 1);
    });

    testWidgets('« Plus tard » : aucune demande, le refus est retenu, le trek '
        'demarre', (tester) async {
      final systeme = _Systeme(PermissionStatus.denied);
      final (_, trek) = await monterLeDepart(tester, systeme);
      await demarrer(tester);
      await tester.tap(find.text(tr.later));
      await tester.pumpAndSettle();

      expect(systeme.demandes, 0);
      expect(
        trek.demarrages,
        1,
        reason:
            'le refus doit laisser l application utilisable : « Plus tard » '
            'a bloque le depart',
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(PodometerPermissionService.kDeclinedKey), isTrue);
    });

    testWidgets('un refus DEFINITIF ne redemande pas au demarrage : le trek '
        'demarre, sans explication ni demande', (tester) async {
      final systeme = _Systeme(PermissionStatus.permanentlyDenied);
      final (_, trek) = await monterLeDepart(tester, systeme);
      await demarrer(tester);
      expect(find.text(tr.title), findsNothing);
      expect(systeme.demandes, 0);
      expect(trek.demarrages, 1);
    });
  });

  group('671-02 (8) — deux demarrages simultanes', () {
    test(
      'ne montrent qu UNE explication et ne lancent qu UNE demande',
      () async {
        final systeme = _Systeme(PermissionStatus.denied)
          ..retenue = Completer();
        final service = systeme.service();
        var explications = 0;
        Future<bool?> expliquer() async {
          explications++;
          return true;
        }

        final a = service.explainAtTrekStart(
          explain: expliquer,
          onRefused: () {},
        );
        final b = service.explainAtTrekStart(
          explain: expliquer,
          onRefused: () {},
        );
        await Future<void>.delayed(Duration.zero);
        systeme.retenue!.complete();
        await Future.wait([a, b]);
        expect(explications, 1);
        expect(systeme.demandes, 1);
      },
    );

    test('deux demandes concurrentes n en font qu une au systeme', () async {
      final systeme = _Systeme(
        PermissionStatus.denied,
        reponse: PermissionStatus.granted,
      )..retenue = Completer();
      final service = systeme.service();
      final a = service.request();
      final b = service.request();
      systeme.retenue!.complete();
      expect(await Future.wait([a, b]), [
        PodometerAccess.granted,
        PodometerAccess.granted,
      ]);
      expect(systeme.demandes, 1);
    });
  });

  group('671-02 (8) — la ligne des reglages, seul chemin de redemande', () {
    Future<void> monterLaLigne(WidgetTester tester, _Systeme systeme) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            podometerPermissionServiceProvider.overrideWithValue(
              systeme.service(),
            ),
          ],
          child: TranslationProvider(
            child: const MaterialApp(
              home: Scaffold(body: PodometerSettingsTile()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    final ligne = find.byKey(const ValueKey('reglages-compte-des-pas'));

    testWidgets('refus deja retenu : la ligne dit l etat, et l appui '
        'redemande apres l explication', (tester) async {
      SharedPreferences.setMockInitialValues({
        PodometerPermissionService.kDeclinedKey: true,
      });
      final systeme = _Systeme(
        PermissionStatus.denied,
        reponse: PermissionStatus.granted,
      );
      await monterLaLigne(tester, systeme);
      expect(find.text(tr.stateDenied), findsOneWidget);

      await tester.tap(ligne);
      await tester.pumpAndSettle();
      expect(find.text(tr.title), findsOneWidget);
      expect(systeme.demandes, 0);
      await tester.tap(find.text(tr.allow));
      await tester.pumpAndSettle();

      expect(systeme.demandes, 1);
      expect(find.text(tr.stateGranted), findsOneWidget);
    });

    testWidgets('refus DEFINITIF : l appui ouvre les reglages du systeme, '
        'jamais une redemande', (tester) async {
      final systeme = _Systeme(PermissionStatus.permanentlyDenied);
      await monterLaLigne(tester, systeme);
      expect(find.text(tr.statePermanentlyDenied), findsOneWidget);

      await tester.tap(ligne);
      await tester.pumpAndSettle();
      expect(systeme.reglagesOuverts, 1);
      expect(systeme.demandes, 0);
      expect(find.text(tr.title), findsNothing);
    });

    testWidgets('accordee ou sans podometre : la ligne dit l etat et n offre '
        'aucun geste', (tester) async {
      for (final (statut, phrase) in [
        (PermissionStatus.granted, tr.stateGranted),
        (PermissionStatus.restricted, tr.stateUnavailable),
      ]) {
        final systeme = _Systeme(statut);
        await monterLaLigne(tester, systeme);
        expect(find.text(phrase), findsOneWidget);
        expect(tester.widget<ListTile>(ligne).onTap, isNull);
      }
    });
  });
}
