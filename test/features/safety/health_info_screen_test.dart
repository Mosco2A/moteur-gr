import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/safety/data/fiche_medicale_fichier.dart';
import 'package:moteur_gr/features/safety/data/health_info_repository.dart';
import 'package:moteur_gr/features/safety/domain/models/health_info.dart';
import 'package:moteur_gr/features/safety/presentation/health_info_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests E57 (LOT D/D1) de la fiche INFO SANTÉ : câblage du stockage, rendu i18n
/// et NON-RÉGRESSION overflow mobile (360/390/412).
///
/// Retour d'expérience Lot A/B (#95062) : un layout qui tient à 1200 px peut
/// déborder à 360/390/412 px. Ce fichier rend l'écran COMPLET à chaque largeur
/// mobile et échoue si le moindre RenderFlex signale un overflow.
///
/// TÂCHE 613 — LE STOCKAGE A CHANGÉ, ET CES TESTS AVEC LUI. La fiche ne vit plus
/// dans la table `health_info` de la base commune : elle a SON PROPRE FICHIER,
/// sous le dossier déclaré exclu de la sauvegarde du téléphone. La raison est
/// écrite dans `FicheMedicaleFichier` — la base est devenue durable et doit
/// remonter dans la sauvegarde pour que la progression et le carnet survivent au
/// changement d'appareil, or un fichier de base ne s'exclut pas table par table.
/// Ces tests surchargent donc `ficheMedicaleFichierProvider` (bac temporaire).
/// Données LOCAL ONLY : rien ne quitte l'appareil.
void main() {
  late AppDatabase db;
  late Directory bacFiche;
  late FicheMedicaleFichier fiche;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    bacFiche = Directory.systemTemp.createTempSync('fiche613_ecran');
    fiche = FicheMedicaleFichier(dossierApplicatif: () async => bacFiche);
    // TÂCHE 568 (LOT Q) : l'écran re-synchronise à l'ouverture un SIGNAL DE
    // PRÉPARATION persisté en préférences (fiche remplie / conseils lus, cf.
    // `health_prepare_providers.dart`) — il entre dans la porte de démarrage du
    // trek. Magasin de préférences simulé obligatoire.
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() async {
    await db.close();
    if (bacFiche.existsSync()) bacFiche.deleteSync(recursive: true);
  });

  Widget wrap({AppDatabase? database}) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database ?? db),
        // Tâche 613 : la fiche vit dans son propre fichier, pas dans la base.
        ficheMedicaleFichierProvider.overrideWithValue(fiche),
      ],
      // AppHeader (Ph5/L6d) utilise GoRouter (canPop/go). L'écran est atteint,
      // comme en prod, PAR UN PUSH depuis l'écran Urgence -> on l'héberge en
      // SOUS-ROUTE de /home (stack [/home, /home/health]) : `canPop()` est vrai et
      // la sauvegarde (qui fait `Navigator.pop()`) revient bien au parent, sans
      // dépiler la dernière page. L'écran santé reste rendu plein écran au-dessus.
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
              GoRoute(path: '/my-treks', builder: (_, __) => const SizedBox()),
            ],
          ),
        ),
      ),
    );
  }

  group('HealthInfoScreen — câblage du stockage de la fiche', () {
    testWidgets('le stockage de la fiche se câble sans erreur (rendu OK)', (
      tester,
    ) async {
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

    testWidgets('pré-remplit les champs depuis le fichier de la fiche', (
      tester,
    ) async {
      // Seed d'un profil santé existant dans le fichier de la fiche.
      await HealthInfoRepository(fichier: fiche).save(
        const HealthInfo(bloodType: 'AB+', allergies: 'Test-allergie-XYZ'),
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

    testWidgets('sauvegarde : écrit dans le fichier et ferme (snackbar)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      // TÂCHE 630 — CE TEST TAPAIT « O- » DANS LE PREMIER `TextFormField` DE
      // L'ÉCRAN. Il n'y a plus de champ de saisie pour le groupe sanguin : c'est
      // une LISTE FERMÉE de huit valeurs plus « je ne sais pas ». Et le premier
      // champ de l'écran n'est plus le groupe sanguin mais le NOM, parce que
      // c'est ce qu'un secouriste lit en premier. Le test vise donc désormais
      // les deux champs par leur clé — ce qui le rend aussi insensible à un
      // futur réordonnancement.
      await tester.enterText(
        find.byKey(const ValueKey('health-full-name-field')),
        'Christophe Mosconi',
      );
      final liste = find.byKey(const ValueKey('health-blood-type-field'));
      await tester.ensureVisible(liste);
      await tester.tap(liste);
      await tester.pumpAndSettle();
      // Le menu déroulant est ouvert : « O- » y figure (le `.last` évite
      // l'éventuel libellé du champ resté sous le menu).
      await tester.tap(find.text('O-').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.health.save));
      await tester.pump(); // déclenche la sauvegarde + snackbar

      // Écrit bien dans le fichier local (LOCAL ONLY).
      final saved = await HealthInfoRepository(fichier: fiche).get();
      expect(saved.bloodType, 'O-');
      expect(
        saved.fullName,
        'Christophe Mosconi',
        reason:
            'l identite est la premiere chose que lit un secouriste : '
            'elle doit s enregistrer comme le reste',
      );
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

    Future<List<String>> overflowsAt(WidgetTester tester, double width) async {
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
          reason: 'HealthInfoScreen deborde a ${width.toInt()} px : $overflows',
        );
      });
    }
  });
}
