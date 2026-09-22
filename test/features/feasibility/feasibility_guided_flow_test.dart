import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_formula.dart';
import 'package:moteur_gr/features/feasibility/domain/hiker_profile.dart';
import 'package:moteur_gr/features/feasibility/domain/past_hike.dart';
import 'package:moteur_gr/features/feasibility/domain/walk_test_result.dart';
import 'package:moteur_gr/features/feasibility/presentation/trek_feasibility_screen.dart';
import 'package:moteur_gr/features/feasibility/providers/hiker_profile_provider.dart';
import 'package:moteur_gr/features/feasibility/providers/trek_feasibility_provider.dart';
import 'package:moteur_gr/features/feasibility/providers/walk_test_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// FLUX GUIDE DE FAISABILITE (LOT 4, retours R2a/R2c/R2d).
///
/// Verifie, cote 1er utilisateur (profil objectif VIDE) :
///   - R2a : au 1er acces, on montre un QUESTIONNAIRE GUIDE (etapes + barre de
///     progression), PAS un verdict pose sur du vide ;
///   - R2c : un bouton « Valider / Voir mon resultat » est present ;
///   - R2d : appuyer sur Valider mene TOUJOURS a un resultat (feu tricolore).
/// Le verdict lui-meme (#100068) est teste ailleurs (trek_feasibility_screen_test).
void main() {
  setUpAll(() => LocaleSettings.setLocaleRaw('fr'));

  StageEffort stage(int i, String name, double dist, int elev) => StageEffort(
        index: i,
        name: name,
        distanceKm: dist,
        elevationGainM: elev,
      );

  FeasibilityAssessment sampleAssessment() => FeasibilityFormula.evaluate(
        stages: [
          stage(0, 'Depart -> Col', 24, 1600),
          stage(1, 'Col -> Village', 10, 200),
        ],
        level: HikerLevel.intermediate,
      );

  /// Monte l'ecran avec un profil objectif VIDE (1er acces) mais des etapes
  /// disponibles (assessment non-null) -> le flux guide doit s'afficher.
  Future<void> pumpEmptyProfile(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const TrekFeasibilityScreen()),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feasibilityAssessmentProvider
              .overrideWith((ref) async => sampleAssessment()),
          // Profil objectif ABSENT -> flux guide (R2a).
          hasObjectiveProfileProvider.overrideWith((ref) async => false),
          // Etats de completion des etapes : tous vides (barre a 0/3).
          hikerProfileProvider.overrideWith(_EmptyProfile.new),
          walkTestResultProvider.overrideWith((ref) async => null),
          pastHikesProvider.overrideWith(_EmptyHikes.new),
        ],
        child: MaterialApp.router(
          locale: const Locale('fr'),
          routerConfig: router,
        ),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  testWidgets('1er acces (profil vide) -> flux guide + barre + Valider (R2a/c)',
      (tester) async {
    await pumpEmptyProfile(tester);

    // Titre du flux guide (pas le verdict).
    expect(find.text(t.feasibility.flow.title), findsOneWidget);
    // Barre de progression presente.
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    // Les 3 etapes du flux.
    expect(find.text(t.feasibility.flow.stepProfile), findsOneWidget);
    expect(find.text(t.feasibility.flow.stepWalkTest), findsOneWidget);
    expect(find.text(t.feasibility.flow.stepPastHikes), findsOneWidget);
    // Bouton « Valider / Voir mon resultat » (R2c).
    expect(find.text(t.feasibility.flow.validate), findsOneWidget);
    // Le verdict n'est PAS encore affiche (pas de badge tricolore).
    expect(find.text(t.feasibility.formula.stagesTitle), findsNothing);
  });

  // R2d EST REMPLACE par la regle de Chris du 22/09 (mandat #100293, D1).
  //
  // R2d disait « Valider mene TOUJOURS a un resultat », profil vide compris.
  // Chris a constate a l'ecran ou cela menait : saisir age / taille / poids
  // suffisait a obtenir un feu tricolore, alors que le niveau se deduit des
  // randos deja faites — un verdict rendu sur du vide. La regle en vigueur est
  // celle de GR20 : aucun verdict tant que les criteres necessaires ne sont
  // pas tous fournis. Ce test verifie donc l'INVERSE de l'ancien, exprès.
  testWidgets('profil VIDE -> Valider est inerte, aucun verdict (D1)',
      (tester) async {
    await pumpEmptyProfile(tester);

    // Le bouton existe mais ne mene nulle part tant que rien n'est rempli.
    final bouton =
        find.widgetWithText(ElevatedButton, t.feasibility.flow.validate);
    expect(bouton, findsOneWidget);
    expect(tester.widget<ElevatedButton>(bouton).onPressed, isNull);

    await tester.ensureVisible(bouton);
    await tester.tap(bouton, warnIfMissed: false);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    // AUCUN verdict : pas de tableau etape par etape, pas de feu.
    expect(find.text(t.feasibility.formula.stagesTitle), findsNothing);
    expect(find.text(t.feasibility.formula.verdicts.red), findsNothing);
    // A la place, l'ecran NOMME ce qui manque.
    expect(find.text(t.feasibility.flow.missingTitle), findsOneWidget);
    expect(find.text(t.feasibility.flow.missingProfile), findsOneWidget);
    expect(find.text(t.feasibility.flow.missingPastHikes), findsOneWidget);
  });
}

/// Notifier de test : profil vide (1er acces).
class _EmptyProfile extends HikerProfileNotifier {
  @override
  Future<HikerProfile> build() async => HikerProfile.empty;
}

/// Notifier de test : aucune rando passee.
class _EmptyHikes extends PastHikesNotifier {
  @override
  Future<List<PastHike>> build() async => const <PastHike>[];
}
