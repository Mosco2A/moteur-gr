/// LA CARTE RESTE SUR LE POINT D'ARRIVEE — et le bandeau ne cache plus le
/// marcheur (tache 762).
///
/// ---------------------------------------------------------------------------
/// LE DEFAUT, TEL QUE LA RECETTE 753 L'A MESURE
/// ---------------------------------------------------------------------------
///
/// Mot pour mot : « dans les DEUX cas la carte ne reste pas sur le point
/// d'arrivee, le marcheur finit dans le coin bas-gauche a moitie cache ». Dans
/// les deux cas, c'est-a-dire en marche naturelle COMME apres le bouton de saut
/// d'etape : ce n'est donc pas un defaut de la simulation.
///
/// DEUX CAUSES ADDITIVES, ET IL FALLAIT LES DEUX POUR OBTENIR CE QU'IL A VU.
///
/// (1) LE CADRAGE VISE L'ETAPE, PAS L'ARRIVEE. Depuis la tache 747 la carte se
/// recadre sur l'etape SOUS LES PIEDS du marcheur a chaque changement d'etape —
/// ce qui etait le correctif juste, et qui reste la regle pendant la marche. A
/// l'arrivee, l'etape sous ses pieds est la DERNIERE, et on cadre donc sa
/// TRANCHE ENTIERE. Sur le sentier de demonstration cette tranche mesure 25,4
/// km (la dette de donnees nommee par la tache 747, dont la fiche annonce 10,0
/// km) : a cette echelle le point d'arrivee est un pixel au BOUT du cadre, pas
/// au milieu. « Cadrage large », exactement.
///
/// (2) LA BARRE DE CHIFFRES MANGE LE BAS DE LA CARTE. La barre est posee en
/// surcouche AU-DESSUS de la carte, pas a cote d'elle : la carte s'etend sous
/// elle. Aucun cadrage ne reservait cette hauteur, donc le point d'arrivee
/// pouvait tomber dans la bande que la barre recouvre. « A moitie cache par le
/// bandeau », exactement — et avec six cases de chiffres, cette bande fait le
/// tiers d'un ecran de telephone.
///
/// ---------------------------------------------------------------------------
/// CE QUI REMPLACE
/// ---------------------------------------------------------------------------
///
/// A LA FIN DE LA MARCHE, ON CADRE L'ARRIVEE ET ON Y RESTE. Un cadre
/// SYMETRIQUE autour du dernier point de la trace, de [rayonDArriveeM] de
/// demi-cote : le point d'arrivee est donc au CENTRE par construction, et non
/// au bord. Et le cadre montre les derniers hectometres parcourus, ce qui est
/// ce qu'on regarde en arrivant.
///
/// LE RAYON EST GEOMETRIQUE, PAS UN ZOOM EN DUR. Donner un niveau de zoom
/// aurait donne une echelle differente selon la latitude et selon l'ecran ;
/// une distance au sol donne la meme vue partout.
///
/// LA HAUTEUR DE LA BARRE EST MESUREE, PAS DEVINEE. Elle depend du contenu de
/// la barre (six cases ou deux), de la langue, et de la taille de police du
/// telephone : aucune constante ne peut etre juste. [MesureDeLaBarre] la releve
/// sur le widget reellement rendu et la publie dans
/// [_hauteurDeLaBarreProvider] ; le cadrage la passe en marge BASSE a
/// `CameraFit.bounds`, qui reduit le zoom et DECALE le centre vers le haut de
/// la moitie de cette marge (`paddingOffset` de `camera_fit.dart`). Le point
/// d'arrivee monte donc dans la zone degagee.
///
/// ON NE CADRE QU'UNE FOIS, et c'est volontaire : apres ce cadrage le
/// randonneur peut deplacer la carte pour regarder autour de lui, et rien ne la
/// lui arrache des mains. « Rester sur l'arrivee » veut dire « ne plus revenir
/// au depart », pas « se verrouiller ».
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/geo/trace_point.dart';
import '../../providers/tracking_providers.dart';
import 'map_controller.dart';

/// LE DEMI-COTE DU CADRE D'ARRIVEE, en metres au sol.
///
/// 400 m : assez large pour montrer le dernier virage et le batiment d'arrivee,
/// assez serre pour qu'on voie lequel. Valeur de jugement, nommee pour cela —
/// elle n'est mesuree sur aucun terrain.
const double rayonDArriveeM = 400;

/// LA HAUTEUR QUE LA BARRE DE CHIFFRES RECOUVRE, en pixels logiques.
///
/// Zero tant que rien ne l'a mesuree : le cadrage se comporte alors comme avant
/// ce lot, sans reserve basse. Une valeur fausse serait pire qu'une valeur
/// absente.
class _HauteurDeLaBarreNotifier extends Notifier<double> {
  @override
  double build() => 0;

  /// Publie une hauteur relevee. Sans effet si elle n'a pas change — ecrire la
  /// meme valeur a chaque image reconstruirait ses lecteurs pour rien.
  void mesurer(double hauteur) {
    if (!hauteur.isFinite || hauteur < 0) return;
    if ((hauteur - state).abs() < 0.5) return;
    state = hauteur;
  }
}

/// LA HAUTEUR MESUREE DE LA BARRE DE CHIFFRES DU BAS DE LA CARTE.
final _hauteurDeLaBarreProvider =
    NotifierProvider<_HauteurDeLaBarreNotifier, double>(
      _HauteurDeLaBarreNotifier.new,
    );

/// RELEVE LA HAUTEUR REELLE DE [enfant] et la publie.
///
/// LE RELEVE EST FAIT HORS PHASE DE BUILD (post-frame) : la taille d'un widget
/// n'existe qu'une fois la mise en page faite, et ecrire un provider pendant un
/// build est interdit par Riverpod. Le cadrage de l'arrivee n'arrive de toute
/// facon jamais a la premiere image.
class MesureDeLaBarre extends ConsumerStatefulWidget {
  /// Enveloppe [enfant] sans rien changer a son rendu.
  const MesureDeLaBarre({required this.enfant, super.key});

  /// Le widget dont on releve la hauteur.
  final Widget enfant;

  @override
  ConsumerState<MesureDeLaBarre> createState() => _MesureDeLaBarreState();
}

class _MesureDeLaBarreState extends ConsumerState<MesureDeLaBarre> {
  final GlobalKey _cle = GlobalKey();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final hauteur = _cle.currentContext?.size?.height;
      if (hauteur == null) return;
      ref.read(_hauteurDeLaBarreProvider.notifier).mesurer(hauteur);
    });
    return KeyedSubtree(key: _cle, child: widget.enfant);
  }
}

/// LE CADRE D'ARRIVEE : un carre de [rayonDArriveeM] autour de [arrivee].
///
/// Expose a part du widget pour etre verifiable sans carte ni telephone.
LatLngBounds cadreDeLArrivee(LatLng arrivee) {
  // UN DEGRE DE LATITUDE VAUT ENVIRON 111 320 m ; en longitude il se resserre
  // avec le cosinus de la latitude. On convertit donc les deux axes
  // separement, sinon le cadre serait aplati loin de l'equateur.
  const double metresParDegreLat = 111320;
  const deltaLat = rayonDArriveeM / metresParDegreLat;
  // Aux poles le cosinus tend vers zero et la conversion exploserait : on borne
  // le diviseur. Un cadre trop large y vaut mieux qu'un cadre infini.
  final cosLat = math.cos(arrivee.latitude * math.pi / 180).abs();
  final deltaLng =
      rayonDArriveeM / (metresParDegreLat * (cosLat < 0.01 ? 0.01 : cosLat));
  return LatLngBounds(
    LatLng(arrivee.latitude - deltaLat, arrivee.longitude - deltaLng),
    LatLng(arrivee.latitude + deltaLat, arrivee.longitude + deltaLng),
  );
}

/// CADRE LA CARTE SUR L'ARRIVEE, UNE FOIS, QUAND LA MARCHE EST FINIE.
///
/// Ne rend rien a l'ecran — il se monte dans la pile de la carte, sur le modele
/// de `ArrivalPipelineMount`.
class CadrageSurLArrivee extends ConsumerStatefulWidget {
  /// Recoit la trace du sentier : son DERNIER point est l'arrivee.
  const CadrageSurLArrivee({required this.trace, super.key});

  /// Les points du sentier, dans l'ordre du depart vers l'arrivee.
  final List<TrackPoint> trace;

  @override
  ConsumerState<CadrageSurLArrivee> createState() => _CadrageSurLArriveeState();
}

class _CadrageSurLArriveeState extends ConsumerState<CadrageSurLArrivee> {
  /// Vrai des que l'arrivee a ete cadree : on ne la recadre plus.
  bool _cadre = false;

  @override
  Widget build(BuildContext context) {
    final statut = ref.watch(
      trekSessionManagerProvider.select((s) => s.status),
    );

    // `idle` EST LE SEUL ETAT QUI REARME, et c'est ce qui permet a une seconde
    // marche d'etre cadree a son tour : la sortie de demo et le retour a
    // l'ecran d'attente y ramenent. `recording` ne rearme pas — un trek mis en
    // pause puis repris ne doit pas se faire recadrer sur l'arrivee.
    if (statut == TrackingSessionStatus.idle) {
      _cadre = false;
      return const SizedBox.shrink();
    }
    if (statut != TrackingSessionStatus.stopped || _cadre) {
      return const SizedBox.shrink();
    }
    if (widget.trace.length < 2) return const SizedBox.shrink();

    _cadre = true;
    final arrivee = widget.trace.last;
    final cadre = cadreDeLArrivee(LatLng(arrivee.lat, arrivee.lng));
    final reserveBasse = ref.read(_hauteurDeLaBarreProvider);
    final controleur = ref.read(mapControllerProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        controleur.fitCamera(
          CameraFit.bounds(
            bounds: cadre,
            // LA RESERVE BASSE EST LA HAUTEUR MESUREE DE LA BARRE : elle sort
            // le point d'arrivee de la bande que la barre recouvre.
            padding: EdgeInsets.fromLTRB(32, 32, 32, 32 + reserveBasse),
          ),
        );
      } catch (_) {
        // Le cadrage est un confort, pas une fonction vitale (meme regle que
        // `cadrageDOuverture`) : la carte reste utilisable s'il echoue.
      }
    });

    return const SizedBox.shrink();
  }
}
