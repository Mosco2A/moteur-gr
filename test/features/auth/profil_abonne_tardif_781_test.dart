import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/features/auth/data/local_auth_service.dart';
import 'package:moteur_gr/features/auth/presentation/profile_screen.dart';
import 'package:moteur_gr/features/auth/providers/auth_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// « MON COMPTE » OUVERT APRES QUE L IDENTITE EST ETABLIE (tache 781).
///
/// LE DEFAUT MESURE, LE 10/10 SUR emulator-5560 (recette 778). L ecran affiche
/// « Le compte n a pas repondu » apres huit secondes, par ses DEUX portes —
/// l icone du cockpit et l action de la barre de « Mes treks ». Et pourtant
/// l identite existe : les Reglages affichent au meme instant « Services en
/// ligne actifs » avec l identifiant du compte cree chez Firebase.
///
/// C EST L ORDRE QUI TUE, et ce test ne joue que ca : l identite est etablie
/// AVANT que l ecran ne soit monte. C est l ordre REEL — l identite est
/// garantie au lancement, l ecran n est ouvert qu ensuite, a la main. Le flux
/// de diffusion ne rejouant rien a un abonne tardif, l ecran n obtenait plus
/// jamais rien et le garde-fou de la tache 649 disait l attente.
///
/// CE QUE CE TEST EXIGE. Le profil s affiche — le pseudo, et surtout LE
/// REGLAGE DE LA MAIN DOMINANTE, qui ne vit que sur cet ecran et que Christophe
/// a demande de pouvoir passer a gauche. Et le message d attente de la tache
/// 649 ne doit PAS apparaitre, meme en laissant filer bien au-dela de ses huit
/// secondes.
void main() {
  late LocalAuthService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    service = LocalAuthService();

    // L IDENTITE S ETABLIT AVANT L ECRAN. Aucun evenement ne sera plus emis
    // apres le montage : tout ce que l ecran pourra afficher, il devra l avoir
    // obtenu en s abonnant en retard.
    await service.signInAnonymously();
    await service.updateDisplayName('Christophe');
    await pumpEventQueue();
  });

  tearDown(() {
    service.dispose();
  });

  Widget wrap() {
    return ProviderScope(
      overrides: [authServiceProvider.overrideWithValue(service)],
      child: TranslationProvider(
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/home/profile',
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const Scaffold(body: SizedBox()),
                routes: [
                  GoRoute(
                    path: 'profile',
                    builder: (_, __) => const ProfileScreen(),
                  ),
                ],
              ),
              GoRoute(path: '/my-treks', builder: (_, __) => const SizedBox()),
            ],
          ),
        ),
      ),
    );
  }

  /// `pumpAndSettle` est inutilisable : l ecran heberge des indicateurs qui
  /// animent en permanence (infos paquet, etat cloud). On pompe donc un nombre
  /// BORNE de frames, en depassant franchement le delai de la tache 649.
  Future<void> laisserFilerAuDelaDuDelai(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(kAccountFailureDelay + const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('l ecran affiche le profil, pas le message d attente', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap());
    await laisserFilerAuDelaDuDelai(tester);

    expect(
      find.byKey(const ValueKey('compte-echec-attente')),
      findsNothing,
      reason:
          'ROUGE AVANT LE CORRECTIF : l abonnement tardif n obtenait rien, '
          'donc le garde-fou de la 649 affichait « Le compte n a pas repondu »',
    );
    expect(
      find.byKey(const ValueKey('compte-reessayer')),
      findsNothing,
      reason: 'il n y a rien a reessayer quand l identite est deja la',
    );
    expect(
      find.text('Christophe'),
      findsWidgets,
      reason: 'le pseudo etabli avant le montage doit etre affiche',
    );
  });

  testWidgets('le reglage de la main dominante est atteignable', (
    tester,
  ) async {
    // LA DEMANDE DE CHRISTOPHE EN DEPEND. Le passage du bouton SOS a gauche
    // pour un gaucher se regle ICI et nulle part ailleurs : tant que l ecran
    // restait en attente, le reglage etait injoignable par l interface.
    tester.view.physicalSize = const Size(390, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap());
    await laisserFilerAuDelaDuDelai(tester);

    expect(
      find.byType(SegmentedButton<String>),
      findsOneWidget,
      reason:
          'ROUGE AVANT LE CORRECTIF : le choix droitier/gaucher n etait pas '
          'rendu, l ecran etant bloque sur son attente',
    );
  });
}
