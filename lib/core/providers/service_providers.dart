// Providers des services transverses du moteur.
//
// Branche sur Riverpod les services purs (SharedPreferences-based)
// pour qu'ils soient injectables et overridables dans les tests :
// - DemoModeService (E5.18)
// - WidgetDataService (E5.19a)

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/trek/data/widget_data_service.dart';
import '../services/consent_service.dart';
import '../services/demo_mode_service.dart';
import '../services/health_reader_service.dart';
import '../services/firestore_moderation_store.dart';
import '../services/heart_rate_ble_service.dart';
import '../services/moderation_service.dart';
import '../services/sensor_fusion_service.dart';

/// Provider du service mode demo universel (E5.18).
final demoModeServiceProvider = Provider<DemoModeService>(
  (ref) => DemoModeService(),
);

/// Provider du service de donnees widget Home Screen (E5.19a).
final widgetDataServiceProvider = Provider<WidgetDataService>(
  (ref) => WidgetDataService(),
);

/// Provider du service de fusion capteurs barometre + podometre (F6A-02).
final sensorFusionServiceProvider = Provider<SensorFusionService>(
  (ref) => SensorFusionService(),
);

/// Provider du service de FC via ceinture BLE GATT (F6F-02).
final heartRateBleServiceProvider = Provider<HeartRateBleService>(
  (ref) => HeartRateBleService(),
);

/// Provider du service de lecture sante HealthKit/Health Connect (F6F-03).
final healthReaderServiceProvider = Provider<HealthReaderService>(
  (ref) => HealthReaderService(),
);

/// Provider du service de consentement granulaire RGPD (D4A-01).
///
/// Le service est initialise de maniere asynchrone (chargement de
/// SharedPreferences) via [consentServiceProvider] ; ce provider synchrone
/// expose l'instance pour les appels imperatifs (grant/revoke). Il libere
/// le StreamController au dispose du scope.
final consentServiceProvider = Provider<ConsentService>((ref) {
  final service = ConsentService();
  ref.onDispose(service.dispose);
  return service;
});

/// Provider asynchrone qui garantit l'initialisation du [ConsentService].
///
/// A `watch` au demarrage (ou dans l'UI consentement D4A-02) avant tout
/// appel a [ConsentService.hasConsent]. Retourne l'instance initialisee.
final consentServiceReadyProvider = FutureProvider<ConsentService>((ref) async {
  final service = ref.watch(consentServiceProvider);
  await service.initialize();
  return service;
});

/// Provider du store Firestore des notifications de moderation (D4C-01).
///
/// Backend reel adosse a la collection `reports_moderation` (regles D4C-02).
/// Overridable en test par un faux [ModerationStore] en memoire.
final moderationStoreProvider = Provider<ModerationStore>(
  (ref) => FirestoreModerationStore(),
);

/// Provider du service de moderation hebergeur DSA art 16 (D4C-01).
///
/// Notice-and-action : appele par les boutons « Signaler » des features
/// communautaires (F6C-03 signalement, F7B-04 fil, F8A-04 waypoints). Libere
/// son StreamController au dispose du scope.
final moderationServiceProvider = Provider<ModerationService>((ref) {
  final service = ModerationService(store: ref.watch(moderationStoreProvider));
  ref.onDispose(service.dispose);
  return service;
});
