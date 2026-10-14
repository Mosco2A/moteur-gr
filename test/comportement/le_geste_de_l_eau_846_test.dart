import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/branding/stepways_icons.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/data/daos/checklist_dao.dart';
import 'package:moteur_gr/core/data/daos/pois_dao.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/stage_detector.dart';
import 'package:moteur_gr/core/models/poi.dart';
import 'package:moteur_gr/core/models/water_action.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/theme/couleurs_semantiques.dart';
import 'package:moteur_gr/features/checklist/data/ce_que_ce_sentier_exige.dart';
import 'package:moteur_gr/features/checklist/data/checklist_template.dart';
import 'package:moteur_gr/features/checklist/data/les_lignes_manquantes.dart';
import 'package:moteur_gr/features/checklist/providers/checklist_provider.dart';
import 'package:moteur_gr/features/map/providers/supply_alert_provider.dart';
import 'package:moteur_gr/features/map/providers/track_position_provider.dart';
import 'package:moteur_gr/features/planning/domain/shop_catalog.dart';
import 'package:moteur_gr/features/planning/providers/shop_providers.dart';
import 'package:moteur_gr/features/trail/providers/pois_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/features/trek/presentation/map/libelle_de_l_alerte.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/poi/poi_type_config.dart';

import 'le_trou_reel_du_mare_a_mare_834_test.dart'
    show dossierDonnees, etapesReelles, poisReels, trailId;

/// TACHE 846 — L'EAU NE SE DIT PLUS POTABLE OU NON, ELLE SE DIT PAR LE GESTE.
///
/// « Potabilite ca veut dire filtration » (Christophe, 14/10). Ce test ne
/// fabrique AUCUN point d'eau : il lit `assets/data/mare_a_mare_centre/
/// pois.json`, c'est-a-dire exactement ce que le telephone du randonneur
/// embarque, et verrouille le geste porte par chacun de ses cinq points d'eau.
///
/// CE QU'IL FERME, ET C'ETAIT UN MENSONGE PAR LE DESSIN. Les sources thermales
/// de Guitera — eau chaude sulfureuse, baignade — portaient le type `water`,
/// donc la goutte bleue de la fontaine et le libelle « Point d'eau ». La carte
/// invitait a boire une eau qui ne se boit pas, et l'alerte comptait son etape
/// comme servie.
void main() {
  final etapes = etapesReelles();
  final pois = poisReels();
  final catalogue = ShopCatalog.forTrail(trailId)!;
  final eau = pois.where((p) => p.type == 'water').toList();

  PoiModel point(String id) =>
      eau.firstWhere((p) => p.name == _nomsParIdentifiant[id]);

  TrackPositionState surEtape(int stageNumber) => TrackPositionState(
    userLat: 41.9,
    userLng: 9.1,
    projectedLat: 41.9,
    projectedLng: 9.1,
    distanceToTrackM: 4,
    distanceFromStartM: 20000,
    distanceRemainingM: 60000,
    trackIndex: 120,
    stageDetection: (
      stageNumber: stageNumber,
      event: StageDetectionEventValues.between,
    ),
    isOffTrack: false,
  );

  Future<SupplyGapAlert?> alerteSurEtape(int stageNumber) async {
    final container = ProviderContainer(
      overrides: [
        trailIdProvider.overrideWithValue(trailId),
        trailShopsProvider(trailId).overrideWithValue(catalogue),
        trackPositionProvider.overrideWithValue(
          AsyncData(surEtape(stageNumber)),
        ),
        stagesProvider(trailId).overrideWith((ref) async => etapes),
        poisProvider(trailId).overrideWith((ref) async => pois),
      ],
    );
    addTearDown(container.dispose);
    await container.read(stagesProvider(trailId).future);
    await container.read(poisProvider(trailId).future);
    return container.read(supplyGapAlertProvider);
  }

  group('LE GESTE PORTE PAR CHACUN DES CINQ POINTS D EAU', () {
    test('la donnee declare TROIS gestes et en TAIT un, exprès', () {
      // LE TABLEAU COMPLET, verrouille sur la donnee embarquee. La colonne de
      // droite est la PREUVE OSM qui a decide du geste, recopiee du champ
      // `source` de chaque point.
      //
      //  etape  point                       geste            preuve OSM
      //  -----  --------------------------  ---------------  ----------------
      //    1    Fontaine de Serra-di-F.     boire tel quel   fountain +
      //                                                      drinking_water=yes
      //    3    Sources thermales de Gui.   NE PAS BOIRE     natural=spring,
      //                                                      sulfureuse
      //    3    Funtana di Croce            (rien de declare) fountain SANS
      //                                                      drinking_water
      //    4    Fontaine de Guitera         boire tel quel   amenity=
      //                                                      drinking_water
      //    6    Fontaine Saint-Georges      boire tel quel   fountain +
      //                                                      drinking_water=yes
      expect(eau.length, 5);

      expect(
        point('poi-02').declaredWaterAction,
        WaterAction.drinkAsIs,
        reason: 'OSM pose drinking_water=yes sur cette fontaine',
      );
      expect(point('poi-11').declaredWaterAction, WaterAction.drinkAsIs);
      expect(point('poi-18').declaredWaterAction, WaterAction.drinkAsIs);

      expect(
        point('poi-08').declaredWaterAction,
        WaterAction.doNotDrink,
        reason: 'LE CAS DU BRIEF : la source thermale de Guitera-les-Bains',
      );

      // LA FUNTANA DI CROCE NE DECLARE RIEN, ET CE SILENCE EST UN RELEVE.
      // OSM la connait en `amenity=fountain` SANS `drinking_water` — la ou les
      // deux autres fontaines du sentier portent `drinking_water=yes`. OSM ne
      // dit donc pas qu'elle est potable, et nous ne l'inventons pas.
      expect(point('poi-10').declaredWaterAction, isNull);
    });

    test('la donnee muette devient A FILTRER, et le dit', () {
      final funtana = point('poi-10');

      // Le geste a montrer : filtrer.
      expect(funtana.waterAction, WaterAction.filter);
      expect(funtana.waterAction, WaterAction.parPrudence);

      // ET C'EST UNE PRECAUTION, PAS UN RELEVE. C'est toute la difference que
      // ce champ nullable sert a garder : l'application ne fait pas passer son
      // ignorance pour une mesure.
      expect(funtana.waterActionIsPrecaution, isTrue);

      // Les quatre autres sont des releves : rien a nuancer.
      for (final id in ['poi-02', 'poi-08', 'poi-11', 'poi-18']) {
        expect(
          point(id).waterActionIsPrecaution,
          isFalse,
          reason: '$id porte un geste declare',
        );
      }
    });

    test('la fiche du point ecrit la precaution, et seulement la', () {
      // Les mots exacts, en francais, de la ligne qui s'ajoute sous le geste.
      expect(
        t.poi.waterAction.precaution,
        'Par précaution : la donnée ne dit rien de cette eau. '
        'Ce n\'est pas un relevé.',
      );
      expect(t.poi.waterAction.filter, 'À filtrer avant de boire');
      expect(t.poi.waterAction.doNotDrink, 'Ne pas boire');
      expect(t.poi.waterAction.drinkAsIs, 'Eau potable : à boire telle quelle');
    });

    test('la fiche de la Funtana di Croce ne promet plus « potable »', () {
      // LA DESCRIPTION DISAIT LE CONTRAIRE DU GESTE. Elle annoncait
      // « Source d'eau potable le long du sentier » pendant qu'OSM ne le dit
      // pas : l'affirmation venait de nous, pas du releve. Elle est retiree —
      // un point a filtrer dont la fiche promet une eau potable est pire que
      // les deux pris separement.
      final brut = File('$dossierDonnees/pois.json').readAsStringSync();
      final tous = jsonDecode(brut) as List<dynamic>;
      final funtana =
          tous.firstWhere(
                (p) => (p as Map<String, dynamic>)['id'] == 'mam-c-poi-10',
              )
              as Map<String, dynamic>;
      expect(funtana['descriptionFr'], isNot(contains('potable')));
      expect(funtana['descriptionEn'], isNot(contains('Drinking')));
      // Le reste de la fiche est intact : le debit regulier est un releve.
      expect(funtana['descriptionFr'], contains('Débit régulier'));
    });
  });

  group('CE QUI COMPTE COMME DE L EAU, ET CE QUI NE COMPTE PLUS', () {
    test('un point NE PAS BOIRE ne compte jamais, meme avec un filtre', () {
      expect(WaterAction.doNotDrink.donneDeLEau, isFalse);
      expect(WaterAction.doNotDrink.exigeUnFiltre, isFalse);

      // Les trois autres donnent de l'eau : avec le bon geste, elle se boit.
      expect(WaterAction.drinkAsIs.donneDeLEau, isTrue);
      expect(WaterAction.filter.donneDeLEau, isTrue);
      expect(WaterAction.treatOrBoil.donneDeLEau, isTrue);
    });

    test('une etape s annonce a son MEILLEUR point', () {
      // L'etape 3 porte les deux : la source thermale et la Funtana di Croce.
      final etape3 = eau
          .where((p) => p.stageNumber == 3)
          .map((p) => p.waterAction)
          .toList();
      expect(etape3.length, 2);
      expect(WaterAction.meilleur(etape3), WaterAction.filter);

      // Une fontaine l'emporte sur un ruisseau : rien a faire bat un geste.
      expect(
        WaterAction.meilleur([WaterAction.filter, WaterAction.drinkAsIs]),
        WaterAction.drinkAsIs,
      );

      // Une etape qui ne porte QUE de l'eau imbuvable ne porte pas d'eau.
      expect(WaterAction.meilleur([WaterAction.doNotDrink]), isNull);
      expect(WaterAction.meilleur(const []), isNull);
    });

    test('LES QUATRE ETAPES SERVIES NE CHANGENT PAS, et voici pourquoi', () {
      // LE RESULTAT DE 834 TIENT — 1, 3, 4 et 6 — mais plus pour la meme
      // raison. L'etape 3 n'est plus servie par la source thermale : elle
      // l'est par la Funtana di Croce, a filtrer. Si cette derniere
      // n'existait pas, l'etape 3 sortirait de la liste et le trou de l'etape
      // 1 passerait de deux a quatre etapes.
      final servies =
          eau
              .where((p) => p.waterAction.donneDeLEau)
              .map((p) => p.stageNumber)
              .toSet()
              .toList()
            ..sort();
      expect(servies, [1, 3, 4, 6]);

      // Sans la Funtana di Croce, l'etape 3 ne serait plus servie.
      final sansFuntana =
          eau
              .where(
                (p) =>
                    p.waterAction.donneDeLEau && p.name != 'Funtana di Croce',
              )
              .map((p) => p.stageNumber)
              .toSet()
              .toList()
            ..sort();
      expect(sansFuntana, [1, 4, 6]);
    });
  });

  group('CE QUE L ALERTE D EAU DIT MAINTENANT, MOT POUR MOT', () {
    test('apres Ghisonaccia : le point filtrable compte ET SE DIT', () async {
      final alerte = await alerteSurEtape(1);
      expect(alerte, isNotNull);
      expect(alerte!.kind, SupplyGapKind.water);

      // L'ARITHMETIQUE DE 834 EST INTACTE : deux etapes, 28,6 km.
      expect(alerte.gap, 2);
      expect(alerte.km, closeTo(28.6, 0.001));

      // ET LE GESTE EST PORTE JUSQU'AU BANDEAU : l'eau retrouvee a l'etape 3
      // se filtre.
      expect(alerte.waterAction, WaterAction.filter);

      // LE GESTE EST DANS LE TITRE, et c'est une mesure qui l'a decide : en
      // fin de corps de texte il coutait 32 points de hauteur a 320 points de
      // large, soit deux lignes, et le bandeau est au-dessus du SOS. Dans le
      // titre il coute zero — « a filtrer » remplace « limites ».
      expect(titreDeLAlerte(alerte), 'Eau à filtrer');
      expect(
        texteDeLAlerte(alerte),
        'Dernier point d\'eau avant 2 étapes et 28,6 km. Fais le plein !',
      );
    });

    test('apres Quasquara : une fontaine attend, et elle se tait', () async {
      final alerte = await alerteSurEtape(4);
      expect(alerte, isNotNull);
      expect(alerte!.kind, SupplyGapKind.water);
      expect(alerte.gap, 2);
      expect(alerte.km, closeTo(18.0, 0.001));

      // L'eau de l'etape 6 est la Fontaine Saint-Georges : rien a faire, donc
      // rien a dire. LE SILENCE EST L'INFORMATION JUSTE, et le titre reste
      // celui d'avant la tache 846.
      expect(alerte.waterAction, WaterAction.drinkAsIs);
      expect(titreDeLAlerte(alerte), 'Points d\'eau limités');
      expect(
        texteDeLAlerte(alerte),
        'Dernier point d\'eau avant 2 étapes et 18,0 km. Fais le plein !',
      );
    });

    test('l alerte de VIVRES ne parle jamais du geste de l eau', () async {
      final alerte = await alerteSurEtape(2);
      expect(alerte!.kind, SupplyGapKind.food);
      expect(alerte.waterAction, isNull);
      expect(titreDeLAlerte(alerte), 'Points de ravitaillement limités');
      expect(
        texteDeLAlerte(alerte),
        'Dernier ravitaillement avant 5 étapes et 52,5 km. '
        'Prévois tes réserves !',
      );
    });

    test('les deux titres de geste existent dans les CINQ langues', () {
      for (final langue in AppLocale.values) {
        LocaleSettings.setLocale(langue);
        for (final titre in [
          t.map.waterGapTitleFilter,
          t.map.waterGapTitleTreat,
        ]) {
          expect(
            titre.trim(),
            isNotEmpty,
            reason: 'titre de geste vide en ${langue.languageCode}',
          );
          // Il doit se DISTINGUER du titre d'avant, sinon le geste ne se dit
          // pas dans cette langue.
          expect(
            titre,
            isNot(t.map.waterGapTitle),
            reason:
                'titre de geste identique a l ancien en '
                '${langue.languageCode}',
          );
        }
      }
      LocaleSettings.setLocale(AppLocale.fr);
    });
  });

  group('LA CARTE : TROIS DESSINS POUR QUATRE GESTES', () {
    test('une fontaine garde EXACTEMENT ce qu elle avait', () {
      final fontaine = PoiTypeConfig.getStyle(
        'water',
        waterAction: WaterAction.drinkAsIs,
      );
      final avant = PoiTypeConfig.getStyle('water');
      expect(fontaine.icon, avant.icon);
      expect(fontaine.color, avant.color);
      expect(fontaine.icon, StepwaysIcons.pointEau);
    });

    test('a filtrer et ne pas boire se voient DIFFEREMMENT', () {
      final fontaine = PoiTypeConfig.getStyle('water');
      final aFiltrer = PoiTypeConfig.getStyle(
        'water',
        waterAction: WaterAction.filter,
      );
      final interdit = PoiTypeConfig.getStyle(
        'water',
        waterAction: WaterAction.doNotDrink,
      );

      // Trois dessins distincts, et trois couleurs distinctes : on arrive
      // assoiffe, on ne lit pas les etiquettes.
      final icones = {fontaine.icon, aFiltrer.icon, interdit.icon};
      expect(icones.length, 3);
      final couleurs = {fontaine.color, aFiltrer.color, interdit.color};
      expect(couleurs.length, 3);

      expect(aFiltrer.icon, StepwaysIcons.pointEauAFiltrer);
      expect(aFiltrer.color, CouleursSemantiques.pointEauAFiltrer);
      expect(interdit.icon, StepwaysIcons.pointEauInterdit);
      expect(interdit.color, CouleursSemantiques.pointEauNonPotable);
    });

    test('les deux traces neufs sont sur la grille de la famille', () {
      for (final chemin in [
        StepwaysIcons.pointEauAFiltrer,
        StepwaysIcons.pointEauInterdit,
      ]) {
        final svg = File(chemin).readAsStringSync();
        expect(svg, contains('viewBox="0 0 24 24"'), reason: chemin);
        expect(svg, contains('stroke-width="2"'), reason: chemin);
        expect(svg, contains('stroke="currentColor"'), reason: chemin);
        expect(svg, contains('stroke-linecap="round"'), reason: chemin);
        // LA MEME GOUTTE, A LA COURBE PRES, que `point-eau.svg` : c'est de
        // l'eau, et ca doit se reconnaitre de loin.
        expect(
          svg,
          contains('M12 3s6 6.5 6 11a6 6 0 0 1-12 0c0-4.5 6-11 6-11z'),
          reason: '$chemin a perdu la goutte',
        );
      }
    });

    test('le geste n a aucun effet hors d un point d eau', () {
      // Un refuge ne se filtre pas : le registre ignore le geste, et
      // l'appelant n'a donc pas a se demander si le type s'y prete.
      expect(
        PoiTypeConfig.getStyle('refuge', waterAction: WaterAction.filter).icon,
        PoiTypeConfig.getStyle('refuge').icon,
      );
    });
  });

  group('LE SAC : LE FILTRE ENTRE TOUT SEUL', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          trailConfigProvider.overrideWithValue(testTrailConfig),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    Future<void> pret() =>
        Future<void>.delayed(const Duration(milliseconds: 300));

    /// Pose en base un unique point d'eau, avec le geste voulu.
    Future<void> poserUnPointDEau(String? geste) async {
      await PoisDao(db).insertAll([
        PoisCompanion(
          trailId: Value(testTrailConfig.id),
          stageNumber: const Value(1),
          name: const Value('Le point du test'),
          type: const Value('water'),
          lat: const Value(41.9),
          lng: const Value(9.1),
          waterAction: Value(geste),
        ),
      ]);
    }

    test('la regle elle-meme : UN SEUL point filtrable suffit', () {
      PoiModel point(WaterAction? geste) => PoiModel(
        trailId: 'x',
        stageNumber: 1,
        name: 'p',
        type: 'water',
        lat: 0,
        lng: 0,
        declaredWaterAction: geste,
      );

      // Un sentier de fontaines n'impose rien.
      expect(
        articlesExigesParLeSentier([point(WaterAction.drinkAsIs)]),
        isEmpty,
      );
      // Une eau imbuvable n'impose pas un filtre : il n'y repondrait pas.
      expect(
        articlesExigesParLeSentier([point(WaterAction.doNotDrink)]),
        isEmpty,
      );
      // UN SEUL point a filtrer suffit, declare...
      expect(articlesExigesParLeSentier([point(WaterAction.filter)]), [
        filtreAEau,
      ]);
      // ...ou MUET, par la meme prudence qui l'ecrit sur la carte.
      expect(articlesExigesParLeSentier([point(null)]), [filtreAEau]);
      // Un refuge, lui, ne declenche rien, quoi que porte son geste.
      expect(
        articlesExigesParLeSentier(const [
          PoiModel(
            trailId: 'x',
            stageNumber: 1,
            name: 'r',
            type: 'refuge',
            lat: 0,
            lng: 0,
          ),
        ]),
        isEmpty,
      );
    });

    test('SANS point filtrable, le sac reste a 84 articles', () async {
      await poserUnPointDEau(WaterAction.drinkAsIs.versDonnee);
      container.read(checklistProvider);
      await pret();

      final etat = container.read(checklistProvider);
      expect(etat.items.length, 84);
      expect(etat.items.any((i) => i.template.id == 'waterFilter'), isFalse);
    });

    test(
      'AVEC un point filtrable, le filtre est LA, OBLIGATOIRE, et il PESE',
      () async {
        await poserUnPointDEau(WaterAction.filter.versDonnee);
        container.read(checklistProvider);
        await pret();

        final etat = container.read(checklistProvider);

        // 85 : les 84 de la parite GR20, plus celui que CE sentier demande.
        expect(etat.items.length, 85);

        final filtre = etat.items.firstWhere(
          (i) => i.template.id == 'waterFilter',
        );

        // OBLIGATOIRE — le meme mecanisme que les quatre autres obligatoires
        // du sac : c'est de la que viennent le badge rouge, le garde-fou qui
        // empeche de decocher, et le refus de « SAC OK ».
        expect(filtre.template.requirement, ChecklistRequirement.required);
        expect(filtre.template.isEssential, isTrue);

        // IL PESE, et son poids est celui du template.
        expect(filtre.weightGrams, 65);
        expect(filtre.totalWeightGrams, 65);

        // LE MARCHEUR N'A RIEN EU A FAIRE : il n'est pas coche, donc il
        // compte dans ce qui manque, et le sac ne se valide pas sans lui.
        expect(filtre.isChecked, isFalse);
        expect(filtre.isCustom, isFalse, reason: 'ce n est pas une suggestion');
        expect(etat.allRequiredChecked, isFalse);
      },
    );

    test('LA DONNEE MUETTE POSE LE FILTRE AUSSI', () async {
      // Le cas de la Funtana di Croce : rien de declare, donc a filtrer par
      // precaution, donc un filtre au sac. La regle ne vit qu'a un endroit.
      await poserUnPointDEau(null);
      container.read(checklistProvider);
      await pret();
      expect(
        container
            .read(checklistProvider)
            .items
            .any((i) => i.template.id == 'waterFilter'),
        isTrue,
      );
    });

    test('la coche du filtre ARRIVE EN BASE, pas qu a l ecran', () async {
      // LE PIEGE QUE CE LOT A TROUVE : `ChecklistDao.toggleItem` est un UPDATE
      // SEC, et les lignes n'etaient posees que sur un sac VIDE. Un article
      // neuf du template n'avait donc pas de ligne chez un marcheur ayant deja
      // ouvert son sac : sa coche basculait a l'ecran et n'allait pas plus
      // loin. Sur un article OBLIGATOIRE, « SAC OK » restait refuse a chaque
      // redemarrage sans que rien l'explique.
      await poserUnPointDEau(WaterAction.filter.versDonnee);
      container.read(checklistProvider);
      await pret();

      await container.read(checklistProvider.notifier).toggle('waterFilter');
      await pret();

      final lignes = await ChecklistDao(db).getByTrailId(testTrailConfig.id);
      final ligne = lignes.firstWhere((l) => l.itemId == 'waterFilter');
      expect(
        ligne.isChecked,
        isTrue,
        reason: 'la coche n a pas atteint la base',
      );
      expect(ligne.weightGrams, 65);
    });

    test('quelles lignes manquent : la decision, seule et nue', () {
      const a = ChecklistTemplateItem(id: 'a', category: 'c', nameKey: 'a');
      const b = ChecklistTemplateItem(id: 'b', category: 'c', nameKey: 'b');

      // SUR UN SAC VIDE, TOUT MANQUE — c'est l'ancien premier remplissage,
      // mot pour mot.
      expect(lignesManquantes(const [], const [a, b]), [a, b]);

      // Le sac deja rempli ne reclame rien.
      expect(lignesManquantes([_ligne('a'), _ligne('b')], const [a, b]), []);

      // ET LE CAS QUI COMPTE : un article neuf du template, chez un marcheur
      // qui a deja ouvert son sac. C'est la situation ou sa coche n'arrivait
      // pas en base.
      expect(lignesManquantes([_ligne('a')], const [a, b]), [b]);

      // Une ligne en base qui n'est plus au template (article personnalise)
      // ne fait rien reclamer.
      expect(lignesManquantes([_ligne('a'), _ligne('zzz')], const [a]), []);
    });

    test('le filtre porte un nom dans les CINQ langues', () {
      for (final langue in AppLocale.values) {
        LocaleSettings.setLocale(langue);
        final libelle = t['checklist.items.${filtreAEau.nameKey}'];
        expect(
          libelle,
          isA<String>(),
          reason: 'pas de nom en ${langue.languageCode}',
        );
        expect((libelle as String).trim(), isNotEmpty);
        // Le repli de slang rend la CLE quand la traduction manque : un nom
        // egal a sa cle serait un trou, pas une traduction.
        expect(libelle, isNot('waterFilter'));
      }
      LocaleSettings.setLocale(AppLocale.fr);
      expect(t['checklist.items.waterFilter'], 'Filtre à eau');
    });
  });
}

/// Une ligne de sac en base, reduite a ce que [lignesManquantes] regarde.
ChecklistItem _ligne(String itemId) => ChecklistItem(
  id: 0,
  trailId: 'test-trail',
  itemId: itemId,
  category: 'c',
  isChecked: false,
  weightGrams: 0,
  quantity: 1,
  isCustom: false,
  inShoppingList: false,
);

/// Les cinq points d'eau du sentier, par leur identifiant de donnee.
///
/// Le test parle en identifiants (`poi-08`) parce que c'est ce que porte
/// `pois.json`, mais le modele ne garde que le nom : cette table fait le pont,
/// a UN endroit, plutot qu'en recopiant des noms corses dans dix `expect`.
const _nomsParIdentifiant = <String, String>{
  'poi-02': 'Fontaine de Serra-di-Fiumorbo',
  'poi-08': 'Sources thermales de Guitera',
  'poi-10': 'Funtana di Croce',
  'poi-11': 'Fontaine de Guitera',
  'poi-18': 'Fontaine Saint-Georges',
};
