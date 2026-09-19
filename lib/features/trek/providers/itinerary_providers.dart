import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/engine/trail_engine.dart';
import '../domain/models/feasibility_profile.dart';
import '../domain/models/itinerary_config.dart';
import '../domain/models/itinerary_day.dart';
import '../../planning/models/planned_day.dart';
import '../../planning/providers/planned_days_provider.dart';

/// Configuration d'itineraire (LEGACY — conservee pour l'ecran de configuration
/// avance `ItineraryConfigScreen`).
///
/// R3 (#100122, source unique des jours = D2) : le NOMBRE de jours de
/// l'itineraire n'est plus pilote par cette config (maxKm/maxHeures) mais par la
/// SOURCE UNIQUE `selectedDurationProvider` / [plannedDaysProvider]. Cette config
/// reste disponible pour d'eventuels reglages fins mais ne recompose plus les
/// jours (fini les deux modeles desynchronises).
final itineraryConfigProvider = StateProvider<ItineraryConfig>(
  (ref) => ItineraryConfig(
    maxKmPerDay: 20.0,
    maxHoursPerDay: 8.0,
    startDate: DateTime.now(),
    difficultyLevel: 'moderate',
  ),
);

/// Profil de faisabilite par defaut (solo, intermediaire) — LEGACY (voir
/// [itineraryConfigProvider]). Overridable pour supporter le mode groupe.
final feasibilityProfileProvider = StateProvider<FeasibilityProfile>(
  (ref) => const FeasibilityProfile(
    fitnessLevel: 'intermediate',
    experience: 'experienced',
    maxKmPerDay: 25.0,
    maxHoursPerDay: 10.0,
  ),
);

/// Provider de l'itineraire affiche — DERIVE DE LA SOURCE UNIQUE DES JOURS (R3).
///
/// AVANT (bug R3, deux modeles desynchronises) : l'itineraire etait calcule par
/// `ItineraryCalculator` a partir d'un plafond km/heures ([itineraryConfigProvider])
/// TOTALEMENT independant du nombre de jours du Programme
/// ([selectedDurationProvider] / [plannedDaysProvider]). Reduire les jours dans
/// le Programme ne touchait donc PAS l'Itineraire.
///
/// APRES (decision Chris #100122 / D2) : l'itineraire DERIVE du PROGRAMME
/// editable ([plannedDaysProvider]) du sentier actif — la SOURCE UNIQUE. Le
/// Programme repartit deja les etapes sur `selectedDurationProvider` (et honore
/// le sens de marche + les jours de repos). On se contente donc de PROJETER
/// chaque [PlannedDay] en [ItineraryDay] : ainsi, reduire les jours (ou editer le
/// Programme : regrouper / separer / repos / reordonner) recompose
/// IMMEDIATEMENT l'itineraire. Le sens de marche est deja applique en amont par
/// [plannedDaysProvider] : on ne le re-applique PAS ici (sinon double inversion).
///
/// Reste un [FutureProvider] (l'ecran Itineraire et `trekRequirementsProvider`
/// consomment `.future` / `.when`) meme si la derivation est synchrone.
final itineraryProvider = FutureProvider<List<ItineraryDay>>((ref) async {
  // Source unique : le PROGRAMME du sentier actif (jours + repartition + sens).
  final trailId = ref.watch(trailIdProvider);
  final plannedDays = ref.watch(plannedDaysProvider(trailId));

  // Projection PlannedDay -> ItineraryDay (memes totaux : distance / D+ / duree).
  return [for (final day in plannedDays) _toItineraryDay(day)];
});

/// Projette un jour de PROGRAMME ([PlannedDay]) en jour d'ITINERAIRE
/// ([ItineraryDay]) — meme contenu, deux vues. Les totaux sont ceux deja portes
/// par [PlannedDay] (source unique [stageDurationMinutes] pour la duree). Un jour
/// de repos devient un [ItineraryDay] sans etape (l'ecran affiche « repos »).
ItineraryDay _toItineraryDay(PlannedDay day) => ItineraryDay(
      dayNumber: day.dayNumber,
      stages: List.unmodifiable(day.stages),
      totalDistance: day.totalDistanceKm,
      totalElevation: day.totalElevationGainM,
      estimatedHours: day.estimatedHours,
    );
