/// LA DERNIERE POSITION CONNUE, ET LE TIR UNIQUE QUI LA REMPLACE (lot
/// 671-04) : ce que le bouton SOS montre a la premiere milliseconde, sans
/// garder aucun flux GPS chaud.
///
/// LE DEFAUT QUE LE FLUX CHAUD CORRIGEAIT, ET POURQUOI IL NE REVIENT PAS. Le
/// bouton SOS gardait `positionStreamProvider` en ecoute pendant tout le trek
/// (Finitions V1, point 6) : ce flux est FROID, et un simple `ref.read` a
/// l'ouverture du dialogue trouvait souvent un flux qui n'avait pas encore
/// emis — « position GPS indisponible ». La reponse de ce lot est meilleure
/// qu'un flux chaud : une MEMOIRE de la derniere position recue, que deux
/// ecoutes qui existent deja tiennent a jour — le robinet de l'interface
/// ([PositionController.lastFix], flux ou tir) et le service de fond
/// ([BackgroundGpsService.lastPoint], releve ou point ESTIME le long du trace,
/// les deux sources de la position courante du lot 671-03). La lire n'ouvre
/// rien. En profil batterie d'abord, elle a au plus trois minutes ; en profil
/// carte, elle est fraiche ; et le bouton SOS n'existe que pendant un trek.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/data/daos/session_track_points_dao.dart'
    show TrackPointSource;
import '../../../core/services/journal_de_mesure.dart';
import 'background_gps_service.dart';
import 'gps_service.dart';
import 'position_controller.dart';

/// Une position connue et l'heure ou elle a ete mesuree (ou estimee).
class PositionConnue {
  /// Une position mesuree a [mesureeA].
  const PositionConnue({
    required this.latitude,
    required this.longitude,
    required this.mesureeA,
    this.altitude,
    this.estimee = false,
  });

  /// Un releve du recepteur.
  factory PositionConnue.releve(Position p) => PositionConnue(
    latitude: p.latitude,
    longitude: p.longitude,
    altitude: p.altitude,
    mesureeA: p.timestamp,
  );

  /// Un point de l'isolate de fond, releve ou estime le long du trace.
  factory PositionConnue.deFond(BgTrackPoint p) => PositionConnue(
    latitude: p.latitude,
    longitude: p.longitude,
    altitude: p.altitude,
    mesureeA: p.timestamp,
    estimee: p.source == TrackPointSource.estimated,
  );

  /// Latitude en degres.
  final double latitude;

  /// Longitude en degres.
  final double longitude;

  /// Altitude en metres (celle du trace pour un point estime), nulle si
  /// inconnue.
  final double? altitude;

  /// L'heure de la mesure : c'est d'elle que se calcule l'age affiche.
  final DateTime mesureeA;

  /// Vrai pour un point ESTIME le long du trace, entre deux releves.
  final bool estimee;
}

/// Les positions que le SOS sait montrer : la derniere connue, et une
/// fraiche par un tir unique.
class PositionsConnues {
  /// [robinet] est le robinet unique GPS de l'interface ; [pointDeFond] rend
  /// le dernier point du suivi en cours recu de l'isolate de fond
  /// ([BackgroundGpsService.lastPoint]) ; [journal] le journal de mesure, ou
  /// s'ecrit la ligne `sos` ; [maintenant] l'horloge de l'age (`DateTime.now`
  /// en production, une fausse horloge en test).
  PositionsConnues({
    required PositionController robinet,
    required BgTrackPoint? Function() pointDeFond,
    required MeasureJournal journal,
    DateTime Function()? maintenant,
  }) : _robinet = robinet,
       _pointDeFond = pointDeFond,
       _journal = journal,
       maintenant = maintenant ?? DateTime.now;

  final PositionController _robinet;
  final BgTrackPoint? Function() _pointDeFond;
  final MeasureJournal _journal;

  /// L'horloge sur laquelle se calcule l'age d'une position.
  final DateTime Function() maintenant;

  /// LA PLUS RECENTE des deux memoires, nulle si aucune n'a rien recu.
  PositionConnue? derniere() {
    final fix = _robinet.lastFix;
    final point = _pointDeFond();
    final duRobinet = fix == null ? null : PositionConnue.releve(fix);
    final deFond = point == null ? null : PositionConnue.deFond(point);
    if (duRobinet == null) return deFond;
    if (deFond == null) return duRobinet;
    return deFond.mesureeA.isAfter(duRobinet.mesureeA) ? deFond : duRobinet;
  }

  /// UN TIR UNIQUE, par le robinet ([PositionController.singleShot]) :
  /// precision haute, quinze secondes au plus. Aucun flux ouvert.
  Future<PositionConnue> tirer() async =>
      PositionConnue.releve(await _robinet.singleShot());

  /// LA LIGNE `sos` DU JOURNAL (le mot reserve par le lot 671-01, jamais
  /// ecrit jusqu'ici), a l'appui : la position affichee au champ 6, et son
  /// AGE en secondes au champ 9 — le seul champ du journal qui porte une
  /// duree en secondes ; sur une ligne `sos`, c'est l'age de la position
  /// montree aux secours, pas un temps de premier point. Ne leve jamais.
  Future<void> noterLAppel(PositionConnue? affichee) {
    final at = maintenant();
    return _journal.append(
      MeasureLine.event(
        at: at,
        profile: _robinet.profile,
        event: MeasureEvent.sos,
        latitude: affichee?.latitude,
        longitude: affichee?.longitude,
        timeToFix: affichee == null ? null : at.difference(affichee.mesureeA),
      ),
    );
  }
}

/// Les positions connues du SOS, sur le robinet unique et le service de fond.
final positionsConnuesProvider = Provider<PositionsConnues>((ref) {
  final fond = ref.watch(backgroundGpsServiceProvider);
  return PositionsConnues(
    robinet: ref.watch(positionControllerProvider),
    pointDeFond: () => fond.lastPoint,
    journal: MeasureJournal.documents(),
  );
});
