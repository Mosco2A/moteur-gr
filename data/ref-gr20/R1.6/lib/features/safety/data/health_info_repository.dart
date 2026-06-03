// E5.16 — Repository informations sante LOCAL ONLY.
//
// Persistence locale via Hive. JAMAIS de Firestore.
// Les donnees medicales restent exclusivement sur le telephone.
// Fournit save/get/delete pour le formulaire HealthInfoScreen.

import 'package:hive/hive.dart';

import '../domain/models/health_info.dart';

/// Repository LOCAL pour les informations de sante.
///
/// Utilise Hive (box 'health_info') pour stocker les donnees
/// medicales du randonneur. Aucune synchronisation cloud.
///
/// IMPORTANT : ces donnees ne quittent JAMAIS le telephone.
/// Pas de Firestore, pas de Firebase, pas de sync.
class HealthInfoRepository {
  HealthInfoRepository();

  /// Nom de la box Hive pour les donnees sante.
  static const String _boxName = 'health_info';

  /// Cle unique dans la box (un seul profil sante par telephone).
  static const String _key = 'user_health';

  /// Sauvegarde les informations de sante en local.
  ///
  /// Ecrase les donnees precedentes (un seul profil).
  Future<void> save(HealthInfo info) async {
    final box = await Hive.openBox<Map>(_boxName);
    await box.put(_key, info.toJson());
  }

  /// Recupere les informations de sante depuis le stockage local.
  ///
  /// Retourne un [HealthInfo] vide (champs '') si aucune donnee
  /// n'a encore ete sauvegardee. Ne retourne JAMAIS null.
  Future<HealthInfo> get() async {
    final box = await Hive.openBox<Map>(_boxName);
    final raw = box.get(_key);

    if (raw == null) return const HealthInfo();

    // Hive retourne Map<dynamic, dynamic> — convertir en Map<String, dynamic>
    final json = Map<String, dynamic>.from(raw);
    return HealthInfo.fromJson(json);
  }

  /// Supprime toutes les informations de sante du telephone.
  ///
  /// Utilise en cas de deconnexion ou demande explicite de l'utilisateur.
  Future<void> delete() async {
    final box = await Hive.openBox<Map>(_boxName);
    await box.delete(_key);
  }
}
