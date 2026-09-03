import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/features/feasibility/data/feasibility_question_loader.dart';
import 'package:moteur_gr/features/feasibility/data/feasibility_questions.dart';
import 'package:moteur_gr/features/feasibility/presentation/feasibility_questionnaire_screen.dart';
import 'package:moteur_gr/features/feasibility/presentation/feasibility_result_screen.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_calculator.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// PARITE GR20 (#99460) — ecran FAISABILITE (auto-evaluation -> verdict).
///
/// Clone de l'ecran GR20 : questionnaire complet -> verdict + ecran resultat
/// (badge niveau + carte recommandation + conseils + points forts/faibles +
/// « Recommencer »). Ces tests couvrent, cote StepWays :
///   - le questionnaire complet (repondre a toutes les questions) ;
///   - le verdict correct affiche a la fin (niveau resolu via Slang) ;
///   - l'ecran resultat (jauge, recommandation, conseils, bouton refaire) ;
///   - la navigation aller/retour sans crash (carte HUB -> ecran -> retour).
void main() {
  // Questions chargees une fois, de facon SYNCHRONE, depuis le meme JSON que
  // les assets. En `flutter test`, `rootBundle.loadString` (utilise par le
  // FutureProvider de prod) depend de l'event-loop reel et ne se resout pas de
  // maniere fiable en pompant du temps simule -> on injecte les questions via
  // un override de provider (Future deja complet) pour un flux deterministe,
  // sans I/O asynchrone. Le chargement JSON reel est couvert ailleurs
  // (feasibility_question_loader_test.dart / feasibility_questionnaire_test.dart).
  late final List<FeasibilityQuestion> questions;

  setUpAll(() {
    // Slang en francais (base_locale) pour resoudre les libelles.
    LocaleSettings.setLocaleRaw('fr');
    final jsonContent = File(
      'assets/data/feasibility_questions.json',
    ).readAsStringSync();
    questions = FeasibilityQuestionLoader.parseQuestions(jsonContent);
  });

  /// Override du provider de questions : renvoie un Future deja complet, dont la
  /// valeur est livree des la premiere micro-tache (pompee par `pump`).
  overrides() => [
    questionsFromJsonProvider.overrideWith((ref) => Future.value(questions)),
  ];

  /// Fait avancer le temps par petits pas bornes, SANS `pumpAndSettle`.
  ///
  /// Gotcha (#99460) : l'ecran monte un `CircularProgressIndicator()`
  /// indetermine (etat loading du FutureProvider de questions, puis etat
  /// « questions vides » avant le postFrameCallback d'initialisation) et la
  /// jauge de resultat est aussi un `CircularProgressIndicator(value:)`. Un
  /// spinner indetermine tourne indefiniment -> `pumpAndSettle` timeout. On
  /// pompe donc un nombre BORNE de frames, ce qui laisse le FutureProvider se
  /// resoudre, le postFrameCallback s'executer et les rebuilds se propager,
  /// sans jamais attendre un « repos » qui n'arrivera pas.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Pompe (borne) jusqu'a ce que [finder] trouve au moins [minMatches]
  /// widgets, ou jusqu'a [maxFrames] frames. Complement de [settle] pour les
  /// transitions asynchrones (chargement JSON du FutureProvider de questions,
  /// puis initialisation via postFrameCallback) : chaque `await pump` cede la
  /// main a la boucle d'evenements, ce qui laisse le Future d'asset se resoudre
  /// sur plusieurs frames — sans jamais attendre un repos qui n'arrive pas
  /// (spinner indetermine). Echoue proprement (retourne) si non atteint : le
  /// `expect` appelant produira alors un diagnostic clair.
  Future<void> pumpUntil(
    WidgetTester tester,
    Finder finder, {
    int minMatches = 1,
    int maxFrames = 40,
  }) async {
    for (var i = 0; i < maxFrames; i++) {
      if (tester.widgetList(finder).length >= minMatches) return;
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Enveloppe un [child] avec ProviderScope + Translations + un GoRouter
  /// minimal (le questionnaire n'utilise pas la nav, mais MaterialApp.router
  /// fournit le Navigator attendu par les widgets Material).
  Widget wrap(Widget child) {
    final router = GoRouter(
      initialLocation: '/f',
      routes: [GoRoute(path: '/f', builder: (_, __) => child)],
    );
    return ProviderScope(
      overrides: overrides(),
      child: TranslationProvider(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  /// Repond a toutes les questions en choisissant, pour chacune, la reponse au
  /// [score] demande (0..3). Avance automatiquement question par question.
  Future<void> answerAll(WidgetTester tester, int score) async {
    // 8 questions dans le JSON commun (assets/data/feasibility_questions.json).
    for (var i = 0; i < 8; i++) {
      // La reponse d'index `score` porte ce score (JSON : A=0,B=1,C=2,D=3).
      final answerFinder = find.byType(InkWell);
      // Chaque question affiche 4 cartes reponse (AppCard -> InkWell). On
      // attend (borne) que les cartes soient rendues — pour la Q1, cela couvre
      // le chargement asynchrone des questions (JSON) + l'init postFrame.
      await pumpUntil(tester, answerFinder, minMatches: 4);
      // On tape celle d'index `score`.
      expect(
        tester.widgetList(answerFinder).length,
        greaterThanOrEqualTo(4),
        reason: 'Question ${i + 1} doit afficher au moins 4 reponses',
      );
      await tester.tap(answerFinder.at(score));
      await settle(tester);
    }
  }

  testWidgets('questionnaire complet -> verdict + ecran resultat', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const FeasibilityQuestionnaireScreen()));
    await settle(tester);

    // La premiere question s'affiche (titre AppBar = t.feasibility.title).
    expect(find.text(t.feasibility.title), findsWidgets);

    // Repondre a tout avec le meilleur score (3) -> niveau « excellent ».
    await answerAll(tester, 3);

    // Ecran resultat : la jauge affiche le score max « 24/24 ».
    expect(find.textContaining('/24'), findsOneWidget);

    // Verdict correct : le libelle du niveau « excellent » (Slang) est present.
    final excellentLabel = t['feasibility.levels.excellent'] as String;
    expect(find.text(excellentLabel), findsWidgets);

    // Carte recommandation : titre de reco « excellent » (parite GR20 conseils).
    final recTitle =
        t['feasibility.recommendations.excellent.title'] as String;
    expect(find.text(recTitle), findsOneWidget);

    // Bouton « Recommencer » (parite GR20 : REFAIRE LE QUESTIONNAIRE).
    expect(find.text(t.feasibility.restart), findsOneWidget);

    // Points forts presents (toutes reponses au score 3 -> 8 points forts).
    expect(find.text(t.feasibility.strongPointsTitle), findsOneWidget);
  });

  testWidgets('verdict « danger » quand toutes les reponses sont au minimum', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const FeasibilityQuestionnaireScreen()));
    await settle(tester);

    // Repondre a tout avec le pire score (0) -> niveau « danger ».
    await answerAll(tester, 0);

    // Jauge « 0/24 ».
    expect(find.textContaining('0/24'), findsOneWidget);

    // Verdict « danger » (Slang) + points faibles (8).
    final dangerLabel = t['feasibility.levels.danger'] as String;
    expect(find.text(dangerLabel), findsWidgets);
    expect(find.text(t.feasibility.weakPointsTitle), findsOneWidget);
  });

  testWidgets('« Recommencer » relance le questionnaire (retour a Q1)', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const FeasibilityQuestionnaireScreen()));
    await settle(tester);

    await answerAll(tester, 2);
    // On est sur le resultat : le bouton refaire existe.
    expect(find.text(t.feasibility.restart), findsOneWidget);

    // Le resultat est dans un SingleChildScrollView : le bouton « Recommencer »
    // est en bas et peut etre hors du viewport de test -> on le rend visible
    // avant de le taper (sinon le hit-test rate et onReset ne se declenche pas).
    await tester.ensureVisible(find.text(t.feasibility.restart));
    await settle(tester);

    // Taper « Recommencer » -> retour au questionnaire (barre de progression).
    await tester.tap(find.text(t.feasibility.restart));
    await settle(tester);
    // Le questionnaire redevient visible (les questions sont deja chargees ;
    // reset() ne fait que revenir a Q1) : on attend (borne) ses cartes.
    await pumpUntil(tester, find.byType(InkWell), minMatches: 4);

    // La vue resultat a disparu (plus de bouton refaire), le questionnaire
    // est de nouveau affiche (au moins 4 reponses visibles).
    expect(find.text(t.feasibility.restart), findsNothing);
    expect(
      tester.widgetList(find.byType(InkWell)).length,
      greaterThanOrEqualTo(4),
    );
  });

  testWidgets(
    'ecran resultat autonome (embedded=false) rend un Scaffold + verdict',
    (tester) async {
      const result = FeasibilityResult(
        score: 16,
        maxScore: 24,
        percentage: 16 / 24,
        level: FeasibilityCalculator.levelGood,
        weakPoints: ['gear'],
        strongPoints: ['fitness', 'motivation'],
      );
      await tester.pumpWidget(
        wrap(const FeasibilityResultScreen(result: result)),
      );
      await settle(tester);

      // Titre AppBar = resultTitle (mode autonome).
      expect(find.text(t.feasibility.resultTitle), findsWidgets);
      // Jauge 16/24 + niveau « good » resolu.
      expect(find.textContaining('16/24'), findsOneWidget);
      final goodLabel = t['feasibility.levels.good'] as String;
      expect(find.text(goodLabel), findsWidgets);
    },
  );

  testWidgets('navigation aller/retour vers la faisabilite sans crash', (
    tester,
  ) async {
    // Routeur minimal reproduisant l'entree HUB : push vers l'ecran
    // faisabilite puis retour (pile preservee, pas de context.go).
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.push('/feasibility'),
                child: const Text('go-feasibility'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/feasibility',
          builder: (_, __) => const FeasibilityQuestionnaireScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: TranslationProvider(
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await settle(tester);

    // Aller : ouvrir la faisabilite. On attend (borne) la fin de la transition
    // de route (le bouton back de l'AppBar apparait alors).
    await tester.tap(find.text('go-feasibility'));
    await settle(tester);
    await pumpUntil(tester, find.byTooltip('Back'));
    expect(find.text(t.feasibility.title), findsWidgets);

    // Retour : bouton back de l'AppBar -> on revient au HUB sans crash.
    await tester.tap(find.byTooltip('Back'));
    await settle(tester);
    await pumpUntil(tester, find.text('go-feasibility'));
    expect(find.text('go-feasibility'), findsOneWidget);
  });
}
