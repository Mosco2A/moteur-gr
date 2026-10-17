// GARDE — TACHE 853 : LES DEUX PRODUITS EN VENTE ONT UNE FICHE, DES PHOTOS,
// ET UN TEXTE DONT CHAQUE CHIFFRE EST MESURE.
//
// LE TROU QUE CE FICHIER FERME. Le lot 841 a fait du chapitre l'unite de vente
// (« on achete le sentier seulement si il n y a pas de chapitres », Christophe,
// 15/10 17:45) et a retire le GR20 entier du catalogue. La fiche, elle, est
// restee sur le sentier mere. Resultat : les DEUX seuls produits reellement en
// vente n'avaient ni texte, ni bande de photos, ni meme de photo de couverture
// sur leur carte du catalogue. La garde `photos_du_produit_848_test` le nommait
// elle-meme « un TROU DE PRODUIT ouvert par la jonction des deux lots ».
//
// CE QUE CE FICHIER VERIFIE, ET QUI EST PLUS QU'UNE PRESENCE : que le texte de
// vente ne dit QUE des choses mesurees. Un chiffre de fiche qui ne sort pas de
// la trace est une promesse commerciale, et ce depot a deja paye ce genre de
// promesse — seize longueurs d'etape venues d'un topo remis a l'echelle, justes
// au total et fausses partout ailleurs (tache 839). Chaque nombre cite dans les
// deux fiches est donc RELU dans la donnee ici meme.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/gr20_nord_trail_config.dart';
import 'package:moteur_gr/core/config/gr20_sud_trail_config.dart';
import 'package:moteur_gr/core/config/trail_catalog.dart';
import 'package:moteur_gr/core/models/fiche_de_sentier.dart';
import 'package:moteur_gr/domain/difficulte_du_sentier.dart';
import 'package:moteur_gr/domain/echelle_de_difficulte.dart';
import 'package:moteur_gr/domain/nuit_possible.dart';
import 'package:moteur_gr/features/planning/domain/decoupage_sur_les_nuits.dart';

/// La fiche d'un chapitre, lue par le MEME lecteur que le produit.
FicheDeSentier ficheDe(String trailId) {
  final chemin = TrailCatalog.byId(trailId)!.ficheAssetPath!;
  final fiche = lireFicheDeSentier(File(chemin).readAsStringSync(), trailId);
  expect(fiche, isNotNull, reason: '$trailId : sa fiche doit se lire');
  return fiche!;
}

/// Le manifeste de decoupe des chapitres, mesure sur la trace.
Map<String, Map<String, dynamic>> lireLesChapitres() {
  final brut =
      jsonDecode(File('assets/data/gr20/chapitres.json').readAsStringSync())
          as Map<String, dynamic>;
  return {
    for (final c
        in (brut['chapitres'] as List<dynamic>).cast<Map<String, dynamic>>())
      c['id'] as String: c,
  };
}

/// Les nuits relevees d'un chapitre.
DecoupageDeNuits lireLesNuits(String dossier) => DecoupageDeNuits.fromJson(
  jsonDecode(
        File('assets/data/$dossier/nuits_possibles.json').readAsStringSync(),
      )
      as Map<String, dynamic>,
);

/// Le verdict d'un chapitre a une allure donnee, par le socle du produit.
NiveauDeDifficulte verdictDe(DecoupageDeNuits nuits, int jours) =>
    DifficulteDuSentier.calculer(
      jours: jours,
      journees: DecoupageSurLesNuits.repartir(nuits, jours)
          .map(
            (j) => JourneeMesuree(
              km: j.km,
              deniveleM: j.deniveleM,
              descenteM: j.descenteM,
            ),
          )
          .toList(growable: false),
    )!.verdict!;

void main() {
  group('853 — les deux chapitres ont enfin une fiche', () {
    test('CHACUN DECLARE LA SIENNE, ET LE LECTEUR L ACCEPTE', () {
      for (final id in <String>['gr20-nord', 'gr20-sud']) {
        final config = TrailCatalog.byId(id)!;
        expect(
          config.ficheAssetPath,
          'assets/data/$id/fiche.json',
          reason: '$id declare sa fiche',
        );
        expect(File(config.ficheAssetPath!).existsSync(), isTrue);
        // LE LECTEUR REFUSE UNE FICHE QUI ANNONCE UN AUTRE SENTIER : ce cas
        // prouve donc aussi que le `trailId` du fichier est le bon.
        final fiche = ficheDe(id);
        expect(fiche.trailId, id);
        expect(fiche.estVide, isFalse);
      }
    });

    test('SIX PHOTOS CHACUN, SA COUVERTURE, AUCUN REFUS', () {
      final nord = ficheDe('gr20-nord');
      final sud = ficheDe('gr20-sud');

      for (final fiche in <FicheDeSentier>[nord, sud]) {
        expect(fiche.photos.length, 6);
        expect(fiche.photosRefusees, isEmpty);
        expect(fiche.couverture, isNotNull);
        expect(fiche.couverture!.couverture, isTrue);
      }

      // LA COUVERTURE DE CHACUN EST CELLE DE SON CHAPITRE, et c'est le defaut
      // le plus visible qui est corrige : faute de fiche, la carte du sud
      // s'ouvrait sur la couverture du sentier mere, c'est-a-dire sur le lac de
      // Capitello — qui est dans le NORD.
      expect(
        nord.couverture!.fichier,
        endsWith('couverture-lac-de-capitello.jpg'),
      );
      expect(
        sud.couverture!.fichier,
        endsWith('couverture-col-de-bavella.jpg'),
      );
    });

    test('LES IMAGES NE SONT PAS DUPLIQUEES DANS LE BINAIRE', () {
      // LA DECISION DE CE LOT, FIGEE. Les douze fichiers restent dans le
      // dossier du sentier mere avec leur preuve UNIQUE ; les fiches des
      // chapitres les declarent par leur vrai chemin. Si quelqu'un recopie un
      // jour six images par chapitre, ce cas rougit — et il faudra alors tenir
      // deux PROVENANCE.json pour les memes images.
      for (final id in <String>['gr20-nord', 'gr20-sud']) {
        for (final photo in ficheDe(id).photos) {
          expect(
            photo.fichier,
            startsWith('assets/data/gr20/photos/'),
            reason: '$id : ses images vivent dans le dossier du sentier mere',
          );
          expect(File(photo.fichier).existsSync(), isTrue);
        }
      }
    });

    test('LA MENTION DE LICENCE CITE SON AUTEUR, PHOTO PAR PHOTO', () {
      // UNE CC-BY RESPECTEE DANS UN JSON ET NULLE PART AILLEURS N'EST PAS
      // RESPECTEE. L'application est PAYANTE : c'est un risque juridique avant
      // d'etre un risque d'affichage.
      for (final id in <String>['gr20-nord', 'gr20-sud']) {
        for (final photo in ficheDe(id).photos) {
          expect(photo.estPubliable, isTrue, reason: photo.fichier);
          expect(LicencesCommerciales.autorise(photo.licence), isTrue);
          expect(photo.mention, contains(photo.auteur));
        }
      }
    });
  });

  group('853 — le texte de vente ne dit que des choses mesurees', () {
    test('LES TROIS QUESTIONS SONT REPONDUES, ET LE SCHEMA EST LE BON', () {
      for (final id in <String>['gr20-nord', 'gr20-sud']) {
        final brut =
            jsonDecode(
                  File(
                    TrailCatalog.byId(id)!.ficheAssetPath!,
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(brut['schema'], 1);
        // L'ATTRIBUTION DE LA TRACE EST OBLIGATOIRE : la trace vient
        // d'OpenStreetMap sous licence ODbL, et la citer est une condition de
        // la licence, pas une politesse.
        expect(brut['attribution'] as String, contains('OpenStreetMap'));
        expect(brut['attribution'] as String, contains('ODbL'));

        final fiche = ficheDe(id);
        expect(fiche.description.ouCest, isNotEmpty);
        expect(fiche.description.ceQuOnYVoit, isNotEmpty);
        expect(fiche.description.aQuoiSAttendre, isNotEmpty);
      }
    });

    test('LES CHIFFRES DU TEXTE SONT CEUX DE LA DONNEE', () {
      final chapitres = lireLesChapitres();
      final nord = chapitres['gr20-nord']!;
      final sud = chapitres['gr20-sud']!;

      // LA MESURE D'ABORD, pour que le cas rougisse si la trace bouge.
      expect(nord['deniveleM'], 7401);
      expect(sud['deniveleM'], 4243);
      expect((nord['distanceKm'] as num).toStringAsFixed(2), '91.80');
      expect((sud['distanceKm'] as num).toStringAsFixed(2), '91.79');
      expect(nord['etapes'], 9);
      expect(sud['etapes'], 7);
      expect(nord['nuits'], 15);
      expect(sud['nuits'], 16);

      // PUIS LE TEXTE, qui doit porter exactement ces nombres.
      final texteNord = ficheDe('gr20-nord').description;
      expect(texteNord.ouCest, contains('91,80 km'));
      expect(texteNord.ouCest, contains('7 401 m'));
      expect(texteNord.ouCest, contains('neuf etapes'));
      expect(texteNord.aQuoiSAttendre, contains('7 401 m'));
      expect(texteNord.aQuoiSAttendre, contains('4 243'));
      expect(texteNord.aQuoiSAttendre, contains('Quinze endroits'));

      final texteSud = ficheDe('gr20-sud').description;
      expect(texteSud.ouCest, contains('91,79 km'));
      expect(texteSud.ouCest, contains('4 243 m'));
      expect(texteSud.ouCest, contains('sept etapes'));
      expect(texteSud.aQuoiSAttendre, contains('Seize endroits'));
    });

    test('LES ALTITUDES DU TEXTE SONT CELLES QUE LA CONFIG PROUVE', () {
      // `altitude_max_mesuree_846_test` verifie ces deux nombres SUR LA TRACE
      // de chaque chapitre. Ce cas-ci verifie que le texte dit les memes.
      expect(gr20NordTrailConfig.maxAltitudeM, 2578);
      expect(gr20SudTrailConfig.maxAltitudeM, 2021);

      expect(ficheDe('gr20-nord').description.ceQuOnYVoit, contains('2 578 m'));
      expect(ficheDe('gr20-sud').description.ceQuOnYVoit, contains('2 021 m'));
      // L'ECART EST DIT, ET IL EST JUSTE : 2 578 - 2 021 = 557.
      expect(
        gr20NordTrailConfig.maxAltitudeM! - gr20SudTrailConfig.maxAltitudeM!,
        557,
      );
      expect(ficheDe('gr20-sud').description.ceQuOnYVoit, contains('557 m'));
    });
  });

  group('853 — la difference entre les deux moities est REELLE', () {
    test('LE NORD EST TRES DIFFICILE A TOUTES SES ALLURES', () {
      // CE QUE LA FICHE DU NORD PROMET : « de cinq a quinze jours, le verdict
      // ne bouge pas ». Mesure ici, allure par allure, par le socle du produit.
      final nuits = lireLesNuits('gr20-nord');
      expect(nuits.journeesMaximales, 15);
      for (var jours = 5; jours <= 15; jours++) {
        expect(
          verdictDe(nuits, jours),
          NiveauDeDifficulte.tresDifficile,
          reason: 'le nord a $jours jours',
        );
      }
      expect(
        ficheDe('gr20-nord').description.aQuoiSAttendre,
        contains('de cinq a quinze jours, le verdict ne bouge pas'),
      );
    });

    test('LE SUD BASCULE A HUIT JOURS, ET LA FICHE LE DIT', () {
      // LA SEULE FRONTIERE MOBILE DU GR20, ET C'EST UNE INFORMATION DE VENTE.
      // A sept jours le sud est tres difficile — par l'ENCHAINEMENT, pas par
      // une journee qui casse. Des huit, il est difficile, et il le reste.
      final nuits = lireLesNuits('gr20-sud');
      expect(nuits.journeesMaximales, 16);

      expect(verdictDe(nuits, 7), NiveauDeDifficulte.tresDifficile);
      for (var jours = 8; jours <= 16; jours++) {
        expect(
          verdictDe(nuits, jours),
          NiveauDeDifficulte.difficile,
          reason: 'le sud a $jours jours',
        );
      }

      // ET A SEPT JOURS, C'EST BIEN L'ACCUMULATION QUI LE MONTE : sa pire
      // journee est « difficile », donc un verdict calcule sur elle seule
      // n'aurait jamais rendu « tres difficile ».
      final aSept = DifficulteDuSentier.calculer(
        jours: 7,
        journees: DecoupageSurLesNuits.repartir(nuits, 7)
            .map(
              (j) => JourneeMesuree(
                km: j.km,
                deniveleM: j.deniveleM,
                descenteM: j.descenteM,
              ),
            )
            .toList(growable: false),
      )!;
      expect(aSept.plancher, NiveauDeDifficulte.difficile);
      expect(aSept.verdictMonteParLAccumulation, isTrue);
      expect(aSept.plusLongueSuiteEnBandesHautes, 7);

      final texte = ficheDe('gr20-sud').description.aQuoiSAttendre;
      expect(texte, contains('huit jours'));
      expect(texte, contains('difficile'));
    });

    test('LE SELECTEUR DU SUD OFFRE L ALLURE QUI CHANGE LE VERDICT', () {
      // UN TEXTE QUI PROMET UN CRAN QUE LE SELECTEUR N'ATTEINT PAS EST PIRE
      // QU'UN TEXTE MUET. Le sud n'offrait que 5 et 7 jours — ses deux seules
      // allures tres difficiles — alors que sa fiche annonce le basculement a
      // huit.
      expect(gr20SudTrailConfig.availableDurations, contains(8));
      final nuits = lireLesNuits('gr20-sud');
      final verdicts = {
        for (final jours in gr20SudTrailConfig.availableDurations)
          jours: verdictDe(nuits, jours),
      };
      expect(
        verdicts.values.toSet().length,
        greaterThan(1),
        reason: 'les allures offertes ne rendent pas toutes le meme mot',
      );
    });

    test('LE NORD EST LE PLUS DUR DES DEUX, A DISTANCE EGALE', () {
      // L'ARGUMENT QUI SEPARE LES DEUX PRODUITS : meme longueur au metre pres,
      // presque deux fois la montee au nord.
      final chapitres = lireLesChapitres();
      final kmNord = (chapitres['gr20-nord']!['distanceKm'] as num).toDouble();
      final kmSud = (chapitres['gr20-sud']!['distanceKm'] as num).toDouble();
      expect((kmNord - kmSud).abs(), lessThan(0.02));

      final dNord = chapitres['gr20-nord']!['deniveleM'] as int;
      final dSud = chapitres['gr20-sud']!['deniveleM'] as int;
      expect(dNord / dSud, greaterThan(1.7));
    });
  });
}
