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
import '../presentation/health_info_screen.dart'
    show healthInfoRepositoryProvider;

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

/// LA FICHE D'URGENCE SUR L'ECRAN VERROUILLE — ALLUMEE ET ETEINTE (tache 630).
///
/// ===========================================================================
/// LE DEFAUT MESURE, ET IL EST PLUS GRAVE QUE CELUI QUI A DECLENCHE LE LOT
/// ===========================================================================
///
/// Le lot E5.20a avait ecrit `LockscreenWidgetService` en entier : notification
/// persistante, contenu enrichi, payload iOS. Personne ne l'a JAMAIS branche.
/// Mesure du 29/09 : `activate()` et `updateSecurityData()` ne sont appeles par
/// AUCUNE ligne de `lib/`, et `lockscreenWidgetServiceProvider` n'est lu nulle
/// part. Autrement dit, sur le telephone de Christophe, un secouriste qui
/// ramasse l'appareil ne voit RIEN — pas une fiche amputee de deux champs : rien
/// du tout.
///
/// C'est le meme motif que les taches 613 (exclusion posee sur un dossier VIDE)
/// et 615 (commentaire annoncant une ecriture qui n'existait pas) : du code qui
/// a l'air de proteger et qui ne tourne jamais.
///
/// ===========================================================================
/// QUAND ELLE S'ALLUME, ET POURQUOI PAS PLUS TOT
/// ===========================================================================
///
/// PENDANT LE TREK, et seulement pendant. Trois raisons, dans l'ordre :
///
///  1. C'EST LE MOMENT OU ELLE SERT. Une notification permanente affichant le
///     groupe sanguin de quelqu'un qui est chez lui n'est pas une securite,
///     c'est une exposition. Sur le sentier, le rapport s'inverse : le risque
///     qu'un inconnu lise la fiche est infiniment plus petit que le risque qu'un
///     secouriste ne trouve rien. C'est l'arbitrage de Christophe, verbatim :
///     « ou la trouver quand tu es a terre !!! serieux ».
///
///  2. LA PERMISSION EST DEJA ACQUISE A CE MOMENT-LA. `POST_NOTIFICATIONS`
///     (Android 13+) est demandee, expliquee, AVANT le depart pour le service de
///     fond du GPS (`ensureBackgroundTrackingExplained`). S'accrocher au meme
///     instant evite une seconde demande sortie de nulle part — et une demande
///     sortie de nulle part se refuse.
///
///  3. ELLE S'ETEINT TOUTE SEULE. Attachee au debut et a la fin de la capture de
///     fond, elle ne peut pas survivre au trek : pas de notification orpheline
///     qui resterait des semaines sur l'ecran verrouille.
///
/// ELLE NE S'ALLUME PAS SUR UNE FICHE VIDE : il n'y aurait rien a lire, et une
/// notification vide apprend au randonneur a la balayer.
///
/// ELLE NE LEVE JAMAIS. Elle est appelee depuis le demarrage d'un trek ; un
/// canal de notification indisponible ne doit pas empecher quelqu'un de partir
/// marcher.
class FicheEcranVerrouille {
  FicheEcranVerrouille(this._ref);

  final Ref _ref;

  /// Allume la fiche d'urgence sur l'ecran verrouille.
  ///
  /// [stageName] et [stageIndex] situent le randonneur sur le sentier : c'est le
  /// contexte du secours, pas la fiche. La position GPS n'est PAS passee ici —
  /// elle bouge a chaque pas et sera rafraichie par le trek, pas figee au
  /// depart.
  Future<void> allumer({String? stageName, int? stageIndex}) async {
    try {
      final fiche = await _ref.read(healthInfoRepositoryProvider).get();
      if (!fiche.hasData) return;
      final contacts = _ref.read(emergencyContactsServiceProvider);
      contacts.chargerDepuisLaFiche(fiche.emergencyContacts);
      final service = _ref.read(lockscreenWidgetServiceProvider);
      await service.updateSecurityData(
        healthInfo: fiche,
        stageName: stageName,
        stageIndex: stageIndex,
      );
      await service.activate();
    } on Object {
      // Best-effort : le secours ne doit pas empecher le depart.
    }
  }

  /// Eteint la fiche d'urgence de l'ecran verrouille (fin ou abandon du trek).
  Future<void> eteindre() async {
    try {
      await _ref.read(lockscreenWidgetServiceProvider).deactivate();
    } on Object {
      // Best-effort : l'arret d'une notification ne doit pas empecher la
      // finalisation d'un trek.
    }
  }
}

/// La fiche d'urgence d'ecran verrouille, allumee au depart, eteinte a l'arrivee.
final ficheEcranVerrouilleProvider = Provider<FicheEcranVerrouille>(
  FicheEcranVerrouille.new,
);
