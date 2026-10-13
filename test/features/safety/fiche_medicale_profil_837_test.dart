import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/recovery_code_service.dart';
import 'package:moteur_gr/features/auth/domain/auth_service.dart';
import 'package:moteur_gr/features/auth/presentation/profile_screen.dart';
import 'package:moteur_gr/features/auth/providers/auth_provider.dart';
import 'package:moteur_gr/features/checklist/widgets/checklist_preparation_section.dart';
import 'package:moteur_gr/features/hub/presentation/widgets/step_status_icon.dart';
import 'package:moteur_gr/features/safety/domain/models/health_info.dart';
import 'package:moteur_gr/features/safety/presentation/health_sheet_check.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TACHE 837 — LOT C (C4) : LA FICHE MEDICALE DEVIENT UNE DONNEE DU PROFIL.
///
/// Christophe : « Fiche medicale dans profil », et elle reste listee dans la
/// check-list de preparation de chaque randonnee, cochee ou non selon sa
/// completude — « c'est a dire une coche a trois etats : vide, partielle,
/// complete ».
///
/// ETAT MESURE AVANT CORRECTIF :
///  - la fiche n'avait qu'UN SEUL point d'entree dans toute l'app, l'ecran
///    d'URGENCE (`emergency_screen.dart` -> push('/health')) : on la
///    decouvrait au pire moment pour la remplir ;
///  - elle etait absente du profil ET absente de la check-list ;
///  - elle n'avait AUCUN calcul de completude : juste `hasData`, un booleen
///    « au moins un champ », qui disait donc « remplie » pour un groupe
///    sanguin seul.
///
/// CE QUI EST FIGE ICI : les trois etats, la presence dans le profil, et le
/// fait que la check-list CONSTATE sans pouvoir modifier (aucune case a cocher
/// sur cette ligne, et elle ne compte comme faite que COMPLETE).
void main() {
  group('les trois etats de la fiche (vide / partielle / complete)', () {
    test('fiche vierge -> VIDE', () {
      const fiche = HealthInfo();
      expect(fiche.filledFieldCount, 0);
      expect(fiche.completion, HealthSheetCompletion.empty);
    });

    test('un seul champ -> PARTIELLE (et non « remplie »)', () {
      // C'est LE cas que `hasData` traitait comme une fiche complete.
      const fiche = HealthInfo(bloodType: 'A+');
      expect(fiche.hasData, isTrue);
      expect(fiche.filledFieldCount, 1);
      expect(fiche.completion, HealthSheetCompletion.partial);
    });

    test('quatre champs sur cinq -> encore PARTIELLE', () {
      const fiche = HealthInfo(
        bloodType: 'O-',
        allergies: 'penicilline',
        treatments: 'aucun',
        doctorContact: 'Dr Dupont',
      );
      expect(fiche.filledFieldCount, 4);
      expect(fiche.completion, HealthSheetCompletion.partial);
    });

    test('les cinq champs -> COMPLETE', () {
      const fiche = HealthInfo(
        bloodType: 'O-',
        allergies: 'penicilline',
        treatments: 'aucun',
        doctorContact: 'Dr Dupont',
        insuranceNumber: 'CEAM-123',
      );
      expect(fiche.filledFieldCount, HealthInfo.fieldCount);
      expect(fiche.completion, HealthSheetCompletion.complete);
    });

    test('des espaces ne remplissent rien', () {
      // Une fiche d'espaces ne secourt personne : elle reste VIDE.
      const fiche = HealthInfo(
        bloodType: '   ',
        allergies: '\n',
        treatments: ' \t ',
      );
      expect(fiche.filledFieldCount, 0);
      expect(fiche.completion, HealthSheetCompletion.empty);
    });

    test('la coche montre une FORME differente par etat (daltonisme)', () {
      // La lisibilite ne doit pas reposer sur la seule couleur.
      expect(
        HealthSheetCheck.statusOf(HealthSheetCompletion.empty),
        PlanningStepStatus.notStarted,
      );
      expect(
        HealthSheetCheck.statusOf(HealthSheetCompletion.partial),
        PlanningStepStatus.inProgress,
      );
      expect(
        HealthSheetCheck.statusOf(HealthSheetCompletion.complete),
        PlanningStepStatus.completed,
      );
      // Et les trois libelles sont traduits (zero texte en dur).
      final libelles = HealthSheetCompletion.values
          .map((c) => HealthSheetCheck.label(t, c))
          .toSet();
      expect(libelles.length, 3, reason: 'trois etats, trois libelles');
      expect(libelles.any((l) => l.trim().isEmpty), isFalse);
    });
  });

  group('la fiche est DANS LE PROFIL', () {
    late AppDatabase db;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    Widget wrapProfil(ProviderContainer container) {
      final router = GoRouter(
        initialLocation: '/my-treks/profile',
        routes: [
          GoRoute(
            path: '/my-treks',
            builder: (_, __) => const Scaffold(body: SizedBox()),
            routes: [
              GoRoute(
                path: 'profile',
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
          GoRoute(path: '/health', builder: (_, __) => const Text('FICHE')),
        ],
      );
      return UncontrolledProviderScope(
        container: container,
        child: TranslationProvider(
          child: MaterialApp.router(routerConfig: router),
        ),
      );
    }

    Future<void> pumpProfil(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          currentUserProvider.overrideWith(
            (ref) => Stream.value(
              const AuthUser(uid: 'u1', authMethod: AuthMethodValues.anonymous),
            ),
          ),
          recoveryCodeProvider.overrideWith(
            (ref) async => 'AAAA-BBBB-CCCC-DDDD',
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(wrapProfil(container));
      await tester.pumpAndSettle();
    }

    testWidgets('le profil porte la fiche, et dit qu elle est A REMPLIR', (
      tester,
    ) async {
      await pumpProfil(tester);

      // La tuile existe (elle n'existait pas du tout avant la tache 837).
      expect(
        find.byKey(const ValueKey('profile-health-sheet')),
        findsOneWidget,
      );
      expect(find.text(t.health.entryTitle), findsOneWidget);
      // Base vide -> etat VIDE annonce en clair.
      expect(find.text(t.health.completion.empty), findsOneWidget);
    });

    testWidgets('une fiche partielle est annoncee PARTIELLE, pas remplie', (
      tester,
    ) async {
      await db.healthInfoDao.insertEntry(
        HealthInfoEntriesCompanion.insert(bloodType: const Value('AB+')),
      );
      await pumpProfil(tester);

      expect(find.text(t.health.completion.partial), findsOneWidget);
      expect(find.text(t.health.completion.complete), findsNothing);
    });

    testWidgets('une fiche complete est annoncee COMPLETE', (tester) async {
      await db.healthInfoDao.insertEntry(
        HealthInfoEntriesCompanion.insert(
          bloodType: const Value('AB+'),
          allergies: const Value('penicilline'),
          treatments: const Value('aucun'),
          doctorContact: const Value('Dr Dupont'),
          insuranceNumber: const Value('CEAM-123'),
        ),
      );
      await pumpProfil(tester);

      expect(find.text(t.health.completion.complete), findsOneWidget);
    });

    testWidgets('depuis le profil, la fiche s ouvre (on la remplit la)', (
      tester,
    ) async {
      await pumpProfil(tester);

      await tester.tap(find.byKey(const ValueKey('profile-health-sheet')));
      await tester.pumpAndSettle();

      expect(find.text('FICHE'), findsOneWidget);
    });
  });

  group('la check-list de preparation ne fait que CONSTATER', () {
    late AppDatabase db;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    Future<void> pumpChecklist(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        initialLocation: '/prepa',
        routes: [
          GoRoute(
            path: '/prepa',
            builder: (_, __) => const Scaffold(
              body: SingleChildScrollView(
                child: ChecklistPreDepartureSection(),
              ),
            ),
          ),
          GoRoute(path: '/health', builder: (_, __) => const Text('FICHE')),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: TranslationProvider(
            child: MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // La section est un ExpansionTile replie : on l'ouvre.
      await tester.tap(find.text(t.checklist.ui.preDepartureTitle));
      await tester.pumpAndSettle();
    }

    testWidgets('la fiche y est listee, SANS case a cocher', (tester) async {
      await pumpChecklist(tester);

      final ligne = find.byKey(const ValueKey('predeparture-health-sheet'));
      expect(ligne, findsOneWidget);
      expect(find.text(t.health.entryTitle), findsOneWidget);

      // ON NE COCHE PAS UNE FICHE MEDICALE A LA MAIN : aucune Checkbox dans
      // cette ligne. Les 8 autres rappels en ont une, elle non.
      expect(
        find.descendant(of: ligne, matching: find.byType(Checkbox)),
        findsNothing,
      );
      // Mais elle porte la coche a trois etats, en lecture.
      expect(
        find.descendant(of: ligne, matching: find.byType(HealthSheetCheck)),
        findsOneWidget,
      );
    });

    testWidgets('fiche vide : comptee dans le total, PAS dans les faits', (
      tester,
    ) async {
      await pumpChecklist(tester);

      // 8 rappels + la fiche = 9 lignes au total, 0 faite.
      final attendu = t.checklist.ui.preDepartureCounter
          .replaceAll('{checked}', '0')
          .replaceAll('{total}', '9');
      expect(find.text(attendu), findsOneWidget);
      expect(find.text(t.health.completion.empty), findsOneWidget);
    });

    testWidgets('fiche PARTIELLE : toujours pas comptee comme faite', (
      tester,
    ) async {
      await db.healthInfoDao.insertEntry(
        HealthInfoEntriesCompanion.insert(bloodType: const Value('A+')),
      );
      await pumpChecklist(tester);

      // Une fiche a moitie remplie ne doit pas rassurer a tort.
      final attendu = t.checklist.ui.preDepartureCounter
          .replaceAll('{checked}', '0')
          .replaceAll('{total}', '9');
      expect(find.text(attendu), findsOneWidget);
      expect(find.text(t.health.completion.partial), findsOneWidget);
    });

    testWidgets('fiche COMPLETE : la check-list la compte comme faite', (
      tester,
    ) async {
      await db.healthInfoDao.insertEntry(
        HealthInfoEntriesCompanion.insert(
          bloodType: const Value('A+'),
          allergies: const Value('aucune'),
          treatments: const Value('aucun'),
          doctorContact: const Value('Dr Dupont'),
          insuranceNumber: const Value('CEAM-9'),
        ),
      );
      await pumpChecklist(tester);

      // 1 fait sur 9, sans que l'utilisateur ait coche quoi que ce soit ici :
      // la check-list a CONSTATE l'etat du profil.
      final attendu = t.checklist.ui.preDepartureCounter
          .replaceAll('{checked}', '1')
          .replaceAll('{total}', '9');
      expect(find.text(attendu), findsOneWidget);
      expect(find.text(t.health.completion.complete), findsOneWidget);
    });

    testWidgets('depuis la check-list, la fiche s ouvre (on ne la coche pas)', (
      tester,
    ) async {
      await pumpChecklist(tester);

      await tester.tap(find.byKey(const ValueKey('predeparture-health-sheet')));
      await tester.pumpAndSettle();

      expect(find.text('FICHE'), findsOneWidget);
    });
  });
}
