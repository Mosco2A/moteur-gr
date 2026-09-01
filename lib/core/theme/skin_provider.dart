import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/data/settings_service.dart';
import '../config/trail_config.dart';
import '../engine/trail_engine.dart';
import 'app_skin.dart';

/// Selection + persistance + resolution de la peau visuelle (SW-SKIN-L7).
///
/// Trois briques :
///  - [skinProvider]           : la peau CHOISIE par l'utilisateur (persistee,
///    globale au sentier, defaut [AppSkin.sentierVivant]) ;
///  - [trailHasCoverPhotosProvider] : eligibilite Grand Air du sentier actif
///    (drapeau `hasCoverPhotos`, isole ici — cf. §Eligibilite) ;
///  - [effectiveSkinProvider]  : la peau REELLEMENT appliquee, apres fallback
///    Grand Air -> Sentier Vivant quand le sentier n'est pas eligible.
///
/// Le theme (`buildLightTheme`/`buildDarkTheme`, cf. `main.dart`) consomme
/// [effectiveSkinProvider] : changer de peau reconstruit le theme et prend
/// effet immediatement (CCO §2.5).

/// Parse le nom d'enum persiste vers [AppSkin], avec defaut sur valeur inconnue.
///
/// Robustesse : une preference corrompue / issue d'une version future
/// (nom d'enum inconnu) retombe silencieusement sur [AppSkin.sentierVivant]
/// plutot que de crasher (defaut sur, jamais de rendu casse).
AppSkin _skinFromName(String? name) {
  if (name == null) return AppSkin.sentierVivant;
  for (final skin in AppSkin.values) {
    if (skin.name == name) return skin;
  }
  return AppSkin.sentierVivant;
}

/// Peau CHOISIE par l'utilisateur (SW-SKIN-L7).
///
/// - Defaut : [AppSkin.sentierVivant] (CCO §2.5 : Sentier Vivant pour tout
///   sentier, tout utilisateur, au premier lancement).
/// - Persistance : via le MEME store que les autres preferences
///   ([SettingsService] / SharedPreferences) — aucune techno nouvelle.
/// - Portee : GLOBALE (le choix d'habitacle ne depend pas du sentier, CCO §2.5).
///
/// NB : c'est la peau *selectionnee*, pas forcement celle *rendue* : si le
/// sentier actif n'est pas eligible a Grand Air, [effectiveSkinProvider]
/// applique le fallback SANS perdre ce choix (il se re-applique des qu'un
/// sentier eligible est actif).
class SkinNotifier extends Notifier<AppSkin> {
  SettingsService? _service;

  @override
  AppSkin build() {
    // Chargement asynchrone de la preference persistee ; l'etat initial est le
    // defaut (Sentier Vivant) puis est ecrase par la valeur relue si differente
    // (meme pattern que SettingsNotifier).
    _load();
    return AppSkin.sentierVivant;
  }

  /// Relit la peau persistee via [SettingsService].
  ///
  /// `ref.mounted` apres le gap async : si le provider a ete dispose pendant
  /// l'attente (ex. container detruit tot en test, ou rebuild), on n'ecrit pas
  /// `state` (sinon Riverpod 3 leve « Ref used after dispose »).
  Future<void> _load() async {
    final service = await SettingsService.create();
    if (!ref.mounted) return;
    _service = service;
    state = _skinFromName(service.getSkin());
  }

  /// Selectionne une peau et la persiste (choix global, survit au redemarrage).
  void select(AppSkin skin) {
    state = skin;
    _service?.setSkin(skin.name);
  }
}

/// Provider de la peau choisie (persistee). Cf. [SkinNotifier].
final skinProvider =
    NotifierProvider<SkinNotifier, AppSkin>(SkinNotifier.new);

/// Eligibilite Grand Air du sentier actif — drapeau `hasCoverPhotos`.
///
/// POINT D'ISOLATION L9 (mandat SW-SKIN-L7 §Eligibilite) : le champ
/// `hasCoverPhotos` n'existe PAS ENCORE dans [TrailConfig] (il arrive en L9
/// avec les champs image). Pour L7 on l'expose derriere CETTE fonction avec un
/// DEFAUT SUR : `false` (comme si aucun sentier n'avait de photos) -> Grand Air
/// non eligible partout -> `effectiveSkin` retombe sur Sentier Vivant + tuile
/// grisee. En L9, il suffira de brancher ici la lecture du vrai drapeau
/// (`config.hasCoverPhotos` / derivation depuis `coverImageUrl`) SANS toucher
/// au reste du selecteur ni a la logique de fallback.
bool trailHasCoverPhotos(TrailConfig config) {
  // L7 : defaut sur. Aucun sentier eligible tant que L9 n'a pas ajoute les
  // champs image au modele.
  return false;
}

/// Le sentier actif a-t-il des photos de couverture (Grand Air eligible) ?
///
/// Derive de [trailConfigProvider] via [trailHasCoverPhotos]. En L7 : toujours
/// `false` (defaut sur) ; en L9 : reflete la config reelle du sentier.
final trailHasCoverPhotosProvider = Provider<bool>((ref) {
  final config = ref.watch(trailConfigProvider);
  return trailHasCoverPhotos(config);
});

/// Peau REELLEMENT appliquee = choix utilisateur apres regle de fallback.
///
/// Regle (CCO §2.6 / mandat §Eligibilite) :
///   effectiveSkin = (selected == grandAir && !hasCoverPhotos)
///                     ? sentierVivant
///                     : selected
///
/// Consomme par la construction du theme (`main.dart`). Silencieux et non
/// bloquant : le choix Grand Air n'est PAS perdu (il vit dans [skinProvider]),
/// il se re-applique des qu'un sentier eligible est actif.
final effectiveSkinProvider = Provider<AppSkin>((ref) {
  final selected = ref.watch(skinProvider);
  if (selected == AppSkin.grandAir &&
      !ref.watch(trailHasCoverPhotosProvider)) {
    return AppSkin.sentierVivant;
  }
  return selected;
});
