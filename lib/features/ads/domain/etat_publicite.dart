/// Pourquoi ce sentier est sans publicite : l'une des trois raisons, jamais
/// deux, et jamais « parce que ».
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/monetization_service.dart';

/// POURQUOI CE SENTIER EST SANS PUBLICITE — l'une des trois raisons, jamais
/// deux, jamais « parce que ».
///
/// LA DEMANDE DE CHRISTOPHE, MOT POUR MOT (30/09 12:41, DEM-260930-1241) : « Il
/// faut que l on fasse la diff entre = je suis abonne et je n ai pas de pub en
/// prepa, j ai achete un trek sans pub, je suis en prepa avec pub ».
///
/// Trois etats a rendre VISUELLEMENT DISTINCTS. Un booleen « sans pub » ne peut
/// pas les distinguer : il dit qu'il n'y a pas de publicite, pas POURQUOI. Or
/// c'est le pourquoi que Christophe veut lire — et c'est aussi ce qui decide de
/// la suite : un abonne n'a rien a acheter, un acheteur non plus, un randonneur
/// en preparation gratuite peut acheter OU retirer les pubs.
enum RaisonSansPub {
  /// ABONNE : sans publicite PARTOUT, tant qu'il paie (regle d'or #99404).
  abonne,

  /// TREK ACHETE : sans publicite sur CE sentier, sans echeance.
  achete,

  /// RECOMPENSE VIDEO : sans publicite pendant 24 h, avec un compte a rebours.
  ///
  /// « video 24h retire la pub prepa pendant 24h point » (DEM-260930-1241) :
  /// rien d'autre — ni etapes, ni droits, ni realisation.
  video24h,
}

/// L'ETAT PUBLICITAIRE D'UN SENTIER, tel que l'ecran doit le montrer.
///
/// CE QUE CETTE CLASSE N'EST PAS : une seconde regle. La decision « y a-t-il une
/// publicite » reste portee par la SOURCE UNIQUE
/// [MonetizationService.isNoAdsActive]. Ici on ne fait que DIRE LAQUELLE des
/// trois exceptions a repondu, parce que l'ecran doit l'ecrire, et qu'un ecran
/// qui le recalculerait finirait par le recalculer autrement.
class EtatPublicite {
  const EtatPublicite({required this.raison, this.finDeLaRecompense});

  /// UNE PUBLICITE VA S'AFFICHER : aucune des trois exceptions ne joue.
  static const avecPub = EtatPublicite(raison: null);

  /// `null` quand une publicite va s'afficher.
  final RaisonSansPub? raison;

  /// Echeance de la recompense de 24 h — renseignee POUR ELLE SEULE, parce
  /// qu'elle est la seule des trois a expirer. C'est ce qui porte le compte a
  /// rebours demande par Christophe.
  final DateTime? finDeLaRecompense;

  /// Vrai quand une publicite va effectivement s'afficher.
  ///
  /// C'est la condition d'affichage de l'icone pub et du bouton « Retirer les
  /// pubs » (DEM-260930-1223 et 1224) : ni l'un ni l'autre n'apparait quand il
  /// n'y a rien a annoncer ni rien a retirer.
  bool get pubAffichee => raison == null;

  /// Vrai quand le sans-pub est DEFINITIF pour ce sentier (abonnement en cours
  /// ou achat). Sert a ne pas proposer de retirer ce qui est deja retire.
  bool get sansPubDurable =>
      raison == RaisonSansPub.abonne || raison == RaisonSansPub.achete;
}

/// L'etat publicitaire du sentier [trailId], lu sur la source unique.
///
/// L'ORDRE DES TROIS TESTS EST UNE DECISION, PAS UN HASARD. Quand plusieurs
/// exceptions jouent en meme temps (un abonne qui a aussi achete le sentier, ou
/// qui a regarde une video), on annonce la plus FORTE et la plus DURABLE :
///   1. ABONNE — il paie pour n'avoir de publicite nulle part ; c'est ce qu'il
///      veut lire, et c'est vrai sur tous les sentiers ;
///   2. ACHETE — sans echeance, mais limite a ce sentier ;
///   3. VIDEO 24 H — la plus faible : elle expire, et on affiche jusqu'a quand.
/// Annoncer la video a un abonne lui ferait croire que son abonnement est fini
/// dans 24 h.
///
/// REACTIF, comme la banniere elle-meme : un achat, une souscription ou une
/// video repeignent la carte sans changer d'ecran. On depend des memes signaux
/// vivants que [isDemoModeProvider] (les droits du trek) via
/// [monetizationReadyProvider], et le provider est `autoDispose` — la question
/// est reposee a chaque montage.
final etatPubliciteProvider = FutureProvider.autoDispose
    .family<EtatPublicite, String>((ref, trailId) async {
      final monetisation = await ref.watch(monetizationReadyProvider.future);
      // On relit le droit du trek pour que l'achat repeigne la carte : c'est le
      // meme signal que celui du mode demo, deja observe par le catalogue.
      ref.watch(isDemoModeProvider(trailId));

      if (await monetisation.isSubscriberActive()) {
        return const EtatPublicite(raison: RaisonSansPub.abonne);
      }
      if (await monetisation.accessFor(trailId) == TrailAccess.owned) {
        return const EtatPublicite(raison: RaisonSansPub.achete);
      }
      final fin = await monetisation.rewardNoAdsExpiresAt();
      if (fin != null) {
        return EtatPublicite(
          raison: RaisonSansPub.video24h,
          finDeLaRecompense: fin,
        );
      }
      return EtatPublicite.avecPub;
    });
