/// Seuil de SORTIE par defaut : au-dela de cette distance perpendiculaire au
/// trace, on bascule "hors trace" et on declenche UNE alerte. Generique (aucun
/// sentier particulier) — parametrable a la construction du [OffTrackDetector].
const double kOffTrackExitThresholdMeters = 80.0;

/// Seuil de RETOUR par defaut : en deca de cette distance, on repasse "sur le
/// trace" et l'alerte se leve. Strictement inferieur au seuil de sortie -> zone
/// morte [50 m, 80 m] qui empeche le clignotement quand la position GPS oscille
/// autour du seuil (hysteresis).
const double kOffTrackReturnThresholdMeters = 50.0;

/// Transition renvoyee par [OffTrackDetector.update].
enum OffTrackTransition {
  /// Etat inchange (zone morte, ou pas de franchissement de seuil).
  none,

  /// On vient de sortir du trace -> declencher UNE alerte (notif + vibration).
  enteredOffTrack,

  /// On vient de revenir sur le trace -> lever l'alerte.
  returnedOnTrack,
}

/// Coeur de decision "sur le trace / hors trace" avec HYSTERESIS.
///
/// Dart pur (aucune dependance Flutter) -> entierement testable sans binding.
/// Ne raisonne QUE sur des distances (metres) ; le calcul geometrique
/// (projection de la position sur le trace) est fait en amont via le
/// `TrackProjector` (projection sur le trace PLEINE RESOLUTION, pas le trace
/// simplifie d'affichage — faux positifs dans les lacets).
///
/// Deux seuils distincts creent une zone morte [return, exit] : une fois un
/// etat atteint, il faut FRANCHIR l'autre seuil pour en changer. Tant que la
/// distance reste dans la zone morte, l'etat ne bascule pas — pas de
/// clignotement.
class OffTrackDetector {
  OffTrackDetector({
    this.exitThresholdMeters = kOffTrackExitThresholdMeters,
    this.returnThresholdMeters = kOffTrackReturnThresholdMeters,
  }) : assert(
          returnThresholdMeters < exitThresholdMeters,
          'Le seuil de retour doit etre < seuil de sortie (hysteresis).',
        );

  /// Distance au-dela de laquelle on passe hors trace.
  final double exitThresholdMeters;

  /// Distance en deca de laquelle on revient sur le trace.
  final double returnThresholdMeters;

  bool _offTrack = false;

  /// True si l'etat courant est "hors trace".
  bool get isOffTrack => _offTrack;

  /// Injecte une nouvelle distance perpendiculaire au trace (metres) et
  /// retourne la transition d'etat eventuelle.
  OffTrackTransition update(double distanceMeters) {
    if (!_offTrack && distanceMeters > exitThresholdMeters) {
      _offTrack = true;
      return OffTrackTransition.enteredOffTrack;
    }
    if (_offTrack && distanceMeters < returnThresholdMeters) {
      _offTrack = false;
      return OffTrackTransition.returnedOnTrack;
    }
    return OffTrackTransition.none;
  }

  /// Remet l'etat a "sur le trace" (nouvelle session / nouveau trace).
  void reset() => _offTrack = false;
}
