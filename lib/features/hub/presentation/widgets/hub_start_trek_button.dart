/// Le depart, grise tant que les informations minimum manquent — un bouton qui
/// dit pourquoi il n'est pas encore cliquable.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/monetization_service.dart';
import '../../../../core/services/session_demo.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/category_icon_colors.dart';
import '../../../../i18n/translations.g.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/background_tracking_rationale_dialog.dart';
import '../../../../shared/widgets/paywall_sheet.dart';
import '../../../treks/presentation/widgets/active_trek_conflict_dialog.dart';
import '../../../trek/providers/tracking_providers.dart';
import '../../providers/cockpit_start_providers.dart';
import '../../../../core/branding/stepways_icons.dart';

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
    //
    // EN DEMO, LA PORTE EST OUVERTE (tache 638, bug 16 — DEM-260930-1024),
    // verbatim de Christophe : « le bouton demarrer la rando doit etre accessible
    // en mode demo ! ».
    //
    // POURQUOI LA PORTE NE PEUT PAS SE FRANCHIR HONNETEMENT EN DEMO : une de ses
    // quatre conditions est la FICHE MEDICALE remplie (decision du 26/09), et
    // remplir la fiche medicale est une ECRITURE — barree en demo, et qui doit
    // l'etre (c'est une donnee de sante). La gate ne pouvait donc JAMAIS s'ouvrir
    // pendant une demonstration : le bouton restait grise a vie, ce qui est
    // exactement ce que Christophe a constate. On l'ouvre, et le message sous le
    // bouton DIT que c'est la demo qui l'ouvre — pas une gate qui aurait cede.
    final enDemo = ref.watch(enDemoProvider);
    final canStart =
        enDemo || ref.watch(prepareCoreDoneProvider(widget.trailId));
    final enabled = canStart && !_starting;

    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: AppButton(
              variant: AppButtonVariant.filledTone,
              tone: orange,
              icon: StepwaysIcons.enregistrer,
              iconSize: 22,
              label: t.hub.startCta,
              // Grise (onPressed null) tant que le minimum manque ou pendant le
              // demarrage. SEUL le gate 3 cartes conditionne l'enable (la
              // proximite GPS ne bloque jamais — filet au clic).
              onPressed: enabled ? () => _onStartPressed(context) : null,
            ),
          ),
          // EN DEMO, ON DIT CE QUE LE BOUTON VA FAIRE : il lance une SIMULATION,
          // pas une randonnee. Sans cette ligne, un bouton « Demarrer » actif
          // sur un sentier non achete ressemblerait a un droit accorde.
          if (enDemo) ...[
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              t.demo.departSimule,
              key: const ValueKey('demo-depart-simule'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
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
    // EN DEMO, PAS DE QUESTION DE PROXIMITE (tache 638, bug 16). Le GPS n'est
    // meme pas arme pendant une demonstration (`_startBackgroundCapture` sort en
    // demo) : la proximite est donc TOUJOURS inconnue, et le dialogue
    // « Démarrer quand même ? » surgirait a chaque fois pour une question qui n'a
    // pas de sens quand on ne marche pas.
    if (ref.read(enDemoProvider)) {
      await _start(context);
      return;
    }
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
  /// PERMISSIONS DE SUIVI — PRE-VOL EXPLIQUE (campagne personas 21/09,
  /// MAJEUR-1). L'escalade partait en fire-and-forget juste avant la carte, et
  /// un deuxieme chemin la relancait en parallele : l'ecran systeme « Toujours
  /// autoriser en arrière-plan ? » recouvrait la carte a la toute premiere
  /// rando, sans explication. Desormais on explique DANS l'application, on
  /// attend la reponse systeme ICI (avant la carte), et on demarre quoi qu'il
  /// arrive : le suivi premier plan n'a pas besoin de la permission de fond.
  Future<void> _start(BuildContext context) async {
    final notifier = ref.read(trekSessionManagerProvider.notifier);
    // LE DROIT D'ABORD, LA PERMISSION ENSUITE (tache 651, defaut C).
    //
    // CET ORDRE ETAIT INVERSE, et il faisait payer au randonneur une question
    // intime pour un service qu'on allait lui refuser : on lui demandait la
    // localisation « Toujours » — la permission la plus lourde du systeme, celle
    // qui suit ses pas quand l'application est fermee — puis on lui annoncait
    // que la randonnee demandait un achat. Deux gestes dans le mauvais ordre :
    // la permission obtenue ne servait a rien, et le refus arrivait apres coup.
    //
    // MEME SOURCE DE VERITE que la garde d'unicite ([canRealizeTrail]) : on ne
    // duplique aucune regle de droit, on la consulte simplement AVANT de
    // deranger le systeme. La garde reste en place derriere (defense en
    // profondeur), et la branche `purchaseRequired` ci-dessous aussi : un droit
    // peut disparaitre entre les deux lectures.
    //
    // EN DEMO, NI L'UN NI L'AUTRE : la demo ne demande aucune permission (une
    // permission de fond pour une randonnee qui n'aura pas lieu) et ne demande
    // aucun droit (elle simule, cf. `demarrerSimulationDemo`).
    if (!ref.read(enDemoProvider)) {
      final monetization = ref.read(monetizationServiceProvider);
      if (!await monetization.canRealizeTrail(widget.trailId)) {
        if (!context.mounted || !mounted) return;
        await _direPourquoiEtOuAcheter(context);
        return;
      }
      if (!context.mounted || !mounted) return;
      // La permission de fond, expliquee puis demandee une seule fois. Ne jette
      // jamais, ne bloque jamais le demarrage : le suivi premier plan n'en a
      // pas besoin.
      await ensureBackgroundTrackingExplained(context, ref);
    }
    if (!context.mounted || !mounted) return;
    setState(() => _starting = true);
    try {
      final outcome = await notifier.ensureSingleActiveThenStart(
        widget.trailId,
        resolve: (ongoingTrailId) =>
            showActiveTrekConflictDialog(context, ongoingTrailId),
      );
      if (!context.mounted) return;
      if (outcome == StartOutcome.started) {
        context.push('/map');
        return;
      }
      // LE REFUS D'ACHAT DIT POURQUOI, ET OU ACHETER (tache 594, A1).
      //
      // Realiser une randonnee est reserve au trek achete. Le refus ne peut
      // pas etre un bouton qui ne repond pas : on NOMME la raison, puis on
      // ouvre le chemin d'achat avec son prix. C'est la regle du LOT X — un
      // geste qui ne produit rien est un mensonge — appliquee au seul endroit
      // ou l'application doit dire non pour etre vendable.
      if (outcome == StartOutcome.purchaseRequired) {
        await _direPourquoiEtOuAcheter(context);
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  /// Explique le refus d'achat, puis ouvre le paywall du sentier.
  ///
  /// DEUX TEMPS, PAS UN. D'abord la raison — « realiser demande d'avoir
  /// debloque, la preparation reste gratuite » — parce qu'un paywall qui
  /// surgit sans phrase ressemble a une panne. Ensuite seulement le prix et le
  /// bouton d'achat, si l'utilisateur veut aller plus loin.
  Future<void> _direPourquoiEtOuAcheter(BuildContext context) async {
    final continuer = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const ValueKey('realisation-verrouillee'),
        icon: const StepIcon(StepwaysIcons.cadenas),
        title: Text(t.monetization.realizationLockedTitle),
        content: Text(t.monetization.realizationLockedBody),
        actions: [
          AppButton(
            variant: AppButtonVariant.text,
            label: t.navPilote.startCancel,
            isFullWidth: false,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          AppButton(
            label: t.monetization.buyCta,
            isFullWidth: false,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (continuer != true || !context.mounted) return;
    // LE TROISIEME POINT D'ENTREE DE L'ACHAT (tache 614) : le depart. Les deux
    // autres sont le catalogue et la preparation, et tous trois empruntent
    // CETTE fonction — un seul geste, un seul prix, une seule vitrine.
    await acheterSentier(context, ref, trailId: widget.trailId);
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
          AppButton(
            variant: AppButtonVariant.text,
            label: t.navPilote.startCancel,
            isFullWidth: false,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          AppButton(
            label: t.navPilote.startConfirm,
            isFullWidth: false,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
  }
}
