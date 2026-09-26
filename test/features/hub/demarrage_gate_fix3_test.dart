import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/features/hub/presentation/widgets/hub_start_trek_button.dart';
import 'package:moteur_gr/features/hub/providers/cockpit_start_providers.dart';
import 'package:moteur_gr/features/notifications/providers/download_reminder_provider.dart';
import 'package:moteur_gr/features/safety/providers/health_prepare_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// FIX-3 — NON-REGRESSION DU GATE DE DEMARRAGE (« Démarrer la randonnée »).
///
/// CONTEXTE. Le rapport QA personas cycle4 impute 4 coincements de la persona
/// Lea a un « gate de demarrage non satisfait », et le lot FIX-2 a remonte que
/// le CTA n'apparaissait jamais malgre Itineraire + Programme + dates poses.
/// La mesure sur appareil a montre que le CTA est bien la, ACTIF, en bas du
/// cockpit : les deux observations etaient des erreurs d'observation (le CTA a
/// ete deplace EN BAS du cockpit au LOT 2, il n'est plus en haut).
///
/// CE QUE CES TESTS VERROUILLENT. Le gate [prepareCoreDoneProvider] est une VUE
/// DERIVEE de l'etat de preparation : c'est exactement la famille de bug de M4
/// (un FutureProvider lu une seule fois, jamais invalide, qui fige l'ecran sur
/// un etat perime). Aucun test ne couvrait jusqu'ici le sens « la gate S'OUVRE »
/// — seulement « la gate est fermee » (`hub_screen_test.dart`). On verrouille
/// donc les trois chemins par lesquels l'etat de preparation arrive au bouton :
///   1. a chaud, pendant que l'utilisateur complete ses 3 etapes ;
///   2. au boot, quand les 3 signaux sont relus des SharedPreferences ;
///   3. quand la relecture au build croise un `markSeen` immediat (course).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const trailId = 'mare-a-mare-centre';

  /// TACHE 568 (LOT Q) — LA PORTE A GAGNE UNE QUATRIEME CONDITION.
  ///
  /// Decision de Chris du 26/09 10:29, verbatim : « on ne demarre pas un trek
  /// sans avoir rempli sa fiche medicale et lu les conseils pour qu'elle soit
  /// applicable sur le sentier ». Ces tests-ci portent sur la MECANIQUE de
  /// rafraichissement de la vue derivee (lecon M4) et sur la COURSE de relecture
  /// des preferences (lecon FIX-3) : la fiche medicale y est donc posee comme
  /// ACQUISE, pour que ce qu'ils mesurent reste le trio historique. La regle de
  /// la 4e condition, elle, est verrouillee par
  /// `test/features/safety/fiche_medicale_condition_depart_568_test.dart` et par
  /// `test/features/hub/providers/cockpit_start_providers_test.dart`.
  const ficheMedicaleFaite = <String, Object>{
    kHealthPrepareStepsKey: <String>['filled', 'adviceRead'],
  };

  /// Enveloppe le bouton avec le minimum vital : Slang (libelles) + un routeur
  /// (le bouton pousse `/map` au succes) + un [ProviderScope] reel (aucun
  /// override : on veut les VRAIS notifiers et leur chargement asynchrone).
  Widget wrap() {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(
            body: SingleChildScrollView(
              child: HubStartTrekButton(trailId: trailId),
            ),
          ),
        ),
        GoRoute(path: '/map', builder: (_, __) => const SizedBox()),
      ],
    );
    return ProviderScope(
      child: TranslationProvider(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  /// Le [FilledButton] du CTA. `onPressed == null` = grise (gate fermee).
  FilledButton cta(WidgetTester tester) => tester.widget<FilledButton>(
        find.ancestor(
          of: find.text(t.hub.startCta),
          matching: find.byType(FilledButton),
        ),
      );

  ProviderContainer scopeOf(WidgetTester tester) => ProviderScope.containerOf(
        tester.element(find.byType(HubStartTrekButton)),
      );

  group('FIX-3 — le CTA « Démarrer » s ouvre quand la preparation est faite', () {
    testWidgets(
      'A CHAUD : le CTA passe de grise a ACTIF des le 3e signal, sans relancer '
      'l application (lecon M4 : une vue derivee doit se rafraichir)',
      (tester) async {
        SharedPreferences.setMockInitialValues(ficheMedicaleFaite);
        await tester.pumpWidget(wrap());
        await tester.pumpAndSettle();

        // Depart : rien de fait -> bouton grise + message d'aide affiche.
        expect(cta(tester).onPressed, isNull);
        expect(find.text(t.hub.startGateHint), findsOneWidget);

        final c = scopeOf(tester);
        final steps = c.read(prepareCoreStepsProvider(trailId).notifier);

        // L'utilisateur ouvre l'ecran Itineraire.
        await steps.markSeen(PrepCoreStep.itinerary);
        await tester.pumpAndSettle();
        expect(
          cta(tester).onPressed,
          isNull,
          reason: 'Itineraire seul ne doit pas ouvrir la gate',
        );

        // Puis l'ecran Programme.
        await steps.markSeen(PrepCoreStep.programme);
        await tester.pumpAndSettle();
        expect(
          cta(tester).onPressed,
          isNull,
          reason: 'la date de depart manque encore',
        );

        // Puis il pose sa date de depart dans le calendrier.
        await c
            .read(downloadReminderProvider(trailId).notifier)
            .setDepartureDate(DateTime(2026, 10, 20));
        await tester.pumpAndSettle();

        // C'est ICI que M4 se serait rejoue : sans rafraichissement de la vue
        // derivee, le bouton resterait grise alors que tout est rempli.
        expect(
          cta(tester).onPressed,
          isNotNull,
          reason: 'les 3 signaux sont poses : le CTA doit etre ACTIF',
        );
        expect(find.text(t.hub.startGateHint), findsNothing);
      },
    );

    testWidgets(
      'AU BOOT : les 3 signaux deja persistes rendent le CTA ACTIF une fois les '
      'prefs relues (chargement asynchrone du notifier)',
      (tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'prepare_core_steps_$trailId': <String>['itinerary', 'programme'],
          'departure_date_$trailId': '2026-10-20T00:00:00.000',
          ...ficheMedicaleFaite,
        });
        await tester.pumpWidget(wrap());
        await tester.pumpAndSettle();

        expect(
          cta(tester).onPressed,
          isNotNull,
          reason: 'preparation deja faite en prefs : le CTA doit etre ACTIF',
        );
        expect(find.text(t.hub.startGateHint), findsNothing);
      },
    );
  });

  group('FIX-3 — la relecture des prefs n ecrase pas une etape marquee', () {
    /// COURSE REELLE. `build()` lance `_loadFromPrefs()` SANS l'attendre, et
    /// chaque ecran coeur appelle `markSeen` des son ouverture. Si l'ecran
    /// marque son etape pendant que la relecture est en vol, la relecture (qui
    /// rend la main la PREMIERE, son `await` ayant ete pose en premier) ecrase
    /// l'etat avec la valeur d'AVANT le marquage : l'etape est perdue en
    /// memoire alors qu'elle est bien ecrite en prefs. L'utilisateur voit alors
    /// un bouton grise avec une preparation complete — le symptome exact
    /// remonte par la QA. La relecture doit FUSIONNER, jamais ecraser.
    test(
      'un markSeen concurrent de la relecture au build survit (gate ouverte)',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'prepare_core_steps_$trailId': <String>['programme'],
          'departure_date_$trailId': '2026-10-20T00:00:00.000',
          ...ficheMedicaleFaite,
        });
        final c = ProviderContainer();
        addTearDown(c.dispose);

        // Le cockpit observe la gate : c'est CE premier acces qui construit les
        // deux notifiers et lance leurs relectures de prefs, encore en vol.
        expect(c.read(prepareCoreDoneProvider(trailId)), isFalse);

        // Dans la foulee, l'ecran Itineraire marque son etape : le marquage et
        // la relecture se croisent. C'est la course a verrouiller.
        await c
            .read(prepareCoreStepsProvider(trailId).notifier)
            .markSeen(PrepCoreStep.itinerary);
        // On laisse toutes les continuations asynchrones se derouler.
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // PERSISTANCE : `markSeen` ecrit la liste ENTIERE. S'il la calcule sur
        // un etat perime (la relecture n'a pas encore rendu la main), il
        // DETRUIT en prefs l'etape deja acquise -> l'utilisateur perd pour de
        // bon une carte qu'il avait faite, et la gate ne se rouvrira pas au
        // prochain lancement. C'est le coeur du defaut.
        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getStringList('prepare_core_steps_$trailId'),
          containsAll(<String>['itinerary', 'programme']),
          reason: 'le marquage ne doit pas ecraser une etape deja persistee',
        );

        // MEMOIRE : la vue derivee doit porter les DEUX etapes.
        expect(
          c.read(prepareCoreStepsProvider(trailId)),
          containsAll(<PrepCoreStep>[
            PrepCoreStep.itinerary,
            PrepCoreStep.programme,
          ]),
          reason: 'la relecture des prefs ne doit pas perdre le marquage',
        );
        expect(
          c.read(prepareCoreDoneProvider(trailId)),
          isTrue,
          reason: 'Itineraire + Programme + Date : la gate doit etre ouverte',
        );
      },
    );

    /// Meme course sur l'autre entree du gate : la DATE de depart, posee
    /// pendant que la relecture initiale est en vol. Contrairement aux etapes,
    /// `setDepartureDate` ecrit une valeur SCALAIRE qu'il porte lui-meme (il ne
    /// recalcule pas une liste a partir de l'etat) : il n'y a donc pas de mise
    /// a jour perdue ici. Ce test VERROUILLE cette propriete — si un jour la
    /// date devient derivee d'un etat relu, la regression sera vue tout de suite.
    test(
      'une date posee pendant la relecture au build survit',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final c = ProviderContainer();
        addTearDown(c.dispose);

        // Premier acces = build() -> relecture des prefs EN VOL.
        final reminder = c.read(downloadReminderProvider(trailId).notifier);
        await reminder.setDepartureDate(DateTime(2026, 10, 20));
        await Future<void>.delayed(Duration.zero);

        expect(
          c.read(downloadReminderProvider(trailId)).departureDate,
          isNotNull,
          reason: 'la relecture des prefs ne doit pas effacer la date posee',
        );
      },
    );
  });
}
