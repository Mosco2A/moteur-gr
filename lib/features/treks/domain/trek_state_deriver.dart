import '../../trek/domain/models/trek_session.dart';
import 'trek_lifecycle_state.dart';

/// Statuts de session (String extensible cote [TrekSession]) — constantes
/// partagees pour la derivation d'etat, alignees sur le reste du socle
/// (`adventure_recap_provider.dart`).
const String kSessionStatusActive = 'active';
const String kSessionStatusPaused = 'paused';
const String kSessionStatusCompleted = 'completed';
const String kSessionStatusAbandoned = 'abandoned';

/// Derive l'[TrekLifecycleState] d'un trek POSSEDE (StepWays LOT 2, §1).
///
/// Fonction PURE et testable : elle ne lit NI base NI provider, uniquement les
/// faits deja connus de l'appelant. Rien n'est persiste en plus — l'etat est un
/// pur calcul sur :
///  * [latestSession] : la DERNIERE session persistee du trek (ou null) ;
///  * [hasPlanningOrProgress] : existe-t-il une progression et/ou une
///    planification pour ce trek (une ligne `UserProgress`, un itineraire
///    planifie...) ? Sert a distinguer [TrekLifecycleState.owned] (rien fait)
///    de [TrekLifecycleState.prepared] (prepare mais pas en cours).
///
/// Priorite (spec §1) : **inProgress > completed > prepared > owned**.
///  1. session active|paused        -> inProgress ;
///  2. sinon derniere session completed -> completed ;
///  3. sinon (planif/progression, OU session abandonnee) -> prepared ;
///  4. sinon -> owned.
///
/// L'ABANDON n'est pas un etat : une derniere session `abandoned` NE compte pas
/// comme `completed`, le trek retombe [TrekLifecycleState.prepared] (rejouable).
/// Un statut de session inconnu (extensible) est traite comme non-terminal
/// (fail-safe : ni inProgress ni completed) -> prepared/owned selon la planif.
TrekLifecycleState deriveState({
  required TrekSession? latestSession,
  required bool hasPlanningOrProgress,
}) {
  final status = latestSession?.status;

  // 1. En cours : une session active OU en pause prime sur tout le reste.
  if (status == kSessionStatusActive || status == kSessionStatusPaused) {
    return TrekLifecycleState.inProgress;
  }

  // 2. Termine : derniere session `completed` (finisher). L'abandon ne compte
  //    PAS ici (il retombe prepared plus bas).
  if (status == kSessionStatusCompleted) {
    return TrekLifecycleState.completed;
  }

  // 3. Prepare : soit une planif/progression existe, soit la derniere session a
  //    ete abandonnee (trek re-preparable). Un statut inconnu retombe ici aussi
  //    des qu'il y a de la matiere (fail-safe non-terminal).
  if (hasPlanningOrProgress || latestSession != null) {
    return TrekLifecycleState.prepared;
  }

  // 4. Rien fait : possede mais vierge.
  return TrekLifecycleState.owned;
}
