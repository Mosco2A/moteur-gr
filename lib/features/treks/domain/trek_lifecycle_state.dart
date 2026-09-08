/// Etat de cycle de vie d'un trek POSSEDE, cote accueil multi-trek (StepWays
/// LOT 2, §1 — état-trek).
///
/// 100 % DERIVE : rien n'est persiste en plus. L'etat est recalcule a la volee
/// depuis les faits deja en base (droit d'acces + progression/planif + derniere
/// session) par [deriveState] (`trek_state_deriver.dart`). Un trek n'apparait
/// dans « Mes treks » que s'il est POSSEDE (owned = entitlement ∪ vitrine) ; cet
/// enum qualifie ensuite OU il en est.
///
/// Priorite de derivation : inProgress > completed > prepared > owned (cf.
/// [deriveState]). L'abandon (`status == abandoned`) N'est PAS un etat ici : un
/// trek abandonne retombe [prepared] (rejouable) — la memoire des etapes
/// acquises reste tracee ailleurs (`TrekEntitlements`), le trek se re-prepare.
enum TrekLifecycleState {
  /// Possede (droit d'acces), mais RIEN n'a encore ete fait : aucune
  /// progression, aucune planif, aucune session. Point de depart.
  owned,

  /// Prepare : il existe une progression et/ou une planification, mais AUCUNE
  /// session active|paused. Inclut le cas d'un trek dont la derniere session a
  /// ete ABANDONNEE (rejouable) : il retombe ici, pas dans [completed].
  prepared,

  /// En cours : une session est active OU en pause (C4, unicite cross-trail).
  /// C'est l'etat le plus prioritaire.
  inProgress,

  /// Termine : la derniere session est `completed` (finisher legitime). Un trek
  /// termine reste rejouable (une nouvelle session le fera repasser inProgress).
  completed,
}
