/// L ecran carte : sa garde de sentier, son echafaudage et sa miette
/// d'observabilite.
///
/// Lot 645-06b (regle 12, pas de `part`) : ses widgets vivent dans des
/// bibliotheques voisines — `map_content.dart` (la FlutterMap, ses couches et
/// les barres d'etape), `map_sheets.dart` (panneau Calques et detail d'un
/// point), `map_overlays.dart` (boutons flottants et bandeaux),
/// `map_photo_button.dart`, `map_arrival_pipeline.dart` (le pont d'arrivee)
/// et `map_controller.dart` (le controleur de carte et son provider).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/analytics/screen_entry.dart';
import '../../../../core/engine/trail_engine.dart';
import '../../../../core/ui/error_view.dart';
import '../../../../core/ui/loading_view.dart';
import '../../../../i18n/translations.g.dart';
import '../../../map/map_facade.dart' show gpxTrackProvider, showMapGuideSheet;
import '../../../../core/branding/stepways_icons.dart';
import 'map_content.dart';

/// Ecran carte orchestrateur -- FlutterMap v8 + tous layers assembles.
///
/// PARITE GR20 (#99460, ecran Navigation terrain) : l'onglet Carte de StepWays
/// reprend, hors peau, tout ce que la Navigation GR20 affiche —
///   * fond OSM + trace de reference + position GPS (socle E2.3f) ;
///   * couche POI + bouton Calques (toggle par type, reutilise `PoiFilterBar`) ;
///   * bouton SOS (reutilise `SosButton`, visible pendant un trek) ;
///   * banniere hors-trace VISIBLE (reutilise `OffTrackBanner`) ;
///   * barre d'etape active (reutilise `StageProgressBar`) pendant un trek.
/// Generique multi-sentiers (donnees du sentier courant, zero hardcode), i18n
/// Slang, a11y (SOS + calques labellises).
///
/// Structure : Scaffold > [MapContent], qui porte la Stack de la carte (sa
/// documentation detaille les couches et les overlays ; lot 645-06b, le
/// paragraphe y a suivi le code qu'il decrit).
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
///     `_PlannedStageBar`.
///  2. LE BOUTON PHOTO VERS LE JOURNAL DU JOUR, present sur la carte de
///     reference (`_takePhoto`), qui n'existait nulle part cote StepWays. Cf.
///     `MapPhotoButton` — et il respecte le verrou du journal (#99410) : sans
///     achat, il ouvre la vitrine au lieu d'ecrire.
///  3. LE GUIDE DES ICONES (reference l.1087-1284) : action (i) de l'en-tete,
///     cf. [showMapGuideSheet] ; et la LISTE DES POINTS DE L'ETAPE qu'on coche
///     au passage, ajoutee au panneau Calques (cf. `StagePoiChecklist`) — le
///     panneau ne savait qu'afficher et masquer des couches, ce qui est une
///     autre fonction.
///
/// SOS — ACCES UNIQUE ALIGNE GR20 (decision Chris 12/09, cycle 3) : le SOS n'a
/// qu'UN SEUL point d'entree — le bouton flottant en overlay (colonne bas-gauche,
/// `SosButton`, visible en trek actif). C'est EXACTEMENT le placement GR20
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
  void initState() {
    super.initState();
    // LA MIETTE D'OBSERVABILITE DE LA CARTE (lot 645-09).
    //
    // LA CARTE EST L'ECRAN DE TERRAIN : celui ou le randonneur passe ses
    // journees, celui qui tient le GPS allume, et donc celui dont un rapport
    // de plantage a le plus besoin de contexte. Elle alimente `screen` et
    // `trail`. PAS `stage`, ET C'EST DELIBERE : le numero d'etape courante vit
    // dans un provider, et le lire a l'entree de l'ecran le ferait NAITRE une
    // frame plus tot qu'aujourd'hui. Le lot exige « comportement avant =
    // apres » ; la cle `stage` est donc alimentee par les quatre ecrans qui
    // portent deja un numero d'etape en champ (trail_stage_detail,
    // trek_stage_detail, accommodation_detail, weather), sans une seule
    // lecture nouvelle.
    //
    // Lot 645-06b : elle etait declaree dans la racine d'une bibliotheque a
    // `part` et posee dans un morceau ; la classe de l'ecran vit de nouveau
    // dans ce fichier, la miette y est donc declaree ET posee, a l'entree.
    observeScreenEntry(ref, ScreenBreadcrumb.map, trail: widget.trailId);
  }

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
          // LA COMMANDE DE SIMULATION N'EST PLUS ICI (tache 747).
          //
          // Retour de Christophe du 09/10 08:48 : « 7/ bouton simuler l'etape
          // suivant mal place et non fonctionnel ». Elle etait posee dans
          // l'en-tete de la carte, entre les commandes de TERRAIN — le guide
          // des icones ici, le SOS, la photo, les calques et le zoom juste en
          // dessous. Or ce n'est pas une commande de terrain : c'est une
          // commande de DEMONSTRATION, qui n'existe pas pour un randonneur.
          // La melanger aux autres laissait croire a un septieme outil de
          // navigation.
          //
          // ELLE A REJOINT LE BANDEAU DE LA DEMO ([MentionMarcheSimulee]), le
          // seul endroit de l'ecran qui parle DEJA de la demonstration et qui
          // dit « marche simulee - temps accelere ». Elle y est visible
          // pendant toute la marche simulee, et elle disparait avec elle.
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
              return MapContent(trailId: trailId, rawPoints: points);
            },
          );
        },
      ),
    );
  }
}
