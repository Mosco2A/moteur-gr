import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/eta_service.dart';

/// Provider du service d'ETA temps reel (F6B-01).
///
/// Par defaut sans flux d'entree branche : le flux d'estimations est cable au
/// niveau de l'ecran de navigation (F6B-02) qui fournit l'[EtaInput] courant.
final etaServiceProvider = Provider<EtaService>((ref) {
  return EtaService();
});
