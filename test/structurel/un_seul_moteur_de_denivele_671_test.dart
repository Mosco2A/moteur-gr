// GARDE DE PLAFOND — PAS DE QUATRIEME MOTEUR DE DENIVELE (lot 671-06).
//
// CE QUE LA REGLE DIT. Dans `lib/`, le denivele se cumule a UN seul endroit :
// `computeTrackStatsOn` (`lib/core/geo/track_segment_stats.dart`), le moteur
// partage par la carte, le journal et le recapitulatif. Deux implantations
// finiraient par donner deux deniveles differents pour la meme journee.
//
// CE QUE LA GARDE COMPTE. Un cumul de denivele se reconnait a son coeur : il
// compare une DIFFERENCE D'ALTITUDE, en valeur absolue, a un SEUIL DE BRUIT.
// La garde compte donc, dans le code de `lib/` (commentaires exclus), les
// comparaisons d'un `.abs()` a :
// - un seuil de bruit nomme (`elevationNoiseThresholdM`, quel que soit son
//   prefixe : `GeoUtils.`, une constante locale, un champ) ;
// - un litteral de seuil equivalent, un nombre de 1 a 10 — le bruit d'un
//   altimetre se compte en metres. Les `.abs() > 90` et `> 180` d'une
//   latitude ou d'une longitude n'en sont pas.
// SA LIMITE, ECRITE : un cumul ecrit sans `.abs()` (`d > 3 || d < -3`) ne
// serait pas vu. La garde ne pretend pas tout voir ; elle voit la forme que
// les trois moteurs du depot ont tous prise.
//
// POURQUOI ELLE EXISTE : LA GARDE QUE LA CONCEPTION CROYAIT AVOIR N'EXISTAIT
// PAS. La conception du lot 671-06 tenait que `aucun_doublon_645_test.dart`
// couvrait le risque d'un second moteur de statistiques. Mesure du
// 07/10/2026 : cette garde compte des NOMS de fichiers et de classes, elle ne
// sait pas lire une boucle de cumul ; un moteur de plus, dans un fichier au
// nom neuf, passait sans un bruit. LA PREUVE QUE LE TROU ETAIT DEJA PAYE :
// `lib/` portait ce jour-la TROIS sites, et non un.
//
// LE PLAFOND EST 3, ET 3 EST UNE DETTE CONNUE, PAS UNE NORME :
// - `lib/core/geo/track_segment_stats.dart` — le vrai moteur, le seul vivant ;
// - `lib/domain/trek_stats.dart` (`TrekStats`, le cumul de `addPoint`) —
//   INERTE : `addPoint` n'a aucun appelant, et `trekStatsProvider` rend un
//   `TrekStats` construit vide ;
// - `lib/features/trek/domain/post_trek_stats.dart`
//   (`PostTrekStatsCalculator._cumulativeElevation`) — INERTE : aucun
//   appelant dans `lib/`, et il porte SA PROPRE COPIE EN DUR du seuil de 3 m
//   au lieu de lire `GeoUtils.elevationNoiseThresholdM`.
// Le lot 671-06 ne les retire pas : ce n'est pas son lot. LE JOUR OU
// QUELQU'UN LES RETIRERA, LE PLAFOND DESCENDRA A 1. Il ne remonte JAMAIS.
library;

import 'package:flutter_test/flutter_test.dart';

import 'mesure_des_sources_645.dart';

/// Mesure du 07/10/2026, tete fabb1ec2 : trois sites, dont deux inertes.
const plafondCumulsDeDenivele = 3;

/// Le seul site legitime, et celui que la garde doit toujours voir.
const moteurAttendu = 'lib/core/geo/track_segment_stats.dart';

/// Un `.abs()` compare a un seuil de bruit nomme, ou a un litteral de 1 a
/// 10 (decimales comprises).
final motifCumulDeDenivele = RegExp(
  r'\.abs\(\)\s*(?:>=|<=|<|>)\s*'
  r'(?:(?:[A-Za-z_]\w*\.)?\w*[Nn]oise[Tt]hreshold\w*'
  r'|(?:10|[1-9])(?:\.\d+)?\b(?!\.\d))',
);

/// Les sites de [motifCumulDeDenivele] dans le CODE de `lib/`.
List<String> sitesDeCumul() {
  final sites = <String>[];
  for (final chemin in sourcesLib()) {
    final lignes = lignesDe(chemin);
    for (var i = 0; i < lignes.length; i++) {
      if (estLigneDeCommentaire(lignes[i])) continue;
      if (motifCumulDeDenivele.hasMatch(lignes[i])) {
        sites.add('$chemin:${i + 1}');
      }
    }
  }
  return sites;
}

void main() {
  group('671-06 — un seul moteur de denivele', () {
    test('au plus $plafondCumulsDeDenivele sites de lib/ comparent une '
        'difference d altitude a un seuil de bruit', () {
      final sites = sitesDeCumul();
      expect(
        sites.length,
        lessThanOrEqualTo(plafondCumulsDeDenivele),
        reason:
            'UN MOTEUR DE DENIVELE DE PLUS : ${sites.length} sites comparent '
            'une difference d altitude a un seuil de bruit, plafond '
            '$plafondCumulsDeDenivele (dont deux inertes, une dette connue). '
            'Le denivele se calcule dans computeTrackStatsOn, et nulle part '
            'ailleurs : donnez-lui votre suite de points au lieu d ecrire un '
            'second cumul :\n${sites.join('\n')}',
      );
    });

    test('LA GARDE MESURE VRAIMENT : le moteur est vu, les formes connues sont '
        'reconnues, une latitude et un commentaire ne comptent pas', () {
      // UNE GARDE QUI NE VOIT PLUS RIEN PASSE AU VERT EN SILENCE.
      expect(
        sitesDeCumul().where((s) => s.startsWith('$moteurAttendu:')),
        hasLength(1),
        reason: 'le vrai moteur n est plus vu : le motif ou le parcours casse',
      );
      for (final forme in [
        'if (d.abs() >= GeoUtils.elevationNoiseThresholdM) {',
        'if (altDiff.abs() >= elevationNoiseThresholdM) {',
        'if (diff.abs() < elevationNoiseThresholdM) continue;',
        'if (delta.abs() >= 3) {',
        'if (delta.abs() > 3.0) {',
        'if ((b - a).abs() >= 5) {',
        'if (d.abs() >= 2.5) {',
      ]) {
        expect(
          motifCumulDeDenivele.hasMatch(forme),
          isTrue,
          reason: 'forme non reconnue : $forme',
        );
      }
      for (final pasUnCumul in [
        'if (latitude.abs() > 90 || longitude.abs() > 180) return false;',
        'if (x.abs() < 0.5) {',
        'if (v.abs() > 15.5) {',
      ]) {
        expect(
          motifCumulDeDenivele.hasMatch(pasUnCumul),
          isFalse,
          reason: 'faux positif : $pasUnCumul',
        );
      }
      expect(
        estLigneDeCommentaire(
          '  // if (d.abs() >= GeoUtils.elevationNoiseThresholdM)',
        ),
        isTrue,
      );
    });
  });
}
