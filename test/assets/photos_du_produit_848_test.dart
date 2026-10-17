// GARDE — TACHE 848 : LES PHOTOS SONT DANS LE BINAIRE, ET LEUR PREUVE AVEC.
//
// CE QUE CES CAS EMPECHENT, ET C'EST UN RISQUE JURIDIQUE AVANT D'ETRE UN
// RISQUE TECHNIQUE. L'application est PAYANTE. Une image dont on ne peut pas
// prouver la licence y est une infraction, et « libre de droit » recouvre
// quatre realites dont deux l'interdisent (memoire #102112, 17/10). Le fonds de
// la tache 845 a donc ete constitue avec, pour chaque image, l'adresse de la
// page qui PORTE sa licence, son auteur, sa licence exacte et la mention a
// afficher.
//
// LE RISQUE PRECIS QUE CE FICHIER COUVRE : que l'image et sa preuve se
// SEPARENT. Le fonds vit hors du depot, dans un dossier que git ignore ; les
// images, elles, entrent dans le binaire. Si la preuve reste dehors, le binaire
// embarque des images dont plus rien, dans le depot, ne dit d'ou elles
// viennent. D'ou les trois exigences verifiees ici : chaque image declaree
// EXISTE, chaque image presente est DECLAREE, et la preuve voyage A COTE.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/trail_catalog.dart';
import 'package:moteur_gr/core/models/fiche_de_sentier.dart';

/// Les sentiers qui declarent une fiche, et le dossier d'assets ou cette fiche
/// vit.
///
/// [TrailCatalog.referentiel] ET PAS [TrailCatalog.all] — LA JONCTION DES LOTS
/// 841 ET 848 L'A IMPOSE (tache 851).
///
/// Ce fichier lisait `all`, qui etait alors « tout ce qui existe vraiment ». Le
/// lot 841 lui a donne un second filtre : un sentier qui a des CHAPITRES en est
/// ECARTE, sur la decision de Christophe du 15/10 17:45 (« on achete le sentier
/// seulement si il n y a pas de chapitres »). Le GR20 mere a quitte `all`
/// — et avec lui les DOUZE images de son fonds, puisque c'est SA fiche qui les
/// declare. Mesure a la fusion : il ne comptait plus que 6 images sur 18
/// et 11 refus sur 22, sans qu'une seule ligne de preuve ait bouge.
///
/// `referentiel` est le bon ensemble pour CE fichier, et ce n'est pas un
/// assouplissement : les attentes restent 18 et 22, exactement. Ce que ces cas
/// prouvent est l'INTEGRITE DU FONDS et la completude de sa preuve — chaque
/// image publiable, sourcee, presente sur le disque, sans orpheline, avec son
/// `PROVENANCE.json` et son `CHOIX_ET_REFUS.csv`. Or le GR20 mere « est une
/// VERITE qui n'est pas un produit » (mot pour mot la doc de
/// [TrailCatalog.all]) : ses donnees restent la reference d'ou ses chapitres
/// sont decoupes, et son fonds photo avec elles. Le mesurer sur `all`, c'etait
/// faire dependre une garde de DONNEES d'une decision de VENTE.
///
/// LE TROU DE PRODUIT EST BOUCHE, ET CE FICHIER A CHANGE DE METHODE POUR CA
/// (tache 853).
///
/// CE QUI MANQUAIT, ET QUE CE FICHIER DISAIT LUI-MEME : « les deux chapitres du
/// GR20 ne declarent AUCUNE fiche, donc leur fiche n'a ni texte ni bande de
/// photos. C'est un TROU DE PRODUIT ouvert par la jonction des deux lots (...)
/// il est remonte a Christophe plutot que tranche ici. » Il est tranche : les
/// deux chapitres declarent chacun sa fiche, son texte et SES six photos, avec
/// sa propre couverture — le lac de Capitello au nord, le col de Bavella au
/// sud. La repartition n'a pas eu a etre inventee : le fonds de la tache 845
/// etait DEJA range par chapitre (`chapitre_du_fonds`, `role_dans_le_fonds`).
///
/// LES IMAGES NE SONT PAS DUPLIQUEES, ET C'EST POURQUOI LA MESURE A CHANGE DE
/// PIVOT. Les douze fichiers du GR20 restent dans `assets/data/gr20/photos/`
/// avec LEUR PREUVE UNIQUE ; les fiches des deux chapitres les declarent par
/// leur vrai chemin. Recopier six images par chapitre aurait double six
/// megaoctets de JPEG dans un binaire hors ligne par conception, et surtout
/// DEDOUBLE la preuve : deux `PROVENANCE.json` a tenir a jour pour les memes
/// images, donc deux occasions de se contredire.
///
/// LA MESURE EST DONC PAR IMAGE ET NON PLUS PAR FICHE, ET ELLE Y GAGNE. Avant,
/// chaque cas partait de la fiche et cherchait la preuve A COTE DE LA FICHE ;
/// il comptait aussi les photos en SOMMANT les fiches, ce qui compte deux fois
/// une image partagee par deux produits. Desormais la preuve est cherchee A
/// COTE DE L'IMAGE — c'est la ou elle doit etre, et c'est litteralement ce que
/// l'en-tete de ce fichier exige depuis la 848 — et les comptes portent sur les
/// images DISTINCTES du fonds. Les attentes restent 18 et 22, exactement, et
/// elles mesurent maintenant ce qu'elles pretendent mesurer.
Map<String, String> fichesDuCatalogue() => <String, String>{
  for (final config in TrailCatalog.referentiel)
    if ((config.ficheAssetPath ?? '').isNotEmpty)
      config.id: config.ficheAssetPath!,
};

/// Toutes les photos DECLAREES par une fiche du catalogue, image par image,
/// avec le sentier qui la declare — une image partagee apparait une fois par
/// declarant.
List<(String, PhotoDeSentier)> photosDeclarees() => [
  for (final entree in fichesDuCatalogue().entries)
    for (final photo in lireFicheDeSentier(
      File(entree.value).readAsStringSync(),
      entree.key,
    )!.photos)
      (entree.key, photo),
];

/// LE DOSSIER DE PREUVE D'UNE IMAGE : celui ou l'image EST, pas celui ou sa
/// fiche est.
///
/// C'est tout le changement de la 853 : `assets/data/gr20-nord/fiche.json`
/// declare des images qui vivent dans `assets/data/gr20/photos/`, et c'est la
/// que leur `PROVENANCE.json` doit se trouver — avec elles.
String dossierDePreuveDe(PhotoDeSentier photo) =>
    File(photo.fichier).parent.path.replaceAll(r'\', '/');

/// Les dossiers de photos DISTINCTS que le catalogue embarque reellement.
Set<String> dossiersDePreuve() => {
  for (final (_, photo) in photosDeclarees()) dossierDePreuveDe(photo),
};

void main() {
  test('AU MOINS UN SENTIER PORTE DES PHOTOS', () {
    // CE CAS EST LA SENTINELLE DES AUTRES. Tous les cas ci-dessous bouclent sur
    // les photos declarees : si plus aucune n'etait declaree, ils passeraient
    // tous en ne verifiant RIEN. La tache 846 a livre le lecteur avec des
    // manifestes VIDES ; la 848 y fait entrer dix-huit images.
    //
    // ON COMPTE LES IMAGES DISTINCTES, ET PLUS LA SOMME DES FICHES (tache 853).
    // Depuis que les deux chapitres du GR20 declarent leurs six photos, une
    // SOMME compterait les douze images du GR20 deux fois : une fois par la
    // fiche du sentier mere, une fois par celles de ses chapitres. Le fonds,
    // lui, n'a pas grossi — il porte toujours dix-huit images, et c'est ce
    // nombre-la qui dit la verite sur ce qui voyage dans le binaire.
    final distinctes = {for (final (_, p) in photosDeclarees()) p.fichier};
    expect(distinctes.length, 18, reason: 'les 18 images du fonds de la 845');

    // ET CHAQUE SENTIER REELLEMENT LIVRE EN PORTE, ce que la version
    // precedente de ce fichier ne prouvait justement PLUS. C'est le trou de
    // produit referme : un sentier vendable sans fiche s'affiche avec une carte
    // VIDE, puis une page sans texte ni photo.
    //
    // « REELLEMENT LIVRE » = QUI PORTE UNE TRACE, et l'exception est nommee
    // plutot que large. `gr-pyrenees` est au registre avec une trace VIDE
    // (`gpxAssetPath: ''`, tache 607, « la correction est de ne plus mentir,
    // pas de fabriquer une trace ») : sa source de publication le retient en
    // `draft`, il n'est pas un produit, et lui demander une fiche de photos
    // reviendrait a demander des photos d'un sentier dont on n'a pas le
    // chemin. Le jour ou il recoit sa trace, ce cas exigera sa fiche.
    for (final config in TrailCatalog.all) {
      if (config.isFictional) continue;
      if (config.gpxAssetPath.isEmpty) continue;
      expect(
        config.ficheAssetPath ?? '',
        isNotEmpty,
        reason: '${config.id} est livre et ne declare aucune fiche',
      );
    }
  });

  group('848 — chaque photo declaree est publiable ET presente', () {
    test('les cinq champs, la liste blanche, et le fichier sur le disque', () {
      for (final entree in fichesDuCatalogue().entries) {
        final fiche = lireFicheDeSentier(
          File(entree.value).readAsStringSync(),
          entree.key,
        );
        expect(fiche, isNotNull, reason: 'la fiche de ${entree.key} se lit');

        // AUCUN REFUS : une image refusee ne s'afficherait pas, et son poids
        // resterait dans le binaire. Les deux sont inacceptables.
        expect(
          fiche!.photosRefusees,
          isEmpty,
          reason:
              'photos refusees sur ${entree.key} : '
              '${fiche.photosRefusees.map(_decrire).join(', ')}',
        );
        expect(fiche.photos, isNotEmpty);

        for (final photo in fiche.photos) {
          expect(photo.estPubliable, isTrue);
          expect(
            LicencesCommerciales.autorise(photo.licence),
            isTrue,
            reason: '${photo.fichier} : licence « ${photo.licence} »',
          );
          expect(
            File(photo.fichier).existsSync(),
            isTrue,
            reason: '${photo.fichier} est declare mais absent du depot',
          );
          // LA MENTION CITE L'AUTEUR : une CC-BY respectee dans un JSON et
          // nulle part ailleurs n'est pas respectee.
          expect(photo.mention, contains(photo.auteur));
        }

        // UNE COUVERTURE, et c'est celle qui va sur la carte du catalogue.
        expect(fiche.couverture, isNotNull);
        expect(fiche.couverture!.couverture, isTrue);
      }
    });

    test('AUCUNE IMAGE ORPHELINE dans les dossiers de photos', () {
      // Une image presente mais non declaree pese dans le binaire sans jamais
      // s'afficher, et sans porter sa preuve. C'est le symetrique exact du cas
      // precedent.
      //
      // DECLAREE PAR N'IMPORTE QUELLE FICHE SUFFIT (tache 853) : une image du
      // dossier du GR20 peut n'etre declaree que par la fiche d'un de ses
      // chapitres, et elle n'est pas orpheline pour autant. Ce qui serait
      // inacceptable, c'est qu'AUCUNE fiche ne la declare.
      final declarees = {
        for (final (_, p) in photosDeclarees()) p.fichier.split('/').last,
      };
      for (final chemin in dossiersDePreuve()) {
        final dossier = Directory(chemin);
        expect(
          dossier.existsSync(),
          isTrue,
          reason: '$chemin : des images y sont declarees et il n existe pas',
        );
        for (final fichier in dossier.listSync().whereType<File>()) {
          final nom = fichier.path.replaceAll(r'\', '/').split('/').last;
          final bas = nom.toLowerCase();
          if (!bas.endsWith('.jpg') &&
              !bas.endsWith('.jpeg') &&
              !bas.endsWith('.png')) {
            continue;
          }
          expect(
            declarees,
            contains(nom),
            reason: '$chemin/$nom est dans les assets sans etre declare',
          );
        }
      }
    });

    test('CHAQUE FICHE A SA PROPRE COUVERTURE, ET PAS CELLE DU VOISIN', () {
      // LE DEFAUT QUE CE CAS INTERDIT, ET IL ETAIT REEL AVANT LA 853 : le sud
      // n'ayant pas de fiche, sa carte du catalogue s'ouvrait sur la couverture
      // du sentier mere, c'est-a-dire sur le lac de Capitello — qui est dans le
      // NORD. On vendait une moitie avec la photo de l'autre.
      final couvertures = <String, String>{};
      for (final entree in fichesDuCatalogue().entries) {
        final fiche = lireFicheDeSentier(
          File(entree.value).readAsStringSync(),
          entree.key,
        )!;
        expect(fiche.couverture, isNotNull, reason: entree.key);
        couvertures[entree.key] = fiche.couverture!.fichier;
      }
      // LES DEUX CHAPITRES DU GR20 N'OUVRENT PAS SUR LA MEME IMAGE.
      expect(couvertures['gr20-nord'], isNotNull);
      expect(couvertures['gr20-sud'], isNotNull);
      expect(
        couvertures['gr20-nord'],
        isNot(couvertures['gr20-sud']),
        reason: 'nord et sud ne peuvent pas partager leur couverture',
      );
    });

    test('UN CHAPITRE NE DECLARE QUE LES PHOTOS DE SON CHAPITRE', () {
      // LA REPARTITION N'EST PAS REINVENTEE PAR LA FICHE : elle est celle du
      // fonds, qui porte `chapitre_du_fonds` image par image. Ce cas verifie
      // que les deux ne divergent pas — une photo du sud dans la fiche du nord
      // montrerait au client un endroit qu'il n'ira pas voir.
      final provenance =
          jsonDecode(
                File(
                  'assets/data/gr20/photos/PROVENANCE.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final chapitreDe = <String, String>{
        for (final image
            in (provenance['images'] as List<dynamic>)
                .cast<Map<String, dynamic>>())
          image['fichier'] as String: image['chapitre_du_fonds'] as String,
      };

      for (final chapitre in <String>['gr20-nord', 'gr20-sud']) {
        final chemin = fichesDuCatalogue()[chapitre];
        expect(chemin, isNotNull, reason: '$chapitre declare une fiche');
        final fiche = lireFicheDeSentier(
          File(chemin!).readAsStringSync(),
          chapitre,
        )!;
        expect(fiche.photos.length, 6, reason: '$chapitre : six vues');
        for (final photo in fiche.photos) {
          expect(
            chapitreDe[photo.fichier.split('/').last],
            chapitre,
            reason: '${photo.fichier} n est pas une image de $chapitre',
          );
        }
      }
    });
  });

  group('848 — la preuve voyage avec l image', () {
    test('PROVENANCE.json et CHOIX_ET_REFUS.csv sont a cote des images', () {
      // A COTE DES IMAGES, et plus « a cote de la fiche » (tache 853). C'est ce
      // que le titre de ce cas dit depuis le debut, et c'est desormais ce qu'il
      // mesure : le dossier est deduit du chemin de l'IMAGE.
      final dossiers = dossiersDePreuve();
      expect(dossiers, isNotEmpty);
      for (final dossier in dossiers) {
        for (final preuve in <String>[
          'PROVENANCE.json',
          'CHOIX_ET_REFUS.csv',
          'LISEZ-MOI.txt',
        ]) {
          expect(
            File('$dossier/$preuve').existsSync(),
            isTrue,
            reason: '$dossier/$preuve manque : la preuve resterait dehors',
          );
        }
      }
    });

    test('LA PROVENANCE PORTE, PAR IMAGE, DE QUOI REFAIRE LA VERIFICATION', () {
      // LE PIVOT EST LE DOSSIER D'IMAGES, ET LE COMPTE SE FAIT AVEC CE QUI EST
      // SUR LE DISQUE (tache 853). L'ancienne egalite comparait le nombre
      // d'entrees de la preuve au nombre de photos d'UNE fiche ; elle n'a plus
      // de sens des qu'un dossier sert plusieurs fiches — la fiche d'un
      // chapitre en declare six quand la preuve en couvre douze. Ce qui doit
      // etre vrai, et qui est plus fort, c'est que la preuve couvre EXACTEMENT
      // les images presentes : aucune image sans preuve, aucune preuve sans
      // image.
      for (final dossier in dossiersDePreuve()) {
        final provenance =
            jsonDecode(File('$dossier/PROVENANCE.json').readAsStringSync())
                as Map<String, dynamic>;
        final images = (provenance['images'] as List<dynamic>)
            .cast<Map<String, dynamic>>();

        final surLeDisque = Directory(dossier)
            .listSync()
            .whereType<File>()
            .map((f) => f.path.replaceAll(r'\', '/').split('/').last)
            .where((n) {
              final bas = n.toLowerCase();
              return bas.endsWith('.jpg') ||
                  bas.endsWith('.jpeg') ||
                  bas.endsWith('.png');
            })
            .toSet();
        expect(
          images.map((i) => i['fichier'] as String).toSet(),
          surLeDisque,
          reason: '$dossier : la preuve et les images ne se recouvrent pas',
        );

        for (final image in images) {
          for (final champ in <String>[
            'fichier',
            'adresse_d_origine',
            'auteur',
            'licence',
            'adresse_de_la_licence',
            'mention_a_afficher',
            'conditions',
            'sha256',
          ]) {
            expect(
              (image[champ] as String?) ?? '',
              isNotEmpty,
              reason: '${image['fichier']} : champ « $champ » vide',
            );
          }
          // L'EMPREINTE EST CELLE DU FICHIER EMBARQUE, pas une promesse : on la
          // recalcule ici-meme.
          final fichier = File('$dossier/${image['fichier']}');
          expect(fichier.existsSync(), isTrue);
          expect(
            sha256Hex(fichier.readAsBytesSync()),
            (image['sha256'] as String).toLowerCase(),
            reason: '${image['fichier']} : empreinte differente',
          );
        }
      }
    });

    test('LE FICHIER DE REFUS NE PORTE QUE DES REFUS, ET IL EN PORTE', () {
      // Le tri doit rester LISIBLE dans le produit : vingt-deux images ont ete
      // examinees puis ecartees (filigrane, marque d'un tiers, personne
      // identifiable, lieu hors itineraire...). Un fichier de refus vide
      // laisserait croire que rien n'a ete ecarte.
      // LES FICHIERS DE REFUS SONT COMPTES UNE FOIS CHACUN (tache 853). Trois
      // fiches partagent desormais le dossier du GR20 ; sommer par fiche
      // compterait ses onze refus trois fois.
      var lignes = 0;
      for (final dossier in dossiersDePreuve()) {
        final csv = File('$dossier/CHOIX_ET_REFUS.csv').readAsLinesSync();
        expect(csv.first, contains('motif du refus'));
        for (final ligne in csv.skip(1)) {
          if (ligne.trim().isEmpty) continue;
          lignes++;
          expect(
            ligne,
            isNot(contains('RETENUE')),
            reason: 'le fichier de refus ne porte que les refus',
          );
        }
      }
      expect(lignes, 22, reason: 'les 22 refus du fonds de la tache 845');
    });
  });

  test('LES DOSSIERS DE PHOTOS SONT DECLARES AU PUBSPEC', () {
    // Les dossiers d'assets de Flutter ne sont PAS recursifs : declarer
    // `assets/data/gr20/` n'embarque pas `assets/data/gr20/photos/`. Sans cette
    // ligne, la fiche afficherait des cadres vides pour des images presentes
    // dans le depot et absentes du binaire.
    //
    // LE DOSSIER EST CELUI DES IMAGES (tache 853) : c'est lui qu'il faut
    // embarquer, pas celui de la fiche. Une fiche de chapitre qui declare les
    // images du sentier mere a besoin du dossier DU MERE au pubspec, et de rien
    // d'autre.
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final dossier in dossiersDePreuve()) {
      final relatif = '${dossier.substring(dossier.indexOf('assets/'))}/';
      expect(
        pubspec,
        contains('- $relatif'),
        reason: '$relatif n est pas declare au pubspec',
      );
    }
    // ET LE DOSSIER DE DONNEES DE CHAQUE FICHE AUSSI, sinon le fichier
    // `fiche.json` lui-meme n'entre pas dans le binaire et le lecteur rend
    // `null` sans rien dire : exactement l'etat d'avant ce lot.
    for (final chemin in fichesDuCatalogue().values) {
      final dossier = '${File(chemin).parent.path.replaceAll(r'\', '/')}/';
      final relatif = dossier.substring(dossier.indexOf('assets/'));
      expect(
        pubspec,
        contains('- $relatif'),
        reason: '$relatif n est pas declare au pubspec',
      );
    }
  });
}

/// Un refus, dit en clair dans le message d'echec.
String _decrire(PhotoRefusee refus) => '${refus.fichier} (${refus.motif.name})';

/// SHA-256 en hexadecimal minuscule — la meme empreinte que le manifeste.
String sha256Hex(List<int> octets) =>
    sha256.convert(octets).toString().toLowerCase();
