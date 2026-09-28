import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/copie_sauvegardable_fiche_service.dart';

/// Cle SharedPreferences du refus de sauvegarde systeme des donnees medicales.
///
/// UNE SEULE cle, non prefixee par un sentier : c'est une decision de PERSONNE,
/// pas de trek — comme la fiche elle-meme.
const String kRefusSauvegardeSystemeKey = 'refus_sauvegarde_systeme_sante';

/// LE REFUS EST LE DEFAUT, ET IL L'EST AVANT MEME QUE LE RANDONNEUR AIT VU LA
/// CASE (tache 612, decision de Christophe du 28/09 10:49, verbatim : « option
/// prechochee, Je refuse la sauvegarde sur le cloud google de mes donnees
/// medicales, quand il se connecte »).
///
/// POURQUOI LE DEFAUT EST VRAI ET NON NULL. Une case pre-cochee qui n'aurait
/// d'effet qu'apres avoir ete VUE ne protegerait que les randonneurs attentifs.
/// Christophe a demande que « la protection ne depende pas de sa vigilance » :
/// tant qu'aucune decision n'est enregistree, le refus s'applique. Il n'y a donc
/// pas d'etat « pas encore repondu » cote protection — il n'y en a un que pour
/// savoir s'il faut encore POSER la question ([decisionPrise]).
const bool kRefusSauvegardeSystemeParDefaut = true;

/// Etat persiste du refus de sauvegarde systeme des donnees medicales.
class RefusSauvegardeSystemeNotifier extends Notifier<bool> {
  /// Vrai des qu'une ecriture LOCALE a eu lieu : la relecture initiale ne doit
  /// alors plus ecraser l'etat (elle est arrivee trop tard). Meme discipline que
  /// [HealthPrepareStepsNotifier], et pour la meme raison.
  bool _ecritureLocale = false;

  @override
  bool build() {
    _relire();
    return kRefusSauvegardeSystemeParDefaut;
  }

  Future<void> _relire() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted || _ecritureLocale) return;
    state = prefs.getBool(kRefusSauvegardeSystemeKey) ??
        kRefusSauvegardeSystemeParDefaut;
    // ON CONVERGE LE DISQUE A CHAQUE OUVERTURE, ET C'EST CE QUI REND LES AUTRES
    // APPELS SUREMENT NON BLOQUANTS.
    //
    // Les ecrans lancent [realignerLaCopie] SANS L'ATTENDRE : la confirmation
    // d'un enregistrement ne doit jamais dependre d'une ecriture de fichier. Le
    // prix de ce choix serait un trou : une application fermee juste apres un
    // effacement pourrait laisser sa copie derriere elle. Ce re-alignement-ci le
    // bouche. La regle n'est donc pas « chaque geste est transactionnel » mais
    // « le disque converge vers la decision a chaque ouverture », ce qui tient
    // meme apres un plantage.
    await realignerLaCopie();
  }

  /// Enregistre la decision du randonneur et ALIGNE LE DISQUE DESSUS.
  ///
  /// La bascule n'est pas un affichage : elle fait apparaitre ou disparaitre la
  /// COPIE sauvegardable de la fiche ([CopieSauvegardableFicheService]). Sans cet
  /// appel, re-cocher le refus laisserait derriere lui une copie que la
  /// sauvegarde du telephone continuerait d'emporter — un refus qui laisse une
  /// trace de passage n'est pas un refus (meme defaut que celui mesure au LOT Y).
  Future<void> definir({required bool refuse}) async {
    _ecritureLocale = true;
    state = refuse;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kRefusSauvegardeSystemeKey, refuse);
    await ref
        .read(copieSauvegardableFicheServiceProvider)
        .appliquer(refuse: refuse);
    // LA QUESTION EST TRANCHEE, ON CESSE DE LA POSER. Sans cette invalidation,
    // [decisionSauvegardeSystemePriseProvider] garderait sa reponse en cache et
    // une deconnexion suivie d'une reconnexion dans la meme session reposerait la
    // question a quelqu'un qui vient d'y repondre.
    if (ref.mounted) ref.invalidate(decisionSauvegardeSystemePriseProvider);
  }

  /// RE-ALIGNE LA COPIE SUR LA FICHE, sans changer la decision.
  ///
  /// Appele apres chaque ecriture de la fiche (enregistrement, effacement) : la
  /// copie SUIT la donnee, elle ne lui survit pas. Une fiche effacee alors que le
  /// randonneur avait decoche laisserait sinon sa copie intacte, et le
  /// changement de telephone la ferait revenir.
  Future<void> realignerLaCopie() => ref
      .read(copieSauvegardableFicheServiceProvider)
      .appliquer(refuse: state);
}

/// Refus de sauvegarde systeme des donnees medicales (persiste, defaut : refuse).
final refusSauvegardeSystemeProvider =
    NotifierProvider<RefusSauvegardeSystemeNotifier, bool>(
  RefusSauvegardeSystemeNotifier.new,
);

/// Vrai quand le randonneur a DEJA tranche, faux quand la question reste a poser.
///
/// Distinct de [refusSauvegardeSystemeProvider] : celui-la dit ce qui s'applique
/// (refus par defaut), celui-ci dit s'il faut encore poser la question a la
/// connexion. Confondre les deux ferait l'un des deux defauts : soit reposer la
/// question a chaque connexion, soit ne pas proteger avant de l'avoir posee.
final decisionSauvegardeSystemePriseProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.containsKey(kRefusSauvegardeSystemeKey);
});
