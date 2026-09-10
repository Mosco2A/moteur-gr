import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/contextual_action_bar.dart';

/// Mécanisme DÉCLARATIF de la barre contextuelle (StepWays LOT 3, Ph2).
///
/// Réf : SPEC_LOT3_nav.md §3 (ContextualBottomBar, archi déclarative via provider
/// de scope) + §8 Ph2. Chaque écran DÉCLARE ses actions au montage et les VIDE au
/// démontage ; la barre ([ContextualBottomBar]) LIT ce provider et s'affiche
/// uniquement si la liste est non vide. RECO retenue vs InheritedWidget : plus
/// découplé, testable, pas de re-wrap du Scaffold global.
///
/// NB : le CÂBLAGE écran par écran (quelles actions par écran, SPEC §4) se fait
/// en Ph5 (L6). Ici on ne crée QUE le mécanisme (provider + helper + widget).

/// Provider de SCOPE : la liste des actions de l'écran courant.
///
/// Vide par défaut (aucune barre). Un écran écrit ses actions au montage
/// (`setContextualActions`) et remet la liste vide au démontage
/// (`clearContextualActions`). Un seul écran « actif » à la fois pilote la barre
/// (hub-and-push : un écran plein écran à l'avant-plan).
final contextualActionsProvider =
    NotifierProvider<ContextualActionsNotifier, List<ContextualAction>>(
  ContextualActionsNotifier.new,
);

/// Notifier de la liste d'actions courantes (set au montage / clear au démontage).
class ContextualActionsNotifier extends Notifier<List<ContextualAction>> {
  @override
  List<ContextualAction> build() => const [];

  /// Déclare les actions de l'écran courant (remplace la liste).
  void set(List<ContextualAction> actions) => state = actions;

  /// Vide les actions (au démontage de l'écran).
  void clear() => state = const [];
}

/// Mixin pour un écran ([ConsumerState]) qui DÉCLARE des actions de barre
/// contextuelle. Pattern set-on-mount / clear-on-dispose, sans boilerplate :
///
/// ```dart
/// class _MyScreenState extends ConsumerState<MyScreen>
///     with ContextualActionsMixin {
///   @override
///   List<ContextualAction> buildContextualActions(BuildContext context) => [
///         ContextualAction(icon: ..., label: ..., onPressed: ...),
///       ];
/// }
/// ```
///
/// Les actions sont posées APRÈS le 1er frame (hors phase de build) et vidées au
/// `dispose`. Un écran sans action ne déclare rien (barre absente).
mixin ContextualActionsMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// Actions de barre contextuelle de cet écran (vide = pas de barre).
  List<ContextualAction> buildContextualActions(BuildContext context);

  /// Référence du notifier capturée au montage : `ref` n'est PAS utilisable dans
  /// `dispose()` (Riverpod : « save the provider state in a field »). On garde
  /// donc le notifier pour pouvoir vider la barre au démontage.
  ContextualActionsNotifier? _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = ref.read(contextualActionsProvider.notifier);
    // Hors phase de build : on écrit le provider après le montage.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _notifier?.set(buildContextualActions(context));
    });
  }

  @override
  void dispose() {
    // Vide la barre au démontage (l'écran suivant re-déclarera les siennes).
    // Via la référence capturée (ref interdit dans dispose) ET APRÈS la phase de
    // finalisation du tree (modifier un provider pendant dispose est interdit) :
    // on planifie le clear en microtask. L'écran suivant, qui déclare ses propres
    // actions en post-frame, écrasera de toute façon cette liste.
    final notifier = _notifier;
    Future.microtask(() {
      // Le container peut avoir été détruit entre-temps (fin d'app/de test) :
      // on ignore alors proprement (rien à vider).
      try {
        notifier?.clear();
      } catch (_) {
        // Container disposé : plus de barre à piloter, no-op.
      }
    });
    super.dispose();
  }
}
