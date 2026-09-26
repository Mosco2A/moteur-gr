import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/feasibility/data/hiker_profile_repository.dart';
import 'package:moteur_gr/features/feasibility/presentation/past_hikes_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Q3 (tache 568, LOT Q) — « ENREGISTRER » DISAIT OUI ET NE RAMENAIT PAS.
///
/// CE QUE CHRIS A VU, verbatim (26/09 09:59) : « Apres 5 derniere rando,
/// enregistrer dit que la note est enregistree mais ne revient pas a
/// faisabilite ».
///
/// LA CAUSE, mesuree : `_saveNote` sauvegardait, affichait la SnackBar
/// `difficultiesSaved` et S ARRETAIT LA — aucun `pop`. Le randonneur restait sur
/// l'ecran avec un message de succes et devait retrouver le retour lui-meme.
/// MEME MOTIF QUE LE BOUTON MORT DE L ACCUEIL (Q1) : l'action reussit, la
/// navigation ne suit pas.
///
/// LES DEUX CHEMINS D ENREGISTREMENT DE CET ECRAN, ET CE QUE CHACUN DOIT FAIRE :
///  1. LA NOTE DE DIFFICULTES (bouton « Enregistrer » en bas de l'ecran) : il
///     conclut le passage sur l'ecran -> il RAMENE la ou l'on venait (test
///     ROUGE avant correction, c'est le defaut de Chris) ;
///  2. L AJOUT / MODIFICATION D UNE RANDO (feuille modale) : « la ou l'on
///     venait » est LA LISTE elle-meme — on en saisit jusqu'a cinq, et la note
///     de difficultes se redige en dessous. Depiler l'ecran entier ici rendrait
///     le bouton « Ajouter une rando » inutilisable au-dela de la premiere et
///     jetterait la note en cours de frappe : ce serait creer le defaut voisin.
///     Le test ci-dessous VERROUILLE donc ce retour-la (la feuille se ferme, la
///     liste reapparait avec la rando ajoutee, l'ecran reste).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    await db.close();
  });

  /// L'ecran est POUSSE au-dessus d'un temoin : si le retour a lieu, le temoin
  /// reapparait (c'est la preuve observable, pas une supposition).
  Widget wrap() {
    final repo = HikerProfileRepository(db: db, prefs: prefs);
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        hikerProfileRepositoryProvider.overrideWithValue(repo),
      ],
      child: TranslationProvider(
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/feasibility/past-hikes',
            routes: [
              GoRoute(
                path: '/feasibility',
                builder: (_, __) =>
                    const Scaffold(body: Text('FAISABILITE_TEMOIN')),
                routes: [
                  GoRoute(
                    path: 'past-hikes',
                    builder: (_, __) => const PastHikesScreen(),
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

  group('Q3 — apres un enregistrement reussi, on est ramene', () {
    testWidgets(
      'le bouton du bas RAMENE a la faisabilite (et ne laisse pas le '
      'randonneur chercher le retour)',
      (tester) async {
        tester.view.physicalSize = const Size(390, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(wrap());
        await tester.pumpAndSettle();
        expect(find.byType(PastHikesScreen), findsOneWidget);

        // PLUS DE NOTE A SAISIR AVANT (tache 570, S2) : le champ texte libre
        // « difficultes » a ete retire. Le geste teste reste EXACTEMENT celui
        // du defaut de Chris — appuyer sur le bouton du bas de l'ecran — et
        // c'est son RETOUR qui est sous test, pas ce qu'il enregistrait.
        await tester.tap(find.text(t.pastHikes.backToFeasibility));
        await tester.pumpAndSettle();

        expect(
          find.byType(PastHikesScreen),
          findsNothing,
          reason: 'apres le geste de conclusion, l ecran est depile',
        );
        expect(
          find.text('FAISABILITE_TEMOIN'),
          findsOneWidget,
          reason: 'on revient LA D OU L ON VENAIT (defaut Chris 26/09 09:59)',
        );

        // LA NOTE N'EXISTE PLUS, LE RETOUR SI (tache 570, S2). Le champ texte
        // libre « difficultes » a ete retire : il etait stocke sur trois etages
        // et lu par personne. L'ACQUIS DE LA 568 EST ICI, et il est verifie
        // au-dessus : le bouton ramene toujours a la faisabilite. Ce qui a
        // change, c'est qu'il ne promet plus d'enregistrer ce qui n'existe pas.
        expect(
          prefs.getString(kHikerExperienceNotePrefsKey),
          isNull,
          reason: 'plus rien ne doit ecrire la note de difficultes',
        );
      },
    );

    testWidgets(
      'l ajout d une rando ramene A LA LISTE : la feuille se ferme, la rando '
      'apparait, et l ecran reste pour en saisir d autres',
      (tester) async {
        tester.view.physicalSize = const Size(390, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(wrap());
        await tester.pumpAndSettle();

        await tester.tap(find.text(t.pastHikes.addHike));
        await tester.pumpAndSettle();

        // Jours (requis) + distance (au moins un effort) : la feuille accepte.
        await tester.enterText(
          find.widgetWithText(TextFormField, t.pastHikes.fieldDays),
          '3',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, t.pastHikes.fieldDistance),
          '42',
        );
        await tester.pumpAndSettle();

        // Le bouton « Enregistrer » DE LA FEUILLE (le dernier rendu).
        await tester.tap(find.text(t.pastHikes.save).last);
        await tester.pumpAndSettle();

        expect(
          find.byType(PastHikesScreen),
          findsOneWidget,
          reason: 'on reste sur la liste : on en saisit jusqu a cinq, et la '
              'note de difficultes se redige en dessous',
        );
        expect(find.text('FAISABILITE_TEMOIN'), findsNothing);
        // La rando ajoutee est visible (la feuille a bien rendu sa valeur).
        expect(find.text('42 km'), findsOneWidget);
      },
    );
  });
}
