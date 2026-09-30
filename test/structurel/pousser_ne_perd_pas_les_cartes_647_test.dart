import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// GARDE STRUCTURELLE — « POUSSER » NE PEUT PLUS EFFACER LA CARTE HORS LIGNE
/// (integration 647, piege remonte en base #100943).
///
/// LE PIEGE, ET IL ETAIT SILENCIEUX. Deux outils ecrivent le MEME document
/// Firestore, `trails/{id}` :
///   * `tool/publier_en_base.py` (lot 641) y pose la fiche du catalogue — nom,
///     prix, distance, `data_version` ;
///   * `tool/cartes_hors_ligne/publier.py` (lot 648) y pose l adresse de la
///     carte hors ligne : `tiles_path`, `tiles_size`, `tiles_hash`.
///
/// Or le premier ecrivait par `PATCH` SANS `updateMask`. L API REST de Firestore
/// est explicite la-dessus : sans masque, les champs presents dans le document
/// et absents du corps de la requete sont SUPPRIMES. Le prochain « pousser »
/// aurait donc efface les trois champs de la carte — et l application aurait
/// cesse de trouver la carte hors ligne du Mare a Mare Centre sans un message,
/// sans une erreur, et sans que personne n ait touche au code de la carte. Le
/// genre de panne qu on cherche trois jours.
///
/// LA GARDE TIENT LES TROIS MAILLONS, parce qu il suffit d en casser un :
///   1. l outil construit un `updateMask` depuis les champs qu il envoie — il ne
///      detruit plus ce qu il ne porte pas ;
///   2. l outil PORTE quand meme les trois champs quand le manifeste les declare,
///      et il les envoie A PLAT et en snake_case, comme la carte les a poses ;
///   3. le manifeste publie les declare vraiment, pour le Mare a Mare Centre.
///
/// CE QU ELLE NE FAIT PAS : toucher au reseau. Elle lit le depot, et c est
/// exactement ce qu il faut pour empecher qu un geste futur rouvre le piege.
void main() {
  group('647 — « pousser » ne peut plus effacer la carte hors ligne', () {
    final outil = File('tool/publier_en_base.py');
    final manifeste = File('publication/publie/manifest.json');

    test('les deux fichiers existent la ou la garde les attend', () {
      expect(outil.existsSync(), isTrue, reason: outil.path);
      expect(manifeste.existsSync(), isTrue, reason: manifeste.path);
    });

    test(
      '1. l ecriture porte un updateMask construit sur les champs envoyes',
      () {
        final source = outil.readAsStringSync();
        expect(
          source,
          contains('updateMask.fieldPaths'),
          reason:
              'un PATCH Firestore sans updateMask REMPLACE le document : tout ce '
              'que cet outil ne porte pas serait supprime',
        );

        // LE MASQUE EST DERIVE DES CHAMPS, PAS ECRIT EN DUR. Un masque fige
        // rouvrirait le piege des qu un champ s ajouterait.
        final ecrire = _corpsDeLaMethode(source, 'def ecrire(');
        expect(
          ecrire,
          isNotNull,
          reason: 'la methode ecrire() de la classe Firestore doit exister',
        );
        expect(
          ecrire,
          contains('for nom in champs'),
          reason: 'le masque se construit depuis les champs reellement envoyes',
        );
      },
    );

    test('2. l outil porte les trois champs de la carte, a plat et en serpent', () {
      final source = outil.readAsStringSync();
      for (final champ in const ['tilesPath', 'tilesSize', 'tilesHash']) {
        expect(
          source,
          contains(champ),
          reason:
              '$champ doit etre repris du manifeste vers la fiche du catalogue',
        );
      }
      expect(
        source,
        contains('en_serpent'),
        reason:
            'la carte a pose tiles_path / tiles_size / tiles_hash en snake_case : '
            'l outil doit republier les memes noms, pas du camelCase',
      );
    });

    test('3. le manifeste publie declare la carte du Mare a Mare Centre', () {
      final donnees =
          jsonDecode(manifeste.readAsStringSync()) as Map<String, dynamic>;
      final sentiers = (donnees['trails'] as List).cast<Map<String, dynamic>>();
      final mareAMare = sentiers.firstWhere(
        (t) => t['trailId'] == 'mare-a-mare-centre',
        orElse: () =>
            throw StateError('mare-a-mare-centre absent du manifeste'),
      );

      expect(
        mareAMare['tilesPath'],
        'mare_a_mare_centre/tuiles_z10-15_v20260930T154231Z.mbtiles',
      );
      expect(mareAMare['tilesSize'], 26955776);
      expect(
        mareAMare['tilesHash'],
        'ed7f445095bb710cde6de51e51980b8ad5884f5d5825fbdefb4fa09a142b8676',
      );
    });
  });
}

/// Le corps d une methode Python, de son `def` jusqu au prochain `def` de meme
/// niveau. Suffisant pour lire UNE methode sans analyser tout le fichier.
String? _corpsDeLaMethode(String source, String entete) {
  final debut = source.indexOf(entete);
  if (debut < 0) return null;
  final suite = source.indexOf('\n    def ', debut + entete.length);
  return suite < 0 ? source.substring(debut) : source.substring(debut, suite);
}
