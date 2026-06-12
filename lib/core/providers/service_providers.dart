// Providers des services transverses du moteur.
//
// Branche sur Riverpod les services purs (SharedPreferences-based)
// pour qu'ils soient injectables et overridables dans les tests :
// - DemoModeService (E5.18)
// - WidgetDataService (E5.19a)

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/trek/data/widget_data_service.dart';
import '../services/demo_mode_service.dart';
import '../services/heart_rate_ble_service.dart';
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
