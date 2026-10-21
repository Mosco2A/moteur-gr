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
import 'package:moteur_gr/core/geo/gpx_depuis_les_assets.dart';
import 'package:moteur_gr/core/models/fiche_de_sentier.dart';
import 'package:moteur_gr/domain/indice_du_terrain.dart';
import 'package:moteur_gr/domain/journees_pesees.dart';
import 'package:moteur_gr/domain/nuit_possible.dart';
import 'package:moteur_gr/domain/profil_du_terrain.dart';
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

/// Le profil d'un chapitre, lu sur SA trace — celle de son propre dossier.
ProfilDuTerrain profilDe(String dossier) {
  final points = GpxDepuisLesAssets.parseFromString(
    File('assets/data/$dossier/track.gpx').readAsStringSync(),
  );
  return ProfilDuTerrain.depuisLaTrace(
    distancesM: points.map((p) => p.distanceFromStart).toList(growable: false),
    altitudesM: points.map((p) => p.altitude).toList(growable: false),
  );
}

/// L'EFFORT D'UN GROUPE DE SEGMENTS — la charge que le repartiteur egalise
/// depuis la tache 860 (« Oui a l'effort pas au temps »).
double Function(int, int) effortDuGroupe(
  DecoupageDeNuits nuits,
  ProfilDuTerrain profil,
) {
  final pkParNom = <String, double>{
    for (final nuit in nuits.nuits) nuit.nom: nuit.pkKm,
  };
  double pkDeFin(int segment) =>
      pkParNom[nuits.segments[segment].arrivee] ?? 0.0;
  return (debut, fin) {
    final pkDebut = debut == 0 ? 0.0 : pkDeFin(debut - 1);
    final pkFin = pkDeFin(fin - 1);
    if (pkFin <= pkDebut) return 0.0;
    return IndiceDuTerrain.calculer(
      terrain: profil.tranche(
        pkDebutM: pkDebut * 1000.0,
        pkFinM: pkFin * 1000.0,
      ),
    ).indice;
  };
}

/// LES JOURNEES D'UNE ALLURE, AVEC LEURS BORNES SUR LA TRACE — exactement
/// comme la fiche les pose (tache 858). La borne de depart d'une journee est
/// l'arrivee de la precedente, et toutes viennent des nuits RELEVEES.
List<JourneeAPeser> journeesDe(
  DecoupageDeNuits nuits,
  ProfilDuTerrain profil,
  int jours,
) {
  final journees = <JourneeAPeser>[];
  var pk = 0.0;
  var depart = nuits.teteDeSentier;
  for (final j in DecoupageSurLesNuits.repartir(
    nuits,
    jours,
    effortDuGroupe: effortDuGroupe(nuits, profil),
  )) {
    final pkFin = j.arrivee?.pkKm ?? pk;
    journees.add(
      JourneeAPeser(
        depart: depart,
        arrivee: j.arriveeNom,
        km: j.km,
        deniveleM: j.deniveleM,
        descenteM: j.descenteM,
        minutes: j.minutes,
        pkDebutKm: pk,
        pkFinKm: pkFin,
      ),
    );
    pk = pkFin;
    depart = j.arriveeNom;
  }
  return journees;
}

/// L'INDICE DE TERRAIN de la pire journee d'un chapitre a une allure donnee,
/// par le socle du produit (tache 858). Il a remplace le kilometre-effort de
/// la tache 852, qui etait faux et que ces fiches CITAIENT a leurs clients.
JourneePesee pireJourneeDe(String dossier, int jours) {
  final profil = profilDe(dossier);
  final nuits = lireLesNuits(dossier);
  return SentierPese.peser(
    jours: jours,
    profil: profil,
    journees: journeesDe(nuits, profil, jours),
  )!.pireJournee!;
}

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
    test('LE NORD A UN PLANCHER D INDICE QUE L ALLURE NE FAIT PAS DESCENDRE, '
        'ET SA FICHE LE CHIFFRE', () {
      // CE QUE LA FICHE DU NORD PROMET, ET POURQUOI C'EST VRAI : sa premiere
      // journee monte 1 455 m d'un seul tenant et AUCUN couchage releve ne la
      // coupe. Elle est donc le PLANCHER de toutes les allures fines : de
      // huit a quinze jours, la pire journee du nord ne descend plus.
      final nuits = lireLesNuits('gr20-nord');
      expect(nuits.journeesMaximales, 15);
      for (var jours = 8; jours <= 15; jours++) {
        final pire = pireJourneeDe('gr20-nord', jours);
        expect(
          pire.noteDEffort,
          closeTo(16.06, 0.05),
          reason: 'le nord a $jours jours',
        );
        expect(pire.depart, 'Calenzana');
        expect(pire.plusGrosseMonteeM, closeTo(1454, 2));
      }
      // A SEPT JOURS LE PLANCHER N EST PLUS L ETAPE 1, et c'est une
      // consequence de l'exposant mesure : la journee Ortu vers Ascu-Stagnu
      // la depasse de quatre centiemes d'indice.
      expect(pireJourneeDe('gr20-nord', 7).noteDEffort, closeTo(16.12, 0.05));
      // ET SERRER L'ALLURE A CINQ JOURS FAIT MONTER, ce que la fiche
      // annonce : 17,5 contre 16,1 sur vingt d'effort. L'ECART S'EST
      // RESSERRE EN PASSANT AUX SEUILS PUBLIES (1,4 point au lieu de 2,9)
      // et c'est attendu : le dernier palier de la jauge d'effort est le
      // plus plat de tous, parce qu'au-dela du seuil publie de 25 km et
      // 1 000 m aucun bareme du monde ne gradue plus.
      final aCinq = pireJourneeDe('gr20-nord', 5);
      expect(aCinq.noteDEffort, closeTo(17.48, 0.05));
      final texte = ficheDe('gr20-nord').description.aQuoiSAttendre;
      expect(texte, contains('un effort de 16,1 sur 20'));
      expect(texte, contains('passe a 17,5 sur 20'));
    });

    test('LE SUD DESCEND QUAND ON LUI DONNE DU TEMPS, ET LA FICHE LE '
        'CHIFFRE', () {
      // LA VRAIE DIFFERENCE ENTRE LES DEUX MOITIES, MESUREE EN INDICE : le sud
      // repond a l'allure, le nord non. De cinq a seize jours sa pire journee
      // tombe de 14,1 a 8,3 d'effort, parce que ses montees se coupent
      // toutes sur un couchage releve.
      expect(lireLesNuits('gr20-sud').journeesMaximales, 16);
      final aCinq = pireJourneeDe('gr20-sud', 5).noteDEffort;
      final aSept = pireJourneeDe('gr20-sud', 7).noteDEffort;
      final aHuit = pireJourneeDe('gr20-sud', 8).noteDEffort;
      final aSeize = pireJourneeDe('gr20-sud', 16).noteDEffort;
      expect(aCinq, closeTo(14.11, 0.05));
      expect(aSept, closeTo(10.57, 0.05));
      expect(aHuit, closeTo(9.21, 0.05));
      expect(aSeize, closeTo(8.29, 0.05));
      expect(
        aCinq > aSept && aSept > aHuit && aHuit > aSeize,
        isTrue,
        reason: 'au sud, chaque jour donne allege la pire journee',
      );
      // LA JOURNEE QUI FAIT LE PLANCHER DU SUD A CHANGE AVEC LE COMPTE, et la
      // fiche le dit : le kilometre-effort nommait la DERNIERE journee, celle
      // qui DESCEND 1 090 m vers Conca, parce qu'il facturait la descente a
      // 0,30. L'indice mesure l'energie : c'est la PREMIERE, la montee de
      // 703 m au-dessus de Vizzavona, qui fait le plancher du chapitre.
      final plancher = pireJourneeDe('gr20-sud', 16);
      expect(plancher.depart, contains('Vizzavona'));
      expect(plancher.deniveleM, greaterThan(plancher.descenteM));
      final texte = ficheDe('gr20-sud').description.aQuoiSAttendre;
      expect(texte, contains('10,6 sur 20'));
      expect(texte, contains('ne descend jamais sous 8,3 sur 20'));
      expect(texte, contains('Vizzavona'));
    });

    test('LE SELECTEUR DU SUD OFFRE L ALLURE QUI CHANGE LE CHIFFRE', () {
      // UN TEXTE QUI PROMET UN ALLEGEMENT QUE LE SELECTEUR N'ATTEINT PAS EST
      // PIRE QU'UN TEXTE MUET. Le sud n'offrait que 5 et 7 jours alors que sa
      // fiche parle de huit.
      expect(gr20SudTrailConfig.availableDurations, contains(8));
      final indices = {
        for (final jours in gr20SudTrailConfig.availableDurations)
          jours: pireJourneeDe('gr20-sud', jours).noteDEffort,
      };
      expect(
        indices.values.toSet().length,
        greaterThan(1),
        reason: 'les allures offertes ne rendent pas toutes le meme chiffre',
      );
    });

    test('PLUS AUCUNE FICHE NE CITE LE KILOMETRE-EFFORT A SES CLIENTS '
        '(tache 858)', () {
      // LA GARDE DU NETTOYAGE. Le kilometre-effort de la tache 852 etait
      // AFFICHE AUX CLIENTS, jusque dans le texte de vente des fiches, et il
      // etait faux. Il est retire du code ; cette garde empeche qu'il revienne
      // par la donnee.
      // TOUS LES SENTIERS DU CATALOGUE QUI ONT UNE FICHE, et pas une liste
      // d'identifiants ecrite a la main : un sentier ajoute demain doit entrer
      // dans cette garde tout seul.
      final avecFiche = TrailCatalog.all
          .where((c) => (c.ficheAssetPath ?? '').isNotEmpty)
          .map((c) => c.id)
          .toList(growable: false);
      expect(avecFiche.length, greaterThanOrEqualTo(3));
      for (final id in avecFiche) {
        final fiche = ficheDe(id);
        for (final texte in <String>[
          fiche.description.ouCest,
          fiche.description.ceQuOnYVoit,
          fiche.description.aQuoiSAttendre,
        ]) {
          expect(
            texte.toLowerCase(),
            isNot(contains('km-effort')),
            reason: 'la fiche de $id cite encore le compte retire',
          );
          expect(texte.toLowerCase(), isNot(contains('kilometre-effort')));
        }
      }
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
