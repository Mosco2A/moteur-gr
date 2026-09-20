/// VERROU D'EDITION DU PROGRAMME PENDANT LA RANDO (R12, LOT L9).
///
/// Regle metier imposee par Christophe : une fois le trek DEMARRE, le
/// randonneur peut encore MODIFIER la repartition de ses jours et de ses
/// etapes, mais **uniquement sur la partie NON FAITE** du programme :
///
///   * ce qui est deja realise est **fige** — un jour qui contient au moins une
///     etape reellement marchee (arrivee detectee, cf.
///     `TrekSession.completedStages`) n'est plus editable, ni lui ni les jours
///     qui le precedent (un jour de repos deja passe est passe) ;
///   * **aucune inversion** de l'ordre des etapes n'est possible des lors que le
///     trek est demarre : on ne peut pas marcher l'etape 6 avant l'etape 5 apres
///     coup. Le glisser-deposer (reorganisation) est donc neutralise en rando,
///     y compris depuis l'ecran Programme de la preparation (toujours joignable
///     via l'accordeon « Preparer » du cockpit).
///
/// Ce modele est PUR (aucune dependance Riverpod / Flutter) : il transporte
/// l'etat de rando observe (trek demarre ? quelles etapes sont faites ?) que le
/// programme editable consomme pour refuser les mutations interdites. Les
/// identifiants d'etape sont ceux du moteur (`'${stageNumber}'`, cf.
/// `domainStagesProvider` / `currentStageIdProvider`).
class TrekEditLock {
  const TrekEditLock({
    this.trekStarted = false,
    this.doneStageIds = const <String>{},
  });

  /// Le trek est-il DEMARRE (session de rando active ou en pause) ?
  ///
  /// Des que c'est vrai, l'ordre des etapes est GELE (plus de reorganisation) —
  /// meme si aucune etape n'est encore terminee : on ne reorganise pas un
  /// parcours qu'on a commence a marcher.
  final bool trekStarted;

  /// Identifiants des etapes REELLEMENT marchees (`TrekSession.completedStages`).
  ///
  /// Union de la session vivante (tracking en memoire) et de la session
  /// persistee (survit a un redemarrage de l'app en pleine rando).
  final Set<String> doneStageIds;

  /// Aucun verrou : etat de PREPARATION (trek pas demarre). Le programme est
  /// alors entierement editable, exactement comme avant R12.
  static const TrekEditLock none = TrekEditLock();

  /// L'etape [stageNumber] est-elle deja FAITE ?
  bool isStageDone(int stageNumber) => doneStageIds.contains('$stageNumber');

  /// Y a-t-il au moins une contrainte a appliquer ?
  bool get isActive => trekStarted || doneStageIds.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrekEditLock &&
          other.trekStarted == trekStarted &&
          other.doneStageIds.length == doneStageIds.length &&
          other.doneStageIds.containsAll(doneStageIds);

  @override
  int get hashCode => Object.hash(trekStarted, doneStageIds.length);
}
