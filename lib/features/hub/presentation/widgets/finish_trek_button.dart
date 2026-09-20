import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/engine/trail_engine.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/category_icon_colors.dart';
import '../../../../i18n/translations.g.dart';
import '../../../treks/domain/trek_lifecycle_state.dart';
import '../../../treks/providers/my_treks_provider.dart';
import '../../../trek/providers/tracking_providers.dart';

/// Bouton « Terminer le trek » (Finitions V1, point 3 — décision Chris).
///
/// RÉTABLIT un moyen ATTEIGNABLE de terminer manuellement un trek en cours,
/// SANS dépendre uniquement de la détection GPS d'arrivée. Symétrique du
/// « Démarrer » : bouton ORANGE (parité GR20 `orangeTerre`), placé EN FIN DE
/// SCROLL du cockpit (sous toutes les cartes), pleine largeur hauteur 52.
///
/// VISIBILITÉ : ne s'affiche QUE lorsqu'un trek est réellement EN COURS
/// (session `active`|`paused`, état vivant du tracking OU état dérivé
/// `inProgress` du sentier actif). Sinon `SizedBox.shrink` (rien) — jamais de
/// bouton « Terminer » quand il n'y a rien à terminer.
///
/// COMPORTEMENT au clic : confirmation (« Terminer maintenant ? — les étapes
/// restantes ne seront pas marquées ») puis, si confirmé, appelle
/// [TrekSessionManagerNotifier.stop] (finalise la session en `completed`, même
/// teardown que l'arrivée GPS) et route vers le récap (`/trail/:id/recap`,
/// accessible même sans finisher légitime — parité GR20). AUCUNE logique de
/// session recréée : on réutilise la machine de session existante.
///
/// Zéro texte en dur (Slang `hub.finishTrek.*`).
///
/// Clés stables du parcours de fin de trek (FIX-2, finding M4) : le bouton du
/// cockpit et les deux actions de la confirmation sont désignables SANS passer
/// par leur libellé, que « Terminer le trek » / « Terminer le trek ? » /
/// « Terminer » rendent ambigu.
const String kFinishTrekButtonKey = 'finish-trek-button';
const String kFinishTrekDialogKey = 'finish-trek-dialog';
const String kFinishTrekConfirmKey = 'finish-trek-confirm';
const String kFinishTrekCancelKey = 'finish-trek-cancel';

class FinishTrekButton extends ConsumerStatefulWidget {
  const FinishTrekButton({super.key});

  @override
  ConsumerState<FinishTrekButton> createState() => _FinishTrekButtonState();
}

class _FinishTrekButtonState extends ConsumerState<FinishTrekButton> {
  bool _finishing = false;

  @override
  Widget build(BuildContext context) {
    // Trek en cours ? On suit d'abord l'état VIVANT du tracking (recording /
    // paused), puis, à défaut (session persistée pas encore reprise en mémoire
    // après un redémarrage), l'état DÉRIVÉ `inProgress` du sentier actif.
    final tracking = ref.watch(trekSessionManagerProvider);
    final liveActive = tracking.status == TrackingSessionStatus.recording ||
        tracking.status == TrackingSessionStatus.paused;
    final derivedInProgress = ref.watch(
          currentTrailSummaryProvider.select((a) => a.value?.state),
        ) ==
        TrekLifecycleState.inProgress;

    // Rien à terminer -> pas de bouton (jamais de « Terminer » hors rando).
    if (!liveActive && !derivedInProgress) return const SizedBox.shrink();

    // Orange de parité GR20 (orangeTerre) — même token que le reste des CTA.
    final orange = CategoryIconColors.of(context).orange;

    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingLg),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.icon(
          key: const ValueKey(kFinishTrekButtonKey),
          onPressed: _finishing ? null : () => _onFinishPressed(context),
          icon: const Icon(Icons.flag_outlined, size: 22),
          label: Text(t.hub.finishTrek.action),
          style: FilledButton.styleFrom(
            backgroundColor: orange,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }

  /// Confirmation puis fin manuelle du trek (jamais sans confirmer).
  ///
  /// FIX-2 (finding M4) — ACTIONS IDENTIFIABLES. Le bouton du cockpit
  /// (« Terminer le trek »), le titre du dialogue (« Terminer le trek ? ») et
  /// l'action de confirmation (« Terminer ») partagent le meme mot. Designer
  /// l'action par son libelle est donc ambigu : on peut viser le bouton RESTE
  /// SOUS la barriere modale au lieu de la confirmation, et le dialogue ne se
  /// referme jamais — plus rien n'est atteignable derriere. Chaque action porte
  /// donc une cle stable, seul point d'entree non ambigu (meme demarche que
  /// l'accessibilite du Journal en L10).
  Future<void> _onFinishPressed(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const ValueKey(kFinishTrekDialogKey),
        title: Text(t.hub.finishTrek.confirmTitle),
        content: Text(t.hub.finishTrek.confirmBody),
        actions: [
          TextButton(
            key: const ValueKey(kFinishTrekCancelKey),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.hub.finishTrek.cancel),
          ),
          FilledButton(
            key: const ValueKey(kFinishTrekConfirmKey),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.hub.finishTrek.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    await _finish(context);
  }

  /// Finalise la session en `completed` via la machine de session existante,
  /// puis ouvre le récap. Best-effort sur la navigation (le trek est terminé
  /// quoi qu'il arrive).
  Future<void> _finish(BuildContext context) async {
    final trailId = ref.read(trailConfigProvider).id;
    final notifier = ref.read(trekSessionManagerProvider.notifier);
    setState(() => _finishing = true);
    try {
      // stop() = finalisation `completed` (même teardown que l'arrivée GPS :
      // capture de fond arrêtée, session persistée). Ne touche PAS
      // `parcoursFullyWalked` (pas de faux finisher pour une fin manuelle).
      await notifier.stop();
      if (!context.mounted) return;
      // Récap accessible même sans finisher (parité GR20 : abandon/fin manuelle
      // ouvrent quand même « Mon aventure »). push -> retour propre au cockpit.
      context.push('/trail/$trailId/recap');
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }
}
