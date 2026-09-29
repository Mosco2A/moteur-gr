import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_header.dart';
import '../../tips/domain/models/tip_card.dart';
import '../data/weather_repository.dart' show IssueMiseAJourMeteo;
import '../models/fire_risk_config.dart';
import '../models/weather_alert.dart';
import '../models/weather_forecast.dart';
import '../providers/program_weather_provider.dart';
import '../providers/weather_providers.dart';
import '../widgets/all_stages_weather_list.dart';
import '../widgets/compact_forecast_row.dart';
import '../widgets/program_weather_list.dart';
import '../widgets/today_stage_weather_card.dart';
import '../widgets/weather_alert_banner.dart';
import '../widgets/weather_guide_sheet.dart';
import '../widgets/weather_source_banner.dart';
import 'weather_freshness.dart';

/// Écran météo d'une étape (E31, LOT-B — périmètre dégradé).
///
/// Lit le bulletin que NOTRE SERVEUR a fabriqué et déposé, via
/// [stageWeatherProvider] — aucun appel à un fournisseur de météo (lot 625). Expose
/// l'UX de référence : carte du jour + reco (RF-4), prévisions J+1/J+2 (RF-5),
/// « toutes les étapes » (RF-6), bandeau source + DATE DE FABRICATION (RF-3),
/// toggle alertes orage + guide (RF-1), tirer-pour-rafraîchir (RF-7). Tous les
/// libellés passent par Slang (cloisonnement, aucun libellé GR20).
///
/// LES DEUX ÉTATS QUI COMPTENT LE PLUS SONT CEUX OÙ IL N'AFFICHE AUCUN CHIFFRE :
/// le randonneur qui n'a jamais eu de réseau depuis l'installation, et celui dont le
/// dernier bulletin a plus de trois jours. Ni l'un ni l'autre ne doit voir un écran
/// vide, et aucun des deux ne doit voir de prévision inventée.
class WeatherScreen extends ConsumerWidget {
  const WeatherScreen({
    super.key,
    required this.trailId,
    required this.stageNumber,
    this.region = '',
    this.fireRiskConfig = const FireRiskConfig(),
    this.fireTipCard,
  });

  final String trailId;
  final int stageNumber;

  /// Région géographique du sentier pour l'évaluation du risque incendie.
  /// Vide par défaut (config incendie inerte tant que le socle E00 ne
  /// l'alimente pas — dégradation propre, sans alerte).
  final String region;

  /// Config paramétrable du risque incendie (seuils, mois, régions).
  final FireRiskConfig fireRiskConfig;

  /// Fiche conseil incendie pour le CTA (null = pas de CTA).
  final TipCard? fireTipCard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final params = WeatherStageParams(
      trailId: trailId,
      stageNumber: stageNumber,
    );
    final weather = ref.watch(stageWeatherProvider(params));
    final stormAlertsEnabled = ref.watch(stormAlertsEnabledProvider);

    return Scaffold(
      // Ph5 (L6c) : AppHeader universel + actions conservees (guide / alertes
      // orage / rafraichir) — parite ecran, aucune action perdue.
      appBar: AppHeader(
        title: t.weather.title,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: t.weather.guideTitle,
            onPressed: () => WeatherGuideSheet.show(context),
          ),
          IconButton(
            icon: Icon(stormAlertsEnabled
                ? Icons.thunderstorm
                : Icons.thunderstorm_outlined),
            tooltip: stormAlertsEnabled
                ? t.weather.stormAlertsToggleOn
                : t.weather.stormAlertsToggleOff,
            onPressed: () => ref
                .read(stormAlertsEnabledProvider.notifier)
                .state = !stormAlertsEnabled,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: t.weather.refresh,
            onPressed: () => _refresh(context, ref, params),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(context, ref, params, silent: true),
        child: _buildBody(context, ref, theme, weather, t, stormAlertsEnabled),
      ),
    );
  }

  /// DEMANDE UNE PASSE DE SYNCHRONISATION, ET RELIT TOUT L'ECRAN.
  ///
  /// TACHE 572 (U2), tenue : le bouton rafraichit ce qu'il AFFICHE, et le resultat
  /// est ANNONCE. Ce qui change au lot 625, c'est la nature du travail — une passe
  /// pour tout le sentier au lieu d'un appel par etape — et le vocabulaire du
  /// resultat : recu / deja a jour / hors ligne / echec. « Partiel » a disparu
  /// parce qu'il n'est plus atteignable.
  Future<void> _refresh(
    BuildContext context,
    WidgetRef ref,
    WeatherStageParams params, {
    bool silent = false,
  }) async {
    final t = Translations.of(context);
    final messenger = silent ? null : ScaffoldMessenger.of(context);

    // UNE SEULE PASSE, PLUS UNE PASSE PAR ETAPE (lot 625).
    //
    // L ancienne version lancait un appel Open-Meteo par etape du programme, en
    // parallele, et comptait les reussites pour annoncer un succes « partiel ». Ce
    // decompte n a plus d objet : la passe de synchronisation descend le fichier de
    // donnees du sentier, donc TOUTES les etapes a la fois, dans UNE transaction.
    // Une mise a jour partielle de la meteo d un sentier n existe plus — la copie
    // atomique l interdit (#C1 de la spec 605).
    //
    // Les autres etapes n ont donc rien a demander ; il leur suffit de RELIRE ce
    // que la passe a pose.
    final abouti = await ref
        .read(stageWeatherProvider(params).notifier)
        .refresh();

    final autresEtapes = <int>{};
    for (final day in ref.read(programWeatherProvider(trailId)).days) {
      if (day.stageNumber > 0 && day.stageNumber != params.stageNumber) {
        autresEtapes.add(day.stageNumber);
      }
    }
    for (final n in autresEtapes) {
      ref.invalidate(stageWeatherProvider(
        WeatherStageParams(trailId: trailId, stageNumber: n),
      ));
    }

    if (messenger == null || !context.mounted) return;

    final etat = ref.read(stageWeatherProvider(params));
    final produiteLe = etat.forecast?.produiteLeLocal;

    // TROIS MESSAGES DISTINCTS, PARCE QU IL Y A TROIS SITUATIONS DIFFERENTES.
    // « Rien de plus recent » est le cas le PLUS FREQUENT d une cadence de quatre
    // heures, et l annoncer comme un echec apprendrait au randonneur a ignorer le
    // message — ce qui est exactement la faute que la tache 572 a corrigee dans
    // l autre sens.
    final message = switch (etat.derniereIssue) {
      IssueMiseAJourMeteo.recue => t.weather.refreshedAt(
          date: produiteLe == null ? '-' : formatFetchedAt(produiteLe),
        ),
      IssueMiseAJourMeteo.rienDePlusRecent => t.weather.refreshUpToDate,
      IssueMiseAJourMeteo.horsLigne => t.weather.refreshOffline,
      IssueMiseAJourMeteo.echec => produiteLe == null
          ? t.weather.refreshFailedNoData
          : t.weather.refreshFailed(date: formatFetchedAt(produiteLe)),
      null => abouti ? t.weather.refreshUpToDate : t.weather.error,
    };
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    WeatherState weather,
    Translations t,
    bool stormAlertsEnabled,
  ) {
    // LA ROUE PLEIN ECRAN EST RESERVEE A LA TOUTE PREMIERE LECTURE (lot 625).
    //
    // Elle s affichait des que `isLoading` montait, donc AUSSI pendant un
    // rafraichissement. Consequence sur l ecran sans bulletin : appuyer sur
    // « Actualiser » effacait l explication que le randonneur etait en train de
    // lire, la remplacait par une roue, puis la remettait. Il perdait le seul
    // texte utile de l ecran au moment ou il agissait.
    //
    // `jamaisRecue` DIT QUE LA LECTURE A DEJA REPONDU — « il n y a rien » est une
    // reponse. On garde donc l ecran d explication, et le resultat de la tentative
    // vient s y ajouter au lieu de s y substituer.
    if (weather.isLoading && weather.forecast == null && !weather.jamaisRecue) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(
            child: Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: AppTheme.spacingBase),
                Text(t.weather.loading, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      );
    }

    // LE REPLI DEMO EST SUPPRIME, ET C EST UNE CORRECTION DE FOND (lot 625).
    //
    // DEFAUT MESURE, PAS SUPPOSE. Quand ni le reseau ni le cache ne repondaient,
    // l ecran fabriquait une prevision FICTIVE (`WeatherSeed.forCoords`, 12 a 25 °C,
    // codes WMO cycliques) et la badgeait « donnees de demonstration » — sur un
    // sentier REEL, au randonneur qui vient de l installer et qui n a jamais eu de
    // reseau. Un badge discret contre sept cartes de chiffres credibles : c est le
    // « defaut vert » que la conception 611 nomme un mensonge confortable (#I21), et
    // c est precisement le cas que Christophe demande de rendre PROPRE.
    //
    // Ce qu on affiche a la place dit la verite et dit la SUITE : le serveur
    // fabrique la meteo, elle arrivera avec les donnees du sentier, il n y a rien a
    // demander.
    final WeatherForecast? forecast = weather.forecast;

    if (forecast == null) {
      return ListView(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        children: [
          const SizedBox(height: 80),
          _EcranSansBulletin(
            titre: t.weather.neverReceived.title,
            corps: t.weather.neverReceived.body,
            icone: Icons.cloud_queue,
            // CE QUE LA DERNIERE TENTATIVE A DONNE, ECRIT A L ECRAN ET PAS
            // SEULEMENT DANS UN MESSAGE FUGACE.
            //
            // DEFAUT MESURE PAR LA GARDE ANTI-GESTE-MORT (tache 573), PAS SUPPOSE :
            // sur cet ecran-la, « Actualiser » n avait pour seule trace qu un
            // bandeau temporaire. Un randonneur hors reseau appuyait, le message
            // passait, et l ecran redevenait identique — il ne pouvait pas savoir
            // si son geste avait fait quelque chose. La reponse doit RESTER, parce
            // que c est justement l ecran ou il n y a rien d autre a lire.
            // L ATTENTE EST DITE EN TEXTE, PAS EN ROUE QUI TOURNE. Deux raisons,
            // et la seconde est mesurable : une roue sur cet ecran remplacerait
            // l explication que le randonneur est en train de lire ; et une
            // animation perpetuelle rend l ecran impossible a stabiliser en test,
            // donc impossible a verifier. Le geste doit se VOIR des l appui — sur
            // un ecran sans chiffres, c est la seule preuve que le bouton a pris.
            note: weather.isLoading
                ? t.weather.loading
                : switch (weather.derniereIssue) {
                    IssueMiseAJourMeteo.horsLigne => t.weather.refreshOffline,
                    IssueMiseAJourMeteo.echec => t.weather.refreshFailedNoData,
                    IssueMiseAJourMeteo.rienDePlusRecent =>
                      t.weather.refreshUpToDate,
                    _ => null,
                  },
          ),
        ],
      );
    }

    // L AGE COMMANDE CE QUI PEUT S AFFICHER. Une seule lecture, partagee par le
    // bandeau, la carte du jour, les jours suivants et la liste du programme :
    // quatre endroits qui decideraient chacun a partir de quand ils se taisent ne se
    // tairaient pas au meme moment.
    final fraicheur = weatherFreshness(
      produiteLe: forecast.produiteLeLocal,
      t: t,
    );

    // PLUS AUCUN CHIFFRE AU-DELA DE 72 HEURES (#T8 de la conception 611).
    //
    // C EST LE POINT LE PLUS IMPORTANT DU LOT, et c est la phrase de Christophe :
    // une meteo de trois jours presentee comme fraiche a quelqu un qui decide de
    // passer un col est dangereuse. Griser ne suffit pas a cet age-la : un grise
    // permanent devient une decoration qu on ne lit plus. On retire les chiffres, et
    // on dit depuis quand on ne sait plus.
    if (fraicheur.plusAucunChiffre) {
      return ListView(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        children: [
          WeatherSourceBanner(
            source: WeatherSource.server,
            fraicheur: fraicheur.label,
          ),
          const SizedBox(height: AppTheme.spacingBase),
          _EcranSansBulletin(
            titre: t.weather.expiredNotice.title,
            corps: t.weather.expiredNotice.body(
              days: plusAucunChiffreApres.inDays,
            ),
            icone: Icons.history_toggle_off,
          ),
          const SizedBox(height: AppTheme.spacingBase),
          // LA LISTE DU PROGRAMME RESTE, ET ELLE SE TAIT AUSSI. Elle nomme les
          // lieux et les dates — qui ne perimment pas — et dit, pour chaque
          // journee, que le bulletin est trop ancien. Retirer la section entiere
          // ferait disparaitre une information juste (ou le randonneur dort) avec
          // une information perimee.
          ProgramWeatherList(trailId: trailId),
        ],
      );
    }

    final source = forecast.produiteLe == null
        ? WeatherSource.demo
        : WeatherSource.server;
    final days = forecast.days;
    final today = days.isNotEmpty ? days.first : null;
    final upcoming = days.length > 1 ? days.sublist(1) : const <DayForecast>[];

    // Alertes météo + incendie, filtrées par le toggle orage (RF-1).
    final fireAlerts = WeatherAlert.fireAlertsFromForecast(
      forecast,
      fireConfig: fireRiskConfig,
      region: region,
    );
    final allAlerts = [...weather.alerts, ...fireAlerts].where((a) {
      if (!stormAlertsEnabled && a.kind == WeatherAlertKind.storm) return false;
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      children: [
        // LA DATE AFFICHEE EST CELLE DE FABRICATION PAR LE MODELE (lot 625), pas
        // celle du telechargement — demande explicite de Christophe. Et l AGE est
        // dans la meme ligne, toujours : hors ligne comme en ligne, le randonneur
        // voit de quand date ce qu il lit.
        WeatherSourceBanner(source: source, fraicheur: fraicheur.label),
        const SizedBox(height: AppTheme.spacingSm),

        // TACHE 572 (U2) : un rafraichissement RATE se voit. Avant, l'echec
        // etait ecrit dans `WeatherState.errorMessage` et lu par personne. On
        // regarde les DEUX signaux : aucun echec present dans l'etat ne doit
        // pouvoir rester muet, quelle que soit la branche qui l'a pose.
        if (weather.refreshFailed || weather.errorMessage != null) ...[
          _RefreshFailedBanner(produiteLe: forecast.produiteLeLocal),
          const SizedBox(height: AppTheme.spacingSm),
        ],

        if (allAlerts.isNotEmpty) ...[
          WeatherAlertBanner(alerts: allAlerts, fireTipCard: fireTipCard),
          const SizedBox(height: AppTheme.spacingBase),
        ],

        // « Meteo = ici et maintenant, ok » (Chris) : la carte du jour au point
        // ou on se trouve reste en tete, elle sert a s'habiller le matin.
        //
        // ELLE SE GRISE DES SIX HEURES, PAS DES SOIXANTE-DOUZE. La peremption du
        // JOUR COURANT est plus courte que celle des jours suivants (#T8) : le temps
        // de cet apres-midi vieillit plus vite qu une tendance a J+2, et six heures
        // est en dessous de la cadence de collecte du serveur — donc un bulletin
        // plus vieux signifie qu au moins une collecte n est pas arrivee ici.
        if (today != null) ...[
          TodayStageWeatherCard(
            day: today,
            perime: fraicheur.jourCourantGrise,
          ),
          const SizedBox(height: AppTheme.spacingBase),
        ],
        if (upcoming.isNotEmpty) ...[
          CompactForecastRow(
            days: upcoming,
            perime: fraicheur.joursSuivantsGrises,
          ),
          const SizedBox(height: AppTheme.spacingBase),
        ],

        // ... « mais indiquer le lieu des etapes et la meteo des etapes, pas
        // celle du jour ». C'est CETTE section qui sert a decider : une journee
        // de programme par ligne, son lieu d'arrivee NOMME, sa date, son temps.
        // Elle remplace l'ancienne liste « jour par jour » du bulletin d'un seul
        // point, qui melangeait les index d'API et les journees de marche.
        ProgramWeatherList(trailId: trailId),
        const SizedBox(height: AppTheme.spacingLg),

        AllStagesWeatherList(trailId: trailId),
        const SizedBox(height: AppTheme.spacingLg),
      ],
    );
  }

}

/// CE QU ON MONTRE QUAND ON NE MONTRE PAS DE CHIFFRES.
///
/// Deux cas l utilisent, et aucun des deux n est un ecran vide : le randonneur qui
/// n a JAMAIS eu de reseau depuis l installation, et celui dont le dernier bulletin
/// a plus de trois jours. Dans les deux cas il faut dire la meme chose sous deux
/// formes : ou en est-on, et ce qui va se passer.
class _EcranSansBulletin extends StatelessWidget {
  const _EcranSansBulletin({
    required this.titre,
    required this.corps,
    required this.icone,
    this.note,
  });

  final String titre;
  final String corps;
  final IconData icone;

  /// Resultat DURABLE de la derniere tentative de mise a jour. `null` si aucune.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icone, size: 56, color: theme.colorScheme.onSurface.withAlpha(120)),
        const SizedBox(height: AppTheme.spacingBase),
        Text(
          titre,
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          corps,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(180),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        if (note != null) ...[
          const SizedBox(height: AppTheme.spacingBase),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.orangeDifficile.withAlpha(15),
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(color: AppTheme.orangeDifficile.withAlpha(60)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.sync_problem,
                    size: 18, color: AppTheme.orangeDifficile),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    note!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.orangeDifficile,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Bandeau « la mise a jour n'a pas abouti » (tache 572, U2).
///
/// Un bouton qui echoue en silence est pire qu'un bouton absent : le randonneur
/// croit disposer d'une donnee fraiche. Le bandeau dit l'echec ET l'age de ce qui
/// reste affiche, pour qu'il sache sur quoi il decide.
class _RefreshFailedBanner extends StatelessWidget {
  const _RefreshFailedBanner({required this.produiteLe});

  final DateTime? produiteLe;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    const color = AppTheme.orangeDifficile;
    final message = produiteLe == null
        ? t.weather.refreshFailedNoData
        : t.weather.refreshFailed(date: formatFetchedAt(produiteLe!));

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.sync_problem, size: 18, color: color),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: color, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
