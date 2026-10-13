/// LE BANC DE MESURE BATTERIE (lot 671-01) : ce que l'ecran de mesure cache
/// des reglages lit et commande dans `trek`, derriere une seule porte.
///
/// L'ecran choisit le profil et lit l'etat ; il ne demarre, n'arrete et
/// n'efface RIEN. Le journal est ouvert et alimente par le suivi du trek.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/gps_cadence.dart';
import '../../../core/services/journal_de_mesure.dart';
import '../data/background_gps_service.dart';
import '../data/gps_service.dart';
import '../data/podometre_preferences.dart';
import '../data/repli_gps_continu.dart';
import '../domain/longueur_de_pas.dart';

/// Les gestes et lectures du banc, injectables pour les tests.
class MeasureBench {
  /// Chaque fonction est un acces au systeme ; le provider branche le reel.
  const MeasureBench({
    required this.readProfile,
    required this.chooseProfile,
    required this.readBattery,
    required this.journal,
    required this.stepsAllowed,
    required this.requestSteps,
    required this.readStride,
  });

  /// Le profil en vigueur, tel que l'isolate de fond le lit.
  final Future<PositionProfile> Function() readProfile;

  /// Ecrit [PositionProfile] dans le canal et l'applique sans redemarrer.
  final Future<void> Function(PositionProfile profile) chooseProfile;

  /// Le pourcentage de batterie, nul si illisible.
  final Future<int?> Function() readBattery;

  /// Le journal de mesure.
  final MeasureJournal journal;

  /// Vrai si l'activite physique (comptage des pas) est autorisee.
  final Future<bool> Function() stepsAllowed;

  /// Demande l'autorisation au systeme ; vrai si elle est accordee.
  final Future<bool> Function() requestSteps;

  /// La calibration de la longueur de pas, lue au point de calibration
  /// (lot 671-02), en lecture seule.
  final Future<StrideCalibration> Function() readStride;
}

/// LE CANAL DU PROFIL (lot 671-00) : le controleur ecrit `kPrefsBgProfile` et
/// change la cadence de l'interface ; le service transmet au fond s'il tourne.
/// Le seul chemin d'un changement de profil, manuel ou de secours (lot
/// 671-03) : aucun flux de positions n'est ouvert ici.
final positionProfileChannelProvider =
    Provider<Future<void> Function(PositionProfile profile)>((ref) {
      return (profile) async {
        await ref.read(positionControllerProvider).setProfile(profile);
        ref.read(backgroundGpsServiceProvider).applyProfile(profile);
      };
    });

/// Le dernier profil CHOISI a l'ecran de mesure pendant cette session de
/// l'application, nul avant tout choix. Les sorties de secours vers le GPS
/// continu l'ecoutent : le choix manuel reste maitre (lot 671-03).
class ChosenPositionProfileNotifier extends Notifier<PositionProfile?> {
  @override
  PositionProfile? build() => null;

  /// Note le choix du randonneur.
  void choose(PositionProfile profile) => state = profile;
}

/// Voir [ChosenPositionProfileNotifier].
final chosenPositionProfileProvider =
    NotifierProvider<ChosenPositionProfileNotifier, PositionProfile?>(
      ChosenPositionProfileNotifier.new,
    );

/// Le banc branche sur le robinet unique GPS et le service de fond.
final measureBenchProvider = Provider<MeasureBench>((ref) {
  return MeasureBench(
    readProfile: bgReadStoredPositionProfile,
    chooseProfile: (profile) async {
      await ref.read(positionProfileChannelProvider)(profile);
      // Le choix du randonneur est range a part du profil en vigueur, qu'une
      // sortie de secours peut remplacer par la carte (lot 671-03).
      await writeChosenPositionProfile(profile);
      ref.read(chosenPositionProfileProvider.notifier).choose(profile);
    },
    readBattery: bgReadBatteryPercent,
    journal: MeasureJournal.documents(),
    stepsAllowed: bgStepsAllowed,
    requestSteps: bgRequestStepsPermission,
    readStride: ref.read(podometerStoreProvider).readStride,
  );
});
