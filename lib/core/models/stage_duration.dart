import 'stage.dart';

/// Duree d'etape — source unique de verite (parite GR20, socle « donnees
/// externes »).
///
/// Le modele generique [StageModel] porte desormais une duree RICHE optionnelle
/// ([StageModel.estimatedDurationMinutes]) alimentee par la donnee du sentier
/// (`assets/data/<trail>/stages.json`, backend en P4). Quand la donnee est
/// presente, elle FAIT AUTORITE. Quand elle est absente (sentier plus pauvre,
/// ex. test-trail), on retombe proprement sur une ESTIMATION documentee — aucun
/// crash, affichage degrade coherent.
///
/// Formule d'estimation (repli) : regle de marche « Naismith simplifiee » deja
/// utilisee par le moteur d'itineraire et de planning cote StepWays :
///   duree = distance / 4 km/h + denivele positif / 400 m/h
/// soit 15 min par km a plat + 15 min par 100 m de montee. Coefficients
/// identiques a [ItineraryCalculator] / [PlanningCalculator] : la duree affichee
/// reste coherente que la donnee vienne du sentier ou de l'estimation.

/// Vitesse a plat de reference (km/h) — regle de marche Naismith simplifiee.
const double kWalkingKmPerHour = 4.0;

/// Denivele positif absorbe par heure (m/h) — regle de marche Naismith.
const double kWalkingElevationMPerHour = 400.0;

/// Duree estimee d'une etape, en MINUTES.
///
/// Retourne la donnee du sentier ([StageModel.estimatedDurationMinutes]) si elle
/// est presente ET strictement positive ; sinon l'estimation Naismith calculee
/// depuis distance + D+. Toujours >= 0.
int stageDurationMinutes(StageModel stage) {
  final provided = stage.estimatedDurationMinutes;
  if (provided != null && provided > 0) return provided;
  return estimatedStageDurationMinutes(
    distanceKm: stage.distanceKm,
    elevationGainM: stage.elevationGainM,
  );
}

/// True si la duree affichee provient de la donnee du sentier (et non d'une
/// estimation). Utile pour nuancer l'UI (ex. libelle « estimee »).
bool hasProvidedDuration(StageModel stage) {
  final provided = stage.estimatedDurationMinutes;
  return provided != null && provided > 0;
}

/// Estimation Naismith simplifiee (minutes) depuis distance + denivele positif.
///
/// Isolee pour etre testable et reutilisable hors [StageModel] (ex. agregats
/// jour). Arrondie a la minute.
int estimatedStageDurationMinutes({
  required double distanceKm,
  required int elevationGainM,
}) {
  final hours =
      distanceKm / kWalkingKmPerHour + elevationGainM / kWalkingElevationMPerHour;
  return (hours * 60).round();
}

/// Duree totale (minutes) d'un ensemble d'etapes, en respectant pour CHAQUE
/// etape la donnee du sentier quand elle existe, sinon l'estimation.
///
/// A privilegier pour les totaux jour/itineraire afin que la duree affichee soit
/// coherente avec celle des etapes prises une a une.
int totalStagesDurationMinutes(Iterable<StageModel> stages) =>
    stages.fold<int>(0, (sum, s) => sum + stageDurationMinutes(s));

/// Formate une duree en minutes vers « Xh » ou « XhMM » (parite GR20).
///
/// Ex. 350 -> « 5h50 », 240 -> « 4h », 65 -> « 1h05 ». Les minutes sont
/// zero-paddees a deux chiffres quand non nulles.
String formatDurationMinutes(int minutes) {
  final safe = minutes < 0 ? 0 : minutes;
  final h = safe ~/ 60;
  final m = safe % 60;
  return m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2, '0')}';
}
