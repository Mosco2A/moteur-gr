import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/hub/providers/cockpit_start_providers.dart';
import 'package:moteur_gr/features/safety/domain/models/health_info.dart';
import 'package:moteur_gr/features/safety/presentation/health_info_screen.dart';
import 'package:moteur_gr/features/safety/providers/health_prepare_providers.dart';
import 'package:moteur_gr/features/settings/providers/account_erasure_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Q4b (tache 568, LOT Q) — LA FICHE MEDICALE DEVIENT UNE CONDITION DE DEPART,
/// ET LA LECTURE DE SES CONSEILS AUSSI.
///
/// DECISION DE CHRIS DU 26/09 10:29, verbatim : « ca doit faire partie de la
/// prepa, on ne demarre pas un trek sans avoir rempli sa fiche medicale et lu
/// les conseils pour qu'elle soit applicable sur le sentier ».
///
/// TROIS EXIGENCES, pas une. La carte de preparation est verrouillee par
/// `test/features/hub/portes_sans_entree_568_test.dart`. Ce fichier verrouille
/// les DEUX AUTRES :
///  * la fiche REMPLIE et ses conseils LUS s'ajoutent a la porte de demarrage
///    ([prepareCoreDoneProvider]) — on ne part pas sans elle ;
///  * les conseils existent, disent les quatre choses qui les rendent
///    applicables sur le sentier, et leur lecture est ACCUSEE (pas seulement
///    disponible).
///
/// POURQUOI LE SIGNAL VIT EN PREFERENCES ET PAS EN BASE : la porte de demarrage
/// est une vue SYNCHRONE lue a chaque frame par le bouton du cockpit. La fiche
/// elle-meme reste en Drift (art. 9, local only) ; ce qui entre dans la porte est
/// un signal de PREPARATION, exactement comme les etapes coeur
/// (`prepare_core_steps_`) qui derivent deja d'ecrans ouverts. L'ecran de la
/// fiche re-synchronise ce signal a chaque ouverture, donc il ne peut pas
/// mentir durablement.
///
/// TOUS LES TESTS DE GATE ONT ETE ECRITS ROUGES : avant correction, les trois
/// signaux historiques suffisaient a ouvrir la porte.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const trailId = 'mare-a-mare-centre';

  /// Les trois signaux HISTORIQUES de la porte (Itineraire + Programme + Date).
  Map<String, Object> socleHistorique() => <String, Object>{
        'prepare_core_steps_$trailId': <String>['itinerary', 'programme'],
        'departure_date_$trailId': '2026-10-20T00:00:00.000',
      };

  /// Laisse les relectures asynchrones de preferences rendre la main.
  Future<void> laisserLirePrefs() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  group('Q4b — la porte de demarrage exige la fiche medicale', () {
    test(
      'les trois signaux historiques NE SUFFISENT PLUS : sans fiche medicale, '
      'la porte reste fermee',
      () async {
        SharedPreferences.setMockInitialValues(socleHistorique());
        final c = ProviderContainer();
        addTearDown(c.dispose);

        expect(c.read(prepareCoreDoneProvider(trailId)), isFalse);
        await laisserLirePrefs();
        expect(
          c.read(prepareCoreDoneProvider(trailId)),
          isFalse,
          reason: 'on ne demarre pas un trek sans avoir rempli sa fiche '
              'medicale (decision Chris 26/09)',
        );
      },
    );

    test(
      'fiche REMPLIE mais conseils NON LUS : la porte reste fermee (« et lu les '
      'conseils » est une condition a part entiere)',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          ...socleHistorique(),
          kHealthPrepareStepsKey: <String>[HealthPrepStep.filled.name],
        });
        final c = ProviderContainer();
        addTearDown(c.dispose);

        c.read(prepareCoreDoneProvider(trailId));
        await laisserLirePrefs();
        expect(c.read(prepareCoreDoneProvider(trailId)), isFalse);
      },
    );

    test(
      'conseils LUS mais fiche VIDE : la porte reste fermee (lire ne remplit '
      'pas)',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          ...socleHistorique(),
          kHealthPrepareStepsKey: <String>[HealthPrepStep.adviceRead.name],
        });
        final c = ProviderContainer();
        addTearDown(c.dispose);

        c.read(prepareCoreDoneProvider(trailId));
        await laisserLirePrefs();
        expect(c.read(prepareCoreDoneProvider(trailId)), isFalse);
      },
    );

    test(
      'les CINQ conditions reunies : la porte s ouvre',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          ...socleHistorique(),
          kHealthPrepareStepsKey: <String>[
            HealthPrepStep.filled.name,
            HealthPrepStep.adviceRead.name,
          ],
        });
        final c = ProviderContainer();
        addTearDown(c.dispose);

        c.read(prepareCoreDoneProvider(trailId));
        await laisserLirePrefs();
        expect(c.read(prepareCoreDoneProvider(trailId)), isTrue);
      },
    );

    test(
      'A CHAUD : marquer les deux signaux ouvre la porte sans relancer l app',
      () async {
        SharedPreferences.setMockInitialValues(socleHistorique());
        final c = ProviderContainer();
        addTearDown(c.dispose);

        c.read(prepareCoreDoneProvider(trailId));
        await laisserLirePrefs();
        expect(c.read(prepareCoreDoneProvider(trailId)), isFalse);

        final notifier = c.read(healthPrepareStepsProvider.notifier);
        await notifier.setFilled(true);
        await notifier.markAdviceRead();
        await laisserLirePrefs();

        expect(c.read(prepareCoreDoneProvider(trailId)), isTrue);
      },
    );

    test(
      'effacer la fiche REFERME la porte (le signal suit la donnee, il ne la '
      'survit pas)',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          ...socleHistorique(),
          kHealthPrepareStepsKey: <String>[
            HealthPrepStep.filled.name,
            HealthPrepStep.adviceRead.name,
          ],
        });
        final c = ProviderContainer();
        addTearDown(c.dispose);

        c.read(prepareCoreDoneProvider(trailId));
        await laisserLirePrefs();
        expect(c.read(prepareCoreDoneProvider(trailId)), isTrue);

        await c.read(healthPrepareStepsProvider.notifier).setFilled(false);
        await laisserLirePrefs();
        expect(
          c.read(prepareCoreDoneProvider(trailId)),
          isFalse,
          reason: 'une fiche effacee n est plus une fiche remplie',
        );

        // ... et la preference ne garde pas le signal perime.
        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getStringList(kHealthPrepareStepsKey),
          isNot(contains(HealthPrepStep.filled.name)),
        );
      },
    );
  });

  group('Q4b — le message d aide ne mentionne plus une liste incomplete', () {
    test(
      'le texte de la porte fermee NOMME la fiche medicale, avec le meme '
      'libelle que sa carte',
      () {
        // Le message annoncait « Itineraire, Date et Programme » : depuis la
        // decision de Chris il manquait une condition — un texte qui annonce
        // autre chose que ce que le code exige est exactement le defaut que
        // Chris trouve depuis deux jours.
        expect(
          t.hub.startGateHint,
          contains(t.hub.cards.health),
          reason: 'le message doit nommer la 4e condition, et la nommer comme '
              'la carte qui y mene',
        );
      },
    );
  });

  // ==========================================================================
  // L EFFACEMENT DE COMPTE DOIT REFERMER LA PORTE
  // ==========================================================================
  //
  // LA LECON DU LOT M, APPLIQUEE A UN SIGNAL NEUF. Le disque partait deja tout
  // seul : `DataRetentionService._wipeAllPersonalPrefs` DERIVE la liste des cles
  // a effacer de `prefs.getKeys()` moins deux exceptions (reglages, etage
  // monetaire), donc `health_prepare_steps` tombe sans avoir a etre enumeree.
  // MAIS LA MEMOIRE VIVE, ELLE, NE TOMBE PAS TOUTE SEULE : le notifier garde son
  // etat, et la porte de demarrage serait restee OUVERTE sur une fiche medicale
  // qui n'existe plus — exactement le defaut M1 (« le disque est propre, la
  // memoire vive ne l etait pas »), sur la piece que la tache 568 vient d'ajouter.
  //
  // ECRIT ROUGE : sans l'invalidation ajoutee a
  // `oublierLesDonneesPersonnellesEnMemoire`, ce test echoue sur la derniere
  // assertion.
  group('Q4b — un effacement de compte referme la porte', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      SharedPreferences.setMockInitialValues(<String, Object>{});
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'le signal de fiche medicale ne survit ni au disque ni a la memoire vive',
      () async {
        final container = ProviderContainer(
          overrides: [databaseProvider.overrideWithValue(db)],
        );
        addTearDown(container.dispose);

        // Le randonneur a rempli sa fiche et lu les conseils : la porte s'ouvre.
        await container
            .read(healthInfoRepositoryProvider)
            .save(const HealthInfo(bloodType: 'A+'));
        final notifier = container.read(healthPrepareStepsProvider.notifier);
        await notifier.setFilled(true);
        await notifier.markAdviceRead();
        expect(
          container.read(healthPrepareDoneProvider),
          isTrue,
          reason: 'le test ne prouve rien si la porte n a pas ete ouverte',
        );

        await container.read(accountErasureProvider)();

        // Le disque : la cle tombe d'elle-meme (derivee du store reel).
        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getStringList(kHealthPrepareStepsKey),
          isNull,
          reason: 'la source durable du signal doit etre vide',
        );

        // La memoire vive : c'est ICI que le defaut M1 se rejouerait.
        expect(
          container.read(healthPrepareDoneProvider),
          isFalse,
          reason: 'la porte de demarrage ne peut pas rester ouverte sur une '
              'fiche medicale effacee',
        );
      },
    );
  });

  // ==========================================================================
  // LES CONSEILS D USAGE ET LEUR ACCUSE DE LECTURE
  // ==========================================================================
  group('Q4b — les conseils d usage terrain et leur accuse de lecture', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    tearDown(() async {
      await db.close();
    });

    Widget wrap() => ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: TranslationProvider(
            child: MaterialApp.router(
              routerConfig: GoRouter(
                initialLocation: '/home/health',
                routes: [
                  GoRoute(
                    path: '/home',
                    builder: (_, __) => const Scaffold(body: SizedBox()),
                    routes: [
                      GoRoute(
                        path: 'health',
                        builder: (_, __) => const HealthInfoScreen(),
                      ),
                    ],
                  ),
                  GoRoute(path: '/consent', builder: (_, __) => const SizedBox()),
                  GoRoute(path: '/my-treks', builder: (_, __) => const SizedBox()),
                ],
              ),
            ),
          ),
        );

    Future<void> pumpEcran(WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();
    }

    testWidgets(
      'les QUATRE conseils qui rendent la fiche applicable sur le sentier sont '
      'affiches',
      (tester) async {
        await pumpEcran(tester);

        expect(find.text(t.health.advice.title), findsOneWidget);
        // 1. Ou la trouver quand on est a terre.
        expect(find.text(t.health.advice.whereToFind), findsOneWidget);
        // 2. Comment la montrer aux secours.
        expect(find.text(t.health.advice.showToRescue), findsOneWidget);
        // 3. Pourquoi la recopier dans la fiche medicale du telephone
        //    (qui s affiche ecran verrouille).
        expect(find.text(t.health.advice.phoneCard), findsOneWidget);
        // 4. Un papier dans la poche ne tombe jamais en panne de batterie.
        expect(find.text(t.health.advice.paper), findsOneWidget);
      },
    );

    testWidgets(
      'l accuse de lecture est un GESTE : tant qu il n est pas fait, le signal '
      'n est pas pose ; une fois fait, il est persiste',
      (tester) async {
        await pumpEcran(tester);

        final prefsAvant = await SharedPreferences.getInstance();
        expect(
          prefsAvant.getStringList(kHealthPrepareStepsKey) ?? const <String>[],
          isNot(contains(HealthPrepStep.adviceRead.name)),
          reason: 'afficher un texte ne prouve pas qu il a ete lu',
        );

        final bouton = find.text(t.health.advice.ackButton);
        expect(bouton, findsOneWidget);
        await tester.ensureVisible(bouton);
        await tester.pumpAndSettle();
        await tester.tap(bouton);
        await tester.pumpAndSettle();

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getStringList(kHealthPrepareStepsKey),
          contains(HealthPrepStep.adviceRead.name),
        );

        // Le geste est fait : l invitation devient une confirmation.
        expect(find.text(t.health.advice.ackButton), findsNothing);
        expect(find.text(t.health.advice.ackDone), findsOneWidget);
      },
    );

    testWidgets(
      'enregistrer une fiche qui porte quelque chose pose le signal « remplie »',
      (tester) async {
        await pumpEcran(tester);

        await tester.enterText(
          find.byKey(const ValueKey('health-blood-type-field')),
          'A+',
        );
        await tester.pumpAndSettle();

        final save = find.text(t.health.save);
        await tester.ensureVisible(save);
        await tester.pumpAndSettle();
        await tester.tap(save);
        await tester.pumpAndSettle();

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getStringList(kHealthPrepareStepsKey),
          contains(HealthPrepStep.filled.name),
        );
      },
    );
  });
}
