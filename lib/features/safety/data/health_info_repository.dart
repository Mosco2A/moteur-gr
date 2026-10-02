/// La fiche medicale a quitte la base commune pour un fichier a elle : la base
/// doit remonter dans la sauvegarde, elle non.
library;

// E5.16 — Repository informations sante LOCAL ONLY.
//
// Persistance locale dans un FICHIER DEDIE, sous le dossier declare exclu de la
// sauvegarde du telephone (tache 613). JAMAIS de Firestore. Les donnees
// medicales restent exclusivement sur le telephone.
// Fournit save/get/delete pour HealthInfoScreen.

import '../domain/models/health_info.dart';
import 'fiche_medicale_fichier.dart';

/// Repository LOCAL pour les informations de sante.
///
/// IL A CHANGE DE STOCKAGE A LA TACHE 613, ET LA RAISON EST ECRITE EN ENTIER
/// DANS [FicheMedicaleFichier] : la fiche vivait dans la table `health_info` de
/// la base commune, or cette base est devenue DURABLE et doit remonter dans la
/// sauvegarde du telephone pour que la progression et le journal survivent au
/// changement d'appareil. Un fichier de base ne s'exclut pas table par table :
/// la fiche a donc son propre fichier, dans le dossier declare exclu.
///
/// IMPORTANT : ces donnees ne quittent JAMAIS le telephone. Pas de Firestore,
/// pas de Firebase, pas de sync.
class HealthInfoRepository {
  HealthInfoRepository({required this.fichier});

  /// Le stockage durable de la fiche (un fichier sous `medical/`).
  final FicheMedicaleFichier fichier;

  /// Sauvegarde les informations de sante en local.
  ///
  /// Ecrase les donnees precedentes (un seul profil).
  Future<void> save(HealthInfo info) => fichier.ecrire(info);

  /// Recupere les informations de sante depuis le stockage local.
  ///
  /// Retourne un [HealthInfo] vide (champs '') si aucune donnee
  /// n'a encore ete sauvegardee. Ne retourne JAMAIS null.
  Future<HealthInfo> get() => fichier.lire();

  /// Supprime toutes les informations de sante du telephone.
  ///
  /// Utilise en cas de deconnexion ou demande explicite de l'utilisateur.
  Future<void> delete() => fichier.effacer();
}
