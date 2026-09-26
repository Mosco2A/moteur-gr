import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/features/training/models/training_plan.dart';
import 'package:moteur_gr/features/training/presentation/training_screen.dart';
import 'package:moteur_gr/features/training/providers/training_plan_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// TACHE 570, S3 — LE PLAN D'ENTRAINEMENT DEVIENT UN PLAN.
///
/// TROIS DEFAUTS, TROIS DECISIONS DE CHRIS (26/09), verbatim : « semaine 1 et 2
/// c'est une sortie de chaque ou plusieurs, une seule sortie cardio c'est
/// vraiment peu idem pour la sortie marche, ton et ca s'appelle marche
/// reguliere. En plus tu fais un plan sans savoir quand il part, 8 semaines
/// c'est le minimum en dessous duquel tu ne propose pas de prepa physique ».
///
/// (a) LA FREQUENCE MANQUAIT. Le plan listait des TYPES de seances et l'ecran
///     les presentait comme des seances UNIQUES cochables : deux semaines de
///     Fondation semblaient ne demander qu'UNE sortie cardio. Chaque seance
///     porte desormais son rythme, et TOUS les chiffres sont sources (REI
///     Expert Advice, Terres d'Aventure, OMS 2020, Randonner Malin) — regle
///     #6178 : un plan de preparation a la montagne se source, il ne s'invente
///     pas.
/// (b) LE PLAN S'AFFICHAIT SANS DATE DE DEPART. Un plan progressif sans date de
///     fin ne sait pas dans quelle semaine on est, ni quand affuter : il ne
///     s'affiche plus du tout, il invite a poser la date et DIT pourquoi.
/// (c) SOUS 8 SEMAINES, AUCUNE PREPA. L'ecran condensait le plan sur le temps
///     restant (seuil de 21 jours) : un programme tasse fabrique de la
///     blessure, pas de la forme. On refuse, et on dit pourquoi.
void main() {
  setUpAll(() => LocaleSettings.setLocaleRaw('fr'));

  const trailId = 'test-trail';

  /// Plan de test calque sur la DONNEE reelle : des seances rythmees.
  const plan = TrainingPlan(
    trailId: trailId,
    durationWeeks: 8,
    phases: [
      TrainingPhase(
        id: 'foundation',
        weekStart: 1,
        weekEnd: 2,
        titleFr: 'Fondation',
        sessions: [
          TrainingSession(
            id: 'foundation-s1',
            labelFr: 'Cardio 1 h',
            timesPerWeek: 2,
          ),
          TrainingSession(
            id: 'foundation-s3',
            labelFr: 'Marche reguliere 1 h 30',
            timesPerWeek: 1,
          ),
        ],
      ),
      TrainingPhase(
        id: 'endurance',
        weekStart: 6,
        weekEnd: 8,
        titleFr: 'Endurance',
        sessions: [
          TrainingSession(
            id: 'endurance-s2',
            labelFr: 'Deux jours enchaines',
            occurrence: SessionOccurrence.oncePerPhase,
          ),
          TrainingSession(
            id: 'endurance-s3',
            labelFr: 'Affutage',
            occurrence: SessionOccurrence.finalWeek,
          ),
        ],
      ),
    ],
    objective: TrainingObjective(labelFr: 'Tenir 6 h de marche'),
  );

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  /// Monte l'ecran avec une date de depart CHOISIE (ou aucune).
  ///
  /// La date passe par [trainingDepartureDateProvider], seule source de date de
  /// l'ecran : on pilote donc exactement ce que le randonneur aurait pose dans
  /// le Calendrier, sans toucher au stockage.
  Widget wrap({int? daysUntilDeparture}) {
    return ProviderScope(
      overrides: [
        trailConfigProvider.overrideWithValue(testTrailConfig),
        isDemoModeProvider(testTrailConfig.id).overrideWith((ref) async => false),
        trainingPlanProvider.overrideWith((ref) async => plan),
        trainingDepartureDateProvider.overrideWithValue(
          daysUntilDeparture == null
              ? null
              : DateTime.now().add(Duration(days: daysUntilDeparture)),
        ),
      ],
      child: TranslationProvider(
        child: MaterialApp.router(
          locale: const Locale('fr'),
          routerConfig: GoRouter(
            initialLocation: '/training',
            routes: [
              GoRoute(
                  path: '/training', builder: (_, __) => const TrainingScreen()),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // (a) CHAQUE SEANCE PORTE SA FREQUENCE
  // =========================================================================
  group('S3-a — chaque seance porte sa frequence', () {
    test('la DONNEE livree rythme toutes ses seances', () {
      final raw = File('assets/data/training_plans.json').readAsStringSync();
      final json = jsonDecode(raw) as Map<String, dynamic>;

      final plans = <Map<String, dynamic>>[
        json['default'] as Map<String, dynamic>,
        ...(json['trails'] as Map<String, dynamic>)
            .values
            .cast<Map<String, dynamic>>(),
      ];

      var checked = 0;
      for (final p in plans) {
        for (final phase in (p['phases'] as List).cast<Map<String, dynamic>>()) {
          for (final s
              in (phase['sessions'] as List).cast<Map<String, dynamic>>()) {
            final occurrence = s['occurrence'] as String?;
            expect(occurrence, isNotNull,
                reason: 'seance ${s['id']} sans rythme declare');
            if (occurrence == 'weekly') {
              expect(s['timesPerWeek'] as int? ?? 0, greaterThan(0),
                  reason: 'seance hebdomadaire ${s['id']} sans frequence : '
                      'c est un TYPE de seance, pas une seance');
            }
            checked++;
          }
        }
      }
      expect(checked, greaterThanOrEqualTo(9),
          reason: 'le plan par defaut compte au moins 9 seances');
    });

    testWidgets('l ecran affiche le rythme de chaque seance', (tester) async {
      // Depart assez loin pour que le plan s affiche (plancher respecte).
      await tester.pumpWidget(wrap(daysUntilDeparture: 90));
      await tester.pumpAndSettle();

      // Phase 1 ouverte par defaut : ses deux rythmes doivent etre lisibles.
      expect(find.text(t.training.freqPerWeek(n: 2)), findsWidgets,
          reason: 'la seance cardio est a 2 fois par semaine, il faut le dire');
      expect(find.text(t.training.freqPerWeek(n: 1)), findsWidgets,
          reason: 'la marche reguliere est a 1 fois par semaine');

      // Et l origine des chiffres est declaree : aucune frequence maison.
      expect(
        find.text(t.training.freqSourceNotice, skipOffstage: false),
        findsOneWidget,
        reason: 'les frequences sont sourcees, l ecran doit le dire',
      );
    });

    testWidgets('les rythmes non hebdomadaires sont dits en clair',
        (tester) async {
      await tester.pumpWidget(wrap(daysUntilDeparture: 90));
      await tester.pumpAndSettle();

      // Deplie la phase Endurance pour atteindre ses deux seances singulieres.
      await tester.tap(find.text(
          t.training.phaseWeeks(start: 6, end: 8, title: 'Endurance')));
      await tester.pumpAndSettle();

      expect(find.text(t.training.freqOncePerPhase), findsOneWidget,
          reason: 'le test du materiel est un rendez-vous, pas un rythme');
      expect(find.text(t.training.freqFinalWeek), findsOneWidget,
          reason: 'l affutage est la derniere semaine, et seulement elle');
    });
  });

  // =========================================================================
  // (b) PAS DE DATE DE DEPART -> PAS DE PLAN
  // =========================================================================
  group('S3-b — sans date de depart, pas de plan', () {
    testWidgets('aucune seance affichee, une invite et sa raison',
        (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(
        find.byType(CheckboxListTile),
        findsNothing,
        reason: 'un plan progressif sans date ne sait pas ou il commence',
      );
      expect(find.text(t.training.objectiveTitle), findsNothing,
          reason: 'pas de plan affiche, donc pas d objectif de plan');
      expect(find.text(t.training.inviteSetDate), findsOneWidget);
      expect(
        find.text(t.training.noDateWhy, skipOffstage: false),
        findsOneWidget,
        reason: 'on ne refuse pas sans dire pourquoi',
      );
    });
  });

  // =========================================================================
  // (c) MOINS DE 8 SEMAINES -> AUCUNE PREPA, ET ON DIT POURQUOI
  // =========================================================================
  group('S3-c — sous le plancher de 8 semaines, aucune prepa', () {
    testWidgets('a 30 jours du depart : rien de propose, raison donnee',
        (tester) async {
      await tester.pumpWidget(wrap(daysUntilDeparture: 30));
      await tester.pumpAndSettle();

      expect(
        find.byType(CheckboxListTile),
        findsNothing,
        reason: '30 jours c est moins de 8 semaines : aucune prepa proposee',
      );
      expect(find.text(t.training.tooShortTitle), findsOneWidget);
      expect(
        find.text(
            t.training.tooShortWhy(days: 30, weeks: kTrainingMinWeeks),
            skipOffstage: false),
        findsOneWidget,
        reason: 'le refus doit etre motive, plancher et source nommes',
      );
    });

    testWidgets('a 8 semaines pile, le plan s affiche', (tester) async {
      await tester.pumpWidget(
          wrap(daysUntilDeparture: kTrainingMinWeeks * 7));
      await tester.pumpAndSettle();

      expect(find.byType(CheckboxListTile), findsWidgets,
          reason: '8 semaines est le MINIMUM, donc 8 semaines suffisent');
      expect(find.text(t.training.tooShortTitle), findsNothing);
    });

    test('le plancher est bien de 8 semaines', () {
      // Source : Terres d'Aventure, « commencez a vous entrainer au moins 2
      // mois avant de partir ». Deux mois = 8 semaines.
      expect(kTrainingMinWeeks, 8);
    });
  });
}
