/// Les surcouches de la carte, extraites en vague 1.
///
/// Morceau de `map_screen.dart` (lot 645-06, vague 2) : meme
/// bibliotheque, donc aucune visibilite, aucun identifiant et
/// aucun site d appel ne changent.
part of 'map_screen.dart';

/// Le bas de la carte : les boutons flottants et la barre d'etape.
///
/// L'ETAT RESTE CHEZ L'ECRAN : la feuille des calques est ouverte par
/// [onShowLayers], que l'ecran fournit avec son propre `context`.
class _MapBottomBar extends StatelessWidget {
  const _MapBottomBar({required this.bounds, required this.onShowLayers});

  /// La bounding box du trace, repli de « centrer sur moi ».
  final LatLngBounds bounds;

  /// Ouvre la feuille des calques.
  final VoidCallback onShowLayers;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MapLeftButtons(onShowLayers: onShowLayers),
              const Spacer(),
              _MapRightControls(bounds: bounds),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Barre d'etape active (parite GR20 : bandeau de progression).
        // Visible uniquement pendant un trek reel, alimentee par la
        // projection sur le trace (etape, distance restante, progression,
        // hors-trace). Reutilise [StageProgressBar]. Rendu nul hors trek.
        const _ActiveStageBar(),
      ],
    );
  }
}

/// Colonne gauche : SOS (visible en trek) + Photo + Calques.
class _MapLeftButtons extends StatelessWidget {
  const _MapLeftButtons({required this.onShowLayers});

  /// Ouvre la feuille des calques.
  final VoidCallback onShowLayers;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SosButton(),
        const SizedBox(height: 8),
        // PHOTO VERS LE JOURNAL DU JOUR (LOT D, manque reel
        // n°1) : present sur la carte de reference, absent de
        // StepWays. Cote gauche avec le SOS, pour ne pas
        // allonger la colonne des controles de carte.
        const _MapPhotoButton(),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'mapLayers',
          tooltip: t.map.layers,
          onPressed: onShowLayers,
          child: const StepIcon(StepwaysIcons.calques),
        ),
      ],
    );
  }
}

/// Colonne droite : controles carte (peau + zoom + centrer).
class _MapRightControls extends StatelessWidget {
  const _MapRightControls({required this.bounds});

  /// La bounding box du trace, repli de « centrer sur moi ».
  final LatLngBounds bounds;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final mapController = ref.read(mapControllerProvider);
        return MapControls(
          mapController: mapController,
          onCenterOnMe: () {
            final posAsync = ref.read(locationProvider);
            final pos = posAsync.value;
            if (pos != null) {
              mapController.move(
                LatLng(pos.latitude, pos.longitude),
                mapController.camera.zoom,
              );
              return;
            }
            // SANS POSITION, LE BOUTON LE DIT (tache 601).
            //
            // Il recentrait SILENCIEUSEMENT sur le trace. Quand
            // la camera est deja sur le trace — le cas a
            // l'ouverture de la carte — ce repli ne bouge rien :
            // le randonneur appuie sur « centrer sur moi », rien
            // ne se passe, et rien ne lui dit pourquoi. C'est un
            // bouton muet au sens de la regle du LOT X.
            //
            // POURQUOI PERSONNE NE L'AVAIT VU. L'invariante des
            // gestes morts ne l'atteignait pas : le bouton photo,
            // joue avant lui sur le meme ecran, restait suspendu
            // pour toujours sur le canal de l'appareil photo, si
            // bien que tous les gestes suivants etaient declares
            // « non joues » au lieu d'etre mesures. La tache 601
            // a donne au bouton photo une reponse immediate (le
            // paywall du sentier redevenu payant) : la mesure est
            // allee plus loin, et elle a trouve celui-ci.
            //
            // Le repli reste — il sert quand la camera a derive.
            // On ajoute la seule chose qui manquait : la RAISON.
            mapController.fitCamera(
              CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(32),
              ),
            );
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(t.gps.centeredOnTrack)));
          },
        );
      },
    );
  }
}

/// --- Bandeaux du haut, empiles : hors-trace (securite) puis
/// ravitaillement (correctif L6-1). Deux alertes de nature differente
/// qui peuvent coexister ; la Column garantit qu'aucune ne recouvre
/// l'autre, quelle que soit la hauteur du texte traduit.
class _MapTopBanners extends StatelessWidget {
  const _MapTopBanners();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Alerte hors-trace : banniere in-screen en tete.
        // La notification + la vibration partent du provider (meme
        // telephone en poche) ; ici on injecte les libelles traduits
        // (Slang) dans le provider et on affiche le bonus visuel.
        // RepaintBoundary : isole du raster carte.
        Consumer(
          builder: (context, ref, _) {
            // Sync des libelles de notification avec la langue courante,
            // hors phase de build (setMessages modifie un provider).
            final messages = OffTrackMessages(
              notifTitle: t.navAlert.offTrackNotifTitle,
              notifBody: (m) => t.navAlert.offTrackNotifBody(meters: m),
            );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(offTrackMessagesProvider.notifier).setMessages(messages);
            });
            return const RepaintBoundary(child: OffTrackBanner());
          },
        ),
        // Alerte ravitaillement (correctif L6-1).
        const _SupplyAlertBanner(),
      ],
    );
  }
}
