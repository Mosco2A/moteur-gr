/// LE PERIMETRE DE LA BARRE DE LA CARTE : l'etape en cours, ou le sentier
/// entier — et le retour automatique a l'etape (tache 747).
///
/// DECISION DE CHRISTOPHE DU 09/10, 08:54 et 08:57. Son retour de depart,
/// 08:45, mot pour mot : « 4/ on a les donnees de trek complete au lieu
/// d'avoir les donnees de l'etape ». La regle qu'il a tranchee ensuite, et qui
/// est exactement ce que ce fichier tient :
///
///   * a l'ouverture, les chiffres sont ceux de L'ETAPE EN COURS ;
///   * un appui bascule vers le SENTIER ENTIER ;
///   * au bout de [delaiDeRetour], la vue sentier revient TOUTE SEULE a
///     l'etape ;
///   * le temporisateur SE REMET A ZERO si on touche l'ecran pendant ces vingt
///     secondes.
///
/// POURQUOI UN RETOUR AUTOMATIQUE, ET PAS DEUX ONGLETS. L'etape est ce qui sert
/// en marchant : « combien me reste-t-il avant le refuge ». Le sentier entier
/// est une curiosite qu'on consulte, pas un affichage de travail. Un etat qui
/// ne revient pas tout seul laisse le randonneur devant les mauvais chiffres
/// sans qu'il s'en apercoive — c'est le defaut d'origine, en pire, parce qu'il
/// l'aurait demande lui-meme trois heures plus tot.
///
/// POURQUOI LE TOUCHER REMET LE COMPTE A ZERO. Vingt secondes, c'est long quand
/// on lit, et court quand on deplace la carte pour situer la suite du sentier.
/// Si le randonneur est EN TRAIN de s'en servir, la vue ne doit pas se derober
/// sous ses doigts. Le toucher est la preuve qu'il est encore la.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Les deux perimetres que la barre sait montrer.
enum PerimetreDeLaBarre {
  /// L'etape en cours : le perimetre par defaut, celui qui sert en marchant.
  etape,

  /// Le sentier entier, du depart a l'arrivee.
  sentier,
}

/// Tient le perimetre affiche et le temporisateur de retour a l'etape.
class PerimetreDeLaBarreNotifier extends Notifier<PerimetreDeLaBarre> {
  /// COMBIEN DE TEMPS LA VUE SENTIER RESTE AVANT DE REVENIR A L'ETAPE.
  ///
  /// Vingt secondes, et c'est le chiffre que Christophe a donne (09/10 08:57).
  static const Duration delaiDeRetour = Duration(seconds: 20);

  Timer? _retour;

  @override
  PerimetreDeLaBarre build() {
    // LE TEMPORISATEUR NE SURVIT PAS A L'ECRAN. Sans cela, une minuterie
    // continuerait de tourner apres la fermeture de la carte et viendrait
    // ecrire dans un notifier dispose.
    ref.onDispose(_couperLeTemporisateur);
    // A L'OUVERTURE : L'ETAPE. C'est la decision de Christophe, et c'est aussi
    // le seul perimetre qui ait un sens avant de savoir ou on en est.
    return PerimetreDeLaBarre.etape;
  }

  /// UN APPUI : on passe au sentier entier, ou on revient a l'etape.
  ///
  /// Un VA-ET-VIENT et non un aller simple : le randonneur qui a vu ce qu'il
  /// voulait voir doit pouvoir revenir a ses chiffres de marche tout de suite,
  /// sans attendre vingt secondes devant le mauvais perimetre.
  void basculer() {
    if (state == PerimetreDeLaBarre.etape) {
      state = PerimetreDeLaBarre.sentier;
      _armerLeRetour();
      return;
    }
    _couperLeTemporisateur();
    state = PerimetreDeLaBarre.etape;
  }

  /// L'ECRAN A ETE TOUCHE : le compte des vingt secondes repart de zero.
  ///
  /// Sans effet quand la barre est deja sur l'etape — il n'y a alors aucun
  /// retour en attente, et toucher la carte ne doit rien declencher.
  void toucheEcran() {
    if (state != PerimetreDeLaBarre.sentier) return;
    _armerLeRetour();
  }

  /// Revient a l'etape immediatement, temporisateur coupe.
  ///
  /// Sert a la fin de la marche : les chiffres de l'arrivee se lisent sur
  /// l'etape, pas sur une vue sentier laissee ouverte.
  void revenirALEtape() {
    _couperLeTemporisateur();
    state = PerimetreDeLaBarre.etape;
  }

  void _armerLeRetour() {
    _couperLeTemporisateur();
    _retour = Timer(delaiDeRetour, () {
      _retour = null;
      state = PerimetreDeLaBarre.etape;
    });
  }

  void _couperLeTemporisateur() {
    _retour?.cancel();
    _retour = null;
  }
}

/// LE PERIMETRE AFFICHE PAR LA BARRE DE LA CARTE.
final perimetreDeLaBarreProvider =
    NotifierProvider<PerimetreDeLaBarreNotifier, PerimetreDeLaBarre>(
      PerimetreDeLaBarreNotifier.new,
    );
