// E5.20a — Providers du module securite.
//
// Branche les services securite sur Riverpod :
// - EmergencyContactsService (via emergency_screen.dart)
// - LockscreenWidgetService (notification lockscreen secours)
//
// Le nom du sentier actif et les secours regionaux viennent de
// TrailConfig — aucune donnee sentier hardcodee dans le moteur.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/trail_engine.dart';
import '../data/lockscreen_widget_service.dart';
import '../presentation/emergency_screen.dart'
    show emergencyContactsServiceProvider;

/// Provider du service widget lockscreen.
///
/// Le titre de la notification utilise le nom du sentier actif
/// (TrailConfig.name) injecte ici — jamais hardcode.
final lockscreenWidgetServiceProvider = Provider<LockscreenWidgetService>(
  (ref) => LockscreenWidgetService(
    contactsService: ref.watch(emergencyContactsServiceProvider),
    trailName: ref.watch(trailConfigProvider).name,
  ),
);
