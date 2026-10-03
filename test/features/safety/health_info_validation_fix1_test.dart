import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/safety/data/health_info_file.dart';
import 'package:moteur_gr/features/safety/data/health_info_repository.dart';
import 'package:moteur_gr/features/safety/domain/health_bounds.dart';
import 'package:moteur_gr/features/safety/domain/models/health_info.dart';
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
  late Directory bacFiche;
  late HealthInfoFile fiche;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    // TACHE 613 : la fiche a son propre fichier, hors de la base.
    bacFiche = Directory.systemTemp.createTempSync('fiche613_validation');
    fiche = HealthInfoFile(dossierApplicatif: () async => bacFiche);
    // TACHE 568 (LOT Q) : l'ecran pose desormais un SIGNAL DE PREPARATION en
    // preferences (fiche remplie / conseils lus, cf. `health_prepare_providers`)
    // — c'est lui qui entre dans la porte de demarrage du trek. Sans magasin de
    // preferences simule, l'enregistrement restait en attente et le bouton
    // gardait son spinner : `pumpAndSettle` ne rendait plus la main.
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() async {
    await db.close();
    if (bacFiche.existsSync()) bacFiche.deleteSync(recursive: true);
  });

  Widget wrap() {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        healthInfoFileProvider.overrideWithValue(fiche),
      ],
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

    // ========================================================================
    // TACHE 630 — CES TROIS TESTS ONT CHANGE DE NATURE, ET LA RAISON EST QUE LA
    // GARANTIE, ELLE, A CHANGE DE NATURE.
    //
    // FIX-1 avait rendu la SAISIE LIBRE sure : filtrage des caracteres, puis
    // refus au `validate()` avec un message. Ils testaient donc qu'une valeur
    // inventee etait REFUSEE. Christophe a tranche autrement le 29/09
    // (DEM-260929-1135) : il n'existe que huit groupes sanguins, la saisie libre
    // n'a aucune raison d'exister sur une fiche d'urgence.
    //
    // ON NE TESTE PLUS QU'UNE MAUVAISE VALEUR EST REFUSEE : ON TESTE QU'ELLE EST
    // IMPOSSIBLE. C'est une garantie strictement plus forte, et les tests qui la
    // verifient remplacent — sans en perdre — ceux qui verifiaient la
    // precedente. Le refus au `validate()` reste couvert par le premier test du
    // groupe, qui porte sur la table de reference elle-meme.
    // ========================================================================

    testWidgets('il n existe AUCUN champ de saisie pour le groupe sanguin', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      final champ = find.byKey(const ValueKey('health-blood-type-field'));
      expect(champ, findsOneWidget);
      expect(
        find.descendant(of: champ, matching: find.byType(EditableText)),
        findsNothing,
        reason:
            'plus aucun clavier ne s ouvre sur le groupe sanguin : '
            '« XYZ123!! » n est plus refuse, il est INSAISISSABLE',
      );
    });

    testWidgets('la liste propose les HUIT groupes et « je ne sais pas », '
        'et rien d autre', (tester) async {
      tester.view.physicalSize = const Size(390, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      final champ = find.byKey(const ValueKey('health-blood-type-field'));
      await tester.ensureVisible(champ);
      await tester.tap(champ);
      await tester.pumpAndSettle();

      // NEUF choix, pas huit et pas dix : les huit groupes du systeme ABO +
      // Rhesus (source : Etablissement francais du sang) et « je ne sais pas »,
      // qui est une REPONSE et non un champ vide.
      expect(kBloodTypeChoices.length, 9);
      for (final groupe in kBloodTypes) {
        expect(
          find.text(groupe),
          findsWidgets,
          reason: 'le groupe $groupe doit etre proposable',
        );
      }
      expect(find.text(t.health.bloodTypeUnknown), findsWidgets);
    });

    testWidgets('un groupe choisi dans la liste est enregistre tel quel', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      final champ = find.byKey(const ValueKey('health-blood-type-field'));
      await tester.ensureVisible(champ);
      await tester.tap(champ);
      await tester.pumpAndSettle();
      await tester.tap(find.text('AB+').last);
      await tester.pumpAndSettle();
      await tapSave(tester);

      final saved = await HealthInfoRepository(fichier: fiche).get();
      expect(
        saved.bloodType,
        'AB+',
        reason:
            'la valeur vient d une liste fermee : elle est deja '
            'canonique, il n y a plus rien a normaliser',
      );
    });

    testWidgets('une valeur heritee non reconnue est MONTREE, jamais effacee', (
      tester,
    ) async {
      // CONSIGNE 630, mot pour mot : « les fiches deja saisies ne perdent
      // RIEN ». Une fiche remplie avant FIX-1 peut porter n importe quoi.
      await HealthInfoRepository(
        fichier: fiche,
      ).save(const HealthInfo(bloodType: 'XYZ123!!'));

      tester.view.physicalSize = const Size(390, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      // L avertissement existe ET il porte la valeur d origine : le randonneur
      // voit ce qu il avait ecrit, et choisit.
      expect(
        find.byKey(const ValueKey('health-blood-type-legacy')),
        findsOneWidget,
      );
      expect(
        find.textContaining('XYZ123!!'),
        findsOneWidget,
        reason:
            'la valeur heritee doit etre LUE par le randonneur, pas '
            'effacee dans son dos',
      );
      // Et le fichier, lui, n a pas ete touche par la simple ouverture.
      final surLeDisque = await HealthInfoRepository(fichier: fiche).get();
      expect(surLeDisque.bloodType, 'XYZ123!!');
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

      final allergies = find.widgetWithText(
        TextFormField,
        t.health.field.allergies,
      );
      await tester.enterText(allergies, 'a' * 2000);
      await tester.pumpAndSettle();

      final input = tester.widget<TextField>(
        find.descendant(of: allergies, matching: find.byType(TextField)),
      );
      expect(input.controller!.text.length, kHealthFreeTextMaxLength);
      // La limite est VISIBLE (compteur), pas une coupe muette.
      expect(
        find.text('$kHealthFreeTextMaxLength/$kHealthFreeTextMaxLength'),
        findsOneWidget,
      );
    });
  });
}
