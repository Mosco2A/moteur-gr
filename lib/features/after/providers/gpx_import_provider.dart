import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../trek/providers/gps_providers.dart';
import '../data/gpx_import_service.dart';

/// Service d'import GPX (singleton, sans etat).
///
/// PARITE GR20 : miroir de `gpxImportServiceProvider` (GR20). Le service est
/// pur/generique — toute la specificite du sentier passe par
/// [importTrailConfigProvider] au moment de l'appel.
final gpxImportServiceProvider = Provider<GpxImportService>((ref) {
  return const GpxImportService();
});

/// Config d'import DERIVEE du sentier actif (data-driven, zero hardcode).
///
/// Construit [TrailImportConfig] a partir des ETAPES du sentier actif
/// ([domainStagesProvider]) :
///  * bornes geographiques = boite englobante des coordonnees d'etapes + marge
///    (aucune borne « Corse » en dur ; null si aucune etape -> hors-zone
///    tolerant) ;
///  * points de reference (detection d'etapes + hors-trace) = coordonnees
///    depart/arrivee des etapes ;
///  * nombre total d'etapes = celui du PARCOURS choisi
///    ([currentTrekPlanProvider], direction-aware) a defaut le nombre d'etapes
///    du sentier — jamais « 16 » en dur.
final importTrailConfigProvider = Provider<TrailImportConfig>((ref) {
  final stages = ref.watch(domainStagesProvider);
  final plan = ref.watch(currentTrekPlanProvider);
  return TrailImportConfig.fromStages(
    stages,
    totalStages: plan?.stageCount ?? stages.length,
  );
});
