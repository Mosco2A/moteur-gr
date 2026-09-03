import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../diploma/presentation/widgets/session_trace_painter.dart';
import '../providers/adventure_recap_provider.dart';

/// PARITE GR20, LOT 3 (#99433), point 3.A — Recapitulatif « Mon aventure ».
///
/// Parite avec `features/after/presentation/adventure_recap_screen.dart` de
/// GR20 : affiche les STATS DE LA SESSION REELLE (etapes REELLEMENT marchees,
/// distance/D+ parcourus, duree, dates, trace GPS si dispo). Accessible quand le
/// trek est TERMINE ou ABANDONNE (plus la VITRINE pour la demo) ; sinon un etat
/// verrouille est affiche (comme GR20).
///
/// Zero chiffre statique du sentier : la session reelle
/// ([adventureStatsProvider], derive de `TrekSessionsDao`) fait foi. Tous les
/// libelles passent par Slang (`t.recap.*`) — zero texte en dur, aucun libelle
/// propre a un sentier. A11y : chaque stat porte un [Semantics] label ; les
/// cibles tactiles (boutons) respectent le plancher 48px d'[AppButton].
class AdventureRecapScreen extends ConsumerWidget {
  const AdventureRecapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recapT = t.recap;
    final available = ref.watch(isRecapAvailableProvider);

    if (!available) {
      return Scaffold(
        appBar: AppBar(title: Text(recapT.title)),
        body: _LockedState(
          title: recapT.lockedTitle,
          message: recapT.lockedMessage,
        ),
      );
    }

    final statsAsync = ref.watch(adventureStatsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(recapT.title)),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _LockedState(
          title: recapT.lockedTitle,
          message: recapT.noData,
        ),
        data: (stats) => _RecapBody(stats: stats),
      ),
    );
  }
}

/// Corps du recap une fois les stats reelles chargees.
class _RecapBody extends ConsumerWidget {
  const _RecapBody({required this.stats});
  final AdventureStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recapT = t.recap;
    final trailId = ref.watch(trailConfigProvider.select((c) => c.id));
    final diplomaUnlocked = ref.watch(isDiplomaUnlockedProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bandeau finisher vs parcours partiel (ton distinct, parite GR20).
          _CongratsBanner(fullyWalked: stats.fullyWalked),
          const SizedBox(height: AppTheme.spacingLg),

          // Statistiques REELLES de la session.
          SectionHeader(title: recapT.statsSection, icon: Icons.bar_chart),
          _StatsCard(stats: stats),
          const SizedBox(height: AppTheme.spacingLg),

          // Trace GPS reelle de la session (offline, sans tuiles).
          SectionHeader(title: recapT.traceSection, icon: Icons.route),
          _TraceCard(stats: stats),
          const SizedBox(height: AppTheme.spacingLg),

          // Le diplome n'est propose QUE s'il est deverrouille (finisher reel ou
          // vitrine) — parite GR20 (bouton diplome reserve au finisher).
          if (diplomaUnlocked)
            AppButton(
              label: recapT.viewDiploma,
              icon: Icons.emoji_events,
              onPressed: () => context.push('/trail/$trailId/diploma'),
            ),
        ],
      ),
    );
  }
}

/// Bandeau de tete : finisher (parcours fini) vs parcours partiel / abandon.
class _CongratsBanner extends StatelessWidget {
  const _CongratsBanner({required this.fullyWalked});
  final bool fullyWalked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recapT = t.recap;
    final title = fullyWalked ? recapT.finisherTitle : recapT.partialTitle;
    final subtitle =
        fullyWalked ? recapT.finisherSubtitle : recapT.partialSubtitle;
    final color =
        fullyWalked ? theme.colorScheme.primary : AppTheme.grisTexteSecondaire;

    return Semantics(
      container: true,
      label: '$title. $subtitle',
      child: AppCard(
        backgroundColor: color.withAlpha(30),
        borderColor: color.withAlpha(90),
        child: Column(
          children: [
            Icon(
              fullyWalked ? Icons.emoji_events : Icons.terrain,
              size: 48,
              color: color,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.grisTexteSecondaire,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte des statistiques reelles (etapes marchees, distance, D+, duree, dates).
class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});
  final AdventureStats stats;

  @override
  Widget build(BuildContext context) {
    final recapT = t.recap;

    final stagesLabel = recapT.stages
        .replaceAll('{done}', '${stats.stagesWalked}')
        .replaceAll('{total}', '${stats.totalStages}');
    final distanceLabel =
        recapT.distance.replaceAll('{km}', stats.distanceKm.toStringAsFixed(0));
    final elevationLabel =
        recapT.elevation.replaceAll('{meters}', '${stats.elevationGainM}');
    final durationLabel =
        recapT.duration.replaceAll('{days}', '${stats.durationDays}');

    final rows = <Widget>[
      _StatRow(icon: Icons.flag, label: stagesLabel),
      _StatRow(icon: Icons.straighten, label: distanceLabel),
      _StatRow(icon: Icons.trending_up, label: elevationLabel),
      _StatRow(icon: Icons.timer, label: durationLabel),
    ];

    // Dates reelles (si la session porte un debut et une fin). Le formatage
    // localise est tolerant : si les donnees de locale intl ne sont pas encore
    // initialisees (edge case hors app), on retombe sur un format ISO plutot que
    // de faire echouer toute la carte de stats.
    final start = stats.startDate;
    final end = stats.endDate;
    if (start != null && end != null) {
      String fmtDate(DateTime d) {
        try {
          return DateFormat.yMMMd(LocaleSettings.currentLocale.languageCode)
              .format(d);
        } catch (_) {
          return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
              '${d.day.toString().padLeft(2, '0')}';
        }
      }

      final datesLabel = recapT.dates
          .replaceAll('{start}', fmtDate(start))
          .replaceAll('{end}', fmtDate(end));
      rows.add(_StatRow(icon: Icons.date_range, label: datesLabel));
    }

    return AppCard(
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: AppTheme.spacingBase),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// Ligne de statistique (icone + libelle), exposee a l'a11y via [Semantics].
class _StatRow extends StatelessWidget {
  const _StatRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: label,
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 22),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte de la trace GPS reelle de la session (rendu offline, sans tuiles).
class _TraceCard extends StatelessWidget {
  const _TraceCard({required this.stats});
  final AdventureStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recapT = t.recap;
    final points = stats.tracePoints;

    return AppCard(
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: points.length < 2
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.map,
                      size: 48,
                      color: theme.colorScheme.primary.withAlpha(120),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      recapT.noTrace,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.grisTexteSecondaire,
                      ),
                    ),
                  ],
                ),
              )
            : CustomPaint(
                painter: SessionTracePainter(
                  points: [
                    for (final p in points) Offset(p.lng, p.lat),
                  ],
                  color: theme.colorScheme.primary,
                ),
              ),
      ),
    );
  }
}

/// Etat verrouille (trek ni termine ni abandonne, hors vitrine) — parite GR20.
class _LockedState extends StatelessWidget {
  const _LockedState({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 64,
              color: AppTheme.grisTexteSecondaire,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppTheme.grisTexteSecondaire,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.grisTexteSecondaire,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
