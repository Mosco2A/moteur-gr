import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/models/stage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../booking/domain/models/nuitee_type.dart';
import '../../booking/providers/nuitee_selections_provider.dart';
import '../../notifications/providers/download_reminder_provider.dart';
import '../../trek/providers/gps_providers.dart';
import '../models/planned_day.dart';
import '../providers/planned_days_provider.dart';

/// Ecran RESUME / SYNTHESE du plan (parite GR20 `PlanSummaryScreen`).
///
/// AGREGATEUR : cet ecran n'invente aucune donnee, il SYNTHETISE ce qui existe
/// deja cote StepWays (programme, etapes, nuitees, dates) et le presente a
/// l'identique de GR20 : etat vide + 4 sections (Configuration, Statistiques,
/// Jour par jour, Boutons d'action). Toutes les donnees viennent des providers
/// StepWays deja en place, ZERO hardcode de localite ni de « GR20 ».
///
/// Reutilisation (aucune duplication de donnee) :
///   * PROGRAMME jour par jour + jours de repos : [plannedDaysProvider] (family
///     par sentier) — meme source que Programme / Calendrier / Nuitees ;
///   * STATISTIQUES globales : [planningStatsProvider] — equivalent EXACT du
///     `planningStatsProvider` de GR20 (distance, D+, D-, heures, etapes, repos),
///     deja calcule a partir des etapes du programme (rien de nouveau ici) ;
///   * DATES : la date de depart persistee par sentier via
///     [downloadReminderProvider] (source unique cote StepWays, cf. Calendrier).
///     Le modele [PlannedDay] ne porte pas de date propre -> chaque jour est date
///     par sa position chronologique (depart + index), exactement comme l'ecran
///     Calendrier ;
///   * HEBERGEMENT (icone par jour) : [nuiteeSelectionsProvider] (lot Nuitees),
///     `typeFor(dayNumber)` -> [NuiteeType] et son icone ;
///   * SENS de marche : [selectedDirectionProvider] (defaut = 1er sens declare
///     par le sentier). Le D+ / D- et l'ordre sont pris DANS LE SENS choisi
///     (meme regle que Transport et le moteur de fin de trek) ;
///   * TITRE « Mon {sentier} » : [TrailConfig.displayName] (generique).
///
/// ECARTS DE MODELE assumes (cf. rapport, memes que les autres ecrans parite) :
///   * StepWays n'a pas de notion de PARCOURS (entier/moitie) ni de MODE CONFORT
///     dans le moteur generique -> la carte Configuration montre Direction +
///     Duree + Dates (les 2 lignes GR20 « Parcours » / « Confort » n'ont pas
///     d'equivalent et sont donc omises, jamais inventees) ;
///   * le detail d'etape s'ouvre via `/stages/:num` (route StepWays existante,
///     meme cible que l'ecran Programme), et non via l'index GR20.
///
/// Hors systeme de peaux : couleurs semantiques d'AppTheme + du `colorScheme`
/// (le « vert » et le « bleu » de GR20 suivent ici la peau active,
/// `primary` / `secondary`). Tout libelle d'interface passe par Slang
/// (`t.summary.*`, 5 langues) ; a11y via [Semantics] sur les tuiles et boutons.
class PlanSummaryScreen extends ConsumerWidget {
  const PlanSummaryScreen({super.key, required this.trailId});

  /// Identifiant du sentier dont on synthetise le plan (family par sentier).
  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final days = ref.watch(plannedDaysProvider(trailId));
    final stats = ref.watch(planningStatsProvider(trailId));
    final startDate =
        ref.watch(downloadReminderProvider(trailId)).departureDate;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.summary.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: t.a11y.back,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: SafeArea(
        child: days.isEmpty
            ? _EmptyState(trailId: trailId)
            : _SummaryContent(
                trailId: trailId,
                theme: theme,
                days: days,
                stats: stats,
                startDate: startDate,
              ),
      ),
    );
  }
}

/// Contenu principal du resume — 4 sections (parite GR20).
class _SummaryContent extends StatelessWidget {
  const _SummaryContent({
    required this.trailId,
    required this.theme,
    required this.days,
    required this.stats,
    required this.startDate,
  });

  final String trailId;
  final ThemeData theme;
  final List<PlannedDay> days;
  final PlanningStats stats;
  final DateTime? startDate;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Section 1 : carte Configuration ---
          _ConfigSummaryCard(
            trailId: trailId,
            stats: stats,
            startDate: startDate,
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // --- Section 2 : carte Statistiques globales ---
          _GlobalStatsCard(stats: stats),
          const SizedBox(height: AppTheme.spacingLg),

          // --- Section 3 : liste jour par jour ---
          Text(
            t.summary.dayByDay,
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          ...List.generate(days.length, (i) {
            // Date du jour : depart + index chronologique (le modele StepWays ne
            // porte pas de date propre, cf. Calendrier). Null si pas de depart.
            final date = startDate?.add(Duration(days: i));
            return _DaySummaryTile(
              trailId: trailId,
              day: days[i],
              date: date,
            );
          }),

          const SizedBox(height: AppTheme.spacingLg),

          // --- Section 4 : boutons d'action ---
          _ActionButtons(trailId: trailId, days: days, stats: stats),

          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }
}

/// Etat vide — aucun itineraire configure (parite GR20 `_buildEmptyState`).
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.trailId});

  final String trailId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.summarize,
              size: 80,
              color: AppTheme.grisGranite.withAlpha(80),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              t.summary.empty.title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppTheme.grisGranite,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              t.summary.empty.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.grisGranite.withAlpha(180),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXl),
            ElevatedButton.icon(
              onPressed: () => context.push('/trail/$trailId/itinerary'),
              icon: const Icon(Icons.route),
              label: Text(t.summary.empty.action),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte resume de la configuration (parite GR20 `_ConfigSummaryCard`).
///
/// Titre « Mon {sentier} » (data-driven via [TrailConfig.displayName]). Lignes :
/// Direction + Duree + Dates. Les lignes GR20 « Parcours » et « Confort » sont
/// omises (pas d'equivalent dans le moteur generique StepWays, cf. en-tete).
class _ConfigSummaryCard extends ConsumerWidget {
  const _ConfigSummaryCard({
    required this.trailId,
    required this.stats,
    required this.startDate,
  });

  final String trailId;
  final PlanningStats stats;
  final DateTime? startDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final config = ref.watch(trailConfigProvider);
    // Sens de marche : 1er sens declare par le sentier par defaut (jamais un
    // code en dur), meme regle que Transport / moteur de fin de trek.
    final forward =
        config.directions.isNotEmpty ? config.directions.first : 'NS';
    final direction = ref.watch(selectedDirectionProvider) ?? forward;

    final durationValue = stats.restDays > 0
        ? t.summary.durationValueWithRest(
            days: stats.trekDays.toString(),
            rest: stats.restDays.toString(),
          )
        : t.summary.durationValue(days: stats.trekDays.toString());

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withAlpha(60),
            scheme.primary.withAlpha(30),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: scheme.primary.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre « Mon {sentier} ».
          Row(
            children: [
              Icon(Icons.terrain, size: 28, color: scheme.primary),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  t.summary.configTitle(name: config.displayName),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // Direction (sens de marche choisi).
          _ConfigRow(
            icon: Icons.navigation,
            label: t.summary.direction,
            value: direction,
          ),

          // Duree.
          _ConfigRow(
            icon: Icons.calendar_today,
            label: t.summary.duration,
            value: durationValue,
          ),

          // Dates (si une date de depart est posee).
          if (startDate != null) ...[
            _ConfigRow(
              icon: Icons.event,
              label: t.summary.startDate,
              value: _formatDate(startDate!, 'd MMMM yyyy'),
            ),
            if (stats.totalDays > 0)
              _ConfigRow(
                icon: Icons.event_available,
                label: t.summary.endDate,
                value: _formatDate(
                  startDate!.add(Duration(days: stats.totalDays - 1)),
                  'd MMMM yyyy',
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Ligne de configuration (icone + label + valeur) — parite GR20 `_ConfigRow`.
class _ConfigRow extends StatelessWidget {
  const _ConfigRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.grisGranite),
          const SizedBox(width: AppTheme.spacingSm),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Carte des statistiques globales (parite GR20 `_GlobalStatsCard`).
///
/// Grille 2x3 des 6 KPI, alimentee par [PlanningStats] (equivalent exact du
/// provider GR20). Aucune valeur en dur : tout vient de l'agregat du programme.
class _GlobalStatsCard extends StatelessWidget {
  const _GlobalStatsCard({required this.stats});

  final PlanningStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.summary.stats.title,
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          Row(
            children: [
              Expanded(
                child: _BigStat(
                  icon: Icons.straighten,
                  value: stats.totalDistance.toStringAsFixed(1),
                  unit: 'km',
                  label: t.summary.stats.distance,
                  color: scheme.secondary,
                ),
              ),
              Expanded(
                child: _BigStat(
                  icon: Icons.arrow_upward,
                  value: '${stats.totalElevationGain}',
                  unit: 'm',
                  label: t.summary.stats.elevationGain,
                  color: AppTheme.rougeExtreme,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              Expanded(
                child: _BigStat(
                  icon: Icons.arrow_downward,
                  value: '${stats.totalElevationLoss}',
                  unit: 'm',
                  label: t.summary.stats.elevationLoss,
                  color: scheme.secondary,
                ),
              ),
              Expanded(
                child: _BigStat(
                  icon: Icons.schedule,
                  value: stats.totalHours.toStringAsFixed(0),
                  unit: 'h',
                  label: t.summary.stats.duration,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              Expanded(
                child: _BigStat(
                  icon: Icons.hiking,
                  value: '${stats.stageCount}',
                  unit: '',
                  label: t.summary.stats.stages,
                  color: AppTheme.orangeDifficile,
                ),
              ),
              Expanded(
                child: _BigStat(
                  icon: Icons.self_improvement,
                  value: '${stats.restDays}',
                  unit: '',
                  label: t.summary.stats.restDays,
                  color: AppTheme.jauneModere,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Statistique principale avec grosse valeur (parite GR20 `_BigStat`).
class _BigStat extends StatelessWidget {
  const _BigStat({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String unit;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (unit.isNotEmpty)
                TextSpan(
                  text: ' $unit',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Tuile resume d'un jour — tappable (parite GR20 `_DaySummaryTile`).
///
/// Jour de marche : J{n} | etapes | date | distance | D+ | duree | icone
/// hebergement | chevron -> tap ouvre le detail d'etape (`/stages/:num`). Jour de
/// repos : J{n} | icone repos | libelle | date | chevron -> tap ouvre un
/// `showModalBottomSheet` (date, lieu). D+ et duree du jour sont pris DANS LE
/// SENS de marche (cf. [directionalDayStats]).
class _DaySummaryTile extends ConsumerWidget {
  const _DaySummaryTile({
    required this.trailId,
    required this.day,
    required this.date,
  });

  final String trailId;
  final PlannedDay day;
  final DateTime? date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Sens de marche courant (defaut = 1er sens du sentier).
    final config = ref.watch(trailConfigProvider);
    final forward =
        config.directions.isNotEmpty ? config.directions.first : 'NS';
    final selected = ref.watch(selectedDirectionProvider) ?? forward;
    final isForward = selected == forward;

    if (day.isRestDay) {
      return _buildRestDay(context, theme, scheme, ref);
    }

    // Jour de marche : stats agregees DANS LE SENS de marche.
    final stats = directionalDayStats(day, isForward: isForward);

    // Etiquettes des etapes (numeros), derivees de la liste d'etapes du jour.
    final stageLabels = day.stages
        .map((s) => t.summary.stageLabel(n: s.stageNumber.toString()))
        .toList(growable: false);

    // Icone hebergement (lot Nuitees) : type choisi pour ce jour (defaut refuge).
    final nuiteeType =
        ref.watch(nuiteeSelectionsProvider).typeFor(day.dayNumber);

    return Semantics(
      button: true,
      label: t.summary.a11y.dayTile(day: day.dayNumber.toString()),
      child: InkWell(
        onTap: day.stages.isNotEmpty
            ? () => context.push('/stages/${day.stages.first.stageNumber}')
            : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingXs),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSm,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          ),
          child: Row(
            children: [
              // Numero du jour.
              SizedBox(
                width: 36,
                child: Text(
                  t.summary.dayLabel(n: day.dayNumber.toString()),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontSize: 14,
                  ),
                ),
              ),

              // Etapes + date.
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stageLabels.join(' + '),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (date != null)
                      Text(
                        _formatDate(date!, 'EEE d MMM'),
                        style:
                            theme.textTheme.bodySmall?.copyWith(fontSize: 14),
                      ),
                  ],
                ),
              ),

              // Stats compactes (distance / D+ / duree).
              SizedBox(
                width: 55,
                child: Text(
                  '${stats.km.toStringAsFixed(1)} km',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 14),
                  textAlign: TextAlign.right,
                ),
              ),
              SizedBox(
                width: 55,
                child: Text(
                  '+${stats.gain} m',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 14,
                    color: AppTheme.rougeExtreme,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '${stats.hours.toStringAsFixed(1)}h',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 14),
                  textAlign: TextAlign.right,
                ),
              ),

              // Icone hebergement (type de nuitee du jour).
              const SizedBox(width: AppTheme.spacingSm),
              Icon(
                nuiteeType.icon,
                size: 20,
                color: nuiteeType == NuiteeType.refuge
                    ? AppTheme.orangeDifficile
                    : scheme.secondary,
              ),

              // Chevron (affordance tap).
              const SizedBox(width: AppTheme.spacingXs),
              const Icon(Icons.chevron_right,
                  size: 20, color: AppTheme.grisGranite),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestDay(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
    WidgetRef ref,
  ) {
    // Type de nuitee du jour de repos (lot Nuitees) pour l'afficher dans la
    // fiche (equivalent du « Lieu » GR20, generique : type d'hebergement).
    final nuiteeType =
        ref.watch(nuiteeSelectionsProvider).typeFor(day.dayNumber);

    return Semantics(
      button: true,
      label: t.summary.a11y.restDayTile(day: day.dayNumber.toString()),
      child: InkWell(
        onTap: () {
          showModalBottomSheet<void>(
            context: context,
            builder: (ctx) {
              return Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.self_improvement,
                            size: 24, color: scheme.secondary),
                        const SizedBox(width: AppTheme.spacingSm),
                        Text(
                          t.summary.restDayTitle(n: day.dayNumber.toString()),
                          style: theme.textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    if (date != null)
                      Text(
                        _formatDate(date!, 'EEEE d MMMM yyyy'),
                        style: theme.textTheme.bodyLarge,
                      ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      t.summary.restDayPlace(place: nuiteeType.label),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                  ],
                ),
              );
            },
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingXs),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSm,
          ),
          decoration: BoxDecoration(
            color: scheme.secondary.withAlpha(15),
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  t.summary.dayLabel(n: day.dayNumber.toString()),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.secondary,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(Icons.self_improvement, size: 20, color: scheme.secondary),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                t.summary.restDay,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.secondary,
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                ),
              ),
              if (date != null) ...[
                const Spacer(),
                Text(
                  _formatDate(date!, 'EEE d MMM'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 14,
                    color: scheme.secondary,
                  ),
                ),
              ],
              const SizedBox(width: AppTheme.spacingXs),
              const Icon(Icons.chevron_right,
                  size: 20, color: AppTheme.grisGranite),
            ],
          ),
        ),
      ),
    );
  }
}

/// Boutons d'action en bas du resume (parite GR20 `_ActionButtons`).
///
/// « Exporter en PDF » et « Telecharger les cartes offline » = STUBS (SnackBar
/// « bientot disponible », comme GR20 : StepWays ne porte pas encore l'offline
/// reel ni l'export PDF). « Partager mon plan » = ACTIF via `share_plus`
/// (`Share.share`, meme API que le reste du code StepWays), texte GENERIQUE par
/// sentier (nom, config, stats, planning jour par jour) — aucun « GR20 » ni lieu
/// en dur.
class _ActionButtons extends ConsumerWidget {
  const _ActionButtons({
    required this.trailId,
    required this.days,
    required this.stats,
  });

  final String trailId;
  final List<PlannedDay> days;
  final PlanningStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Exporter en PDF (stub).
        Semantics(
          button: true,
          label: t.summary.a11y.export,
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.summary.actions.exportPdfSoon)),
              );
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: Text(t.summary.actions.exportPdf),
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),

        // Telecharger cartes offline (stub).
        Semantics(
          button: true,
          label: t.summary.a11y.download,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.summary.actions.downloadMapsSoon)),
              );
            },
            icon: const Icon(Icons.download),
            label: Text(t.summary.actions.downloadMaps),
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),

        // Partager (actif via share_plus).
        Semantics(
          button: true,
          label: t.summary.a11y.share,
          child: OutlinedButton.icon(
            onPressed: () {
              final config = ref.read(trailConfigProvider);
              final forward = config.directions.isNotEmpty
                  ? config.directions.first
                  : 'NS';
              final selected =
                  ref.read(selectedDirectionProvider) ?? forward;
              final startDate =
                  ref.read(downloadReminderProvider(trailId)).departureDate;
              final text = _buildShareText(
                trailName: config.displayName,
                isForward: selected == forward,
                startDate: startDate,
              );
              Share.share(text);
            },
            icon: const Icon(Icons.share),
            label: Text(t.summary.actions.share),
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.secondary,
              side: BorderSide(color: scheme.secondary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  /// Genere le texte de partage du plan (generique par sentier, i18n Slang).
  String _buildShareText({
    required String trailName,
    required bool isForward,
    required DateTime? startDate,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(t.summary.share.titleLine(name: trailName));
    buffer.writeln(
      stats.restDays > 0
          ? t.summary.share.walkDaysWithRest(
              days: stats.trekDays.toString(),
              rest: stats.restDays.toString(),
            )
          : t.summary.share.walkDays(days: stats.trekDays.toString()),
    );
    buffer.writeln('');
    buffer.writeln(
      t.summary.share.distance(km: stats.totalDistance.toStringAsFixed(1)),
    );
    buffer.writeln(
      t.summary.share.elevationGain(m: stats.totalElevationGain.toString()),
    );
    buffer.writeln(
      t.summary.share.elevationLoss(m: stats.totalElevationLoss.toString()),
    );
    buffer.writeln(
      t.summary.share.duration(h: stats.totalHours.toStringAsFixed(0)),
    );
    buffer.writeln('');

    if (startDate != null && stats.totalDays > 0) {
      buffer.writeln(t.summary.share.dates(
        start: _formatDate(startDate, 'd MMMM yyyy'),
        end: _formatDate(
          startDate.add(Duration(days: stats.totalDays - 1)),
          'd MMMM yyyy',
        ),
      ));
      buffer.writeln('');
    }

    buffer.writeln(t.summary.share.planning);
    for (final day in days) {
      if (day.isRestDay) {
        buffer.writeln(
          t.summary.share.dayRest(n: day.dayNumber.toString()),
        );
      } else {
        // Titre depart -> arrivee du jour DANS LE SENS de marche (parite GR20).
        final label = day.stages
            .map((s) => directionalStageTitle(s, isForward: isForward))
            .join(' + ');
        buffer.writeln(t.summary.share.dayStages(
          n: day.dayNumber.toString(),
          stages: label,
        ));
      }
    }

    buffer.writeln('');
    buffer.writeln(t.summary.share.footer(name: trailName));

    return buffer.toString();
  }
}

// --- Helpers agregateur (sens de marche + format date) --------------------

/// Stats d'un jour dans le sens de marche (immutable). Publique pour test.
class DaySummaryStats {
  const DaySummaryStats({
    required this.km,
    required this.gain,
    required this.hours,
  });
  final double km;
  final int gain;
  final double hours;
}

/// Agrege distance / D+ / duree d'un jour DANS LE SENS de marche.
///
/// Parite GR20 (« D+ du jour dans le sens choisi, inverse en sens retour ») :
/// dans le sens de reference le D+ = somme des `elevationGainM` ; dans le sens
/// inverse, la montee et la descente s'echangent (le D+ devient le D- officiel).
/// La distance et la duree sont invariantes au sens. Fonction pure (testable).
DaySummaryStats directionalDayStats(PlannedDay day, {required bool isForward}) {
  final km = day.totalDistanceKm;
  final gain = isForward ? day.totalElevationGainM : day.totalElevationLossM;
  final hours = day.estimatedHours;
  return DaySummaryStats(km: km, gain: gain, hours: hours);
}

/// Titre « Depart -> Arrivee » d'une etape DANS LE SENS de marche (parite GR20
/// `stageTitleForDirection`). En sens inverse, on lit l'arrivee comme depart et
/// inversement. Repli sur le nom de l'etape si les noms d'endpoints manquent
/// (sentier pauvre) — jamais d'invention de lieu. Fonction pure (testable).
String directionalStageTitle(StageModel stage, {required bool isForward}) {
  final dep = stage.departureName?.trim();
  final arr = stage.arrivalName?.trim();
  final from = isForward ? dep : arr;
  final to = isForward ? arr : dep;
  if ((from == null || from.isEmpty) && (to == null || to.isEmpty)) {
    return stage.name;
  }
  final fromLabel = (from == null || from.isEmpty) ? stage.name : from;
  final toLabel = (to == null || to.isEmpty) ? stage.name : to;
  return '$fromLabel -> $toLabel';
}

/// Formate une date de facon robuste (parite comportement Calendrier StepWays :
/// pas de dependance a `initializeDateFormatting`). Tente le format localise
/// (locale Slang courante) puis retombe sur le format independant de la locale
/// si les donnees de locale ne sont pas chargees. Jamais d'exception a
/// l'affichage.
String _formatDate(DateTime date, String pattern) {
  final languageCode = LocaleSettings.currentLocale.languageCode;
  try {
    return DateFormat(pattern, languageCode).format(date);
  } on Exception {
    return DateFormat(pattern).format(date);
  }
}
