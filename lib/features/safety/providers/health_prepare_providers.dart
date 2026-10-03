/// La fiche medicale devient un sujet de PREPARATION : on ne part pas sans
/// l'avoir remplie, elle n'est plus un ecran de terrain cache.
library;

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
/// cockpit ([HubStartTrekButton]). Y brancher une lecture de disque en ferait une
/// vue asynchrone.
///
/// CE QUI ENTRE ICI NE CONTIENT AUCUNE DONNEE MEDICALE — deux noms d'enum, pas un
/// groupe sanguin —, et cette precision compte : les preferences, elles, sont
/// emportees par la sauvegarde du telephone. C'est un signal de PREPARATION,
/// exactement de la meme nature que les etapes coeur (`prepare_core_steps_`) deja
/// derivees d'ecrans ouverts. L'ecran de la fiche RE-SYNCHRONISE
/// [HealthPrepStep.filled] a chaque ouverture depuis la fiche elle-meme : le
/// signal ne peut donc pas mentir durablement, et une fiche effacee referme la
/// porte (verrouille par test).
///
/// CETTE PHRASE A ETE CORRIGEE A LA TACHE 615. Elle disait « la DONNEE de sante
/// reste evidemment en Drift », ce qui est FAUX depuis la tache 613 : la fiche a
/// quitte la base pour son propre fichier, sous le dossier exclu de la sauvegarde
/// (`HealthInfoFile`). Le motif des commentaires qui survivent a la regle
/// qu'ils decrivent, mesure le 27/09, valait aussi pour celui-la.
enum HealthPrepStep {
  /// La fiche medicale porte au moins une information ([HealthInfo.hasData]).
  filled,

  /// Les conseils d'usage terrain ont ete LUS (accuse de lecture explicite).
  adviceRead,

  /// LA FICHE A ETE RECOPIEE DANS LA FICHE D'URGENCE DU TELEPHONE (tache 630).
  ///
  /// POURQUOI CE TROISIEME SIGNAL EXISTE, ET CE N'EST PAS UNE CASE DE PLUS. La
  /// mesure de la tache 630 (documentation Apple et Google, 29/09) a etabli que
  /// SUR IPHONE AUCUNE APPLICATION TIERCE NE PEUT AFFICHER QUOI QUE CE SOIT DE
  /// COMPLET SANS DEVERROUILLAGE : la fiche que les premiers intervenants
  /// atteignent est celle du SYSTEME, et Apple n'offre aucune API pour y ecrire.
  /// Sur Android, la notification persistante y arrive, mais le randonneur peut
  /// masquer les notifications sensibles de son ecran verrouille — la
  /// documentation le dit : « the user always has ultimate control ».
  ///
  /// LA RECOPIE DANS LA FICHE DU TELEPHONE EST DONC LE SEUL CHEMIN QUI MARCHE
  /// PARTOUT. Elle etait ecrite depuis la tache 568 comme une ligne de conseil
  /// parmi quatre (`health.advice.phoneCard`) — c'est-a-dire comme une
  /// information, pas comme un acte. Elle devient une ETAPE, avec un rappel
  /// visible tant qu'elle n'est pas faite, parce que c'est ELLE qui sauve.
  ///
  /// ELLE N'ENTRE PAS DANS LA PORTE DE DEMARRAGE DU TREK, et c'est delibere :
  /// nous ne pouvons pas VERIFIER qu'elle a ete faite (rien ne nous donne acces
  /// a la fiche du systeme). Bloquer un depart sur une declaration invérifiable
  /// apprendrait au randonneur a cocher sans faire. On rappelle, on n'interdit
  /// pas — cf. [healthPrepareDoneProvider].
  phoneCardCopied,
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

  /// Enregistre que la fiche a ete RECOPIEE dans celle du telephone (tache 630).
  ///
  /// REVOCABLE, contrairement a l'accuse de lecture. On ne « delit » pas un
  /// conseil, mais on peut tres bien avoir efface la fiche du telephone, ou en
  /// avoir change. Le randonneur doit pouvoir dire « finalement non » et
  /// retrouver son rappel.
  Future<void> setPhoneCardCopied(bool recopiee) => _apply(
    ajouts: recopiee ? const {HealthPrepStep.phoneCardCopied} : const {},
    retraits: recopiee ? const {} : const {HealthPrepStep.phoneCardCopied},
  );
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
