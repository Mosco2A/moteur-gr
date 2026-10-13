/// LA GARDE QUI REFUSE UN LIEU POSE A COTE DU CHEMIN (tache 775).
///
/// CE QU ELLE FERME, ET C EST ENCORE CHRISTOPHE QUI L A VU. Verbatim du 10/10 :
/// « j ai l impression que les POI de mare a mare ne sont pas au bon endroit ».
/// Il avait raison et la recette 778 l avait vu a l ecran : la source bleue
/// flottait nettement hors trace. Mesure avant ce lot : 18 des 20 points
/// d interet de la carte etaient a plus de 500 m de la trace reelle, ecart
/// MEDIAN 1 596 m, pire cas 7 128 m.
///
/// CE N EST PAS EUX QUI ONT BOUGE, C EST LE CHEMIN QUI EST ARRIVE. Ces lieux
/// ont ete poses du temps ou la trace etait un croquis de 53 points coupant les
/// virages en ligne droite. Le lot 761 a remplace le croquis par la vraie trace
/// — 3 590 points releves dans OpenStreetMap — et les lieux sont restes ou ils
/// etaient. Aucun correctif d affichage ne rapproche un lieu dont la coordonnee
/// est fausse : le defaut est dans la DONNEE, et seule une garde sur la donnee
/// l empeche de revenir.
///
/// LE SEUIL, ET POURQUOI CELUI-LA. Il n est pas choisi au gout : c est
/// [StageDetector.toleranceRadiusM] (200 m), le rayon dans lequel
/// l application accepte d attribuer une position aux bornes d une etape. Or
/// CHAQUE lieu de cette donnee porte une etape (`stageId` / `stageNumber`).
/// Un lieu rattache a une etape mais pose plus loin que le rayon dans lequel
/// l application reconnait cette etape est un lieu que l application elle-meme
/// refuserait d y rattacher. Le seuil SUIT donc la constante : si le detecteur
/// d etape change d avis, la garde change avec lui.
///
/// L AUTRE BOUT DE L ARGUMENT, mesure et non suppose : l application declare le
/// marcheur SORTI du chemin au-dela de [kOffTrackExitThresholdMeters] (80 m).
/// Le seuil de la garde est donc deja deux fois et demie la distance a laquelle
/// l application considere qu on a quitte le sentier — large, pas serre. Et le
/// releve le confirme : sur les 406 objets reels releves dans le corridor de la
/// relation OSM 10032398, le mobilier de bord de chemin (panneaux
/// d information, eau potable, fontaines, sources — 48 objets) a un ecart
/// MEDIAN de 12 m, et sur les 12 cols que le sentier franchit par definition,
/// 10 sont a moins de 2 m de la trace. Quand un lieu est vraiment sur le
/// chemin, OSM le pose a quelques metres. Pas a quelques kilometres.
///
/// LA DEUXIEME REGLE, ET ELLE A ATTRAPE CE QUE LA DISTANCE LAISSAIT PASSER. Un
/// ecart faible ne dit PAS que le lieu est au bon endroit : « Gite de
/// Quasquara » (mam-acc-06) etait a 97 m de la trace — et a douze kilometres
/// de Quasquara le long du sentier, projete dans l etape 3 au lieu de
/// l etape 4. La garde exige
/// donc aussi que chaque lieu se projette DANS l etape qu il declare, avec la
/// meme tolerance d arc aux bornes (un lieu du village d arrivee peut tomber
/// quelques dizaines de metres au-dela de la coupure).
///
/// LE CAS LEGITIME DU VILLAGE D ETAPE EST PREVU, ET IL EST MESURE. Un sentier
/// de la mer a la mer part d une plage et le village est dans les terres :
/// Ghisonaccia est a 4 221 m de la trace, Santa-Maria-Sicche a 2 683 m, Bisinao
/// a 1 108 m — alors que Catastaghju est a 7 m, Serra-di-Fiumorbo a 25 m,
/// Quasquara a 23 m, Porticcio a 46 m, Cozzano a 69 m et Guitera a 148 m. Le
/// gite d un village eloigne est donc legitimement loin du chemin. Il n a pas
/// pour autant droit a un seuil plus large : il est NOMME dans
/// [kLieuxLegitimementLoinDuChemin] avec sa raison et sa source. Un seuil de
/// quatre kilometres ne garderait plus rien ; une liste nommee se lit dans un
/// diff.
///
/// CE QUE LA GARDE NE MESURE PAS, ET POURQUOI C EST VERROUILLE. Les 19 points
/// ajoutes par l etage editorial (`pois_ajoutes`) sont des lieux D ACCES et de
/// RAVITAILLEMENT : un arret d autocar dans le bourg de Ghisonaccia, l aeroport
/// d Ajaccio a 3 733 m, une gare, des commerces de village. Ils sont loin du
/// chemin par NATURE — c est ce qui les rend utiles — et leur imposer le seuil
/// n aurait aucun sens. Mais le trou doit rester ferme : un test verifie que
/// cette famille ne contient QUE des prefixes d acces et de ravitaillement
/// ([kFamillesHorsChemin]). Personne ne peut y glisser une fontaine pour
/// echapper a la mesure.
///
/// LE TEMOIN, SANS QUOI LA GARDE N AFFIRMERAIT RIEN. Les trois fichiers d avant
/// ce lot sont conserves dans `test/fixtures/lieux/` et le dernier test prouve
/// qu ils ROUGISSENT : 19 des 20 points de la carte y depassent le seuil. Sans
/// ce temoin, le seuil pourrait etre pose si haut que plus rien ne le
/// franchirait.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/geo/stage_detector.dart';
import 'package:moteur_gr/core/geo/trace_point.dart';
import 'package:moteur_gr/core/geo/track_projection.dart';
import 'package:moteur_gr/features/map/domain/off_track_detector.dart';
import 'package:moteur_gr/features/trek/data/gpx_parser.dart';

/// L ecart maximal admis entre un lieu du sentier et sa trace.
///
/// Il SUIT [StageDetector.toleranceRadiusM] : voir l en-tete.
double get ecartMaxDuLieuAuCheminM => StageDetector.toleranceRadiusM;

/// Les bornes d etape du Mare a Mare Centre, en metres d abscisse curviligne,
/// telles que le lot 761 les a publiees.
const List<double> kBornesDEtapeM = <double>[
  0,
  19934,
  34846,
  48525,
  58179,
  66280,
  76153,
  87284,
];

/// LES LIEUX DISPENSES DE LA REGLE DE DISTANCE, chacun avec sa raison.
///
/// Trois familles, et aucune n est un passe-droit :
///   * le lieu EXISTE et il est reellement loin du chemin (thermes au fond
///     d une vallee, village d etape dans les terres) : sa coordonnee est
///     relevee, l ecart est un fait sur le lieu ;
///   * le lieu N A PAS D OBJET CORRESPONDANT sur le terrain cartographique :
///     il est laisse ou il est, jamais deplace au juge ;
///   * l ETABLISSEMENT N EST PAS IDENTIFIE par une source publique (constat
///     deja fait au lot 761) : sa coordonnee est heritee et non sourcee. Ce
///     sont des lieux a retirer ou a documenter — decision de Christophe, pas
///     d un agent.
const Map<String, String> kLieuxLegitimementLoinDuChemin = <String, String>{
  // --- Le lieu existe et il est vraiment la-bas ---
  'mam-c-poi-08':
      'LES BAINS DE GUITERA SONT REELLEMENT DANS LA VALLEE DU TARAVO, en '
      'contrebas du village que le sentier traverse. Coordonnee relevee : OSM '
      'node 5746820140 (natural=spring, « Source Thermale des Bains de '
      'Guitera »), a 1 922 m de la trace. L ecart est un fait sur le lieu, pas '
      'une erreur de donnee.',
  'mam-poi-05':
      'meme lieu que mam-c-poi-08 dans l espace de noms de la publication : '
      'OSM node 5746820140, 1 922 m.',
  'mam-poi-11':
      'VILLAGE D ETAPE DANS LES TERRES. Coordonnee relevee : OSM node '
      '1877120458 (place=hamlet, « Santa-Maria-Sicche »), a 2 683 m de la '
      'trace — le sentier passe sous le village.',
  'mam-acc-07':
      'hebergement du village d etape de Santa-Maria-Sicche, recale sur le '
      'lieu reel (OSM node 1877120458, 2 683 m). L etablissement lui-meme '
      'reste non identifie : le lot 761 notait deja qu aucun gite d etape n y '
      'est annonce.',
  'mam-acc-17':
      'hebergement du village de Campo, recale sur le lieu reel (OSM node '
      '1624369843, place=village, a 907 m de la trace).',
  'mam-acc-13':
      'LE CAMPING EXISTE ET IL EST AU BORD DE MER. Coordonnee relevee : OSM '
      'way 1559412066 (tourism=camp_site, « Marina d Erba Rossa », route de la '
      'Mer, Ghisonaccia), a 4 730 m de la trace. L ecart a AUGMENTE en passant '
      'a la coordonnee vraie (4 249 m avant) : c est la mesure qui etait '
      'flatteuse, pas la donnee qui etait bonne.',

  // --- Aucun objet correspondant sur le terrain cartographique ---
  'mam-c-poi-14':
      'AUCUNE CHATAIGNERAIE RELEVEE. Les quatre vergers (landuse=orchard) du '
      'secteur sont a 2 375 m au moins de la trace et aucun ne porte d espece. '
      'Le lieu est laisse ou il est (1 158 m) : lui inventer un emplacement '
      'serait la meme faute que celle qu on repare.',
  'mam-poi-07':
      'meme constat que mam-c-poi-14 pour la chataigneraie de Quasquara '
      '(1 158 m).',
  'mam-c-poi-16':
      'AUCUNE BERGERIE RELEVEE SUR L ETAPE 6. « Bergerie de Tolla » existe '
      'bien (OSM way 120874153, tourism=camp_site) mais a 25 120 m de cette '
      'trace, a '
      'Vivario ; la commune de Tolla (OSM relation 2162149) est a 7 396 m. La '
      'deplacer sur son objet reel EMPIRERAIT l ecart. Laissee a 4 581 m.',
  'mam-poi-12':
      '« Maquis corse » ne designe aucun objet cartographique nomme : c est '
      'une '
      'vegetation, pas un lieu. Laisse a 852 m.',
  'mam-poi-03':
      'LES BERGERIES DE CAPANNELLE NE SONT PAS SUR CE SENTIER : l objet reel '
      '(OSM node 5410456473, place=isolated_dwelling, commune de Ghisoni) est '
      'a 13 895 m de la trace — c est une etape du GR20. La publication le '
      'RETIRE '
      'deja avec cette raison (cle pois_retires de '
      'publication/contenu/mare-a-mare-centre.json), il ne part donc jamais en '
      'base. Laisse a 1 243 m dans l asset.',

  'mam-info-02':
      'CONSEIL D ACCES, PAS UN LIEU DU CHEMIN : ou reserver ses nuits, '
      'rattache '
      'au bourg de Ghisonaccia (OSM relation 76886, a 4 221 m de la trace). Il '
      'est de type « info » et non d une famille d acces, donc il est nomme '
      'ici '
      'plutot que dispense par son prefixe.',

  // --- Seul objet releve de son etape, juste au-dela du seuil ---
  'mam-c-poi-18':
      'SEULE FONTAINE RELEVEE DE L ETAPE 6 : OSM node 12118989530 '
      '(amenity=fountain, drinking_water=yes, « Fontaine Saint Georges »), au '
      'Col Saint-Georges, a 207 m — sept metres au-dela du seuil. Le seuil ne '
      'se desserre pas pour sept metres et le lieu ne se deplace pas vers un '
      'objet qui n existe pas : il est nomme ici.',

  // --- Etablissement non identifie par aucune source publique ---
  'mam-acc-02':
      'ETABLISSEMENT NON IDENTIFIE : aucun objet OSM nomme « camping '
      'municipal » a Ghisonaccia. Les deux campings releves pres du depart '
      'sont '
      'Campu Serenu (OSM way 1000065959, 1 854 m) et Via Romana (OSM way '
      '1000066049, 1 094 m), ni l un ni l autre municipal. Le lot 761 notait '
      'deja l absence de source publique. Coordonnee heritee, 4 342 m.',
  'mam-acc-05':
      'ETABLISSEMENT NON IDENTIFIE : aucun objet OSM « camping les Thermes de '
      'Guitera ». Le lot 761 notait deja l absence de source publique. '
      'Coordonnee heritee, 2 248 m.',
  'mam-acc-08':
      'COTI-CHIAVARI N EST PAS SUR L ITINERAIRE : le village (OSM node '
      '340121589) est a 12 001 m de la trace et aucun gite d etape n y est '
      'releve. Le lot 761 notait deja l absence de source publique. Coordonnee '
      'heritee, 1 401 m.',
  'mam-acc-09':
      'COTI-CHIAVARI N EST PAS SUR L ITINERAIRE (voir mam-acc-08) et aucun '
      'camping n y est releve. Coordonnee heritee, 1 338 m.',
  'mam-acc-11':
      'ETABLISSEMENT NON IDENTIFIE : aucun objet OSM « camping de Porticcio ». '
      'Les campings releves du secteur sont Benista (OSM way 1064470592, '
      '2 270 m) et U Prunelli (OSM way 1064470594, 2 631 m). Coordonnee '
      'heritee, 310 m.',
  'mam-acc-12':
      'ETABLISSEMENT NON TROUVE DANS OSM : « A Casa di Maria Cicilia » est '
      'annonce a Ghisonaccia par sa source (mare-a-mare.fr) mais aucun objet '
      'cartographique ne le porte. La commune (OSM relation 76886) est a '
      '4 221 m de la trace. Coordonnee heritee, 4 249 m.',
};

/// LES LIEUX DISPENSES DE LA REGLE D ETAPE, avec leur raison.
///
/// Ce sont exactement les lieux que le releve n a pas pu replacer : n ayant pas
/// bouge, ils se projettent encore la ou l ancien croquis les avait laisses.
const Map<String, String> kLieuxSansEtapeVerifiable = <String, String>{
  'mam-c-poi-14':
      'laisse faute d objet correspondant (voir '
      'kLieuxLegitimementLoinDuChemin) : il se projette donc encore dans '
      'l etape 3 alors qu il declare l etape 5.',
  'mam-c-poi-16':
      'laisse faute d objet correspondant : se projette dans l etape 3 alors '
      'qu il declare l etape 6.',
  'mam-poi-07':
      'laisse faute d objet correspondant : se projette dans l etape 3 alors '
      'qu il declare l etape 4.',
  'mam-poi-12':
      'laisse faute d objet nomme : se projette dans l etape 5 alors qu il '
      'declare l etape 6.',
};

/// LES SEULES FAMILLES AUTORISEES A SE TENIR LOIN DU CHEMIN SANS ETRE NOMMEES.
///
/// Un arret d autocar, une gare, un aeroport, un commerce de bourg : ce sont
/// des lieux par lesquels on ARRIVE au sentier ou dont on s ECARTE pour se
/// ravitailler. Leur distance au chemin n est pas un defaut. Le prefixe est la
/// convention du depot, documentee dans
/// `lib/features/planning/providers/lieux_en_base_provider.dart`.
const Set<String> kFamillesHorsChemin = <String>{'transport_', 'shop_'};

/// Un lieu a mesurer : son identite, sa coordonnee, l etape qu il declare.
typedef Lieu = ({String id, double lat, double lng, int etape, String nom});

List<TrackPoint> _trace() {
  const chemin = 'assets/data/mare_a_mare_centre/track.gpx';
  final fichier = File(chemin);
  expect(
    fichier.existsSync(),
    isTrue,
    reason: '$chemin est la trace de reference de la garde, et il est absent',
  );
  return GpxParser.parse(fichier.readAsStringSync()).allTrackPoints;
}

Map<String, dynamic> _json(String chemin) {
  final fichier = File(chemin);
  expect(
    fichier.existsSync(),
    isTrue,
    reason: '$chemin est declare mais absent du depot',
  );
  return jsonDecode(fichier.readAsStringSync()) as Map<String, dynamic>;
}

List<dynamic> _liste(String chemin) {
  final fichier = File(chemin);
  expect(
    fichier.existsSync(),
    isTrue,
    reason: '$chemin est declare mais absent du depot',
  );
  return jsonDecode(fichier.readAsStringSync()) as List<dynamic>;
}

int _numeroDEtape(Object? stageId) {
  final texte = stageId?.toString() ?? '';
  final trouve = RegExp(r's(\d+)$').firstMatch(texte);
  return trouve == null ? 0 : int.parse(trouve.group(1)!);
}

/// Les 20 lieux que la CARTE dessine (table `pois`, via SeedDataLoader).
List<Lieu> lieuxDeLaCarte(String chemin) => <Lieu>[
  for (final brut in _liste(chemin))
    (
      id: (brut as Map<String, dynamic>)['id'] as String,
      lat: (brut['lat'] as num).toDouble(),
      lng: (brut['lng'] as num).toDouble(),
      etape: (brut['stageNumber'] as num).toInt(),
      nom: brut['nameFr'] as String,
    ),
];

/// Les lieux d une famille de l asset publie (`pois`, `accommodations`).
List<Lieu> lieuxDeLAsset(Map<String, dynamic> asset, String famille) => <Lieu>[
  for (final brut in asset[famille] as List<dynamic>)
    (
      id: (brut as Map<String, dynamic>)['id'] as String,
      lat: (brut['lat'] as num).toDouble(),
      lng: (brut['lng'] as num).toDouble(),
      etape: _numeroDEtape(brut['stageId']),
      nom: brut['nameFr'] as String,
    ),
];

/// Les hebergements ajoutes par l etage editorial (snake_case).
List<Lieu> lieuxAjoutes(Map<String, dynamic> contenu, String famille) => <Lieu>[
  for (final brut in (contenu[famille] as List<dynamic>? ?? <dynamic>[]))
    (
      id: (brut as Map<String, dynamic>)['id'] as String,
      lat: (brut['lat'] as num).toDouble(),
      lng: (brut['lng'] as num).toDouble(),
      etape: _numeroDEtape(brut['stage_id']),
      nom: brut['name_fr'] as String,
    ),
];

/// L ecart du lieu a la trace, et l abscisse ou il se projette.
({double ecartM, double abscisseM}) _projeter(
  Lieu lieu,
  List<TrackPoint> trace,
) {
  final p = TrackProjector.project(
    userLat: lieu.lat,
    userLng: lieu.lng,
    trackPoints: trace,
    // null : on balaie TOUTE la trace. Une fenetre glissante supposerait
    // qu on sait deja ou le lieu se trouve — c est precisement la question.
    lastKnownIndex: null,
  );
  return (ecartM: p.distanceToTrackM, abscisseM: p.distanceFromStartM);
}

/// Le median des ecarts, en metres. Le median et non la moyenne : un seul lieu
/// perdu a quatre kilometres ne doit pas condamner la mesure d ensemble, et
/// dix-neuf lieux perdus ne doivent pas etre absous par un vingtieme juste.
double medianDesEcarts(Iterable<double> ecarts) {
  final v = ecarts.toList()..sort();
  expect(v, isNotEmpty, reason: 'aucun ecart a mesurer');
  final milieu = v.length ~/ 2;
  return v.length.isOdd ? v[milieu] : (v[milieu - 1] + v[milieu]) / 2;
}

/// Les lieux de la famille qui depassent le seuil SANS etre nommes.
List<String> _horsSeuilNonNommes(List<Lieu> lieux, List<TrackPoint> trace) => [
  for (final lieu in lieux)
    if (_projeter(lieu, trace).ecartM > ecartMaxDuLieuAuCheminM &&
        !kLieuxLegitimementLoinDuChemin.containsKey(lieu.id))
      '${lieu.id} (${lieu.nom}) a '
          '${_projeter(lieu, trace).ecartM.toStringAsFixed(0)} m',
];

void main() {
  group('les lieux du Mare a Mare Centre sont sur le chemin', () {
    late List<TrackPoint> trace;
    late List<Lieu> carte;
    late List<Lieu> poisPublies;
    late List<Lieu> hebergements;

    setUpAll(() {
      trace = _trace();
      carte = lieuxDeLaCarte('assets/data/mare_a_mare_centre/pois.json');
      final asset = _json('assets/data/mare_a_mare_centre.json');
      poisPublies = lieuxDeLAsset(asset, 'pois');
      final contenu = _json('publication/contenu/mare-a-mare-centre.json');
      hebergements = <Lieu>[
        ...lieuxDeLAsset(asset, 'accommodations'),
        ...lieuxAjoutes(contenu, 'accommodations_ajoutees'),
      ];
    });

    test('le seuil suit les constantes de l application', () {
      expect(
        ecartMaxDuLieuAuCheminM,
        StageDetector.toleranceRadiusM,
        reason:
            'le seuil de la garde EST le rayon de tolerance du detecteur '
            'd etape : il ne se regle pas a part',
      );
      expect(
        ecartMaxDuLieuAuCheminM,
        greaterThan(kOffTrackExitThresholdMeters),
        reason:
            'un lieu du sentier doit rester accessible sans que l application '
            'declare le marcheur sorti du chemin '
            '(${kOffTrackExitThresholdMeters.toStringAsFixed(0)} m) ; si le '
            'seuil de la garde descendait sous celui-la, elle refuserait des '
            'lieux parfaitement poses au bord du chemin',
      );
    });

    test('aucun lieu de la carte ne flotte a cote du chemin', () {
      final fautifs = _horsSeuilNonNommes(carte, trace);
      expect(
        fautifs,
        isEmpty,
        reason:
            'ces lieux de assets/data/mare_a_mare_centre/pois.json sont a plus '
            'de ${ecartMaxDuLieuAuCheminM.toStringAsFixed(0)} m de la trace '
            'sans etre nommes dans kLieuxLegitimementLoinDuChemin : '
            '${fautifs.join(', ')}. Soit la coordonnee est relevee dans '
            'OpenStreetMap, soit le lieu est nomme avec sa raison. Il n y a '
            'pas '
            'de troisieme voie.',
      );
      expect(carte, hasLength(20), reason: 'la carte porte 20 lieux');
    });

    test('aucun lieu publie ne flotte a cote du chemin', () {
      final fautifs = _horsSeuilNonNommes(poisPublies, trace);
      expect(
        fautifs,
        isEmpty,
        reason:
            'ces lieux de assets/data/mare_a_mare_centre.json (cle pois) sont '
            'hors seuil sans etre nommes : ${fautifs.join(', ')}',
      );
      expect(poisPublies, isNotEmpty);
    });

    test('aucun hebergement ne flotte a cote du chemin', () {
      final fautifs = _horsSeuilNonNommes(hebergements, trace);
      expect(
        fautifs,
        isEmpty,
        reason:
            'ces hebergements sont hors seuil sans etre nommes : '
            '${fautifs.join(', ')}',
      );
      expect(
        hebergements,
        hasLength(18),
        reason:
            'le sentier porte 18 hebergements : 11 dans l asset et 7 ajoutes '
            'par l etage editorial',
      );
    });

    test('les lieux ajoutes ne servent pas de cachette', () {
      // Les 19 points ajoutes echappent au seuil parce qu ils sont des lieux
      // d ACCES et de RAVITAILLEMENT. Ce test verifie que c est bien tout ce
      // qu ils sont : sans lui, il suffirait d ajouter une fontaine ici pour
      // qu elle ne soit jamais mesuree.
      final contenu = _json('publication/contenu/mare-a-mare-centre.json');
      final ajoutes = <Lieu>[...lieuxAjoutes(contenu, 'pois_ajoutes')];
      final types = <String, String>{
        for (final brut in contenu['pois_ajoutes'] as List<dynamic>)
          (brut as Map<String, dynamic>)['id'] as String:
              brut['type'] as String,
      };

      final fautifs = <String>[];
      for (final lieu in ajoutes) {
        final type = types[lieu.id] ?? '';
        final horsChemin = kFamillesHorsChemin.any(type.startsWith);
        if (horsChemin) continue;
        if (kLieuxLegitimementLoinDuChemin.containsKey(lieu.id)) continue;
        final ecart = _projeter(lieu, trace).ecartM;
        if (ecart > ecartMaxDuLieuAuCheminM) {
          fautifs.add(
            '${lieu.id} (${lieu.nom}), type "$type", a '
            '${ecart.toStringAsFixed(0)} m',
          );
        }
      }
      expect(
        fautifs,
        isEmpty,
        reason:
            'ces lieux ajoutes ne sont ni d une famille d acces '
            '(${kFamillesHorsChemin.join(', ')}) ni nommes, et ils sont hors '
            'seuil : ${fautifs.join(' ; ')}',
      );
      expect(
        ajoutes,
        hasLength(19),
        reason:
            'l etage editorial ajoute 19 points d acces et de ravitaillement',
      );
    });

    test('chaque lieu se projette dans l etape qu il declare', () {
      final fautifs = <String>[];
      var examines = 0;
      for (final lieu in [...carte, ...poisPublies, ...hebergements]) {
        if (lieu.etape < 1 || lieu.etape > 7) continue;
        if (kLieuxSansEtapeVerifiable.containsKey(lieu.id)) continue;
        examines++;
        final abscisse = _projeter(lieu, trace).abscisseM;
        final debut = kBornesDEtapeM[lieu.etape - 1] - ecartMaxDuLieuAuCheminM;
        final fin = kBornesDEtapeM[lieu.etape] + ecartMaxDuLieuAuCheminM;
        if (abscisse < debut || abscisse > fin) {
          fautifs.add(
            '${lieu.id} (${lieu.nom}) declare l etape ${lieu.etape} mais se '
            'projette a ${(abscisse / 1000).toStringAsFixed(3)} km',
          );
        }
      }
      expect(
        fautifs,
        isEmpty,
        reason:
            'UN ECART FAIBLE NE DIT PAS QUE LE LIEU EST AU BON ENDROIT : ces '
            'lieux se projettent hors de l etape qu ils declarent, donc a un '
            'autre endroit du sentier. ${fautifs.join(' ; ')}',
      );
      expect(
        examines,
        greaterThan(40),
        reason:
            'la garde n a presque rien examine : elle ne garde plus rien. '
            'Verifier que les trois fichiers de lieux sont encore lus.',
      );
    });

    test('les ecarts medians restent bas, liste nommee comprise', () {
      // Sans cette mesure, la liste nommee pourrait absorber une regression de
      // masse un lieu a la fois, chaque entree paraissant raisonnable seule.
      expect(
        medianDesEcarts(carte.map((l) => _projeter(l, trace).ecartM)),
        lessThan(50),
        reason:
            'les 20 lieux de la carte avaient un ecart median de 1 596 m avant '
            'ce lot ; apres releve il est de 22 m. Au-dela de 50 m, quelque '
            'chose est reparti de travers.',
      );
      expect(
        medianDesEcarts(poisPublies.map((l) => _projeter(l, trace).ecartM)),
        lessThan(200),
        reason: 'les lieux publies avaient 1 201 m de median, ils ont 58 m',
      );
      expect(
        medianDesEcarts(hebergements.map((l) => _projeter(l, trace).ecartM)),
        lessThan(600),
        reason:
            'les 18 hebergements avaient 1 357 m de median, ils ont 255 m. Le '
            'median reste plus haut que celui des points d interet parce que '
            'sept etablissements ne sont identifies par aucune source publique '
            'et gardent leur coordonnee heritee.',
      );
    });

    test('la liste nommee ne contient ni entree morte ni entree inutile', () {
      final tous = <String, Lieu>{
        for (final lieu in [
          ...carte,
          ...poisPublies,
          ...hebergements,
          ...lieuxAjoutes(
            _json('publication/contenu/mare-a-mare-centre.json'),
            'pois_ajoutes',
          ),
        ])
          lieu.id: lieu,
      };

      for (final entree in kLieuxLegitimementLoinDuChemin.entries) {
        final lieu = tous[entree.key];
        expect(
          lieu,
          isNotNull,
          reason:
              '${entree.key} est dispense mais n existe plus dans la donnee : '
              'entree morte, a retirer de kLieuxLegitimementLoinDuChemin',
        );
        expect(
          _projeter(lieu!, trace).ecartM,
          greaterThan(ecartMaxDuLieuAuCheminM),
          reason:
              '${entree.key} est dispense alors qu il passe le seuil : la '
              'dispense ne sert a rien et fait croire a un probleme. La '
              'retirer.',
        );
        expect(
          entree.value.length,
          greaterThan(60),
          reason:
              '${entree.key} est dispense sans raison ecrite. Une dispense '
              'sans motif est un seuil desactive en silence.',
        );
      }

      for (final entree in kLieuxSansEtapeVerifiable.entries) {
        expect(
          tous.containsKey(entree.key),
          isTrue,
          reason:
              '${entree.key} est dispense de la regle d etape mais n existe '
              'plus dans la donnee',
        );
        expect(entree.value.length, greaterThan(40));
      }
    });

    test('elle rougit sur les donnees d avant, et le temoin le prouve', () {
      final avantCarte = lieuxDeLaCarte(
        'test/fixtures/lieux/pois_mare_a_mare_centre_avant_775.json',
      );
      expect(
        avantCarte,
        hasLength(20),
        reason: 'le temoin est bien la carte d avant',
      );

      final ecarts = avantCarte.map((l) => _projeter(l, trace).ecartM).toList();
      final horsSeuil = ecarts.where((e) => e > ecartMaxDuLieuAuCheminM).length;

      // LE COEUR DE LA GARDE : sans ces lignes, le seuil pourrait etre pose si
      // haut que plus rien ne le franchirait jamais.
      expect(
        horsSeuil,
        19,
        reason:
            'avant ce lot, 19 des 20 lieux de la carte depassaient le seuil de '
            '${ecartMaxDuLieuAuCheminM.toStringAsFixed(0)} m. Si ce compte '
            'tombe, le temoin a ete touche ou le seuil ne mord plus.',
      );
      expect(
        medianDesEcarts(ecarts),
        closeTo(1596, 5),
        reason:
            'l ecart median mesure avant ce lot etait de 1 596 m, et c est le '
            'chiffre que Christophe a vu a l ecran',
      );
      expect(
        ecarts.reduce((a, b) => a > b ? a : b),
        closeTo(7128, 5),
        reason: 'le pire cas mesure avant ce lot etait de 7 128 m',
      );

      final avantPublie = _json(
        'test/fixtures/lieux/publication_mare_a_mare_centre_avant_775.json',
      );
      final avantHebergements = <Lieu>[
        ...lieuxDeLAsset(avantPublie, 'accommodations'),
        ...lieuxAjoutes(
          _json(
            'test/fixtures/lieux/overlay_mare_a_mare_centre_avant_775.json',
          ),
          'accommodations_ajoutees',
        ),
      ];
      expect(avantHebergements, hasLength(18));
      expect(
        avantHebergements
            .map((l) => _projeter(l, trace).ecartM)
            .where((e) => e > ecartMaxDuLieuAuCheminM)
            .length,
        17,
        reason:
            'avant ce lot, 17 des 18 hebergements depassaient le seuil : la '
            'recette 778 ne les avait pas mesures, ils souffraient du meme mal',
      );
    });
  });
}
