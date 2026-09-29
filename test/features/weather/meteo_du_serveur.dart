import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:moteur_gr/core/data/daos/trail_meteo_dao.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/revision_de_donnee.dart';

/// OUTILLAGE DE TEST : DEPOSER UN BULLETIN COMME LE SERVEUR LE FERAIT (lot 625).
///
/// UN SEUL ENDROIT ECRIT LA FORME PUBLIEE DANS LES TESTS, et ce n est pas du confort.
/// Cinq fichiers de test avaient besoin de fabriquer un bulletin ; cinq fixtures
/// recopiees a la main auraient diverge au premier champ ajoute, et c est
/// precisement le piege #S11 de la spec 605 — deux ecritures du meme sentier qui se
/// contredisent — reproduit dans la suite de tests.
///
/// La forme produite ici est celle du fichier publie : SNAKE_CASE, `produite_le`
/// obligatoire, `jours` en bloc.

/// Un jour de prevision dans la forme PUBLIEE.
Map<String, dynamic> jourPublie(
  String date, {
  int code = 1,
  double tMax = 22.0,
  double tMin = 12.0,
  double precipitationMm = 0.0,
  double ventKmh = 10.0,
  double uv = 5.0,
  num? probabilite,
}) =>
    {
      'date': date,
      'temperature_max': tMax,
      'temperature_min': tMin,
      'precipitation_mm': precipitationMm,
      'wind_speed_kmh': ventKmh,
      'uv_index': uv,
      'weather_code': code,
      if (probabilite != null) 'precipitation_probability_max': probabilite,
    };

/// Cinq jours a partir de [depuis] — la portee que le serveur publie (#W6).
List<Map<String, dynamic>> joursDepuis(
  DateTime depuis, {
  int nombre = 5,
  int code = 1,
}) =>
    [
      for (var i = 0; i < nombre; i++)
        jourPublie(
          DateTime(depuis.year, depuis.month, depuis.day)
              .add(Duration(days: i))
              .toIso8601String()
              .substring(0, 10),
          code: code,
        ),
    ];

/// ENREGISTREMENT `meteo` TEL QUE LE SERVEUR LE PUBLIE, pret a etre pose par
/// `DeltaUpdateService.appliquerRevisions`.
Map<String, dynamic> meteoPubliee({
  required String trailId,
  required int stageNumber,
  required String produiteLe,
  String? collecteeLe,
  String? rev,
  String source = 'met-norway',
  double latitude = 42.472,
  double longitude = 8.927,
  List<Map<String, dynamic>>? jours,
  String? id,
  String? stageId,
}) =>
    {
      'id': id ?? '$trailId-s$stageNumber-meteo',
      'trail_id': trailId,
      'stage_id': stageId ?? '$trailId-s$stageNumber',
      'stage_number': stageNumber,
      'latitude': latitude,
      'longitude': longitude,
      'source': source,
      'produite_le': produiteLe,
      if (collecteeLe != null) 'collectee_le': collecteeLe,
      'jours': jours ??
          joursDepuis(DateTime.parse(produiteLe).toLocal()),
      if (rev != null) 'rev': rev,
    };

/// Depose un bulletin DIRECTEMENT en base, sans passer par la synchronisation.
///
/// Sert aux tests d affichage, qui n ont pas besoin de rejouer tout le transport.
/// Les tests du MECANISME, eux, passent par `appliquerRevisions` avec
/// [meteoPubliee] : c est la seule facon de verifier que la famille est bien
/// branchee sur le chemin unique.
Future<void> deposerMeteoEnBase(
  AppDatabase db, {
  required String trailId,
  required int stageNumber,
  required DateTime produiteLe,
  DateTime? collecteeLe,
  String source = 'met-norway',
  List<Map<String, dynamic>>? jours,
  double latitude = 42.472,
  double longitude = 8.927,
}) async {
  final instant = HorodatageServeur.annonceParLeServeur(
    produiteLe.toUtc().toIso8601String(),
  )!;
  await TrailMeteoDao(db).insertOrReplace(TrailMeteoCompanion(
    id: Value('$trailId-s$stageNumber-meteo'),
    trailId: Value(trailId),
    stageId: Value('$trailId-s$stageNumber'),
    stageNumber: Value(stageNumber),
    latitude: Value(latitude),
    longitude: Value(longitude),
    source: Value(source),
    produiteLe: Value(instant),
    collecteeLe: Value(collecteeLe == null
        ? null
        : HorodatageServeur.annonceParLeServeur(
            collecteeLe.toUtc().toIso8601String(),
          )),
    joursJson: Value(jsonEncode(jours ?? joursDepuis(DateTime.now()))),
    rev: Value(instant),
  ));
}
