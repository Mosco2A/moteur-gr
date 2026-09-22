import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/checklist/presentation/checklist_screen.dart';
import 'package:moteur_gr/features/checklist/providers/checklist_provider.dart';
import 'package:moteur_gr/features/feasibility/domain/hiker_input_bounds.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// NON-REGRESSION FIX-1 — « ce qu'on accepte et ce qu'on dit » cote Sac.
///
/// Findings couverts (rapport personas cycle4, fiche #100167) :
///  - B1 (BLOQUANT) : le champ « Poids corporel » du bandeau Materiel & Sac
///    n'avait ni filtre, ni borne haute, ni message : l'app AFFICHAIT
///    « Poids du sac : Infinity kg » et « 150000000.0 kg », et une fois
///    Infinity pose, plus rien ne le reinitialisait ;
///  - M3 : clamps SILENCIEUX du poids d'article (99999999 g -> 50 000 g,
///    999999999999999999999 g -> 100 g par depassement 64 bits) ;
///  - m4 : quantite d'article non bornee en session alors que le rechargement
///    clampe a 999 (divergence affichage / etat recharge).
void main() {
  const testTrail = TrailConfig(
    id: 'test_trail',
    name: 'Test Trail',
    displayName: 'Test',
    tagline: 'Test tagline',
    totalStages: 5,
    totalDistanceKm: 50.0,
    totalElevationGain: 3000,
    region: 'Test Region',
    country: 'France',
    primaryColorValue: 0xFF2E7D32,
    secondaryColorValue: 0xFF1565C0,
    gpxAssetPath: 'assets/gpx/test.gpx',
    defaultDuration: 5,
    availableDurations: [3, 5, 7],
  );

  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Widget wrap() {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        trailConfigProvider.overrideWithValue(testTrail),
      ],
      child: TranslationProvider(
        child: MaterialApp.router(
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
  }

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(ChecklistScreen)));

  group('B1 (BLOQUANT) — poids corporel : le provider refuse l absurde', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        trailConfigProvider.overrideWithValue(testTrail),
      ]);
    });

    tearDown(() => container.dispose());

    test('Infinity, NaN, 1e9 et 890 kg sont IGNORES (etat inchange)', () async {
      final notifier = container.read(checklistProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      notifier.setBodyWeight(80);
      expect(container.read(checklistProvider).bodyWeightKg, 80);

      // Les 4 saisies qui produisaient un verdict absurde a l'ecran.
      notifier.setBodyWeight(double.infinity);
      notifier.setBodyWeight(double.nan);
      notifier.setBodyWeight(1e9);
      notifier.setBodyWeight(890);
      notifier.setBodyWeight(-50);
      notifier.setBodyWeight(0);

      // Le dernier poids VALIDE est conserve : aucune valeur absurde ne passe,
      // et le ratio reste calculable (plus de « Infinity kg »).
      final state = container.read(checklistProvider);
      expect(state.bodyWeightKg, 80);
      expect(state.backpackRatio.isFinite, isTrue);
    });

    test('les bornes poids sont celles de la fiche morpho', () async {
      final notifier = container.read(checklistProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      notifier.setBodyWeight(kWeightMinKg.toDouble());
      expect(container.read(checklistProvider).bodyWeightKg, kWeightMinKg);
      notifier.setBodyWeight(kWeightMaxKg.toDouble());
      expect(container.read(checklistProvider).bodyWeightKg, kWeightMaxKg);

      notifier.setBodyWeight(kWeightMinKg - 0.1);
      notifier.setBodyWeight(kWeightMaxKg + 0.1);
      expect(container.read(checklistProvider).bodyWeightKg, kWeightMaxKg,
          reason: 'hors bornes = refus, on garde la derniere valeur valide');
    });

    test('un randonneur de 160 kg pilote la jauge comme les autres', () async {
      // Decision Chris #100328 : l ancien plafond de 150 kg excluait a la porte
      // d entree exactement les randonneurs pour qui le dispositif de charge du
      // sac a le plus de valeur. Le bandeau doit les accepter.
      final notifier = container.read(checklistProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      notifier.setBodyWeight(160);
      expect(container.read(checklistProvider).bodyWeightKg, 160);
      expect(container.read(checklistProvider).backpackRatio.isFinite, isTrue);
    });

    test('l injection depuis le profil applique la meme regle', () async {
      final notifier = container.read(checklistProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      notifier.seedBodyWeightFromProfile(double.infinity);
      notifier.seedBodyWeightFromProfile(900);
      expect(container.read(checklistProvider).bodyWeightKg,
          kDefaultBodyWeightKg);

      notifier.seedBodyWeightFromProfile(64);
      expect(container.read(checklistProvider).bodyWeightKg, 64);
    });
  });

  group('B1 (BLOQUANT) — poids corporel : l ecran filtre et dit pourquoi', () {
    testWidgets('« Infinity » et « abc » n entrent meme pas dans le champ',
        (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      final field = find.byKey(const ValueKey('checklist-body-weight-field'));
      expect(field, findsOneWidget);

      await tester.enterText(field, 'Infinity');
      await tester.pumpAndSettle();

      // Les lettres sont filtrees A LA SAISIE : il ne reste rien a parser.
      expect(find.text('Infinity'), findsNothing);
      expect(tester.widget<TextField>(field).controller!.text, '');
      // Et surtout : le bandeau n'affiche PAS de verdict absurde.
      expect(find.textContaining('Infinity'), findsNothing);
      expect(containerOf(tester).read(checklistProvider).bodyWeightKg,
          kDefaultBodyWeightKg);

      await tester.enterText(field, 'abc');
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller!.text, '');
    });

    testWidgets('890 kg est REFUSE avec le message borne de la morpho',
        (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      final field = find.byKey(const ValueKey('checklist-body-weight-field'));
      await tester.enterText(field, '890');
      await tester.pumpAndSettle();

      // Message visible, identique a la fiche morpho (meme donnee, meme regle).
      final error = find.byKey(const ValueKey('checklist-body-weight-error'));
      expect(error, findsOneWidget);
      expect(tester.widget<Text>(error).data, t.hikerProfile.errorWeight);
      // La jauge garde le dernier poids valide.
      expect(containerOf(tester).read(checklistProvider).bodyWeightKg,
          kDefaultBodyWeightKg);
    });

    testWidgets('une saisie valide efface le message et pilote la jauge',
        (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      final field = find.byKey(const ValueKey('checklist-body-weight-field'));
      await tester.enterText(field, '890');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('checklist-body-weight-error')),
          findsOneWidget);

      await tester.enterText(field, '62');
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('checklist-body-weight-error')),
          findsNothing);
      expect(containerOf(tester).read(checklistProvider).bodyWeightKg, 62);
    });

    testWidgets('la saisie est physiquement limitee a 5 caracteres',
        (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      final field = find.byKey(const ValueKey('checklist-body-weight-field'));
      await tester.enterText(field, '150000000');
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(field).controller!.text, '15000');
      // Depassement SIGNALE (pas de troncature muette) et valeur refusee.
      expect(find.byKey(const ValueKey('checklist-body-weight-error')),
          findsOneWidget);
      expect(containerOf(tester).read(checklistProvider).bodyWeightKg,
          kDefaultBodyWeightKg);
    });
  });

  group('M3 — poids d article : refus motive, plus de clamp silencieux', () {
    testWidgets('99999999 g et 21 chiffres sont impossibles a saisir',
        (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      // Les categories sont repliees par defaut : en ouvrir une.
      await tester.tap(find.byType(ExpansionTile).first);
      await tester.pumpAndSettle();

      final addButton = find.text(t.checklist.ui.addItem).first;
      await tester.ensureVisible(addButton);
      await tester.pumpAndSettle();
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      final weightField =
          find.byKey(const ValueKey('checklist-add-weight-field'));
      expect(weightField, findsOneWidget);

      await tester.enterText(weightField, '99999999');
      await tester.pumpAndSettle();
      // Barriere physique : 5 chiffres max -> le nombre a 8 chiffres ne rentre
      // pas, et le depassement est SIGNALE.
      expect(tester.widget<TextField>(weightField).controller!.text, '99999');
      expect(find.text(t.checklist.ui.errorWeightGrams), findsOneWidget);

      await tester.enterText(weightField, '999999999999999999999');
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(weightField).controller!.text, '99999');
    });

    testWidgets('au-dela de 50 000 g : refus avec message, rien n est ajoute',
        (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();
      final before =
          containerOf(tester).read(checklistProvider).items.length;

      await tester.tap(find.byType(ExpansionTile).first);
      await tester.pumpAndSettle();
      final addButton = find.text(t.checklist.ui.addItem).first;
      await tester.ensureVisible(addButton);
      await tester.pumpAndSettle();
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const ValueKey('checklist-add-weight-field')),
          '60000');
      await tester.enterText(
          find.widgetWithText(TextField, t.checklist.ui.fieldName).first,
          'Rechaud');
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.checklist.ui.add));
      await tester.pumpAndSettle();

      // Le dialogue RESTE ouvert avec le message : aucun article n'a ete cree
      // avec un poids invente.
      expect(find.text(t.checklist.ui.errorWeightGrams), findsOneWidget);
      expect(find.byKey(const ValueKey('checklist-add-weight-field')),
          findsOneWidget);
      expect(containerOf(tester).read(checklistProvider).items.length, before);
    });

    testWidgets('un nom vide est refuse avec un message (plus de no-op muet)',
        (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ExpansionTile).first);
      await tester.pumpAndSettle();
      final addButton = find.text(t.checklist.ui.addItem).first;
      await tester.ensureVisible(addButton);
      await tester.pumpAndSettle();
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.checklist.ui.add));
      await tester.pumpAndSettle();

      expect(find.text(t.checklist.ui.errorNameRequired), findsOneWidget);
    });

    testWidgets('une saisie valide ajoute bien l article avec SON poids',
        (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();
      final container = containerOf(tester);
      final before = container.read(checklistProvider).items.length;

      await tester.tap(find.byType(ExpansionTile).first);
      await tester.pumpAndSettle();
      final addButton = find.text(t.checklist.ui.addItem).first;
      await tester.ensureVisible(addButton);
      await tester.pumpAndSettle();
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextField, t.checklist.ui.fieldName).first,
          'Rechaud');
      await tester.enterText(
          find.byKey(const ValueKey('checklist-add-weight-field')), '450');
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.checklist.ui.add));
      await tester.pumpAndSettle();

      final items = container.read(checklistProvider).items;
      expect(items.length, before + 1);
      final added = items.firstWhere((i) => i.customName == 'Rechaud');
      expect(added.weightGrams, 450,
          reason: 'le poids saisi est celui enregistre, sans clamp muet');
    });
  });

  group('m4 — quantite bornee en session comme au rechargement', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        trailConfigProvider.overrideWithValue(testTrail),
      ]);
    });

    tearDown(() => container.dispose());

    test('la quantite ne depasse jamais kItemQuantityMax', () async {
      final notifier = container.read(checklistProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      await notifier.toggle('backpack'); // article coche
      await notifier.setItemQuantity('backpack', 5000);

      final item = container
          .read(checklistProvider)
          .items
          .firstWhere((i) => i.template.id == 'backpack');
      expect(item.quantity, kItemQuantityMax,
          reason: 'affichage et etat recharge doivent converger');
    });
  });
}
