// LES DEUX APPUIS DES GARDES DE LA TACHE 762 : un statut de session pilotable,
// et des reglages figes.
//
// POURQUOI DANS UN FICHIER A PART. Les gardes de ce lot ont besoin de FAIRE
// PASSER une session de `recording` a `stopped` pendant le test — c'est
// l'instant exact ou le defaut de la recette 753 apparaissait. Un notifier de
// test qui ne sait que rendre un etat initial ne suffit pas : il faut pouvoir
// en poser un nouveau.
library;

import 'package:moteur_gr/domain/trek_session.dart';
import 'package:moteur_gr/features/settings/providers/settings_provider.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';

/// L'identifiant de la marche que les gardes mesurent.
const String idDeLaMarche = 'sess-762';

/// Une session de marche, avec une date de depart FIXE.
///
/// Fixe, et pas `DateTime.now()` : une garde qui lit l'horloge du banc se met a
/// dependre du moment ou elle tourne.
TrekSession sessionMarchee({String id = idDeLaMarche}) => TrekSession(
  id: id,
  trailId: 'test-trail',
  startedAt: DateTime.utc(2026, 6, 15, 8),
  status: 'active',
);

/// Un gestionnaire de session dont l'etat se POSE depuis le test.
///
/// Il n'execute AUCUNE des transitions reelles (`start`, `stop`, `_finalize`) :
/// il reproduit leur RESULTAT, c'est-a-dire l'etat observable par les ecrans.
/// C'est ce que les ecrans lisent, et c'est donc ce qui doit etre mis sous
/// garde.
class StatutPilote extends TrekSessionManagerNotifier {
  /// Part de [_initial], et se laisse reposer par [poser].
  StatutPilote(this._initial);

  final TrackingSessionState _initial;

  @override
  TrackingSessionState build() => _initial;

  /// Pose un nouvel etat, comme une transition reelle l'aurait fait.
  void poser(TrackingSessionState nouveau) => state = nouveau;
}

/// Des reglages FIGES sur une main dominante.
///
/// NE LIT NI N'ECRIT LES PREFERENCES : le vrai notifier ouvre
/// `SharedPreferences` dans un `_load()` asynchrone, ce qui n'a rien a faire
/// dans une garde d'affichage. Ce qui est sous garde ici, c'est que l'ecran
/// SUIVE le reglage — pas la facon dont il est stocke, qui a deja ses propres
/// tests (`settings_service_test.dart`).
class ReglagesFixes extends SettingsNotifier {
  /// Fige la main dominante a [main].
  ReglagesFixes(this.main);

  /// La main dominante annoncee aux ecrans.
  final DominantHand main;

  @override
  AppSettings build() => AppSettings(dominantHand: main);
}
