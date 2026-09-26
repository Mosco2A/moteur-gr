import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/hiker_profile_repository.dart';
import '../domain/hiker_profile.dart';
import '../domain/past_hike.dart';

/// Profil randonneur courant (fiche d'info) — StepWays LOT 4, Ph1.
///
/// `AsyncNotifier` : charge le profil depuis la source durable (prefs) au
/// premier acces, puis expose lecture/ecriture. La faisabilite (Ph5) et la
/// fiche info consomment ce provider.
final hikerProfileProvider =
    AsyncNotifierProvider<HikerProfileNotifier, HikerProfile>(
        HikerProfileNotifier.new);

/// Notifier du profil randonneur.
class HikerProfileNotifier extends AsyncNotifier<HikerProfile> {
  /// Repository pour les ECRITURES (hors `build`, ou `watch` est interdit).
  HikerProfileRepository get _repo => ref.read(hikerProfileRepositoryProvider);

  @override
  Future<HikerProfile> build() async {
    // `watch` ET PAS `read` — TACHE 564 (LOT M, M1). Avec `read`, ce notifier ne
    // declarait AUCUNE dependance au repository : invalider le repository (ce que
    // fait l'effacement art. 17 pour vider la memoire vive) ne le reconstruisait
    // pas, et l'ecran continuait de servir l'instantane d'avant l'effacement.
    // `watch` dans `build` rend la dependance reelle, donc la cascade
    // d'invalidation reelle — pour cet ecran et pour tous ceux qui viendront.
    return ref.watch(hikerProfileRepositoryProvider).load();
  }

  /// Enregistre la fiche profil (morpho SENSIBLE, IMC calcule local).
  Future<void> save(HikerProfile profile) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.saveProfile(profile));
  }

  /// Efface la fiche profil (droit a l'effacement RGPD).
  Future<void> clear() async {
    await _repo.deleteProfile();
    state = const AsyncValue.data(HikerProfile.empty);
  }

  /// EFFACE LA MORPHOLOGIE (age, taille, poids) — consentement article 9 refuse
  /// ou retire (tache 560, N1).
  ///
  /// Un refus n'est pas seulement « on n'ecrit plus » : c'est « ce qui a ete
  /// ecrit s'en va ». Voir [HikerProfileRepository.eraseMorphology] pour le
  /// perimetre exact et pourquoi il s'arrete a ces trois champs.
  Future<void> forgetMorphology() async {
    state = await AsyncValue.guard(_repo.eraseMorphology);
  }
}

/// Randos passees du randonneur (max 5) — StepWays LOT 4, Ph3.
final pastHikesProvider =
    AsyncNotifierProvider<PastHikesNotifier, List<PastHike>>(
        PastHikesNotifier.new);

/// Notifier des randos passees.
class PastHikesNotifier extends AsyncNotifier<List<PastHike>> {
  /// Repository pour les ECRITURES (hors `build`, ou `watch` est interdit).
  HikerProfileRepository get _repo => ref.read(hikerProfileRepositoryProvider);

  @override
  Future<List<PastHike>> build() async {
    // `watch` ET PAS `read` : voir [HikerProfileNotifier.build]. C'est
    // PRECISEMENT ce provider que la campagne personas a vu ressusciter une
    // randonnee effacee — « Vos 5 dernieres randos » resservait son cache.
    return ref.watch(hikerProfileRepositoryProvider).loadPastHikes();
  }

  /// Remplace la liste complete des randos (plafonnee a 5, la plus recente
  /// d'abord). L'ecran d'interview gere l'edition puis persiste l'ensemble.
  Future<void> saveAll(List<PastHike> hikes) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.savePastHikes(hikes));
  }
}

// LA NOTE D'EXPERIENCE (texte libre « difficultes ») N'A PLUS DE PROVIDER
// (tache 570, S2).
//
// `experienceNoteProvider` et son notifier vivaient ici. Leur commentaire
// d'origine portait l'aveu : « V1 : STOCKEE seulement (l'IA la lira en V2) ».
// La V2 n'est jamais venue, et la mesure est sans appel : le provider
// n'apparaissait que dans DEUX fichiers — celui-ci et l'ecran qui le remplissait
// — alors que la donnee, elle, descendait jusqu'au cloud et remontait a la
// restauration. Elle etait donc collectee, propagee, conservee, et lue par
// personne.
//
// Decision de Chris du 26/09 : « sinon tu le vire pour l'instant ». Le provider
// part avec l'ecran et avec son ecriture. Ce qui RESTE, volontairement, c'est
// l'EFFACEMENT de ce qui a deja ete ecrit sur les telephones existants (voir
// [HikerProfileRepository.eraseAllPersonalData]) : cesser de collecter ne
// dispense pas d'effacer, et un randonneur qui exerce son droit a l'oubli doit
// voir partir aussi la note qu'il avait saisie avant ce lot.
