import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/trail_config.dart';
import '../../../core/engine/trail_engine.dart';
import '../../../core/services/monetization_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/paywall_sheet.dart';
import '../models/localized_text.dart';
import '../models/training_plan.dart';
import '../providers/training_plan_providers.dart';

/// ECRAN ENTRAINEMENT — coeur du LOT 5 (sous-ensemble A), PAYANT.
///
/// Transforme le verdict de faisabilite en PROGRAMME SUIVI : un plan progressif
/// (Fondation / Denivele / Endurance), cale sur la DATE DE DEPART (« X jours
/// avant »), adapte au PROFIL (fiche L4 + verdict L4), avec un OBJECTIF chiffre
/// (repere du sentier charge) et des seances COCHABLES (barre de progression).
///
/// PAYANT (decisions #83707/#99305) : verrouille derriere l'achat d'un pack/abo
/// — lie au PACK, PAS a l'etape (consomme 0 etape). Le reste de la prepa
/// (faisabilite, programme, calendrier, checklist) reste GRATUIT. Le verrou
/// reutilise la SOURCE UNIQUE d'acces ([isDemoModeProvider]) : un trek possede /
/// couvert par abo / vitrine est debloque ; sinon teaser + « Debloquer ».
///
/// HORS-LIGNE : l'acces derive des droits Drift LOCAUX (cache entitlement) —
/// [isDemoModeProvider] ne fait AUCUN appel reseau pour juger l'acces. Un payeur
/// n'est donc JAMAIS bloque faute de reseau (spec, contrainte non negociable).
/// Seul l'ACHAT (paywall) requiert le reseau, a l'initiative de l'utilisateur.
///
/// AGNOSTIQUE AU SENTIER : le plan + l'objectif viennent de la DONNEE du sentier
/// charge ([trainingPlanProvider], externalise JSON) — jamais « GR20 » en dur.
/// Tout texte d'interface via Slang (5 langues) ; le CONTENU editorial du plan
/// est traduit INLINE dans la donnee ([pickLocalized]). Look GR20 conserve.
class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trail = ref.watch(trailConfigProvider);
    // Acces REACTIF, derive des droits Drift LOCAUX (offline-safe) : demo =
    // verrouille (teaser), sinon debloque. Tant qu'indetermine -> chargement.
    final isDemoAsync = ref.watch(isDemoModeProvider(trail.id));
    final planAsync = ref.watch(trainingPlanProvider);

    return Scaffold(
      appBar: AppHeader(title: t.training.title),
      body: SafeArea(
        child: isDemoAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _LockedView(trail: trail, planAsync: planAsync),
          data: (isDemo) => isDemo
              ? _LockedView(trail: trail, planAsync: planAsync)
              : _UnlockedView(trail: trail, planAsync: planAsync),
        ),
      ),
    );
  }
}

// ===========================================================================
// ETAT VERROUILLE (pas de pack/abo) — teaser + paywall
// ===========================================================================

/// Vue VERROUILLEE (spec etat « verrouille ») : intro effort (visible), apercu
/// FLOUTE des phases (seances masquees), encart paywall + bouton « Debloquer ».
/// L'ecran donne envie, il ne livre pas le detail.
class _LockedView extends ConsumerWidget {
  const _LockedView({required this.trail, required this.planAsync});

  final TrailConfig trail;
  final AsyncValue<TrainingPlan> planAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = planAsync.value;
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      children: [
        _IntroEffortCard(trail: trail, plan: plan),
        const SizedBox(height: AppTheme.spacingBase),
        if (plan != null) _BlurredPhasesPreview(plan: plan),
        const SizedBox(height: AppTheme.spacingBase),
        _PaywallCard(trail: trail),
      ],
    );
  }
}

/// Apercu FLOUTE des phases (verrouille) : on montre les grandes phases, les
/// seances restent masquees (flou + cadenas) — teaser de valeur.
class _BlurredPhasesPreview extends StatelessWidget {
  const _BlurredPhasesPreview({required this.plan});

  final TrainingPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne des phases (lisible : donne envie) ...
          Wrap(
            spacing: AppTheme.spacingMd,
            runSpacing: AppTheme.spacingSm,
            children: [
              for (final phase in plan.phases)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_phaseIcon(phase.icon),
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: AppTheme.spacingXs),
                    Text(
                      pickLocalized(
                        fr: phase.titleFr,
                        en: phase.titleEn,
                        de: phase.titleDe,
                        it: phase.titleIt,
                        es: phase.titleEs,
                      ),
                      style: theme.textTheme.labelLarge,
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          // ... mais le detail des seances est FLOUTE (masque).
          Stack(
            alignment: Alignment.center,
            children: [
              // Barres grisees simulant les seances masquees.
              Column(
                children: List.generate(
                  3,
                  (_) => Container(
                    height: 14,
                    margin:
                        const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withAlpha(25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              Icon(
                Icons.lock_outline,
                color: theme.colorScheme.onSurface.withAlpha(120),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Encart PAYWALL (spec) : cadenas + « inclus dans le pack <sentier> » + CTA
/// « Debloquer » -> paywall. Le pack ouvre l'acces (pas le solde d'etapes).
class _PaywallCard extends StatelessWidget {
  const _PaywallCard({required this.trail});

  final TrailConfig trail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = t.training;
    return AppCard(
      backgroundColor: theme.colorScheme.primary.withAlpha(18),
      borderColor: theme.colorScheme.primary.withAlpha(80),
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock, color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  tr.paywallTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            tr.paywallIncludedIn(trail: trail.displayName),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            tr.paywallSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(170),
            ),
          ),
          const SizedBox(height: AppTheme.spacingBase),
          AppButton(
            icon: Icons.lock_open,
            label: tr.unlock,
            onPressed: () => showPaywallSheet(
              context,
              trailId: trail.id,
              totalStages: trail.totalStages,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// ETAT DEBLOQUE (pack/abo/demo) — plan complet, cochable
// ===========================================================================

/// Vue DEBLOQUEE (spec etats « normal / sans fiche / sans date / trop proche /
/// sans plan specifique »). Compose l'encart effort+compte a rebours, les blocs
/// de phases cochables, l'objectif chiffre et la barre de progression, et insere
/// les invites NON BLOQUANTES selon le contexte (fiche/date/plan generique).
class _UnlockedView extends ConsumerWidget {
  const _UnlockedView({required this.trail, required this.planAsync});

  final TrailConfig trail;
  final AsyncValue<TrainingPlan> planAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return planAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _NoPlanState(),
      data: (plan) {
        // Sentier SANS plan exploitable (aucune phase) -> message neutre.
        if (plan.phases.isEmpty) return _NoPlanState();
        return _PlanContent(trail: trail, plan: plan);
      },
    );
  }
}

/// Contenu deroulant du plan debloque (tous etats « debloque »).
class _PlanContent extends ConsumerWidget {
  const _PlanContent({required this.trail, required this.plan});

  final TrailConfig trail;
  final TrainingPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = t.training;
    final theme = Theme.of(context);

    final daysUntil = ref.watch(trainingDaysUntilDepartureProvider);
    final tooClose = ref.watch(trainingDepartureTooCloseProvider);
    final hasSpecificPlan =
        ref.watch(hasSpecificTrainingPlanProvider).value ?? true;
    final perso = ref.watch(trainingPersonalizationProvider).value;
    final progress = ref.watch(trainingProgressProvider(trail.id));

    // Seances du plan (IDs stables) pour borner la progression.
    final planSessionIds = {
      for (final ph in plan.phases)
        for (final s in ph.sessions) s.id,
    };
    final doneCount = progress.doneCountFor(planSessionIds);
    final totalCount = planSessionIds.length;

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      children: [
        // --- Encart bleu : effort du sentier + compte a rebours (ou invite) ---
        _IntroEffortCard(
          trail: trail,
          plan: plan,
          daysUntilDeparture: daysUntil,
        ),
        const SizedBox(height: AppTheme.spacingBase),

        // --- Etat « sans date » : pas de compte a rebours -> invite Calendrier ---
        if (daysUntil == null) ...[
          _InviteBanner(
            icon: Icons.event_available,
            message: tr.inviteSetDate,
          ),
          const SizedBox(height: AppTheme.spacingBase),
        ],

        // --- Etat « depart trop proche » : avertissement + plan condense ---
        if (tooClose) ...[
          _WarningBanner(
            message: tr.departureTooClose(days: daysUntil ?? 0),
          ),
          const SizedBox(height: AppTheme.spacingBase),
        ],

        // --- Etat « sans fiche » : invite non bloquante a remplir la fiche ---
        if (perso != null && !perso.hasProfile) ...[
          _InviteBanner(
            icon: Icons.badge_outlined,
            message: tr.inviteFillProfile,
          ),
          const SizedBox(height: AppTheme.spacingBase),
        ],

        // --- Etat « plan generique » : aucun plan dedie a ce sentier ---
        if (!hasSpecificPlan) ...[
          _InviteBanner(
            icon: Icons.info_outline,
            message: tr.genericPlanNotice,
          ),
          const SizedBox(height: AppTheme.spacingBase),
        ],

        // --- Rappel de prudence adapte au verdict (personnalisation) ---
        if (perso?.verdict == 'caution' || perso?.verdict == 'danger') ...[
          _WarningBanner(message: tr.cautionVerdictNotice),
          const SizedBox(height: AppTheme.spacingBase),
        ],

        // --- Titre de section ---
        Text(
          tr.planOverWeeks(n: plan.durationWeeks),
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppTheme.spacingSm),

        // --- Blocs de phases depliables a seances cochables ---
        for (final phase in plan.phases)
          _PhaseBlock(
            phase: phase,
            condensed: tooClose,
            isDone: progress.isDone,
            onToggle: (id) =>
                ref.read(trainingProgressProvider(trail.id).notifier).toggle(id),
          ),
        const SizedBox(height: AppTheme.spacingBase),

        // --- Encart orange : objectif chiffre (repere du sentier) ---
        if (plan.objective != null) ...[
          _ObjectiveCard(objective: plan.objective!),
          const SizedBox(height: AppTheme.spacingBase),
        ],

        // --- Barre de progression (« N seances sur M faites ») ---
        _ProgressCard(done: doneCount, total: totalCount),
      ],
    );
  }
}

/// Encart bleu d'intro : rappelle l'EFFORT du sentier (distance + D+) + compte a
/// rebours (« Depart dans X jours ») si la date est posee. Visible meme
/// verrouille (informatif). Agnostique : chiffres du sentier charge.
class _IntroEffortCard extends StatelessWidget {
  const _IntroEffortCard({
    required this.trail,
    required this.plan,
    this.daysUntilDeparture,
  });

  final TrailConfig trail;
  final TrainingPlan? plan;
  final int? daysUntilDeparture;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = t.training;
    final weeks = plan?.durationWeeks ?? 8;
    return AppCard(
      backgroundColor: AppTheme.bleuRepos.withAlpha(20),
      borderColor: AppTheme.bleuRepos.withAlpha(70),
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.fitness_center,
              color: AppTheme.bleuRepos, size: 24),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.effortIntro(
                    weeks: weeks,
                    km: trail.totalDistanceKm.round(),
                    elevation: trail.totalElevationGain,
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
                if (daysUntilDeparture != null &&
                    daysUntilDeparture! >= 0) ...[
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    tr.countdown(days: daysUntilDeparture!),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.bleuRepos,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bloc de phase DEPLIABLE a seances COCHABLES (maquette). Replie par defaut
/// sauf la 1re. En mode condense (depart trop proche), l'affichage reste mais
/// la phase est marquee « condensee ».
class _PhaseBlock extends StatelessWidget {
  const _PhaseBlock({
    required this.phase,
    required this.condensed,
    required this.isDone,
    required this.onToggle,
  });

  final TrainingPhase phase;
  final bool condensed;
  final bool Function(String sessionId) isDone;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = t.training;
    final title = pickLocalized(
      fr: phase.titleFr,
      en: phase.titleEn,
      de: phase.titleDe,
      it: phase.titleIt,
      es: phase.titleEs,
    );
    final subtitle = pickLocalized(
      fr: phase.subtitleFr,
      en: phase.subtitleEn,
      de: phase.subtitleDe,
      it: phase.subtitleIt,
      es: phase.subtitleEs,
    );
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        // 1re phase ouverte par defaut (maquette).
        initiallyExpanded: phase.id == 'foundation',
        leading: Icon(_phaseIcon(phase.icon), color: theme.colorScheme.primary),
        title: Text(
          tr.phaseWeeks(
            start: phase.weekStart,
            end: phase.weekEnd,
            title: title,
          ),
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle.isEmpty
            ? null
            : Text(subtitle, style: theme.textTheme.bodySmall),
        childrenPadding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
        children: [
          for (final session in phase.sessions)
            CheckboxListTile(
              key: ValueKey('training-session-${session.id}'),
              value: isDone(session.id),
              onChanged: (_) => onToggle(session.id),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              title: Text(
                pickLocalized(
                  fr: session.labelFr,
                  en: session.labelEn,
                  de: session.labelDe,
                  it: session.labelIt,
                  es: session.labelEs,
                ),
                style: theme.textTheme.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }
}

/// Encart orange « objectif cle » (maquette) : le but chiffre a atteindre avant
/// de partir (repere du sentier charge, donnee du plan).
class _ObjectiveCard extends StatelessWidget {
  const _ObjectiveCard({required this.objective});

  final TrainingObjective objective;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      backgroundColor: AppTheme.orangeDifficile.withAlpha(20),
      borderColor: AppTheme.orangeDifficile.withAlpha(80),
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.my_location,
              color: AppTheme.orangeDifficile, size: 22),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.training.objectiveTitle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.orangeDifficile,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  pickLocalized(
                    fr: objective.labelFr,
                    en: objective.labelEn,
                    de: objective.labelDe,
                    it: objective.labelIt,
                    es: objective.labelEs,
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Barre de progression « N seances sur M faites » + barre lineaire.
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = total > 0 ? done / total : 0.0;
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.training.progress(done: done, total: total),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: theme.colorScheme.onSurface.withAlpha(25),
            ),
          ),
        ],
      ),
    );
  }
}

/// Etat « sentier sans plan » (spec) : message neutre, jamais d'ecran casse.
class _NoPlanState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty,
                size: 48, color: theme.colorScheme.onSurface.withAlpha(120)),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              t.training.noPlan,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(170),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bandeau d'invite NON BLOQUANTE (fiche / date / plan generique).
class _InviteBanner extends StatelessWidget {
  const _InviteBanner({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withAlpha(60),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bandeau d'AVERTISSEMENT (depart trop proche / verdict prudent).
class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.orangeDifficile.withAlpha(28),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.orangeDifficile.withAlpha(90)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber,
              size: 20, color: AppTheme.orangeDifficile),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(message, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

/// Resout le nom d'icone de phase (donnee) en [IconData] (couche UI).
IconData _phaseIcon(String name) {
  switch (name) {
    case 'terrain':
      return Icons.terrain;
    case 'hiking':
      return Icons.hiking;
    case 'directions_walk':
      return Icons.directions_walk;
    case 'fitness_center':
      return Icons.fitness_center;
    case 'favorite_outline':
      return Icons.favorite_outline;
    default:
      return Icons.directions_walk;
  }
}
