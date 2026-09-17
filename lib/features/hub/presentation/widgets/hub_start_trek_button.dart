import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/category_icon_colors.dart';
import '../../../../i18n/translations.g.dart';
import '../../../../shared/services/location_permission_service.dart';
import '../../../treks/presentation/widgets/active_trek_conflict_dialog.dart';
import '../../../trek/providers/tracking_providers.dart';
import '../../providers/cockpit_start_providers.dart';

/// Bouton « Démarrer la randonnée » du cockpit HUB (retour Chris #3, LOT 2).
///
/// PLACEMENT : EN BAS du cockpit (`hub_screen.dart`, apres les cartes de
/// preparation), et non plus en haut (il etait porte, toujours actif, par la
/// [HubTrekCard]).
///
/// GATE D'ACTIVATION (« infos minimum ») : le bouton est GRISE (disabled) tant
/// que [prepareCoreDoneProvider] est faux — c'est-a-dire tant que les 3 cartes
/// coeur de la preparation ne sont pas faites : **Itineraire + Date +
/// Programme** (cf. `cockpit_start_providers.dart`, ancre sur des signaux DEJA
/// persistes, aucune persistance neuve). Un message d'aide sous le bouton
/// explique ce qu'il reste a completer.
///
/// AU CLIC (gate ouverte) : lit [startProximityProvider] (filet anti-cul-de-sac,
/// jamais bloquant). Au point de depart -> demarrage direct ; sinon (hors zone
/// OU GPS indisponible) -> dialog « Démarrer quand même ? ». Le demarrage passe
/// TOUJOURS par la garde d'unicite C4
/// ([TrekSessionManagerNotifier.ensureSingleActiveThenStart], meme chemin que
/// l'ancien bouton de la [HubTrekCard]), puis `push('/map')` au succes.
///
/// STYLE : bouton ORANGE pleine largeur (parite GR20 `orangeTerre` via
/// [CategoryIconColors.orange]), hauteur 52 — meme facture que « Terminer le
/// trek » du cockpit. Zero texte en dur (Slang). Le look grise est le rendu
/// natif d'un [FilledButton] a `onPressed: null`.
class HubStartTrekButton extends ConsumerStatefulWidget {
  const HubStartTrekButton({required this.trailId, super.key});

  final String trailId;

  @override
  ConsumerState<HubStartTrekButton> createState() => _HubStartTrekButtonState();
}

class _HubStartTrekButtonState extends ConsumerState<HubStartTrekButton> {
  bool _starting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orange = CategoryIconColors.of(context).orange;

    // Gate « infos minimum » : Itineraire + Date + Programme (retour Chris #3).
    final canStart = ref.watch(prepareCoreDoneProvider(widget.trailId));
    final enabled = canStart && !_starting;

    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              // Grise (onPressed null) tant que le minimum manque ou pendant le
              // demarrage. SEUL le gate 3 cartes conditionne l'enable (la
              // proximite GPS ne bloque jamais — filet au clic).
              onPressed: enabled ? () => _onStartPressed(context) : null,
              icon: const Icon(Icons.play_arrow, size: 22),
              label: Text(t.hub.startCta),
              style: FilledButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          // Message d'aide tant que la gate est fermee (retour Chris #3 :
          // « grise tant que les infos minimum n'ont pas ete rentrees »).
          if (!canStart) ...[
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              t.hub.startGateHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Clic sur « Démarrer » (gate ouverte). Choisit le CHEMIN selon la proximite
  /// GPS : direct si au depart, sinon dialog de secours (jamais de cul-de-sac).
  Future<void> _onStartPressed(BuildContext context) async {
    final proximity = ref.read(startProximityProvider);
    if (proximity.atDeparture) {
      await _start(context);
      return;
    }
    final confirmed = await _confirmStartAway(context, proximity);
    if (confirmed == true) {
      if (!context.mounted) return;
      await _start(context);
    }
  }

  /// Demarrage effectif via la garde d'unicite C4 (parite `hub_trek_card.dart`
  /// d'origine), puis navigation vers la carte au succes.
  ///
  /// PERMISSIONS DE SUIVI — escalade NON BLOQUANTE (parite GR20, fix deadlock) :
  /// l'escalade « localisation Toujours + notifications + exemption batterie »
  /// est lancee en FIRE-AND-FORGET (`unawaited`), AVANT de demarrer mais SANS
  /// l'attendre — le suivi PREMIER PLAN (`whileInUse`, pre-accorde) suffit a
  /// demarrer, donc l'escalade de fond ne conditionne pas le demarrage
  /// (« jamais de cul-de-sac »).
  Future<void> _start(BuildContext context) async {
    final notifier = ref.read(trekSessionManagerProvider.notifier);
    setState(() => _starting = true);
    try {
      unawaited(
        ref.read(locationPermissionServiceProvider).ensureBackgroundTracking(),
      );
      final outcome = await notifier.ensureSingleActiveThenStart(
        widget.trailId,
        resolve: (ongoingTrailId) =>
            showActiveTrekConflictDialog(context, ongoingTrailId),
      );
      if (!context.mounted) return;
      if (outcome == StartOutcome.started) {
        context.push('/map');
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  /// Dialog de secours « Démarrer quand même ? » (filet Q1). Message adapte :
  /// hors zone (avec distance) OU position indisponible.
  Future<bool?> _confirmStartAway(BuildContext context, StartProximity p) {
    final body = p.gpsAvailable && p.distanceMeters != null
        ? t.navPilote.startAwayBody(distance: p.distanceMeters!.round())
        : t.navPilote.startNoGpsBody;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.navPilote.startAwayTitle),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.navPilote.startCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.navPilote.startConfirm),
          ),
        ],
      ),
    );
  }
}
