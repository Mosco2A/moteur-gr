import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/routing/contextual_actions_provider.dart';
import 'contextual_action_bar.dart';

/// Barre du bas CONTEXTUELLE déclarative (StepWays LOT 3, Ph2).
///
/// Réf : SPEC_LOT3_nav.md §3 + §8 Ph2. LIT le provider de scope
/// [contextualActionsProvider] (alimenté par l'écran courant via
/// [ContextualActionsMixin]) et rend les actions via le composant présentiel
/// [ContextualActionBar] (BottomAppBar, cibles ≥ 48 dp, action saillante SOS).
///
/// ABSENTE si aucune action n'est déclarée (`SizedBox.shrink`) — la barre est
/// contextuelle, pas systématique (B1/B2 « barre fixe » tombent, SPEC §2).
///
/// Usage : `Scaffold(bottomNavigationBar: const ContextualBottomBar(), ...)`.
/// Le CÂBLAGE des actions par écran (SPEC §4) est fait en Ph5 (L6) ; ici on ne
/// fournit que le rendu piloté par le provider.
class ContextualBottomBar extends ConsumerWidget {
  const ContextualBottomBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.watch(contextualActionsProvider);
    if (actions.isEmpty) return const SizedBox.shrink();
    return ContextualActionBar(actions: actions);
  }
}
