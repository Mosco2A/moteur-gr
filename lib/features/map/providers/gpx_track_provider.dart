/// La trace brute d'un sentier, lue EN BASE d'abord ; l'asset du binaire n'est
/// plus que le secours (tache 606).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/geo/trail_track.dart';
import '../../../core/geo/trace_point.dart';

/// Provider du trace GPX brut, parametre par trailId.
///
/// LA CARTE LIT LA BASE, L ASSET EST LE SECOURS (tache 606). Cette ligne disait
/// jusqu ici « Charge le fichier GPX depuis les assets via
/// GpxDepuisLesAssets.parseFromAsset », et c etait la seconde moitie du mur
/// n1 : un sentier connu du SEUL distant apparaissait au catalogue (lot 605),
/// ses
/// donnees descendaient bien dans `trail_gpx_points` — et sa trace ne
/// s affichait PAS, parce que la carte allait la chercher dans le BINAIRE. Il
/// etait consultable et pas marchable.
///
/// L ordre des sources est celui du catalogue, pas un autre : la base d abord,
/// l asset embarque en secours quand la base n a rien (cf. [SourceDeLaTrace]).
/// Les quatre sentiers embarques ne perdent rien — l amorce pose desormais leur
/// trace ENTIERE en base, la ou elle y posait une copie simplifiee.
///
/// La resolution des sources vit dans [LecteurDeTrace], chemin UNIQUE partage
/// avec `DriftTrailDataProvider.getTrackPoints`.
final gpxTrackProvider = FutureProvider.family<List<TrackPoint>, String>((
  ref,
  trailId,
) async {
  final config = ref.watch(trailConfigProvider);

  // Verifier que le trailId correspond a la config active
  if (config.id != trailId) {
    throw ArgumentError(
      'Trail "$trailId" ne correspond pas a la config active "${config.id}"',
    );
  }

  final trace = await ref
      .watch(lecteurDeTraceProvider)
      .lire(trailId: trailId, cheminAsset: config.gpxAssetPath);
  return trace.points;
});

/// La trace du sentier ACTIF avec sa PROVENANCE (base ou asset embarque).
///
/// [gpxTrackProvider] ne rend que les points, parce que ses consommateurs —
/// sept fichiers au lot 671-04, les charnieres comprises — n ont besoin que de
/// cela. La provenance est exposee separement pour qu un
/// ecran de diagnostic — ou un test — puisse verifier d ou vient la trace sans
/// avoir a deviner : « la trace s affiche » et « la trace vient de la base » sont
/// deux affirmations differentes, et c est la seconde qui prouve que le mur est
/// tombe.
final traceDuSentierProvider = FutureProvider.family<TrailTrack, String>((
  ref,
  trailId,
) async {
  final config = ref.watch(trailConfigProvider);
  return ref
      .watch(lecteurDeTraceProvider)
      .lire(
        trailId: trailId,
        cheminAsset: config.id == trailId ? config.gpxAssetPath : '',
      );
});

/// La trace du sentier ACTIF telle que la lisent les chiffres du jour (lot
/// 671-06), ou `null` quand elle est indisponible.
///
/// Les chiffres de la carte, du journal et du recapitulatif se calculent sur
/// la tranche de cette trace que le randonneur a parcourue. Une trace qui ne
/// se charge pas (sentier sans trace en base ni dans le binaire) n'est pas une
/// erreur pour eux : ils reviennent aux releves, comme avant le lot. Le choix
/// est fait ICI, une fois, plutot que dans chacun des trois.
final statsTraceProvider = FutureProvider<List<TrackPoint>?>((ref) async {
  final trailId = ref.watch(trailIdProvider);
  try {
    return await ref.watch(gpxTrackProvider(trailId).future);
  } on Object {
    return null;
  }
});
