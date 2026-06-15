// D4A-02 — Tests widget de l'ecran de consentement au 1er lancement.
//
// Couvre les exigences CNIL/RGPD du design #86166 :
//   - AUCUNE case pre-cochee au 1er lancement (opt-in reel, acte positif)
//   - granularite par finalite : 4 bascules distinctes
//   - finalite SANTE (art 9) presentee SEPAREMENT avec avertissement renforce
//   - acte positif : cocher une finalite la persiste sans toucher les autres
//   - lien vers la politique de confidentialite present
//
// SharedPreferences mocke (etat vierge = 1er lancement). Le ConsentService
// reel est branche via les providers (pas de mock du service).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/services/consent_service.dart';
import 'package:moteur_gr/features/consent/presentation/consent_onboarding_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Translations tr = AppLocale.fr.buildSync();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Widget buildApp({VoidCallback? onContinue, VoidCallback? onPolicy}) {
    return ProviderScope(
      child: TranslationProvider(
        child: MaterialApp(
          home: ConsentOnboardingScreen(
            onContinue: onContinue ?? () {},
            onOpenPrivacyPolicy: onPolicy,
          ),
        ),
      ),
    );
  }

  group('ConsentOnboardingScreen — D4A-02', () {
    testWidgets('1er lancement : AUCUNE case pre-cochee (opt-in reel)', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // 4 bascules de consentement (une par finalite).
      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      expect(switches.length, ConsentPurpose.values.length);

      // TOUTES sont a false : rien n'est consenti par defaut.
      for (final s in switches) {
        expect(s.value, isFalse, reason: 'Aucune finalite pre-cochee');
      }
    });

    testWidgets('granularite : une bascule par finalite (4 distinctes)', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      for (final purpose in ConsentPurpose.values) {
        expect(
          find.byKey(ValueKey('consent-toggle-${purpose.name}')),
          findsOneWidget,
          reason: 'Bascule presente pour $purpose',
        );
      }
    });

    testWidgets(
        'sante (art 9) presentee separement avec avertissement renforce', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Avertissement sante renforce visible.
      expect(find.text(tr.consent.healthWarning), findsOneWidget);
      // Badge "donnee sensible".
      expect(find.text(tr.consent.healthBadge), findsOneWidget);
    });

    testWidgets('acte positif : cocher la navigation ne coche pas les autres', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Coche la navigation perso.
      await tester.tap(
        find.byKey(const ValueKey('consent-toggle-locationNavigation')),
      );
      await tester.pumpAndSettle();

      // L'etat persiste : la navigation est accordee...
      final prefs = await SharedPreferences.getInstance();
      final service = ConsentService(prefs: prefs);
      expect(service.hasConsent(ConsentPurpose.locationNavigation), isTrue);
      // ...mais aucune autre finalite (pas de groupage).
      expect(service.hasConsent(ConsentPurpose.socialSharing), isFalse);
      expect(service.hasConsent(ConsentPurpose.publicReporting), isFalse);
      expect(service.hasConsent(ConsentPurpose.healthData), isFalse);
    });

    testWidgets('lien vers la politique de confidentialite present + cliquable',
        (tester) async {
      var opened = false;
      await tester.pumpWidget(buildApp(onPolicy: () => opened = true));
      await tester.pumpAndSettle();

      // Lien en bas de la liste defilante : on le remonte ENTIEREMENT dans le
      // viewport (scrollUntilVisible peut le laisser au ras du bord bas).
      final link = find.text(tr.consent.privacyPolicyLink);
      await tester.scrollUntilVisible(link, 120);
      await tester.ensureVisible(link);
      await tester.pumpAndSettle();
      expect(link, findsOneWidget);
      await tester.tap(link);
      await tester.pumpAndSettle();
      expect(opened, isTrue);
    });

    testWidgets('le bouton de validation declenche onContinue', (tester) async {
      var continued = false;
      await tester.pumpWidget(buildApp(onContinue: () => continued = true));
      await tester.pumpAndSettle();

      // Bouton en bas de la liste defilante : on le remonte avant de cliquer.
      final button = find.text(tr.consent.acceptSelected);
      await tester.scrollUntilVisible(button, 120);
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(continued, isTrue);
    });
  });
}
