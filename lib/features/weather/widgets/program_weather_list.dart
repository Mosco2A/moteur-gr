import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../domain/forecast_reach.dart';
import '../presentation/weather_date_format.dart';
import '../presentation/weather_freshness.dart';
import '../providers/program_weather_provider.dart';
import 'day_forecast_card.dart' show DayForecastCard;

/// METEO ETAPE PAR ETAPE (tache 572, U1).
///
/// Une carte par JOUR DE PROGRAMME : le numero du jour, sa DATE, le NOM du lieu
/// ou le randonneur arrivera ce jour-la, et le temps prevu a ce lieu ce jour-la.
///
/// C'est la demande de Chris mot pour mot : « la meteo a l'endroit ou on est
/// cense se trouver le lendemain, puis le surlendemain etc ». Et c'est aussi la
/// raison pour laquelle chaque ligne porte un NOM : un bulletin sans nom de lieu
/// ne sert a rien.
///
/// Les trois cas ou il n'y a PAS de chiffre a montrer sont ecrits, jamais laisses
/// en blanc :
///   * pas de date de depart -> on la demande (le trek n'est pas forcement pour
///     aujourd'hui) ;
///   * journee au-dela de la portee du fournisseur -> on dit jusqu'ou on sait ;
///   * journee dans la portee mais absente du bulletin en cache -> on le dit.
/// Et les journees au-dela de la fenetre fiable portent le badge « Tendance » :
/// la valeur est affichee, mais jamais sans dire ce qu'elle vaut.
class ProgramWeatherList extends ConsumerWidget {
  const ProgramWeatherList({super.key, required this.trailId});

  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(programWeatherProvider(trailId));

    if (state.days.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: t.weather.program.title,
          icon: Icons.route_outlined,
          iconColor: theme.colorScheme.primary,
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          t.weather.program.subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(160),
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),

        // Sans date de depart, aucune journee ne peut etre datee : on le dit une
        // fois, en tete, au lieu de le repeter sur chaque ligne.
        if (state.departureUnknown) ...[
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            decoration: BoxDecoration(
              color: AppTheme.orangeDifficile.withAlpha(15),
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border:
                  Border.all(color: AppTheme.orangeDifficile.withAlpha(60)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.event_busy_outlined,
                    size: 18, color: AppTheme.orangeDifficile),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    t.weather.program.unknownDeparture,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.orangeDifficile,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
        ],

        // Fraicheur GLOBALE de la section : la FABRICATION la plus recente parmi
        // les journees affichables (lot 625). Elle change des qu'une passe de
        // synchronisation rapporte un bulletin plus recent — c'est precisement ce
        // qui manquait pour que le bouton « produise » quelque chose de visible.
        if (!state.departureUnknown)
          _FreshnessLine(produiteLe: state.fabricationLaPlusRecente),

        const SizedBox(height: AppTheme.spacingSm),
        for (final day in state.days)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
            child: _ProgramDayCard(day: day),
          ),
      ],
    );
  }
}

/// Ligne de fraicheur : quand le bulletin affiche a-t-il ete FABRIQUE.
class _FreshnessLine extends StatelessWidget {
  const _FreshnessLine({required this.produiteLe});

  final DateTime? produiteLe;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final freshness = weatherFreshness(produiteLe: produiteLe, t: t);
    // LES COULEURS SUIVENT LA GRAVITE, ET LE ROUGE EST RESERVE AU CAS OU L'ON NE
    // MONTRE PLUS RIEN. Un bulletin de trois jours n'est pas « un peu vieux » :
    // c'est le cas que Christophe a nomme dangereux, et il ne doit pas porter la
    // meme couleur qu'un bulletin de sept heures.
    final color = switch (freshness.level) {
      FreshnessLevel.fresh => AppTheme.vertFacile,
      FreshnessLevel.jourCourantPerime =>
        theme.colorScheme.onSurface.withAlpha(170),
      FreshnessLevel.stale => AppTheme.orangeDifficile,
      FreshnessLevel.tropVieux => AppTheme.rougeUrgence,
      FreshnessLevel.unknown => AppTheme.grisGranite,
    };
    return Row(
      children: [
        Icon(Icons.update, size: 14, color: color),
        const SizedBox(width: AppTheme.spacingXs),
        Expanded(
          child: Text(
            freshness.label,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// Carte d'une journee de programme.
///
/// Reutilise [DayForecastCard] — meme carte, meme liseré d'alerte, memes
/// pastilles que le reste du module — en lui donnant un en-tete different : le
/// JOUR DE PROGRAMME, sa DATE et son LIEU D'ARRIVEE au lieu de la seule date du
/// bulletin. Recopier ce corps ici aurait cree deux rendus a maintenir, qui
/// auraient divergé au premier correctif.
class _ProgramDayCard extends StatelessWidget {
  const _ProgramDayCard({required this.day});

  final ProgramDayWeather day;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final forecast = day.day;

    // Titre : « Jour 3 · sam. 5 juil. ». Sans date de depart, le jour seul —
    // on n'invente pas une date qu'on n'a pas.
    final dated = day.reach != ForecastReach.unknownDeparture;
    final title = dated
        ? '${t.weather.program.dayLabel(day: day.dayNumber)} · '
            '${formatWeatherDate(day.date, 'EEE d MMM', languageCode)}'
        : t.weather.program.dayLabel(day: day.dayNumber);
    final subtitle = day.placeName.isEmpty
        ? ''
        : t.weather.program.place(place: day.placeName);
    final restBadge = day.isRestDay
        ? _Badge(label: t.weather.program.restDay, color: AppTheme.vertFacile)
        : null;

    // Journee sans chiffre a montrer : carte sobre qui DIT pourquoi.
    if (forecast == null) {
      return AppCard(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                if (restBadge != null) restBadge,
              ],
            ),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            _Absence(
              reach: day.reach,
              porteeAnnoncee: day.porteeAnnoncee,
            ),
          ],
        ),
      );
    }

    return DayForecastCard(
      day: forecast,
      title: title,
      subtitle: subtitle,
      trailing: restBadge,
      extraChips: [
        if (day.reach == ForecastReach.trend)
          _TrendChip(label: t.weather.program.trendBadge),
      ],
      footnote: day.reach == ForecastReach.trend
          ? Text(
              t.weather.program.trendHint(reliable: reliableForecastDays),
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.orangeDifficile,
                height: 1.3,
              ),
            )
          : null,
    );
  }
}

/// Pastille « Tendance » : la valeur est affichee, mais jamais sans dire ce
/// qu'elle vaut.
class _TrendChip extends StatelessWidget {
  const _TrendChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: AppTheme.orangeDifficile.withAlpha(30),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.trending_up,
              size: 14, color: AppTheme.orangeDifficile),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppTheme.orangeDifficile),
          ),
        ],
      ),
    );
  }
}

/// Pourquoi il n'y a pas de chiffre pour cette journee — ecrit, jamais blanc.
class _Absence extends StatelessWidget {
  const _Absence({required this.reach, required this.porteeAnnoncee});

  final ForecastReach reach;

  /// Portee REELLEMENT recue, annoncee au randonneur (lot 625).
  final int porteeAnnoncee;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final (IconData icon, String message) = switch (reach) {
      ForecastReach.beyondHorizon => (
          Icons.hourglass_empty,
          t.weather.program.beyondHorizon(horizon: porteeAnnoncee),
        ),
      ForecastReach.unknownDeparture => (
          Icons.event_busy_outlined,
          t.weather.program.unknownDeparture,
        ),
      // DISTINCT DE « aucune donnee », ET LA DISTINCTION N'EST PAS COSMETIQUE.
      // « Aucune donnee » veut dire que nous n'avons rien pour ce lieu ce jour-la.
      // « Bulletin trop ancien » veut dire que nous avons quelque chose et que nous
      // REFUSONS de le montrer, parce qu'il a plus de trois jours. Les confondre
      // laisserait croire a un trou de couverture la ou il y a un choix delibere.
      ForecastReach.tropVieux => (
          Icons.history_toggle_off,
          t.weather.program.tooOld,
        ),
      _ => (Icons.cloud_off_outlined, t.weather.program.noData),
    };
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppTheme.grisGranite),
          const SizedBox(width: AppTheme.spacingXs),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.grisGranite,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
