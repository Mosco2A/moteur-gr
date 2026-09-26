import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/feasibility/data/hiker_profile_repository.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_formula.dart';
import 'package:moteur_gr/features/feasibility/domain/hiker_profile.dart';
import 'package:moteur_gr/features/feasibility/domain/past_hike.dart';
import 'package:moteur_gr/features/feasibility/domain/walk_test_norms.dart';
import 'package:moteur_gr/features/feasibility/presentation/hiker_profile_screen.dart';
import 'package:moteur_gr/features/feasibility/presentation/trek_feasibility_screen.dart';
import 'package:moteur_gr/features/feasibility/providers/hiker_profile_provider.dart';
import 'package:moteur_gr/features/feasibility/providers/trek_feasibility_provider.dart';
import 'package:moteur_gr/features/feasibility/providers/walk_test_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// TACHE 570, S1 — L'AGE DIT A QUOI IL SERT (il n'est PAS retire).
///
/// LA PREMISSE DE LA DEMANDE ETAIT FAUSSE, ET C'EST MESURE. Chris a dit « si
/// l'age ne sert a rien pas besoin de le demander ». L'age sert, et a DEUX
/// endroits :
///  1. [FeasibilityFormula] — correction d'age : le niveau retenu perd UN cran
///     a partir de 60 ans, DEUX a partir de 75 (VO2max -10 % par decennie
///     au-dela de 40 ans) ;
///  2. [WalkTestNorms.predictedFor] — prediction d'Enright : l'age entre avec
///     la taille et le poids pour fixer la distance de REFERENCE du test de
///     marche 6 min, donc la normalisation du resultat.
///
/// La campagne qui avait conclu l'inverse avait compare 38 ans a 68 ans sur un
/// profil DEJA AU PLANCHER, la ou `math.max(0, rank - 1)` ne peut rien retirer :
/// elle a mesure une borne, pas l'absence d'effet. Ces tests VERROUILLENT
/// l'effet reel, pour qu'on ne re-conclue plus jamais a l'inutilite de l'age.
///
/// LE VRAI DEFAUT ETAIT AILLEURS : l'ecran ne DISAIT pas a quoi sert l'age. Une
/// donnee de sante dont on n'explique pas l'usage est une donnee arrachee — la
/// minimisation RGPD demande de dire l'usage la ou l'on collecte. C'est ce que
/// les deux tests d'affichage exigent ici.
void main() {
  setUpAll(() => LocaleSettings.setLocaleRaw('fr'));

  // =========================================================================
  // L'AGE AGIT — non-regression de la premisse fausse
  // =========================================================================
  group('S1 — l age agit, et on ne le retirera pas', () {
    /// Reperes realises IDENTIQUES, age SEUL qui change, et un profil qui n'est
    /// PAS au plancher : c'est la mesure que la campagne n'avait pas su faire.
    /// 1200 m/j -> expert par le denivele, 24 km/j -> confirme par la distance,
    /// on retient le plus prudent (confirme, rang 2) : il reste donc DEUX crans
    /// a perdre, la ou un profil deja a 0 n'en avait aucun.
    test('60 ans retire UN cran de niveau, 75 ans en retire DEUX', () {
      HikerLevel levelAt(int age) => FeasibilityFormula.deriveLevel(
            maxElevationGainPerDayDone: 1200,
            maxDistancePerDayDone: 24,
            age: age,
            fitnessRank: 1,
          );

      final young = levelAt(45);
      final sixty = levelAt(60);
      final seventyFive = levelAt(75);

      expect(young.index, greaterThan(sixty.index),
          reason: 'a 60 ans le niveau retenu doit descendre d un cran');
      expect(sixty.index, greaterThan(seventyFive.index),
          reason: 'a 75 ans il doit descendre d un cran de plus');
      expect(young.index - seventyFive.index, 2,
          reason: 'l ecart 45 ans -> 75 ans est de DEUX crans');
    });

    test('l age change la distance de reference du test de marche', () {
      const base = HikerProfile(
        age: 45,
        heightCm: 175,
        weightKg: 72,
        sex: HikerSex.male,
      );
      final at45 = WalkTestNorms.predictedFor(base);
      final at70 = WalkTestNorms.predictedFor(base.copyWith(age: 70));

      expect(at45, isNotNull);
      expect(at70, isNotNull);
      expect(at45! - at70!, greaterThan(50),
          reason: 'la distance predite doit baisser nettement avec l age');
    });
  });

  // =========================================================================
  // L'ECRAN LE DIT — la ou l'age est COLLECTE
  // =========================================================================
  group('S1 — la fiche dit a quoi sert l age', () {
    late AppDatabase db;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async => db.close());

    Widget wrapProfile() {
      return ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          hikerProfileRepositoryProvider
              .overrideWithValue(HikerProfileRepository(db: db, prefs: prefs)),
        ],
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
                      builder: (_, __) => const HikerProfileScreen(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('le champ age porte l explication de son usage', (tester) async {
      await tester.pumpWidget(wrapProfile());
      await tester.pumpAndSettle();

      // Le champ est TOUJOURS LA (on ne retire pas l age).
      expect(find.text(t.hikerProfile.fieldAge), findsOneWidget);
      // Et l ecran dit maintenant ce que l age change.
      expect(
        find.text(t.hikerProfile.ageUsage, skipOffstage: false),
        findsOneWidget,
        reason: 'la fiche doit ecrire a quoi sert l age, comme pour le reste',
      );
    });
  });

  // =========================================================================
  // LE VERDICT LE DIT AUSSI — parite avec la ligne « le poids ne compte pas »
  // =========================================================================
  group('S1 — le verdict declare l age comme il declare la masse', () {
    setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

    StageModel stage(int n) => StageModel(
          trailId: 'test-trail',
          stageNumber: n,
          name: 'Etape $n',
          distanceKm: 10,
          elevationGainM: 400,
          elevationLossM: 300,
          startLat: 42.0,
          startLng: 9.0,
          endLat: 42.1,
          endLng: 9.1,
        );

    testWidgets('« ce qui est entre dans ce verdict » nomme l age',
        (tester) async {
      final assessment = FeasibilityFormula.evaluate(
        stages: [
          const StageEffort(
              index: 0, name: 'A -> B', distanceKm: 12, elevationGainM: 500),
          const StageEffort(
              index: 1, name: 'B -> C', distanceKm: 14, elevationGainM: 700),
        ],
        level: HikerLevel.intermediate,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            stagesProvider('test-trail').overrideWith(
                (ref) => Future.value([for (var n = 1; n <= 5; n++) stage(n)])),
            feasibilityAssessmentProvider.overrideWith((ref) async => assessment),
            hikerProfileProvider.overrideWith(
              () => _FixedProfile(const HikerProfile(
                  age: 45, heightCm: 178, weightKg: 76)),
            ),
            pastHikesProvider.overrideWith(() => _FixedHikes([
                  PastHike(
                    date: DateTime(2026, 6, 1),
                    days: 3,
                    avgWalkHoursPerDay: 6,
                    totalElevationGain: 2400,
                    totalDistanceKm: 54,
                  ),
                ])),
            walkTestResultProvider.overrideWith((ref) async => null),
          ],
          child: TranslationProvider(
            child: MaterialApp.router(
              locale: const Locale('fr'),
              routerConfig: GoRouter(
                initialLocation: '/',
                routes: [
                  GoRoute(
                      path: '/',
                      builder: (_, __) => const TrekFeasibilityScreen()),
                ],
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }

      // La ligne sur la masse existe deja : c'est elle qui sert de repere.
      expect(
        find.text(t.feasibility.formula.massNotCounted, skipOffstage: false),
        findsOneWidget,
        reason: 'repere du test : la ligne sur la masse doit etre affichee',
      );
      // Celle sur l age doit exister AU MEME ENDROIT.
      expect(
        find.text(t.feasibility.formula.ageCounted, skipOffstage: false),
        findsOneWidget,
        reason: 'le verdict declare ce que la masse ne fait pas mais taisait '
            'ce que l age fait',
      );
    });
  });
}

/// Notifier de test : profil fige (aucune lecture de stockage).
class _FixedProfile extends HikerProfileNotifier {
  _FixedProfile(this._profile);
  final HikerProfile _profile;
  @override
  Future<HikerProfile> build() async => _profile;
}

/// Notifier de test : randos passees figees.
class _FixedHikes extends PastHikesNotifier {
  _FixedHikes(this._hikes);
  final List<PastHike> _hikes;
  @override
  Future<List<PastHike>> build() async => _hikes;
}
