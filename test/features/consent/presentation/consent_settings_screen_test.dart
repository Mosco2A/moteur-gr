// D4A-02 — Tests widget de l'ecran de consentement dans les REGLAGES.
//
// Couvre les exigences RGPD du design #86166 :
//   - retrait possible a tout moment depuis les reglages (revoke)
//   - granularite : 4 finalites distinctes affichees avec leur etat
//   - finalite SANTE (art 9) isolee avec avertissement renforce
//   - lien vers la politique de confidentialite present
//
// Le ConsentService reel est branche via les providers ; SharedPreferences
// est mocke avec un etat initial (consentements deja accordes) pour tester
// le RETRAIT.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/services/consent_service.dart';
import 'package:moteur_gr/features/consent/presentation/consent_settings_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Translations tr = AppLocale.fr.buildSync();

  /// Construit la valeur stockee pour une finalite accordee (version courante).
  String grantedJson() => jsonEncode(<String, dynamic>{
        'granted': true,
        'decidedAt': DateTime.now().millisecondsSinceEpoch,
        'policyVersion': ConsentService.currentPolicyVersion,
      });

  Widget buildApp({VoidCallback? onPolicy}) {
    return ProviderScope(
      child: TranslationProvider(
        child: MaterialApp(
          home: ConsentSettingsScreen(onOpenPrivacyPolicy: onPolicy),
        ),
      ),
    );
  }

  group('ConsentSettingsScreen — D4A-02', () {
    testWidgets('affiche les 4 finalites avec leur etat', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // L'ecran est une liste defilante : on remonte chaque bascule dans le
      // viewport avant de l'asserter (ListView paresseuse).
      for (final purpose in ConsentPurpose.values) {
        final finder = find.byKey(ValueKey('consent-toggle-${purpose.name}'));
        await tester.scrollUntilVisible(finder, 120);
        expect(finder, findsOneWidget);
      }
    });

    testWidgets('RETRAIT depuis les reglages : revoke persiste', (
      tester,
    ) async {
      // Etat initial : navigation accordee.
      SharedPreferences.setMockInitialValues(<String, Object>{
        ConsentPurpose.locationNavigation.storageKey: grantedJson(),
      });
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // La bascule reflete l'etat accorde au depart.
      final toggle = find.byKey(
        const ValueKey('consent-toggle-locationNavigation'),
      );
      expect(tester.widget<Switch>(find.descendant(
        of: toggle,
        matching: find.byType(Switch),
      )).value, isTrue);

      // Retrait : l'utilisateur desactive.
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      // Le retrait est persiste.
      final prefs = await SharedPreferences.getInstance();
      final service = ConsentService(prefs: prefs);
      expect(service.hasConsent(ConsentPurpose.locationNavigation), isFalse);
    });

    testWidgets('sante (art 9) isolee avec avertissement renforce', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Section sante en bas de liste : on la remonte dans le viewport.
      final warning = find.text(tr.consent.healthWarning);
      await tester.scrollUntilVisible(warning, 120);
      expect(warning, findsOneWidget);
      expect(find.text(tr.consent.healthBadge), findsOneWidget);
    });

    testWidgets('lien politique de confidentialite present', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      var opened = false;
      await tester.pumpWidget(buildApp(onPolicy: () => opened = true));
      await tester.pumpAndSettle();

      final link = find.text(tr.consent.privacyPolicyLink);
      await tester.scrollUntilVisible(link, 120);
      await tester.ensureVisible(link);
      await tester.pumpAndSettle();
      expect(link, findsOneWidget);
      await tester.tap(link);
      await tester.pumpAndSettle();
      expect(opened, isTrue);
    });
  });
}
