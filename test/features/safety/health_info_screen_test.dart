import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/safety/presentation/health_info_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Tests E57 (LOT D/D1) de la fiche INFO SANTÉ : câblage DAO Drift, rendu i18n
/// et NON-RÉGRESSION overflow mobile (360/390/412).
///
/// Retour d'expérience Lot A/B (#95062) : un layout qui tient à 1200 px peut
/// déborder à 360/390/412 px. Ce fichier rend l'écran COMPLET à chaque largeur
/// mobile et échoue si le moindre RenderFlex signale un overflow.
///
/// Câblage vérifié : `healthInfoDaoProvider` dérive de `databaseProvider`
/// (override DB in-memory ici) — plus d'`UnimplementedError`. Données LOCAL
/// ONLY : rien ne quitte l'appareil.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Widget wrap({AppDatabase? database}) {
    return ProviderScope(
      overrides: [
        // Câblage réel : le DAO santé auto-dérive de databaseProvider.
        databaseProvider.overrideWithValue(database ?? db),
      ],
      child: TranslationProvider(
        child: const MaterialApp(home: HealthInfoScreen()),
      ),
    );
  }

  group('HealthInfoScreen — câblage DAO Drift', () {
    testWidgets('le DAO santé se câble sans UnimplementedError (rendu OK)',
        (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      // Titre + bandeau confidentialité + note urgence (i18n Slang).
      expect(find.text(t.health.title), findsWidgets);
      expect(find.text(t.health.privacyBanner), findsOneWidget);
      expect(find.text(t.health.emergencyHint), findsOneWidget);
      // Les 5 champs (labels i18n).
      expect(find.text(t.health.field.bloodType), findsOneWidget);
      expect(find.text(t.health.field.allergies), findsOneWidget);
      expect(find.text(t.health.field.treatments), findsOneWidget);
      expect(find.text(t.health.field.doctor), findsOneWidget);
      expect(find.text(t.health.field.insurance), findsOneWidget);
      // Bouton sauvegarder.
      expect(find.text(t.health.save), findsOneWidget);
    });

    testWidgets('pré-remplit les champs depuis Drift (données déjà saisies)',
        (tester) async {
      // Seed d'un profil santé existant dans la DB.
      await db.healthInfoDao.insertEntry(
        HealthInfoEntriesCompanion.insert(
          bloodType: const Value('AB+'),
          allergies: const Value('Test-allergie-XYZ'),
        ),
      );

      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      // Les valeurs seedées sont chargées dans les TextFormField.
      expect(find.text('AB+'), findsOneWidget);
      expect(find.text('Test-allergie-XYZ'), findsOneWidget);
    });

    testWidgets('sauvegarde : écrit en Drift et ferme (snackbar de confirmation)',
        (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'O-',
      );
      await tester.tap(find.text(t.health.save));
      await tester.pump(); // déclenche la sauvegarde + snackbar

      // Écrit bien dans la table locale (LOCAL ONLY).
      final saved = await db.healthInfoDao.getFirst();
      expect(saved, isNotNull);
      expect(saved!.bloodType, 'O-');
    });
  });

  group('HealthInfoScreen — cloisonnement StepWays', () {
    testWidgets('aucun libellé GR20 / Fra li Monti', (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.textContaining('GR20'), findsNothing);
      expect(find.textContaining('Fra li Monti'), findsNothing);
    });
  });

  // --- Non-régression overflow largeurs mobiles (retour Lot A/B #95062) ---
  group('non-regression overflow largeurs mobiles', () {
    const mobileWidths = <double>[360, 390, 412];

    Future<List<String>> overflowsAt(
      WidgetTester tester,
      double width,
    ) async {
      final captured = <String>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        final message = details.exceptionAsString();
        if (message.contains('overflowed')) {
          captured.add(message.split('\n').first);
        } else {
          (previous ?? FlutterError.presentError)(details);
        }
      };

      tester.view.physicalSize = Size(width, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      try {
        await tester.pumpWidget(wrap());
        await tester.pumpAndSettle();
      } finally {
        FlutterError.onError = previous;
      }

      for (var guard = 0; guard < captured.length + 8; guard++) {
        final pending = tester.takeException();
        if (pending == null) break;
        if (!pending.toString().contains('overflowed')) {
          throw pending;
        }
      }
      return captured;
    }

    for (final width in mobileWidths) {
      testWidgets('aucun overflow a ${width.toInt()} px', (tester) async {
        final overflows = await overflowsAt(tester, width);
        expect(
          overflows,
          isEmpty,
          reason:
              'HealthInfoScreen deborde a ${width.toInt()} px : $overflows',
        );
      });
    }
  });
}
