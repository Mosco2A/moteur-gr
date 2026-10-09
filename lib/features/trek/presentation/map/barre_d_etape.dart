/// LA BARRE DE CHIFFRES DU BAS DE LA CARTE, et son PERIMETRE (tache 747).
///
/// Sortie de `map_content.dart` a la tache 747 : ce fichier etait a 489 lignes
/// sur les 500 du plafond ECR-15, et la bascule de perimetre n'y tenait pas.
///
/// ---------------------------------------------------------------------------
/// LE DEFAUT QUE CE FICHIER CORRIGE, MESURE AVANT D'ETRE TOUCHE
/// ---------------------------------------------------------------------------
///
/// Capture de l'ecran de Christophe du 09/10 au matin : la barre affichait EN
/// MEME TEMPS « 9,9 km restants », « 86 % », Total 84,0 km et Parcouru
/// 63,0 km. Or 84 moins 63 font 21, pas 9,9. Les trois nombres ne peuvent pas
/// etre vrais ensemble — et pourtant chacun etait juste, SUR SON PROPRE TOTAL :
///
///   * `Parcouru`, `restants` et le pourcentage etaient mesures sur la TRACE
///     GPX du sentier, longue de 72,892 km : 63,0 + 9,9 = 72,9, et
///     63,0 / 72,892 = 86,4 % — le « 86 % » affiche ;
///   * `Total` venait de la FICHE du sentier (`trailConfig.totalDistanceKm`),
///     c'est-a-dire de la somme des sept etapes du programme : 84,0 km.
///
/// DEUX TOTAUX POUR UN SEUL SENTIER, mis cote a cote dans la meme barre. Et
/// AUCUNE des cinq cases n'etait au perimetre de l'etape, alors que la barre
/// porte un NOM D'ETAPE en titre — le retour de Christophe du 09/10 08:45,
/// mot pour mot : « 4/ on a les donnees de trek complete au lieu d'avoir les
/// donnees de l'etape ».
///
/// ---------------------------------------------------------------------------
/// CE QUI REMPLACE : UN SEUL TOTAL PAR PERIMETRE, UNE SEULE SOUSTRACTION
/// ---------------------------------------------------------------------------
///
/// Les cinq cases viennent desormais d'UN SEUL [ChiffresDuPerimetre]. Son
/// `restant` n'est pas mesure : c'est son total moins son parcouru. Il est donc
/// IMPOSSIBLE que la somme ne retombe pas sur le total, et le pourcentage est
/// le rapport de ces deux memes nombres.
///
/// LA BARRE PARLE GEOMETRIE, DANS SES DEUX ETATS. Le total du sentier est la
/// LONGUEUR DE LA TRACE, pas la somme de la fiche ; le total d'une etape est sa
/// TRANCHE de trace. C'est le seul choix qui rende les chiffres vrais : la
/// position du marcheur n'existe que sur la trace, donc tout ce qui se deduit
/// d'elle se compte sur la trace. Les distances de la FICHE restent ce
/// qu'elles sont — des donnees de programme — et continuent de s'afficher au
/// catalogue et sur la fiche d'etape, que ce lot ne touche pas.
///
/// CE QUE CA DECOUVRE, ET QUI EST UN DEFAUT DE DONNEES, PAS DE CODE : sur le
/// sentier de demonstration, la trace GPX ne compte que 53 points pour 72,892
/// km, la ou la fiche annonce 84,0 km — 11,1 km d'ecart — et les coordonnees
/// de bornage des etapes tombent loin de leur place reelle sur cette trace
/// grossiere (la tranche de l'etape 7 mesure 25,4 km quand sa fiche en annonce
/// 10,0). Les chiffres de la barre sont desormais COHERENTS ENTRE EUX ; ils ne
/// peuvent pas etre plus fideles que la trace qu'on leur donne a lire.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/engine/trail_engine.dart';
import '../../../../i18n/translations.g.dart';
import '../../../map/map_facade.dart'
    show
        ChiffresDuPerimetre,
        PerimetreDeLaBarre,
        StageProgressBar,
        etapesFaites,
        jalonALAbscisse,
        jalonsDesEtapesProvider,
        mapFocusStage,
        perimetreDeLaBarreProvider,
        reliefDeLEtapeProvider,
        trackPositionProvider;
import '../../../trail/trail_facade.dart'
    show currentStageNumberProvider, stagesProvider;
import '../../providers/derniers_chiffres_mesures.dart';
import '../../providers/live_trek_stats_provider.dart';
import '../../providers/tracking_providers.dart';

/// Barre d'etape active affichee en bas de la carte pendant un trek (PARITE
/// GR20 : bandeau de progression d'etape de la Navigation).
///
/// LES CINQ CASES ET LEUR SOURCE, APRES LA TACHE 747 — toutes les cinq
/// viennent du MEME [ChiffresDuPerimetre], donc du meme total :
///   1. le NOM DE L'ETAPE : l'abscisse du marcheur sur la trace, par
///      [jalonALAbscisse] — plus aucun detecteur geographique ;
///   2. « X km restants » : `restantM` ;
///   3. le POURCENTAGE : `ratio` ;
///   4. `Total` : `totalM` ;
///   5. `Parcouru` : `parcouruM`.
///
/// DEPUIS LA TACHE 762, LES SIX CASES SUIVENT LE PERIMETRE — pas seulement les
/// cinq de distance. La tache 747 avait laisse le denivele, la vitesse moyenne
/// et l'altitude au perimetre de la SESSION, dette assumee et ecrite ici meme ;
/// Christophe l'a tranchee le 09/10 a 16:29 et 16:32 :
///
///   * EN VUE ETAPE : Total, Parcouru et le POURCENTAGE de l'etape, la vitesse
///     moyenne de la session, le D+ et le D- DEJA MARCHES DANS L'ETAPE
///     ([reliefDeLEtapeProvider]), et l'altitude du moment ;
///   * EN VUE SENTIER ENTIER : Total du sentier, Parcouru depuis le depart, la
///     meme vitesse moyenne, le D+ et le D- CUMULES depuis le depart, et — a la
///     place de l'altitude, qui ne dit rien a cette echelle — LE NOMBRE
///     D'ETAPES FAITES SUR LE TOTAL, forme « 3 / 7 ».
///
/// AUCUN SECOND MOTEUR DE DENIVELE N'A ETE ECRIT, et c'est ce qui rendait la
/// dette tenable jusqu'ici. Le relief d'etape passe par [reliefDeLaTranche] :
/// le decoupage de `TrackSlice.between` suivi de la boucle de
/// `computeTrackStatsOn`, les deux deja en service depuis le lot 671-06. Meme
/// moteur, autres bornes — deux abscisses au lieu de deux releves projetes.
///
/// LA VITESSE MOYENNE, ELLE, NE SUIT PAS LE PERIMETRE, et c'est la demande
/// telle quelle : Christophe a qualifie le denivele d'« etape », pas la
/// vitesse. Une tranche de sentier n'a d'ailleurs pas d'horodatage, donc pas de
/// duree a diviser.
///
/// AVANT TOUTE MARCHE, ou sans projection : la barre passe la main a
/// [_PlannedStageBar] (LOT D, tache 554 : cette barre ne disparait plus
/// jamais). APRES UNE MARCHE elle garde ses chiffres, et la tache 762 dit
/// pourquoi — une session finalisee n'est pas une session jamais partie.
class ActiveStageBar extends ConsumerWidget {
  /// Cree la barre de chiffres du bas de la carte.
  const ActiveStageBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      trekSessionManagerProvider.select((s) => s.status),
    );
    final trekActive =
        status == TrackingSessionStatus.recording ||
        status == TrackingSessionStatus.paused;

    // LA MARCHE ACHEVEE GARDE SA BARRE, ET C'EST LE CORRECTIF DU RECUL
    // D'ETAPE (tache 762).
    //
    // MESURE DE LA RECETTE 753 : « a la fermeture [des felicitations] le
    // bandeau RETOMBE SUR L'ETAPE 1 avec 11,8 km restants et 0 pour cent ».
    // Le chemin exact : l'arrivee ouvre la porte du finisher, `stop()`
    // finalise, et `_finalize` pose un etat `stopped` SANS session. Cette
    // barre n'y voyait plus de trek actif et passait la main a la barre du
    // PROGRAMME, qui lit `currentStageNumberProvider` — la colonne
    // `currentStage` que PERSONNE n'ecrit (constat de la tache 747), donc
    // toujours 1. D'ou l'etape 1, les 11,8 km de la premiere etape, et 0 %.
    //
    // `stopped` N'EST PAS `idle`, ET TOUT EST LA. `idle` est l'etat d'avant
    // toute marche : la barre du programme y est la bonne reponse, et le lot D
    // l'exige. `stopped` est l'etat d'APRES une marche : il n'arrive qu'une
    // fois qu'une session a ete finalisee dans cette execution. Les deux
    // tombaient dans la meme branche ; ils sont desormais distingues.
    //
    // ET ELLE NE MONTRE RIEN QU'ELLE N'AIT : la projection sur la trace
    // survit a la fin de la session (elle ne depend que de la position
    // courante, pas du statut), donc l'abscisse de l'arrivee est encore la.
    // Sans projection, on retombe sur la barre du programme comme avant.
    final acheve = status == TrackingSessionStatus.stopped;
    if (!trekActive && !acheve) return const _PlannedStageBar();

    final trailId = ref.watch(trailConfigProvider.select((c) => c.id));
    final trackPos = ref.watch(trackPositionProvider);

    return trackPos.maybeWhen(
      data: (state) {
        final jalons = ref.watch(jalonsDesEtapesProvider(trailId));
        final abscisseM = state.distanceFromStartM;
        final jalon = jalonALAbscisse(jalons, abscisseM);

        // LE SENTIER ENTIER. Son total est la longueur de la TRACE, et elle est
        // deja dans l'etat : parcouru plus restant, par construction de la
        // projection. Aucune lecture de la fiche, donc aucun second total.
        final sentier = ChiffresDuPerimetre(
          totalM: state.distanceFromStartM + state.distanceRemainingM,
          parcouruM: state.distanceFromStartM,
        );

        // L'ETAPE EN COURS : sa tranche de trace. Sans jalon — aucune etape
        // chargee — il n'y a qu'un perimetre a montrer, celui du sentier.
        final etape = jalon == null
            ? sentier
            : ChiffresDuPerimetre.surLaTranche(
                debutM: jalon.debutM,
                finM: jalon.finM,
                abscisseM: abscisseM,
              );

        final perimetre = ref.watch(perimetreDeLaBarreProvider);
        final vueSentier =
            jalon == null || perimetre == PerimetreDeLaBarre.sentier;
        final chiffres = vueSentier ? sentier : etape;

        // LE TITRE SUIT LE PERIMETRE, et ce n'est pas cosmetique : afficher un
        // nom d'etape au-dessus des chiffres du sentier entier, c'est le
        // malentendu d'origine. En vue sentier, le titre est le SENTIER.
        final trailName = ref.watch(
          trailConfigProvider.select((c) => c.displayName),
        );
        final String titre;
        if (vueSentier) {
          titre = trailName;
        } else {
          final etapes = ref.watch(
            stagesProvider(trailId).select((async) => async.value),
          );
          final modele = (etapes ?? const [])
              .where((s) => s.stageNumber == jalon.numero)
              .firstOrNull;
          titre = modele?.name ?? t.a11y.stageMarker(number: jalon.numero);
        }

        // LES CHIFFRES MESURES DE LA MARCHE, et ils survivent a son dernier pas
        // (tache 762). Lus par [chiffresDeLaMarcheProvider], qui rend ceux de
        // la marche en cours ou, une fois la session finalisee, les derniers
        // qu'elle a reellement mesures. C'est ce qui empeche les trois chiffres
        // de relief de disparaitre a l'arrivee — releve de la recette 753.
        final mesures = ref.watch(chiffresDeLaMarcheProvider);
        final mesurable = mesures != null;

        // LE RELIEF SUIT LE PERIMETRE (tache 762), decision de Christophe du
        // 09/10 16:29. En vue SENTIER c'est le cumul depuis le depart — le
        // perimetre de [chiffresDeLaMarcheProvider], qui porte toute la
        // session. En vue ETAPE c'est la tranche deja marchee DANS l'etape,
        // par [reliefDeLEtapeProvider] : meme moteur de denivele, autres
        // bornes. Aucun second calcul n'est introduit (cf. lot 671-06).
        final relief = vueSentier ? mesures : ref.watch(reliefDeLEtapeProvider);

        // LES ETAPES FAITES REMPLACENT L'ALTITUDE EN VUE SENTIER (16:32, forme
        // « 3 / 7 »). Comptees sur l'ABSCISSE et non sur `completedStages` :
        // voir [etapesFaites], qui dit pourquoi.
        final faites = vueSentier && jalons.isNotEmpty
            ? etapesFaites(jalons, abscisseM)
            : null;

        return StageProgressBar(
          stageName: titre,
          distanceRemainingKm: chiffres.restantKm,
          progressRatio: chiffres.ratio,
          isOffTrack: state.isOffTrack,
          totalDistanceKm: chiffres.totalKm,
          distanceCoveredKm: chiffres.parcouruKm,
          elevationGainM: relief?.elevationGainM,
          elevationLossM: relief?.elevationLossM,
          // LA VITESSE MOYENNE RESTE CELLE DE LA SESSION DANS LES DEUX
          // PERIMETRES, et c'est ce que Christophe a demande : il a qualifie le
          // denivele d'« etape », pas la vitesse. Une tranche de sentier n'a
          // d'ailleurs pas d'horodatage, donc pas de duree a diviser.
          avgSpeedKmh: mesurable ? mesures.averageSpeedKmh : null,
          // L'ALTITUDE DU MOMENT NE SE MONTRE QU'EN VUE ETAPE : a l'echelle du
          // sentier entier elle ne dit rien du sentier, et le compte des etapes
          // prend sa place.
          altitudeM: vueSentier ? null : ref.watch(currentAltitudeProvider),
          etapesFaites: faites,
          etapesTotal: faites == null ? null : jalons.length,
          perimetreLabel: vueSentier
              ? t.map.perimetreSentier
              : t.map.perimetreEtape,
          // LE BOUTON PORTE LA DESTINATION, LA PASTILLE GARDE LE PERIMETRE
          // (tache 762, retour de Christophe du 09/10 16:27).
          basculeLabel: vueSentier
              ? t.map.basculerVersEtape
              : t.map.basculerVersSentier,
          vueSentier: vueSentier,
          // SANS ETAPE CONNUE, PAS DE BASCULE : il n'y aurait rien a basculer
          // vers, et un appui sans effet est un geste mort.
          onBasculer: jalon == null
              ? null
              : ref.read(perimetreDeLaBarreProvider.notifier).basculer,
        );
      },
      // En trek mais sans projection encore disponible (le fix GPS met une
      // seconde a arriver) : barre du PROGRAMME plutot qu'ecran nu.
      orElse: () => const _PlannedStageBar(),
    );
  }
}

/// Barre d'etape AVANT le depart (LOT D, tache 554) — l'etat garni qui
/// manquait.
///
/// CE QU'ELLE MONTRE : le nom de l'etape de depart, la tranche de trace qui
/// reste a marcher sur cette etape, la longueur de la trace du sentier, et un
/// TIRET sur ce qui exige la marche (parcouru, vitesse moyenne) — jamais un
/// zero, qui se lirait comme une mesure. L'altitude est REELLE des qu'un fix
/// existe (le marcheur est peut-etre deja au depart), un tiret sinon.
///
/// ELLE COMPTE SUR LA TRACE, COMME LA BARRE ACTIVE (tache 747). Elle lisait la
/// distance de la FICHE de l'etape et le total de la FICHE du sentier ; la
/// barre active, elle, mesure sur la trace. Le total sautait donc de 84,0 km a
/// 72,9 km au moment du depart, sous les yeux du randonneur. Les deux etats
/// lisent desormais la meme geometrie.
///
/// ELLE NE PRETEND PAS DIRE OU EST LE MARCHEUR : elle nomme l'etape courante
/// quand la base en connait une, et la PREMIERE sinon, parce que c'est le point
/// de depart connu du programme.
class _PlannedStageBar extends ConsumerWidget {
  const _PlannedStageBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trailId = ref.watch(trailConfigProvider.select((c) => c.id));
    final stages = ref.watch(
      stagesProvider(trailId).select((async) => async.value),
    );
    // ETAPE COURANTE SI LA BASE EN CONNAIT UNE, PREMIERE ETAPE SINON.
    final currentNumber = ref.watch(currentStageNumberProvider(trailId));
    final stage = mapFocusStage(stages, currentNumber);

    // Repli de titre : le nom du sentier. Toujours vrai, meme quand la base
    // n'a pas encore rendu les etapes.
    final String trailName = ref.watch(
      trailConfigProvider.select((c) => c.displayName),
    );

    // LA GEOMETRIE, PAS LA FICHE (747). Sans jalons — trace pas encore
    // chargee — les deux chiffres de distance restent nuls et la barre montre
    // ses tirets : on ne remplace jamais une mesure absente par celle de la
    // fiche, ce serait remettre deux totaux dans la meme barre.
    final jalons = ref.watch(jalonsDesEtapesProvider(trailId));
    final jalon = stage == null
        ? null
        : jalons.where((j) => j.numero == stage.stageNumber).firstOrNull;
    final longueurDuSentierM = jalons.isEmpty ? 0.0 : jalons.last.finM;

    return StageProgressBar(
      stageName: stage?.name ?? trailName,
      // « Restant » avant le depart = toute l'etape (rien n'est marche).
      distanceRemainingKm: (jalon?.longueurM ?? longueurDuSentierM) / 1000,
      progressRatio: 0,
      isOffTrack: false,
      totalDistanceKm: longueurDuSentierM > 0
          ? longueurDuSentierM / 1000
          : null,
      // Rien de marche : tiret, jamais « 0.0 km ».
      distanceCoveredKm: null,
      elevationGainM: stage?.elevationGainM,
      elevationLossM: stage?.elevationLossM,
      avgSpeedKmh: null,
      altitudeM: ref.watch(currentAltitudeProvider),
      showPendingValues: true,
      // LE MOT DU PERIMETRE EST LA DES AVANT LE DEPART : ces chiffres sont
      // ceux de l'etape de depart, et rien ne le disait.
      perimetreLabel: t.map.perimetreEtape,
      // PAS DE BASCULE AVANT LE DEPART : sans position, le sentier entier
      // n'aurait aucun parcouru a montrer — un appui ne changerait que le
      // titre.
    );
  }
}
