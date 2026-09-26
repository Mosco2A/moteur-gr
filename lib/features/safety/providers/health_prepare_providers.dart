import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Signaux de PREPARATION de la fiche medicale (tache 568, LOT Q).
///
/// DECISION DE CHRIS DU 26/09 10:29, verbatim : « ca doit faire partie de la
/// prepa, on ne demarre pas un trek sans avoir rempli sa fiche medicale et lu
/// les conseils pour qu'elle soit applicable sur le sentier ».
///
/// La fiche medicale cesse donc d'etre un ecran de terrain cache derriere
/// l'ecran d'urgence : elle devient une ETAPE DE LA PREPARATION, et sa
/// completion s'ajoute a la porte de demarrage du trek
/// ([prepareCoreDoneProvider]).
///
/// POURQUOI DEUX SIGNAUX, ET PAS UN. La phrase de Chris en porte deux : la fiche
/// REMPLIE, et ses conseils LUS. « Lu les conseils pour qu'elle soit applicable
/// sur le sentier » n'est pas un ornement : une fiche parfaite que personne ne
/// sait ou trouver ni comment montrer ne sert a rien le jour de l'accident. Un
/// texte simplement DISPONIBLE ne prouve pas qu'il a ete lu -> accuse de
/// lecture.
///
/// POURQUOI CES SIGNAUX VIVENT EN PREFERENCES ET PAS EN BASE. La porte de
/// demarrage est une vue SYNCHRONE, relue a chaque frame par le bouton du
/// cockpit ([HubStartTrekButton]). Y brancher la base Drift en ferait une vue
/// asynchrone et l'attacherait a l'ouverture de la base. La DONNEE de sante
/// reste evidemment en Drift, LOCAL ONLY (art. 9 RGPD) ; ce qui entre ici est un
/// signal de PREPARATION, exactement de la meme nature que les etapes coeur
/// (`prepare_core_steps_`) deja derivees d'ecrans ouverts. L'ecran de la fiche
/// RE-SYNCHRONISE [HealthPrepStep.filled] a chaque ouverture depuis la base :
/// le signal ne peut donc pas mentir durablement, et une fiche effacee referme
/// la porte (verrouille par test).
enum HealthPrepStep {
  /// La fiche medicale porte au moins une information ([HealthInfo.hasData]).
  filled,

  /// Les conseils d'usage terrain ont ete LUS (accuse de lecture explicite).
  adviceRead,
}

/// Cle SharedPreferences des signaux de preparation de la fiche medicale.
///
/// UNE SEULE cle, non prefixee par un sentier : la fiche medicale est une donnee
/// de PERSONNE, pas de trek (cf. l'absence de `trailId` sur la route `/health`
/// et son entree dans `excludedPaths` du guard).
const String kHealthPrepareStepsKey = 'health_prepare_steps';

/// Etat persiste des signaux de preparation de la fiche medicale.
class HealthPrepareStepsNotifier extends Notifier<Set<HealthPrepStep>> {
  /// Vrai des qu'une ecriture LOCALE a eu lieu : la relecture initiale des
  /// preferences ne doit alors plus ecraser l'etat (elle est arrivee trop tard).
  bool _ecritureLocale = false;

  @override
  Set<HealthPrepStep> build() {
    _loadFromPrefs();
    return const <HealthPrepStep>{};
  }

  /// Decode la liste persistee (noms d'enum) en signaux, en ignorant l'inconnu.
  Set<HealthPrepStep> _decode(List<String> names) => names
      .map(
        (name) => HealthPrepStep.values
            .where((s) => s.name == name)
            .cast<HealthPrepStep?>()
            .firstWhere((s) => s != null, orElse: () => null),
      )
      .whereType<HealthPrepStep>()
      .toSet();

  /// Relecture au premier acces (non attendue par `build`).
  ///
  /// Contrairement aux etapes coeur, ces signaux peuvent etre RETIRES (une fiche
  /// s'efface). Une fusion aveugle ferait donc revivre un signal qu'une ecriture
  /// concurrente vient de retirer : si une ecriture locale a eu lieu pendant que
  /// la relecture etait en vol, c'est l'ecriture qui fait autorite — elle a deja
  /// ecrit la liste complete sur le disque.
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted || _ecritureLocale) return;
    state = _decode(prefs.getStringList(kHealthPrepareStepsKey) ?? const []);
  }

  /// Applique un ajout et/ou un retrait, puis persiste la liste ENTIERE.
  ///
  /// La liste ecrite est recalculee APRES l'attente, a partir de ce qui est
  /// REELLEMENT persiste a cet instant (meme discipline que
  /// `PrepareCoreStepsNotifier.markSeen`, lecon FIX-3) : sans cette relecture,
  /// un marquage concurrent de la relecture initiale reecrirait la cle depuis un
  /// etat perime et DETRUIRAIT un signal deja acquis.
  Future<void> _apply({
    Set<HealthPrepStep> ajouts = const <HealthPrepStep>{},
    Set<HealthPrepStep> retraits = const <HealthPrepStep>{},
  }) async {
    _ecritureLocale = true;
    // Reactivite immediate : l'UI n'attend pas l'ecriture disque.
    state = <HealthPrepStep>{...state, ...ajouts}..removeAll(retraits);
    final prefs = await SharedPreferences.getInstance();
    final fusion = <HealthPrepStep>{
      ..._decode(prefs.getStringList(kHealthPrepareStepsKey) ?? const []),
      ...state,
      ...ajouts,
    }..removeAll(retraits);
    await prefs.setStringList(
      kHealthPrepareStepsKey,
      fusion.map((s) => s.name).toList(),
    );
    if (!ref.mounted) return;
    state = fusion;
  }

  /// Aligne le signal « fiche remplie » sur la realite de la base.
  ///
  /// Appele par l'ecran de la fiche a chaque ouverture, a chaque enregistrement
  /// et apres un effacement : le signal SUIT la donnee, il ne lui survit pas.
  Future<void> setFilled(bool remplie) => _apply(
        ajouts: remplie ? const {HealthPrepStep.filled} : const {},
        retraits: remplie ? const {} : const {HealthPrepStep.filled},
      );

  /// Enregistre l'ACCUSE DE LECTURE des conseils d'usage terrain. Idempotent.
  Future<void> markAdviceRead() =>
      _apply(ajouts: const {HealthPrepStep.adviceRead});
}

/// Signaux de preparation de la fiche medicale (persistes).
final healthPrepareStepsProvider =
    NotifierProvider<HealthPrepareStepsNotifier, Set<HealthPrepStep>>(
  HealthPrepareStepsNotifier.new,
);

/// « Fiche medicale prete » : REMPLIE **et** conseils LUS (decision Chris).
///
/// Entre dans la porte de demarrage du trek ([prepareCoreDoneProvider]) : on ne
/// part pas sans elle.
final healthPrepareDoneProvider = Provider<bool>((ref) {
  final steps = ref.watch(healthPrepareStepsProvider);
  return steps.contains(HealthPrepStep.filled) &&
      steps.contains(HealthPrepStep.adviceRead);
});
