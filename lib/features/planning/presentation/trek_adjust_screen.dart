import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../models/planned_day.dart';
import '../providers/planned_days_provider.dart';
import '../providers/trek_edit_lock_provider.dart';
import '../widgets/day_action_chip.dart';

/// ADAPTER L'ITINERAIRE — modifier la rando EN COURS (R12, LOT L9).
///
/// PORTE D'ENTREE : section « Randonner » du cockpit, donc uniquement en rando
/// active. C'est la place que GR20 donne a ce geste (`ActiveStageScreen` ->
/// « Adapter itineraire », icone `Icons.edit_road`).
///
/// PARITE GR20 — le GESTE est celui de l'ecran « Programme » de GR20
/// (`planning_screen.dart`) : une liste de cartes-jour, et sur chaque jour les
/// memes trois actions compactes « Regrouper » (`Icons.compress`) / « Separer »
/// (`Icons.call_split`) / « Repos » (`Icons.self_improvement`), TOUJOURS
/// visibles, grisees quand l'action est impossible, et qui expliquent pourquoi
/// au tap (snackbar). Aucun flux maison n'est invente : c'est le meme
/// vocabulaire d'edition que la preparation, rendu par les memes widgets
/// ([DayActionChip], [DayMiniStat]).
///
/// CE QUI CHANGE PAR RAPPORT A LA PREPARATION (regle metier Christophe) :
///   1. **Les jours deja marches sont FIGES.** Ils sont rendus a part, en tete,
///      grises, cadenas + badge « Fait », SANS aucune action. Le refus n'est pas
///      qu'un affichage : il est porte par [PlannedDaysNotifier] (`isDayLocked`,
///      `splitBlockedReason`, `mergeBlockedReason`, `canAddRestDayAfter`), donc
///      infranchissable meme par une autre porte d'entree.
///   2. **Aucune inversion possible.** Il n'y a PAS de `ReorderableListView` ni
///      de poignee de glissement sur cet ecran : l'ordre des etapes ne se touche
///      plus une fois parti. (Cote domaine, `reorder` refuse egalement.)
///
/// DIFFERENCE ASSUMEE AVEC GR20 : l'ecran GR20 cense couvrir ce cas
/// (`ItineraryAdaptationScreen`, premium) est une MAQUETTE non cablee — son
/// bouton « Confirmer le nouveau plan » ne fait qu'un `setState` + snackbar et
/// n'ecrit nulle part. Ici, chaque action ecrit IMMEDIATEMENT dans
/// [plannedDaysProvider], la source unique du programme que lisent deja le
/// Programme, le Resume et le Calendrier : la modification est donc reelle et
/// visible partout dans l'app, pas un message de confirmation vide.
class TrekAdjustScreen extends ConsumerWidget {
  const TrekAdjustScreen({super.key, required this.trailId});

  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(plannedDaysProvider(trailId));
    // INDISPENSABLE : le verrou est injecte dans le notifier par `ref.listen`
    // (pour ne pas regenerer le programme a chaque etape terminee), donc il
    // change SANS emettre de nouvel etat de programme. Sans ce `watch`, une
    // etape terminee pendant que l'ecran est ouvert laisserait la carte du jour
    // qu'on vient de marcher encore modifiable.
    ref.watch(trekEditLockProvider);
    final notifier = ref.read(plannedDaysProvider(trailId).notifier);

    final lockedCount = notifier.lockedDayCount;
    final started = notifier.editLock.trekStarted;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.programme.inTrek.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: t.programme.helpTooltip,
            onPressed: () => _showHelpSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: days.isEmpty
            ? _EmptyAdjustState(message: t.programme.inTrek.empty.message,
                title: t.programme.inTrek.empty.title)
            : Column(
                children: [
                  _IntroBanner(
                    message: started
                        ? t.programme.inTrek.intro
                        : t.programme.inTrek.notStarted,
                    started: started,
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingBase,
                        vertical: AppTheme.spacingSm,
                      ),
                      children: [
                        // --- Deja marche (fige) ---
                        if (lockedCount > 0) ...[
                          _SectionLabel(
                            icon: Icons.lock_outline,
                            label: t.programme.inTrek.doneSection,
                          ),
                          for (var i = 0; i < lockedCount; i++)
                            _AdjustDayCard(
                              key: ValueKey('locked_day_$i'),
                              day: days[i],
                              locked: true,
                            ),
                          const SizedBox(height: AppTheme.spacingMd),
                        ],

                        // --- A venir (editable) ---
                        _SectionLabel(
                          icon: Icons.hiking,
                          label: t.programme.inTrek.upcomingSection,
                        ),
                        if (lockedCount >= days.length)
                          Padding(
                            padding: const EdgeInsets.all(AppTheme.spacingMd),
                            child: Text(
                              t.programme.inTrek.allDone,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )
                        else
                          for (var i = lockedCount; i < days.length; i++)
                            _AdjustDayCard(
                              key: ValueKey('day_${days[i].dayNumber}_$i'),
                              day: days[i],
                              locked: false,
                              canMerge: notifier.canMergeWithNext(i),
                              mergeBlockedReason: notifier.mergeBlockedReason(i),
                              canSplit: notifier.canSplit(i),
                              splitBlockedReason: notifier.splitBlockedReason(i),
                              onMerge: () => notifier.mergeWithNext(i),
                              onSplit: () => notifier.splitDay(i),
                              onAddRestDay: () => notifier.addRestDay(i),
                              onRemoveRestDay: days[i].isRestDay
                                  ? () => notifier.removeRestDay(i)
                                  : null,
                            ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        // Les modifications sont DEJA ecrites dans le programme
                        // (source unique) a chaque action : ce bouton confirme
                        // et rend la main, il ne « sauvegarde » pas en douce.
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(t.programme.inTrek.saved),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          if (context.canPop()) context.pop();
                        },
                        child: Text(t.programme.inTrek.validate),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Aide contextuelle (parite GR20 : `IconButton(info_outline)` ->
  /// `showModalBottomSheet`).
  void _showHelpSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.programme.inTrek.info.title,
                style: theme.textTheme.titleLarge),
            const SizedBox(height: AppTheme.spacingMd),
            _HelpLine(
              icon: Icons.lock_outline,
              title: t.programme.inTrek.info.done.title,
              body: t.programme.inTrek.info.done.body,
            ),
            _HelpLine(
              icon: Icons.edit_road,
              title: t.programme.inTrek.info.upcoming.title,
              body: t.programme.inTrek.info.upcoming.body,
            ),
            _HelpLine(
              icon: Icons.swap_vert,
              title: t.programme.inTrek.info.order.title,
              body: t.programme.inTrek.info.order.body,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(t.programme.inTrek.info.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bandeau d'explication en tete d'ecran : ce qui est modifiable, ce qui ne
/// l'est pas. Le randonneur doit comprendre la regle AVANT de taper un chip.
class _IntroBanner extends StatelessWidget {
  const _IntroBanner({required this.message, required this.started});

  final String message;
  final bool started;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppTheme.spacingBase,
        AppTheme.spacingBase,
        AppTheme.spacingBase,
        0,
      ),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            started ? Icons.edit_road : Icons.info_outline,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(message, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

/// Intitule de section (« Deja marche » / « A venir »).
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        top: AppTheme.spacingSm,
        bottom: AppTheme.spacingSm,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: dayNeutralColor(context)),
          const SizedBox(width: AppTheme.spacingSm),
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: dayNeutralColor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Une ligne d'aide du bottom-sheet.
class _HelpLine extends StatelessWidget {
  const _HelpLine({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(body, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte d'un jour sur l'ecran d'adaptation.
///
/// Deux etats :
///   * [locked] = jour DEJA MARCHE -> grise, cadenas, badge « Fait », AUCUNE
///     action, pas de tap : ce qui est fait est fait ;
///   * sinon -> memes mini-stats et memes trois chips que la carte de la
///     preparation (parite GR20), sans poignee de glissement (pas d'inversion).
class _AdjustDayCard extends StatelessWidget {
  const _AdjustDayCard({
    super.key,
    required this.day,
    required this.locked,
    this.canMerge = false,
    this.mergeBlockedReason,
    this.canSplit = false,
    this.splitBlockedReason,
    this.onMerge,
    this.onSplit,
    this.onAddRestDay,
    this.onRemoveRestDay,
  });

  final PlannedDay day;
  final bool locked;
  final bool canMerge;
  final String? mergeBlockedReason;
  final bool canSplit;
  final String? splitBlockedReason;
  final VoidCallback? onMerge;
  final VoidCallback? onSplit;
  final VoidCallback? onAddRestDay;
  final VoidCallback? onRemoveRestDay;

  Color _difficultyColor(int rank) {
    if (rank <= 1) return AppTheme.vertFacile;
    if (rank <= 2) return AppTheme.jauneModere;
    if (rank <= 3) return AppTheme.orangeDifficile;
    return AppTheme.rougeExtreme;
  }

  String _mergeLabel() {
    switch (mergeBlockedReason) {
      case 'no-next':
        return t.programme.mergeBlocked.noNext;
      case 'rest':
        return t.programme.mergeBlocked.rest;
      case 'locked':
        return t.programme.mergeBlocked.locked;
      case 'too-long':
        return t.programme.mergeBlocked.tooLong
            .replaceAll('{hours}', day.estimatedHours.toStringAsFixed(1))
            .replaceAll(
              '{max}',
              PlannedDaysNotifier.maxManualHoursPerDay.toInt().toString(),
            );
      default:
        return t.programme.mergeBlocked.noNext;
    }
  }

  /// `portion` : tache 558 — une etape deja coupee en deux ne se recoupe pas,
  /// et ce n'est pas la meme chose que « rien a couper ».
  String _splitLabel() => switch (splitBlockedReason) {
        'locked' => t.programme.splitBlocked.locked,
        'portion' => t.programme.splitBlocked.portion,
        _ => t.programme.splitBlocked.single,
      };

  void _blocked(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  String _formatDuration(double totalHours) {
    final hours = totalHours.floor();
    final minutes = ((totalHours - hours) * 60).round();
    return minutes == 0
        ? '${hours}h'
        : '${hours}h${minutes.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRest = day.isRestDay;
    final accent = locked
        ? dayNeutralColor(context)
        : isRest
            ? AppTheme.bleuRepos
            : _difficultyColor(day.maxDifficulty);

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Opacity(
        // Les jours faits sont VISIBLES (le randonneur voit son parcours en
        // entier) mais visiblement inertes.
        opacity: locked ? 0.55 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withAlpha(30),
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  border: Border.all(color: accent, width: 2),
                ),
                child: Center(
                  child: Text(
                    'J${day.dayNumber}',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: accent, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isRest)
                      Row(
                        children: [
                          Icon(Icons.self_improvement, size: 20, color: accent),
                          const SizedBox(width: AppTheme.spacingSm),
                          Flexible(
                            child: Text(
                              t.programme.restDay,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: accent,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      ...day.stages.map(
                        (stage) => Text(
                          stage.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                      Wrap(
                        spacing: AppTheme.spacingMd,
                        runSpacing: AppTheme.spacingXs,
                        children: [
                          DayMiniStat(
                            icon: Icons.straighten,
                            value: '${day.totalDistanceKm.toStringAsFixed(1)} km',
                          ),
                          DayMiniStat(
                            icon: Icons.arrow_upward,
                            value: '${day.totalElevationGainM} m D+',
                            color: AppTheme.rougeExtreme,
                          ),
                          DayMiniStat(
                            icon: Icons.schedule,
                            value: _formatDuration(day.estimatedHours),
                          ),
                        ],
                      ),
                    ],
                    if (locked) ...[
                      const SizedBox(height: AppTheme.spacingXs),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline,
                              size: 16, color: dayNeutralColor(context)),
                          const SizedBox(width: 4),
                          Text(
                            t.programme.inTrek.doneBadge,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: dayNeutralColor(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Actions : UNIQUEMENT sur un jour non fait. Sur un jour fige, on
              // n'affiche AUCUN chip (meme grise) — il n'y a rien a negocier.
              // Aucune poignee de glissement nulle part : l'ordre est gele.
              if (!locked)
                Column(
                  children: [
                    if (!isRest) ...[
                      DayActionChip(
                        icon: Icons.compress,
                        label: t.programme.actions.merge,
                        tone: DayActionTone.principal,
                        enabled: canMerge,
                        onPressed: canMerge
                            ? onMerge!
                            : () => _blocked(context, _mergeLabel()),
                      ),
                      DayActionChip(
                        icon: Icons.call_split,
                        label: t.programme.actions.split,
                        tone: DayActionTone.secondaire,
                        enabled: canSplit,
                        onPressed: canSplit
                            ? onSplit!
                            : () => _blocked(context, _splitLabel()),
                      ),
                    ],
                    if (onAddRestDay != null)
                      DayActionChip(
                        icon: Icons.self_improvement,
                        label: t.programme.actions.rest,
                        tone: DayActionTone.principal,
                        onPressed: onAddRestDay!,
                      ),
                    if (onRemoveRestDay != null)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                        color: AppTheme.rougeUrgence,
                        tooltip: t.programme.actions.removeRest,
                        onPressed: onRemoveRestDay,
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 48, minHeight: 48),
                      ),
                  ],
                )
              else
                Icon(Icons.lock_outline,
                    size: 20, color: dayNeutralColor(context)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Etat vide : aucun programme a adapter.
class _EmptyAdjustState extends StatelessWidget {
  const _EmptyAdjustState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy,
                size: 48, color: dayNeutralColor(context)),
            const SizedBox(height: AppTheme.spacingMd),
            Text(title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.spacingSm),
            Text(message,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
