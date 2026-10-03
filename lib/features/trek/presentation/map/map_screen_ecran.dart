/// L ecran carte : sa garde de sentier et son echafaudage.
///
/// Morceau de `map_screen.dart` (lot 645-06, vague 2) : meme
/// bibliotheque, donc aucune visibilite, aucun identifiant et
/// aucun site d appel ne changent.
part of 'map_screen.dart';

/// Ecran carte orchestrateur -- FlutterMap v8 + tous layers assembles.
///
/// PARITE GR20 (#99460, ecran Navigation terrain) : l'onglet Carte de StepWays
/// reprend, hors peau, tout ce que la Navigation GR20 affiche —
///   * fond OSM + trace de reference + position GPS (socle E2.3f) ;
///   * couche POI + bouton Calques (toggle par type, reutilise [PoiFilterBar]) ;
///   * bouton SOS (reutilise [SosButton], visible pendant un trek) ;
///   * banniere hors-trace VISIBLE (reutilise [OffTrackBanner]) ;
///   * barre d'etape active (reutilise [StageProgressBar]) pendant un trek.
/// Generique multi-sentiers (donnees du sentier courant, zero hardcode), i18n
/// Slang, a11y (SOS + calques labellises).
///
/// Structure : Scaffold > Stack > FlutterMap(TileLayer, TraceLayer,
/// TrailMarkersLayer, UserPositionLayer) + overlays (barre d'etape, controles,
/// SOS, calques, banniere hors-trace). Les etapes et les points d'interet
/// partagent UNE couche depuis la tache 571 : deux couches empilees ne peuvent
/// pas s'entendre sur un repere commun quand elles designent le meme lieu.
/// ZERO ref.watch() dans build() -- chaque donnee passe par Consumer
/// avec select() pour un rebuild minimal et chirurgical.
///
/// CARTE TERRAIN — PLUS AUCUNE BARRE DU BAS (correctif L6-3, 21/09/2026).
///
/// L'ecran portait une barre contextuelle heritee du LOT 3 (« Étape en cours »
/// / « Journal »). La navigation de reference n'a AUCUNE barre du bas sur sa
/// carte — sa seule definition de barre est un theme jamais consomme. Sur un
/// ecran de terrain, cette barre prenait de la hauteur utile a la carte et
/// proposait deux navigations deja accessibles depuis le cockpit, ou l'on
/// revient par le bouton retour. Elle est donc RETIREE.
///
/// NUANCE EXPLICITE, pour qu'elle ne soit pas « corrigee » par erreur plus
/// tard : l'accueil maison (`my_treks_screen.dart`) GARDE sa barre. C'est un
/// ecran multi-sentiers qui n'existe pas dans la reference — la comparaison ne
/// tient pas pour lui. Seule la barre de la CARTE etait un vrai ecart.
///
/// LOT D (tache 554) — « 14 navigation ne ressemble en rien a GR20 !!!!! »,
/// retour de Chris mot pour mot. Trois choses changent ici, et une seule etait
/// un vrai manque de fonction :
///
///  1. PLUS JAMAIS D'ECRAN NU. La barre d'etape ne se rendait QUE pendant un
///     trek avec fix GPS : un utilisateur neuf n'avait qu'une carte et des
///     boutons. Elle se rend desormais TOUJOURS — en trek avec les chiffres
///     mesures, avant le depart avec les chiffres DU PROGRAMME (distance de
///     l'etape, D+, D-) et un tiret sur ce qui demande le GPS. Cf.
///     [_PlannedStageBar].
///  2. LE BOUTON PHOTO VERS LE JOURNAL DU JOUR, present sur la carte de
///     reference (`_takePhoto`), qui n'existait nulle part cote StepWays. Cf.
///     [_MapPhotoButton] — et il respecte le verrou du journal (#99410) : sans
///     achat, il ouvre la vitrine au lieu d'ecrire.
///  3. LE GUIDE DES ICONES (reference l.1087-1284) : action (i) de l'en-tete,
///     cf. [showMapGuideSheet] ; et la LISTE DES POINTS DE L'ETAPE qu'on coche
///     au passage, ajoutee au panneau Calques (cf. [StagePoiChecklist]) — le
///     panneau ne savait qu'afficher et masquer des couches, ce qui est une
///     autre fonction.
///
/// SOS — ACCES UNIQUE ALIGNE GR20 (decision Chris 12/09, cycle 3) : le SOS n'a
/// qu'UN SEUL point d'entree — le bouton flottant en overlay (colonne bas-gauche,
/// [SosButton], visible en trek actif). C'est EXACTEMENT le placement GR20
/// (`SosFloatingButton` positionne dans le Stack, bas-gauche ; GR20 n'a AUCUNE
/// barre contextuelle ni SOS en barre). Le retrait de la barre rend ce point
/// definitif : il n'existe plus de barre ou un second SOS pourrait reapparaitre.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key, required this.trailId});

  /// Identifiant du sentier a afficher sur la carte.
  final String trailId;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  @override
  Widget build(BuildContext context) {
    final trailId = widget.trailId;
    return Scaffold(
      // AUCUN bottomNavigationBar (correctif L6-3) : la carte occupe toute la
      // hauteur, comme sur la navigation de reference.
      appBar: AppBar(
        title: Consumer(
          builder: (context, ref, _) {
            final name = ref.watch(
              trailConfigProvider.select((c) => c.displayName),
            );
            return Text(name);
          },
        ),
        // Fix retour (#99460) : l'onglet Carte est la RACINE d'une branche du
        // shell (StatefulShellRoute). Y appeler `Navigator.pop()` viderait une
        // pile vide -> bouton mort / exception. On ne pope que s'il y a
        // reellement une page a depiler (cas ou la carte est atteinte via un
        // `push` hors-shell) ; sinon on revient a l'accueil (comportement
        // attendu depuis le HUB, aligne sur le correctif « Itineraire »).
        leading: IconButton(
          icon: const StepIcon(StepwaysIcons.flecheArriere),
          tooltip: t.a11y.back,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        // GUIDE DES ICONES (LOT D, manque reel n°2). Place en action (i) de
        // l'en-tete : c'est le geste maison pour un guide d'ecran (cf. le (i)
        // du Programme), et cela n'ajoute pas un huitieme bouton flottant sur
        // une carte de terrain.
        actions: [
          // FAIRE AVANCER LA RANDONNEE SIMULEE, DEPUIS LA CARTE (tache 638,
          // bugs 11 et 16). C'est ici qu'on regarde quand on marche : le bouton
          // de simulation doit donc etre atteignable sans repasser par le
          // cockpit. Invisible hors demo et hors randonnee simulee.
          const BoutonSimulationDemo(compact: true),
          IconButton(
            icon: const StepIcon(StepwaysIcons.info),
            tooltip: t.map.title,
            onPressed: () => showMapGuideSheet(context, trailId),
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, _) {
          final trackAsync = ref.watch(gpxTrackProvider(trailId));

          return trackAsync.when(
            loading: () => LoadingView(message: t.map.loading),
            error: (error, _) => ErrorView(
              message: t.common.cannotLoadTrack,
              onRetry: () => ref.invalidate(gpxTrackProvider(trailId)),
            ),
            data: (points) {
              if (points.isEmpty) {
                return ErrorView(message: t.map.noTrack);
              }
              return _MapContent(trailId: trailId, rawPoints: points);
            },
          );
        },
      ),
    );
  }
}
