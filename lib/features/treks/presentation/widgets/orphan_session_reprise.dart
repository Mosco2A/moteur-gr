import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/trail_selection.dart';
import '../../../trek/domain/models/trek_session.dart';
import '../../../trek/providers/session_recovery_provider.dart';
import '../../../trek/providers/tracking_providers.dart';
import '../../providers/my_treks_provider.dart';
import 'resume_orphan_session_dialog.dart';

/// Garde de REPRISE de session orpheline au boot (StepWays LOT 2, C4 §3).
///
/// La detection + le nettoyage sont deja cables au boot
/// ([pendingSessionProvider], awaite par `appBootstrapProvider`) ; il manquait
/// l'UI PROACTIVE. Ce widget, insere juste sous l'arbre route une fois l'amorce
/// resolue (dans le `builder` de `MaterialApp.router`, donc SOUS un Navigator),
/// lit la session orpheline eventuelle et, s'il y en a une, presente UNE SEULE
/// FOIS le dialog Reprendre / Abandonner ([showResumeOrphanSessionDialog]) au
/// premier rendu :
///   * Reprendre  -> selectionne le sentier de la session
///     ([selectedTrailIdProvider]) et rejoint le cockpit (`/home`) ; la session
///     reste `active`|`paused` (le cockpit affiche la carte « en cours ») ;
///   * Abandonner -> solde la session en base (`abandoned`, via
///     [TrekSessionManagerNotifier.abandonPendingSession], jamais de faux
///     finisher) puis invalide les vues derivees (Mes treks / cockpit / trek
///     actif / detection orpheline) pour refleter l'abandon.
///
/// L'orpheline ne se represente pas : un drapeau d'etat garantit un seul
/// affichage par session (id memorise), et le dialog n'est pas dismissible
/// (l'utilisateur doit trancher — sinon l'orpheline reviendrait au prochain
/// lancement). Zero identifiant technique montre a l'utilisateur.
///
/// Transparent quand il n'y a rien a reprendre : rend simplement [child].
class OrphanSessionReprise extends ConsumerStatefulWidget {
  const OrphanSessionReprise({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<OrphanSessionReprise> createState() =>
      _OrphanSessionRepriseState();
}

class _OrphanSessionRepriseState extends ConsumerState<OrphanSessionReprise> {
  /// Id de la session deja traitee (dialog montre) : garantit un seul affichage
  /// par session orpheline, meme si le widget se reconstruit.
  String? _handledSessionId;

  /// Un dialog est-il en cours d'affichage ? (evite tout double `showDialog` si
  /// plusieurs frames s'enchainent avant le premier `await`).
  bool _dialogOpen = false;

  @override
  Widget build(BuildContext context) {
    // `pendingSessionProvider` est deja resolu (awaite au boot) : on lit sa
    // valeur sans re-declencher de calcul. On ne montre le dialog que pour une
    // session orpheline non encore traitee.
    final pending = ref.watch(pendingSessionProvider).asData?.value;
    if (pending != null &&
        pending.session.id != _handledSessionId &&
        !_dialogOpen) {
      _dialogOpen = true;
      _handledSessionId = pending.session.id;
      // Post-frame : `showDialog` a besoin d'un Navigator monte (l'arbre route
      // est en cours de premier rendu). On declenche apres la frame courante.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _promptReprise(pending.session);
      });
    }

    return widget.child;
  }

  /// Presente le dialog et applique le choix (Reprendre / Abandonner).
  Future<void> _promptReprise(TrekSession session) async {
    if (!mounted) return;

    final choice = await showResumeOrphanSessionDialog(context);
    if (!mounted) return;

    switch (choice) {
      case ResumeOrphanChoice.resume:
        // Rejoindre le cockpit du trek en cours : ecrire la selection puis
        // naviguer (la session reste en cours, la carte s'affichera « active »).
        ref.read(selectedTrailIdProvider.notifier).state = session.trailId;
        context.go('/home');
      case ResumeOrphanChoice.abandon:
        // Solder la session en base, puis invalider les vues derivees pour
        // qu'elles refletent l'abandon (le trek retombe `prepared`).
        await ref
            .read(trekSessionManagerProvider.notifier)
            .abandonPendingSession(session);
        ref.invalidate(pendingSessionProvider);
        ref.invalidate(myTreksProvider);
        ref.invalidate(currentTrailSummaryProvider);
        ref.invalidate(activeTrekIdProvider);
      case null:
        // Dialog non dismissible : ce cas ne survient pas. Par securite on ne
        // fait rien (l'orpheline sera reproposee au prochain lancement).
        break;
    }

    if (mounted) _dialogOpen = false;
  }
}
