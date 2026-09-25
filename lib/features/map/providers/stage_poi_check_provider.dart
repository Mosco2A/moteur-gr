import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Points de l'étape déjà COCHÉS par le marcheur (LOT D, tâche 554).
///
/// À QUOI ÇA SERT : sur la carte, la liste des points d'eau et des hébergements
/// de l'étape EN COURS se coche au passage — « source prise », « refuge
/// dépassé ». C'est le pense-bête du marcheur, pas un réglage d'affichage : le
/// panneau Calques, lui, montre et masque des couches, ce qui est une autre
/// fonction (retour de Chris : la navigation ne ressemblait en rien à la
/// référence, qui liste les points de l'étape).
///
/// PORTÉE VOLONTAIREMENT MÉMOIRE VIVE, ET IL FAUT LE DIRE : les coches vivent
/// le temps de la session d'application. Les persister demanderait une colonne
/// de base (migration Drift) ; ce lot est un lot d'ÉCRANS, il n'ouvre pas la
/// couche de données. Conséquence assumée : l'application relancée repart avec
/// des cases vides. Aucun chiffre du trek n'en dépend — ni la progression, ni
/// le journal, ni le diplôme — donc rien ne peut devenir faux à cause de ça.
///
/// La clé est l'IDENTIFIANT DE BASE du POI ([PoiModel.id]) : il est unique pour
/// tout le sentier, donc deux étapes ne peuvent pas se marcher sur les pieds.
class StagePoiChecksNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => const <int>{};

  /// Coche ou décoche le point [poiId].
  void toggle(int poiId) {
    final next = Set<int>.of(state);
    if (!next.remove(poiId)) next.add(poiId);
    state = next;
  }

  /// Vrai si le point [poiId] est coché.
  bool isChecked(int poiId) => state.contains(poiId);

  /// Remet toutes les coches à zéro (changement de sentier, fin de trek).
  void clear() => state = const <int>{};
}

final stagePoiChecksProvider =
    NotifierProvider<StagePoiChecksNotifier, Set<int>>(
  StagePoiChecksNotifier.new,
);
