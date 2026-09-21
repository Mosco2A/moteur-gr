import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/feasibility/data/hiker_profile_repository.dart';
import 'package:moteur_gr/features/feasibility/presentation/hiker_profile_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// FICHE D'INFO VIDE — non-regression du defaut MAJEUR-3 de la campagne
/// personas du 21/09 (rapport #100277).
///
/// CE QUI S'EST PASSE : une fiche sans age, sans taille et sans poids etait
/// acceptee et persistee EN SILENCE. L'ecran se fermait, rien n'etait dit, et
/// ce profil 0/0/0 alimentait ensuite la faisabilite. Les saisies aberrantes,
/// elles, etaient deja refusees proprement (890 kg -> « Poids invalide », 1280
/// cm -> « Taille invalide »). La fiche vide recoit le meme traitement.
void main() {
  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  /// L'ecran est atteint par un push depuis /home (comme en prod) : le
  /// `Navigator.pop()` de la sauvegarde a bien une page ou revenir, donc un
  /// « l'ecran est quitte » se constate vraiment.
  Widget wrap() {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        hikerProfileRepositoryProvider
            .overrideWithValue(HikerProfileRepository(db: db, prefs: prefs)),
      ],
      child: TranslationProvider(
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/home/profile',
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const Scaffold(body: SizedBox()),
                routes: [
                  GoRoute(
                    path: 'profile',
                    builder: (_, __) => const HikerProfileScreen(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> ouvrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
  }

  final tp = t.hikerProfile;

  testWidgets('tous champs vides : refus avec message, rien enregistre',
      (tester) async {
    await ouvrir(tester);

    await tester.tap(find.text(tp.save));
    await tester.pumpAndSettle();

    // Le refus est DIT, et il est visible la ou l'on vient d'appuyer.
    expect(find.byKey(const ValueKey('hiker-profile-empty-error')),
        findsOneWidget);
    expect(find.text(tp.errorEmpty), findsOneWidget);
    // L'ecran n'est PAS quitte : le formulaire est toujours la.
    expect(find.text(tp.fieldAge), findsOneWidget);
    // Et rien n'a ete enregistre (aucune confirmation).
    expect(find.text(tp.saved), findsNothing);

    final persiste = await HikerProfileRepository(db: db, prefs: prefs).load();
    expect(persiste.isEmpty, isTrue,
        reason: 'aucun profil 0/0/0 ne doit atteindre la faisabilite');
  });

  testWidgets('saisir une donnee efface le refus', (tester) async {
    await ouvrir(tester);

    await tester.tap(find.text(tp.save));
    await tester.pumpAndSettle();
    expect(find.text(tp.errorEmpty), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, tp.fieldAge), '42');
    await tester.pumpAndSettle();

    expect(find.text(tp.errorEmpty), findsNothing);
  });

  testWidgets('une fiche renseignee passe toujours (le chemin normal tient)',
      (tester) async {
    await ouvrir(tester);

    await tester.enterText(
        find.widgetWithText(TextFormField, tp.fieldAge), '42');
    await tester.enterText(
        find.widgetWithText(TextFormField, tp.fieldHeight), '175');
    await tester.enterText(
        find.widgetWithText(TextFormField, tp.fieldWeight), '72');
    await tester.pumpAndSettle();

    await tester.tap(find.text(tp.save));
    await tester.pumpAndSettle();

    expect(find.text(tp.errorEmpty), findsNothing);
    final persiste = await HikerProfileRepository(db: db, prefs: prefs).load();
    expect(persiste.age, 42);
    expect(persiste.heightCm, 175);
    expect(persiste.weightKg, 72);
  });
}
