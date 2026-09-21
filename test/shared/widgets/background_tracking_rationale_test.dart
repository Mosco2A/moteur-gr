import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/services/location_permission_service.dart';
import 'package:moteur_gr/shared/widgets/background_tracking_rationale_dialog.dart';

/// PRE-VOL EXPLIQUE DU SUIVI DE FOND — non-regression du defaut MAJEUR-1 de la
/// campagne personas du 21/09 (rapport #100277).
///
/// CE QUI S'EST PASSE : au premier demarrage de rando, l'ecran systeme
/// « Toujours autoriser en arrière-plan ? » recouvrait la carte sans un mot
/// d'explication, lance depuis DEUX endroits a la fois ; dans un run
/// l'application est restee sept minutes derriere cet ecran systeme.
///
/// CE QUE CES TESTS VERROUILLENT :
///   - rien n'est demande au systeme tant que l'utilisateur n'a pas LU puis
///     accepte l'explication ;
///   - « Plus tard » n'ouvre aucun ecran systeme, est memorise, et rend la main
///     (la rando demarre) ;
///   - quand il n'y a rien a demander, aucun dialogue n'apparait ;
///   - deux appels concurrents ne produisent QU'UNE demande systeme (c'est la
///     collision qui bloquait l'application sept minutes).
void main() {
  setUpAll(() => LocaleSettings.setLocaleRaw('fr'));

  Future<void> pumpEcran(WidgetTester tester, _FauxService service) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationPermissionServiceProvider.overrideWithValue(service),
        ],
        child: TranslationProvider(
          child: MaterialApp(
            locale: const Locale('fr'),
            home: Consumer(
              builder: (context, ref, _) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () =>
                        ensureBackgroundTrackingExplained(context, ref),
                    child: const Text('Demarrer'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  final tr = t.tracking.backgroundRationale;

  testWidgets('explique AVANT de demander : le dialogue precede le systeme',
      (tester) async {
    final service = _FauxService(doitDemander: true);
    await pumpEcran(tester, service);

    await tester.tap(find.text('Demarrer'));
    await tester.pumpAndSettle();

    // L'explication est a l'ecran, dans la langue de l'application.
    expect(find.text(tr.title), findsOneWidget);
    expect(find.text(tr.body), findsOneWidget);
    // Ce que coute un refus est dit AVANT, pas apres.
    expect(find.text(tr.ifRefused), findsOneWidget);
    // Et RIEN n'a encore ete demande au systeme.
    expect(service.demandesSysteme, 0);
  });

  testWidgets('accepter l explication declenche UNE demande systeme',
      (tester) async {
    final service = _FauxService(doitDemander: true);
    await pumpEcran(tester, service);

    await tester.tap(find.text('Demarrer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(tr.allow));
    await tester.pumpAndSettle();

    expect(service.demandesSysteme, 1);
    expect(service.refusMemorise, isFalse);
    // Le dialogue est referme : l'utilisateur n'est pas laisse dessus.
    expect(find.text(tr.title), findsNothing);
  });

  testWidgets('« Plus tard » : aucun ecran systeme, refus memorise, on continue',
      (tester) async {
    final service = _FauxService(doitDemander: true);
    await pumpEcran(tester, service);

    await tester.tap(find.text('Demarrer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(tr.later));
    await tester.pumpAndSettle();

    expect(service.demandesSysteme, 0);
    expect(service.refusMemorise, isTrue);
    expect(find.text(tr.title), findsNothing);
  });

  testWidgets('rien a demander : aucun dialogue, aucun ecran systeme',
      (tester) async {
    final service = _FauxService(doitDemander: false);
    await pumpEcran(tester, service);

    await tester.tap(find.text('Demarrer'));
    await tester.pumpAndSettle();

    expect(find.text(tr.title), findsNothing);
    expect(service.demandesSysteme, 0);
    expect(service.refusMemorise, isFalse);
  });

  test('deux appels concurrents ne lancent QU UNE demande systeme', () async {
    final service = _ServiceComptantLesDemandes();

    final a = service.ensureBackgroundTracking();
    final b = service.ensureBackgroundTracking();
    service.debloquer();
    final resultats = await Future.wait([a, b]);

    // C'est la collision de deux demandes simultanees qui rendait
    // « A request for permissions is already running » et laissait
    // l'application derriere l'ecran systeme des permissions.
    expect(service.demandesFond, 1);
    expect(resultats.first, resultats.last);
  });
}

/// Service factice : compte ce qui part vers le systeme, sans canal natif.
class _FauxService implements LocationPermissionService {
  _FauxService({required this.doitDemander});

  final bool doitDemander;

  /// Nombre de fois ou une demande SYSTEME a ete lancee.
  int demandesSysteme = 0;

  /// Le refus de l'explication a-t-il ete memorise ?
  bool refusMemorise = false;

  @override
  Future<bool> shouldAskBackgroundRationale() async => doitDemander;

  @override
  Future<void> rememberBackgroundRationaleDeclined() async {
    refusMemorise = true;
  }

  @override
  Future<BackgroundLocationStatus> ensureBackgroundTracking() async {
    demandesSysteme++;
    return BackgroundLocationStatus.granted;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Vrai service, canaux natifs remplaces : seule l'orchestration est testee.
class _ServiceComptantLesDemandes extends LocationPermissionService {
  final _porte = Completer<void>();

  /// Nombre d'escalades « localisation de fond » reellement lancees.
  int demandesFond = 0;

  /// Laisse la (ou les) demande(s) en cours se terminer.
  void debloquer() => _porte.complete();

  @override
  Future<bool> requestNotificationPermission() async => true;

  @override
  Future<BackgroundLocationStatus> requestBackgroundPermission() async {
    demandesFond++;
    await _porte.future;
    return BackgroundLocationStatus.granted;
  }

  @override
  Future<bool> requestBatteryOptimizationExemption() async => true;
}
