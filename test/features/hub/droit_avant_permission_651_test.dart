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
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/services/location_permission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// NON-REGRESSION — TACHE 651, DEFAUT C (MINEUR) : ON DEMANDAIT LA
/// LOCALISATION « TOUJOURS », PUIS ON REFUSAIT LA RANDONNEE FAUTE D'ACHAT.
///
/// CE QUI SE PASSAIT. `_start()` appelait `ensureBackgroundTrackingExplained`
/// AVANT `ensureSingleActiveThenStart`, la seule etape qui regarde le droit de
/// realiser. Sur un sentier non achete, le randonneur voyait donc, dans cet
/// ordre : l'explication du suivi de fond, l'ecran systeme « Autoriser tout le
/// temps ? », puis « la realisation demande d'avoir debloque ce sentier ». La
/// permission la plus lourde du systeme — celle qui suit ses pas application
/// fermee — etait obtenue pour un service qu'on allait lui refuser.
///
/// LA REGLE VERROUILLEE ICI : le DROIT d'abord, la PERMISSION ensuite. Rien
/// n'est demande au systeme avant de savoir qu'on a quelque chose a rendre.
void main() {
  const trailId = 'sentier-test';

  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  /// Monte le CTA « Démarrer la randonnée », porte de preparation OUVERTE et
  /// randonneur AU POINT DE DEPART (aucun dialogue de proximite en travers).
  Widget wrap({
    required bool droitDeRealiser,
    required _Permissions permissions,
    bool enDemo = false,
  }) {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(
            body: SingleChildScrollView(
              child: HubStartTrekButton(trailId: trailId),
            ),
          ),
        ),
        GoRoute(path: '/map', builder: (_, __) => const SizedBox()),
      ],
    );
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        enDemoProvider.overrideWithValue(enDemo),
        prepareCoreDoneProvider(trailId).overrideWithValue(true),
        startProximityProvider.overrideWithValue(
          const StartProximity(
            atDeparture: true,
            distanceMeters: 0,
            gpsAvailable: true,
          ),
        ),
        monetizationServiceProvider.overrideWithValue(_Droits(droitDeRealiser)),
        locationPermissionServiceProvider.overrideWithValue(permissions),
      ],
      child: TranslationProvider(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  Future<void> appuyerSurDemarrer(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.hub.startCta));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'DEFAUT C — sentier NON achete : le refus arrive SANS avoir demande la '
    'localisation « Toujours »',
    (tester) async {
      final permissions = _Permissions();
      await tester.pumpWidget(
        wrap(droitDeRealiser: false, permissions: permissions),
      );
      await appuyerSurDemarrer(tester);

      // Le refus est dit, avec sa raison et son chemin d'achat.
      expect(
        find.byKey(const ValueKey('realisation-verrouillee')),
        findsOneWidget,
      );

      // ET RIEN N'A ETE DEMANDE AU SYSTEME : ni l'explication dans
      // l'application, ni l'ecran systeme derriere.
      expect(
        find.byKey(const ValueKey('background-tracking-rationale-dialog')),
        findsNothing,
      );
      expect(
        permissions.consulte,
        isFalse,
        reason:
            'on demandait la permission de fond AVANT de regarder le droit '
            'de realiser : permission lourde obtenue pour un service refuse',
      );
      expect(permissions.escaladeDemandee, isFalse);
    },
  );

  testWidgets(
    'SENTIER ACHETE — la permission de fond est bien demandee (l ordre '
    'inverse ne supprime rien)',
    (tester) async {
      final permissions = _Permissions();
      await tester.pumpWidget(
        wrap(droitDeRealiser: true, permissions: permissions),
      );
      await appuyerSurDemarrer(tester);

      expect(
        find.byKey(const ValueKey('background-tracking-rationale-dialog')),
        findsOneWidget,
        reason:
            'MAJEUR-1 (21/09) : on explique DANS l application avant que le '
            'systeme ne pose sa question. Le droit d abord ne doit pas avoir '
            'supprime l explication.',
      );
      expect(permissions.consulte, isTrue);
      expect(
        find.byKey(const ValueKey('realisation-verrouillee')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'EN DEMO — ni droit demande, ni permission demandee (tache 638, bug 16)',
    (tester) async {
      final permissions = _Permissions();
      await tester.pumpWidget(
        wrap(droitDeRealiser: false, permissions: permissions, enDemo: true),
      );
      await appuyerSurDemarrer(tester);

      expect(permissions.consulte, isFalse);
      expect(
        find.byKey(const ValueKey('realisation-verrouillee')),
        findsNothing,
      );
    },
  );
}

/// Droits de realisation injectes (meme source que la garde d'unicite).
class _Droits extends Fake implements MonetizationService {
  _Droits(this.autorise);
  final bool autorise;

  @override
  Future<bool> canRealizeTrail(String trailId) async => autorise;
}

/// Espion de permissions : retient si on lui a DEMANDE quoi que ce soit.
class _Permissions extends Fake implements LocationPermissionService {
  bool consulte = false;
  bool escaladeDemandee = false;

  @override
  Future<bool> shouldAskBackgroundRationale() async {
    consulte = true;
    return true;
  }

  @override
  Future<void> rememberBackgroundRationaleDeclined() async {}

  @override
  Future<BackgroundLocationStatus> ensureBackgroundTracking() async {
    escaladeDemandee = true;
    return BackgroundLocationStatus.granted;
  }
}
