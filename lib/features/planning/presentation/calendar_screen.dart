import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../notifications/providers/download_reminder_provider.dart';
import '../models/planned_day.dart';
import '../providers/planned_days_provider.dart';

/// Formate une date de facon robuste (parite comportement GR20, mais sans
/// dependre de `initializeDateFormatting` — l'app StepWays ne l'appelle pas,
/// cf. `weather_date_format.dart`). Tente le format localise (locale Slang
/// courante) puis retombe sur le format independant de la locale (en_US) si les
/// donnees de locale ne sont pas chargees. Jamais d'exception a l'affichage.
String _formatDate(DateTime date, String pattern, String languageCode) {
  try {
    return DateFormat(pattern, languageCode).format(date);
  } on Exception {
    return DateFormat(pattern).format(date);
  }
}

/// Ecran CALENDRIER (parite GR20 `CalendarScreen`).
///
/// Outil de DATES : l'utilisateur choisit sa date de DEPART, la date d'ARRIVEE
/// est calculee (depart + totalDays - 1), et un calendrier visuel mois par mois
/// montre les JOURS DE MARCHE et les JOURS DE REPOS du programme du sentier
/// courant. Si aucune date n'est choisie, le picker s'ouvre directement a
/// l'arrivee sur l'ecran (parite GR20 M-05b).
///
/// Generique multi-sentiers, ZERO hardcode : les jours de marche/repos viennent
/// du programme du sentier actif ([plannedDaysProvider]) et le total de jours de
/// [planningStatsProvider]. La date de depart est persistee via
/// [downloadReminderProvider] (SharedPreferences, par sentier) — c'est la source
/// de verite des dates cote StepWays (l'equivalent de `itineraryConfig.startDate`
/// de GR20). Hors systeme de peaux : couleurs semantiques d'AppTheme + du
/// `colorScheme`. Tout libelle passe par Slang (`t.calendar.*`) et les dates sont
/// localisees via la locale Slang courante (jamais de format en dur non
/// localise).
///
/// ECART DE MODELE ASSUME (cf. rapport) : StepWays n'a pas de provider de
/// progression de planification global (`planning_progress`) — GR20 marque
/// `PlanningStepKeys.calendar` completee au choix de date. Cote StepWays, ce
/// jalon n'existe pas ; le choix de date est simplement persiste (source unique
/// [downloadReminderProvider]). Aucune autre difference (hors peau).
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key, required this.trailId});

  /// Identifiant du sentier courant (dates + programme par sentier).
  final String trailId;

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  /// Mois actuellement affiche dans le calendrier.
  DateTime? _displayedMonth;

  /// Vrai tant que le picker d'ouverture automatique (M-05b) n'a pas encore ete
  /// declenche, pour ne l'ouvrir qu'une seule fois.
  bool _autoPickTried = false;

  @override
  Widget build(BuildContext context) {
    final reminder = ref.watch(downloadReminderProvider(widget.trailId));
    final days = ref.watch(plannedDaysProvider(widget.trailId));
    final stats = ref.watch(planningStatsProvider(widget.trailId));
    final theme = Theme.of(context);
    final startDate = reminder.departureDate;

    // Initialise le mois affiche a la date de depart (ou +30 j par defaut),
    // normalise au premier du mois. Fait ici (et non dans initState) car la date
    // de depart est chargee de facon asynchrone (SharedPreferences).
    _displayedMonth ??= DateTime(
      (startDate ?? DateTime.now().add(const Duration(days: 30))).year,
      (startDate ?? DateTime.now().add(const Duration(days: 30))).month,
    );

    // Protection : si aucun itineraire n'est configure (aucun jour planifie),
    // afficher un etat vide (meme pattern que le PROGRAMME / GR20 `planning`).
    if (days.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(t.calendar.title),
          leading: _BackButton(),
        ),
        body: SafeArea(child: _EmptyItineraryState(trailId: widget.trailId)),
      );
    }

    // M-05b : si pas de date choisie, ouvrir le DatePicker directement (une fois).
    if (startDate == null && !_autoPickTried) {
      _autoPickTried = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pickStartDate();
      });
    }

    final totalDays = stats.totalDays;
    final endDate = startDate?.add(Duration(days: totalDays - 1));

    return Scaffold(
      appBar: AppBar(
        title: Text(t.calendar.title),
        leading: _BackButton(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingBase),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Section dates depart / arrivee ---
                    _DatePickerSection(
                      startDate: startDate,
                      endDate: endDate,
                      onPickStartDate: _pickStartDate,
                    ),
                    const SizedBox(height: AppTheme.spacingLg),

                    // --- Resume du trek ---
                    _TrekSummary(stats: stats),
                    const SizedBox(height: AppTheme.spacingLg),

                    // --- Calendrier visuel mensuel ---
                    if (startDate != null) ...[
                      _buildMonthHeader(theme),
                      const SizedBox(height: AppTheme.spacingSm),
                      _buildCalendarGrid(theme, startDate, days),
                      const SizedBox(height: AppTheme.spacingBase),
                      _buildCalendarLegend(theme),
                      const SizedBox(height: AppTheme.spacingLg),

                      // --- Liste des jours avec boutons separer / grouper ---
                      _buildDayActions(theme, days),
                    ] else ...[
                      _NoDateState(onPickStartDate: _pickStartDate),
                    ],

                    const SizedBox(height: AppTheme.spacingLg),
                  ],
                ),
              ),
            ),

            // --- Bouton VALIDER LES DATES ---
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: startDate != null
                      ? () => context.push('/trail/${widget.trailId}/planning')
                      : null,
                  child: Text(t.calendar.validate),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Selectionne une date de depart (parite GR20 `_pickStartDate`).
  ///
  /// Plage aujourd'hui -> +365 j. La date est persistee via
  /// [downloadReminderProvider] (source unique cote StepWays). Le mois affiche
  /// se recale sur la date choisie.
  Future<void> _pickStartDate() async {
    final reminder = ref.read(downloadReminderProvider(widget.trailId));
    final now = DateTime.now();

    // Le picker herite deja du theme de l'app (couleur primaire = peau active) :
    // pas de builder de teinte en dur (GR20 forcait un vert fixe, non desirable
    // ici — parite comportement, pas parite couleur : « hors peau »).
    final picked = await showDatePicker(
      context: context,
      initialDate:
          reminder.departureDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      await ref
          .read(downloadReminderProvider(widget.trailId).notifier)
          .setDepartureDate(picked);
      if (!mounted) return;
      setState(() {
        _displayedMonth = DateTime(picked.year, picked.month);
      });
    }
  }

  /// En-tete du mois avec navigation (parite GR20 `_buildMonthHeader`).
  Widget _buildMonthHeader(ThemeData theme) {
    final locale = LocaleSettings.currentLocale.languageCode;
    final monthLabel = _formatDate(_displayedMonth!, 'MMMM yyyy', locale);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: t.calendar.previousMonth,
          onPressed: () {
            setState(() {
              _displayedMonth = DateTime(
                _displayedMonth!.year,
                _displayedMonth!.month - 1,
              );
            });
          },
        ),
        Text(
          monthLabel.toUpperCase(),
          style: theme.textTheme.titleLarge?.copyWith(letterSpacing: 1.0),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: t.calendar.nextMonth,
          onPressed: () {
            setState(() {
              _displayedMonth = DateTime(
                _displayedMonth!.year,
                _displayedMonth!.month + 1,
              );
            });
          },
        ),
      ],
    );
  }

  /// Grille du calendrier mensuel (parite GR20 `_buildCalendarGrid`).
  ///
  /// Le modele StepWays [PlannedDay] ne porte pas de date propre (contrairement
  /// a GR20) : chaque jour du programme est date par sa position chronologique
  /// depuis la date de depart (jour i -> depart + i), coherent avec le calcul de
  /// la date d'arrivee. On construit donc une map date -> PlannedDay a partir de
  /// cet index, puis on peint chaque cellule (depart, arrivee, marche, repos,
  /// passe) exactement comme GR20.
  Widget _buildCalendarGrid(
    ThemeData theme,
    DateTime startDate,
    List<PlannedDay> days,
  ) {
    final scheme = theme.colorScheme;
    final firstDayOfMonth =
        DateTime(_displayedMonth!.year, _displayedMonth!.month, 1);
    final daysInMonth =
        DateTime(_displayedMonth!.year, _displayedMonth!.month + 1, 0).day;
    // Lundi = 1 (la semaine commence le lundi).
    final startWeekday = firstDayOfMonth.weekday; // 1=lun, 7=dim

    // Map date -> PlannedDay : chaque jour du programme est positionne a
    // depart + son index (chronologie du sentier). Cle normalisee a la journee.
    final Map<String, PlannedDay> dayMap = {};
    final startDay = DateTime(startDate.year, startDate.month, startDate.day);
    for (var i = 0; i < days.length; i++) {
      final d = startDay.add(Duration(days: i));
      dayMap['${d.year}-${d.month}-${d.day}'] = days[i];
    }

    final totalDays = days.length;
    final endDate = startDay.add(Duration(days: totalDays - 1));

    // Noms des jours de la semaine (Slang, localises).
    final weekDayNames = [
      t.calendar.weekdays.mon,
      t.calendar.weekdays.tue,
      t.calendar.weekdays.wed,
      t.calendar.weekdays.thu,
      t.calendar.weekdays.fri,
      t.calendar.weekdays.sat,
      t.calendar.weekdays.sun,
    ];

    return Column(
      children: [
        // En-tete jours de la semaine.
        Row(
          children: weekDayNames.map((name) {
            return Expanded(
              child: Center(
                child: Text(
                  name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.grisGranite,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppTheme.spacingSm),

        // Jours du mois (6 semaines max).
        ...List.generate(6, (weekIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: List.generate(7, (dayIndex) {
                final cellIndex = weekIndex * 7 + dayIndex;
                final dayOffset = cellIndex - (startWeekday - 1);
                final dayNum = dayOffset + 1;

                if (dayNum < 1 || dayNum > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 42));
                }

                final cellDate = DateTime(
                  _displayedMonth!.year,
                  _displayedMonth!.month,
                  dayNum,
                );
                final key = '${cellDate.year}-${cellDate.month}-${cellDate.day}';
                final plannedDay = dayMap[key];

                // Detecter les jours passes.
                final today = DateTime.now();
                final todayDate = DateTime(today.year, today.month, today.day);
                final isPastDay = cellDate.isBefore(todayDate);

                Color? bgColor;
                Color? textColor;
                BoxBorder? border;

                final isStartDay = cellDate.year == startDay.year &&
                    cellDate.month == startDay.month &&
                    cellDate.day == startDay.day;

                final isEndDay = cellDate.year == endDate.year &&
                    cellDate.month == endDate.month &&
                    cellDate.day == endDate.day;

                if (isPastDay) {
                  // Jours passes : gris attenue, pas de labels J1/J2.
                  textColor = AppTheme.grisGranite.withAlpha(76);
                } else if (isStartDay) {
                  bgColor = scheme.primary;
                  textColor = scheme.onPrimary;
                  border = Border.all(color: scheme.primary, width: 2);
                } else if (isEndDay) {
                  bgColor = AppTheme.orangeDifficile;
                  textColor = Colors.white;
                  border = Border.all(color: AppTheme.orangeDifficile, width: 2);
                } else if (plannedDay != null && plannedDay.isRestDay) {
                  bgColor = scheme.secondary.withAlpha(40);
                  textColor = scheme.secondary;
                  border = Border.all(color: scheme.secondary.withAlpha(80));
                } else if (plannedDay != null) {
                  bgColor = scheme.primary.withAlpha(30);
                  textColor = scheme.primary;
                  border = Border.all(color: scheme.primary.withAlpha(60));
                }

                return Expanded(
                  child: Container(
                    height: 42,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(6),
                      border: border,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$dayNum',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: textColor,
                              fontWeight: (!isPastDay &&
                                      (plannedDay != null ||
                                          isStartDay ||
                                          isEndDay))
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              fontSize: 14,
                            ),
                          ),
                          // Pas de labels J/R sur les jours passes ni depart/arrivee.
                          if (!isPastDay &&
                              plannedDay != null &&
                              !isStartDay &&
                              !isEndDay)
                            Text(
                              plannedDay.isRestDay
                                  ? t.calendar.restDayLabel
                                  : t.calendar.dayLabel.replaceAll(
                                      '{n}', '${plannedDay.dayNumber}'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                color: textColor?.withAlpha(180),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  /// Legende du calendrier (parite GR20 `_buildCalendarLegend`).
  Widget _buildCalendarLegend(ThemeData theme) {
    final scheme = theme.colorScheme;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppTheme.spacingBase,
      runSpacing: AppTheme.spacingXs,
      children: [
        _legendItem(theme, scheme.primary, t.calendar.legend.start),
        _legendItem(theme, scheme.primary.withAlpha(60), t.calendar.legend.walk),
        _legendItem(
            theme, scheme.secondary.withAlpha(80), t.calendar.legend.rest),
        _legendItem(theme, AppTheme.orangeDifficile, t.calendar.legend.arrival),
      ],
    );
  }

  Widget _legendItem(ThemeData theme, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 14),
        ),
      ],
    );
  }

  /// Liste des jours de marche avec boutons separer / grouper (parite GR20
  /// `_buildDayActions`). Reutilise le notifier du PROGRAMME (memes regles
  /// split/merge que l'ecran Programme et que GR20).
  Widget _buildDayActions(ThemeData theme, List<PlannedDay> days) {
    final scheme = theme.colorScheme;

    // Jours de marche uniquement (les repos ne sont pas ajustables ici).
    final hikeDays = <int>[];
    for (var i = 0; i < days.length; i++) {
      if (!days[i].isRestDay) hikeDays.add(i);
    }
    if (hikeDays.isEmpty) return const SizedBox.shrink();

    final notifier = ref.read(plannedDaysProvider(widget.trailId).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.calendar.adjustStages,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppTheme.grisGranite,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        ...hikeDays.map((index) {
          final day = days[index];
          // Numeros d'etape du jour (le modele StepWays porte la liste d'etapes,
          // pas une liste de numeros — on la derive, generique).
          final stageNumbers =
              day.stages.map((s) => s.stageNumber).toList(growable: false);
          final stageLabel = stageNumbers.length > 1
              ? t.calendar.stagesPlural
                  .replaceAll('{list}', stageNumbers.join(', '))
              : t.calendar.stageSingular.replaceAll(
                  '{n}',
                  stageNumbers.isNotEmpty ? '${stageNumbers.first}' : '-',
                );

          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${t.calendar.dayLabel.replaceAll('{n}', '${day.dayNumber}')} — $stageLabel',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 14,
                      color: scheme.primary,
                    ),
                  ),
                ),
                if (notifier.canSplit(index))
                  IconButton(
                    icon: const Icon(Icons.call_split, size: 20),
                    tooltip: t.calendar.splitStages,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    color: AppTheme.orangeDifficile,
                    onPressed: () => notifier.splitDay(index),
                  ),
                if (notifier.canMergeWithNext(index))
                  IconButton(
                    icon: const Icon(Icons.compress, size: 20),
                    tooltip: t.calendar.mergeWithNext,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    color: scheme.secondary,
                    onPressed: () => notifier.mergeWithNext(index),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// Bouton retour d'AppBar (parite GR20 : pop si possible, sinon retour HUB).
class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: t.a11y.back,
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      },
    );
  }
}

/// Section date de depart et d'arrivee (parite GR20 `_DatePickerSection`).
class _DatePickerSection extends StatelessWidget {
  const _DatePickerSection({
    required this.startDate,
    required this.endDate,
    required this.onPickStartDate,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onPickStartDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = LocaleSettings.currentLocale.languageCode;
    String fmt(DateTime d) => _formatDate(d, 'EEE d MMM yyyy', locale);

    return Row(
      children: [
        // Date de depart.
        Expanded(
          child: InkWell(
            onTap: onPickStartDate,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingBase),
              decoration: BoxDecoration(
                color: scheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: scheme.primary.withAlpha(80)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.flight_takeoff,
                          size: 16, color: scheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        t.calendar.departure,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    startDate != null
                        ? fmt(startDate!)
                        : t.calendar.chooseDate,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: startDate != null ? null : AppTheme.grisGranite,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingSm),
          child: Icon(Icons.arrow_forward,
              size: 18, color: AppTheme.grisGranite),
        ),
        // Date d'arrivee (calculee).
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            decoration: BoxDecoration(
              color: AppTheme.orangeDifficile.withAlpha(20),
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(color: AppTheme.orangeDifficile.withAlpha(80)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flag,
                        size: 16, color: AppTheme.orangeDifficile),
                    const SizedBox(width: 6),
                    Text(
                      t.calendar.arrival,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.orangeDifficile,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  endDate != null ? fmt(endDate!) : '-- --',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: endDate != null ? null : AppTheme.grisGranite,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Resume du trek : jours total / marche / repos (parite GR20 `_TrekSummary`).
///
/// ECART DE MODELE : GR20 affiche en 4e colonne le SENS de marche
/// (`config.direction.label`). Le modele StepWays ne porte pas de sens de marche
/// (cf. residuels du chantier parite) — cette colonne est donc omise (les 3
/// autres, jours total / marche / repos, sont identiques a GR20).
class _TrekSummary extends StatelessWidget {
  const _TrekSummary({required this.stats});

  final PlanningStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      decoration: BoxDecoration(
        color: scheme.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: scheme.primary.withAlpha(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Flexible(
              child: _summaryItem(
                  theme, '${stats.totalDays}', t.calendar.summary.totalDays)),
          Container(
              width: 1, height: 30, color: AppTheme.grisGranite.withAlpha(40)),
          Flexible(
              child: _summaryItem(
                  theme, '${stats.trekDays}', t.calendar.summary.walkDays)),
          Container(
              width: 1, height: 30, color: AppTheme.grisGranite.withAlpha(40)),
          Flexible(
              child: _summaryItem(
                  theme, '${stats.restDays}', t.calendar.summary.restDays)),
        ],
      ),
    );
  }

  Widget _summaryItem(ThemeData theme, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 14),
        ),
      ],
    );
  }
}

/// Etat vide quand aucune date n'est selectionnee (parite GR20
/// `_buildNoDateState`).
class _NoDateState extends StatelessWidget {
  const _NoDateState({required this.onPickStartDate});

  final VoidCallback onPickStartDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        children: [
          const SizedBox(height: AppTheme.spacingXl),
          Icon(
            Icons.calendar_month,
            size: 64,
            color: AppTheme.grisGranite.withAlpha(80),
          ),
          const SizedBox(height: AppTheme.spacingBase),
          Text(
            t.calendar.noDate.title,
            style: theme.textTheme.titleLarge
                ?.copyWith(color: AppTheme.grisGranite),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            t.calendar.noDate.message,
            style:
                theme.textTheme.bodyMedium?.copyWith(color: AppTheme.grisGranite),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          ElevatedButton.icon(
            onPressed: onPickStartDate,
            icon: const Icon(Icons.calendar_today),
            label: Text(t.calendar.chooseDateAction),
          ),
        ],
      ),
    );
  }
}

/// Etat vide — aucun itineraire configure (parite GR20
/// `_buildEmptyItineraryState`).
class _EmptyItineraryState extends StatelessWidget {
  const _EmptyItineraryState({required this.trailId});

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
              Icons.calendar_month,
              size: 80,
              color: AppTheme.grisGranite.withAlpha(80),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              t.calendar.empty.title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppTheme.grisGranite,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              t.calendar.empty.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.grisGranite.withAlpha(180),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXl),
            ElevatedButton.icon(
              onPressed: () => context.push('/trail/$trailId/itinerary'),
              icon: const Icon(Icons.route),
              label: Text(t.calendar.empty.action),
            ),
          ],
        ),
      ),
    );
  }
}
