/// Choisit la source des tuiles : le fichier du sentier s'il est lisible, le
/// reseau sinon — l'ecran de carte n'a pas a connaitre la difference.
library;

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_mbtiles/flutter_map_mbtiles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'mbtiles_manager.dart';
import 'test_inert_tile_provider.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// POURQUOI LE RESEAU A ETE CHOISI. Jamais un booleen : chaque cause se lit
/// differemment dans un journal de terrain.
enum RaisonDuReseau {
  /// Aucun `{trailId}.mbtiles` complet sur le telephone.
  pasDeFichier,

  /// Le fichier existe mais ne s'ouvre pas comme une carte MBTiles : base
  /// SQLite abimee, table absente, octets qui ne sont pas une base.
  fichierIllisible,

  /// Le dossier des documents ne repond pas (plateforme sans `path_provider`,
  /// stockage indisponible) : on ne sait meme pas ou chercher.
  dossierInaccessible,

  /// Decision pas encore rendue (quelques millisecondes a l'ouverture).
  enAttente,
}

/// LA DECISION DU FOND DE CARTE, rendue comme une VALEUR.
///
/// ORIGINE (lot carte-hors-ligne-branchee, 07/10/2026). Le randonneur
/// telechargeait des centaines de megaoctets de carte et l'ecran carte ne
/// lisait JAMAIS ce fichier : les quatre couches de tuiles de l'application
/// partaient en dur vers OpenStreetMap, et en mode avion le fond etait BLANC.
/// La decision existait (ce fichier) mais personne ne l'appelait. Elle passe
/// desormais par `FondDeCarte`, seul endroit de `lib/` autorise a construire
/// une couche de tuiles — une garde structurelle y veille.
///
/// LA REGLE. Fichier present et lisible -> il GAGNE, meme quand le reseau est
/// la : c'est ce qui economise la batterie et le forfait du randonneur.
/// Fichier absent, abime ou illisible -> reseau, sans exception qui remonte.
sealed class ChoixDuFond {
  const ChoixDuFond();
}

/// Le fond vient du fichier telecharge du sentier.
final class FondDuFichier extends ChoixDuFond {
  /// Fond lu dans [chemin], qui couvre les zooms [zoomMin] a [zoomMax].
  const FondDuFichier({required this.chemin, this.zoomMin, this.zoomMax});

  /// Chemin absolu du `.mbtiles`.
  final String chemin;

  /// Plus petit niveau de zoom PRESENT dans le fichier (metadonnee `minzoom`).
  ///
  /// En dessous, le fichier n'a rien : sans relais, la vue d'ensemble d'un
  /// circuit (zoom 9 pour cent kilometres) serait blanche MEME EN LIGNE.
  final int? zoomMin;

  /// Plus grand niveau de zoom present (metadonnee `maxzoom`). Au-dela, les
  /// tuiles de ce niveau sont agrandies au lieu de laisser un fond vide.
  final int? zoomMax;

  @override
  bool operator ==(Object other) =>
      other is FondDuFichier &&
      other.chemin == chemin &&
      other.zoomMin == zoomMin &&
      other.zoomMax == zoomMax;

  @override
  int get hashCode => Object.hash(chemin, zoomMin, zoomMax);

  @override
  String toString() => 'FondDuFichier($chemin, z$zoomMin-$zoomMax)';
}

/// Le fond vient du reseau OpenStreetMap, pour la [raison] dite.
final class FondDuReseau extends ChoixDuFond {
  /// Fond venu du reseau, pour [raison].
  const FondDuReseau(this.raison);

  /// Pourquoi le fichier n'a pas ete retenu.
  final RaisonDuReseau raison;

  @override
  bool operator ==(Object other) =>
      other is FondDuReseau && other.raison == raison;

  @override
  int get hashCode => raison.hashCode;

  @override
  String toString() => 'FondDuReseau(${raison.name})';
}

/// Rend la decision du fond de carte pour un sentier.
class OfflineTileProvider {
  /// Decideur adosse au gestionnaire des fichiers de carte.
  OfflineTileProvider({required this.mbtilesManager});

  /// Ou sont les fichiers, et lesquels sont complets.
  final MBTilesManager mbtilesManager;

  /// URL template des tuiles OSM (le relais reseau).
  static const defaultTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Choisit le fond pour [trailId]. NE LEVE JAMAIS : toute panne rend
  /// [FondDuReseau], parce qu'une carte sans fond hors ligne vaut mieux
  /// qu'un ecran de navigation en erreur.
  Future<ChoixDuFond> choisir(String trailId) async {
    final String chemin;
    try {
      if (!await mbtilesManager.hasMbtiles(trailId)) {
        return const FondDuReseau(RaisonDuReseau.pasDeFichier);
      }
      chemin = await mbtilesManager.getMbtilesPath(trailId);
    } catch (e) {
      _log.w('[OfflineTileProvider] Dossier des cartes inaccessible: $e');
      return const FondDuReseau(RaisonDuReseau.dossierInaccessible);
    }
    return examinerLeFichier(chemin);
  }

  /// OUVRE le fichier et le SONDE avant de le declarer bon.
  ///
  /// Exister ne suffit pas : un `.mbtiles` est une base SQLite, et une base
  /// abimee ne se voit qu'a la premiere lecture — en montagne, sans reseau.
  /// L'ouverture lit les metadonnees, la sonde interroge la table des tuiles ;
  /// l'une ou l'autre qui leve, et c'est le reseau. La connexion d'examen est
  /// toujours refermee : la couche ouvre la sienne, dont elle a la charge.
  static ChoixDuFond examinerLeFichier(String chemin) {
    MbTilesTileProvider? examen;
    try {
      examen = MbTilesTileProvider.fromPath(path: chemin);
      final meta = examen.mbtiles.getMetadata();
      examen.mbtiles.getTile(z: 0, x: 0, y: 0);
      _log.d('[OfflineTileProvider] Fond hors ligne: $chemin');
      return FondDuFichier(
        chemin: chemin,
        zoomMin: meta.minZoom?.ceil(),
        zoomMax: meta.maxZoom?.floor(),
      );
    } catch (e) {
      _log.e('[OfflineTileProvider] Fichier de carte illisible ($chemin): $e');
      return const FondDuReseau(RaisonDuReseau.fichierIllisible);
    } finally {
      try {
        examen?.dispose();
      } catch (_) {
        // Fermer une base deja en echec ne doit pas masquer la decision.
      }
    }
  }

  /// Fabrique le fournisseur de tuiles qui REALISE [choix].
  ///
  /// Chaque appel ouvre une connexion neuve : une [TileLayer] dispose son
  /// fournisseur quand elle disparait, un fournisseur partage serait donc
  /// referme sous les pieds de la suivante. Si le fichier ne s'ouvre plus
  /// (efface entre la decision et l'affichage), c'est le reseau.
  static TileProvider fournisseurPour(ChoixDuFond choix) {
    if (choix is FondDuFichier) {
      try {
        return MbTilesTileProvider.fromPath(
          path: choix.chemin,
          silenceTileNotFound: true,
        );
      } catch (e) {
        _log.e('[OfflineTileProvider] Ouverture refusee, relais reseau: $e');
      }
    }
    return inertTileProviderOrNull() ?? NetworkTileProvider();
  }
}

/// Provider du OfflineTileProvider.
final offlineTileProviderFactoryProvider = Provider<OfflineTileProvider>((ref) {
  final manager = ref.watch(mbtilesManagerProvider);
  return OfflineTileProvider(mbtilesManager: manager);
});

/// La decision du fond pour un sentier.
///
/// `autoDispose` : la decision est relue a chaque ouverture d'une carte, donc
/// une carte telechargee entre deux visites est prise sans redemarrer l'app.
final choixDuFondProvider = FutureProvider.autoDispose
    .family<ChoixDuFond, String>((ref, trailId) {
      return ref.watch(offlineTileProviderFactoryProvider).choisir(trailId);
    });
