// V1 ARGENT (tache 594, A3) — LES ECRANS DE PAIEMENT QUI MANQUAIENT.
//
// CE QUI N EXISTAIT PAS. Aucun ecran pour recharger le compte-etapes : la
// grille officielle (11 = 9,99 / 25 = 19,99 / 50 = 34,99) etait ecrite au
// centime dans `kStepPacks` et AFFICHEE NULLE PART (inventaire 593 §M1).
// Aucun ecran d abonnement, alors que l abo light est un des trois niveaux du
// modele. Aucun bouton « Restaurer mes achats ».
//
// ET UNE MALHONNETETE INTERNE. Le bouton « Debloquer » du paywall appelait
// `buyTrail`, JETAIT le resultat et fermait la feuille — quel que soit
// l echec. La meme application, depuis le LOT X, fait dire son refus a la
// boutique de packs. Deux honnetetes dans un meme produit.
//
// TESTS ECRITS ROUGES AVANT CORRECTION.
library;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/features/monetization/presentation/subscription_screen.dart';
import 'package:moteur_gr/features/monetization/presentation/wallet_recharge_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/widgets/paywall_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Moniteur de connectivite toujours hors ligne (deterministe en test).
class _HorsLigne extends ConnectivityMonitor {
  @override
  Future<ConnectivityStatus> checkStatus() async =>
      ConnectivityStatusValues.offline;
}

void main() {
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() async => db.close());

  Widget monter(Widget ecran) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        // Hors ligne : le complement store est alors REFUSE pour une raison
        // nommee, sans dependre du plugin reseau dans un test.
        connectivityMonitorProvider.overrideWithValue(_HorsLigne()),
      ],
      child: TranslationProvider(
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/x',
            routes: [GoRoute(path: '/x', builder: (_, __) => ecran)],
          ),
        ),
      ),
    );
  }

  group('A3 — l ecran de recharge du compte-etapes', () {
    testWidgets('affiche la grille officielle, au centime', (tester) async {
      await tester.pumpWidget(monter(const WalletRechargeScreen()));
      await tester.pumpAndSettle();

      for (final pack in kStepPacks) {
        expect(
          find.byKey(ValueKey('pack-etapes-${pack.steps}')),
          findsOneWidget,
          reason:
              'la grille ${pack.steps} etapes / ${pack.priceEur} EUR est '
              'ecrite dans le code et n etait affichee nulle part',
        );
      }
      // Les prix EXACTS, pas un fragment : « 19,99 » contient « 9,99 ».
      for (final prix in <String>['9,99', '19,99', '34,99']) {
        expect(
          find.text(t.monetization.packPrice(price: prix)),
          findsOneWidget,
          reason: 'le prix $prix EUR de la grille doit etre affiche tel quel',
        );
      }
    });

    testWidgets('un achat impossible le DIT, il ne se tait pas', (
      tester,
    ) async {
      await tester.pumpWidget(monter(const WalletRechargeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('pack-etapes-11')));
      await tester.pumpAndSettle();

      expect(
        find.byType(SnackBar),
        findsOneWidget,
        reason: 'un bouton qui ne produit rien est un mensonge (LOT X)',
      );
      expect(find.text(t.monetization.storeUnavailable), findsOneWidget);
    });
  });

  group('A3 — l ecran d abonnement', () {
    testWidgets('dit ce que l abo donne, ET ce qu il ne donne pas', (
      tester,
    ) async {
      await tester.pumpWidget(monter(const SubscriptionScreen()));
      await tester.pumpAndSettle();

      expect(find.text(t.monetization.subscriptionTitle), findsOneWidget);
      expect(find.text(t.monetization.subscriptionSubtitle), findsOneWidget);
      expect(
        find.text(t.monetization.subscriptionIncludesNoAds),
        findsOneWidget,
      );
      expect(
        find.text(
          t.monetization.subscriptionIncludesAllowance(
            steps: kSubscriberStepsAllowance!,
          ),
        ),
        findsOneWidget,
        reason:
            'la cagnotte annonce son NOMBRE depuis la decision de Chris '
            'du 27/09 : deux etapes par mois',
      );
      // ET SON PRIX. Une page d abonnement sans prix ne vend rien.
      expect(
        find.byKey(const ValueKey('abo-prix')),
        findsOneWidget,
        reason: 'l abonnement coute 2 euros par mois, et l ecran le dit',
      );
      // LE POINT QUI COMPTE : l abo ne debloque NI les outils complets NI la
      // realisation. L ecran doit le dire, sinon il vend autre chose.
      expect(find.text(t.monetization.subscriptionExcludes), findsOneWidget);
    });

    testWidgets('porte le bouton « Restaurer mes achats », et il repond', (
      tester,
    ) async {
      await tester.pumpWidget(monter(const SubscriptionScreen()));
      await tester.pumpAndSettle();

      // L ECRAN A GRANDI (tache 601) : il porte desormais le PRIX, le montant
      // de la cagnotte et le bouton d arret de l abonnement exige par la loi. La
      // restauration passe donc sous la ligne de flottaison d un ecran de test,
      // et un ListView ne CONSTRUIT pas ce qui est hors champ. On fait defiler
      // avant d appuyer, comme un utilisateur.
      final bouton = find.byKey(const ValueKey('restaurer-achats'));
      await tester.scrollUntilVisible(bouton, 200);
      await tester.pumpAndSettle();
      expect(bouton, findsOneWidget);
      await tester.tap(bouton);
      await tester.pumpAndSettle();

      expect(
        find.byType(SnackBar),
        findsOneWidget,
        reason: 'restaurer sans store disponible doit le DIRE',
      );
      expect(find.text(t.monetization.restoreUnavailable), findsOneWidget);
    });

    testWidgets('souscrire quand c est impossible le dit aussi', (
      tester,
    ) async {
      await tester.pumpWidget(monter(const SubscriptionScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('souscrire-abo')));
      await tester.pumpAndSettle();
      expect(find.text(t.monetization.storeUnavailable), findsOneWidget);
    });
  });

  group('A3 — le bouton Debloquer n avale plus son echec', () {
    testWidgets('un achat qui echoue le dit et NE FERME PAS la feuille', (
      tester,
    ) async {
      // TACHE 614 — ON OUVRE LA VITRINE PAR LE GESTE UNIQUE. `showPaywallSheet`
      // etait publique et chaque ecran ouvrait sa propre vitrine avec son
      // propre prix ; elle est devenue privee et son seul appelant est
      // [buyTrail]. Ce test emprunte donc le meme chemin que les trois
      // points d'entree de l'application, au lieu d'un chemin de test a lui.
      await tester.pumpWidget(
        monter(
          Consumer(
            builder: (context, ref, _) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => buyTrail(context, ref, trailId: 'gr20'),
                  child: const Text('ouvrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();

      expect(find.byType(PaywallSheet), findsOneWidget);
      await tester.tap(find.byKey(const Key('paywall-buy-button')));
      await tester.pumpAndSettle();

      // Compte-etapes vide + IAP stub -> complement store non confirme.
      expect(
        find.byType(SnackBar),
        findsOneWidget,
        reason:
            'le bouton appelait buyTrail, JETAIT le resultat et fermait '
            'la feuille : l utilisateur ne savait jamais que rien ne s etait '
            'passe',
      );
      expect(
        find.byType(PaywallSheet),
        findsOneWidget,
        reason: 'on ne ferme pas la porte de sortie sur un echec',
      );

      // Laisse le message se retirer de lui-meme (son minuteur ne doit pas
      // survivre a la fin du test).
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });
}
