/// Detection d'une mise a jour cote Firestore, en amont du calcul de delta : il
/// dit QU'IL y a du neuf, pas ce qu'il faut descendre.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../data/daos/trail_manifests_dao.dart';
import '../data/revision_de_donnee.dart';
import '../firebase/firebase_service.dart';
import '../network/connectivity_monitor.dart';
import '../providers/database_provider.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Resultat de la detection de mise a jour pour un sentier.
class UpdateCheckResult {
  const UpdateCheckResult({
    required this.trailId,
    required this.hasUpdate,
    this.localVersion = HorodatageServeur.origine,
    this.remoteVersion = HorodatageServeur.origine,
  });

  /// Identifiant du sentier verifie.
  final String trailId;

  /// True si une nouvelle version est disponible.
  final bool hasUpdate;

  /// L INSTANT jusqu auquel ce telephone est a jour.
  final HorodatageServeur localVersion;

  /// L INSTANT de publication annonce cote serveur.
  final HorodatageServeur remoteVersion;
}

/// Service de detection des mises a jour de sentiers (E4.11b).
///
/// Compare la version du manifeste local (Drift) avec la version
/// distante (Firestore trails/{trailId}.data_version).
/// Complementaire de DeltaUpdateService : celui-ci detecte au niveau
/// Firestore (source temps reel), DeltaUpdateService calcule ensuite
/// le delta de tables a partir du manifeste.
///
/// Dependances : E4.3 (manifest model), E4.4b (Drift storage).
class UpdateChecker {
  UpdateChecker({
    required this.dao,
    required this.connectivityMonitor,
    required this.firebaseService,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore;

  final TrailManifestsDao dao;
  final ConnectivityMonitor connectivityMonitor;
  final FirebaseService firebaseService;
  FirebaseFirestore? _firestore;

  /// Accesseur Firestore (lazy init pour les tests).
  FirebaseFirestore get firestore => _firestore ??= FirebaseFirestore.instance;

  /// Verifie si un sentier a une mise a jour disponible.
  Future<UpdateCheckResult> checkForUpdate(String trailId) async {
    if (!firebaseService.isAvailable) {
      _log.d('[UpdateChecker] Firebase non disponible, check ignore');
      return UpdateCheckResult(trailId: trailId, hasUpdate: false);
    }

    final status = await connectivityMonitor.checkStatus();
    if (status == ConnectivityStatusValues.offline) {
      _log.d('[UpdateChecker] Hors ligne, check ignore');
      return UpdateCheckResult(trailId: trailId, hasUpdate: false);
    }

    try {
      final doc = await firestore.collection('trails').doc(trailId).get();

      if (!doc.exists || doc.data() == null) {
        _log.d('[UpdateChecker] Aucun document distant pour $trailId');
        return UpdateCheckResult(trailId: trailId, hasUpdate: false);
      }

      final remoteData = doc.data()!;
      final remoteVersion =
          HorodatageServeur.annonceParLeServeur(remoteData['data_version']) ??
          HorodatageServeur.origine;

      final localEntry = await dao.getByTrailId(trailId);
      final localVersion =
          localEntry?.localVersion ?? HorodatageServeur.origine;

      final hasUpdate = remoteVersion > localVersion;

      if (hasUpdate) {
        _log.d(
          '[UpdateChecker] MAJ disponible $trailId: '
          '$localVersion -> $remoteVersion',
        );
      }

      return UpdateCheckResult(
        trailId: trailId,
        hasUpdate: hasUpdate,
        localVersion: localVersion,
        remoteVersion: remoteVersion,
      );
    } catch (e) {
      _log.e('[UpdateChecker] Erreur check $trailId: $e');
      return UpdateCheckResult(trailId: trailId, hasUpdate: false);
    }
  }

  /// Verifie les mises a jour pour LES SENTIERS TELECHARGES SUR CE TELEPHONE.
  ///
  /// LE PERIMETRE EST CELUI DE CHRISTOPHE, 28/09 : « on telecharge tout ce qui
  /// concerne SES sentiers ». Pas le catalogue, SES sentiers.
  ///
  /// LE FILTRE S APPELAIT `getPossedes` ET LE NOM A ETE CORRIGE EN
  /// `getTelecharges` (tache 616) : il mesure la PRESENCE DES DONNEES, pas le droit
  /// d achat. Les deux sont deliberement independants, et un nom qui les melange
  /// invite a brancher la cadence sur les achats — ce qui raterait les sentiers
  /// gratuits copies et irait chercher les donnees de sentiers payes mais absents.
  ///
  /// CE QUE CETTE METHODE NE DIT PAS, ET C EST VOULU : A QUEL NIVEAU resynchroniser.
  /// Elle repond « lesquels sont en retard ». Le niveau de chaque sentier est relu
  /// en base par [OrdonnanceurDeSynchronisation], qui le passe a
  /// [UpdateDownloader.downloadAllUpdates].
  ///
  /// LE DEFAUT QUE CE FILTRE FERME, ET IL ETAIT MESURE, PAS SUPPOSE. La lecture du
  /// catalogue distant ecrit une ligne de `trail_manifests` pour CHAQUE sentier
  /// publie (`CatalogueSentiersNotifier._conserver`, tache 605) — c est ce qui fait
  /// survivre le catalogue au hors-ligne, et c est voulu. Mais ces lignes ont
  /// `localVersion` a NULL, et `needsUpdate` rend vrai des que `localVersion` est
  /// NULL. Cette methode parcourait `dao.getAll()` : sur un serveur portant
  /// quarante sentiers, un randonneur qui en possede UN declenchait donc la
  /// synchronisation des QUARANTE — quarante fichiers de donnees complets sur son
  /// forfait, et chacun depuis l origine, donc le sentier entier. C est exactement
  /// ce que Christophe a nomme.
  ///
  /// UN REPERE NON NUL EST LE CRITERE DE POSSESSION, et c est le meme fait que
  /// `DisponibiliteDuSentier.copieComplete` lit pour l ecran : le sentier a ete
  /// COPIE au moins une fois sur cet appareil. La premiere copie, elle, ne passe
  /// pas par ici : c est le geste « telecharger » du randonneur
  /// (`CatalogNotifier.downloadTrail`), ou [UpdateDownloader.downloadSingleUpdate]
  /// pour un sentier nomme. Ce chemin-ci est la mise a jour PERIODIQUE, et une mise
  /// a jour periodique n a rien a telecharger d un sentier qu on ne possede pas.
  Future<List<UpdateCheckResult>> checkAllForUpdates() async {
    if (!firebaseService.isAvailable) {
      return [];
    }

    final status = await connectivityMonitor.checkStatus();
    if (status == ConnectivityStatusValues.offline) {
      return [];
    }

    final localEntries = await dao.getTelecharges();
    final results = <UpdateCheckResult>[];

    for (final entry in localEntries) {
      final result = await checkForUpdate(entry.trailId);
      if (result.hasUpdate) {
        results.add(result);
      }
    }

    if (results.isNotEmpty) {
      _log.d('[UpdateChecker] ${results.length} MAJ disponible(s)');
    }

    return results;
  }
}

/// Provider Riverpod pour le service de detection de MAJ.
final updateCheckerProvider = Provider<UpdateChecker>((ref) {
  final db = ref.watch(databaseProvider);
  final connectivity = ref.watch(connectivityMonitorProvider);
  final firebase = ref.watch(firebaseServiceProvider);
  return UpdateChecker(
    dao: TrailManifestsDao(db),
    connectivityMonitor: connectivity,
    firebaseService: firebase,
  );
});
