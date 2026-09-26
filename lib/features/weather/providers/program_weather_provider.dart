import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/stage.dart';
import '../../notifications/providers/download_reminder_provider.dart';
import '../../planning/models/planned_day.dart';
import '../../planning/providers/planned_days_provider.dart';
import '../domain/forecast_reach.dart';
import '../models/weather_forecast.dart';
import 'weather_providers.dart';

// ---------------------------------------------------------------------------
// METEO ETAPE PAR ETAPE (tache 572, LOT U, U1).
//
// Ce que Chris a demande, verbatim : « indiquer le lieu des etapes et la meteo
// des etapes, pas celle du jour, pour l'etape du lendemain », puis, precise :
// « quand je dis etape par etape, c'es la meteo a l'endroit ou on est cense se
// trouver le lendemain, puis le surlendemain etc ».
//
// Ca change le modele, et pas qu'un peu. Avant, l'ecran affichait le bulletin
// d'UN point, jour d'API par jour d'API : « aujourd'hui, demain, J+2 » au meme
// endroit. Utile pour s'habiller le matin, inutile pour DECIDER. Ce qu'un
// randonneur veut savoir c'est le temps qu'il fera LA OU IL SERA, LE JOUR OU IL
// Y SERA.
//
// Les deux informations existaient deja dans l'application, elles n'avaient
// juste jamais ete croisees :
//   * le PROGRAMME ([plannedDaysProvider]) dit quelles etapes tombent quel jour,
//     y compris les jours de repos et les journees regroupees ou coupees ;
//   * la DATE DE DEPART ([downloadReminderProvider]) donne le calendrier — la
//     meme source que la faisabilite (LOT R) et la checklist, pas une nouvelle.
//
// Le LIEU d'une journee, c'est son point d'ARRIVEE : la ou le randonneur dort,
// et le seul point de la journee qui porte un nom (`arrivalName`). Un bulletin
// sans nom de lieu ne sert a rien ; c'est pour ca que le nom est obligatoire ici
// et que le repository echantillonne desormais ce meme point (endLat/endLng).
// ---------------------------------------------------------------------------

/// Meteo d'UNE journee du programme : un lieu nomme, une date, un bulletin.
class ProgramDayWeather {
  const ProgramDayWeather({
    required this.dayNumber,
    required this.date,
    required this.placeName,
    required this.stageNumber,
    required this.isRestDay,
    required this.reach,
    this.day,
    this.fetchedAt,
  });

  /// Numero du jour dans le programme (1 = jour de depart).
  final int dayNumber;

  /// Date calendaire de cette journee (date de depart + dayNumber - 1).
  ///
  /// C'est la date du PROGRAMME, pas l'index d'un tableau de prevision. Les deux
  /// ne coincident que si le trek part aujourd'hui.
  final DateTime date;

  /// Nom du lieu d'ARRIVEE de la journee, tel qu'il sera affiche.
  ///
  /// `arrivalName` de la derniere etape du jour quand le sentier le fournit,
  /// sinon le nom de cette etape. Jamais vide pour une journee de marche : un
  /// bulletin anonyme ne sert a rien.
  final String placeName;

  /// Etape dont l'arrivee nomme et localise la journee (clef du socle meteo).
  ///
  /// 0 pour une journee de repos en tete de programme, qui ne suit aucune etape.
  final int stageNumber;

  /// Journee de repos (le randonneur reste ou il est arrive la veille).
  final bool isRestDay;

  /// Ce que vaut la prevision de cette journee — et donc ce que l'ecran est en
  /// droit d'afficher.
  final ForecastReach reach;

  /// Prevision de CETTE journee a CE lieu. `null` des que [reach] n'est ni
  /// [ForecastReach.forecast] ni [ForecastReach.trend] : on n'affiche pas un
  /// chiffre qu'on n'a pas.
  final DayForecast? day;

  /// Instant du releve du bulletin d'ou vient [day] (fraicheur affichable).
  final DateTime? fetchedAt;

  /// Vrai si un chiffre peut etre affiche pour cette journee.
  bool get hasValue => day != null;
}

/// Etat de la meteo etape par etape d'un sentier.
class ProgramWeatherState {
  const ProgramWeatherState({
    required this.days,
    required this.departureDate,
    required this.isLoading,
  });

  /// Une entree par journee de programme, dans l'ordre du programme.
  final List<ProgramDayWeather> days;

  /// Date de depart retenue. `null` = le randonneur ne l'a pas choisie, et
  /// l'ecran la demande au lieu de supposer aujourd'hui.
  final DateTime? departureDate;

  /// Vrai tant qu'au moins une journee attend encore son bulletin.
  final bool isLoading;

  /// Vrai si la date de depart manque : aucune journee ne peut etre datee.
  bool get departureUnknown => departureDate == null;

  /// Releve le PLUS RECENT parmi les journees affichables — la fraicheur
  /// globale que l'ecran annonce en tete de section.
  DateTime? get latestFetchedAt {
    DateTime? latest;
    for (final d in days) {
      final f = d.fetchedAt;
      if (f == null) continue;
      if (latest == null || f.isAfter(latest)) latest = f;
    }
    return latest;
  }

  /// Nombre de journees pour lesquelles un chiffre est affichable.
  int get coveredDayCount => days.where((d) => d.hasValue).length;
}

/// METEO ETAPE PAR ETAPE du sentier [trailId].
///
/// Croise le programme, la date de depart et le socle meteo par etape. AUCUN
/// nouvel appel reseau et AUCUNE nouvelle ligne de cache : chaque journee lit le
/// bulletin de l'etape dont elle atteint l'arrivee, via
/// [stageWeatherProvider] — le meme que le HUB et l'ecran incendie. Le cout
/// reste donc d'au plus UN appel par etape du sentier (quota Open-Meteo gratuit :
/// 600 appels/minute, 10 000/jour), divise par le cache. Deux journees qui
/// finissent au meme endroit, ou un jour de repos qui suit une etape, partagent
/// la meme ligne de cache et ne declenchent rien de plus.
final programWeatherProvider =
    Provider.family<ProgramWeatherState, String>((ref, trailId) {
  final plan = ref.watch(plannedDaysProvider(trailId));

  // Meme source de date que la faisabilite (LOT R) et la checklist : le trek
  // n'est pas forcement pour aujourd'hui, et le moteur le DECLARE au lieu de le
  // supposer. Une lecture impossible (prefs indisponibles) vaut « inconnue ».
  DateTime? departure;
  try {
    departure = ref.watch(
      downloadReminderProvider(trailId).select((s) => s.departureDate),
    );
  } catch (_) {
    departure = null;
  }

  if (plan.isEmpty) {
    return ProgramWeatherState(
      days: const [],
      departureDate: departure,
      isLoading: true,
    );
  }

  final today = DateTime.now();
  final result = <ProgramDayWeather>[];
  var anyLoading = false;

  // Etape qui nomme la journee courante. Un jour de repos ne porte pas d'etape :
  // le randonneur reste ou il est ARRIVE la veille, donc il herite du lieu
  // precedent — c'est le meme endroit, donc le meme bulletin.
  StageModel? lastArrival;

  for (final planned in plan) {
    final stage = _arrivalStageOf(planned) ?? lastArrival;
    if (stage != null) lastArrival = stage;

    final date = departure == null
        ? today
        : DateTime(departure.year, departure.month, departure.day)
            .add(Duration(days: planned.dayNumber - 1));

    if (departure == null) {
      // Sans calendrier, on ne peut pas dire quel jour est quel jour. On nomme
      // quand meme le lieu (c'est une information sure) et on le declare.
      result.add(ProgramDayWeather(
        dayNumber: planned.dayNumber,
        date: date,
        placeName: _placeNameOf(stage),
        stageNumber: stage?.stageNumber ?? 0,
        isRestDay: planned.isRestDay,
        reach: ForecastReach.unknownDeparture,
      ));
      continue;
    }

    final daysAhead = calendarDaysBetween(today, date);

    // Au-dela de la portee du fournisseur, on ne demande RIEN : pas d'appel
    // inutile, pas de chiffre invente. On le dit, c'est tout.
    if (forecastReachFor(daysAhead: daysAhead) ==
        ForecastReach.beyondHorizon) {
      result.add(ProgramDayWeather(
        dayNumber: planned.dayNumber,
        date: date,
        placeName: _placeNameOf(stage),
        stageNumber: stage?.stageNumber ?? 0,
        isRestDay: planned.isRestDay,
        reach: ForecastReach.beyondHorizon,
      ));
      continue;
    }

    if (stage == null) {
      result.add(ProgramDayWeather(
        dayNumber: planned.dayNumber,
        date: date,
        placeName: _placeNameOf(null),
        stageNumber: 0,
        isRestDay: planned.isRestDay,
        reach: ForecastReach.noData,
      ));
      continue;
    }

    final weather = ref.watch(stageWeatherProvider(
      WeatherStageParams(trailId: trailId, stageNumber: stage.stageNumber),
    ));
    final forecast = weather.forecast;
    if (weather.isLoading && forecast == null) anyLoading = true;

    final dayForecast = forecast?.dayOn(date);
    final reach = reachForProgramDay(
      daysAhead: daysAhead,
      hasForecast: dayForecast != null,
    );

    result.add(ProgramDayWeather(
      dayNumber: planned.dayNumber,
      date: date,
      placeName: _placeNameOf(stage),
      stageNumber: stage.stageNumber,
      isRestDay: planned.isRestDay,
      reach: reach,
      day: dayForecast,
      fetchedAt: forecast?.fetchedAt,
    ));
  }

  return ProgramWeatherState(
    days: result,
    departureDate: departure,
    isLoading: anyLoading,
  );
});

/// Etape dont l'ARRIVEE termine la journee [planned].
///
/// La DERNIERE de la journee : une journee qui regroupe deux etapes se termine a
/// l'arrivee de la seconde, pas de la premiere. `null` pour un jour de repos ou
/// une journee sans etape.
StageModel? _arrivalStageOf(PlannedDay planned) =>
    planned.stages.isEmpty ? null : planned.stages.last;

/// Nom affichable du lieu d'arrivee.
///
/// `arrivalName` quand le sentier le fournit (champ riche du socle « donnees
/// externes »), sinon le nom de l'etape — jamais une chaine vide, et jamais une
/// localite en dur dans le moteur (genericite #84627).
String _placeNameOf(StageModel? stage) {
  if (stage == null) return '';
  final arrival = stage.arrivalName?.trim();
  if (arrival != null && arrival.isNotEmpty) return arrival;
  return stage.name;
}
