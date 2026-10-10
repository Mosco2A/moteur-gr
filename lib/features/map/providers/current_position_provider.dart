/// LA POSITION COURANTE (lot 671-03) : la position REELLE en profil carte, la
/// position ESTIMEE le long du trace entre deux releves en profils batterie.
/// C'est elle, et non plus le flux GPS brut, que lit la projection sur le
/// trace : tout ce qui en depend suit sans etre touche.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/services/gps_cadence.dart';
import '../../trek/trek_facade.dart'
    show BgTrackPoint, estimatedTrackPointsProvider, positionControllerProvider;
import 'location_provider.dart';

/// Ou le randonneur se trouve maintenant, releve ou estime.
class CurrentPosition {
  /// Une position ; [trackDistanceM] n'est porte que par un point estime.
  const CurrentPosition({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    this.accuracy,
    this.trackDistanceM,
  });

  /// Un releve reel, tel que le robinet GPS le livre.
  factory CurrentPosition.measured(Position position) => CurrentPosition(
    latitude: position.latitude,
    longitude: position.longitude,
    altitude: position.altitude,
    accuracy: position.accuracy,
  );

  /// Un point estime par l'isolate de fond, sur le trace.
  factory CurrentPosition.estimated(BgTrackPoint point) => CurrentPosition(
    latitude: point.latitude,
    longitude: point.longitude,
    altitude: point.altitude,
    trackDistanceM: point.trackDistanceM,
  );

  /// Latitude en degres.
  final double latitude;

  /// Longitude en degres.
  final double longitude;

  /// Altitude en metres : celle du recepteur, ou celle du trace pour un
  /// point estime.
  final double altitude;

  /// Precision du recepteur en metres ; nulle pour un point estime, qui n'a
  /// pas de recepteur.
  final double? accuracy;

  /// Distance du point estime depuis le depart du trace ; nulle pour un
  /// releve, qui doit etre projete.
  final double? trackDistanceM;

  /// Vrai pour un point estime le long du trace.
  bool get isEstimated => trackDistanceM != null;
}

/// Le dernier point estime recu depuis le dernier releve, ou nul.
///
/// Un releve reel l'efface : AU RELEVE SUIVANT, LA POSITION COURANTE EST
/// REMISE A LA POSITION REELLE. Un estime n'est pris qu'en profil de tir
/// (batterie d'abord, batterie basse) : en profil carte, la position courante
/// reste le releve, au metre pres, comme avant le lot.
class _LatestEstimateNotifier extends Notifier<BgTrackPoint?> {
  /// L'heure du dernier releve : un estime calcule avant lui est perime.
  DateTime? _lastFixAt;

  @override
  BgTrackPoint? build() {
    ref.listen(locationProvider, (_, next) {
      final fix = next.value;
      if (fix == null) return;
      _lastFixAt = fix.timestamp;
      state = null;
    });
    final subscription = ref
        .watch(estimatedTrackPointsProvider)
        .listen(_onEstimate);
    ref.onDispose(subscription.cancel);
    return null;
  }

  void _onEstimate(BgTrackPoint point) {
    final profile = ref.read(positionControllerProvider).profile;
    if (!GpsCadence.of(profile).isSingleShot) return;
    if (point.trackDistanceM == null) return;
    final lastFix = _lastFixAt;
    if (lastFix != null && point.timestamp.isBefore(lastFix)) return;
    state = point;
  }
}

final _latestEstimateProvider =
    NotifierProvider<_LatestEstimateNotifier, BgTrackPoint?>(
      _LatestEstimateNotifier.new,
    );

/// LA POSITION COURANTE, LE POINT D'ENTREE UNIQUE de la projection sur le
/// trace ([trackPositionProvider]), du marqueur de la carte et de son bouton
/// « centrer sur moi ».
///
/// Sans estime, c'est le releve du robinet GPS ([locationProvider]), avec son
/// etat de chargement et ses erreurs, inchanges.
final currentPositionProvider = Provider<AsyncValue<CurrentPosition>>((ref) {
  final estimate = ref.watch(_latestEstimateProvider);
  if (estimate != null) {
    return AsyncData(CurrentPosition.estimated(estimate));
  }
  final releve = ref.watch(locationProvider);

  // UN ROBINET QUI SE RECHARGE N'EFFACE PLUS LA POSITION CONNUE (tache 772).
  //
  // RETOUR DE CHRISTOPHE DU 10/10 11:08, mot pour mot : « en demo le centrage
  // du point d'avancement ne centre rien ».
  //
  // CE QUI SE PASSAIT, MESURE. Cette ligne composait le resultat avec
  // `AsyncValue.whenData`, qui ne transforme QUE la branche `data` : sur la
  // branche `loading` il rend une `AsyncLoading` NUE. Or Riverpod, pendant un
  // rechargement, RETIENT la derniere valeur — et `whenData` la jetait. Mesure
  // faite en demo, marcheur toujours en marche : `locationProvider` rendait
  // `hasValue: true` avec la bonne latitude A L'INSTANT PRECIS ou ce
  // provider-ci rendait `null`. L'application cessait de savoir ou est le
  // randonneur alors qu'elle le savait encore.
  //
  // CE QUE LE RANDONNEUR VOYAIT : son marqueur disparaissait de la carte, le
  // cadrage retombait sur la premiere etape, et « centrer sur moi » se
  // rabattait sur le trace en annoncant « Position introuvable ».
  //
  // POURQUOI LA DEMO EN SOUFFRAIT PLUS QUE LA VRAIE RANDONNEE. Le robinet se
  // reconstruit pour des raisons ordinaires — un changement de profil GPS
  // decide par le recalage, une entree ou une sortie de demo. En randonnee
  // reelle le recepteur reemet de lui-meme et la trouee se referme en une
  // seconde ; en demo les positions passent par un flux DIFFUSE, ou un nouvel
  // abonne ne recoit rien avant le battement suivant — et plus rien du tout
  // quand le marcheur simule est ARRIVE. La trouee pouvait donc ne jamais se
  // refermer.
  //
  // LA BRANCHE D'ERREUR N'EST PAS TOUCHEE : une permission refusee doit
  // continuer de remonter telle quelle, sinon l'ecran la cacherait derriere
  // une position perimee. Seule la fenetre de rechargement est rattrapee.
  final retenue = releve.value;
  if (releve.isLoading && retenue != null) {
    return AsyncData(CurrentPosition.measured(retenue));
  }
  return releve.whenData(CurrentPosition.measured);
});
