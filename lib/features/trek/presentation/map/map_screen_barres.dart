/// Les barres d etape du bas de la carte, le bouton photo et le
/// montage du pont d arrivee.
///
/// Morceau de `map_screen.dart` (lot 645-06, vague 2) : meme
/// bibliotheque, donc aucune visibilite, aucun identifiant et
/// aucun site d appel ne changent.
part of 'map_screen.dart';

/// Barre d'etape active affichee en bas de la carte pendant un trek (PARITE
/// GR20 : bandeau de progression d'etape de la Navigation).
///
/// N'est rendue que lorsqu'une session est `recording`/`paused` ET qu'une
/// projection sur le trace est disponible (etape detectee). Alimente
/// [StageProgressBar] avec : nom de l'etape courante (donnees du sentier),
/// distance restante, progression et etat hors-trace — le tout depuis
/// [trackPositionProvider] et [stagesProvider] (source unique projetee, aucune
/// donnee en dur, generique multi-sentiers). Hors trek ou sans fix GPS : rendu
/// nul (SizedBox.shrink), la carte reste degagee.
///
/// CORRECTIF L6-2 : la barre portait QUATRE informations la ou la navigation
/// de reference en affiche SIX sur deux lignes. Les manquantes — denivele,
/// vitesse moyenne, altitude, plus le couple total/parcouru — sont ajoutees
/// ici, MESUREES sur la trace de la session ([liveTrekStatsProvider]) et non
/// deduites d'une somme nominale d'etapes. Chaque valeur indisponible est
/// MASQUEE plutot qu'affichee a zero (meme regle que le correctif L5-6 : une
/// vitesse mesuree, ou rien).
///
/// LOT D (tache 554) — CETTE BARRE NE DISPARAIT PLUS JAMAIS. Elle se rendait en
/// `SizedBox.shrink()` hors trek et sans fix GPS : c'est EXACTEMENT l'ecran nu
/// que Chris a vu (« 14 navigation ne ressemble en rien a GR20 !!!!! »). La
/// navigation de reference, elle, affiche sa barre de chiffres EN PERMANENCE et
/// met un tiret dans les cases qu'elle ne sait pas encore remplir. Hors trek, la
/// barre passe donc la main a [_PlannedStageBar] au lieu de s'effacer.
class _ActiveStageBar extends ConsumerWidget {
  const _ActiveStageBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      trekSessionManagerProvider.select((s) => s.status),
    );
    final trekActive =
        status == TrackingSessionStatus.recording ||
        status == TrackingSessionStatus.paused;
    if (!trekActive) return const _PlannedStageBar();

    final trailId = ref.watch(trailConfigProvider.select((c) => c.id));
    final trackPos = ref.watch(trackPositionProvider);

    return trackPos.maybeWhen(
      data: (state) {
        final stages = ref.watch(
          stagesProvider(trailId).select((async) => async.value),
        );
        // Nom de l'etape courante detectee (fallback : libelle generique).
        final stageNumber = state.stageDetection.stageNumber;
        final stage = (stages ?? const [])
            .where((s) => s.stageNumber == stageNumber)
            .firstOrNull;
        final stageName =
            stage?.name ??
            (stageNumber > 0
                ? t.a11y.stageMarker(number: stageNumber)
                : t.map.title);

        // Chiffres mesures sur la trace de la session en cours (L6-2).
        // Tant que la trace n'a pas deux points, il n'y a rien de mesurable :
        // `hasData` est faux et toutes les valeurs restent masquees.
        final mesures = ref.watch(liveTrekStatsProvider).value;
        final mesurable = mesures != null && mesures.hasData;
        final totalKm = ref.watch(
          trailConfigProvider.select((c) => c.totalDistanceKm),
        );
        // Parcouru = distance PROJETEE sur le trace, la meme source unique que
        // le HUB, l'accueil et le widget — jamais le cumul GPS brut, qui
        // gonfle sur un aller-retour.
        final parcouruKm = ref.watch(stageDistanceCoveredProvider) / 1000.0;

        return StageProgressBar(
          stageName: stageName,
          distanceRemainingKm: state.distanceRemainingKm,
          progressRatio: state.progressRatio,
          isOffTrack: state.isOffTrack,
          totalDistanceKm: totalKm > 0 ? totalKm : null,
          distanceCoveredKm: parcouruKm,
          elevationGainM: mesurable ? mesures.elevationGainM : null,
          elevationLossM: mesurable ? mesures.elevationLossM : null,
          // `averageSpeedKmh` vaut deja null quand le chiffre n'aurait aucun
          // sens (duree nulle, vitesse non marchable) : on le laisse decider.
          avgSpeedKmh: mesurable ? mesures.averageSpeedKmh : null,
          altitudeM: ref.watch(currentAltitudeProvider),
        );
      },
      // En trek mais sans projection encore disponible (le fix GPS met une
      // seconde a arriver) : barre du PROGRAMME plutot qu'ecran nu.
      orElse: () => const _PlannedStageBar(),
    );
  }
}

/// Barre d'etape AVANT le depart (LOT D, tache 554) — l'etat garni qui manquait.
///
/// CE QU'ELLE MONTRE, ET POURQUOI CHAQUE CHIFFRE EST LEGITIME :
///  * le nom et les chiffres de la PREMIERE etape du programme — distance, D+,
///    D- : ce sont des donnees du sentier, connues sans le moindre GPS ;
///  * la distance totale du sentier, qui vient de la configuration ;
///  * un TIRET sur les trois chiffres qui exigent la marche (parcouru, vitesse
///    moyenne) — jamais un zero, qui se lirait comme une mesure ;
///  * l'altitude REELLE des qu'un fix existe (le marcheur est peut-etre deja au
///    depart), un tiret sinon.
///
/// CE QU'ELLE NE PRETEND PAS : elle ne dit pas ou se trouve le marcheur. Elle
/// nomme l'etape COURANTE quand la base en connait une (tache 558 : la colonne
/// `currentStage`, ecrite depuis toujours par le suivi de trek, est enfin LUE —
/// cf. [currentStageNumberProvider]), et la PREMIERE sinon, parce que c'est le
/// point de depart connu du programme. Des que la projection GPS repond,
/// l'etape DETECTEE prend le relais ([_ActiveStageBar]).
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
    final totalKm = ref.watch(
      trailConfigProvider.select((c) => c.totalDistanceKm),
    );

    // Repli de titre : le nom du sentier. Toujours vrai, meme quand la base
    // n'a pas encore rendu les etapes.
    final String trailName = ref.watch(
      trailConfigProvider.select((c) => c.displayName),
    );
    final String stageName = stage?.name ?? trailName;

    // « Restant » avant le depart = toute l'etape (rien n'est marche). Sans
    // etape connue, on retombe sur le sentier entier.
    final remainingKm = stage?.distanceKm ?? (totalKm > 0 ? totalKm : 0.0);

    return StageProgressBar(
      stageName: stageName,
      distanceRemainingKm: remainingKm,
      progressRatio: 0,
      isOffTrack: false,
      totalDistanceKm: totalKm > 0 ? totalKm : null,
      // Rien de marche : tiret, jamais « 0.0 km ».
      distanceCoveredKm: null,
      elevationGainM: stage?.elevationGainM,
      elevationLossM: stage?.elevationLossM,
      avgSpeedKmh: null,
      altitudeM: ref.watch(currentAltitudeProvider),
      showPendingValues: true,
      // LE LAIUS SUR LES TIRETS EST SUPPRIME (tache 558). Retour de Chris, mot
      // pour mot : « enleve dans randonnee le laius sur les tiret ». La phrase
      // `map.statsPendingNote` expliquait pourquoi certaines cases portent un
      // tiret — elle part AVEC SA CLE dans les cinq langues. Un tiret se
      // comprend seul, et la navigation de reference n'explique pas les siens.
      // L'acquis du lot 554 reste entier : les six cases sont toujours la, avec
      // un tiret et jamais un zero sur ce qui exige la marche.
    );
  }
}

/// Bouton PHOTO de la carte -> journal du jour (LOT D, manque reel n°1).
///
/// LA REFERENCE L'A SUR SA CARTE (`_takePhoto`), STEPWAYS NE L'AVAIT NULLE PART :
/// zero occurrence de `photo_camera` dans `lib/features/trek/` et
/// `lib/features/map/`. Le marcheur devait quitter la navigation, ouvrir le
/// journal, creer une note, choisir la galerie… pour garder une image du col.
///
/// DEUX REGLES MAISON RESPECTEES, ET ELLES COMPTENT :
///  1. LE VERROU DU JOURNAL TIENT (decision Chris du 02/09, memoire #99410) :
///     le journal fait partie du pack. Sans achat, ce bouton n'ecrit RIEN — il
///     ouvre la vitrine ([acheterSentier]). On ne remplit pas un carnet
///     verrouille, et on ne masque pas la fonction pour autant : le marcheur
///     voit ce qu'il gagne en achetant.
///  2. L'ERREUR EST DITE, jamais avalee : quota du jour atteint, photo trop
///     lourde, disque en echec -> message traduit ([PhotoError]), la meme
///     table de libelles que le journal.
class _MapPhotoButton extends ConsumerStatefulWidget {
  const _MapPhotoButton();

  @override
  ConsumerState<_MapPhotoButton> createState() => _MapPhotoButtonState();
}

class _MapPhotoButtonState extends ConsumerState<_MapPhotoButton> {
  /// Vrai pendant la prise et l'enregistrement : le bouton ne se redeclenche
  /// pas (un double tap en marchant est la norme, pas l'exception).
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final trailId = ref.watch(trailConfigProvider.select((c) => c.id));
    // Le droit d'acces est OBSERVE ici, pas seulement lu au moment du tap : un
    // `ref.read` sur un provider jamais observe declenche son chargement et
    // rend `AsyncLoading` -> un payeur se serait vu proposer la vitrine au
    // premier appui. En l'observant, il est resolu avant que le doigt arrive.
    ref.watch(isDemoModeProvider(trailId));
    return FloatingActionButton.small(
      heroTag: 'mapTakePhoto',
      tooltip: t.journal.addPhoto,
      onPressed: _busy ? null : () => _onPressed(trailId),
      child: _busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const StepIcon(StepwaysIcons.photo),
    );
  }

  Future<void> _onPressed(String trailId) async {
    // Acces au journal = SOURCE UNIQUE [isDemoModeProvider] (correctif L7-3).
    // FAIL-CLOSED : tant que le droit est indetermine ou en erreur, on n'ecrit
    // pas — on propose l'achat, exactement comme l'ecran du journal.
    final acces = ref.read(isDemoModeProvider(trailId));
    final verrouille = acces.value ?? true;
    if (verrouille) {
      if (!mounted) return;
      await acheterSentier(context, ref, trailId: trailId);
      return;
    }

    // Capture AVANT tout await : la feuille systeme de l'appareil photo peut
    // demonter ce contexte, il ne doit pas servir a afficher le message.
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _busy = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        // Memes bornes que le dialogue du journal : la compression finale
        // reste l'affaire de PhotoService (500 Ko max).
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked == null) return;

      final error = await ref
          .read(journalScreenProvider.notifier)
          .addPhotoNote(
            stageNumber: _currentStageNumber(),
            content: '',
            sourcePath: picked.path,
          );

      if (error != null) {
        messenger.showSnackBar(
          SnackBar(content: Text(_photoErrorLabel(error))),
        );
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const StepIcon(StepwaysIcons.cocheCercle, size: 18),
              const SizedBox(width: AppTheme.spacingSm),
              // CONFIRMATION DEDIEE (branchee tache 557) : le message lisait
              // `t.journal.entriesOfDay` — « Entrees du jour », un TITRE de
              // section du journal. Il servait de confirmation faute de mieux,
              // et ne disait pas ce qui venait de se passer.
              // `t.journal.photoAdded` (tache 552, cinq langues) le dit :
              // « Photo ajoutee au journal ».
              Expanded(child: Text(t.journal.photoAdded)),
            ],
          ),
          action: SnackBarAction(
            label: t.nav.journal,
            // Resolution du routeur DIFFEREE au tap : la carte est alors
            // encore montee (le message s'efface avec elle), et un harnais de
            // test sans routeur ne paye pas ce branchement.
            onPressed: () {
              if (mounted) context.push('/journal');
            },
          ),
        ),
      );
    } catch (_) {
      // Appareil photo indisponible / permission refusee : on le DIT.
      messenger.showSnackBar(SnackBar(content: Text(t.journal.photoError)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Etape a laquelle rattacher la photo : l'etape DETECTEE si la projection
  /// repond, sinon la premiere du programme (plancher a 1 — une entree de
  /// journal doit porter un numero d'etape valide).
  int _currentStageNumber() {
    final detected = ref
        .read(trackPositionProvider)
        .whenOrNull(data: (s) => s.stageDetection.stageNumber);
    if (detected != null && detected > 0) return detected;
    return 1;
  }

  /// Libelle Slang d'un echec d'ajout de photo (meme table que le journal).
  String _photoErrorLabel(PhotoError error) {
    switch (error) {
      case PhotoError.dailyLimitReached:
        return t.journal.photoLimit;
      case PhotoError.tooLarge:
        return t.journal.photoTooBig;
      case PhotoError.fileNotFound:
      case PhotoError.ioError:
        return t.journal.photoError;
    }
  }
}

/// Monte le pipeline « detection d'etape -> arrivee -> complétion/finisher »
/// tant qu'un trek est en cours (PARITE GR20, LOT 2, #99433).
///
/// Au LOT 1, [arrivalCompletionListenerProvider] et [currentStageIdProvider]
/// n'etaient observes par AUCUN ecran : la chaine terrain etait INERTE (aucune
/// arrivee detectee, finisher jamais declenche). Cet element, monte dans l'ecran
/// carte (terrain actif), les rend vivants — mais UNIQUEMENT quand une session
/// est `recording`/`paused`, pour ne pas ouvrir le flux GPS hors trek (et rester
/// neutre dans les tests d'ecran a l'arret). Ne rend rien a l'ecran.
class _ArrivalPipelineMount extends ConsumerWidget {
  const _ArrivalPipelineMount();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      trekSessionManagerProvider.select((s) => s.status),
    );
    final trekActive =
        status == TrackingSessionStatus.recording ||
        status == TrackingSessionStatus.paused;

    if (trekActive) {
      // Rend le pont d'arrivee -> etapes completees -> porte du finisher ACTIF
      // (il s'auto-abonne a arrivalEventsProvider). Sans achat cote vitrine, le
      // GPS est jouable (2.A) : le cycle complet peut donc se derouler.
      ref.watch(arrivalCompletionListenerProvider);
      // Alimente aussi la detection d'etape courante pendant la nav (parite
      // GR20) : etape affichee coherente avec la position.
      // L3-1 : l'etape detectee est notee au gestionnaire de session, qui
      // l'inscrit sur chaque point de trace — c'est ce qui permet de rendre
      // le trace ETAPE PAR ETAPE dans le recap.
      final stageId = ref.watch(currentStageIdProvider).value;
      ref.read(trekSessionManagerProvider.notifier).noteCurrentStage(stageId);
    }

    return const SizedBox.shrink();
  }
}
