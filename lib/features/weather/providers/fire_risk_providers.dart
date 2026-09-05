import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/trail_engine.dart';
import '../../trail/providers/stages_provider.dart';
import '../domain/fire_risk.dart';
import '../domain/fire_risk_catalog.dart';
import 'weather_providers.dart';

// ---------------------------------------------------------------------------
// Providers RISQUE INCENDIE (parite GR20 `FireRiskScreen`).
//
// GR20 : le niveau de risque (0-5) est un champ `DayForecast.fireRiskLevel`
// produit par le provider meteo ; l'ecran lit `weatherResultProvider` (toutes
// les etapes d'un coup) et regroupe par etape. Cote StepWays, la meteo est
// chargee PAR ETAPE (offline-first, [stageWeatherProvider] family, coords
// dynamiques Drift) : on REUTILISE cette source (parite GR20) et on DERIVE le
// niveau via [calculateFireRiskLevel] (meme algorithme que GR20), puis on
// AGREGE par etape. Zero nouveau socle meteo, zero hardcode de localite.
// ---------------------------------------------------------------------------

/// Niveau de risque incendie d'UN JOUR d'une etape (parite GR20 : detail par
/// jour de la carte d'etape).
///
/// [dayLabel] est resolu cote UI via Slang (Aujourd'hui / Demain / J+n) a partir
/// de [dayIndex] — le modele reste pur (aucune dependance Slang). [level] est le
/// niveau 0-5 derive de la meteo du jour ([calculateFireRiskLevel]).
class FireRiskDay {
  const FireRiskDay({required this.dayIndex, required this.level});

  /// Index du jour dans la prevision (0 = aujourd'hui, 1 = demain, ...).
  final int dayIndex;

  /// Niveau de risque incendie 0-5 (0 = aucun, 5 = extreme).
  final int level;
}

/// Risque incendie AGREGE d'une etape (parite GR20 : une carte d'etape a risque).
///
/// Porte le numero et le nom de l'etape (donnees du sentier) et la liste des
/// niveaux par jour. Le niveau MAX de l'etape ([maxLevel]) sert au tri et au
/// badge « Niv. X » (parite GR20 `_buildStageFireCard`).
class StageFireRisk {
  const StageFireRisk({
    required this.stageNumber,
    required this.stageName,
    required this.days,
  });

  /// Numero de l'etape (1-indexed).
  final int stageNumber;

  /// Nom de l'etape (donnee du sentier).
  final String stageName;

  /// Niveau de risque par jour (parite GR20 : detail par jour).
  final List<FireRiskDay> days;

  /// Niveau de risque MAXIMAL de l'etape (0 si aucune donnee) — tri + badge.
  int get maxLevel =>
      days.isEmpty ? 0 : days.map((d) => d.level).reduce((a, b) => a > b ? a : b);

  /// Vrai si l'etape presente au moins un jour a risque (niveau >= 1) — parite
  /// GR20 : seules les etapes a risque sont listees.
  bool get hasRisk => maxLevel >= 1;
}

/// Etat AGREGE du risque incendie du sentier (parite GR20 `WeatherResult` cote
/// risque : liste d'etapes + fraicheur/source globale).
///
/// [stages] = risque par etape (deja calcule). [isLoading] est vrai tant qu'au
/// moins une etape n'a pas fini de charger sa meteo (l'ecran affiche alors un
/// indicateur). [hasAnyForecast] indique si AU MOINS une etape a une prevision
/// exploitable (sinon fallback informatif « donnees indisponibles »).
class FireRiskState {
  const FireRiskState({
    required this.stages,
    required this.isLoading,
    required this.hasAnyForecast,
  });

  /// Risque par etape (toutes les etapes, y compris a niveau 0).
  final List<StageFireRisk> stages;

  /// Vrai tant qu'une etape au moins charge encore sa meteo.
  final bool isLoading;

  /// Vrai si au moins une etape a une prevision meteo exploitable.
  final bool hasAnyForecast;

  /// Etapes A RISQUE (niveau max >= 1), triees du plus eleve au plus bas (parite
  /// GR20 : filtre niveau >= 1 + tri decroissant).
  List<StageFireRisk> get stagesAtRisk {
    final risky = stages.where((s) => s.hasRisk).toList()
      ..sort((a, b) => b.maxLevel.compareTo(a.maxLevel));
    return risky;
  }
}

/// Provider AGREGE du risque incendie du sentier [trailId] (parite GR20 :
/// l'ecran lit une source unique et regroupe par etape).
///
/// Reutilise la source meteo StepWays PAR ETAPE ([stageWeatherProvider], coords
/// dynamiques + cache/API) et DERIVE le niveau par jour via
/// [calculateFireRiskLevel] (algorithme GR20). Family par `trailId` (isolation
/// multi-sentiers, coherent avec [stagesProvider] / le scope transport/shop).
///
/// Retourne un [FireRiskState] toujours non-null : tant que les etapes ne sont
/// pas chargees -> `isLoading: true`, liste vide (l'ecran montre le loader).
final trailFireRiskProvider =
    Provider.family<FireRiskState, String>((ref, trailId) {
  // Etapes du sentier (nom + numero). AsyncValue -> valeur chargee seulement.
  final stagesAsync = ref.watch(stagesProvider(trailId));
  final stages = stagesAsync.value;

  if (stages == null || stages.isEmpty) {
    // Etapes pas encore chargees (ou sentier vide) : etat de chargement.
    return FireRiskState(
      stages: const [],
      isLoading: stagesAsync.isLoading,
      hasAnyForecast: false,
    );
  }

  // Ordre officiel : croissant par numero d'etape (source unique de l'ordre,
  // comme le reste du moteur).
  final ordered = [...stages]
    ..sort((a, b) => a.stageNumber.compareTo(b.stageNumber));

  final result = <StageFireRisk>[];
  var anyForecast = false;
  var anyLoading = false;

  for (final stage in ordered) {
    final params = WeatherStageParams(
      trailId: trailId,
      stageNumber: stage.stageNumber,
    );
    // Prevision de l'etape via le socle meteo (select forecast). Chargee
    // paresseusement : null tant que le provider n'a pas resolu cache/API.
    final weatherState = ref.watch(stageWeatherProvider(params));
    final forecast = weatherState.forecast;

    if (weatherState.isLoading && forecast == null) {
      anyLoading = true;
    }

    if (forecast == null || forecast.days.isEmpty) {
      // Pas de prevision pour cette etape : niveau 0 (aucune donnee) — l'etape
      // ne remontera pas dans « a risque » (parite GR20 : filtre niveau >= 1).
      result.add(StageFireRisk(
        stageNumber: stage.stageNumber,
        stageName: stage.name,
        days: const [],
      ));
      continue;
    }

    anyForecast = true;
    final days = <FireRiskDay>[];
    for (var i = 0; i < forecast.days.length; i++) {
      final d = forecast.days[i];
      days.add(FireRiskDay(
        dayIndex: i,
        level: calculateFireRiskLevel(
          temperatureMax: d.temperatureMax,
          windSpeedKmh: d.windSpeedKmh,
          precipitationMm: d.precipitationMm,
          precipitationProbability: d.precipitationProbabilityMax,
        ),
      ));
    }

    result.add(StageFireRisk(
      stageNumber: stage.stageNumber,
      stageName: stage.name,
      days: days,
    ));
  }

  return FireRiskState(
    stages: result,
    isLoading: anyLoading,
    hasAnyForecast: anyForecast,
  );
});

/// Reglementation incendie du sentier [trailId] (catalogue embarque, offline).
///
/// Simple lecture du [FireRiskCatalog] (data-driven, genericite #84627).
/// Retourne `null` si le sentier ne fournit pas de reglementation -> l'ecran
/// masque proprement la section reglementation (le reste reste actif). Family
/// par `trailId`. Le backend (Phase 4) remplacera la source du catalogue.
final trailFireRegulationProvider =
    Provider.family<FireRegulation?, String>((ref, trailId) {
  final data = FireRiskCatalog.forTrail(trailId);
  return (data != null && data.regulation.hasContent) ? data.regulation : null;
});

/// Un numero d'urgence affichable sur l'ecran incendie (parite GR20 : liste
/// « Numeros utiles » tappables). Modele pur (libelle universel resolu cote UI).
class FireEmergencyNumber {
  const FireEmergencyNumber({
    required this.phone,
    this.labelKey,
    this.labelData,
  });

  /// Numero a appeler (tel:).
  final String phone;

  /// Cle i18n du libelle quand le numero est UNIVERSEL (18 pompiers, 112 secours
  /// europeens) — resolu cote UI via Slang. Null pour un numero regional.
  final String? labelKey;

  /// Libelle du numero quand il vient de la DONNEE du sentier (secours regional,
  /// langue de la donnee). Null pour un numero universel (voir [labelKey]).
  final String? labelData;

  /// Vrai si le libelle est universel (traduit via [labelKey]).
  bool get isUniversal => labelKey != null;
}

/// Cles i18n stables pour les libelles des numeros UNIVERSELS (resolues cote UI).
class FireEmergencyLabelKeys {
  const FireEmergencyLabelKeys._();

  /// Pompiers (18) — numero national francais.
  static const firefighters = 'firefighters';

  /// Secours europeens (112) — numero d'urgence europeen universel.
  static const europeanEmergency = 'europeanEmergency';
}

/// Numeros d'urgence du sentier [trailId] pour l'ecran incendie (parite GR20 :
/// 18 / 112 universels + secours regional).
///
/// DATA-DRIVEN + HONNETETE (#99460) : le 18 (pompiers FR) et le 112 (secours
/// europeens) sont UNIVERSELS et geres par le moteur (libelles traduits via
/// Slang) ; les numeros REGIONAUX (ex. secours montagne) viennent de la DONNEE
/// du sentier ([TrailConfig.emergencyNumbers]) — jamais inventes. Aucun numero
/// local en dur dans le moteur. Family par `trailId`.
final fireEmergencyNumbersProvider =
    Provider.family<List<FireEmergencyNumber>, String>((ref, trailId) {
  final config = ref.watch(trailConfigProvider);

  return [
    // Universels (moteur) : pompiers FR + secours europeens. Libelles i18n.
    const FireEmergencyNumber(
      phone: '18',
      labelKey: FireEmergencyLabelKeys.firefighters,
    ),
    const FireEmergencyNumber(
      phone: '112',
      labelKey: FireEmergencyLabelKeys.europeanEmergency,
    ),
    // Regionaux (donnee du sentier) : secours locaux fournis par la config.
    for (final n in config.emergencyNumbers)
      FireEmergencyNumber(phone: n.phone, labelData: n.name),
  ];
});
