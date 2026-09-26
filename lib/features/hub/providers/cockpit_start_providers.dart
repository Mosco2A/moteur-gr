import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../notifications/providers/download_reminder_provider.dart';
import '../../safety/providers/health_prepare_providers.dart';
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

  /// Décode la liste persistée (noms d'enum) en étapes, en ignorant l'inconnu.
  Set<PrepCoreStep> _decode(List<String> names) => names
      .map(
        (name) => PrepCoreStep.values
            .where((s) => s.name == name)
            .cast<PrepCoreStep?>()
            .firstWhere((s) => s != null, orElse: () => null),
      )
      .whereType<PrepCoreStep>()
      .toSet();

  /// Lit les étapes persistées et les FUSIONNE dans l'état courant.
  ///
  /// FUSION, jamais écrasement (FIX-3) : `build()` lance cette relecture SANS
  /// l'attendre, et chaque écran cœur appelle [markSeen] dès son ouverture. Si
  /// l'écran marque son étape pendant que la relecture est en vol, un
  /// `state = stored` écraserait le marquage avec l'état d'AVANT — l'étape
  /// serait perdue et la gate de démarrage resterait fermée alors que la
  /// préparation est complète. Il n'existe aucune opération de « démarquage » :
  /// l'union est donc toujours la valeur correcte.
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    final stored = _decode(prefs.getStringList('$_prefix$_trailId') ?? const []);
    state = {...state, ...stored};
  }

  /// Marque une étape cœur comme faite (persistant). Idempotent.
  ///
  /// ÉCRITURE SANS MISE À JOUR PERDUE (FIX-3) : la clé porte la liste ENTIÈRE
  /// des étapes. La liste à écrire est donc recalculée APRÈS l'attente, à
  /// partir de ce qui est réellement persisté À CET INSTANT, uni à l'état
  /// courant et à l'étape marquée. Sans cette relecture, un marquage concurrent
  /// de la relecture initiale réécrivait la clé à partir d'un état périmé et
  /// DÉTRUISAIT en préférences une étape déjà acquise (mesuré : « programme »
  /// disparaissait du disque) — la gate ne se rouvrait alors plus, même après
  /// redémarrage de l'application.
  Future<void> markSeen(PrepCoreStep step) async {
    if (state.contains(step)) return;
    // Réactivité immédiate : l'UI ne doit pas attendre l'écriture disque.
    state = {...state, step};
    final prefs = await SharedPreferences.getInstance();
    final merged = {
      ..._decode(prefs.getStringList('$_prefix$_trailId') ?? const []),
      ...state,
      step,
    };
    await prefs.setStringList(
      '$_prefix$_trailId',
      merged.map((s) => s.name).toList(),
    );
    if (!ref.mounted) return;
    state = merged;
  }
}

/// Étapes cœur faites pour un sentier donné (persisté). Famille par `trailId`.
final prepareCoreStepsProvider = NotifierProvider.family<
    PrepareCoreStepsNotifier, Set<PrepCoreStep>, String>(
  PrepareCoreStepsNotifier.new,
);

/// « Préparer terminé » (Q1, §12.1) : Itinéraire ET Date ET Programme, PLUS la
/// FICHE MÉDICALE depuis la décision de Chris du 26/09 (tâche 568, LOT Q).
///
/// - **Itinéraire** + **Programme** : dérivés de [prepareCoreStepsProvider]
///   (les 2 écrans cœur ont été ouverts/validés).
/// - **Date** : dérivée du signal DÉJÀ persisté [downloadReminderProvider]
///   (`departureDate != null` = l'utilisateur a choisi une date de départ dans
///   le calendrier). Aucune persistance neuve pour la date.
/// - **Fiche médicale** : dérivée de [healthPrepareDoneProvider] — fiche
///   REMPLIE *et* conseils d'usage LUS. Décision de Chris, verbatim : « on ne
///   demarre pas un trek sans avoir rempli sa fiche medicale et lu les conseils
///   pour qu'elle soit applicable sur le sentier ». Les deux moitiés comptent :
///   une fiche parfaite que personne ne sait ni trouver ni montrer ne sert à
///   rien le jour de l'accident.
///
/// C'est le SEUL critère d'ENABLE du bouton « Démarrer » (§12.5). La proximité
/// GPS ne conditionne PAS l'enable.
///
/// LE MESSAGE D'AIDE SUIT (`t.hub.startGateHint`) : il annonçait « Itinéraire,
/// Date et Programme » et a été réécrit dans les 5 langues pour nommer la
/// quatrième condition. Un test verrouille qu'il contient le libellé exact de la
/// carte qui y mène — un texte qui annonce autre chose que ce que le code exige
/// est précisément le défaut que Chris trouve depuis deux jours.
final prepareCoreDoneProvider = Provider.family<bool, String>((ref, trailId) {
  final steps = ref.watch(prepareCoreStepsProvider(trailId));
  final hasDate = ref.watch(
    downloadReminderProvider(trailId).select((s) => s.departureDate != null),
  );
  // Signal de PERSONNE (pas de sentier) : la fiche médicale suit le randonneur
  // d'un trek à l'autre, elle n'est pas à refaire par sentier.
  final healthReady = ref.watch(healthPrepareDoneProvider);
  return steps.contains(PrepCoreStep.itinerary) &&
      steps.contains(PrepCoreStep.programme) &&
      hasDate &&
      healthReady;
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
