/// La carte qui reflete le CYCLE DE VIE du sentier actif, et plus seulement
/// l'etat du suivi en memoire : a preparer, en cours, en pause, fini.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/engine/trail_engine.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/category_icon_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../i18n/translations.g.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_data_stat.dart';
import '../../../map/map_facade.dart' show stageDistanceCoveredProvider;
import '../../../trek/trek_facade.dart'
    show TrackingSessionState, trekSessionManagerProvider;
import '../../../../core/branding/stepways_icons.dart';
import '../cockpit_phase.dart';

/// Carte principale du trek (RF-4 / #ET-1 / #ET-2), enrichie du cycle de vie
/// multi-trek (StepWays LOT 2, Phase 5).
///
/// Elle a TROIS VISAGES, et c'est [CockpitPhase] qui choisit lequel — la meme
/// source que « Préparer », « Démarrer » et « Acheter » depuis la tache 809 :
///   * [CockpitPhase.hike] : carte « en cours » avec stats temps reel du jour
///     + CTA « Reprendre la navigation » (#R08) ;
///   * [CockpitPhase.after] : carte de fin, porte unique « Mon aventure »
///     (`/trail/:id/recap`), qui ouvre elle-meme le diplome et le journal ;
///   * [CockpitPhase.prepare] : carte d'invite. Le CTA « Démarrer » a QUITTE
///     cette carte (retour Christophe #3) et vit en bas du cockpit.
///
/// ELLE CONNAIT DESORMAIS LA DEMONSTRATION, ET C'EST UN CHANGEMENT ASSUME. Son
/// en-tete disait « le mode demo reste masque — la carte ne connait que le trek
/// reel » (D1, arbitrage #94902) : vrai tant qu'elle lisait la base, que
/// la demo n'ecrit pas. En lisant la phase, elle voit l'arrivee d'une marche
/// simulee et pose sa carte de fin. D1 parlait de ne pas inventer un trek de
/// demonstration a cote du vrai ; ici le trek EST le vrai Mare a Mare, et c'est
/// sa marche qui est simulee. Rien n'est acquis pour autant : aucun droit n'est
/// accorde, et la porte qu'elle ouvre reste celle de l'apres-randonnee reelle.
class HubTrekCard extends ConsumerWidget {
  const HubTrekCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // CETTE CARTE NE DERIVE PLUS SON ETAT, ELLE LIT LA PHASE (tache 809).
    //
    // Elle melangeait elle-meme l'etat vivant du suivi et l'etat derive de la
    // base — le MEME melange que faisait l'ecran du cockpit, et qu'un troisieme
    // widget faisait encore ailleurs. Trois recalculs du meme fait, avec trois
    // chances de ne pas tomber d'accord. Le melange est desormais fait UNE
    // fois, dans [cockpitPhaseProvider].
    //
    // CE QUE CE SEUL CHANGEMENT REPARE, ET C'EST LE DEFAUT (b) DE CHRISTOPHE :
    // « demarrer la randonne, le bouton aparait encore une fois la randonnee
    // finie au lieu d acceder a la post rando ». En demonstration, la base ne
    // voyait jamais l'arrivee, donc cette carte retombait sur [_StartTrekCard]
    // (« prêt à partir ») et la porte « Mon aventure » de [_CompletedTrekCard]
    // ne s'ouvrait JAMAIS. La phase connaissant maintenant l'arrivee sans la
    // base, c'est bien la carte de fin qui se pose, avec sa porte.
    switch (ref.watch(cockpitPhaseProvider)) {
      case CockpitPhase.hike:
        // Rando active : stats du jour + reprise de la navigation. Couvre aussi
        // la session persistee pas (encore) reprise en memoire apres un
        // redemarrage — les stats valent alors 0 jusqu'a la reprise.
        return _ActiveTrekCard(tracking: ref.watch(trekSessionManagerProvider));
      case CockpitPhase.after:
        return const _CompletedTrekCard();
      case CockpitPhase.prepare:
        // Pendant le calcul, en erreur, ou sans aucun trek : la carte d'invite
        // a demarrer — jamais d'ecran casse.
        return const _StartTrekCard();
    }
  }
}

/// Etat « trek en cours » : stats du jour + progression + reprise navigation.
class _ActiveTrekCard extends ConsumerWidget {
  const _ActiveTrekCard({required this.tracking});

  final TrackingSessionState tracking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final totalKm = ref.watch(
      trailConfigProvider.select((c) => c.totalDistanceKm),
    );
    // Finitions V1 (point 7) : « distance parcourue » = distance PROJETÉE sur
    // le tracé ([stageDistanceCoveredProvider], mètres), la MÊME source unique
    // que la carte, l'overlay et le widget (correctif build 117 / E10 RF-10).
    // L'ancien affichage lisait `tracking.distanceKm` (cumul GPS brut de
    // [TrekStats]), qui reste bloqué à 0 : le pipeline
    // `TrekStats.addPoint`/`updateStats` N'EST PAS câblé (aucun appelant) ->
    // d'où le « 0.0 km » constaté en QA. La source projetée, elle, est
    // alimentée et ne gonfle pas sur un aller-retour.
    final coveredKm = ref.watch(stageDistanceCoveredProvider) / 1000.0;
    final progress = totalKm > 0 ? (coveredKm / totalKm).clamp(0.0, 1.0) : 0.0;
    final percent = (progress * 100).round();

    final hours = tracking.elapsedDuration.inHours;
    final minutes = tracking.elapsedDuration.inMinutes.remainder(60);
    final durationText = hours > 0
        ? '${hours}h${minutes.toString().padLeft(2, '0')}'
        : '${minutes}min';

    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icone "en cours" en vert categoriel (parite GR20 Navigation ->
              // vertMaquis) plutot que l'accent-sentier unique (#IR02).
              StepIcon(
                StepwaysIcons.pas,
                color: CategoryIconColors.of(context).green,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              // Flexible + ellipsis : le titre s'ajuste a la largeur (mobile
              // 360 px) au lieu de deborder la Row a droite (fix overflow).
              Expanded(
                child: Text(
                  t.hub.trekCard.activeTitle,
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingBase),
          // Stats du jour (distance / denivele / temps) : gros chiffres data
          // via AppDataStat (SW-SKIN-L5), role data tabular L1. Chaque tuile
          // est `Expanded` (repartition en largeur egale, ex-`_Stat`), alignee
          // a gauche. Valeur formatee avec unite incluse -> iso-texte pour les
          // tests existants (find.text('12.5 km') / '640 m').
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppDataStat(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  label: t.hub.trekCard.distanceCovered,
                  // Point 7 : source PROJETÉE (cohérente carte/overlay/widget),
                  // plus le cumul GPS brut non câblé qui affichait « 0.0 km ».
                  value: '${coveredKm.toStringAsFixed(1)} km',
                ),
              ),
              Expanded(
                child: AppDataStat(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  label: t.hub.trekCard.elevationGain,
                  value: '${tracking.elevationGainM.round()} m',
                ),
              ),
              Expanded(
                child: AppDataStat(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  label: t.hub.trekCard.duration,
                  value: durationText,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingBase),
          // Barre de progression sur la distance totale du sentier.
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            t.hub.trekCard.progressLabel(percent: percent),
            style: theme.textTheme.bodySmall?.copyWith(
              // R1 : contraste WCAG AA du sous-texte sur fond sombre (0.87).
              color: scheme.onSurface.withValues(alpha: 0.87),
            ),
          ),
          const SizedBox(height: AppTheme.spacingBase),
          // SW-SKIN-L3e : ElevatedButton.icon -> AppButton primary, pleine
          // largeur (SizedBox width infinity conserve). Libelle inchange.
          SizedBox(
            width: double.infinity,
            child: AppButton(
              icon: StepwaysIcons.maPosition,
              label: t.hub.trekCard.resume,
              // Ph4 (hub-and-push, SPEC §5) : push -> retour propre au cockpit.
              onPressed: () => context.push('/map'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Etat « owned / prepared » : carte d'INVITE (titre + message), SANS bouton.
///
/// Retour Chris #3 (LOT 2) : l'action « Démarrer la randonnée » a QUITTE cette
/// carte (elle etait en HAUT du cockpit et toujours active). Elle vit desormais
/// EN BAS du cockpit ([HubStartTrekButton], `hub_screen.dart`), GRISEE tant que
/// les infos minimum (Itineraire + Date + Programme) ne sont pas saisies. Cette
/// carte ne porte donc plus que l'ETAT (invite a preparer/demarrer) — la garde
/// d'unicite C4 et le demarrage reel sont portes par le bouton du bas.
/// La planification reste atteignable par la carte « Programme » de la section
/// Preparer (inchangee).
class _StartTrekCard extends StatelessWidget {
  const _StartTrekCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // TACHE 639 (bug 3) — LE DESSIN DE CETTE TUILE EST BICOLORE.
              //
              // Il portait la couleur categorielle verte, donc le trace
              // monochrome teinte : c'est exactement ce que Christophe a vu
              // (« pret a partir non plus »). Sur la tuile d'etat du cockpit,
              // le vert categoriel n'apporte rien que le bicolore ne dise mieux
              // — le trace duo porte deja le vert #1F3D2B de l'identite. On
              // retire donc la couleur imposee, et la regle de
              // [iconeBicolorePour] fait sortir « carte » en bicolore.
              const StepIcon.tuile(StepwaysIcons.map),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  t.hub.trekCard.noTrekTitle,
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            t.hub.trekCard.noTrekBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              // R1 : contraste WCAG AA du corps de la carte d'invite sur fond
              // sombre — 2e encart de l'accueil (0.8 -> 0.87).
              color: scheme.onSurface.withValues(alpha: 0.87),
            ),
          ),
          // Retour Chris #3 : plus de CTA « Démarrer » ici — il est en bas du
          // cockpit ([HubStartTrekButton]), grise tant que le minimum manque.
        ],
      ),
    );
  }
}

/// Etat « completed » (finisher legitime) : felicitations + acces Revoir /
/// Diplôme (StepWays LOT 2, Phase 5). Les deux routes existent deja (regle S8
/// « zero route morte ») ; la garde fine (recap/diplome) reste portee par les
/// ecrans cibles.
class _CompletedTrekCard extends ConsumerWidget {
  const _CompletedTrekCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final trailId = ref.watch(trailConfigProvider.select((c) => c.id));

    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // TACHE 639 (bug 3) : tuile d'etat de fin de trek = un sujet. Le
              // diplome est l'une des 20 rubriques, il a un trace bicolore.
              const StepIcon.tuile(StepwaysIcons.diploma),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  t.hub.trekCard.completedTitle,
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingBase),
          // CORRECTIF L5-8 — UNE SEULE PORTE D'ENTREE APRES LE TREK.
          //
          // Sur un trek termine, le cockpit affichait QUATRE commandes pour
          // DEUX destinations : « Mon aventure » et « Diplome » ici, et les
          // MEMES deux, memes libelles, dans la section « Apres le trek » du
          // menu, sur le meme ecran en meme temps. Cette duplication est une
          // invention de StepWays, le cockpit de reference n'en a aucune.
          //
          // Il reste CETTE commande, et une seule. Le diplome n'est pas perdu :
          // « Mon aventure » l'ouvre (bouton en tete du recapitulatif, sous sa
          // garde de finisher), avec le journal, le partage et l'export GPX.
          SizedBox(
            width: double.infinity,
            child: AppButton(
              key: const ValueKey('completed-review'),
              icon: StepwaysIcons.sommet,
              label: t.hub.cards.recap,
              onPressed: () => context.push('/trail/$trailId/recap'),
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            t.hub.trekCard.progressLabel(percent: 100),
            style: theme.textTheme.bodySmall?.copyWith(
              // R1 : contraste WCAG AA du sous-texte sur fond sombre (0.87).
              color: scheme.onSurface.withValues(alpha: 0.87),
            ),
          ),
        ],
      ),
    );
  }
}
