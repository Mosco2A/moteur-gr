import 'package:shared_preferences/shared_preferences.dart';

/// STOCKAGE DURABLE DU DECOUPAGE RETENU (correctif N2 / D2, mandat #100293).
///
/// POURQUOI CE FICHIER EXISTE. Le bouton « Generer mon programme (N jours) »
/// de la Faisabilite ecrivait bien la duree — mais dans un `Notifier` en
/// MEMOIRE VIVE uniquement. Resultat a l'ecran : choisir le decoupage propose
/// ne laissait aucune trace. Rien ne disait que N jours etait desormais le
/// plan retenu, et la moindre relance de l'application ramenait la duree par
/// defaut du sentier. C'etait l'un des deux defauts trouves par Chris.
///
/// Le decoupage retenu est une DECISION du randonneur, pas un etat d'ecran :
/// il se range donc a cote des autres decisions durables de la preparation
/// (fiche profil, randos passees, date de depart) — SharedPreferences, source
/// durable de l'application (la base Drift tourne en memoire, cf.
/// `hiker_profile_repository.dart`).
///
/// UNE CLE PAR SENTIER : le moteur est multi-sentiers, deux sentiers ont deux
/// plans. Aucun identifiant en dur.

/// Prefixe SharedPreferences du decoupage retenu (nombre de jours).
const String kRetainedDurationPrefsPrefix = 'planning.retainedDuration.';

/// Cle SharedPreferences du decoupage retenu pour [trailId].
String retainedDurationPrefsKey(String trailId) =>
    '$kRetainedDurationPrefsPrefix$trailId';

/// Lecture / ecriture du decoupage retenu, isolees du graphe Riverpod.
///
/// Toutes les operations sont DEFENSIVES : un stockage indisponible (tests
/// unitaires sans mock de plateforme, prefs corrompues) ne doit jamais faire
/// tomber la preparation. Dans ce cas on se comporte comme « aucun decoupage
/// retenu » et le sentier garde sa duree par defaut.
class RetainedPlanStore {
  const RetainedPlanStore();

  /// Decoupage retenu pour [trailId], ou `null` si le randonneur n'a encore
  /// rien choisi (ou si le stockage est indisponible).
  Future<int?> read(String trailId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final days = prefs.getInt(retainedDurationPrefsKey(trailId));
      // Une duree nulle ou negative n'a aucun sens : on la traite comme absente.
      return (days != null && days > 0) ? days : null;
    } catch (_) {
      return null;
    }
  }

  /// Retient [days] jours pour [trailId] (decision durable).
  Future<void> write(String trailId, int days) async {
    if (days <= 0) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(retainedDurationPrefsKey(trailId), days);
    } catch (_) {
      // Stockage indisponible : le choix reste actif pour la session en cours.
    }
  }

  /// Oublie le decoupage retenu pour [trailId] (retour a la duree du sentier).
  Future<void> clear(String trailId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(retainedDurationPrefsKey(trailId));
    } catch (_) {
      // Rien a faire : il n'y avait de toute facon rien a oublier.
    }
  }
}
