import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/booking/presentation/hebergements_peripheriques_screen.dart';
import 'package:moteur_gr/features/booking/providers/hebergement_peripherique_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/widgets/app_card.dart';

/// Lanceur de deeplink factice : enregistre les URLs ouvertes (pas de réseau).
class _FakeDeeplinkLauncher implements DeeplinkLauncher {
  final List<String> opened = [];
  bool result = true;

  @override
  Future<bool> open(String url) async {
    opened.add(url);
    return result;
  }
}

/// Tests widget de l'écran des hébergements périphériques (F6D-02).
///
/// Vérifie : la liste des hébergements et leur détour A/R, le bandeau
/// facilitateur (pas de réservation in-app), et que le bouton OUVRE un deeplink
/// sortant (rôle de facilitateur, #84100) sans réservation interne.
void main() {
  late _FakeDeeplinkLauncher fakeLauncher;

  setUp(() => fakeLauncher = _FakeDeeplinkLauncher());

  Widget wrap() => ProviderScope(
    overrides: [deeplinkLauncherProvider.overrideWithValue(fakeLauncher)],
    child: TranslationProvider(
      child: const MaterialApp(
        home: HebergementsPeripheriquesScreen(trailId: 'test-trail'),
      ),
    ),
  );

  group('HebergementsPeripheriquesScreen', () {
    testWidgets('affiche le titre et le bandeau facilitateur', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.text(t.hebergement.title), findsWidgets);
      expect(find.text(t.hebergement.facilitatorNote), findsOneWidget);
    });

    testWidgets('liste les hébergements avec leur détour A/R', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      // Au moins une carte d'hébergement présente.
      // SW-SKIN-L3e : les Card Material ont ete unifiees en AppCard.
      expect(find.byType(AppCard), findsWidgets);
      // Le détour A/R formaté apparaît (ex. 2.4 km).
      expect(find.text(t.hebergement.detourAR(km: '2.4')), findsOneWidget);
      // Bouton d'ouverture du site présent pour chaque hébergement.
      expect(find.text(t.hebergement.openSite), findsWidgets);
    });

    testWidgets('le bouton ouvre un deeplink sortant (facilitateur)', (
      tester,
    ) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      // Ouvre le premier hébergement.
      await tester.tap(find.text(t.hebergement.openSite).first);
      await tester.pumpAndSettle();

      // Un deeplink a été ouvert (URL sortante), aucune réservation interne.
      expect(fakeLauncher.opened, isNotEmpty);
      expect(fakeLauncher.opened.first, startsWith('https://'));
    });

    testWidgets('affiche un message si le lien ne peut pas être ouvert', (
      tester,
    ) async {
      fakeLauncher.result = false;
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.hebergement.openSite).first);
      await tester.pump(); // laisse apparaître la SnackBar

      expect(find.text(t.hebergement.cannotOpen), findsOneWidget);
    });
  });
}
