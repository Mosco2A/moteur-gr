import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/features/feasibility/data/feasibility_question_loader.dart';

/// Tests finitions V8 F2 — questions de faisabilite indexees par sentier.
///
/// Resolution : version sentier (TrailConfig.seedAssetsBase) puis
/// fallback fichier commun puis template hardcode.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TrailConfig config({String? seedAssetsBase}) => TrailConfig(
        id: 'sentier-bleu',
        name: 'SB',
        displayName: 'Sentier Bleu',
        tagline: 'Sentier fictif de test',
        totalStages: 3,
        totalDistanceKm: 42.0,
        totalElevationGain: 1200,
        region: 'Region Test',
        country: 'France',
        primaryColorValue: 0xFF0000FF,
        secondaryColorValue: 0xFF00FF00,
        gpxAssetPath: 'assets/gpx/sentier_bleu.gpx',
        seedAssetsBase: seedAssetsBase,
      );

  group('FeasibilityQuestionLoader par sentier (F2)', () {
    test('sans config : fichier commun charge (8 questions)', () async {
      final questions = await FeasibilityQuestionLoader.load();
      expect(questions.length, 8);
    });

    test('seedAssetsBase sans version sentier : fallback fichier commun',
        () async {
      final questions = await FeasibilityQuestionLoader.load(
        config: config(seedAssetsBase: 'assets/data/sentier_inexistant'),
      );
      expect(questions.length, 8);
    });

    test('version sentier presente : prioritaire sur le fichier commun',
        () async {
      const trailAsset =
          'assets/data/sentier_bleu/feasibility_questions.json';
      const trailJson = '''
      {
        "questions": [
          {
            "id": "q_test",
            "categoryKey": "fitness",
            "questionKey": "feasibility.questions.fitness",
            "answers": [{"answerKey": "a1", "score": 3}]
          }
        ]
      }
      ''';

      final messenger = TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger;
      messenger.setMockMessageHandler('flutter/assets', (message) async {
        final key = utf8.decode(message!.buffer
            .asUint8List(message.offsetInBytes, message.lengthInBytes));
        if (key == trailAsset) {
          final bytes = utf8.encode(trailJson);
          return ByteData.view(Uint8List.fromList(bytes).buffer);
        }
        return null; // autres assets absents
      });
      addTearDown(
        () => messenger.setMockMessageHandler('flutter/assets', null),
      );

      final questions = await FeasibilityQuestionLoader.load(
        config: config(seedAssetsBase: 'assets/data/sentier_bleu'),
      );
      expect(questions.length, 1);
      expect(questions.single.id, 'q_test');
    });
  });
}
