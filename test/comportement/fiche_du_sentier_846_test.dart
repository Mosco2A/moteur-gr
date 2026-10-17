// GARDE — TACHE 846 : UNE PHOTO SANS PROVENANCE N'ENTRE PAS DANS LE PRODUIT.
//
// CE QUE CES CAS VERROUILLENT, ET POURQUOI ILS EXISTENT. Le depot porte 271
// photos qui servent aux carrousels, et leur seul fichier de suivi enregistre
// le SUJET de chaque image — ni sa source, ni sa licence (mesure du 17/10,
// memoire #102112). Interroge, Christophe a repondu « On les a trouve sur
// internet en libre de droit ». Cette phrase recouvre quatre realites tres
// differentes : domaine public, CC0, CC-BY qui EXIGE de citer l'auteur, et
// CC-BY-NC qui INTERDIT l'usage commercial. Dans une application PAYANTE, deux
// de ces quatre cas sont des infractions.
//
// LA REGLE N'EST DONC PAS UN AVERTISSEMENT, C'EST UN REFUS, et c'est ce que ces
// cas prouvent : le lecteur du manifeste ECARTE une photo incomplete au lieu de
// la signaler. C'est la difference entre le commentaire « donnees fictives » et
// le drapeau `isFictional` de la tache 793 — un commentaire n'est pas une
// garde.
//
// ET LA LISTE DES LICENCES EST BLANCHE, PAS NOIRE. Une liste noire laisse
// passer ce qu'elle n'a pas prevu ; le jeu d'essai contient exprès une photo
// dont la licence est remplie « libre de droit », c'est-a-dire la phrase meme
// qui a declenche cette regle, et elle doit etre refusee.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/gr20_trail_config.dart';
import 'package:moteur_gr/core/config/mare_a_mare_centre_trail_config.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/models/fiche_de_sentier.dart';

/// Le jeu d'essai : six photos, dont quatre a refuser.
String lireJeuDEssai() =>
    File('test/fixtures/fiche/jeu_d_essai.json').readAsStringSync();

void main() {
  group('846 — le manifeste se lit, et il refuse', () {
    test('les quatre photos sans provenance valable sont ECARTEES', () {
      final fiche = lireFicheDeSentier(lireJeuDEssai(), 'sentier-d-essai');

      expect(fiche, isNotNull);
      expect(fiche!.photos.length, 2, reason: 'deux photos publiables');
      expect(fiche.photosRefusees.length, 4, reason: 'quatre refus');

      final motifs = fiche.photosRefusees
          .map((refusee) => refusee.motif)
          .toList();
      expect(motifs, contains(MotifDeRefus.auteurManquant));
      expect(motifs, contains(MotifDeRefus.licenceNonCommerciale));
      expect(motifs, contains(MotifDeRefus.sourceManquante));
    });

    test('le refus est NOMME photo par photo — jamais silencieux', () {
      final fiche = lireFicheDeSentier(lireJeuDEssai(), 'sentier-d-essai')!;
      final parFichier = <String, MotifDeRefus>{
        for (final refusee in fiche.photosRefusees)
          refusee.fichier: refusee.motif,
      };

      expect(
        parFichier['test/fixtures/fiche/un_refuge.jpg'],
        MotifDeRefus.auteurManquant,
      );
      expect(
        parFichier['test/fixtures/fiche/un_lac.jpg'],
        MotifDeRefus.licenceNonCommerciale,
        reason: 'CC BY-NC interdit l usage commercial',
      );
      expect(
        parFichier['test/fixtures/fiche/une_vallee.jpg'],
        MotifDeRefus.licenceNonCommerciale,
        reason: '« libre de droit » n est pas une licence',
      );
      expect(
        parFichier['test/fixtures/fiche/un_sommet.jpg'],
        MotifDeRefus.sourceManquante,
      );
    });

    test('la MENTION de chaque photo publiable existe', () {
      final fiche = lireFicheDeSentier(lireJeuDEssai(), 'sentier-d-essai')!;
      for (final photo in fiche.photos) {
        expect(photo.mention, isNotEmpty);
        expect(photo.auteur, isNotEmpty);
        expect(photo.licence, isNotEmpty);
        expect(photo.adresseDOrigine, isNotEmpty);
        expect(photo.estPubliable, isTrue);
        expect(photo.motifDeRefus, isNull);
      }
    });

    test('les coordonnees ne sont lues que si la source les donne', () {
      final fiche = lireFicheDeSentier(lireJeuDEssai(), 'sentier-d-essai')!;
      final avec = fiche.photos.firstWhere((p) => p.aDesCoordonnees);
      final sans = fiche.photos.firstWhere((p) => !p.aDesCoordonnees);

      expect(avec.lat, closeTo(42.4652, 0.0001));
      expect(avec.lon, closeTo(8.90688, 0.0001));
      expect(sans.lat, isNull);
      expect(sans.lon, isNull, reason: 'on ne devine pas un lieu');
    });

    test('la COUVERTURE est celle qui se declare telle', () {
      final fiche = lireFicheDeSentier(lireJeuDEssai(), 'sentier-d-essai')!;
      expect(fiche.couverture?.fichier, 'test/fixtures/fiche/un_col.jpg');
    });

    test('sans photo declaree couverture, c est la premiere publiable', () {
      const fiche = FicheDeSentier(
        trailId: 'x',
        description: DescriptionDeSentier.vide,
        photos: [
          PhotoDeSentier(
            fichier: 'a.jpg',
            adresseDOrigine: 'https://exemple.invalid/a',
            auteur: 'A',
            licence: 'CC0',
            mention: 'A — CC0',
          ),
          PhotoDeSentier(
            fichier: 'b.jpg',
            adresseDOrigine: 'https://exemple.invalid/b',
            auteur: 'B',
            licence: 'CC0',
            mention: 'B — CC0',
          ),
        ],
        photosRefusees: <PhotoRefusee>[],
      );
      expect(fiche.couverture?.fichier, 'a.jpg');
      expect(fiche.estVide, isFalse);
    });

    test('la description se lit en TROIS parties separees', () {
      final fiche = lireFicheDeSentier(lireJeuDEssai(), 'sentier-d-essai')!;
      expect(fiche.description.ouCest, isNotEmpty);
      expect(fiche.description.ceQuOnYVoit, isNotEmpty);
      expect(fiche.description.aQuoiSAttendre, isNotEmpty);
      expect(fiche.description.estVide, isFalse);
    });

    test('un manifeste qui parle d UN AUTRE sentier est refuse en bloc', () {
      // Une fiche pauvre est un etat normal ; une fiche qui se trompe de
      // sentier est une FAUTE, et elle ne doit pas s'afficher sur le mauvais
      // sentier.
      expect(lireFicheDeSentier(lireJeuDEssai(), 'gr20'), isNull);
    });

    test('un JSON casse ne leve pas : il rend une fiche absente', () {
      expect(lireFicheDeSentier('{ ceci n est pas du json', 'gr20'), isNull);
      expect(lireFicheDeSentier('[]', 'gr20'), isNull);
      expect(lireFicheDeSentier('', 'gr20'), isNull);
    });

    test('un manifeste sans photos ni description rend une fiche VIDE', () {
      final fiche = lireFicheDeSentier('{"trailId": "gr20"}', 'gr20');
      expect(fiche, isNotNull);
      expect(fiche!.estVide, isTrue);
      expect(fiche.couverture, isNull);
      expect(fiche.description.estVide, isTrue);
    });
  });

  group('846 — la liste blanche des licences refuse par defaut', () {
    test('ce qui autorise l usage commercial passe', () {
      for (final licence in <String>[
        'CC0',
        'CC0 1.0',
        'cc0',
        'domaine public',
        'public domain',
        'CC BY 4.0',
        'CC-BY-4.0',
        'ccby4.0',
        'CC BY-SA 3.0',
        'CC_BY_SA_2.5',
      ]) {
        expect(
          LicencesCommerciales.autorise(licence),
          isTrue,
          reason: '$licence devrait passer',
        );
      }
    });

    test('ce qui ne l autorise pas, ou qu on ne connait pas, ne passe pas', () {
      for (final licence in <String>[
        '',
        'CC BY-NC 4.0',
        'CC BY-NC-SA 4.0',
        'CC-BY-NC-ND-4.0',
        'libre de droit',
        'droits reserves',
        'tous droits reserves',
        'usage personnel',
        'inconnue',
      ]) {
        expect(
          LicencesCommerciales.autorise(licence),
          isFalse,
          reason: '$licence ne devrait PAS passer',
        );
      }
    });

    test('la ponctuation ne fait pas refuser une licence legitime', () {
      expect(
        LicencesCommerciales.normaliser('CC BY-SA 4.0'),
        LicencesCommerciales.normaliser('cc_by_sa_4.0'),
      );
    });
  });

  group('846 — les deux sentiers reels ont une fiche, le decor n en a pas', () {
    Map<String, dynamic> lireManifeste(String chemin) =>
        jsonDecode(File(chemin).readAsStringSync()) as Map<String, dynamic>;

    test('le GR20 declare sa fiche, et elle est lisible et pleine', () {
      final chemin = gr20TrailConfig.ficheAssetPath;
      expect(chemin, isNotNull);
      final fichier = File(chemin!);
      expect(fichier.existsSync(), isTrue, reason: 'fiche du GR20 absente');

      final fiche = lireFicheDeSentier(fichier.readAsStringSync(), 'gr20')!;
      expect(fiche.description.ouCest, contains('Calenzana'));
      expect(fiche.description.ouCest, contains('Conca'));
      expect(fiche.description.ceQuOnYVoit, contains('2 578'));
      expect(fiche.description.aQuoiSAttendre, isNotEmpty);
      expect(fiche.estVide, isFalse);
      // TACHE 848 — LES PHOTOS SONT ENTREES, ET C'EST CE CAS QUI LE DIT.
      //
      // IL ATTENDAIT L'INVERSE, ET IL AVAIT RAISON DE L'ATTENDRE. La tache 846
      // a livre le LECTEUR, le CONTRAT et le JEU D'ESSAI avec des manifestes
      // VIDES : a ce moment-la, une photo dans le produit aurait ete une photo
      // sans preuve de licence, dans une application PAYANTE. Le fonds
      // documente de la tache 845 existe depuis — dix-huit images de Wikimedia
      // Commons, licence verifiee a l'adresse, mention a afficher, empreinte
      // mesuree — et la tache 848 les a fait entrer avec leur preuve a cote
      // (`assets/data/<sentier>/photos/PROVENANCE.json`).
      //
      // LA REGLE VERIFIEE ICI NE CHANGE PAS, SEUL SON ETAT CHANGE : aucune
      // image n'entre sans ses cinq champs. Le detail est garde par
      // `test/assets/photos_du_produit_848_test.dart`.
      expect(fiche.photos.length, 12, reason: 'six vues du nord, six du sud');
      expect(fiche.photosRefusees, isEmpty);
      expect(fiche.couverture, isNotNull);
      expect(fiche.couverture!.auteur, isNotEmpty);
      expect(fiche.couverture!.mention, contains(fiche.couverture!.auteur));
    });

    test('le Mare a Mare Centre declare la sienne', () {
      final chemin = mareAMareCentreTrailConfig.ficheAssetPath;
      expect(chemin, isNotNull);
      final fiche = lireFicheDeSentier(
        File(chemin!).readAsStringSync(),
        'mare-a-mare-centre',
      )!;
      expect(fiche.description.ouCest, contains('Ghisonaccia'));
      expect(fiche.description.ceQuOnYVoit, contains('1 513'));
    });

    test('le sentier de TEST n a pas de fiche, et c est voulu', () {
      // LA REGLE DU TROU SE VERIFIE SUR LUI : c'est le sentier des tests de
      // widget, il n'a ni description ni photo, et sa fiche doit avoir l'air
      // finie quand meme.
      expect(testTrailConfig.ficheAssetPath, isNull);
      expect(testTrailConfig.maxAltitudeM, isNull);
    });

    test('chaque manifeste porte son attribution et son numero de schema', () {
      for (final chemin in <String>[
        gr20TrailConfig.ficheAssetPath!,
        mareAMareCentreTrailConfig.ficheAssetPath!,
      ]) {
        final brut = lireManifeste(chemin);
        expect(brut['schema'], 1);
        expect(brut['attribution'], isA<String>());
        expect((brut['attribution'] as String), contains('OpenStreetMap'));
        expect(brut['photos'], isA<List<dynamic>>());
      }
    });

    test('le contrat de provenance voyage avec les dossiers de photos', () {
      // Le LISEZ-MOI est ce qui rend le dossier reel (un dossier d'assets vide
      // ne s'embarque pas) ET le contrat que la tache 845 doit remplir. Les
      // deux raisons tiennent ensemble.
      for (final dossier in <String>[
        'assets/data/gr20/photos',
        'assets/data/mare_a_mare_centre/photos',
      ]) {
        final contrat = File('$dossier/LISEZ-MOI.txt');
        expect(
          contrat.existsSync(),
          isTrue,
          reason: 'contrat de provenance absent de $dossier',
        );
        final texte = contrat.readAsStringSync();
        for (final champ in <String>[
          'adresse_d_origine',
          'auteur',
          'licence',
          'mention',
        ]) {
          expect(texte, contains(champ));
        }
      }
    });
  });
}
