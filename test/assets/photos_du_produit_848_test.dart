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

/// Les sentiers du catalogue qui declarent une fiche, et le dossier d'assets
/// ou cette fiche vit.
Map<String, String> fichesDuCatalogue() => <String, String>{
  for (final config in TrailCatalog.all)
    if ((config.ficheAssetPath ?? '').isNotEmpty)
      config.id: config.ficheAssetPath!,
};

void main() {
  test('AU MOINS UN SENTIER PORTE DES PHOTOS', () {
    // CE CAS EST LA SENTINELLE DES AUTRES. Tous les cas ci-dessous bouclent sur
    // les photos declarees : si plus aucune n'etait declaree, ils passeraient
    // tous en ne verifiant RIEN. La tache 846 a livre le lecteur avec des
    // manifestes VIDES ; la 848 y fait entrer dix-huit images.
    var total = 0;
    for (final chemin in fichesDuCatalogue().values) {
      final brut =
          jsonDecode(File(chemin).readAsStringSync()) as Map<String, dynamic>;
      total += (brut['photos'] as List<dynamic>).length;
    }
    expect(total, 18, reason: 'les 18 images du fonds de la tache 845');
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
      for (final entree in fichesDuCatalogue().entries) {
        final fiche = lireFicheDeSentier(
          File(entree.value).readAsStringSync(),
          entree.key,
        )!;
        final declarees = fiche.photos.map((p) => p.fichier).toSet();
        final dossier = Directory('${File(entree.value).parent.path}/photos');
        if (!dossier.existsSync()) continue;
        for (final fichier in dossier.listSync().whereType<File>()) {
          final chemin = fichier.path.replaceAll(r'\', '/');
          if (!chemin.toLowerCase().endsWith('.jpg') &&
              !chemin.toLowerCase().endsWith('.jpeg') &&
              !chemin.toLowerCase().endsWith('.png')) {
            continue;
          }
          expect(
            declarees.any((d) => chemin.endsWith(d.split('/').last)),
            isTrue,
            reason: '$chemin est dans les assets sans etre declare',
          );
        }
      }
    });
  });

  group('848 — la preuve voyage avec l image', () {
    test('PROVENANCE.json et CHOIX_ET_REFUS.csv sont a cote des images', () {
      for (final chemin in fichesDuCatalogue().values) {
        final dossier = '${File(chemin).parent.path}/photos';
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
      for (final entree in fichesDuCatalogue().entries) {
        final dossier = '${File(entree.value).parent.path}/photos';
        final provenance =
            jsonDecode(File('$dossier/PROVENANCE.json').readAsStringSync())
                as Map<String, dynamic>;
        final images = (provenance['images'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        final fiche = lireFicheDeSentier(
          File(entree.value).readAsStringSync(),
          entree.key,
        )!;
        expect(images.length, fiche.photos.length);

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
      var lignes = 0;
      for (final chemin in fichesDuCatalogue().values) {
        final csv = File(
          '${File(chemin).parent.path}/photos/CHOIX_ET_REFUS.csv',
        ).readAsLinesSync();
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
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final chemin in fichesDuCatalogue().values) {
      final dossier =
          '${File(chemin).parent.path.replaceAll(r'\', '/')}/photos/';
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
