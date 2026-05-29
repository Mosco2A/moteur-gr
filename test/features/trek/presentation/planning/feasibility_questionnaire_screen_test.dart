import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/domain/models/feasibility_profile.dart';
import 'package:moteur_gr/features/trek/presentation/planning/feasibility_questionnaire_screen.dart';

/// JSON de test minimal avec 3 questions (fitness, experience, km slider).
const _testQuestionsJson = '''
{
  "version": 1,
  "questions": [
    {
      "id": "fitness_level",
      "field": "fitnessLevel",
      "labelFr": "Quel est votre niveau de forme physique ?",
      "labelEn": "What is your fitness level?",
      "type": "single_choice",
      "options": [
        {
          "value": "sedentary",
          "labelFr": "Sedentaire",
          "labelEn": "Sedentary",
          "icon": "airline_seat_recline_normal",
          "maxKmPerDay": 10.0,
          "maxHoursPerDay": 4.0
        },
        {
          "value": "fit",
          "labelFr": "En forme",
          "labelEn": "Fit",
          "icon": "hiking",
          "maxKmPerDay": 22.0,
          "maxHoursPerDay": 8.0
        }
      ]
    },
    {
      "id": "experience",
      "field": "experience",
      "labelFr": "Quelle est votre experience en randonnee ?",
      "labelEn": "What is your hiking experience?",
      "type": "single_choice",
      "options": [
        {
          "value": "beginner",
          "labelFr": "Debutant",
          "labelEn": "Beginner",
          "icon": "school"
        },
        {
          "value": "experienced",
          "labelFr": "Experimente",
          "labelEn": "Experienced",
          "icon": "landscape"
        }
      ]
    },
    {
      "id": "max_km",
      "field": "maxKmPerDay",
      "labelFr": "Distance maximale par jour (km) ?",
      "labelEn": "Maximum distance per day (km)?",
      "type": "slider",
      "min": 5.0,
      "max": 35.0,
      "divisions": 30,
      "defaultValue": 20.0,
      "unit": "km"
    }
  ]
}
''';

/// Override du provider de questions pour injecter le JSON de test
/// sans dependre du rootBundle.
List<FeasibilityQuestion> _parseTestQuestions() {
  final data =
      json.decode(_testQuestionsJson) as Map<String, dynamic>;
  return (data['questions'] as List<dynamic>)
      .map((q) =>
          FeasibilityQuestion.fromJson(q as Map<String, dynamic>))
      .toList();
}

void main() {
  group('FeasibilityQuestionnaireScreen', () {
    testWidgets(
        'affiche la premiere question et navigue avec Suivant',
        (tester) async {
      final testQuestions = _parseTestQuestions();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feasibilityQuestionsProvider.overrideWith(
              (ref) async => testQuestions,
            ),
          ],
          child: const MaterialApp(
            home: FeasibilityQuestionnaireScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verifie que le titre de la premiere question est affiche
      expect(
        find.text('Quel est votre niveau de forme physique ?'),
        findsOneWidget,
      );

      // Verifie la presence des options
      expect(find.text('Sedentaire'), findsOneWidget);
      expect(find.text('En forme'), findsOneWidget);

      // Verifie le compteur de progression
      expect(find.text('1 / 3'), findsOneWidget);

      // Le bouton Suivant est desactive tant qu'on n'a pas choisi
      final suivantButton = find.widgetWithText(ElevatedButton, 'Suivant');
      expect(suivantButton, findsOneWidget);
      final button =
          tester.widget<ElevatedButton>(suivantButton);
      expect(button.onPressed, isNull);

      // Selectionner une option
      await tester.tap(find.text('En forme'));
      await tester.pumpAndSettle();

      // Le bouton Suivant est maintenant actif
      final activeButton =
          tester.widget<ElevatedButton>(suivantButton);
      expect(activeButton.onPressed, isNotNull);

      // Naviguer a la question suivante
      await tester.tap(suivantButton);
      await tester.pumpAndSettle();

      // Verifie que la deuxieme question est affichee
      expect(
        find.text('Quelle est votre experience en randonnee ?'),
        findsOneWidget,
      );

      // Verifie que le compteur a avance
      expect(find.text('2 / 3'), findsOneWidget);

      // Le bouton Precedent est visible
      expect(
        find.widgetWithText(OutlinedButton, 'Precedent'),
        findsOneWidget,
      );
    });

    testWidgets(
        'construit un FeasibilityProfile correct a la soumission',
        (tester) async {
      final testQuestions = _parseTestQuestions();
      FeasibilityProfile? capturedProfile;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feasibilityQuestionsProvider.overrideWith(
              (ref) async => testQuestions,
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  final result =
                      await Navigator.of(context).push<FeasibilityProfile>(
                    MaterialPageRoute(
                      builder: (_) =>
                          const FeasibilityQuestionnaireScreen(),
                    ),
                  );
                  capturedProfile = result;
                },
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      );

      // Ouvrir le questionnaire
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      // Q1 : choisir "En forme"
      await tester.tap(find.text('En forme'));
      await tester.pumpAndSettle();
      await tester.tap(
          find.widgetWithText(ElevatedButton, 'Suivant'));
      await tester.pumpAndSettle();

      // Q2 : choisir "Experimente"
      await tester.tap(find.text('Experimente'));
      await tester.pumpAndSettle();
      await tester.tap(
          find.widgetWithText(ElevatedButton, 'Suivant'));
      await tester.pumpAndSettle();

      // Q3 : slider — valeur par defaut 20 km, on valide directement
      // Le bouton final affiche "Valider" au lieu de "Suivant"
      expect(
        find.widgetWithText(ElevatedButton, 'Valider'),
        findsOneWidget,
      );

      await tester.tap(
          find.widgetWithText(ElevatedButton, 'Valider'));
      await tester.pumpAndSettle();

      // Verifie que le profil a ete retourne via Navigator.pop
      expect(capturedProfile, isNotNull);
      expect(capturedProfile!.fitnessLevel, 'fit');
      expect(capturedProfile!.experience, 'experienced');
      // Le maxKmPerDay vient de la suggestion de "fit" (22.0)
      // car il a ete pre-rempli par le choix fitness_level
      expect(capturedProfile!.maxKmPerDay, 22.0);
      expect(capturedProfile!.groupMode, false);
    });
  });
}
