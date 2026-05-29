/// Barrel file pour les providers d'etapes (mode trek).
///
/// Re-exporte les providers definis dans [trail_providers.dart]
/// pour un import plus cible depuis les ecrans de navigation.
///
/// Providers disponibles :
/// - [trekStagesProvider] — FutureProvider chargeant les etapes
///   depuis [TrailDataProvider]
/// - [stageByIdProvider] — FutureProvider.family(String id)
///   pour charger une etape par identifiant
/// - [currentTrailIdProvider] — StateProvider<String>
///   pour l'identifiant du sentier actif
library;

export 'trail_providers.dart'
    show trekStagesProvider, stageByIdProvider, currentTrailIdProvider;
