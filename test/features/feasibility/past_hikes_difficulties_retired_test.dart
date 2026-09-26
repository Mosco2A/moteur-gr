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

/// TACHE 570, S2 — LA LISTE DES DIFFICULTES EST RETIREE.
///
/// LA MESURE QUI A MOTIVE LE RETRAIT. Le champ texte libre « difficultes
/// rencontrees » etait saisi, persiste en prefs (`hiker.experienceNote`),
/// recopie dans un miroir Drift, synchronise au cloud
/// (`free_text_difficulties`), restaure a la reinstallation... ET LU PAR
/// PERSONNE : `experienceNoteProvider` n'apparaissait que dans son propre ecran
/// et son propre provider. Le commentaire du depot l'avouait lui-meme : « V1 :
/// STOCKEE seulement (l'IA la lira en V2) ». Decision de Chris du 26/09 : « que
/// la liste des difficultes rencontrees va servir a quelque chose, sinon tu le
/// vire pour l'instant ».
///
/// COLLECTER UNE DONNEE QUE RIEN NE LIT EST UN MANQUEMENT A LA MINIMISATION
/// (RGPD art. 5.1.c) : ce n'est pas seulement du code mort, c'est de la donnee
/// personnelle prise sans finalite. Elle part.
///
/// CE QUI NE DOIT PAS PARTIR AVEC ELLE : le retour a la faisabilite. La tache
/// 568 (LOT Q) avait corrige un defaut de Chris — « enregistrer dit que la note
/// est enregistree mais ne revient pas a faisabilite ». Le bouton reste donc,
/// il depile toujours, et il ne mentionne plus une note qui n'existe plus.
void main() {
  setUpAll(() => LocaleSettings.setLocaleRaw('fr'));

  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() async => db.close());

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
            initialLocation: '/home/past-hikes',
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) =>
                    const Scaffold(body: Center(child: Text('FAISABILITE'))),
                routes: [
                  GoRoute(
                    path: 'past-hikes',
                    builder: (_, __) => const PastHikesScreen(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('aucun champ de texte libre « difficultes » a l ecran',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    // L'ecran est bien celui des randos passees.
    expect(find.text(t.pastHikes.title), findsWidgets);

    // PLUS AUCUNE ZONE DE SAISIE LIBRE. Les champs chiffres vivent dans la
    // feuille modale d'ajout (fermee ici) : l'ecran lui-meme ne doit donc
    // porter aucun `TextField`.
    expect(
      find.byType(TextField, skipOffstage: false),
      findsNothing,
      reason: 'le texte libre difficultes est retire, rien ne le remplace',
    );

    // Et aucun libelle ne parle plus de difficultes.
    for (final mot in <String>['ifficult', 'ampoules', 'genoux en descente']) {
      expect(
        find.textContaining(mot, skipOffstage: false),
        findsNothing,
        reason: 'l ecran mentionne encore « $mot »',
      );
    }
  });

  testWidgets('le bouton ramene a la faisabilite, sans promettre de note',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    // Le bouton ne dit plus « Enregistrer » (il n'y a plus rien a enregistrer
    // a cet instant : chaque rando est deja persistee a son ajout).
    expect(
      find.text(t.pastHikes.backToFeasibility),
      findsOneWidget,
      reason: 'le bouton doit annoncer ce qu il fait vraiment : le retour',
    );

    await tester.tap(find.text(t.pastHikes.backToFeasibility));
    await tester.pumpAndSettle();

    // ACQUIS DE LA TACHE 568 PRESERVE : on revient bien d ou l on venait.
    expect(find.text('FAISABILITE'), findsOneWidget,
        reason: 'la tache 568 avait corrige ce retour, il ne regresse pas');
  });
}
