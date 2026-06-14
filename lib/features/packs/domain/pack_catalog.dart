import 'pack_manifest.dart';
import 'sentier_pack.dart';

/// Libelles localises d'un pack (nom + description), resolus via Slang par l'UI.
///
/// Le domaine reste PUR et testable (aucune dependance Slang/Flutter) : l'UI
/// passe la resolution i18n a la construction du catalogue (meme principe que
/// le catalogue de badges F7C-01).
class PackLabels {
  const PackLabels({required this.nom, required this.description});

  /// Nom localise du pack (ex « Mare a Mare Nord »).
  final String nom;

  /// Description localisee du pack.
  final String description;
}

/// Resout les libelles d'un pack a partir de son [PackType].
typedef PackLabelResolver = PackLabels Function(String type);

/// Catalogue des packs sentier A LA CARTE (F8B-01, regle metier R2).
///
/// Construit la liste des packs achetables/telechargeables INDEPENDANTS pour un
/// sentier (Nord / Sud / Complet / Mare a Mare) — modele FarOut « bundle », PAS
/// de tout-abonnement (R2, A3-11). Chaque pack est associe a son [PackManifest]
/// decrivant le contenu 100 % offline (R3).
///
/// Fonctions PURES (aucune dependance Flutter/Slang) : l'UI fournit le
/// [PackLabelResolver] pour les libelles localises. Donnees fictives en P2-P3
/// (#84627) : les references de manifeste sont des cles symboliques que
/// [PackDownloadService] (F8B-02) resoudra une fois le backend connecte.
abstract final class PackCatalog {
  /// Types de pack proposes A LA CARTE pour un sentier, dans l'ordre d'affichage.
  ///
  /// Nord et Sud (demi-sentiers) puis Complet (sentier entier) puis Mare a Mare
  /// (1er sentier cible #84627). Aucun « tout-abo » : 4 unites distinctes (R2).
  static const List<String> aLaCarteTypes = [
    PackType.nord,
    PackType.sud,
    PackType.complet,
    PackType.mam,
  ];

  /// Compose l'identifiant d'un pack pour un sentier (ex 'mam_complet').
  static String packId(String trailId, String type) => '${trailId}_$type';

  /// Liste les packs disponibles A LA CARTE pour [trailId].
  ///
  /// [labelResolver] fournit les libelles localises (Slang cote UI). Retourne 4
  /// packs distincts (Nord/Sud/Complet/MaM), JAMAIS un abonnement global (R2).
  static List<SentierPack> availablePacks(
    String trailId, {
    required PackLabelResolver labelResolver,
  }) {
    return aLaCarteTypes.map((type) {
      final labels = labelResolver(type);
      return SentierPack(
        id: packId(trailId, type),
        nom: labels.nom,
        trailId: trailId,
        type: type,
        description: labels.description,
      );
    }).toList(growable: false);
  }

  /// Manifeste (fictif P2-P3, #84627) decrivant le contenu offline d'un pack.
  ///
  /// Les references sont symboliques : [PackDownloadService] (F8B-02) les
  /// resoudra. Un pack Complet agrege les references Nord + Sud ; le pack MaM
  /// embarque son propre jeu. [tailleMo] approxime le poids affiche au store.
  static PackManifest manifestFor(String trailId, String type) {
    final id = packId(trailId, type);
    switch (type) {
      case PackType.nord:
        return PackManifest(
          packId: id,
          mbtilesRefs: ['$id/map_nord.mbtiles'],
          gpxRefs: ['$id/track_nord.gpx'],
          poiRefs: ['$id/poi_nord.json'],
          townGuideRefs: ['$id/guides_nord.json'],
          waypointsSnapshotRef: '$id/waypoints_nord.json',
          tailleMo: 180,
        );
      case PackType.sud:
        return PackManifest(
          packId: id,
          mbtilesRefs: ['$id/map_sud.mbtiles'],
          gpxRefs: ['$id/track_sud.gpx'],
          poiRefs: ['$id/poi_sud.json'],
          townGuideRefs: ['$id/guides_sud.json'],
          waypointsSnapshotRef: '$id/waypoints_sud.json',
          tailleMo: 170,
        );
      case PackType.complet:
        // Complet = Nord + Sud agreges (un seul pack achetable, R2).
        return PackManifest(
          packId: id,
          mbtilesRefs: ['$id/map_nord.mbtiles', '$id/map_sud.mbtiles'],
          gpxRefs: ['$id/track_nord.gpx', '$id/track_sud.gpx'],
          poiRefs: ['$id/poi_nord.json', '$id/poi_sud.json'],
          townGuideRefs: ['$id/guides_nord.json', '$id/guides_sud.json'],
          waypointsSnapshotRef: '$id/waypoints_complet.json',
          tailleMo: 340,
        );
      case PackType.mam:
      default:
        return PackManifest(
          packId: id,
          mbtilesRefs: ['$id/map_mam.mbtiles'],
          gpxRefs: ['$id/track_mam.gpx'],
          poiRefs: ['$id/poi_mam.json'],
          townGuideRefs: ['$id/guides_mam.json'],
          waypointsSnapshotRef: '$id/waypoints_mam.json',
          tailleMo: 260,
        );
    }
  }
}
