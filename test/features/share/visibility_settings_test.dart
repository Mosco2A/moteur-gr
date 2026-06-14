import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/settings/presentation/visibility_settings_screen.dart';
import 'package:moteur_gr/features/share/presentation/stage_share_screen.dart';
import 'package:moteur_gr/features/share/providers/visibility_settings_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests widget de la visibilite + partage (F7D-02).
///
/// Verifie : PRIVE par defaut, opt-in granulaire qui change l'etat et persiste,
/// partage gate par l'opt-in, et ZERO occurrence du mot "anonyme".
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      child: TranslationProvider(child: MaterialApp(home: child)),
    );
  }

  void expectNoAnonyme(WidgetTester tester) {
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((w) => (w.data ?? '').toLowerCase());
    for (final s in texts) {
      expect(s.contains('anonym'), isFalse, reason: 'Texte interdit: "$s"');
    }
  }

  group('VisibilitySettingsScreen', () {
    testWidgets('prive par defaut : tous les toggles OFF', (tester) async {
      await tester.pumpWidget(wrap(const VisibilitySettingsScreen()));
      await tester.pumpAndSettle();

      final switches = tester.widgetList<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switches.length, 3);
      expect(switches.every((s) => s.value == false), isTrue);
      expectNoAnonyme(tester);
    });

    testWidgets('opt-in granulaire : activer un toggle change son etat',
        (tester) async {
      await tester.pumpWidget(wrap(const VisibilitySettingsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('toggle-stage-results')));
      await tester.pumpAndSettle();

      final stageSwitch = tester.widget<SwitchListTile>(
        find.byKey(const ValueKey('toggle-stage-results')),
      );
      expect(stageSwitch.value, isTrue);
      // Les autres restent OFF (granularite par finalite).
      final leaderboardSwitch = tester.widget<SwitchListTile>(
        find.byKey(const ValueKey('toggle-leaderboard')),
      );
      expect(leaderboardSwitch.value, isFalse);
    });

    testWidgets('opt-in persiste dans SharedPreferences', (tester) async {
      await tester.pumpWidget(wrap(const VisibilitySettingsScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('toggle-activity-feed')));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(VisibilityKeys.shareActivityFeed), isTrue);
    });

    testWidgets('lien de consentement (design D4) present et cliquable',
        (tester) async {
      var opened = false;
      await tester.pumpWidget(wrap(
        VisibilitySettingsScreen(onOpenConsent: () => opened = true),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.shareVisibility.consentLink));
      await tester.pumpAndSettle();
      expect(opened, isTrue);
    });
  });

  group('StageShareScreen — partage gate par opt-in', () {
    Widget shareScreen({void Function(dynamic)? onShare}) => wrap(
          StageShareScreen(
            authorUidHash: 'deadbeefcafe',
            stageName: 'Etape 3',
            distanceKm: 12.4,
            elevationGainM: 800,
            durationSeconds: 14400,
            onShare: onShare,
          ),
        );

    testWidgets('partage OFF par defaut : message prive, pas de carte',
        (tester) async {
      await tester.pumpWidget(shareScreen());
      await tester.pumpAndSettle();

      expect(find.text(t.shareVisibility.privateNotice), findsOneWidget);
      expect(find.byKey(const ValueKey('share-button')), findsNothing);
      expectNoAnonyme(tester);
    });

    testWidgets('partage ON : carte pseudonyme affichee', (tester) async {
      SharedPreferences.setMockInitialValues({
        VisibilityKeys.shareStageResults: true,
      });
      await tester.pumpWidget(shareScreen());
      await tester.pumpAndSettle();

      // Pseudonyme present, bouton partager present.
      expect(find.text('rndr-deadbeef'), findsOneWidget);
      expect(find.byKey(const ValueKey('share-button')), findsOneWidget);
      expectNoAnonyme(tester);
    });
  });
}
