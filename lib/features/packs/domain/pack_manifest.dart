import 'package:freezed_annotation/freezed_annotation.dart';

part 'pack_manifest.freezed.dart';
part 'pack_manifest.g.dart';

/// Manifeste d'un pack sentier (F8B-01, Phase 8 P8-B, offline-first R3).
///
/// Decrit TOUT ce qu'un pack contient pour fonctionner 100 % OFFLINE une fois
/// telecharge AVANT le depart (R3, pre-telechargement obligatoire) : cartes
/// mbtiles, traces GPX, POI, town guides (P8-C) et snapshot des waypoints
/// communautaires (P8-A). [PackDownloadService] (F8B-02) consomme ce manifeste
/// pour rapatrier, verifier l'integrite et stocker le pack en local.
///
/// Les listes sont des REFERENCES (chemins/cles d'assets ou de stockage), pas le
/// contenu binaire : le service resout chaque reference au telechargement. Une
/// reference de snapshot waypoints distincte (et non une liste) car un pack ne
/// porte qu'un seul instantane communautaire fige au moment de la publication.
@freezed
abstract class PackManifest with _$PackManifest {
  const PackManifest._();

  const factory PackManifest({
    /// Identifiant du pack decrit par ce manifeste ([SentierPack.id]).
    required String packId,

    /// References des fichiers cartes mbtiles (offline).
    @Default(<String>[]) List<String> mbtilesRefs,

    /// References des traces GPX (offline).
    @Default(<String>[]) List<String> gpxRefs,

    /// References des jeux de POI (offline).
    @Default(<String>[]) List<String> poiRefs,

    /// References des town guides (P8-C, offline).
    @Default(<String>[]) List<String> townGuideRefs,

    /// Reference du snapshot des waypoints communautaires (P8-A, offline).
    ///
    /// Instantane fige a la publication du pack ; les contributions ulterieures
    /// arrivent ensuite par la sync differee du [WaypointService] (F8A-02).
    required String waypointsSnapshotRef,

    /// Taille totale du pack en megaoctets (affichee dans le store, F8B-03).
    required int tailleMo,

    /// Checksum d'integrite attendu du pack (verifie par F8B-02).
    ///
    /// Optionnel : null tant que le catalogue serveur ne fournit pas de
    /// checksum (avant Phase 4, #84627). Quand present, le service refuse un
    /// pack dont le checksum calcule differe (ZERO catch silencieux).
    String? checksum,
  }) = _PackManifest;

  /// Nombre total de fichiers references par le manifeste (hors snapshot).
  int get totalFileRefs =>
      mbtilesRefs.length +
      gpxRefs.length +
      poiRefs.length +
      townGuideRefs.length;

  /// Toutes les references de fichiers a telecharger, snapshot waypoints inclus.
  ///
  /// Ordre stable (cartes, gpx, poi, guides, snapshot) — utilise par
  /// [PackDownloadService] (F8B-02) pour piloter la progression.
  List<String> get allRefs => <String>[
        ...mbtilesRefs,
        ...gpxRefs,
        ...poiRefs,
        ...townGuideRefs,
        waypointsSnapshotRef,
      ];

  /// Deserialisation depuis JSON (catalogue serveur ou seed local).
  factory PackManifest.fromJson(Map<String, dynamic> json) =>
      _$PackManifestFromJson(json);
}
