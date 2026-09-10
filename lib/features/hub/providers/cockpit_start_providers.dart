import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../notifications/providers/download_reminder_provider.dart';
import '../../trek/providers/gps_providers.dart';

/// Providers du DÉMARRAGE RÉEL du trek depuis le cockpit (StepWays LOT 3, Q1).
///
/// Réf : SPEC_LOT3_nav.md §12.1 (déblocage des phases) + §12.5 (spéc technique
/// du démarrage réel). Deux mécanismes indépendants :
///
///  1. **Gate d'ACTIVATION du bouton « Démarrer »** ([prepareCoreDoneProvider])
///     = les 3 cartes cœur de Préparer sont faites (Itinéraire + Date +
///     Programme). C'est le SEUL critère d'ENABLE du bouton (§12.5).
///  2. **Proximité GPS** ([startProximityProvider]) = le randonneur est-il au
///     point de départ de l'étape 1 ? Ne conditionne PAS l'enable (filet
///     anti-cul-de-sac) : elle conditionne le CHEMIN au clic (démarrage direct
///     vs dialog de secours « Démarrer quand même ? »).

/// Tolérance de proximité au point de départ de l'étape 1 (Q1, §12.5).
///
/// Valeur figée par défaut = **300 m** (décision Chris 10/09). Constante nommée
/// et réajustable : au-delà de cette distance (ou GPS indisponible), le clic sur
/// « Démarrer » passe par un dialog de confirmation (jamais de blocage).
const double kStartProximityToleranceMeters = 300;

/// Étapes cœur de la préparation dont la complétion débloque le démarrage (Q1).
///
/// Les 3 seules cartes bloquantes de Préparer (§12.1) : les autres (Faisabilité,
/// Nuitées, Transport, Résumé, Matériel) ne bloquent pas. La « Date » n'est PAS
/// listée ici : elle se dérive du signal DÉJÀ persisté [downloadReminderProvider]
/// (`departureDate != null`), on ne duplique donc pas sa persistance.
enum PrepCoreStep {
  /// Carte « Itinéraire » (`/trail/:id/itinerary`) — parcours/sens vus.
  itinerary,

  /// Carte « Programme » (`/trail/:id/planning`) — durée/programme définis.
  programme,
}

/// Signal MINIMAL de complétion des cartes cœur de Préparer, PERSISTÉ par
/// sentier (Q1, §12.5).
///
/// Il n'existe AUCUN signal de complétion par carte dans le code (SPEC §12.5 :
/// `prepared` s'obtient dès qu'une ligne `UserProgress` existe). LOT 1 introduit
/// donc ce signal minimal SANS nouvelle table : on réutilise EXACTEMENT le
/// mécanisme SharedPreferences par sentier déjà employé par
/// [DownloadReminderNotifier] (date de départ). Chaque écran cœur (Itinéraire,
/// Programme) marque son étape « vue » à l'ouverture ([markSeen]) ; l'ensemble
/// est relu au boot depuis les prefs. La « Date » n'y figure pas (dérivée du
/// signal existant `departureDate`).
///
/// Set vide par défaut (premier lancement) → bouton « Démarrer » désactivé tant
/// que les 3 conditions ne sont pas réunies.
class PrepareCoreStepsNotifier extends Notifier<Set<PrepCoreStep>> {
  PrepareCoreStepsNotifier(this._trailId);

  final String _trailId;

  static const _prefix = 'prepare_core_steps_';

  @override
  Set<PrepCoreStep> build() {
    _loadFromPrefs();
    return const <PrepCoreStep>{};
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    final stored = prefs.getStringList('$_prefix$_trailId') ?? const [];
    state = stored
        .map(
          (name) => PrepCoreStep.values
              .where((s) => s.name == name)
              .cast<PrepCoreStep?>()
              .firstWhere((s) => s != null, orElse: () => null),
        )
        .whereType<PrepCoreStep>()
        .toSet();
  }

  /// Marque une étape cœur comme faite (persistant). Idempotent.
  Future<void> markSeen(PrepCoreStep step) async {
    if (state.contains(step)) return;
    final next = {...state, step};
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      '$_prefix$_trailId',
      next.map((s) => s.name).toList(),
    );
  }
}

/// Étapes cœur faites pour un sentier donné (persisté). Famille par `trailId`.
final prepareCoreStepsProvider = NotifierProvider.family<
    PrepareCoreStepsNotifier, Set<PrepCoreStep>, String>(
  PrepareCoreStepsNotifier.new,
);

/// « Préparer terminé » (Q1, §12.1) : Itinéraire ET Date ET Programme.
///
/// - **Itinéraire** + **Programme** : dérivés de [prepareCoreStepsProvider]
///   (les 2 écrans cœur ont été ouverts/validés).
/// - **Date** : dérivée du signal DÉJÀ persisté [downloadReminderProvider]
///   (`departureDate != null` = l'utilisateur a choisi une date de départ dans
///   le calendrier). Aucune persistance neuve pour la date.
///
/// C'est le SEUL critère d'ENABLE du bouton « Démarrer » (§12.5). La proximité
/// GPS ne conditionne PAS l'enable.
final prepareCoreDoneProvider = Provider.family<bool, String>((ref, trailId) {
  final steps = ref.watch(prepareCoreStepsProvider(trailId));
  final hasDate = ref.watch(
    downloadReminderProvider(trailId).select((s) => s.departureDate != null),
  );
  return steps.contains(PrepCoreStep.itinerary) &&
      steps.contains(PrepCoreStep.programme) &&
      hasDate;
});

/// État de proximité au point de départ de l'étape 1 (Q1, §12.5).
///
/// Fonction PURE dérivée de la position live + coords du départ + tolérance :
/// testable en unité. `gpsAvailable == false` couvre stream en erreur /
/// permission refusée / pas encore de fix (le stream n'a pas émis).
class StartProximity {
  const StartProximity({
    required this.atDeparture,
    required this.distanceMeters,
    required this.gpsAvailable,
  });

  /// À portée du départ de l'étape 1 (distance <= tolérance).
  final bool atDeparture;

  /// Distance au départ en mètres (null si position OU coords indisponibles).
  final double? distanceMeters;

  /// GPS exploitable (stream a émis une position sans erreur).
  final bool gpsAvailable;
}

/// Proximité au point de départ de l'étape 1 (direction-aware), Q1 §12.5.
///
/// Coords du départ résolues DYNAMIQUEMENT (jamais en dur, #84627/#99460) :
/// `currentTrekPlanProvider.startStageId` (vraie 1re étape dans le sens de
/// marche) → `Stage` correspondant dans `domainStagesProvider` →
/// `startLat`/`startLng`. Distance via `Geolocator.distanceBetween`.
final startProximityProvider = Provider<StartProximity>((ref) {
  final positionAsync = ref.watch(positionStreamProvider);
  final position = positionAsync.value;
  final gpsAvailable = positionAsync.hasValue && !positionAsync.hasError;

  final plan = ref.watch(currentTrekPlanProvider);
  final startStageId = plan?.startStageId;
  final stages = ref.watch(domainStagesProvider);

  double? startLat;
  double? startLng;
  if (startStageId != null) {
    for (final s in stages) {
      if (s.id == startStageId) {
        startLat = s.startLat;
        startLng = s.startLng;
        break;
      }
    }
  }

  if (position == null || startLat == null || startLng == null) {
    return StartProximity(
      atDeparture: false,
      distanceMeters: null,
      gpsAvailable: gpsAvailable,
    );
  }

  final distance = Geolocator.distanceBetween(
    position.latitude,
    position.longitude,
    startLat,
    startLng,
  );
  return StartProximity(
    atDeparture: distance <= kStartProximityToleranceMeters,
    distanceMeters: distance,
    gpsAvailable: gpsAvailable,
  );
});
