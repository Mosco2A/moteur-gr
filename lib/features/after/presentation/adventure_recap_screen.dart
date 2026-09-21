import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/section_header.dart';
import '../../diploma/presentation/widgets/session_trace_painter.dart';
import '../data/gpx_export_service.dart';
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
        appBar: AppHeader(title: recapT.title),
        body: _LockedState(
          title: recapT.lockedTitle,
          message: recapT.lockedMessage,
        ),
      );
    }

    final statsAsync = ref.watch(adventureStatsProvider);

    return Scaffold(
      // Ph5 (L6d) : AppHeader universel (phase Après — recap).
      appBar: AppHeader(title: recapT.title),
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

          // CORRECTIF L5-5 : le detail jour par jour, qui n'existait pas.
          SectionHeader(title: recapT.daysSection, icon: Icons.calendar_month),
          const _DayByDaySection(),
          const SizedBox(height: AppTheme.spacingLg),

          // Le diplome n'est propose QUE s'il est deverrouille (finisher reel ou
          // vitrine) — parite GR20 (bouton diplome reserve au finisher).
          if (diplomaUnlocked) ...[
            AppButton(
              // CORRECTIF L5-8 : depuis la fusion des quatre entrees du
              // cockpit vers une, CE bouton est la porte du diplome. Sa cle
              // est stable pour que les parcours de test la suivent.
              key: const ValueKey('recap-diploma'),
              label: recapT.viewDiploma,
              icon: Icons.emoji_events,
              onPressed: () => context.push('/trail/$trailId/diploma'),
            ),
            const SizedBox(height: AppTheme.spacingMd),
          ],

          // R10 (retour Chris, LOT L10) — DEUXIEME PORTE D'ENTREE DU JOURNAL.
          // Parite GR20 : `adventure_recap_screen.dart` de GR20 pousse vers le
          // journal depuis l'ecran « Mon aventure ». Cote StepWays cette entree
          // etait absente : une fois le trek termine, relire ses notes imposait
          // de repasser par le cockpit. SANS GARDE (contrairement au diplome) :
          // le journal appartient au randonneur, qu'il ait fini ou abandonne.
          AppButton(
            label: recapT.viewJournal,
            icon: Icons.menu_book_outlined,
            onPressed: () => context.push('/journal'),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // CORRECTIF L5-3 : le recapitulatif n'offrait AUCUN partage.
          _ShareAdventureButton(stats: stats),
          const SizedBox(height: AppTheme.spacingMd),

          // CORRECTIF L5-4 : l'export GPX, qui n'existait pas.
          _ExportGpxButton(stats: stats),
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

/// Texte de partage du recapitulatif d'aventure (CORRECTIF L5-3).
///
/// Fonction PURE, donc testable sans toucher a la feuille de partage du
/// systeme. Elle reprend EXACTEMENT les lignes affichees a l'ecran : le
/// randonneur partage les chiffres qu'il a sous les yeux, pas un second
/// formatage qui finirait par diverger.
String buildAdventureShareText({
  required String trailName,
  required AdventureStats stats,
  required Translations$recap$fr recapT,
  double? averageSpeedKmh,
}) {
  final lines = adventureRecapRows(
    stats,
    recapT,
    averageSpeedKmh: averageSpeedKmh,
  ).map((r) => '- ${r.label}');
  return [recapT.shareHeadline(trail: trailName), ...lines].join('\n');
}

/// Bouton « Partager mon aventure » (CORRECTIF L5-3).
///
/// Le recapitulatif n'offrait AUCUN partage. share_plus est deja en
/// production ailleurs dans l'app (carte de partage, resume de plan) :
/// aucune dependance ajoutee, aucun nouveau motif introduit.
class _ShareAdventureButton extends ConsumerWidget {
  const _ShareAdventureButton({required this.stats});
  final AdventureStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recapT = t.recap;
    final trailName = ref.watch(trailConfigProvider.select((c) => c.displayName));
    final speed = ref.watch(adventureAverageSpeedProvider).value;

    return AppButton(
      label: recapT.shareAdventure,
      icon: Icons.share_outlined,
      onPressed: () async {
        // Capture AVANT tout await : la feuille de partage prend la main,
        // le `context` ne doit plus servir a afficher l'erreur.
        final messenger = ScaffoldMessenger.of(context);
        try {
          await Share.share(
            buildAdventureShareText(
              trailName: trailName,
              stats: stats,
              recapT: recapT,
              averageSpeedKmh: speed,
            ),
            subject: recapT.shareHeadline(trail: trailName),
          );
        } catch (_) {
          messenger.showSnackBar(
            SnackBar(content: Text(recapT.shareError)),
          );
        }
      },
    );
  }
}

/// Detail JOUR PAR JOUR de l'aventure (CORRECTIF L5-5).
///
/// Rien de tel n'existait cote StepWays. Les journees sortent de la TRACE
/// GPS, pas d'un decoupage theorique du sentier : une journee de repos, une
/// double etape ou une etape a cheval sur deux jours s'affichent telles
/// qu'elles ont ete marchees.
class _DayByDaySection extends ConsumerWidget {
  const _DayByDaySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recapT = t.recap;
    final daysAsync = ref.watch(adventureDaysProvider);

    return daysAsync.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (days) {
        if (days.isEmpty) {
          return AppCard(
            child: Text(
              recapT.noDays,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.grisTexteSecondaire,
                  ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < days.length; i++) ...[
              if (i > 0) const SizedBox(height: AppTheme.spacingSm),
              // Le numero affiche retombe sur la position dans la liste quand
              // la trace est anterieure a la migration v26 et ne porte pas de
              // jour de marche : on ne laisse jamais un « Jour null ».
              _DayCard(day: days[i], fallbackNumber: i + 1),
            ],
          ],
        );
      },
    );
  }
}

/// Une journee du detail jour par jour.
class _DayCard extends StatelessWidget {
  const _DayCard({required this.day, required this.fallbackNumber});

  final AdventureDay day;
  final int fallbackNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recapT = t.recap;
    final stats = day.stats;

    String fmtDate(DateTime d) {
      try {
        return DateFormat.yMMMd(LocaleSettings.currentLocale.languageCode)
            .format(d);
      } catch (_) {
        return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}';
      }
    }

    final h = stats.duration.inHours;
    final m = stats.duration.inMinutes.remainder(60);
    final speed = stats.averageSpeedKmh;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                recapT.dayLabel(day: day.dayIndex ?? fallbackNumber),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                fmtDate(day.date),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.grisTexteSecondaire,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            // Une journee sans etape terminee n'est PAS une anomalie : repos,
            // demi-journee, etape a cheval sur deux jours.
            day.stageIds.isEmpty
                ? recapT.dayRest
                : recapT.dayStages(count: day.stageIds.length),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.grisTexteSecondaire,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          // Wrap : en allemand et en espagnol, ces libelles cote a cote
          // debordent la largeur d'un telephone.
          Wrap(
            spacing: AppTheme.spacingLg,
            runSpacing: AppTheme.spacingXs,
            children: [
              Text(
                recapT.distance
                    .replaceAll('{km}', stats.distanceKm.toStringAsFixed(1)),
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                recapT.elevation
                    .replaceAll('{meters}', '${stats.elevationGainM}'),
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                recapT.elevationLoss(meters: stats.elevationLossM),
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                h > 0 ? '$h h $m' : '$m min',
                style: theme.textTheme.bodyMedium,
              ),
              // CORRECTIF L5-6 : la vitesse moyenne n'est affichee QUE
              // lorsqu'elle a un sens (cf. TrackSegmentStats).
              if (speed != null)
                Text(
                  recapT.averageSpeed(kmh: speed.toStringAsFixed(1)),
                  style: theme.textTheme.bodyMedium,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bouton « Exporter la trace en GPX » (CORRECTIF L5-4).
///
/// StepWays ne savait que LIRE du GPX ; l'export etait un TODO. Le fichier
/// est ECRIT puis propose au partage : sans ecriture, l'utilisateur n'aurait
/// aucun moyen de recuperer sa trace — c'est exactement le defaut corrige
/// au diplome par L5-1, on ne le rejoue pas ici.
class _ExportGpxButton extends ConsumerWidget {
  const _ExportGpxButton({required this.stats});
  final AdventureStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recapT = t.recap;
    final config = ref.watch(trailConfigProvider);

    return AppButton(
      label: recapT.exportGpx,
      icon: Icons.download_outlined,
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        // Sans point, on le DIT au lieu d'ecrire un fichier vide qui
        // n'ouvrirait nulle part.
        if (stats.tracePoints.isEmpty) {
          messenger.showSnackBar(SnackBar(content: Text(recapT.gpxEmpty)));
          return;
        }
        try {
          final content = GpxExportService.buildGpx(
            points: stats.tracePoints,
            trackName: config.displayName,
            description: recapT.shareHeadline(trail: config.displayName),
          );
          final file = await GpxExportService.saveGpx(
            content: content,
            trailId: config.id,
          );
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                recapT.gpxExported(file: file.uri.pathSegments.last),
              ),
            ),
          );
          await Share.shareXFiles([XFile(file.path)]);
        } catch (_) {
          messenger.showSnackBar(SnackBar(content: Text(recapT.gpxError)));
        }
      },
    );
  }
}

/// Une ligne du recapitulatif : une icone et un libelle deja localise.
typedef RecapRow = ({IconData icon, String label});

/// Lignes chiffrees du recapitulatif, dans l'ordre d'affichage.
///
/// Fonction unique, partagee par la carte a l'ecran et par le TEXTE DE
/// PARTAGE (correctif L5-3) : deux formatages separes finiraient par
/// diverger, et le randonneur partagerait des chiffres differents de ceux
/// qu'il a sous les yeux.
List<RecapRow> adventureRecapRows(
  AdventureStats stats,
  Translations$recap$fr recapT, {
  double? averageSpeedKmh,
}) {
  final rows = <RecapRow>[
    (
      icon: Icons.flag,
      label: recapT.stages
          .replaceAll('{done}', '${stats.stagesWalked}')
          .replaceAll('{total}', '${stats.totalStages}'),
    ),
    (
      icon: Icons.straighten,
      label:
          recapT.distance.replaceAll('{km}', stats.distanceKm.toStringAsFixed(0)),
    ),
    (
      icon: Icons.trending_up,
      label: recapT.elevation.replaceAll('{meters}', '${stats.elevationGainM}'),
    ),
    // CORRECTIF L5-2 : le D- cumule. Il manquait alors que
    // Stage.elevationLoss existait deja — une descente de plusieurs milliers
    // de metres se lit dans les genoux du randonneur.
    (
      icon: Icons.trending_down,
      label: recapT.elevationLoss(meters: stats.elevationLossM),
    ),
    (
      icon: Icons.timer,
      label: recapT.duration.replaceAll('{days}', '${stats.durationDays}'),
    ),
    // CORRECTIF L5-6 : la vitesse moyenne n'apparait QUE si elle est
    // MESUREE (cf. adventureAverageSpeedProvider). Diviser la distance
    // nominale des etapes par un temps reel donnerait un chiffre faux qui
    // aurait l'air vrai — dans ce cas on n'affiche rien du tout.
    if (averageSpeedKmh != null)
      (
        icon: Icons.speed,
        label: recapT.averageSpeed(kmh: averageSpeedKmh.toStringAsFixed(1)),
      ),
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

    rows.add((
      icon: Icons.date_range,
      label: recapT.dates
          .replaceAll('{start}', fmtDate(start))
          .replaceAll('{end}', fmtDate(end)),
    ));
  }
  return rows;
}

/// Carte des statistiques reelles (etapes marchees, distance, D+, D-, duree,
/// dates).
class _StatsCard extends ConsumerWidget {
  const _StatsCard({required this.stats});
  final AdventureStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speed = ref.watch(adventureAverageSpeedProvider).value;
    final rows = adventureRecapRows(stats, t.recap, averageSpeedKmh: speed);
    return AppCard(
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: AppTheme.spacingBase),
            _StatRow(icon: rows[i].icon, label: rows[i].label),
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
