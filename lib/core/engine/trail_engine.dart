/// Le point d'entree UNIQUE vers la configuration du sentier actif : theme,
/// navigation et GPS la lisent ici, jamais ailleurs.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/trail_config.dart';
import '../config/trail_selection.dart';

/// Moteur central du Moteur GR.
///
/// Point d'entrée unique pour accéder à la configuration du sentier
/// actif. Tous les modules (thème, navigation, GPS, etc.) lisent
/// la config depuis ce provider.
///
/// Multi-sentiers (F8D-01, #84627) : par défaut, la config active est RÉSOLUE
/// depuis la sélection de l'utilisateur ([selectedTrailIdProvider]) sur le
/// catalogue ([resolvedTrailConfigProvider]). Changer de sentier (F8D-02) =
/// écrire le nouvel id dans [selectedTrailIdProvider] ; toute l'app suit.
///
/// Override possible (mono-sentier dédié, tests) — l'override prime toujours :
/// ```dart
/// void main() {
///   const config = TrailConfig(...);
///   runApp(
///     ProviderScope(
///       overrides: [
///         trailConfigProvider.overrideWithValue(config),
///       ],
///       child: const MyApp(),
///     ),
///   );
/// }
/// ```
final trailConfigProvider = Provider<TrailConfig>((ref) {
  // Par défaut : sentier sélectionné, résolu sur le catalogue (genericité).
  return ref.watch(resolvedTrailConfigProvider);
});

/// CHOISIR UN SENTIER — le seul geste autorise pour basculer, et il resout la
/// bascule AVANT de rendre la main.
///
/// LE DEFAUT QU'IL CORRIGE (tache 601), ET IL SORTAIT QUATRE FOIS PAR BASCULE.
/// Les ecrans ecrivaient [selectedTrailIdProvider] puis naviguaient dans le MEME
/// geste synchrone. L'ecriture ne fait que MARQUER SALE toute la chaine de
/// configuration ; la navigation declenche aussitot le build de l'ecran suivant,
/// et c'est ce build qui DECOUVRE la chaine sale — `HubScreen.build` ouvre un
/// `select` sur [trailConfigProvider]. Les providers asynchrones qui en
/// derivent (le resume du trek courant, la decision publicitaire) s'invalident
/// alors EN PLEINE PHASE DE BUILD, et Riverpod demande au `ProviderScope` de se
/// reconstruire : « setState() or markNeedsBuild() called during build », quatre
/// fois de suite.
///
/// LA CORRECTION TIENT EN UNE LECTURE. On resout la configuration ICI, dans le
/// gestionnaire de geste, donc HORS de toute phase de build : la chaine est
/// propre quand la navigation commence, et il ne reste rien a decouvrir au
/// mauvais moment. Ce n'est pas un contournement — c'est l'ordre naturel : on
/// change de sentier, PUIS on change d'ecran.
///
/// POURQUOI PERSONNE NE L'AVAIT VU. Le defaut exige une VRAIE bascule, donc deux
/// sentiers reellement jouables. Le catalogue n'en avait qu'un : le drapeau
/// vitrine debridait le sentier par defaut, et lui seul. Le sentier de
/// demonstration en ajoute un second, et le persona MALADROIT est tombe dessus
/// au premier appui sur « Entrer ».
///
/// [ref] est un [WidgetRef] : ce geste part TOUJOURS d'une interaction, jamais
/// du corps d'un provider — ecrire un etat depuis un provider est justement
/// l'anti-motif qui produirait le meme defaut ailleurs.
void chooseTrail(WidgetRef ref, String trailId) {
  ref.read(selectedTrailIdProvider.notifier).state = trailId;
  // Resolution IMMEDIATE, hors build : c'est tout l'objet de cette fonction.
  ref.read(trailConfigProvider);
}

/// Nom d'affichage du sentier actif.
final trailNameProvider = Provider<String>((ref) {
  return ref.watch(trailConfigProvider).displayName;
});

/// Identifiant du sentier actif.
final trailIdProvider = Provider<String>((ref) {
  return ref.watch(trailConfigProvider).id;
});
