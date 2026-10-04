/// Les surcouches de la carte : boutons flottants, bandeaux du haut
/// et l alerte de ravitaillement.
///
/// Bibliotheque de l'ecran `map_screen.dart` (lot 645-06b).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../i18n/translations.g.dart';
import '../../../map/map_facade.dart'
    show
        OffTrackMessages,
        locationProvider,
        offTrackMessagesProvider,
        supplyGapAlertProvider;
import '../../../map/widgets/off_track_banner.dart';
import '../../../safety/presentation/sos_button.dart';
import '../../providers/tracking_providers.dart';
import 'controls/map_controls.dart';
import '../../../../core/branding/stepways_icons.dart';
import 'map_controller.dart';
import 'map_photo_button.dart';
import 'map_content.dart';

/// Le bas de la carte : les boutons flottants et la barre d'etape.
///
/// L'ETAT RESTE CHEZ L'ECRAN : la feuille des calques est ouverte par
/// [onShowLayers], que l'ecran fournit avec son propre `context`.
class MapBottomBar extends StatelessWidget {
  const MapBottomBar({
    super.key,
    required this.bounds,
    required this.onShowLayers,
  });

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
        const ActiveStageBar(),
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
        const MapPhotoButton(),
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
class MapTopBanners extends StatelessWidget {
  const MapTopBanners({super.key});

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

/// Bandeau « ravitaillement » de la carte (correctif L6-1).
///
/// CE QUI EXISTAIT DEJA, ET QUI N'EST PAS RECONSTRUIT ICI : le calcul de
/// l'ecart au prochain commerce ([TrailShops.gapAfter] / [TrailShops.isGapAlert]),
/// le catalogue du sentier ([trailShopsProvider]), les libelles traduits dans
/// les CINQ langues ([Translations] `shop.gapShort` / `shop.gapLong`) et la
/// detection de l'etape courante ([trackPositionProvider]). Ce qui manquait
/// etait le MONTAGE de l'alerte sur la carte : sa minuterie et son etat de
/// fermeture. C'est tout ce que porte ce widget.
///
/// COMPORTEMENT, aligne sur la reference terrain :
///  - rien hors trek : l'alerte parle au marcheur, pas au lecteur de carte ;
///  - rien tant que l'ecart ne depasse pas le seuil du sentier (cf.
///    [supplyGapAlertProvider]) ;
///  - la banniere s'efface SEULE au bout d'une minute, une seule minuterie
///    posee par apparition ;
///  - elle s'efface aussi a la demande (croix), et cette fermeture tient ;
///  - elle se REARME au changement d'etape : une nouvelle etape est une
///    nouvelle decision de ravitaillement, meme si la precedente avait ete
///    fermee a la main.
///
/// UN POINT OU STEPWAYS FAIT MIEUX QUE LA REFERENCE : chez GR20 le texte de ce
/// bandeau est ECRIT EN DUR dans l'ecran alors qu'une cle de traduction
/// existe. GR20 est bilingue et s'en accommode ; StepWays sert CINQ langues,
/// le texte en dur y est interdit. Le libelle vient donc de Slang, et le
/// nombre d'etapes y est injecte en parametre.
class _SupplyAlertBanner extends ConsumerStatefulWidget {
  const _SupplyAlertBanner();

  @override
  ConsumerState<_SupplyAlertBanner> createState() => _SupplyAlertBannerState();
}

class _SupplyAlertBannerState extends ConsumerState<_SupplyAlertBanner> {
  /// Duree d'affichage avant effacement automatique (parite reference).
  static const Duration _autoHideDelay = Duration(seconds: 60);

  Timer? _timer;

  /// Etape pour laquelle la minuterie courante a ete posee. Sert de memoire
  /// de rearmement : tant qu'elle ne change pas, on ne repose pas de
  /// minuterie et on ne rouvre pas une banniere fermee a la main.
  int? _armedForStage;

  /// Vrai quand la banniere est effacee (minuterie echue ou fermeture
  /// utilisateur) pour l'etape [_armedForStage].
  bool _hidden = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Remet l'alerte a zero pour [stageNumber] : une minuterie, une seule.
  void _armFor(int stageNumber) {
    _timer?.cancel();
    _armedForStage = stageNumber;
    _hidden = false;
    _timer = Timer(_autoHideDelay, () {
      if (mounted) setState(() => _hidden = true);
    });
  }

  void _disarm() {
    _timer?.cancel();
    _timer = null;
    _armedForStage = null;
    _hidden = false;
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(
      trekSessionManagerProvider.select((s) => s.status),
    );
    final trekActive =
        status == TrackingSessionStatus.recording ||
        status == TrackingSessionStatus.paused;
    final alert = ref.watch(supplyGapAlertProvider);

    if (!trekActive || alert == null) {
      // Plus rien a signaler : on desarme, sinon une minuterie continuerait
      // de courir pour une alerte disparue et la prochaine apparition sur la
      // meme etape naitrait deja effacee.
      _disarm();
      return const SizedBox.shrink();
    }

    if (_armedForStage != alert.stageNumber) {
      // Changement d'etape (ou premiere apparition) : minuterie et fermeture
      // repartent de zero. Pas de setState — on est deja dans le build de ce
      // bandeau, le rendu de ce tour tient compte de la remise a zero.
      _armFor(alert.stageNumber);
    }
    if (_hidden) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingBase,
          AppTheme.spacingSm,
          AppTheme.spacingBase,
          0,
        ),
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          color: theme.colorScheme.surface,
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingMd,
              AppTheme.spacingMd,
              AppTheme.spacingSm,
              AppTheme.spacingMd,
            ),
            decoration: BoxDecoration(
              color: AppTheme.orangeDifficile.withAlpha(20),
              border: Border.all(color: AppTheme.orangeDifficile.withAlpha(80)),
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StepIcon(
                  StepwaysIcons.danger,
                  color: AppTheme.orangeDifficile,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.shop.limitedTitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.orangeDifficile,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Libelle TRADUIT (jamais en dur) : le nombre d'etapes
                      // sans commerce est injecte en parametre.
                      Text(
                        t.shop.gapLong(n: alert.gap),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.orangeDifficile,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const StepIcon(StepwaysIcons.croix, size: 18),
                  color: AppTheme.orangeDifficile,
                  tooltip: t.map.supplyDismiss,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _hidden = true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
