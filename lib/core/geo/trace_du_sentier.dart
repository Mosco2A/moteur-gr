/// Ce qui a ete RECU l'emporte sur ce qui a ete COMPILE : meme ordre de sources
/// que le catalogue, l'asset n'etant qu'un secours.
library;

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../data/database.dart';
import '../providers/database_provider.dart';
import 'geo_utils.dart';
import 'gpx_depuis_les_assets.dart';
import 'trace_point.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// D OU VIENT LA TRACE QUE LA CARTE AFFICHE.
///
/// L ORDRE EST LE MEME QUE CELUI DU CATALOGUE (tache 605,
/// `SourceDuCatalogue`), et ce n est pas une coquetterie de symetrie : c est la
/// meme regle appliquee au meme probleme. Ce qui a ete RECU l emporte sur ce qui
/// a ete COMPILE, et le compile est un SECOURS — jamais une source concurrente.
enum SourceDeLaTrace {
  /// Les points copies en base (`trail_gpx_points`), par le telechargement du
  /// sentier ou par l amorce des donnees embarquees. SOURCE DE VERITE.
  base,

  /// Le fichier GPX EMBARQUE dans le binaire. SECOURS : il sert quand la base
  /// n a rien — premiere ouverture avant amorce, base effacee, sentier compile
  /// jamais telecharge.
  assetCompile,

  /// Ni l un ni l autre : le sentier n est pas encore copie et le binaire ne
  /// porte aucun fichier pour lui. C est l etat NORMAL d un sentier distant
  /// « au catalogue, pas sur le telephone » (#E1 de la spec serveur), et il est
  /// NOMME pour que la carte puisse le dire au lieu de montrer un vide muet.
  aucune,
}

/// La trace d un sentier, et d ou elle vient.
class TraceDuSentier {
  const TraceDuSentier({required this.points, required this.source});

  /// Trace vide, source nommee.
  const TraceDuSentier.aucune()
    : points = const [],
      source = SourceDeLaTrace.aucune;

  /// Les points, ordonnes, avec leur distance cumulee depuis le depart.
  final List<TrackPoint> points;

  /// Laquelle des deux couches a produit ces points.
  final SourceDeLaTrace source;

  /// Vrai quand il n y a rien a afficher.
  bool get estVide => points.isEmpty;
}

/// LE CHEMIN UNIQUE DE LA TRACE — LA CARTE LIT LA BASE, L ASSET EST LE SECOURS.
///
/// LE DEFAUT QUE CETTE CLASSE FERME, ET C EST LA SECONDE MOITIE DU MUR N1
/// (tache 606). Le lot 605 a branche le CATALOGUE sur le reseau : un sentier
/// decrit entierement a distance apparaissait dans la liste et ses donnees
/// descendaient bien en base. Mais `gpx_track_provider.dart` lisait la trace
/// depuis les ASSETS (`rootBundle`), c est-a-dire depuis le BINAIRE : un sentier
/// que le binaire ne connait pas n avait donc AUCUNE source de trace. Il etait
/// consultable et pas MARCHABLE — la moitie du mur tenait encore.
///
/// TROIS LECTEURS DE TRACE EXISTAIENT DANS LE DEPOT, MESURES AVANT DE TOUCHER A
/// QUOI QUE CE SOIT, ET ILS PASSENT TOUS PAR ICI :
///  1. `gpxTrackProvider` — la trace de la carte, lue dans l ASSET. Cinq
///     consommateurs (`map_screen`, `track_position_provider`,
///     `simplified_track_provider`, `off_track_provider`,
///     `trek_feasibility_provider`), une seule lecture.
///  2. `DriftTrailDataProvider.getTrackPoints` — lecteur de la BASE, avec sa
///     propre accumulation de distance ; ZERO consommateur, donc une seconde
///     definition du meme calcul qui pouvait deriver sans que rien ne le dise.
///  3. `SeedDataLoader` — lit l ASSET et en pose une copie en base.
///
/// LA MESURE QUI A DICTE LA CORRECTION DU SEMEUR. `SeedDataLoader` ecrivait en
/// base la trace SIMPLIFIEE (Douglas-Peucker, epsilon ~11 m) et non la trace
/// lue : sur `mare_a_mare_centre`, 48 points poses pour 53 lus — 5 points
/// PERDUS. Faire lire la base en premier aurait donc DEGRADE un sentier
/// embarque, ce qui est exclu. Le semeur pose desormais la trace ENTIERE : la
/// simplification reste ou elle a du sens, au rendu, par niveau de zoom
/// (`simplifiedTrackProvider`). Un aller-retour base/asset est ainsi
/// rigoureusement neutre pour les sentiers embarques.
class LecteurDeTrace {
  LecteurDeTrace({
    required AppDatabase db,
    Future<List<TrackPoint>> Function(String chemin)? lireLAsset,
  }) : _db = db,
       _lireLAsset = lireLAsset ?? GpxDepuisLesAssets.parseFromAsset;

  final AppDatabase _db;

  /// Lecture de l asset, injectable : `rootBundle` n existe pas hors binaire.
  final Future<List<TrackPoint>> Function(String chemin) _lireLAsset;

  /// LA TRACE DE [trailId], BASE D ABORD, ASSET EN SECOURS.
  ///
  /// [cheminAsset] est le `gpxAssetPath` de la configuration du sentier. Il vaut
  /// la chaine vide pour un sentier connu du seul distant (la liste distante ne
  /// peut pas inventer un fichier embarque, cf. #F14 de la spec serveur) : dans
  /// ce cas il n y a pas de secours, et l absence est NOMMEE plutot que jetee.
  ///
  /// UN ASSET DECLARE QUI NE SE LIT PAS RESTE UNE ERREUR, et c est deliberе : la
  /// carte affiche aujourd hui « impossible de charger la trace » avec un bouton
  /// reessayer dans ce cas, et avaler l echec transformerait un fichier manquant
  /// en carte silencieusement vide.
  ///
  /// LA MESURE QUI ILLUSTRAIT CE PARAGRAPHE A ETE CORRIGEE (tache 607).
  /// `gr-pyrenees` declarait `assets/gpx/gr_pyrenees.gpx`, absent du depot : ce
  /// sentier ECHOUAIT DEJA, au catalogue et sans trace. La reponse n a pas ete
  /// d avaler l erreur mais de ne plus mentir — son `gpxAssetPath` est VIDE,
  /// donc son absence est NOMMEE, et une garde de `trail_catalog_test` verifie
  /// desormais que tout chemin declare existe reellement dans le depot. Le
  /// comportement decrit ci-dessus ne change pas : un chemin declare qui ne se
  /// lit pas reste une erreur.
  Future<TraceDuSentier> lire({
    required String trailId,
    required String cheminAsset,
  }) async {
    final deLaBase = await _depuisLaBase(trailId);
    if (deLaBase.isNotEmpty) {
      return TraceDuSentier(points: deLaBase, source: SourceDeLaTrace.base);
    }

    if (cheminAsset.isEmpty) {
      _log.d(
        '[Trace] $trailId : rien en base et aucun fichier embarque — le '
        'sentier est au catalogue mais ses donnees ne sont pas copiees.',
      );
      return const TraceDuSentier.aucune();
    }

    final deLAsset = await _lireLAsset(cheminAsset);
    return TraceDuSentier(
      points: deLAsset,
      source: SourceDeLaTrace.assetCompile,
    );
  }

  /// Les points des traces de [trailId], dans l ordre, ou une liste vide.
  ///
  /// COMMENT ON PASSE D UN SENTIER A SES TRACES, ET POURQUOI IL Y A DEUX FORMES.
  /// Le schema relie une trace a un ITINERAIRE, pas a un sentier : la jointure
  /// normale est `trail_itineraries.trail_id` -> `trail_gpx_tracks.itinerary_id`.
  /// Mais l amorce des donnees embarquees (`SeedDataLoader`) ne cree AUCUN
  /// itineraire : elle pose une trace dont l identifiant ET l itineraire valent
  /// le trailId. Les deux formes sont donc acceptees — sinon la base des quatre
  /// sentiers embarques serait invisible et le secours asset servirait toujours,
  /// ce qui reviendrait a ne rien avoir branche.
  ///
  /// CONSEQUENCE A CONNAITRE POUR LE DEPOT SERVEUR : une trace rattachee a un
  /// itineraire que le fichier de donnees ne publie PAS est invisible. Le schema
  /// exige les itineraires (#S2, famille appliquee en second) ; publier
  /// `gpx_tracks` sans son `itineraries` pose donc des points que personne ne
  /// lira.
  Future<List<TrackPoint>> _depuisLaBase(String trailId) async {
    final itineraires = await (_db.select(
      _db.trailItineraries,
    )..where((t) => t.trailId.equals(trailId))).get();

    final rattachements = <String>{
      for (final i in itineraires) i.id,
      trailId, // forme de l amorce embarquee : itineraryId == trailId
    };

    final traces =
        await (_db.select(_db.trailGpxTracks)
              ..where((t) => t.itineraryId.isIn(rattachements))
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();

    if (traces.isEmpty) return const [];

    return pointsDeLaTrace(traces.map((t) => t.id).toList());
  }

  /// LES POINTS DE [identifiantsDeTrace], TRACE PAR TRACE, DANS L ORDRE DONNE.
  ///
  /// C est la SEULE conversion « lignes de la base -> [TrackPoint] » du moteur, y
  /// compris l accumulation de la distance depuis le depart, que la base ne
  /// stocke pas. `DriftTrailDataProvider.getTrackPoints` en portait une seconde
  /// copie ; elle delegue ici.
  Future<List<TrackPoint>> pointsDeLaTrace(
    List<String> identifiantsDeTrace,
  ) async {
    if (identifiantsDeTrace.isEmpty) return const [];

    final lignes =
        await (_db.select(_db.trailGpxPoints)
              ..where((t) => t.trackId.isIn(identifiantsDeTrace))
              ..orderBy([(t) => OrderingTerm.asc(t.sequenceIndex)]))
            .get();

    // Regroupement dans l ordre DEMANDE : une requete unique ne peut pas rendre
    // les traces dans l ordre d une liste Dart, et l ordre des traces decide de
    // la continuite du trace affiche.
    final parTrace = <String, List<TrailGpxPoint>>{};
    for (final ligne in lignes) {
      (parTrace[ligne.trackId] ??= <TrailGpxPoint>[]).add(ligne);
    }

    final points = <TrackPoint>[];
    var distanceCumulee = 0.0;

    for (final id in identifiantsDeTrace) {
      for (final ligne in parTrace[id] ?? const <TrailGpxPoint>[]) {
        if (points.isNotEmpty) {
          final precedent = points.last;
          distanceCumulee += GeoUtils.haversineDistance(
            precedent.lat,
            precedent.lng,
            ligne.lat,
            ligne.lng,
          );
        }
        points.add(
          TrackPoint(
            lat: ligne.lat,
            lng: ligne.lng,
            altitude: ligne.elevation,
            distanceFromStart: distanceCumulee,
          ),
        );
      }
    }

    return points;
  }
}

/// Le lecteur de trace, cable sur la base de l application.
final lecteurDeTraceProvider = Provider<LecteurDeTrace>((ref) {
  return LecteurDeTrace(db: ref.watch(databaseProvider));
});
