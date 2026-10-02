/// Une cle UNIQUE, non prefixee par un sentier, parce que c'est une decision de
/// PERSONNE — et une cle neuve, pas l'ancienne renommee.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/copie_sauvegardable_base_service.dart';
import '../data/copie_sauvegardable_fiche_service.dart';

/// Cle SharedPreferences du refus de sauvegarde systeme — TOUTES LES DONNEES
/// CONFIEES (tache 617).
///
/// UNE SEULE cle, non prefixee par un sentier : c'est une decision de PERSONNE,
/// pas de trek.
///
/// ET C'EST UNE CLE NEUVE, PAS L'ANCIENNE RENOMMEE — LE POINT LE PLUS DELICAT DU
/// LOT. La tache 612 posait `refus_sauvegarde_systeme_sante`, et la question qui
/// l'accompagnait ne parlait QUE de la fiche medicale. Reutiliser cette cle
/// ferait qu'un randonneur qui avait decoche POUR SA SEULE FICHE MEDICALE se
/// retrouverait, sans avoir rien fait, a avoir accepte la sauvegarde de son
/// journal, de son profil, de sa progression et de ses photos. Un consentement
/// donne pour un objet ne s'etend pas tout seul a un objet plus large : c'est le
/// fond du RGPD, et c'est aussi le sens litteral de la phrase de Christophe
/// (« sauf si le client decoche volontairement » — volontairement, pour CELA).
///
/// La question est donc REPOSEE une fois a tout le monde, et le defaut qui
/// s'applique entre-temps est le refus. Le prix est une question de plus pour
/// ceux qui avaient deja repondu ; l'alternative etait d'elargir leur
/// consentement a leur place.
const String kRefusSauvegardeSystemeKey = 'refus_sauvegarde_systeme_donnees';

/// L'ANCIENNE CLE DE LA TACHE 612, SUPPRIMEE A LA PREMIERE LECTURE.
///
/// Elle n'est pas seulement ignoree : elle est EFFACEE. Une cle qui reste
/// derriere elle est une trace du geste passe (meme motif que la tache 566, ou un
/// profil a zero horodate subsistait apres un refus), et surtout elle ferait
/// croire au prochain lecteur qu'il existe deux decisions quand il n'y en a
/// qu'une.
const String kRefusSauvegardeSystemeKeyLegacy =
    'refus_sauvegarde_systeme_sante';

/// LE REFUS EST LE DEFAUT, ET IL L'EST AVANT MEME QUE LE RANDONNEUR AIT VU LA
/// CASE (tache 612, decision de Christophe du 28/09 10:49 ; ELARGIE A TOUTES LES
/// DONNEES CONFIEES par sa regle generale du 28/09 14:31, verbatim : « on ne
/// partage aucune donnee confiee sauf si le client decoche volontairement »).
///
/// POURQUOI LE DEFAUT EST VRAI ET NON NULL. Une case pre-cochee qui n'aurait
/// d'effet qu'apres avoir ete VUE ne protegerait que les randonneurs attentifs.
/// Christophe a demande que « la protection ne depende pas de sa vigilance » :
/// tant qu'aucune decision n'est enregistree, le refus s'applique. Il n'y a donc
/// pas d'etat « pas encore repondu » cote protection — il n'y en a un que pour
/// savoir s'il faut encore POSER la question
/// ([decisionSauvegardeSystemePriseProvider]).
const bool kRefusSauvegardeSystemeParDefaut = true;

/// Etat persiste du refus de sauvegarde systeme de TOUTES les donnees confiees.
class RefusSauvegardeSystemeNotifier extends Notifier<bool> {
  /// Vrai des qu'une ecriture LOCALE a eu lieu : la relecture initiale ne doit
  /// alors plus ecraser l'etat (elle est arrivee trop tard). Meme discipline que
  /// `HealthPrepareStepsNotifier`, et pour la meme raison.
  bool _ecritureLocale = false;

  @override
  bool build() {
    _relire();
    return kRefusSauvegardeSystemeParDefaut;
  }

  Future<void> _relire() async {
    final prefs = await SharedPreferences.getInstance();
    // L'ANCIENNE CLE PART, ET AVANT TOUT LE RESTE. Voir
    // [kRefusSauvegardeSystemeKeyLegacy] : ne pas la LIRE est une decision, ne
    // pas l'EFFACER serait un oubli.
    if (prefs.containsKey(kRefusSauvegardeSystemeKeyLegacy)) {
      await prefs.remove(kRefusSauvegardeSystemeKeyLegacy);
    }
    if (!ref.mounted || _ecritureLocale) return;
    state =
        prefs.getBool(kRefusSauvegardeSystemeKey) ??
        kRefusSauvegardeSystemeParDefaut;
    // ON CONVERGE LE DISQUE A CHAQUE OUVERTURE, ET C'EST CE QUI REND LES AUTRES
    // APPELS SUREMENT NON BLOQUANTS.
    //
    // Les ecrans lancent [realignerLesCopies] SANS L'ATTENDRE : la confirmation
    // d'un enregistrement ne doit jamais dependre d'une ecriture de fichier. Le
    // prix de ce choix serait un trou : une application fermee juste apres un
    // effacement pourrait laisser sa copie derriere elle. Ce re-alignement-ci le
    // bouche. La regle n'est donc pas « chaque geste est transactionnel » mais
    // « le disque converge vers la decision a chaque ouverture », ce qui tient
    // meme apres un plantage.
    await realignerLesCopies();
  }

  /// Enregistre la decision du randonneur et ALIGNE LE DISQUE DESSUS.
  ///
  /// La bascule n'est pas un affichage : elle fait apparaitre ou disparaitre les
  /// COPIES sauvegardables. Sans cet appel, re-cocher le refus laisserait
  /// derriere lui des copies que la sauvegarde du telephone continuerait
  /// d'emporter — un refus qui laisse une trace de passage n'est pas un refus
  /// (meme defaut que celui mesure au LOT Y).
  Future<void> definir({required bool refuse}) async {
    _ecritureLocale = true;
    state = refuse;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kRefusSauvegardeSystemeKey, refuse);
    await _appliquerAuxDeuxCopies(refuse: refuse);
    // LA QUESTION EST TRANCHEE, ON CESSE DE LA POSER. Sans cette invalidation,
    // [decisionSauvegardeSystemePriseProvider] garderait sa reponse en cache et
    // une deconnexion suivie d'une reconnexion dans la meme session reposerait la
    // question a quelqu'un qui vient d'y repondre.
    if (ref.mounted) ref.invalidate(decisionSauvegardeSystemePriseProvider);
  }

  /// RE-ALIGNE LES COPIES SUR LA DONNEE, sans changer la decision.
  ///
  /// Appele apres chaque ecriture de la fiche (enregistrement, effacement) et a
  /// chaque ouverture : les copies SUIVENT la donnee, elles ne lui survivent pas.
  /// Une fiche effacee alors que le randonneur avait decoche laisserait sinon sa
  /// copie intacte, et le changement de telephone la ferait revenir.
  Future<void> realignerLesCopies() => _appliquerAuxDeuxCopies(refuse: state);

  /// LES DEUX COPIES SONT TRAITEES ENSEMBLE, ET AUCUNE NE PEUT FAIRE ECHOUER
  /// L'AUTRE.
  ///
  /// La fiche medicale et la base sont deux fichiers, deux services, deux modes
  /// d'echec. Aucun des deux `appliquer` ne leve (c'est verifie par leurs tests) :
  /// un disque plein sur la copie de la base ne peut donc pas empecher la
  /// SUPPRESSION de la copie de la fiche, et c'est le sens qui compte — celui ou
  /// il resterait de la donnee sur le disque apres un refus.
  ///
  /// `ref.mounted` EST VERIFIE AVANT CHAQUE LECTURE, ET C'EST UN DEFAUT MESURE,
  /// PAS UNE PRECAUTION DE STYLE. Ce re-alignement est lance depuis [_relire],
  /// c'est-a-dire depuis une construction de provider, et il traverse DEUX
  /// attentes de fichier. Une application (ou un test) qui se ferme entre les
  /// deux laisse un `ref` dispose, et `ref.read` LEVE alors : « Cannot use the
  /// Ref [...] after it has been disposed ». Le defaut existait deja dans la
  /// version de la tache 612 ; l'ecriture de ce lot a simplement allonge la
  /// fenetre (une attente de plus, pour effacer l'ancienne cle) et un test l'a
  /// attrape. Il n'y a rien a rattraper dans ce cas : le disque sera re-aligne a
  /// la prochaine ouverture, c'est la propriete meme de la convergence.
  Future<void> _appliquerAuxDeuxCopies({required bool refuse}) async {
    if (!ref.mounted) return;
    await ref
        .read(copieSauvegardableFicheServiceProvider)
        .appliquer(refuse: refuse);
    if (!ref.mounted) return;
    await ref
        .read(copieSauvegardableBaseServiceProvider)
        .appliquer(refuse: refuse);
  }
}

/// Refus de sauvegarde systeme de toutes les donnees confiees (persiste, defaut :
/// refuse).
final refusSauvegardeSystemeProvider =
    NotifierProvider<RefusSauvegardeSystemeNotifier, bool>(
      RefusSauvegardeSystemeNotifier.new,
    );

/// Vrai quand le randonneur a DEJA tranche, faux quand la question reste a poser.
///
/// Distinct de [refusSauvegardeSystemeProvider] : celui-la dit ce qui s'applique
/// (refus par defaut), celui-ci dit s'il faut encore poser la question. Confondre
/// les deux ferait l'un des deux defauts : soit reposer la question a chaque
/// ouverture, soit ne pas proteger avant de l'avoir posee.
///
/// TACHE 637 — IL N'Y A QU'UN SEUL LECTEUR DE CE PROVIDER, ET CE N'EST PAS UN
/// HASARD QU'IL SOIT SEUL.
///
/// Le second rapport Crashlytics du build 6 (`Cannot use the Ref of
/// FutureProvider<bool> after it has been disposed`,
/// `riverpod/src/core/ref.dart:240`) portait sur ce provider. Il n'est PAS une
/// cause : c'est une CONSEQUENCE du plantage principal — l'application mourait
/// pendant que ce `build` attendait `SharedPreferences.getInstance()`, donc le
/// `ProviderScope` etait detruit en pleine attente. Un seul cas contre 28 pour
/// le plantage lui-meme, et il disparait avec lui.
///
/// UNE PISTE A ETE MESUREE PUIS ABANDONNEE : `ref.keepAlive()` ne fait PAS
/// survivre une lecture invalidee en vol. Avec Riverpod 3.3.2, `invalidate`
/// pendant un `build` en attente laisse le `Future` de `.future` EN PLAN — ni
/// valeur, ni erreur (mesure dans
/// `test/comportement/plantage_null_check_refus_sauvegarde_637_test.dart`).
/// Aucune garde locale ne rattrape cela, donc la course est fermee en amont :
/// [RefusSauvegardeSystemeDialog.poserSiNecessaire] tient un verrou qui garantit
/// une seule lecture en vol a la fois, et [definir] — seul appelant de
/// `invalidate` — tourne DANS ce dialogue, donc apres la resolution de cette
/// lecture.
final decisionSauvegardeSystemePriseProvider = FutureProvider<bool>((
  ref,
) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.containsKey(kRefusSauvegardeSystemeKey);
});
