import 'dart:math' as math;

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
/// Formule d'estimation (repli) : LE modele de temps de marche de la maison,
/// decrit par [walkingSeconds] juste en dessous. Un seul modele vit dans ce
/// depot, et c'est celui-la : la duree affichee reste coherente que la donnee
/// vienne du sentier ou de l'estimation, et que le calcul soit fait a la
/// preparation ou en marchant.

/// IL N'Y A PLUS QU'UN SEUL MODELE DE TEMPS DE MARCHE, ET C'EST LE PRUDENT
/// (tache 839).
///
/// CE QUI EXISTAIT, ET SE CONTREDISAIT. Le depot portait DEUX modeles mesures
/// par la tache 838 :
///  1. ici meme, une Naismith simplifiee — distance / 4 km/h + D+ / 400 m/h —
///     ou LA DESCENTE NE COUTAIT RIEN. C'est elle qui decide combien de jours
///     fait un sentier (`ItineraryCalculator`, `PlanningCalculator`,
///     `PlannedDay`, la fiche d'etape, l'ecran d'itineraire) ;
///  2. dans `eta_service.dart`, une Naismith raffinee — 1,1 m/s a plat,
///     600 m/h de montee, descente a 1,67 s par metre. C'est elle qui annonce
///     l'heure d'arrivee en marchant.
/// SUR UNE MONTEE DE 200 m EN 1 km, la premiere rendait 45 min et la seconde
/// 35 min : 29 % d'ecart entre le programme qu'on prepare et l'heure qu'on
/// annonce, sur la meme montagne et pour le meme marcheur.
///
/// CE QUI RESTE, ET POURQUOI C'EST CELUI-LA. Les trois constantes ci-dessous
/// prennent, de chaque modele, la valeur la plus PRUDENTE : 4 km/h a plat
/// (et non 3,96 obtenu par un 1,1 m/s), 400 m de montee a l'heure (et non 600,
/// qui est une allure d'entraine), et la descente PAYEE a 1,67 s par metre (et
/// non gratuite). En montagne on n'annonce pas des horaires optimistes : une
/// estimation trop courte se paie a la tombee de la nuit.
///
/// LA DESCENTE COUTE DESORMAIS QUELQUE CHOSE PARTOUT, et cela change des
/// durees d'etape : sur le GR20, l'etape 16 descend 1 094 m pour 300 m de
/// montee — la gratuite de la descente lui faisait annoncer 4h04 au lieu de
/// 4h34. C'est exactement le genre de journee ou l'erreur se voit sur le
/// terrain.
///
/// La vitesse a plat reste SURCHARGEABLE (`flatPaceMps`) : en marchant,
/// `EtaService` y injecte la vitesse REELLE observee du randonneur. C'est un
/// RAFFINEMENT du meme modele, pas un second modele — les deux penalites de
/// relief, elles, ne se negocient pas.

/// Vitesse a plat de reference (km/h) — unique dans le depot.
const double kWalkingKmPerHour = 4.0;

/// Denivele positif absorbe par heure (m/h) — unique dans le depot.
const double kWalkingElevationMPerHour = 400.0;

/// Vitesse a plat de reference, en m/s — DERIVEE de [kWalkingKmPerHour].
///
/// Derivee et non ecrite : deux constantes pour une seule vitesse, c'est la
/// garantie qu'un jour l'une changera sans l'autre. C'est precisement ce qui
/// s'etait passe (4,0 km/h d'un cote, 1,1 m/s soit 3,96 km/h de l'autre).
const double kWalkingFlatPaceMps = kWalkingKmPerHour * 1000.0 / 3600.0;

/// Secondes ajoutees par metre de MONTEE — derivee de
/// [kWalkingElevationMPerHour] (400 m/h -> 9 s/m).
const double kWalkingAscentSecondsPerMetre = 3600.0 / kWalkingElevationMPerHour;

/// Secondes ajoutees par metre de DESCENTE (Tranter/Langmuir simplifie).
///
/// 1,67 s/m. La descente n'est pas gratuite : elle fatigue, elle ralentit sur
/// les dalles et les eboulis, et le GR20 en compte 11 628 m.
const double kWalkingDescentSecondsPerMetre = 10.0 / 6.0;

/// LE temps de marche, en SECONDES : la seule implementation du depot.
///
/// temps = distance / vitesseAPlat
///       + montee * [kWalkingAscentSecondsPerMetre]
///       + descente * [kWalkingDescentSecondsPerMetre]
///
/// [flatPaceMps] remplace la vitesse a plat de reference quand une vitesse
/// REELLE est observee (GPS lisse, en marchant). Nulle, negative ou non finie,
/// elle est ignoree et [kWalkingFlatPaceMps] s'applique ; elle est bornee par
/// le bas a [kWalkingFloorPaceMps] pour qu'une vitesse quasi nulle ne produise
/// pas un temps infini.
///
/// Toute entree non finie ou negative compte pour zero : une mesure absente ne
/// doit jamais devenir une duree inventee. Fonction PURE.
double walkingSeconds({
  required double distanceMetres,
  required double ascentMetres,
  required double descentMetres,
  double? flatPaceMps,
}) {
  final observed = flatPaceMps;
  final pace = observed != null && observed.isFinite && observed > 0
      ? math.max(observed, kWalkingFloorPaceMps)
      : kWalkingFlatPaceMps;
  final distance = distanceMetres.isFinite && distanceMetres > 0
      ? distanceMetres
      : 0.0;
  final ascent = ascentMetres.isFinite && ascentMetres > 0 ? ascentMetres : 0.0;
  final descent = descentMetres.isFinite && descentMetres > 0
      ? descentMetres
      : 0.0;
  return distance / pace +
      ascent * kWalkingAscentSecondsPerMetre +
      descent * kWalkingDescentSecondsPerMetre;
}

/// Vitesse plancher (m/s) : evite un temps infini quand la vitesse observee
/// tombe a zero (on suppose une marche lente residuelle).
const double kWalkingFloorPaceMps = 0.5;

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
    // LA DESCENTE EST PASSEE (tache 839) : l'etape la connait, le modele la
    // paie. L'ignorer ici aurait laisse survivre, en pratique, le modele
    // « descente gratuite » que ce lot retire.
    elevationLossM: stage.elevationLossM,
  );
}

/// True si la duree affichee provient de la donnee du sentier (et non d'une
/// estimation). Utile pour nuancer l'UI (ex. libelle « estimee »).
bool hasProvidedDuration(StageModel stage) {
  final provided = stage.estimatedDurationMinutes;
  return provided != null && provided > 0;
}

/// Estimation (minutes) depuis distance, montee et descente, calculee par
/// [walkingSeconds].
///
/// Isolee pour etre testable et reutilisable hors [StageModel] (ex. agregats
/// jour). Arrondie a la minute.
///
/// [elevationLossM] vaut zero par defaut : une source qui ne connait pas sa
/// descente n'en paie pas, et c'est la seule reponse honnete. Toute source qui
/// la connait doit la passer — sinon la descente redevient gratuite sans que
/// personne l'ait decide.
int estimatedStageDurationMinutes({
  required double distanceKm,
  required int elevationGainM,
  int elevationLossM = 0,
}) {
  final seconds = walkingSeconds(
    distanceMetres: distanceKm * 1000.0,
    ascentMetres: elevationGainM.toDouble(),
    descentMetres: elevationLossM.toDouble(),
  );
  return (seconds / 60.0).round();
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
