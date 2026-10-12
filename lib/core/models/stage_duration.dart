import 'stage_row.dart';

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
      distanceKm / kWalkingKmPerHour +
      elevationGainM / kWalkingElevationMPerHour;
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

/// LES MINUTES D'UNE DUREE, TOUJOURS SUR DEUX CHIFFRES (tache 835).
///
/// Ex. 5 h 03 min -> « 03 », 5 h 30 -> « 30 ». A passer a une phrase de
/// traduction qui porte deja le mot « h » et le mot « min » : c'est le cas de
/// `eta.durationHm`, dont la forme (« $h h $m min ») est editoriale et vit
/// dans les cinq fichiers de langue, donc hors de ce formateur.
///
/// POURQUOI CETTE FONCTION EXISTE. Le recapitulatif, le journal et l'ETA
/// recalculaient tous les trois `inHours` et `inMinutes.remainder(60)` a la
/// main, et tous les trois OUBLIAIENT le zero : le randonneur lisait « 5 H 3 »
/// pour cinq heures et trois minutes. Onze AUTRES endroits du depot font le
/// meme calcul et pensent, eux, a le zero-padder — la preuve que le geste est
/// juste mais qu'il ne doit pas etre recopie douze fois.
String deuxChiffresDeMinutes(Duration duree) {
  final m = duree.inMinutes.remainder(60).abs();
  return m.toString().padLeft(2, '0');
}

/// UNE DUREE ECRITE POUR L'ECRAN : « 5h03 », « 4h », « 45 min ».
///
/// Sous l'heure, on ecrit les minutes seules : « 0h45 » se lit mal et ce
/// n'etait pas ce que faisaient les ecrans avant ce lot. Au-dela, on delegue a
/// [formatDurationMinutes], qui est la forme maison (parite GR20) deja employee
/// par l'ecran d'itineraire et deja couverte par
/// `test/core/models/stage_duration_test.dart`.
///
/// CE QUE CE LOT CHANGE A L'ECRAN, ET C'EST ASSUME : le recapitulatif et le
/// journal ecrivaient « 5 h 3 » avec des espaces. Ils ecrivent desormais
/// « 5h03 », donc comme l'ecran d'itineraire. Le defaut corrige est le zero
/// manquant ; l'alignement sur la forme maison est le benefice de ne plus avoir
/// douze formateurs de duree, mais UN seul.
String formatDuree(Duration duree) {
  final minutes = duree.inMinutes < 0 ? 0 : duree.inMinutes;
  if (minutes < 60) return '$minutes min';
  return formatDurationMinutes(minutes);
}
