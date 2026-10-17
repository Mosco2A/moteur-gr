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
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/config/trail_catalog.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/fiche_de_sentier.dart';
import 'package:moteur_gr/core/models/stage_row.dart';
import 'package:moteur_gr/domain/echelle_de_difficulte.dart';
import 'package:moteur_gr/domain/nuit_possible.dart';
import 'package:moteur_gr/features/planning/planning_facade.dart';
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

/// DEUX NUITS RELEVEES DE DECOR, et les deux segments qui les relient.
///
/// La pire journee y pese 800 m de montee, contre 1 453 m pour les etapes de
/// decor : c'est ce qui rend l'ecart visible a l'ecran.
DecoupageDeNuits deuxNuits() => DecoupageDeNuits.fromJson(<String, dynamic>{
  'trailId': 'gr20',
  'tete_de_sentier': 'Depart de decor',
  'liste': <Map<String, dynamic>>[
    <String, dynamic>{
      'nom': 'Premiere nuit de decor',
      'pk_km': 9.0,
      'altitude_m': 1200,
      'lat': 42.0,
      'lon': 9.0,
      'minutes_aller': 0,
      'minutes_retour': 0,
      'origine': 'coupure de jour relevee',
    },
    <String, dynamic>{
      'nom': 'Seconde nuit de decor',
      'pk_km': 18.0,
      'altitude_m': 1400,
      'lat': 42.1,
      'lon': 9.1,
      'minutes_aller': 0,
      'minutes_retour': 0,
      'origine': 'fin d etape',
      'fin_d_etape': 1,
    },
  ],
  'entre_les_nuits': <Map<String, dynamic>>[
    <String, dynamic>{
      'rang': 1,
      'depart': 'Depart de decor',
      'arrivee': 'Premiere nuit de decor',
      'km': 9.0,
      'dplus_m': 600,
      'dmoins_m': 100,
      'minutes': 240,
    },
    <String, dynamic>{
      'rang': 2,
      'depart': 'Premiere nuit de decor',
      'arrivee': 'Seconde nuit de decor',
      'km': 9.0,
      'dplus_m': 800,
      'dmoins_m': 200,
      'minutes': 260,
    },
  ],
});

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
            // LES NUITS SONT NEUTRALISEES ICI, ET C'EST VOLONTAIRE (tache
            // 848). La fiche pose desormais ses journees sur les NUITS
            // RELEVEES du sentier quand il en a, et `flutter test` sert les
            // vrais assets : sans cette surcharge, les trente et une nuits du
            // GR20 remplaceraient les trois etapes de decor et ces cas ne
            // mesureraient plus ce qu'ils annoncent. Le chemin « avec nuits »
            // a son propre cas, plus bas.
            decoupageDuSentierProvider(
              'gr20',
            ).overrideWithValue(DecoupageDeNuits.aucun),
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
      // LES DEUX JAUGES SONT LA (tache 848) : le verdict et la repartition.
      expect(find.byKey(const ValueKey('jauge-du-verdict')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('jauge-de-repartition')),
        findsOneWidget,
      );
      // LA MESURE EST A COTE DU MOT : la pire journee du decor, 1 453 m.
      // L'ALTITUDE N'Y EST PLUS — Christophe l'a sortie du calcul le 17/10
      // (« non la difficulte c'est surtout base sur l'etape la plus
      // compliquee et le denivele le plus fort »), donc le critere qui
      // affichait « 2 578 m au point le plus haut » n'existe plus. La fiche
      // cite toujours ce chiffre, mais dans sa DESCRIPTION, pas comme un
      // niveau.
      expect(find.textContaining('1453 m de montee'), findsOneWidget);
      expect(
        find.textContaining('au point le plus haut', skipOffstage: false),
        findsNothing,
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
      for (final jours in <int>[7, 9, 12, 16]) {
        expect(
          find.byKey(ValueKey('allure-$jours'), skipOffstage: false),
          findsNothing,
          reason: '$jours jours n a pas de sens sur trois etapes',
        );
      }

      // LE NOMBRE AFFICHE EST CELUI DU DECOUPAGE : seize jours CONSEILLES,
      // trois journees de marche reelles, parce que le decor n'a que trois
      // etapes et qu'aucune n'est jamais coupee. Les deux nombres sont a
      // l'ecran et ils ne se contredisent pas.
      expect(find.text('Nombre de jours CONSEILLE : 16 jours'), findsOneWidget);
      expect(find.text('Repartition des 3 journees de marche'), findsOneWidget);
      expect(
        find.textContaining('journee 1 sur 3'),
        findsOneWidget,
        reason: 'la pire journee du decor est la premiere, 1 453 m',
      );
      // LA MOYENNE N'EST PLUS AFFICHEE NULLE PART : elle noyait la journee qui
      // decide. 953 m par jour etait le chiffre de la 846 sur ce decor.
      expect(
        find.textContaining('de montee par jour', skipOffstage: false),
        findsNothing,
      );
    });

    testWidgets(
      'AVEC DES NUITS RELEVEES, CE SONT ELLES QUI FONT LES JOURNEES',
      (tester) async {
        // LE CHEMIN NEUF DE LA TACHE 848. Les trois etapes de decor restent
        // chargees ; ce sont pourtant les nuits qui decident, parce qu'elles
        // coupent plus fin et sur des lieux RELEVES. Deux segments ici, donc
        // deux journees, et la pire pese 800 m — alors que les etapes de decor
        // en donnaient 1 453. L'ecran annonce ce que la preparation posera.
        await tester.pumpWidget(
          fiche(
            trailId: 'gr20',
            overrides: [
              trailConfigProvider.overrideWithValue(TrailCatalog.byId('gr20')!),
              stagesProvider(
                'gr20',
              ).overrideWith((ref) => Future.value(etapesDeDecor)),
              paquetDAssetsProvider.overrideWithValue(
                PaquetDeTest({
                  'assets/data/gr20/fiche.json': manifesteDuGr20(),
                }),
              ),
              decoupageDuSentierProvider('gr20').overrideWithValue(deuxNuits()),
            ],
          ),
        );
        await tester.pumpAndSettle();
        await amener(tester, blocDeDifficulte());

        expect(
          find.text('Repartition des 2 journees de marche'),
          findsOneWidget,
        );
        expect(find.textContaining('800 m de montee'), findsOneWidget);
        expect(find.textContaining('journee 2 sur 2'), findsOneWidget);
        expect(
          find.text(NiveauDeDifficulte.difficile.libelle),
          findsOneWidget,
          reason: '800 m de montee dans la journee : difficile (700 a 1 000)',
        );
      },
    );
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
            decoupageDuSentierProvider(
              'test-trail',
            ).overrideWithValue(DecoupageDeNuits.aucun),
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
            decoupageDuSentierProvider(
              'test-trail',
            ).overrideWithValue(DecoupageDeNuits.aucun),
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
      // PLUS RIEN NE MANQUE A CE SENTIER (tache 848), ET C'EST LE CHANGEMENT.
      // Sous la regle de la 846, le sentier de test n'avait pas d'altitude
      // mesuree : un critere disparaissait et la fiche le DISAIT, deux fois —
      // la ligne du manque, et la regle qui nommait les trois mesures.
      // Christophe a sorti l'altitude du calcul le 17/10 : la difficulte ne
      // demande plus que le DENIVELE des journees, que ce sentier fournit.
      // Il n'y a donc plus rien a declarer manquant, et aucune ligne de manque
      // ne s'affiche — meme discipline, a l'etat neuf : on ne nomme un manque
      // que s'il y en a un.
      expect(
        find.textContaining('l\'altitude', skipOffstage: false),
        findsNothing,
      );
      expect(
        find.textContaining('Non mesure sur ce sentier', skipOffstage: false),
        findsNothing,
      );
      // ET LA DIFFICULTE EST BIEN LA, deduite des seules etapes : la pire
      // journee du decor pese 1 453 m, donc TRES DIFFICILE.
      expect(find.byKey(const ValueKey('jauge-du-verdict')), findsOneWidget);
      expect(
        find.text(NiveauDeDifficulte.tresDifficile.libelle),
        findsOneWidget,
      );
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
            decoupageDuSentierProvider(
              'test-trail',
            ).overrideWithValue(DecoupageDeNuits.aucun),
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
            decoupageDuSentierProvider(
              'test-trail',
            ).overrideWithValue(DecoupageDeNuits.aucun),
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

  group('853 — LA FICHE D UN CHAPITRE, QUI EST LE PRODUIT EN VENTE', () {
    // CE GROUPE SERT LES VRAIS FICHIERS LIVRES, pas un manifeste de decor, et
    // c'est voulu : le trou que la 853 ferme n'etait pas un trou de widget —
    // les quatre widgets de la fiche marchaient deja — mais un trou de
    // CABLAGE. Les deux chapitres du GR20 sont les seuls produits en vente
    // depuis la 841, et aucun des deux ne declarait de fiche : le lecteur
    // rendait `null`, et leur page n'avait ni texte ni photo. Un decor
    // prouverait que le widget sait afficher ; seul le fichier reel prouve que
    // le PRODUIT affiche.
    Future<void> poserLeChapitre(WidgetTester tester, String id) async {
      final config = TrailCatalog.byId(id)!;
      final chemin = config.ficheAssetPath!;
      await tester.pumpWidget(
        fiche(
          trailId: id,
          overrides: [
            trailConfigProvider.overrideWithValue(config),
            stagesProvider(
              id,
            ).overrideWith((ref) => Future.value(const <StageModel>[])),
            paquetDAssetsProvider.overrideWithValue(
              PaquetDeTest({chemin: File(chemin).readAsStringSync()}),
            ),
            decoupageDuSentierProvider(
              id,
            ).overrideWithValue(DecoupageDeNuits.aucun),
          ],
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('LE NORD MONTRE SES PHOTOS ET SON TEXTE', (tester) async {
      await poserLeChapitre(tester, 'gr20-nord');

      expect(find.byType(BandeDePhotos), findsOneWidget);
      expect(find.byKey(const ValueKey('bande-de-photos')), findsOneWidget);
      expect(find.byType(DescriptionDuSentier), findsOneWidget);
      expect(find.text('Ou c\'est'), findsOneWidget);
      expect(
        find.text('A quoi s\'attendre', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('LE SUD AUSSI, ET AVEC SA PROPRE COUVERTURE', (tester) async {
      await poserLeChapitre(tester, 'gr20-sud');

      expect(find.byKey(const ValueKey('bande-de-photos')), findsOneWidget);
      expect(find.byType(DescriptionDuSentier), findsOneWidget);
      // LA MENTION DE LA COUVERTURE DU SUD EST A L'ECRAN — celle du col de
      // Bavella, pas celle du lac de Capitello qui est dans le NORD. C'est le
      // defaut le plus visible que ce lot corrige : faute de fiche propre, le
      // sud se vendait avec une photo de l'autre moitie.
      final sud = lireFicheDeSentier(
        File(TrailCatalog.byId('gr20-sud')!.ficheAssetPath!).readAsStringSync(),
        'gr20-sud',
      )!;
      expect(sud.couverture!.fichier, contains('col-de-bavella'));
      expect(
        find.text(sud.couverture!.mention, skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('LES CREDITS DU CHAPITRE SONT A L ECRAN, EN DEFILANT LA '
        'BANDE', (tester) async {
      // LA CONDITION DE LICENCE, VERIFIEE A L'ECRAN ET PAS DANS UN JSON. Une
      // CC-BY respectee dans un fichier et nulle part ailleurs n'est pas
      // respectee, et l'application est PAYANTE.
      //
      // ON DEFILE LA BANDE, PARCE QU'ELLE CONSTRUIT A LA DEMANDE. La bande est
      // une liste horizontale : ses enfants hors champ ne sont pas construits,
      // donc `skipOffstage: false` ne les trouve pas — ils n'existent pas
      // encore. On fait donc ce que le randonneur fait, on fait glisser la
      // bande, et on releve les credits au passage. C'est plus fidele qu'un
      // test de donnees, qui prouverait seulement que la mention est ECRITE
      // (c'est le role de `fiches_des_chapitres_853_test`) : ici on prouve
      // qu'elle se VOIT.
      await poserLeChapitre(tester, 'gr20-nord');
      final nord = lireFicheDeSentier(
        File(
          TrailCatalog.byId('gr20-nord')!.ficheAssetPath!,
        ).readAsStringSync(),
        'gr20-nord',
      )!;
      expect(nord.photos.length, 6);

      final vus = <String>{};
      final bande = find.byKey(const ValueKey('bande-de-photos'));
      for (var glissement = 0; glissement < 12; glissement++) {
        for (final photo in nord.photos) {
          if (find.text(photo.mention).evaluate().isNotEmpty) {
            vus.add(photo.mention);
          }
        }
        if (vus.length == nord.photos.length) break;
        await tester.drag(bande, const Offset(-300, 0));
        await tester.pumpAndSettle();
      }

      for (final photo in nord.photos) {
        expect(
          vus,
          contains(photo.mention),
          reason: '${photo.fichier} : son credit ne se voit jamais',
        );
      }
    });
  });
}
