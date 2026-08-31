// SW-SKIN-L3a — Tests de l'unification des composants (Card -> AppCard,
// FilledButton -> AppButton) sur le domaine settings + consent.
//
// Objectif : prouver que les ecrans du domaine utilisent desormais la grammaire
// unifiee (AppCard / AppButton) et PLUS aucune Card Material brute, tout en
// gardant les taps fonctionnels (iso-fonction). L'iso-rendu visuel (padding,
// couleurs semantiques) est preserve par construction dans les ecrans ; ces
// tests verrouillent la substitution structurelle et le comportement.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moteur_gr/features/consent/presentation/consent_onboarding_screen.dart';
import 'package:moteur_gr/features/consent/presentation/consent_settings_screen.dart';
import 'package:moteur_gr/features/settings/presentation/departure_date_picker.dart';
import 'package:moteur_gr/features/settings/presentation/settings_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/widgets/app_button.dart';
import 'package:moteur_gr/shared/widgets/app_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Translations tr = AppLocale.fr.buildSync();

  setUpAll(() async {
    // DepartureDatePicker formate une date via DateFormat(..., 'fr_FR') :
    // sans donnees de locale, intl leve LocaleDataException au build.
    await initializeDateFormatting('fr_FR');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      child: TranslationProvider(
        child: MaterialApp(home: child),
      ),
    );
  }

  group('SW-SKIN-L3a — SettingsScreen', () {
    testWidgets('utilise AppCard et aucune Card Material brute', (tester) async {
      await tester.pumpWidget(wrap(const SettingsScreen()));
      await tester.pumpAndSettle();

      // L'ecran est un ListView paresseux : au moins une AppCard est construite
      // dans le viewport initial, et surtout AUCUNE Card Material brute nulle
      // part dans l'arbre rendu (grammaire unifiee).
      expect(find.byType(AppCard), findsWidgets);
      expect(find.byType(Card), findsNothing);

      // On parcourt tout l'ecran : chaque section construite est une AppCard,
      // jamais une Card brute (verrou anti-regression au defilement).
      final scrollable = find.byType(Scrollable).first;
      for (final header in <IconData>[
        Icons.language,
        Icons.storage,
        Icons.notifications,
        Icons.privacy_tip_outlined,
        Icons.info_outline,
      ]) {
        await tester.scrollUntilVisible(
          find.byIcon(header),
          120,
          scrollable: scrollable,
        );
        await tester.pumpAndSettle();
        expect(find.byType(Card), findsNothing);
      }
    });
  });

  group('SW-SKIN-L3a — DepartureDatePicker', () {
    testWidgets('utilise AppCard (plus de Card brute)', (tester) async {
      await tester.pumpWidget(wrap(
        const DepartureDatePicker(trailId: 'gr20'),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(AppCard), findsOneWidget);
      expect(find.byType(Card), findsNothing);
    });
  });

  group('SW-SKIN-L3a — ConsentSettingsScreen', () {
    testWidgets('utilise AppCard (plus de Card brute)', (tester) async {
      await tester.pumpWidget(wrap(const ConsentSettingsScreen()));
      await tester.pumpAndSettle();

      // Finalites standard + section sante = au moins 2 AppCard (la banniere
      // "review" n'apparait que si la politique a evolue).
      expect(find.byType(AppCard), findsWidgets);
      expect(find.byType(Card), findsNothing);
    });
  });

  group('SW-SKIN-L3a — ConsentOnboardingScreen', () {
    testWidgets('utilise AppButton pour la validation + tap fonctionnel',
        (tester) async {
      var continued = false;
      await tester.pumpWidget(wrap(
        ConsentOnboardingScreen(onContinue: () => continued = true),
      ));
      await tester.pumpAndSettle();

      // Plus aucune Card Material brute (section sante = AppCard).
      expect(find.byType(Card), findsNothing);

      // Le bouton de validation est en bas d'un ListView paresseux : on le
      // remonte dans le viewport avant de l'asserter.
      final label = find.text(tr.consent.acceptSelected);
      await tester.scrollUntilVisible(label, 120);
      await tester.ensureVisible(label);
      await tester.pumpAndSettle();

      // Le bouton de validation est desormais un AppButton (variante primary).
      expect(find.byType(AppButton), findsOneWidget);

      // Tap fonctionnel : le libelle est preserve et declenche onContinue.
      await tester.tap(label);
      await tester.pumpAndSettle();
      expect(continued, isTrue);
    });
  });
}
