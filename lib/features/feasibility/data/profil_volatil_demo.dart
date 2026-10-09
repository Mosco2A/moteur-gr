/// LE PROFIL D'UNE DEMO VIT EN MEMOIRE, ET IL MEURT AVEC ELLE (tache 760).
///
/// ---------------------------------------------------------------------------
/// CE QUI A ETE MESURE A LA RECETTE 753, ET POURQUOI LA PROMESSE ETAIT FAUSSE
/// ---------------------------------------------------------------------------
///
/// L'ecran de depart de la demo affiche, mot pour mot : « En demo, le depart
/// lance une randonnee simulee : rien n'est enregistre. » Les felicitations
/// disent : « Rien n'a ete enregistre : c'etait une simulation. »
///
/// Pendant la recette, un profil (45 ans, 178 cm, 75 kg) et une randonnee
/// passee ont ete saisis EN DEMO. Apres la sortie de la demo, apres un ARRET
/// FORCE de l'application et apres relance, LES DEUX ETAIENT TOUJOURS LA — et
/// la demo suivante demarrait avec son verdict de faisabilite deja calcule.
///
/// La promesse ne portait que sur la SESSION de randonnee, bien ephemere et
/// gardee par les barrieres des lots 742 et 744. Mais tout ce que le randonneur
/// SAISIT passait par les chemins ordinaires : [HikerProfileFile] ecrivait le
/// fichier protege et le miroir Drift sans jamais demander si une demo etait
/// en cours. Du point de vue de Christophe la promesse etait fausse.
///
/// ---------------------------------------------------------------------------
/// POURQUOI LA MEMOIRE, ET PAS UN ESPACE A PART QU'ON JETTE EN SORTANT
/// ---------------------------------------------------------------------------
///
/// Les deux voies tenaient la promesse sur le papier. Celle-ci la tient AUSSI
/// quand l'application meurt sans prevenir, et c'est ce qui l'a emportee :
///
///  1. CHRISTOPHE A FAIT UN ARRET FORCE. Un espace a part POSE SUR LE DISQUE
///     survit a un `kill` : il faudrait le balayer au demarrage suivant, donc
///     ecrire une routine de nettoyage qui peut elle-meme echouer, et accepter
///     qu'entre-temps un age, une taille et un poids — des donnees de l'article
///     9, que l'application declare elle-meme comme relevant de la sante —
///     restent en clair sur le telephone. La memoire, elle, part avec le
///     processus, sans routine, sans condition et sans exception.
///  2. IL N'Y A RIEN A NETTOYER, DONC RIEN A OUBLIER DE NETTOYER. « La demo
///     suivante repart vierge » n'est pas tenu par du code de purge : il tient
///     a ceci qu'un nouveau magasin volatil est construit a chaque entree en
///     demo (le provider se reconstruit sur [enDemoProvider]).
///  3. C'EST LA BRANCHE « ACTIVE » DE LA REGLE QUE CHRISTOPHE A POSEE LE 30/09
///     (bug 14, voir `grise_en_demo.dart`) : « la fonction se comporte
///     EXACTEMENT comme en reel. Le changement vit en memoire et il est jete
///     a la sortie de la demo. » C'est deja le traitement du sac, du programme
///     et de la date de depart. Le profil le rejoint, il n'invente rien.
///
/// ---------------------------------------------------------------------------
/// IL NE TOUCHE PAS AU DISQUE — MEME PAS EN LECTURE, ET C'EST UN CHOIX
/// ---------------------------------------------------------------------------
///
/// Une demo part VIERGE : ce magasin commence vide et ne lit jamais le vrai
/// document. Christophe l'a demande en ces termes — « il faut que la demo
/// suivante reparte VIERGE ». Trois raisons l'emportent sur l'idee de montrer
/// la fiche deja remplie :
///
///  1. C'EST LA DEMO QU'IL A DEMANDEE LE 29/09 : « un bouton demo qui montre
///     comment marche l'appli de A a Z ». On parcourt le formulaire, on voit le
///     verdict se calculer — pas un verdict deja la avant d'avoir rien fait.
///  2. LE TELEPHONE DE CHRISTOPHE PORTE DEJA UN PROFIL ECRIT PAR LA DEMO
///     FAUTIVE. Si la demo continuait de lire le reel, sa prochaine demo
///     montrerait encore ce profil et le defaut paraitrait non corrige, alors
///     qu'il l'est. Partir vide rend le correctif visible immediatement.
///  3. LA DEMO NE LIT MEME PLUS LES DONNEES DE L'ARTICLE 9. Moins d'exposition,
///     pas seulement moins d'ecriture.
///
/// CE QUE CELA CHANGE A L'ECRAN, ET IL FAUT LE SAVOIR : le recapitulatif
/// « ce sur quoi repose la reponse » ([FeasibilityDemoInputs], bug 5a) affiche
/// « non renseigne » au debut d'une demo, puis les valeurs saisies PENDANT la
/// demo. Il ne montre plus la collecte reelle du randonneur.
///
/// TOUTES LES ECRITURES SONT DETOURNEES : [ecrire] et [effacer] ne touchent
/// que la memoire. [garantirExclusion] ne fait rien, puisqu'il n'y a aucun
/// fichier a proteger. Et [fichier] LEVE : si un chemin venait un jour demander
/// le document reel pendant une demo, il doit echouer bruyamment plutot
/// qu'ecrire en silence — c'est la lecon du defaut que ce lot corrige.
library;

import 'dart:io';

import 'hiker_profile_file.dart';

/// Le document du profil pendant une demo : VIDE au depart, tenu EN MEMOIRE, et
/// jete avec la demo.
///
/// Il herite de [HikerProfileFile] pour en avoir le type — attendu par
/// `HikerProfileRepository` — mais il n'en garde AUCUN geste : les quatre
/// methodes qui touchent au disque sont toutes redefinies.
class ProfilVolatilDeDemo extends HikerProfileFile {
  /// Construit le magasin volatil d'UNE demo.
  ProfilVolatilDeDemo();

  /// Le contenu de la demo, vide tant que rien n'a ete saisi.
  HikerProfileContent _cache = HikerProfileContent.vide;

  /// Vrai des que la demo a MODIFIE quelque chose — les gardes s'en servent
  /// pour verifier qu'une saisie a bien ete prise en compte EN MEMOIRE, sans
  /// jamais aller voir le disque.
  bool get aEteModifie => _modifie;
  bool _modifie = false;

  /// Lit le profil de la demo : la memoire, et rien d'autre.
  @override
  Future<HikerProfileContent> lire() async => _cache;

  /// N'ECRIT RIEN. La saisie de la demo reste en memoire.
  @override
  Future<void> ecrire(HikerProfileContent contenu) async {
    _cache = contenu.estVide ? HikerProfileContent.vide : contenu;
    _modifie = true;
  }

  /// N'EFFACE RIEN SUR LE DISQUE. Le droit a l'effacement exerce PENDANT une
  /// demo ne doit pas emporter la vraie fiche du randonneur : il ne vide que la
  /// fiche de la demo. La vraie porte de sortie reste ouverte hors demo.
  @override
  Future<void> effacer() async {
    _cache = HikerProfileContent.vide;
    _modifie = true;
  }

  /// RIEN A PROTEGER : aucun fichier n'est ecrit pendant une demo, donc aucun
  /// attribut d'exclusion n'est a reposer.
  @override
  Future<void> garantirExclusion() async {}

  /// LEVE TOUJOURS, ET C'EST UNE BARRIERE, PAS UNE LIMITE.
  ///
  /// Le defaut que ce lot corrige est un chemin d'ecriture qu'on avait oublie
  /// de garder. Rendre ici le vrai document laisserait un futur appelant ecrire
  /// en silence pendant une demo ; lever le fait tomber au premier essai, dans
  /// les tests, avant le telephone de Christophe.
  @override
  Future<File> fichier() async {
    throw UnsupportedError(
      'ProfilVolatilDeDemo: aucun document n est ouvert pendant une demo '
      '(tache 760). La demo ne lit et n ecrit qu en memoire.',
    );
  }
}
