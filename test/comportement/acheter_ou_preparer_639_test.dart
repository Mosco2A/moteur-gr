import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/trail_catalog.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/features/trail/presentation/trail_catalog_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/widgets/app_button.dart';

import '../structurel/regie_pub_absente.dart';

/// TACHE 639 — BUG 2 : LA CARTE D'UN SENTIER NE PORTE QU'UNE ACTION, ET SON
/// VERBE DIT CE QU'ELLE FAIT.
///
/// LE RETOUR DE CHRISTOPHE, MOT POUR MOT (30/09 10:06, telephone, build 0.1.3
/// (7)) : « pas debloquer la randonnee mais acheter / preparer (avec une petite
/// pub ou sans si on est abonne == a la place d entrer) ».
///
/// CE QUE LA CARTE MONTRAIT, MESURE. Sur un sentier NON POSSEDE, DEUX boutons :
/// « Entrer » en primaire et « Debloquer cette randonnee — 4,99 € » juste
/// dessous. Or « Entrer » n'entrait pas : le lot 634 (e50b1cec) y avait pose une
/// garde qui l'envoyait, lui aussi, au parcours d'achat. Deux boutons, deux
/// libelles, une seule destination — et un verbe qui promettait autre chose que
/// ce qu'il faisait.
///
/// LA REGLE A CHANGE LE MEME JOUR, A 12:41 (DEM-260930-1241), ET CE FICHIER LE
/// PORTE. Le premier passage avait mis UNE SEULE action par etat — donc
/// « Acheter » SEUL sur un sentier non possede. Christophe a rouvert la
/// preparation gratuite : « je suis en prepa avec pub » est un etat legitime.
/// Verbatim : « Il faut que l on fasse la diff entre = je suis abonne et je n ai
/// pas de pub en prepa, j ai achete un trek sans pub, je suis en prepa avec pub ».
/// Ce qui etait faux n'etait donc pas « deux boutons » mais « deux boutons pour
/// la MEME destination » : « Preparer » prepare vraiment maintenant, et
/// « Acheter » mene au paiement. Deux actions, deux destinations.
///
/// CE QUE CES TESTS VERROUILLENT :
///   1. un sentier non possede montre PREPARER (avec l'icone pub) ET ACHETER ;
///   2. un sentier qui n'est plus a vendre montre PREPARER seul ;
///   3. le mot « debloquer » a quitte les libelles d'action, dans les 5 langues ;
///   4. « Entrer » aussi : c'etait le verbe qui mentait.
void main() {
  // AUCUNE REGIE PUBLICITAIRE ici (tache 595) : le catalogue porte un
  // emplacement de banniere, et sans cette declaration le test toucherait le SDK
  // Google Mobile Ads, dont les canaux muets font pendre l amorce du consentement
  // six secondes de temps reel (« Pending timers », sans rapport avec ce qui est
  // verifie ici). La banniere a son propre test : pub_v1_595_test.dart.
  setUp(brancherAucuneRegiePub);

  /// Un sentier PAYANT du catalogue (ni gratuit, ni de demonstration).
  final payant = TrailCatalog.all.firstWhere((t) => !t.isFreeTrail);

  /// Un sentier QUI N'EST PLUS A VENDRE : rien a acheter, donc « Preparer » seul.
  ///
  /// INTEGRATION 647 — CE FIXTURE CHERCHAIT UN SENTIER GRATUIT, ET IL N'EN EXISTE
  /// PLUS AUCUN. Le lot 638 a retire tout sentier gratuit du catalogue — decision
  /// de Christophe du 29/09 14:17, verbatim : « la prochaine fois que j'ouvre
  /// l'application je n'ai droit a rien ». `firstWhere((t) => t.isFreeTrail)`
  /// levait donc « Bad state: No element » au CHARGEMENT du fichier, ce qui
  /// emportait les huit tests d'un coup.
  ///
  /// CE QUE LE TEST VERIFIE N'A PAS CHANGE. « Plus a vendre » n'est pas declare
  /// par le prix du sentier mais par l'override `isDemoModeProvider` que pose
  /// `poserCatalogue(aVendre: false)`, et cet override vaut pour TOUS les
  /// sentiers. N'importe quelle entree du catalogue fait donc l'affaire : on
  /// reprend la meme que ci-dessus, et le scenario reste exactement celui du lot
  /// 639.
  final plusAVendre = payant;

  Widget hote({required List<Override> overrides}) => ProviderScope(
    overrides: overrides,
    child: TranslationProvider(
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/catalog',
          routes: [
            GoRoute(
              path: '/catalog',
              builder: (_, __) => const TrailCatalogScreen(),
            ),
            GoRoute(path: '/home', builder: (_, __) => const SizedBox()),
            GoRoute(path: '/my-treks', builder: (_, __) => const SizedBox()),
          ],
        ),
      ),
    ),
  );

  /// Fenetre haute : un `ListView` ne construit pas ce qui est hors champ, et le
  /// catalogue porte plusieurs sentiers plus le bouton demo en tete.
  void fenetreHaute(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  /// Rend le catalogue en declarant quels sentiers sont « en mode demo »
  /// (= non possedes, donc a vendre). C'est la source unique
  /// [MonetizationService.isDemoMode], que la carte lit deja.
  Future<void> poserCatalogue(
    WidgetTester tester, {
    required bool aVendre,
  }) async {
    fenetreHaute(tester);
    await tester.pumpWidget(
      hote(
        overrides: [
          isDemoModeProvider.overrideWith((ref, trailId) async => aVendre),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  group('une seule action, celle de l etat du sentier', () {
    testWidgets('sentier NON POSSEDE : PREPARER **et** ACHETER', (
      tester,
    ) async {
      await poserCatalogue(tester, aVendre: true);

      expect(
        find.byKey(ValueKey('catalog-buy-${payant.id}')),
        findsOneWidget,
        reason: 'le sentier a vendre doit porter le bouton d achat',
      );
      expect(
        find.byKey(ValueKey('catalog-enter-${payant.id}')),
        findsOneWidget,
        reason:
            'la preparation gratuite, AVEC publicite, reste possible '
            '(DEM-260930-1241) — la fermer etait la faute du premier passage',
      );

      final achat = tester.widget<AppButton>(
        find.byKey(ValueKey('catalog-buy-${payant.id}')),
      );
      expect(achat.label, startsWith(t.monetization.buyCta));
      expect(achat.onPressed, isNotNull);
      final prepa = tester.widget<AppButton>(
        find.byKey(ValueKey('catalog-enter-${payant.id}')),
      );
      expect(prepa.label, t.catalog.prepare);
      expect(prepa.onPressed, isNotNull);
    });

    testWidgets('sentier PLUS A VENDRE : PREPARER, et rien de plus', (
      tester,
    ) async {
      await poserCatalogue(tester, aVendre: false);

      expect(
        find.byKey(ValueKey('catalog-enter-${plusAVendre.id}')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('catalog-buy-${plusAVendre.id}')),
        findsNothing,
        reason:
            'un bouton d achat sur un sentier deja jouable est un bouton '
            'qui ment',
      );

      final bouton = tester.widget<AppButton>(
        find.byKey(ValueKey('catalog-enter-${plusAVendre.id}')),
      );
      expect(bouton.label, t.catalog.prepare);
      expect(bouton.onPressed, isNotNull);
    });

    for (final aVendre in [true, false]) {
      testWidgets(
        'PREPARER est toujours la, ACHETER seulement s il y a a acheter '
        '(a vendre : $aVendre)',
        (tester) async {
          await poserCatalogue(tester, aVendre: aVendre);
          for (final trail in TrailCatalog.all) {
            expect(
              find.byKey(ValueKey('catalog-enter-${trail.id}')),
              findsOneWidget,
              reason: '${trail.id} : on doit TOUJOURS pouvoir preparer',
            );
            expect(
              tester
                  .widgetList(find.byKey(ValueKey('catalog-buy-${trail.id}')))
                  .length,
              aVendre ? 1 : 0,
              reason:
                  '${trail.id} : un bouton d achat sur un sentier qui n est '
                  'plus a vendre est un bouton qui ment',
            );
          }
        },
      );
    }
  });

  group('les libelles, dans les 5 langues', () {
    // CE QUE CHRISTOPHE A REFUSE EST NOMME ICI, LANGUE PAR LANGUE. Un libelle
    // est interdit parce qu'il est ECRIT dans cette liste, jamais parce qu'un
    // algorithme le trouve suspect.
    const debloquer = <AppLocale, List<String>>{
      AppLocale.fr: ['débloqu', 'debloqu'],
      AppLocale.en: ['unlock'],
      AppLocale.de: ['freischalt'],
      AppLocale.es: ['desbloque'],
      AppLocale.it: ['sblocc'],
    };
    const entrer = <AppLocale, List<String>>{
      AppLocale.fr: ['entrer'],
      AppLocale.en: ['enter'],
      AppLocale.de: ['öffnen'],
      AppLocale.es: ['entrar'],
      AppLocale.it: ['entra'],
    };

    /// Les libelles d'ACTION de la carte d'un sentier et de ses voisins
    /// immediats : ceux sur lesquels le randonneur appuie.
    List<String> libellesDAction(AppLocale locale) {
      final tr = locale.buildSync();
      return [
        tr.catalog.prepare,
        tr.catalog.a11y.prepareButton(nom: 'X'),
        tr.catalog.a11y.buyButton(nom: 'X'),
        tr.monetization.buyCta,
        tr.monetization.buyCtaWithPrice(price: '4,99'),
        tr.checklist.demoUnlockCta,
        tr.checklist.demoLockedCategory,
        tr.journal.lockedUnlock,
        tr.training.unlock,
      ];
    }

    test('aucun libelle d action ne dit plus « debloquer »', () {
      for (final entree in debloquer.entries) {
        for (final libelle in libellesDAction(entree.key)) {
          for (final mot in entree.value) {
            expect(
              libelle.toLowerCase(),
              isNot(contains(mot)),
              reason:
                  '${entree.key.languageCode} : « $libelle » dit encore '
                  '« $mot » — Christophe a demande « acheter »',
            );
          }
        }
      }
    });

    test('aucun libelle d action ne dit plus « entrer »', () {
      for (final entree in entrer.entries) {
        for (final libelle in libellesDAction(entree.key)) {
          for (final mot in entree.value) {
            expect(
              libelle.toLowerCase(),
              isNot(contains(mot)),
              reason:
                  '${entree.key.languageCode} : « $libelle » dit encore '
                  '« $mot » — ce verbe n entrait nulle part',
            );
          }
        }
      }
    });

    test('les deux verbes SONT la : acheter et preparer', () {
      const acheter = <AppLocale, String>{
        AppLocale.fr: 'achet',
        AppLocale.en: 'buy',
        AppLocale.de: 'kauf',
        AppLocale.es: 'compr',
        AppLocale.it: 'acquist',
      };
      const preparer = <AppLocale, String>{
        AppLocale.fr: 'prépar',
        AppLocale.en: 'prepar',
        AppLocale.de: 'vorbereit',
        AppLocale.es: 'prepar',
        AppLocale.it: 'prepar',
      };
      for (final locale in AppLocale.values) {
        final tr = locale.buildSync();
        expect(
          tr.monetization.buyCta.toLowerCase(),
          contains(acheter[locale]),
          reason:
              '${locale.languageCode} : le bouton d achat ne dit pas acheter',
        );
        expect(
          tr.catalog.prepare.toLowerCase(),
          contains(preparer[locale]),
          reason:
              '${locale.languageCode} : le bouton de preparation ne dit pas '
              'preparer',
        );
      }
    });
  });
}
