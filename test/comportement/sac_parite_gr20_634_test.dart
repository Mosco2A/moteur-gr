import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/checklist/data/checklist_template.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// TACHE 634 — RETOUR 9 DE CHRISTOPHE (DEM-260929-1328).
///
/// Verbatim : « Dans sac tu reprends TOUS les item de GR20 ».
///
/// CE QUI A ETE MESURE. La liste du GR20 vit EN DUR dans un ecran de l'autre
/// application (`features/planning/presentation/gear_checklist_screen.dart`,
/// fonction `_defaultGr20Gear()`). Elle porte QUATRE-VINGT-QUATRE articles.
/// Cote StepWays, `defaultChecklistTemplate` en porte QUATRE-VINGT-QUATRE
/// aussi, dans le MEME ORDRE, avec les MEMES poids et les MEMES quantites —
/// verifie article par article, ecart mesure : ZERO.
///
/// LA DEMANDE EST DONC DEJA TENUE, ET C'EST POUR CA QUE CE FICHIER EXISTE.
/// Aucun article a ajouter ne veut pas dire rien a faire : la liste du GR20
/// etait reprise sans qu'AUCUN test ne la tienne. Un article retire ou renomme
/// d'un cote serait passe inapercu, et la promesse « aucun article du GR20 ne
/// doit se perdre » n'aurait tenu qu'a la vigilance du prochain agent.
///
/// LA LISTE DE REFERENCE CI-DESSOUS EST RECOPIEE DU DEPOT GR20, et c'est
/// volontaire : un test ne doit pas dependre d'un autre depot present sur le
/// disque au moment ou il tourne (le GR20 est un depot separe, en lecture
/// seule). La reference est donc GRAVEE ici, avec son origine. Pour la mettre a
/// jour un jour, relire `_defaultGr20Gear()` et rapporter les differences.
///
/// LES TROIS LISTES DEMANDEES PAR CHRISTOPHE, AU 29/09 :
///  1. COMMUN : les 84 articles ci-dessous, tous apparies ;
///  2. MANQUANT A STEPWAYS : aucun. La liste est vide ;
///  3. EN PLUS DANS STEPWAYS : 10 articles, qui ne sont PAS dans la liste de
///     base mais dans deux couches additives — un maillot de bain propre au
///     sentier, et neuf suggestions saisonnieres (crampons legers, gants
///     chauds, sous-couche thermique en hiver ; eau supplementaire, chapeau de
///     soleil, electrolytes en ete ; guetres au printemps ; frontale d'appoint
///     en automne ; reserve d'eau renforcee sur le Mare a Mare en ete). Ils
///     s'AJOUTENT et ne remplacent rien.
void main() {
  /// LA LISTE DU GR20, GRAVEE : (identifiant GR20, libelle FR du GR20,
  /// identifiant StepWays correspondant).
  const gr20 = <(String, String, String)>[
    ('sac_sac_a_dos', 'Sac a dos 35-45L', 'backpack'),
    ('sac_housse_pluie', 'Housse de pluie sac', 'rainCover'),
    ('sac_sacs_etanches', 'Sacs etanches (dry bags)', 'dryBags'),
    ('couch_sac_couchage', 'Sac de couchage (0-5C)', 'sleepingBag'),
    ('couch_matelas', 'Matelas / tapis de sol', 'sleepingPad'),
    ('couch_drap_sac', 'Drap de sac / sac a viande', 'sleepingLiner'),
    ('couch_oreiller', 'Oreiller gonflable', 'pillow'),
    ('vet_pantalon', 'Pantalon de rando', 'hikingPants'),
    ('vet_pantalon_pluie', 'Pantalon de pluie', 'rainPants'),
    ('vet_short', 'Short', 'shorts'),
    ('vet_tshirts', 'T-shirt technique', 'techTshirt'),
    ('vet_polaire', 'Polaire / doudoune legere', 'fleece'),
    ('vet_veste_imper', 'Veste imperméable Gore-Tex', 'rainJacket'),
    ('vet_sous_vet', 'Sous-vetement', 'underwear'),
    ('vet_chaussettes', 'Chaussettes de rando', 'hikingSocks'),
    ('vet_guetres', 'Guetres', 'gaiters'),
    ('vet_chapeau', 'Chapeau / casquette', 'hat'),
    ('vet_bonnet', 'Bonnet', 'beanie'),
    ('vet_buff', 'Buff / tour de cou', 'buff'),
    ('vet_gants', 'Gants legers', 'lightGloves'),
    ('vet_chaussures', 'Chaussures de rando (portees)', 'hikingBoots'),
    ('vet_sandales', 'Sandales de bivouac', 'campSandals'),
    ('cui_rechaud', 'Rechaud (PocketRocket)', 'stove'),
    ('cui_cartouche', 'Cartouche gaz', 'gasCanister'),
    ('cui_popote', 'Popote / gamelle', 'cookpot'),
    ('cui_couverts', 'Couverts (cuillere, couteau)', 'cutlery'),
    ('cui_gourde', 'Gourde / poche a eau 2L', 'waterBottle'),
    ('cui_couteau', 'Couteau pliant', 'knife'),
    ('cui_briquet', 'Briquet', 'lighter'),
    ('nour_barres', 'Barre energetique', 'energyBars'),
    ('nour_fruits_secs', 'Fruits secs', 'driedFruits'),
    ('nour_lyophilise', 'Repas lyophilise', 'freezeDriedMeal'),
    ('nour_pastilles', 'Pastilles purification eau', 'waterPurification'),
    ('nour_electrolytes', 'Electrolytes', 'electrolytes'),
    ('nour_eau', 'Eau transportee (1L = 1000g)', 'carriedWater'),
    ('hyg_savon', 'Savon biodegradable', 'soap'),
    ('hyg_brosse_dents', 'Brosse a dents', 'toothbrush'),
    ('hyg_dentifrice', 'Dentifrice', 'toothpaste'),
    ('hyg_serviette', 'Serviette microfibre', 'microfiberTowel'),
    ('hyg_papier_toilette', 'Papier toilette', 'toiletPaper'),
    ('hyg_sacs_poubelle', 'Sac poubelle', 'trashBag'),
    ('hyg_creme_frottements', 'Crème anti-frottements', 'antiChafingCream'),
    ('hyg_boules_quies', 'Boules Quies', 'earplugs'),
    ('sec_pansements', 'Pansements assortis', 'bandages'),
    ('sec_compresses', 'Compresses steriles', 'sterileCompresses'),
    ('sec_bande', 'Bande elastique', 'elasticBandage'),
    ('sec_desinfectant', 'Desinfectant (50ml)', 'disinfectant'),
    ('sec_doliprane', 'Doliprane / Ibuprofene', 'painkillers'),
    ('sec_creme_solaire', 'Crème solaire SPF50', 'sunscreen'),
    ('sec_stick_levres', 'Stick a levres SPF30', 'lipBalm'),
    ('sec_couverture', 'Couverture de survie', 'emergencyBlanket'),
    ('sec_tire_tiques', 'Tire-tiques', 'tickRemover'),
    ('sec_sifflet', 'Sifflet de secours', 'whistle'),
    ('sec_strapping', 'Elastoplaste / strapping', 'strapping'),
    ('sec_collyre', 'Collyre', 'eyeDrops'),
    ('sec_anti_diarr', 'Anti-diarrheique', 'antiDiarrheal'),
    ('sec_antihistaminique', 'Antihistaminique', 'antihistamine'),
    ('sec_tape_genoux', 'Tape genoux', 'kneeTape'),
    ('elec_telephone', 'Téléphone', 'phone'),
    ('elec_batterie', 'Batterie externe 20000mAh', 'powerBank'),
    ('elec_cable', 'Cable USB', 'usbCable'),
    ('elec_frontale', 'Lampe frontale', 'headlamp'),
    ('elec_piles', 'Piles de rechange', 'spareBatteries'),
    ('femme_protections', 'Protections periodiques', 'periodProtection'),
    ('femme_brassiere', 'Brassiere sport', 'sportsBra'),
    ('femme_lingettes', 'Lingettes intimes', 'intimateWipes'),
    ('femme_pee_cloth', 'Pee-cloth', 'peeCloth'),
    ('homme_rasoir', 'Rasoir', 'razor'),
    ('homme_calecons', 'Calecons tech', 'techBoxers'),
    ('div_batons', 'Batons de marche (portes)', 'hikingPoles'),
    ('div_lunettes', 'Lunettes de soleil', 'sunglasses'),
    ('div_carte', 'Carte IGN / topo', 'trailMap'),
    ('div_lacets', 'Lacets de rechange', 'spareLaces'),
    ('div_fil_aiguille', 'Fil + aiguille', 'needleThread'),
    ('div_ruban', 'Ruban adhesif', 'ductTape'),
    ('div_sacs_ziploc', 'Sacs ziploc', 'ziplocBags'),
    ('div_cordelle', 'Cordelle', 'cord'),
    ('div_argent', 'Argent liquide', 'cash'),
    ('chien_gamelle', 'Gamelle pliable', 'dogBowl'),
    ('chien_laisse', 'Laisse', 'dogLeash'),
    ('chien_croquettes', 'Croquettes (ration/jour)', 'dogKibble'),
    ('chien_bottines', 'Bottines protection', 'dogBooties'),
    ('chien_carnet_vaccins', 'Carnet de vaccins', 'dogVaccineBook'),
    ('chien_sacs_dejections', 'Sacs a dejections', 'dogPoopBags'),
  ];

  /// Le modele lu a l'execution.
  ///
  /// ATTENTION, PIEGE MESURE : `assets/data/checklist_template.json` n'est PAS
  /// ce que l'ecran affiche. Le provider lit la const Dart
  /// ([defaultChecklistTemplate]) ; le JSON n'est charge par personne en
  /// production. Un article ajoute au seul JSON n'apparaitrait jamais. Les
  /// tests portent donc sur la const, et un test de miroir verifie que le JSON
  /// la suit.
  final parId = {for (final i in defaultChecklistTemplate) i.id: i};

  group('AUCUN article du GR20 ne se perd', () {
    test('les 84 articles du GR20 sont TOUS dans StepWays', () {
      final manquants = <String>[];
      for (final (idGr20, libelleGr20, idStepWays) in gr20) {
        if (!parId.containsKey(idStepWays)) {
          manquants.add('$idGr20 (« $libelleGr20 ») -> $idStepWays');
        }
      }
      expect(
        manquants,
        isEmpty,
        reason: 'articles du GR20 perdus :\n${manquants.join('\n')}',
      );
      expect(gr20.length, 84);
    });

    test('la liste de base ne contient RIEN D AUTRE que ces 84 articles', () {
      // L'inverse du test precedent : si quelqu un ajoute un article a la liste
      // de BASE, il doit le faire en connaissance de cause, et venir ici le
      // declarer. La liste de base est la liste du GR20, eprouvee sur le
      // terrain ; les ajouts propres a StepWays vivent dans les couches
      // additives.
      expect(defaultChecklistTemplate.length, 84);
      final attendus = {for (final g in gr20) g.$3};
      expect(parId.keys.toSet(), attendus);
    });

    test('chaque article porte ses CINQ libelles, et aucun n est vide', () {
      // StepWays est en cinq langues, le GR20 en une. Un article repris sans
      // ses cinq libelles afficherait sa clef technique a l'ecran.
      final trous = <String>[];
      for (final langue in AppLocale.values) {
        final traductions = langue.buildSync();
        for (final item in defaultChecklistTemplate) {
          final resolu = traductions['checklist.items.${item.nameKey}'];
          if (resolu is! String || resolu.trim().isEmpty) {
            trous.add('${langue.languageCode} : ${item.nameKey}');
          }
        }
      }
      expect(
        trous,
        isEmpty,
        reason: 'libelles manquants :\n${trous.join('\n')}',
      );
    });

    test('chaque article a une categorie connue', () {
      const categories = {
        'carrying',
        'sleeping',
        'clothing',
        'cooking',
        'foodWater',
        'hygiene',
        'firstAid',
        'electronics',
        'women',
        'men',
        'misc',
        'dog',
      };
      for (final item in defaultChecklistTemplate) {
        expect(categories, contains(item.category), reason: item.id);
      }
    });
  });

  group('les deux sources de la liste ne peuvent plus diverger', () {
    late Map<String, dynamic> modeleJson;

    setUpAll(() {
      modeleJson =
          jsonDecode(
                File('assets/data/checklist_template.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
    });

    test('le JSON est le miroir EXACT de la const que l ecran lit', () {
      final items =
          (modeleJson['defaultTemplate'] as Map<String, dynamic>)['items']
              as List;
      expect(items.length, defaultChecklistTemplate.length);
      for (var i = 0; i < items.length; i++) {
        final j = items[i] as Map<String, dynamic>;
        final c = defaultChecklistTemplate[i];
        expect(j['id'], c.id);
        expect(j['nameKey'], c.nameKey);
        expect(j['category'], c.category);
        expect(j['weightGrams'] ?? 0, c.weightGrams, reason: c.id);
        expect(j['quantity'] ?? 1, c.quantity, reason: c.id);
      }
    });

    test('la surcouche de sentier vise un identifiant de sentier REEL', () {
      // DEFAUT TROUVE EN CHEMIN (tache 634) : la clef etait ecrite avec des
      // soulignes alors que le sentier s'appelle « mare-a-mare-centre » avec
      // des tirets. Elle n'aurait jamais ete trouvee. Le fichier saisonnier,
      // lui, utilisait deja la bonne forme.
      final surcouches = modeleJson['trailOverrides'] as Map<String, dynamic>;
      for (final clef in surcouches.keys) {
        expect(
          clef,
          isNot(contains('_')),
          reason: 'un identifiant de sentier s ecrit avec des tirets : $clef',
        );
      }
      expect(surcouches.keys, contains('mare-a-mare-centre'));
    });
  });

  group('l adaptation saison-sentier n est pas ecrasee', () {
    test('la couche saisonniere est ADDITIVE : elle ne touche pas les 84', () {
      final saisonnier =
          jsonDecode(
                File('assets/data/checklist_seasonal.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      final idsDeBase = defaultChecklistTemplate.map((i) => i.id).toSet();

      final ajouts = <String>{};
      void collecter(Map<String, dynamic> parSaison) {
        for (final liste in parSaison.values) {
          for (final item in liste as List) {
            ajouts.add((item as Map<String, dynamic>)['id'] as String);
          }
        }
      }

      collecter(saisonnier['default'] as Map<String, dynamic>);
      for (final parSentier
          in (saisonnier['trails'] as Map<String, dynamic>).values) {
        collecter(parSentier as Map<String, dynamic>);
      }

      expect(ajouts, isNotEmpty);
      expect(
        ajouts.intersection(idsDeBase),
        isEmpty,
        reason: 'un article saisonnier ecrase un article de la liste du GR20',
      );
    });
  });
}
