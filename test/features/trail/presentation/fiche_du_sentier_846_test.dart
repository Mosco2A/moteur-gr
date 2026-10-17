// GARDE — TACHE 846 : CE QUE LA FICHE MONTRE, ET CE QU'ELLE NE MONTRE PAS.
//
// LES DEUX MOITIES DE CE FICHIER SE REPONDENT.
//
// LA PREMIERE verifie qu'un sentier DOCUMENTE montre tout : sa bande de photos,
// la MENTION de chaque photo — une licence CC-BY respectee dans un fichier JSON
// et nulle part ailleurs n'est pas respectee —, sa description en trois
// parties, sa difficulte deduite et la regle de deduction en clair.
//
// LA SECONDE verifie qu'un sentier SANS FICHE n'a pas l'air casse. C'est la
// quatrieme demande de la tache, verbatim : « l'application se comporte
// proprement quand un sentier n'a ni photo ni description : pas de trou, pas de
// point d'interrogation, pas de cadre vide ». Elle est plus difficile a tenir
// que la premiere, parce qu'un cadre vide est le comportement PAR DEFAUT de
// presque toutes les mises en page.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/config/trail_catalog.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage_row.dart';
import 'package:moteur_gr/domain/difficulte_du_sentier.dart';
import 'package:moteur_gr/features/trail/presentation/trail_detail_screen.dart';
import 'package:moteur_gr/features/trail/providers/fiche_de_sentier_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/features/trail/widgets/bande_de_photos.dart';
import 'package:moteur_gr/features/trail/widgets/description_du_sentier.dart';
import 'package:moteur_gr/features/trail/widgets/difficulte_calculee.dart';
import 'package:moteur_gr/features/trail/widgets/photo_de_couverture.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// UN PAQUET D'ASSETS DE TEST, ET POURQUOI IL LEVE UNE `Error`.
///
/// Pour un asset introuvable, Flutter leve un `FlutterError` (« Unable to load
/// asset »), qui descend d'`Error` et non d'`Exception`. Un faux paquet qui
/// leverait une `Exception` serait donc plus gentil que le vrai, et il
/// validerait un rattrapage qui ne rattraperait rien en production.
class PaquetDeTest extends CachingAssetBundle {
  /// Les fichiers servis, par chemin d'asset.
  PaquetDeTest(this.fichiers);

  /// Le contenu de chaque asset connu.
  final Map<String, String> fichiers;

  @override
  Future<ByteData> load(String key) async {
    final contenu = fichiers[key];
    if (contenu == null) {
      throw FlutterError('Unable to load asset: $key');
    }
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(contenu)));
  }
}

/// Le manifeste d'un sentier documente : deux photos publiables, une refusee.
String manifesteDuGr20() => jsonEncode(<String, Object?>{
  'schema': 1,
  'trailId': 'gr20',
  'description': {
    'ou_c_est': 'En Corse, de Calenzana a Conca.',
    'ce_qu_on_y_voit': 'La haute montagne corse sur toute sa crete.',
    'a_quoi_s_attendre':
        'Des journees de montagne, pas des journees de '
        'marche.',
  },
  'photos': [
    {
      'fichier': 'assets/data/gr20/photos/une_crete.jpg',
      'adresse_d_origine': 'https://exemple.invalid/une_crete',
      'auteur': 'Autrice d\'Essai',
      'licence': 'CC BY-SA 4.0',
      'mention': 'Autrice d\'Essai — CC BY-SA 4.0',
      'couverture': true,
    },
    {
      'fichier': 'assets/data/gr20/photos/un_refuge.jpg',
      'adresse_d_origine': 'https://exemple.invalid/un_refuge',
      'auteur': 'Auteur d\'Essai',
      'licence': 'CC0',
      'mention': 'Auteur d\'Essai — CC0',
    },
    {
      'fichier': 'assets/data/gr20/photos/sans_source.jpg',
      'adresse_d_origine': '',
      'auteur': 'Auteur d\'Essai',
      'licence': 'CC BY 4.0',
      'mention': 'Auteur d\'Essai — CC BY 4.0',
    },
  ],
});

/// Trois etapes de decor, assez contrastees pour que la difficulte bouge.
const etapesDeDecor = <StageModel>[
  StageModel(
    id: 1,
    trailId: 'gr20',
    stageNumber: 1,
    name: 'Premiere montee',
    distanceKm: 11.35,
    elevationGainM: 1453,
    elevationLossM: 194,
    startLat: 42,
    startLng: 9,
    endLat: 42.1,
    endLng: 9.1,
  ),
  StageModel(
    id: 2,
    trailId: 'gr20',
    stageNumber: 2,
    name: 'Deuxieme journee',
    distanceKm: 7.34,
    elevationGainM: 639,
    elevationLossM: 915,
    startLat: 42.1,
    startLng: 9.1,
    endLat: 42.2,
    endLng: 9.2,
  ),
  StageModel(
    id: 3,
    trailId: 'gr20',
    stageNumber: 3,
    name: 'Troisieme journee',
    distanceKm: 4.91,
    elevationGainM: 768,
    elevationLossM: 589,
    startLat: 42.2,
    startLng: 9.2,
    endLat: 42.3,
    endLng: 9.3,
  ),
];

void main() {
  Widget fiche({required String trailId, required List<dynamic> overrides}) =>
      ProviderScope(
        overrides: overrides.cast(),
        child: TranslationProvider(
          child: MaterialApp(home: TrailDetailScreen(trailId: trailId)),
        ),
      );

  /// AMENE UN BLOC A L'ECRAN AVANT DE L'INTERROGER, ET POURQUOI IL FAUT LE
  /// FAIRE DEPUIS LA TACHE 846.
  ///
  /// La fiche defile desormais d'un seul mouvement (`CustomScrollView`). Dans
  /// un defilement, un `Finder` ordinaire ne voit QUE ce qui est peint : le
  /// `Viewport` declare « hors scene » tout sliver dont la part visible est
  /// nulle, si bien qu'un bloc parfaitement construit mais sous la ligne de
  /// flottaison est introuvable. Mesure faite en ecrivant ces cas : avec une
  /// bande de photos et une description au-dessus, la difficulte sortait de
  /// l'ecran de 800 x 600 du banc de test.
  ///
  /// On fait donc ce que le randonneur fait : on defile. C'est plus fidele
  /// qu'un `skipOffstage: false`, qui prouverait seulement que le widget
  /// EXISTE — or ce qui est demande ici est qu'il se VOIE.
  Future<void> amener(WidgetTester tester, Finder cible) async {
    await tester.ensureVisible(cible);
    await tester.pumpAndSettle();
  }

  /// Le bloc de difficulte, cherche dans TOUT l'arbre pour pouvoir y defiler.
  Finder blocDeDifficulte() =>
      find.byKey(const ValueKey('difficulte-calculee'), skipOffstage: false);

  group('846 — un sentier documente montre tout', () {
    Future<void> poser(WidgetTester tester) async {
      await tester.pumpWidget(
        fiche(
          trailId: 'gr20',
          overrides: [
            trailConfigProvider.overrideWithValue(TrailCatalog.byId('gr20')!),
            stagesProvider(
              'gr20',
            ).overrideWith((ref) => Future.value(etapesDeDecor)),
            paquetDAssetsProvider.overrideWithValue(
              PaquetDeTest({'assets/data/gr20/fiche.json': manifesteDuGr20()}),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('la bande de photos est la, et chaque MENTION est lisible', (
      tester,
    ) async {
      await poser(tester);

      expect(find.byType(BandeDePhotos), findsOneWidget);
      expect(find.byKey(const ValueKey('bande-de-photos')), findsOneWidget);
      // Les deux photos publiables, avec leur credit AFFICHE.
      expect(find.text('Autrice d\'Essai — CC BY-SA 4.0'), findsOneWidget);
      expect(find.text('Auteur d\'Essai — CC0'), findsOneWidget);
      // La troisieme n'a pas d'adresse d'origine : elle n'arrive meme pas
      // jusqu'au widget.
      expect(find.text('Auteur d\'Essai — CC BY 4.0'), findsNothing);
    });

    testWidgets('la description s affiche en trois parties titrees', (
      tester,
    ) async {
      await poser(tester);

      expect(find.byType(DescriptionDuSentier), findsOneWidget);
      expect(find.text('Ou c\'est'), findsOneWidget);
      expect(find.text('Ce qu\'on y voit'), findsOneWidget);
      expect(find.text('A quoi s\'attendre'), findsOneWidget);
      expect(find.text('En Corse, de Calenzana a Conca.'), findsOneWidget);
    });

    testWidgets('la difficulte est deduite, et la REGLE est a l ecran', (
      tester,
    ) async {
      await poser(tester);
      await amener(tester, blocDeDifficulte());

      expect(find.byType(DifficulteCalculee), findsOneWidget);
      expect(find.byKey(const ValueKey('difficulte-calculee')), findsOneWidget);
      // LA REGLE EST AFFICHEE, mot pour mot celle que le socle applique.
      expect(find.text(SeuilsDeDifficulte.regleAffichee), findsOneWidget);
      // ET LES MESURES SONT A COTE DU MOT : 2 578 m d'altitude (la mesure du
      // GR20) et la pire journee de decor, 1 453 m.
      expect(
        find.textContaining('2578 m au point le plus haut'),
        findsOneWidget,
      );
      expect(
        find.textContaining('1453 m de montee en une seule journee'),
        findsOneWidget,
      );
    });

    testWidgets('la journee comptee est la VRAIE, pas celle demandee', (
      tester,
    ) async {
      await poser(tester);
      await amener(tester, blocDeDifficulte());

      // AUCUNE allure n'est proposee ici, et c'est le comportement voulu : le
      // GR20 propose 7, 10, 12 et 16 jours, or ce decor n'a que TROIS etapes.
      // Au-dela de trois jours, les jours de plus sont du repos et ne changent
      // plus aucune journee de marche — offrir le choix serait offrir un
      // bouton sans effet.
      for (final jours in <int>[7, 10, 12, 16]) {
        expect(
          find.byKey(ValueKey('allure-$jours'), skipOffstage: false),
          findsNothing,
          reason: '$jours jours n a pas de sens sur trois etapes',
        );
      }

      // LE NOMBRE AFFICHE EST CELUI DU DECOUPAGE, PAS CELUI DE LA DEMANDE :
      // seize jours demandes, trois journees de marche reelles. Il apparait
      // deux fois — a cote de la pastille, et dans la mesure du premier
      // critere — et les deux disent la meme chose.
      expect(find.text('sur 3 journees de marche'), findsOneWidget);
      expect(
        find.textContaining('953 m de montee par jour, sur 3 journees'),
        findsOneWidget,
      );
    });
  });

  group('846 — un sentier sans fiche n a pas l air casse', () {
    testWidgets('ni bande de photos, ni description, et AUCUN cadre vide', (
      tester,
    ) async {
      await tester.pumpWidget(
        fiche(
          trailId: 'test-trail',
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            stagesProvider(
              'test-trail',
            ).overrideWith((ref) => Future.value(etapesDeDecor)),
            paquetDAssetsProvider.overrideWithValue(PaquetDeTest(const {})),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // AUCUN de ces widgets n'est monte : ils ne sont pas vides, ils sont
      // absents. Un widget vide occupe une hauteur ; un widget absent, non.
      // `skipOffstage: false` EST LE POINT DE CES CINQ ASSERTIONS : un finder
      // ordinaire ne verrait pas un bloc sous la ligne de flottaison et
      // declarerait l'absence a tort. Celui-ci interroge TOUT l'arbre — ces
      // widgets ne sont pas invisibles, ils ne sont pas construits.
      expect(find.byType(BandeDePhotos, skipOffstage: false), findsNothing);
      expect(
        find.byType(DescriptionDuSentier, skipOffstage: false),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('bande-de-photos'), skipOffstage: false),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey('description-du-sentier'),
          skipOffstage: false,
        ),
        findsNothing,
      );
      // Aucune image : donc aucune icone d'image manquante non plus — le
      // sentier n'a pas de photo, il n'en a pas « perdu » une.
      expect(find.byType(Image, skipOffstage: false), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('la difficulte reste affichee : elle vient des ETAPES', (
      tester,
    ) async {
      // Elle ne depend pas du manifeste. Ce qui manque au sentier de test,
      // c'est l'ALTITUDE : le critere disparait et la fiche LE DIT.
      await tester.pumpWidget(
        fiche(
          trailId: 'test-trail',
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            stagesProvider(
              'test-trail',
            ).overrideWith((ref) => Future.value(etapesDeDecor)),
            paquetDAssetsProvider.overrideWithValue(PaquetDeTest(const {})),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await amener(tester, blocDeDifficulte());

      expect(find.byType(DifficulteCalculee), findsOneWidget);
      expect(
        find.textContaining('au point le plus haut', skipOffstage: false),
        findsNothing,
      );
      // DEUX FOIS, ET LES DEUX SONT VOULUES : la ligne qui NOMME la mesure
      // manquante, et la regle affichee, qui dit de quelles trois mesures le
      // niveau se deduit. Le randonneur lit donc ce qui manque ET par rapport
      // a quoi il manque.
      expect(
        find.textContaining("l'altitude maximale de la trace"),
        findsNWidgets(2),
      );
      expect(find.textContaining('Non mesure sur ce sentier'), findsOneWidget);
    });

    testWidgets('sans etape, pas de difficulte inventee', (tester) async {
      await tester.pumpWidget(
        fiche(
          trailId: 'test-trail',
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            stagesProvider(
              'test-trail',
            ).overrideWith((ref) => Future.value(<StageModel>[])),
            paquetDAssetsProvider.overrideWithValue(PaquetDeTest(const {})),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(blocDeDifficulte(), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('846 — la photo de couverture du catalogue', () {
    testWidgets('elle s affiche quand le manifeste en declare une', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            paquetDAssetsProvider.overrideWithValue(
              PaquetDeTest({'assets/data/gr20/fiche.json': manifesteDuGr20()}),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: PhotoDeCouverture(trailId: 'gr20')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('couverture-gr20')), findsOneWidget);
    });

    testWidgets('elle n occupe RIEN quand il n y en a pas', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            paquetDAssetsProvider.overrideWithValue(PaquetDeTest(const {})),
          ],
          child: const MaterialApp(
            home: Scaffold(body: PhotoDeCouverture(trailId: 'gr20')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsNothing);
      final taille = tester.getSize(find.byType(PhotoDeCouverture));
      expect(
        taille.height,
        0,
        reason: 'une couverture absente ne reserve aucune hauteur',
      );
    });
  });
}
