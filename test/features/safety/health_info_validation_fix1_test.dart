import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/safety/data/health_info_repository.dart';
import 'package:moteur_gr/features/safety/domain/health_bounds.dart';
import 'package:moteur_gr/features/safety/presentation/health_info_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// NON-REGRESSION FIX-1 — finding M6 : fiche sante VITALE (lue par le SOS).
///
/// Le `Form` portait une `_formKey`... jamais validee : `_save()` n'appelait
/// PAS `validate()`. « XYZ123!! » passait pour un groupe sanguin et le champ
/// allergies avalait 2000 caracteres. Ici on prouve que la saisie est filtree,
/// verifiee, bornee — et qu'une fiche incoherente n'est PAS enregistree.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    // TACHE 568 (LOT Q) : l'ecran pose desormais un SIGNAL DE PREPARATION en
    // preferences (fiche remplie / conseils lus, cf. `health_prepare_providers`)
    // — c'est lui qui entre dans la porte de demarrage du trek. Sans magasin de
    // preferences simule, l'enregistrement restait en attente et le bouton
    // gardait son spinner : `pumpAndSettle` ne rendait plus la main.
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() async {
    await db.close();
  });

  Widget wrap() {
    return ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
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
              GoRoute(path: '/consent', builder: (_, __) => const SizedBox()),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> tapSave(WidgetTester tester) async {
    final save = find.text(t.health.save);
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
  }

  group('M6 — groupe sanguin : liste fermee, plus de valeur inventee', () {
    test('la table de reference ne reconnait que les 8 groupes reels', () {
      for (final valid in kBloodTypes) {
        expect(isValidBloodType(valid), isTrue);
      }
      expect(isValidBloodType('ab+'), isTrue, reason: 'casse ignoree');
      expect(isValidBloodType(' O- '), isTrue, reason: 'espaces ignores');
      expect(isValidBloodType('XYZ123!!'), isFalse);
      expect(isValidBloodType('BBB'), isFalse);
      expect(isValidBloodType('C+'), isFalse);
      expect(normalizeBloodType(' a+ '), 'A+');
    });

    testWidgets('« XYZ123!! » ne peut meme pas etre saisi', (tester) async {
      tester.view.physicalSize = const Size(390, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      final field = find.byKey(const ValueKey('health-blood-type-field'));
      await tester.enterText(field, 'XYZ123!!');
      await tester.pumpAndSettle();

      final input = tester.widget<TextField>(
          find.descendant(of: field, matching: find.byType(TextField)));
      expect(input.controller!.text, '',
          reason: 'chiffres, ponctuation et lettres hors ABO sont filtres');
    });

    testWidgets('un groupe invalide bloque la sauvegarde avec un message',
        (tester) async {
      tester.view.physicalSize = const Size(390, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const ValueKey('health-blood-type-field')), 'BBB');
      await tester.pumpAndSettle();
      await tapSave(tester);

      expect(find.text(t.health.error.bloodType), findsOneWidget);
      // L'ecran n'est pas quitte et RIEN n'est enregistre.
      expect(find.byType(HealthInfoScreen), findsOneWidget);
      final saved = await HealthInfoRepository(dao: db.healthInfoDao).get();
      expect(saved.bloodType, '');
    });

    testWidgets('un groupe valide est enregistre sous forme canonique',
        (tester) async {
      tester.view.physicalSize = const Size(390, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const ValueKey('health-blood-type-field')), 'ab+');
      await tester.pumpAndSettle();
      await tapSave(tester);

      final saved = await HealthInfoRepository(dao: db.healthInfoDao).get();
      expect(saved.bloodType, 'AB+');
    });
  });

  group('M6 — texte libre medical borne (fini les 2000 caracteres)', () {
    testWidgets('le champ allergies s arrete a la borne', (tester) async {
      tester.view.physicalSize = const Size(390, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      final allergies =
          find.widgetWithText(TextFormField, t.health.field.allergies);
      await tester.enterText(allergies, 'a' * 2000);
      await tester.pumpAndSettle();

      final input = tester.widget<TextField>(
          find.descendant(of: allergies, matching: find.byType(TextField)));
      expect(input.controller!.text.length, kHealthFreeTextMaxLength);
      // La limite est VISIBLE (compteur), pas une coupe muette.
      expect(find.text('$kHealthFreeTextMaxLength/$kHealthFreeTextMaxLength'),
          findsOneWidget);
    });
  });
}
