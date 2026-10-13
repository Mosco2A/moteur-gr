// Test miroir de `lib/features/trek/presentation/podometre_autorisation.dart`
// (lot 671-02) : ce que l'explication ne fait PAS. Les deux chemins de
// l'autorisation sont prouves sur le vrai bouton de depart dans
// `test/comportement/permission_activite_physique_671_test.dart`.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/data/podometre_permission_service.dart';
import 'package:moteur_gr/features/trek/presentation/podometre_autorisation.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocaleSettings.setLocaleRaw('fr');
  });

  Future<int> appuyer(WidgetTester tester, PermissionStatus statut) async {
    var demandes = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          podometerPermissionServiceProvider.overrideWithValue(
            PodometerPermissionService(
              readStatus: () async => statut,
              request: () async {
                demandes++;
                return false;
              },
            ),
          ),
        ],
        child: TranslationProvider(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) => Scaffold(
                body: GestureDetector(
                  onTap: () => ensureStepCountingExplained(context, ref),
                  child: const Text('Partir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Partir'));
    await tester.pumpAndSettle();
    return demandes;
  }

  final explication = find.byKey(const ValueKey('podometre-explication'));

  testWidgets('un telephone sans podometre ne voit ni explication ni '
      'demande', (tester) async {
    expect(await appuyer(tester, PermissionStatus.restricted), 0);
    expect(explication, findsNothing);
  });

  testWidgets('fermer l explication par la barriere vaut « Plus tard » : '
      'aucune demande, le refus est retenu et raconte', (tester) async {
    await appuyer(tester, PermissionStatus.denied);
    expect(explication, findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(explication, findsNothing);
    expect(find.text(t.tracking.stepCounting.whyGps), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(PodometerPermissionService.kDeclinedKey), isTrue);
  });
}
