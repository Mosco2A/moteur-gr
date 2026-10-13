// LE DIALOGUE « IL MANQUE DES OBLIGATOIRES » PLANTAIT, SOUS LE VRAI THEME.
//
// CE QUE LA TACHE 645-03 A TROUVE EN PASSANT. Le bas du sac posait ses actions
// de dialogue dans une `Row`, dont le dernier enfant etait un `ElevatedButton`
// brut. Or le theme de l'application donne a tout `ElevatedButton`
// `minimumSize: Size(double.infinity, 52)` — et une `Row` mesure ses enfants
// non flexibles en largeur NON BORNEE. Largeur minimale infinie dans une
// contrainte infinie : « BoxConstraints forces an infinite width », ecran
// rouge, au moment precis ou le randonneur tape « VALIDER MON SAC » sans avoir
// coche tous les obligatoires.
//
// POURQUOI AUCUN TEST NE L'AVAIT VU. Les tests de widget de cet ecran montent
// un `MaterialApp` SANS THEME : leur `ElevatedButton` n'a donc pas le
// `minimumSize` du theme, et la largeur infinie n'apparait jamais. Le defaut
// vivait dans l'ecart entre le bouton teste et le bouton livre. Ce test monte
// le theme REEL — c'est la seule facon de le voir.
//
// CE QUI L'A CORRIGE. Le passage par `AppButton` (meme commit) : le composant
// unique prend `isFullWidth: false` pour une action de `Row`, donc une largeur
// naturelle, donc une contrainte finie. Le dialogue s'ouvre.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/core/theme/app_skin.dart';
import 'package:moteur_gr/core/theme/app_theme.dart';
import 'package:moteur_gr/features/checklist/presentation/checklist_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

void main() {
  /// Le meme montage que les autres tests du sac, A UNE DIFFERENCE PRES, et
  /// c'est tout l'objet de ce fichier : le theme de l'application est pose.
  Widget wrap(AppDatabase db) => ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      trailConfigProvider.overrideWithValue(testTrailConfig),
      isDemoModeProvider.overrideWith((ref, trailId) async => false),
    ],
    child: TranslationProvider(
      child: MaterialApp.router(
        theme: AppTheme.buildDarkTheme(
          primaryColor: Color(testTrailConfig.primaryColorValue),
          secondaryColor: Color(testTrailConfig.secondaryColorValue),
          skin: AppSkin.sentierVivant,
        ),
        routerConfig: GoRouter(
          initialLocation: '/checklist',
          routes: [
            GoRoute(
              path: '/checklist',
              builder: (_, __) => const ChecklistScreen(),
            ),
            GoRoute(path: '/my-treks', builder: (_, __) => const SizedBox()),
          ],
        ),
      ),
    ),
  );

  testWidgets('« VALIDER MON SAC » sans les obligatoires ouvre son dialogue '
      'au lieu de jeter une largeur infinie', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() async => db.close());

    await tester.pumpWidget(wrap(db));
    await tester.pumpAndSettle();

    // Sac neuf : rien n'est coche, donc il manque des obligatoires. Le bouton
    // est en bas d'une longue liste : on l'amene a l'ecran, sinon le tap
    // tomberait a cote (et le dialogue ne s'ouvrirait jamais).
    final valider = find.text(t.checklist.ui.validateBag);
    await tester.ensureVisible(valider);
    await tester.pumpAndSettle();
    await tester.tap(valider);
    await tester.pumpAndSettle();

    expect(
      tester.takeException(),
      isNull,
      reason:
          'le dialogue des obligatoires manquants doit s ouvrir ; avant le '
          'passage par AppButton, la Row d actions jetait « BoxConstraints '
          'forces an infinite width » sous le theme reel',
    );
    // Les deux actions du dialogue sont bien la et lisibles.
    expect(find.text(t.checklist.ui.understood), findsOneWidget);
    expect(find.text(t.checklist.ui.validateAnyway), findsOneWidget);
  });
}
