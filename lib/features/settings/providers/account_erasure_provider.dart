// TACHE 562 (LOT K, K1) — LE CHAINON QUI MANQUAIT ENTRE LE DROIT ET LE
// RANDONNEUR.
//
// `DataRetentionService.deleteAccountData` etait correct et prouve par
// vingt-six tests au terme du LOT J, et il n'avait AUCUN APPELANT : pas de
// provider, pas d'ecran, pas de bouton. Un droit qu'on ne peut pas exercer n'est
// pas un droit. Ce fichier est la couche qui le rend atteignable depuis l'UI.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/database_provider.dart';
import '../../../core/services/data_retention_service.dart';

/// Service de retention / droit a l'effacement, branche sur la base REELLE de
/// l'application et sur les preferences REELLES.
///
/// `FutureProvider` parce que `SharedPreferences.getInstance()` est
/// asynchrone ; la base vient de [databaseProvider], donc de la meme instance
/// que le reste de l'app (un effacement sur une autre instance n'effacerait
/// rien de ce que le randonneur voit).
final dataRetentionServiceProvider =
    FutureProvider<DataRetentionService>((ref) async {
  final db = ref.watch(databaseProvider);
  final prefs = await SharedPreferences.getInstance();
  return DataRetentionService(database: db, prefs: prefs);
});

/// Signature de l'effacement du compte. Injectable : un ecran ne doit pas avoir
/// besoin d'une base pour etre teste, et l'effacement reel doit pouvoir etre
/// observe dans un test d'ecran.
typedef AccountErasure = Future<DeletionReport> Function();

/// L'effacement du compte, tel que l'UI l'appelle.
///
/// PERIMETRE, DIT SANS ARRONDI : l'effacement est LOCAL. Aucune demande de
/// suppression serveur n'est emise, pour une raison et une seule — il n'existe
/// aujourd'hui aucun compte serveur a supprimer : Firebase n'est pas connecte
/// avant la phase 4, aucun identifiant hache n'est attribue, et les gardes de
/// l'article 9 refusent tout envoi sans consentement. Le jour ou un miroir cloud
/// existera, il faudra passer ici l'`uidHash` et une `ServerDeletionRequest` :
/// `deleteAccountData` sait deja les emettre EN PREMIER et laisse remonter
/// l'erreur. Le libelle montre au randonneur ne promet donc rien de plus que ce
/// qui est fait.
final accountErasureProvider = Provider<AccountErasure>((ref) {
  return () async {
    final service = await ref.read(dataRetentionServiceProvider.future);
    return service.deleteAccountData();
  };
});
