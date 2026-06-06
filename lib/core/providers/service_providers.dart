// Providers des services transverses du moteur.
//
// Branche sur Riverpod les services purs (SharedPreferences-based)
// pour qu'ils soient injectables et overridables dans les tests :
// - DemoModeService (E5.18)
// - WidgetDataService (E5.19a)

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/trek/data/widget_data_service.dart';
import '../services/demo_mode_service.dart';

/// Provider du service mode demo universel (E5.18).
final demoModeServiceProvider = Provider<DemoModeService>(
  (ref) => DemoModeService(),
);

/// Provider du service de donnees widget Home Screen (E5.19a).
final widgetDataServiceProvider = Provider<WidgetDataService>(
  (ref) => WidgetDataService(),
);
