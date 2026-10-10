/// LA GARDE QUI REFUSE UNE TRACE TROP PAUVRE (tache 761).
///
/// CE QU ELLE FERME, ET C EST CHRISTOPHE QUI L A VU AVANT NOUS. Verbatim du
/// 10/10 : « Dans GR20 on voyait le trace PRECIS du chemin, le randonneur se
/// deplacait sur ce CHEMIN. La ce sont des traits traces a la regle. » Il avait
/// raison, et ce n etait pas l affichage : la trace du Mare a Mare Centre
/// comptait 53 points pour 72,9 km, soit un point tous les 1,1 km (median).
/// Entre deux points espaces d un kilometre, il n y a RIEN a suivre — la carte
/// relie en ligne droite et le marcheur simule coupe a travers la montagne.
/// Aucun correctif de code ne fait suivre un chemin qui n est pas decrit : le
/// defaut etait dans la DONNEE, et seule une garde sur la donnee l empeche de
/// revenir.
///
/// LE SEUIL, ET POURQUOI CELUI-LA. Il n est pas choisi au gout : c est
/// [kOffTrackReturnThresholdMeters], le seuil auquel l application declare le
/// marcheur REVENU sur le chemin (50 m). Le detecteur de sortie de trace
/// mesure la distance du marcheur a la POLYLIGNE, pas au chemin reel. Entre
/// deux points de trace, la polyligne est une corde tendue alors que le
/// sentier, lui, fait
/// le tour du relief : dans le pire cas — un lacet pris entre deux points — le
/// chemin reel s ecarte de la corde de la moitie de l espacement. Si
/// l espacement MEDIAN atteignait 50 m, la moitie du sentier porterait une
/// erreur de discretisation capable d atteindre a elle seule le seuil de
/// retour : l application ne saurait plus distinguer « revenu sur le chemin »
/// de « encore a cote ». Sous 50 m de median, cette erreur reste inferieure
/// au seuil sur au
/// moins la moitie du sentier — et tres en dessous en pratique. Le seuil suit
/// donc la constante : si le detecteur change d avis, la garde change avec lui.
///
/// LES TROIS MESURES QUI L ENCADRENT, toutes faites a la main avant d ecrire ce
/// fichier :
///   * la trace du GR20 (`projets/interne/GR20`, 8 854 points pour 182,8 km) :
///     espacement median 15,2 m — elle PASSE. C est la reference de qualite
///     citee par Christophe. Elle vit dans un autre depot, donc ce test ne peut
///     pas la lire ; la mesure est rapportee ici et non supposee.
///   * la nouvelle trace du Mare a Mare Centre (3 590 points pour 87,3 km) :
///     espacement median 19,2 m — elle PASSE.
///   * l ANCIENNE trace (53 points pour 72,9 km), conservee en temoin dans
///     `test/fixtures/gpx/mare_a_mare_centre_avant_761.gpx` : espacement median
///     1 078,7 m — elle ROUGIT, et le troisieme test le prouve. Sans ce temoin,
///     la garde affirmerait quelque chose que rien ne verifie.
///
/// IL N Y A PLUS AUCUNE EXEMPTION, ET LA TACHE 793 L A RENDUE INUTILE. Ce
/// fichier dispensait nominativement `test-trail` (« Sentier des Volcans »)
/// de la regle de densite, au motif — juste — qu il n existe aucun chemin reel
/// a relever pour un sentier qui n existe pas. Le raisonnement etait bon et la
/// conclusion fausse : si un sentier n a aucun chemin a suivre, ce n est pas
/// la GARDE qu il faut assouplir, c est le SENTIER qu il ne faut pas mettre au
/// catalogue. Il y etait pourtant, et achetable a 4,95 EUR.
///
/// CETTE EXEMPTION ETAIT DONC LA DERNIERE PORTE, et elle est refermee. Le
/// sentier fictif est sorti du catalogue (`TrailConfig.isFictional` +
/// `TrailCatalog.all`), la boucle ci-dessous ne le rencontre plus, et la carte
/// des dispenses est VIDE. Elle reste declaree, car c est le fait qui compte :
/// tout sentier que le randonneur peut voir doit porter une trace relevee, sans
/// exception nommable. Si un futur sentier devait en demander une, il faudrait
/// d abord se demander ce qu il fait au catalogue.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/trail_catalog.dart';
import 'package:moteur_gr/core/geo/trace_point.dart';
import 'package:moteur_gr/features/map/domain/off_track_detector.dart';
import 'package:moteur_gr/features/trek/data/gpx_parser.dart';

/// Les sentiers dispenses de la regle, avec la raison qui les en dispense.
///
/// VIDE DEPUIS LA TACHE 793, et ce vide est le resultat : la seule entree
/// dispensait le sentier fictif, qui n est plus au catalogue. Aucun sentier
/// visible par le randonneur n echappe desormais a la densite de trace.
const Map<String, String> kSentiersSansCheminReel = <String, String>{};

/// L espacement MEDIAN entre points consecutifs, en metres.
///
/// Le median et non la moyenne : une trace peut etre fine sur dix kilometres et
/// sauter une vallee entiere une fois, auquel cas la moyenne absout le saut. Le
/// median dit ce que le marcheur rencontre la MOITIE du temps, et c est ce qui
/// decide si la ligne dessinee ressemble au chemin.
double espacementMedianM(List<TrackPoint> points) {
  expect(
    points.length,
    greaterThan(1),
    reason: 'une trace d un seul point n a pas d espacement',
  );
  final ecarts = <double>[
    for (var i = 0; i < points.length - 1; i++)
      points[i + 1].distanceFromStart - points[i].distanceFromStart,
  ]..sort();
  final milieu = ecarts.length ~/ 2;
  return ecarts.length.isOdd
      ? ecarts[milieu]
      : (ecarts[milieu - 1] + ecarts[milieu]) / 2;
}

List<TrackPoint> _lire(String chemin) {
  final fichier = File(chemin);
  expect(
    fichier.existsSync(),
    isTrue,
    reason: '$chemin est declare mais absent du depot',
  );
  return GpxParser.parse(fichier.readAsStringSync()).allTrackPoints;
}

void main() {
  group('la densite de la trace', () {
    test('aucun sentier reel du catalogue ne descend sous le seuil', () {
      var examines = 0;
      for (final sentier in TrailCatalog.all) {
        if (sentier.gpxAssetPath.isEmpty) continue;
        final dispense = kSentiersSansCheminReel[sentier.id];
        if (dispense != null) continue;

        final median = espacementMedianM(_lire(sentier.gpxAssetPath));
        examines++;
        expect(
          median,
          lessThan(kOffTrackReturnThresholdMeters),
          reason:
              'la trace de ${sentier.id} (${sentier.gpxAssetPath}) a un '
              'espacement median de ${median.toStringAsFixed(1)} m, au-dela du '
              'seuil de retour sur trace de '
              '${kOffTrackReturnThresholdMeters.toStringAsFixed(0)} m. Entre '
              'deux points aussi espaces, la carte relie en ligne droite et le '
              'marcheur coupe a travers le relief : il n y a rien a suivre. Il '
              'faut une trace relevee, pas un croquis.',
        );
      }
      expect(
        examines,
        greaterThan(0),
        reason:
            'la garde n a examine aucun sentier : elle ne garde plus rien. '
            'Verifier que le catalogue declare encore une trace embarquee.',
      );
    });

    test(
      'la nouvelle trace du Mare a Mare Centre tient ses trois chiffres',
      () {
        final points = _lire('assets/data/mare_a_mare_centre/track.gpx');

        expect(
          points.length,
          3590,
          reason:
              'la trace relevee dans OpenStreetMap (relation 10032398) porte '
              '3 590 points ; un autre compte veut dire qu elle a ete '
              'reechantillonnee ou remplacee',
        );
        expect(
          points.last.distanceFromStart / 1000,
          closeTo(87.284, 0.01),
          reason: 'la longueur mesuree du sentier est de 87,284 km',
        );
        expect(
          espacementMedianM(points),
          closeTo(19.2, 0.1),
          reason: 'l espacement median mesure est de 19,2 m',
        );
      },
    );

    test('elle rougit sur l ancienne trace, et le temoin le prouve', () {
      final avant = _lire('test/fixtures/gpx/mare_a_mare_centre_avant_761.gpx');

      expect(
        avant,
        hasLength(53),
        reason: 'le temoin est bien la trace d avant',
      );
      final median = espacementMedianM(avant);
      expect(
        median,
        closeTo(1078.7, 1.0),
        reason: 'l ancienne trace portait un point tous les 1 078,7 m (median)',
      );
      // LE COEUR DE LA GARDE : sans cette ligne, le seuil pourrait etre pose si
      // haut que plus rien ne le franchirait jamais.
      expect(
        median,
        greaterThan(kOffTrackReturnThresholdMeters),
        reason:
            'la garde doit refuser l ancienne trace, sinon elle ne garde rien',
      );
    });
  });
}
