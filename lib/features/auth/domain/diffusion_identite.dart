/// Un flux d identite rend son ETAT COURANT a tout nouvel abonne, meme tardif :
/// l identite est un etat, pas un evenement qui passe.
library;

import 'dart:async';

/// LA DIFFUSION DE L IDENTITE, ET POURQUOI ELLE N EST PAS UN SIMPLE CONTROLEUR
/// (tache 781).
///
/// LE DEFAUT MESURE, LE 10/10 SUR emulator-5560 (recette 778). L ecran « Mon
/// compte » etait mort par ses DEUX portes — l icone du cockpit et l action de
/// la barre de « Mes treks ». Il affichait « Le compte n a pas repondu » apres
/// huit secondes, et « Reessayer » repartait pour le meme resultat. Et pourtant
/// le compte EXISTAIT : un seul compte etait cree au lancement (acquis de la
/// tache 771), sa fiche technique partait au serveur, et les Reglages
/// affichaient au meme instant « Services en ligne actifs » avec l identifiant
/// exact du compte cree chez Firebase. L identite etait la, le reseau marchait.
///
/// LA CAUSE. Les deux services d identite rendaient `authStateChanges` depuis
/// un `StreamController.broadcast` nu. UN FLUX DE DIFFUSION NE REJOUE RIEN :
/// qui s abonne apres coup n obtient que les evenements suivants. Or au
/// lancement personne n ecoute encore — le provider d identite n est construit
/// que lorsqu un ecran le demande. L identite s etablissait donc AVANT le
/// premier abonne, son evenement tombait dans le vide, et l abonnement tardif
/// de l ecran n obtenait plus jamais rien : le `loading` ne se terminait pas,
/// et le garde-fou de la tache 649 finissait par dire l attente. « Reessayer »
/// etait condamne par la meme cause : il se reabonnait au meme flux muet.
///
/// CE QUE CETTE CLASSE CHANGE, ET POURQUOI ELLE EST ICI. Le defaut n est pas
/// celui d un ecran, c est celui du CONTRAT de `AuthService.authStateChanges` :
/// tout lecteur present ou futur de l identite le subirait. Il se repare donc
/// au seul endroit ou le contrat se tient — la diffusion elle-meme — et les
/// deux implementations la partagent pour qu aucune ne puisse en redevenir
/// l exception.
///
/// ELLE NE REPOND PAS AVANT DE SAVOIR, et c est aussi important. Rejouer
/// « la valeur courante » sans distinguer « aucune identite encore etablie »
/// de « deconnecte » ferait emettre un `null` premature : les lecteurs
/// prendraient cette ignorance pour une deconnexion, et l attente bornee de la
/// tache 649 — qui couvre precisement le cas « aucune identite » — ne se
/// declencherait plus jamais. Tant que rien n a ete publie, le flux se TAIT ;
/// [estEtabli] est la frontiere entre les deux.
///
/// ELLE RESTE UNE DIFFUSION : plusieurs lecteurs simultanes sont attendus
/// (« Mon compte », les Reglages, les gardes de navigation), et chacun recoit
/// l etat courant a son abonnement puis la suite des changements.
class DiffusionIdentite<T extends Object> {
  T? _valeur;
  bool _etabli = false;
  final _controleur = StreamController<T?>.broadcast();

  /// L etat courant. Nul si l identite est inconnue ou absente — [estEtabli]
  /// dit lequel des deux.
  T? get valeur => _valeur;

  /// Vrai des qu un etat a ete publie au moins une fois. Avant cela, personne
  /// ne sait encore s il y a une identite, et le flux ne l affirme pas.
  bool get estEtabli => _etabli;

  /// Vrai quand la diffusion est refermee : plus personne n ecoutera. Permet a
  /// une initialisation lancee en fire-and-forget de renoncer au lieu de
  /// travailler pour rien (voir `LocalAuthService.initialize`).
  bool get estFerme => _controleur.isClosed;

  /// Publie un etat : il devient l etat courant, part aux abonnes presents, et
  /// sera rejoue a tout abonne suivant.
  ///
  /// EMETTRE DANS LE VIDE EST ICI LE COMPORTEMENT CORRECT (lecon de la tache
  /// 561, J3). L initialisation des services est lancee en fire-and-forget par
  /// `authServiceProvider`, qui ferme la diffusion a son dispose. Quand le
  /// dispose arrive pendant que l initialisation est ENCORE EN VOL — ce qui
  /// depend de la charge machine, donc « une fois sur trois » —, une emission
  /// sur un controleur ferme levait `Bad state: Cannot add new events after
  /// calling close` : une erreur asynchrone sans porteur, imputee au test
  /// suivant en test, non geree en production. Plus personne n ecoute : il n y
  /// a rien a dire.
  ///
  /// L ETAT EST RETENU MEME ALORS, et c est delibere : seule l EMISSION est
  /// abandonnee. Renoncer aussi a la valeur ferait mentir [valeur] — un
  /// appelant qui vient de publier une identite la relirait nulle, et les
  /// services la rendent a leur appelant juste apres l avoir publiee.
  void publier(T? valeur) {
    _valeur = valeur;
    _etabli = true;
    if (_controleur.isClosed) return;
    _controleur.add(valeur);
  }

  /// Le flux a donner aux lecteurs. Chaque abonnement recoit d abord l etat
  /// courant s il en existe un, puis les changements.
  ///
  /// `Stream.multi` plutot que le flux du controleur : son corps est rejoue a
  /// CHAQUE abonnement, ce qui est exactement le point — c est la que l etat
  /// courant est rendu a celui qui arrive. L ordre est garanti : l etat est
  /// pose avant que le relais des changements ne soit branche, donc aucun
  /// evenement ne peut doubler le rejeu ni se perdre entre les deux.
  ///
  /// `isBroadcast: true` tient la promesse d avant — plusieurs lecteurs a la
  /// fois, et aucun ne prive les autres.
  Stream<T?> get flux => Stream<T?>.multi((abonne) {
    if (_etabli) abonne.add(_valeur);
    final relais = _controleur.stream.listen(
      abonne.add,
      onError: abonne.addError,
      onDone: abonne.close,
    );
    abonne.onCancel = relais.cancel;
  }, isBroadcast: true);

  /// Ferme la diffusion. Les publications suivantes sont ignorees sans lever.
  void fermer() {
    _controleur.close();
  }
}
