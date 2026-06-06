import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/feature_flags.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/widgets/paywall_sheet.dart';
import 'package:moteur_gr/shared/widgets/purchase_gate_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests widget E4.17 — purchase gate + ecran paywall.
///
/// Verifie : bandeau demo en gratuit, contenu nu en premium,
/// ouverture du paywall et achat stub qui debloque le trek.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MonetizationService svc;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FeatureFlags.clearOverrides();
    svc = MonetizationService(prefs: await SharedPreferences.getInstance());
  });

  tearDown(() {
    svc.clearPurchases();
    FeatureFlags.clearOverrides();
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [monetizationServiceProvider.overrideWithValue(svc)],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('PurchaseGateWidget', () {
    testWidgets('trek non achete : bandeau demo affiche', (tester) async {
      await tester.pumpWidget(wrap(
        const PurchaseGateWidget(
          trailId: 'volcans',
          totalStages: 12,
          child: Text('Contenu du trek'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(t.monetization.demoBanner), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.text('Contenu du trek'), findsOneWidget);
    });

    testWidgets('trek achete : contenu nu, pas de bandeau', (tester) async {
      await svc.purchaseTrail('volcans');

      await tester.pumpWidget(wrap(
        const PurchaseGateWidget(
          trailId: 'volcans',
          totalStages: 12,
          child: Text('Contenu du trek'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(t.monetization.demoBanner), findsNothing);
      expect(find.byIcon(Icons.lock_outline), findsNothing);
      expect(find.text('Contenu du trek'), findsOneWidget);
    });

    testWidgets('tap bandeau ouvre le paywall, achat stub debloque',
        (tester) async {
      await tester.pumpWidget(wrap(
        const PurchaseGateWidget(
          trailId: 'volcans',
          totalStages: 12,
          child: Text('Contenu du trek'),
        ),
      ));
      await tester.pumpAndSettle();

      // Ouvrir le paywall via le bandeau
      await tester.tap(find.text(t.monetization.demoBanner));
      await tester.pumpAndSettle();

      // Ecran paywall affiche : titre + avantages + prix 12 EUR
      expect(find.byType(PaywallSheet), findsOneWidget);
      expect(find.text(t.monetization.paywallTitle), findsOneWidget);
      expect(find.text(t.monetization.featureNoAds), findsOneWidget);
      expect(
        find.text(t.monetization.buyCtaWithPrice(price: '12')),
        findsOneWidget,
      );

      // Achat stub — aucun paiement reel
      await tester.tap(find.byKey(const Key('paywall-buy-button')));
      await tester.pumpAndSettle();

      // Trek debloque : paywall ferme, statut premium actif
      expect(find.byType(PaywallSheet), findsNothing);
      expect(svc.isTrailPurchased('volcans'), isTrue);
      expect(FeatureFlags.isPremiumEnabled('volcans'), isTrue);
    });
  });
}
