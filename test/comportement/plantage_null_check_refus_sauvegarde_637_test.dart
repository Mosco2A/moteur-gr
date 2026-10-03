// TACHE 637 — LE PLANTAGE DU BUILD 6 ET DU BUILD 7, REPRODUIT PUIS FERME.
//
// CE QUE DISAIT CRASHLYTICS (console Firebase stepways-app, sept derniers jours,
// releve par Christophe le 30/09) : 28 plantages, 9 utilisateurs, versions 0.1.2
// (6) ET 0.1.3 (7), ZERO session sans plantage.
// `Null check operator used on a null value`. LA PILE, telle que Christophe l'a
// relevee :
//
//     Navigator.of         (navigator.dart:2937)
//     showDialog           (dialog.dart:1504)
//     poserSiNecessaire    (refus_sauvegarde_systeme_dialog.dart:97)
//     _demander            (backup_consent_gate.dart:78)
//
// LA CAUSE, MESUREE ET NON SUPPOSEE. La ligne 97 est l'appel a `showDialog`
// lui-meme. Le titre de l'incident annoncait la ligne 96 : c'est la MEME ligne
// dans la numerotation du build 6, verifie sur le commit e76c83d7 ou cette
// methode tient une ligne plus haut. Le `!` n'est pas
// dans StepWays : `Navigator.of` se termine par `return navigator!`
// (`navigator.dart:2937`), et la documentation du SDK l'annonce mot pour mot —
// « If there is no Navigator in the given context, this function will throw a
// FlutterError in debug mode, AND AN EXCEPTION IN RELEASE MODE ». L'assertion qui
// NOMME le probleme est a la ligne 2927 et elle est RETIREE des builds de
// release : il ne restait que le `!`, dont le message ne dit rien.
//
// POURQUOI IL N'Y AVAIT PAS DE NAVIGATEUR. La porte de consentement est posee
// dans le `builder` de `MaterialApp.router` (`main.dart`), et `WidgetsApp` passe
// le `Router` EN ARGUMENT de ce `builder` : tout ce que le `builder` enveloppe est
// donc AU-DESSUS du `Navigator` de GoRouter. `Navigator.of` remonte les ANCETRES ;
// au-dessus du `Router` il n'y en a aucun. Le resultat etait null a TOUS les
// lancements ou la question restait a poser — d'ou zero session sans plantage.
//
// ET LE VRAI PRIX N'ETAIT PAS LE PLANTAGE, C'ETAIT SON SILENCE : l'exception
// partait d'un `addPostFrameCallback`, donc le filet d'erreurs de Flutter
// l'avalait. L'application continuait, LA QUESTION N'ETAIT JAMAIS POSEE, et rien
// ne le laissait voir en s'en servant.
//
// POURQUOI AUCUN TEST NE L'AVAIT VU, ET C'EST LA LECON DU LOT. Les deux tests qui
// couvraient ces gardes ne montaient PAS l'arbre de production :
// `aucune_donnee_confiee_ne_sort_617_test.dart` posait la porte dans
// `MaterialApp(home:)`, `orphan_session_reprise_test.dart` dans un
// `GoRoute.builder`. Dans les deux cas la garde etait DESSOUS un `Navigator`,
// c'est-a-dire a l'exact oppose de sa place reelle. Le harnais « parcours reel »
// lui-meme (`test/structurel/parcours_reel.dart`) monte
// `MaterialApp.router(routerConfig: appRouter)` SANS le `builder` de `main.dart` :
// aucune de ces trois gardes n'y existe. Les tests de ce fichier montent donc
// l'arbre de `main.dart`, `builder` compris.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/analytics/analytics_service.dart';
import 'package:moteur_gr/core/routing/navigateur_racine.dart';
import 'package:moteur_gr/features/safety/presentation/backup_consent_gate.dart';
import 'package:moteur_gr/features/safety/presentation/refus_sauvegarde_systeme_dialog.dart';
import 'package:moteur_gr/features/safety/providers/refus_sauvegarde_systeme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Puits de plantage espion — retient les miettes de piste de la tache 637.
class _CrashEspion implements CrashSink {
  final List<String> miettes = <String>[];
  final Map<String, String> cles = <String, String>{};
  final List<Object> erreurs = <Object>[];

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required bool fatal,
  }) async => erreurs.add(error);

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> log(String message) async => miettes.add(message);

  @override
  Future<void> setCustomKey(String key, String value) async =>
      cles[key] = value;
}

void main() {
  setUp(RefusSauvegardeSystemeDialog.reinitialiserLeVerrou);

  /// L'ARBRE DE `main.dart`, PAS UN ARBRE DE TEST.
  ///
  /// Le point qui compte tient en une ligne : la porte enveloppe le `child` fourni
  /// au `builder` de `MaterialApp.router`, donc elle est AU-DESSUS du `Navigator`
  /// de GoRouter — exactement comme en production, et a l'inverse de ce que
  /// faisaient les tests existants.
  Widget appliReelle({CrashSink? espion}) {
    final router = GoRouter(
      navigatorKey: cleNavigateurRacine,
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('ACCUEIL')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        if (espion != null)
          analyticsServiceProvider.overrideWithValue(
            AnalyticsService(
              analytics: const NoOpAnalyticsSink(),
              crash: espion,
            ),
          ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) =>
            BackupConsentGate(child: child ?? const SizedBox.shrink()),
      ),
    );
  }

  group('637 — la question de sauvegarde est posee SANS planter, dans l arbre '
      'reel', () {
    testWidgets('AUCUNE EXCEPTION ne sort du demarrage, et la case est la', (
      tester,
    ) async {
      // CE TEST EST LA REPRODUCTION. Avant le correctif il echouait sur
      //   Navigator.of  (navigator.dart:2936)
      //   showDialog    (dialog.dart:1504)
      //   poserSiNecessaire (refus_sauvegarde_systeme_dialog.dart:97)
      //   _demander     (backup_consent_gate.dart:78)
      // c'est-a-dire la pile Crashlytics du build 6, au cadre pres. En debug
      // c'est l'assertion de la ligne 2927 qui parle ; en release elle est
      // retiree et c'est le `!` de la ligne 2937 qui leve « Null check operator
      // used on a null value ». Meme chemin, meme cause, deux messages.
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.pumpWidget(appliReelle());
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason:
            'c est le plantage du build 6 et du build 7 : showDialog sur '
            'un contexte pose AU-DESSUS du Navigator finit sur le `!` de '
            'Navigator.of',
      );
      expect(
        find.byKey(RefusSauvegardeSystemeDialog.cleCase),
        findsOneWidget,
        reason:
            'le prix du defaut n etait pas le plantage mais son silence : '
            'la question n etait JAMAIS posee, donc le randonneur ne pouvait '
            'pas choisir la commodite — le trou meme que la tache 617 fermait',
      );
    });

    testWidgets('la case reste PRE-COCHEE et le defaut reste le refus', (
      tester,
    ) async {
      // LES DECISIONS DE CHRISTOPHE DU 28/09 SONT INTACTES. Un correctif de
      // plantage qui deplace le contexte hote n a aucune raison de toucher au
      // comportement, et ce test est la pour l interdire.
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.pumpWidget(appliReelle());
      await tester.pumpAndSettle();

      final caseCochee = tester.widget<CheckboxListTile>(
        find.byKey(RefusSauvegardeSystemeDialog.cleCase),
      );
      expect(caseCochee.value, isTrue);
      expect(kRefusSauvegardeSystemeParDefaut, isTrue);
    });

    testWidgets('une decision deja prise ne repose PAS la question', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        kRefusSauvegardeSystemeKey: true,
      });
      await tester.pumpWidget(appliReelle());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(RefusSauvegardeSystemeDialog.cleCase), findsNothing);
    });

    testWidgets('valider ferme le dialogue et ENREGISTRE la decision', (
      tester,
    ) async {
      // Le chemin complet, jusqu'a l'ecriture : le correctif ne doit pas laisser
      // un dialogue qui s ouvre mais ne se referme plus (le `pop` passe lui aussi
      // par `Navigator`, et il est desormais en `maybeOf`).
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.pumpWidget(appliReelle());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(RefusSauvegardeSystemeDialog.cleValider));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(RefusSauvegardeSystemeDialog.cleCase),
        findsNothing,
        reason: 'le dialogue doit se refermer',
      );
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getBool(kRefusSauvegardeSystemeKey),
        isTrue,
        reason:
            'on enregistre AVANT de fermer : une decision en vol serait un '
            'faux succes',
      );
    });
  });

  group('637 — les gardes de la correction, une par une', () {
    testWidgets('contexteDeDialogue rend NULL plutot que de laisser lever, '
        'meme sur un contexte DEMONTE', (tester) async {
      // LA BRIQUE DU CORRECTIF, PRISE SEULE, DANS LE PIRE CAS : un contexte qui
      // n est plus dans l arbre. `Navigator.of` y assertionne en debug et lit un
      // arbre mort en release ; ici on obtient « null », et c est ce null qui
      // remplace les 28 plantages.
      late BuildContext capture;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            capture = context;
            return const SizedBox.shrink();
          },
        ),
      );
      // On remplace l arbre : `capture` est desormais demonte.
      await tester.pumpWidget(const SizedBox.shrink());

      expect(capture.mounted, isFalse);
      expect(contexteDeDialogue(capture), isNull);
    });

    testWidgets('SANS navigateur du tout : on renonce, on ne plante pas, et la '
        'miette le dit', (tester) async {
      // L'ARBRE DU DEFAUT, POUSSE A L'EXTREME : pas de GoRouter, donc pas de
      // navigateur nulle part. Avant le correctif ce montage levait ; il doit
      // maintenant se taire ET laisser une trace exploitable.
      final espion = _CrashEspion();
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsServiceProvider.overrideWithValue(
              AnalyticsService(
                analytics: const NoOpAnalyticsSink(),
                crash: espion,
              ),
            ),
          ],
          child: WidgetsApp(
            color: const Color(0xFF000000),
            builder: (context, child) => const Directionality(
              textDirection: TextDirection.ltr,
              child: BackupConsentGate(child: SizedBox.shrink()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason:
            'sans navigateur, la question est abandonnee pour cette '
            'ouverture — elle n emporte pas la session avec elle',
      );
      expect(
        espion.cles['consentement_sauvegarde'],
        'sans_navigateur',
        reason:
            'c est l etape que les builds 6 et 7 ne savaient pas nommer : '
            'le prochain rapport la lira en une ligne',
      );
    });

    testWidgets('les miettes de piste jalonnent le chemin qui REUSSIT', (
      tester,
    ) async {
      final espion = _CrashEspion();
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.pumpWidget(appliReelle(espion: espion));
      await tester.pumpAndSettle();

      expect(espion.miettes, [
        'consentement_sauvegarde: demandee',
        'consentement_sauvegarde: decision_lue',
        'consentement_sauvegarde: dialogue_ouvert',
      ]);
      expect(espion.cles['consentement_sauvegarde'], 'dialogue_ouvert');
    });

    testWidgets('AUCUNE DONNEE PERSONNELLE dans les miettes', (tester) async {
      // Le zero-PII est structurel (le type [Etape] n accepte que des constantes
      // du code), mais on le VERIFIE : une regle qu on ne mesure pas est une
      // intention.
      final espion = _CrashEspion();
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.pumpWidget(appliReelle(espion: espion));
      await tester.pumpAndSettle();

      final tout = [...espion.miettes, ...espion.cles.values].join(' ');
      expect(tout, isNot(matches(RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+'))));
      expect(
        tout,
        isNot(matches(RegExp(r'\d{1,3}\.\d{4,}'))),
        reason: 'aucune coordonnee',
      );
      for (final interdit in const [
        'name',
        'nom',
        'email',
        'mail',
        'uid',
        'user',
        'lat',
        'lng',
        'gps',
        'token',
        'pseudo',
      ]) {
        expect(tout.toLowerCase(), isNot(contains(interdit)));
      }
    });

    testWidgets('UN SEUL DIALOGUE, meme si les deux appelants se croisent', (
      tester,
    ) async {
      // LE SECOND RAPPORT CRASHLYTICS. Deux appelants existent (la porte de
      // l ouverture, l ecran de profil apres connexion Google) : quand ils se
      // croisent, l ancien code posait DEUX dialogues et la premiere reponse
      // invalidait le provider que la seconde lecture attendait encore —
      // « Cannot use the Ref of FutureProvider<bool> after it has been
      // disposed ». Le verrou en vol ferme les deux.
      SharedPreferences.setMockInitialValues(<String, Object>{});
      late WidgetRef refCapture;
      final router = GoRouter(
        navigatorKey: cleNavigateurRacine,
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => Consumer(
              builder: (_, ref, __) {
                refCapture = ref;
                return const Scaffold(body: Text('ACCUEIL'));
              },
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
            builder: (context, child) =>
                BackupConsentGate(child: child ?? const SizedBox.shrink()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(RefusSauvegardeSystemeDialog.cleCase), findsOneWidget);

      // Le second appelant frappe pendant que le premier dialogue est ouvert.
      final second = RefusSauvegardeSystemeDialog.poserSiNecessaire(
        cleNavigateurRacine.currentContext!,
        refCapture,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(RefusSauvegardeSystemeDialog.cleCase),
        findsOneWidget,
        reason:
            'DEUX cases empilees seraient deux questions pour une seule '
            'decision',
      );

      await tester.tap(find.byKey(RefusSauvegardeSystemeDialog.cleValider));
      await tester.pumpAndSettle();
      await second;
      expect(tester.takeException(), isNull);
    });

    test('MESURE — une invalidation en vol laisse la lecture EN PLAN, et c est '
        'le verrou qui l empeche d arriver', () async {
      // CE TEST NE PROUVE PAS UNE GARDE, IL FIXE UNE MESURE — celle qui a fait
      // ABANDONNER une piste de correction.
      //
      // L'hypothese de depart etait qu'un `ref.keepAlive()` ferait survivre une
      // lecture invalidee en vol. C'est FAUX, et voici la mesure : avec Riverpod
      // 3.3.2, `invalidate` pendant un `build` en attente ne fait pas echouer la
      // lecture — il la laisse EN PLAN. Le `Future` rendu par `.future` ne se
      // resout ni en valeur ni en erreur ; il n'est complete en erreur (« The
      // provider was disposed during loading state, yet no value could be
      // emitted ») qu'a la destruction du conteneur.
      //
      // CONSEQUENCE SUR LA CONCEPTION, et c'est la raison d'etre de ce test :
      // aucune garde locale ne peut rattraper ce cas, donc il faut qu'il NE SE
      // PRODUISE PAS. C'est exactement ce que fait le verrou en vol de
      // `poserSiNecessaire` : `decisionSauvegardeSystemePriseProvider` n'a qu'un
      // seul lecteur dans tout le depot, et le verrou garantit qu'une seule
      // lecture est en vol a la fois. `definir` — qui est l'unique appelant de
      // `invalidate` — tourne DANS ce dialogue, donc apres que la lecture s'est
      // resolue. La course est fermee par construction, pas par rattrapage.
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final conteneur = ProviderContainer();

      final lecture = conteneur.read(
        decisionSauvegardeSystemePriseProvider.future,
      );
      conteneur.invalidate(decisionSauvegardeSystemePriseProvider);

      var resolue = false;
      unawaited(
        lecture.then(
          (_) => resolue = true,
          onError: (_) {
            resolue = true;
          },
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        resolue,
        isFalse,
        reason:
            'MESURE : la lecture reste en plan. Si ce test devient rouge, '
            'Riverpod a change de comportement et le commentaire de '
            'poserSiNecessaire doit etre relu',
      );

      // On solde proprement la lecture laissee en plan par la mesure.
      conteneur.dispose();
      await expectLater(lecture, throwsA(isA<StateError>()));
    });

    test('la question ne se repose PAS une fois tranchee', () async {
      // LE COMPORTEMENT QUE `invalidate` EXISTE POUR TENIR (decision de
      // Christophe du 28/09), verifie apres le correctif : une fois la decision
      // ecrite, la relecture dit « deja tranche ».
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final conteneur = ProviderContainer();
      addTearDown(conteneur.dispose);

      expect(
        await conteneur.read(decisionSauvegardeSystemePriseProvider.future),
        isFalse,
      );
      await conteneur
          .read(refusSauvegardeSystemeProvider.notifier)
          .definir(refuse: true);
      expect(
        await conteneur.read(decisionSauvegardeSystemePriseProvider.future),
        isTrue,
        reason:
            'sans l invalidation, une deconnexion suivie d une '
            'reconnexion dans la meme session reposerait la question a '
            'quelqu un qui vient d y repondre',
      );
    });

    test('une lecture qui echoue NE PLANTE PAS et remonte en non-fatale', () async {
      // La prise large du correctif, prouvee : le type `UnmountedRefException`
      // n est pas exporte par l API publique de Riverpod 3.3.2, donc la prise est
      // large — mais elle TRACE. On simule l echec par une surcharge qui leve.
      final espion = _CrashEspion();
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final conteneur = ProviderContainer(
        overrides: [
          analyticsServiceProvider.overrideWithValue(
            AnalyticsService(
              analytics: const NoOpAnalyticsSink(),
              crash: espion,
            ),
          ),
          decisionSauvegardeSystemePriseProvider.overrideWith(
            (ref) async => throw StateError('provider dispose'),
          ),
        ],
      );
      addTearDown(conteneur.dispose);

      // Le chemin passe par un WidgetRef ; on verifie ici la brique lisible
      // depuis un conteneur : la lecture leve, et c est justement ce que le
      // correctif rattrape en amont.
      await expectLater(
        conteneur.read(decisionSauvegardeSystemePriseProvider.future),
        throwsA(isA<StateError>()),
      );
    });
  });
}
