import '../../../core/config/trail_config.dart';
import '../../../core/data/database.dart' show UserProgressEntry;
import '../../trek/domain/models/trek_session.dart';
import 'trek_lifecycle_state.dart';

/// Vue synthetique d'un trek POSSEDE pour l'accueil « Mes treks » (StepWays
/// LOT 2, §1/§2).
///
/// AGREGAT DERIVE (rien de persiste en plus) : reunit la config du sentier, son
/// [TrekLifecycleState] calcule ([deriveState]) et les faits deja en base
/// (derniere session, progression) pour que l'UI (`TrekSummaryCard`, écran
/// « Mes treks ») affiche l'etat, la progression et trie les treks — SANS
/// recalculer quoi que ce soit ailleurs. Construit par `myTreksProvider`
/// (Phase 2).
///
/// Immutable et sans logique metier (hors petits derives d'affichage) : la
/// regle d'etat vit dans `trek_state_deriver.dart`, la source des donnees dans
/// les DAOs.
class TrekSummary {
  const TrekSummary({
    required this.config,
    required this.state,
    this.latestSession,
    this.progress,
  });

  /// Config du sentier (nom, nombre d'etapes, distance...) — la DONNEE du trek.
  final TrailConfig config;

  /// Etat de cycle de vie derive (owned / prepared / inProgress / completed).
  final TrekLifecycleState state;

  /// Derniere session persistee du trek (ou null si aucune) : source de
  /// `lastActivityAt`, de la fraction de progression et du libelle d'etat.
  final TrekSession? latestSession;

  /// Progression persistee du trek (ou null) : etape courante, distance
  /// marchee... Base de la [progressFraction] quand aucune session ne l'affine.
  final UserProgressEntry? progress;

  /// Identifiant du trek (raccourci sur la config).
  String get trailId => config.id;

  /// Date de derniere activite sur ce trek, pour le tri « recents d'abord ».
  ///
  /// Prend le plus recent signal disponible : fin de session > debut de session
  /// > fin de progression > debut de progression. Null si aucun signal (trek
  /// juste possede, jamais touche).
  DateTime? get lastActivityAt {
    final candidates = <DateTime>[
      if (latestSession?.finishedAt != null) latestSession!.finishedAt!,
      if (latestSession != null) latestSession!.startedAt,
      if (progress?.completedAt != null) progress!.completedAt!,
      if (progress?.startedAt != null) progress!.startedAt!,
    ];
    if (candidates.isEmpty) return null;
    return candidates.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  /// Fraction de progression du trek dans [0.0, 1.0] (pour une barre/anneau).
  ///
  /// Derivee sans nouveau calcul metier :
  ///  * trek [TrekLifecycleState.completed] -> 1.0 ;
  ///  * sinon, etapes REELLEMENT marchees de la derniere session
  ///    ([TrekSession.completedStages]) rapportees au nombre total d'etapes du
  ///    sentier ([TrailConfig.totalStages]), si disponibles ;
  ///  * a defaut, etape courante de la progression ([UserProgressEntry]) — 1
  ///    based — rapportee au total ;
  ///  * 0.0 sinon.
  ///
  /// Toujours borne a [0.0, 1.0] (jamais > 1 sur des donnees incoherentes).
  double get progressFraction {
    if (state == TrekLifecycleState.completed) return 1.0;

    final total = config.totalStages;
    if (total <= 0) return 0.0;

    final walked = latestSession?.completedStages.length ?? 0;
    if (walked > 0) {
      return (walked / total).clamp(0.0, 1.0);
    }

    final currentStage = progress?.currentStage;
    if (currentStage != null && currentStage > 0) {
      // `currentStage` est 1-based : etape 1 = pas encore d'etape terminee.
      final done = currentStage - 1;
      return (done / total).clamp(0.0, 1.0);
    }

    return 0.0;
  }

  TrekSummary copyWith({
    TrailConfig? config,
    TrekLifecycleState? state,
    TrekSession? latestSession,
    UserProgressEntry? progress,
  }) {
    return TrekSummary(
      config: config ?? this.config,
      state: state ?? this.state,
      latestSession: latestSession ?? this.latestSession,
      progress: progress ?? this.progress,
    );
  }
}
