/// La trace de la derniere session : les points persistes au fil de l'eau par
/// l'enregistrement, ou la matiere fabriquee en demonstration.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/daos/session_track_points_dao.dart';
import '../../../core/data/database.dart';
import '../../../core/engine/trail_engine.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/services/session_demo.dart';
import '../../after/after_facade.dart' show traceFabriqueeDeDemoProvider;

/// Tracé GPS de la dernière session de tracking du sentier actif.
///
/// Finitions V8 F3 : points persistés au fil de l'eau par le tracking
/// (table session_track_points), affichés dans le récap diplôme.
/// Liste vide si aucune session enregistrée.
final sessionTraceProvider = FutureProvider<List<SessionTrackPoint>>((
  ref,
) async {
  final trailId = ref.watch(trailConfigProvider.select((c) => c.id));
  final db = ref.watch(databaseProvider);

  // EN DEMONSTRATION, LA TRACE EST FABRIQUEE — ET C'EST LA MEME SOURCE QUE LE
  // RECAPITULATIF (tache 836).
  //
  // LE DEFAUT, ET CE QUI LE REND INSTRUCTIF : le diplome affichait « Trace non
  // disponible » au moment meme ou le carnet, lui, dessinait une trace. Les
  // deux ecrans disaient vrai. La demonstration ne pose RIEN en base — c'est la
  // promesse de la tache 634, tenue par quatre barrieres — donc la table
  // `session_track_points` est VIDE, et ce provider, qui ne lisait que la base,
  // n'avait rien a rendre. Le carnet, lui, passait deja par la matiere
  // fabriquee.
  //
  // LE CORRECTIF N'INVENTE RIEN. La tache 810 avait deja branche la matiere
  // fabriquee sur le recapitulatif ([adventureStatsProvider]) avec exactement
  // cette branche ; le diplome avait ete oublie. On recopie donc la decision
  // existante, on ne cree pas une seconde facon de fabriquer une trace.
  if (ref.watch(enDemoProvider)) {
    return ref.watch(traceFabriqueeDeDemoProvider.future);
  }

  // La trace DENSE, points estimes compris (lot 671-03) : ce provider ne
  // fait que la dessiner, il ne calcule aucun chiffre.
  return db.sessionTrackPointsDao.getByTrailId(
    trailId,
    read: TrackPointsRead.withEstimated,
  );
});
