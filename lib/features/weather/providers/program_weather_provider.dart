import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/stage.dart';
import '../../notifications/providers/download_reminder_provider.dart';
import '../../planning/models/planned_day.dart';
import '../../planning/providers/planned_days_provider.dart';
import '../domain/forecast_reach.dart';
import '../models/weather_forecast.dart';
import '../presentation/weather_freshness.dart';
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
    this.produiteLe,
    this.porteeAnnoncee = forecastHorizonDays,
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

  /// INSTANT DE FABRICATION du bulletin d'ou vient [day] (lot 625).
  ///
  /// Plus l'instant du releve par le telephone : celui de la fabrication par le
  /// modele meteo, pose par le serveur. C'est la date que Christophe a demande de
  /// montrer, et la seule sur laquelle un age soit honnete.
  final DateTime? produiteLe;

  /// PORTEE REELLEMENT RECUE pour cette journee, en jours (lot 625).
  ///
  /// C'est le nombre de jours que le bulletin en main contient, et c'est CE
  /// NOMBRE que l'ecran annonce quand il dit « pas encore de prevision au-dela de
  /// N jours ». Annoncer la constante du code pendant que la decision est prise
  /// sur la donnee recue est exactement le genre d'ecart qui fait mentir un ecran
  /// sans que personne ne s'en apercoive — le defaut a ete attrape par le test
  /// U1-E de la tache 572, qui a survecu a ce lot pour cette raison.
  ///
  /// Vaut [forecastHorizonDays] quand aucun bulletin n'est en main : il n'y a rien
  /// a mesurer, seulement ce que le serveur est cense produire.
  final int porteeAnnoncee;

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

  /// FABRICATION LA PLUS RECENTE parmi les journees affichables — la fraicheur
  /// globale que l'ecran annonce en tete de section.
  DateTime? get fabricationLaPlusRecente {
    DateTime? latest;
    for (final d in days) {
      final f = d.produiteLe;
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
/// appel reseau, ET PLUS AUCUN COUT D APPEL A CHIFFRER (lot 625) : chaque journee
/// lit le bulletin de l'etape dont elle atteint l'arrivee, via
/// [stageWeatherProvider] — le meme que le HUB et l'ecran incendie — et ce bulletin
/// est une LIGNE DE BASE que notre serveur y a deposee. Le raisonnement de quota
/// qui tenait ici (600 appels/minute chez Open-Meteo, divises par le cache) n'a
/// plus d'objet : il n'y a plus d'appelant cote telephone. Deux journees qui
/// finissent au meme endroit, ou un jour de repos qui suit une etape, lisent la
/// meme ligne.
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

    // LA SORTIE ANTICIPEE « AU-DELA DE LA PORTEE » A ETE RETIREE (lot 625), ET SA
    // RAISON D'ETRE AVAIT DISPARU AVANT ELLE.
    //
    // Elle existait pour NE PAS EMETTRE D'APPEL inutile vers le fournisseur sur une
    // journee trop lointaine. Il n'y a plus d'appel : lire un bulletin est une
    // lecture de base. Ce qu'elle coutait, en revanche, etait bien reel — elle
    // tranchait « trop loin » sur la CONSTANTE du code, sans jamais regarder ce que
    // le serveur avait REELLEMENT envoye, et annoncait donc au randonneur une portee
    // qui n'etait pas celle de sa donnee. Defaut attrape par le test U1-E de la
    // tache 572, qui a survecu a ce lot pour cette raison exacte.
    //
    // Sans stage, en revanche, il n'y a aucun bulletin a consulter : la portee
    // attendue est alors tout ce dont on dispose, et on le dit sans pretendre
    // mesurer quoi que ce soit.
    if (stage == null) {
      result.add(ProgramDayWeather(
        dayNumber: planned.dayNumber,
        date: date,
        placeName: _placeNameOf(null),
        stageNumber: 0,
        isRestDay: planned.isRestDay,
        reach: forecastReachFor(daysAhead: daysAhead) ==
                ForecastReach.beyondHorizon
            ? ForecastReach.beyondHorizon
            : ForecastReach.noData,
      ));
      continue;
    }

    final weather = ref.watch(stageWeatherProvider(
      WeatherStageParams(trailId: trailId, stageNumber: stage.stageNumber),
    ));
    final forecast = weather.forecast;
    if (weather.isLoading && forecast == null) anyLoading = true;

    final dayForecast = forecast?.dayOn(date);

    // UN BULLETIN TROP VIEUX NE REND AUCUN CHIFFRE, Y COMPRIS ICI (#T8).
    //
    // C'EST LA MOITIE DE LA REGLE QU'IL SERAIT LE PLUS FACILE D'OUBLIER. L'ecran
    // meteo se tait au-dela de 72 h ; si cette liste continuait a afficher ses
    // temperatures, la regle ne servirait a rien — c'est meme LA section qui sert a
    // decider, celle qui nomme les lieux et les jours. Une regle de securite
    // appliquee a un seul des deux endroits qui montrent la meme donnee n'est pas
    // appliquee.
    final age = forecast?.ageAt(today);
    final tropVieux = age != null && age >= plusAucunChiffreApres;

    final reach = reachForProgramDay(
      daysAhead: daysAhead,
      hasForecast: dayForecast != null,
      porteeRecue: forecast?.days.length,
      bulletinTropVieux: tropVieux,
    );

    result.add(ProgramDayWeather(
      dayNumber: planned.dayNumber,
      date: date,
      placeName: _placeNameOf(stage),
      stageNumber: stage.stageNumber,
      isRestDay: planned.isRestDay,
      reach: reach,
      day: reach == ForecastReach.tropVieux ? null : dayForecast,
      produiteLe: forecast?.produiteLeLocal,
      porteeAnnoncee: forecast?.days.length ?? forecastHorizonDays,
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
