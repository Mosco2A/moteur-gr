import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/domain/feasibility_formula.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_program.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// TACHE 639 (AVENANT) — LE REPOS EST UN CONSEIL, ET SEPT JOURS FONT SEPT JOURS.
///
/// LA DECISION DE CHRISTOPHE, MOT POUR MOT (30/09 12:37, DEM-260930-1238) : « les
/// jours de repos, ca ne presage que de l enchainement pas de la capacite a faire
/// les etapes suivantes. On peut mettre en conseil de prendre n jours de repos c
/// est tout. Si c est 7 jours c est 7 jours, la couleur c est en fonction de la
/// faisabilite, si l utilisateur change le nombre ca change juste le curseur. La
/// faisabilite = conseils, ensuite il regle comme il veut. »
///
/// CE QUI SE PASSAIT, MESURE. La duree CONSEILLEE s'ecrivait en jours TOTAUX,
/// repos compris : `suggestedTotalDays = suggestedDays + suggestedRestDays`, et un
/// commentaire de la tache 569 disait meme « C'est cette valeur, et aucune autre,
/// que le bouton Generer mon programme applique et sur laquelle le curseur
/// s'ouvre ». Resultat sur le Mare a Mare Centre, SEPT etapes : la reponse
/// annoncait « a votre portee en 9 jours », le bouton proposait « 9 jours au
/// total » et le curseur du Programme s'ouvrait sur 9. Le randonneur, qui a sept
/// jours en tete parce que c'est ce que dit le topo, avait l'impression qu'on lui
/// refaisait son itineraire.
///
/// CE QUE CES TESTS VERROUILLENT :
///   1. la duree du PLAN est celle des jours de MARCHE, jamais gonflee ;
///   2. les jours de repos restent CONSEILLES, et se lisent comme un conseil ;
///   3. le repos ne DECIDE jamais du verdict — la couleur vient des etapes ;
///   4. changer le nombre de jours ne re-qualifie rien de punitif.
void main() {
  StageEffort etape(int numero, double km, int gain) => StageEffort(
    index: numero - 1,
    name: 'Etape $numero',
    distanceKm: km,
    elevationGainM: gain,
    elevationLossM: (gain * 0.8).round(),
  );

  /// SEPT etapes regulieres : exactement la forme du Mare a Mare Centre, et
  /// exactement le cas ou la monotonie de Foster grimpe — « plus les etapes sont
  /// regulieres plus elle grimpe ». C'est le pire cas pour le repos.
  final septEtapes = [for (var i = 1; i <= 7; i++) etape(i, 14.0, 700)];

  FeasibilityAssessment evaluer(
    List<StageEffort> etapes, {
    Set<int> repos = const <int>{},
  }) {
    final programme = FeasibilityProgram.fromRawStages(
      etapes,
      restAfterStageIndex: repos,
    );
    return FeasibilityFormula.evaluate(
      stages: programme.dayEfforts,
      level: HikerLevel.intermediate,
      restAfterStageIndex: programme.restAfterDayIndex,
      fromProgram: programme.fromProgram,
    );
  }

  group('la duree du PLAN est celle des jours de marche', () {
    test('sept etapes donnent sept jours, jamais neuf', () {
      final a = evaluer(septEtapes);
      expect(
        a.suggestedPlanDays,
        a.suggestedDays,
        reason: 'la duree du plan EST le nombre de jours de marche',
      );
      expect(
        a.suggestedPlanDays,
        lessThanOrEqualTo(7),
        reason:
            'sept etapes ne peuvent pas demander plus de sept jours de '
            'marche : une etape ne se coupe pas',
      );
    });

    test('le total reste calculable, mais il n est plus la duree du plan', () {
      final a = evaluer(septEtapes);
      expect(a.suggestedTotalDays, a.suggestedDays + a.suggestedRestDays);
      if (a.suggestedRestDays > 0) {
        expect(
          a.suggestedTotalDays,
          greaterThan(a.suggestedPlanDays),
          reason:
              'le total compte le repos, la duree du plan non — c est '
              'justement la distinction qui manquait',
        );
      }
    });

    test('le conseil de duree porte la meme distinction', () {
      const conseil = ProgramDurationAdvice(walkingDays: 7, restDays: 2);
      expect(conseil.planDays, 7, reason: 'sept jours font sept jours');
      expect(conseil.totalDays, 9);
      expect(conseil.restDays, 2, reason: 'le repos reste CONSEILLE');
    });

    test('la duree appliquee au curseur est celle du plan, pas le total', () {
      // GARDE-FOU SUR LA SOURCE : c'est la ligne exacte qui produisait « 9 jours »
      // pour un sentier de sept etapes, et elle vivait a DEUX endroits — l'ecran
      // de faisabilite (bouton « Generer mon programme ») et le provider sur
      // lequel le curseur du Programme s'ouvre. Les deux doivent lire la duree du
      // PLAN.
      final ecran = File(
        'lib/features/feasibility/presentation/trek_feasibility_screen.dart',
      ).readAsStringSync();
      expect(ecran, contains('assessment.suggestedPlanDays'));
      expect(
        ecran,
        isNot(contains('suggestedTotalDays: assessment')),
        reason: 'le bouton applique de nouveau le total',
      );
      final curseur = File(
        'lib/features/feasibility/providers/advised_program_provider.dart',
      ).readAsStringSync();
      expect(curseur, contains('found?.toAdvice().planDays'));
      expect(
        curseur,
        isNot(contains('return found?.totalDays;')),
        reason: 'le curseur s ouvre de nouveau sur le total',
      );
    });
  });

  group('le repos ne decide JAMAIS du verdict', () {
    test('ajouter des jours de repos ne change pas la couleur', () {
      // C est la moitie « la couleur c est en fonction de la faisabilite » de la
      // decision. Le repos change la monotonie (C3), et C3 est EN INFORMATION
      // depuis GO-61 : elle s affiche, elle ne decide pas.
      final sansRepos = evaluer(septEtapes);
      final avecRepos = evaluer(septEtapes, repos: const {2, 4});
      expect(
        avecRepos.globalVerdict,
        sansRepos.globalVerdict,
        reason: 'le repos a change le verdict : il est redevenu decisif',
      );
      expect(
        avecRepos.circuit?.score,
        sansRepos.circuit?.score,
        reason: 'le score de circuit vaut la PIRE journee (C1) et rien d autre',
      );
    });

    test('la dimension DOMINANTE du circuit n est jamais le repos', () {
      // Si C3 redevenait decisive, elle apparaitrait ici — et 24 cellules sur 24
      // repasseraient au rouge pour un itineraire simplement REGULIER, ce que la
      // campagne 569 avait mesure avant GO-61.
      for (final repos in [
        const <int>{},
        const {3},
        const {2, 4},
      ]) {
        final a = evaluer(septEtapes, repos: repos);
        expect(
          a.circuit?.dominant,
          isNot(CircuitConstraint.rest),
          reason: 'le repos decide le verdict avec $repos jour(s) de repos',
        );
        expect(
          a.circuit?.dominant,
          CircuitConstraint.worstStage,
          reason: 'le verdict vaut la PIRE journee (C1), et elle seule',
        );
      }
    });
  });

  group('les libelles disent « conseil », dans les 5 langues', () {
    test('la note de duree annonce la marche, et le repos en CONSEIL', () {
      const conseil = <AppLocale, List<String>>{
        AppLocale.fr: ['conseill'],
        AppLocale.en: ['advise', 'advice'],
        AppLocale.de: ['empfehl', 'rat'],
        AppLocale.es: ['aconseja', 'consejo'],
        AppLocale.it: ['consigl'],
      };
      for (final entree in conseil.entries) {
        final f = entree.key.buildSync().feasibility.formula;
        final note = f.answerDaysNote(walking: 7, rest: 2).toLowerCase();
        expect(
          entree.value.any(note.contains),
          isTrue,
          reason:
              '${entree.key.languageCode} : « $note » ne presente pas le '
              'repos comme un conseil',
        );
        expect(
          note,
          contains('7'),
          reason: '${entree.key.languageCode} : les jours de marche manquent',
        );
        expect(
          note,
          isNot(contains('9')),
          reason:
              '${entree.key.languageCode} : le total est revenu — « Si c est '
              '7 jours c est 7 jours »',
        );
      }
    });

    test('le bouton du programme annonce des jours de MARCHE', () {
      const marche = <AppLocale, List<String>>{
        AppLocale.fr: ['marche'],
        AppLocale.en: ['walking'],
        AppLocale.de: ['wandertage'],
        AppLocale.es: ['marcha'],
        AppLocale.it: ['cammino'],
      };
      for (final entree in marche.entries) {
        final f = entree.key.buildSync().feasibility.formula;
        for (final libelle in [
          f.generateProgram(days: 7).toLowerCase(),
          f.generateProgramDone(days: 7).toLowerCase(),
        ]) {
          expect(
            entree.value.any(libelle.contains),
            isTrue,
            reason:
                '${entree.key.languageCode} : « $libelle » ne dit pas de '
                'quels jours il parle',
          );
        }
      }
    });

    test('plus aucun « au total » dans la duree annoncee', () {
      const total = <AppLocale, List<String>>{
        AppLocale.fr: ['au total'],
        AppLocale.en: ['in total'],
        AppLocale.de: ['insgesamt'],
        AppLocale.es: ['en total'],
        AppLocale.it: ['in totale'],
      };
      for (final entree in total.entries) {
        final f = entree.key.buildSync().feasibility.formula;
        for (final libelle in [
          f.generateProgram(days: 7),
          f.generateProgramDone(days: 7),
          f.answerDaysNote(walking: 7, rest: 2),
          f.advice.optimalDays(walk: 7, rest: 2, current: 7),
          f.advice.optimalDaysNoChoice(walk: 7, rest: 2),
        ]) {
          for (final mot in entree.value) {
            expect(
              libelle.toLowerCase(),
              isNot(contains(mot)),
              reason:
                  '${entree.key.languageCode} : « $libelle » compte encore '
                  'le repos dans la duree',
            );
          }
        }
      }
    });
  });
}
