import 'package:flutter/foundation.dart';

/// OU L'ON ARRETE UN ABONNEMENT — les liens profonds des deux boutiques.
///
/// EXIGENCE DE CHRIS, 27/09 13:09, verbatim : « Et je veux un arreter votre
/// abonnement en 3 clics comme le prevoit la loi, et pas planque au fin fond de
/// l appli ».
///
/// LE DROIT, SOURCE AVANT D'ECRIRE UNE LIGNE (base #100700). Article L215-1-1 du
/// code de la consommation, cree par l'article 17 de la loi n° 2022-1158 du
/// 16 aout 2022, EN VIGUEUR DEPUIS LE 1er JUIN 2023 (modalites techniques :
/// decret n° 2023-417 du 31 mai 2023). Son premier alinea, verbatim : « Lorsqu'un
/// contrat a ete conclu par voie electronique ou a ete conclu par un autre moyen
/// et que le professionnel, au jour de la resiliation par le consommateur, offre
/// au consommateur la possibilite de conclure des contrats par voie electronique,
/// la resiliation est rendue possible selon cette modalite. » La fonctionnalite
/// doit etre GRATUITE, DIRECTE, PERMANENTE et FACILE D'ACCES, et l'interface
/// visee inclut explicitement l'application mobile. Controle DGCCRF.
///
/// ET LA CONTRAINTE QUI TIENT EN MEME TEMPS : UNE APPLICATION NE PEUT PAS
/// ANNULER ELLE-MEME. Un abonnement vendu via Google Play ou l'App Store est
/// facture PAR LA BOUTIQUE, et les deux plateformes interdisent un parcours
/// d'annulation interne qui contournerait leur facturation. Ce que l'application
/// doit faire n'est donc pas d'annuler : c'est d'OUVRIR DIRECTEMENT la page de
/// gestion des abonnements de la boutique. Un bouton qui pretendrait annuler et
/// ne ferait que journaliser serait le pire des faux succes, sur le sujet le plus
/// sensible.
///
/// CE QUE LES DEUX BOUTIQUES DEMANDENT, ET C'EST CONVERGENT AVEC LA LOI. La
/// documentation Google Play est explicite, verbatim : « Your app should include a
/// link on a settings or preferences screen that allows users to manage their
/// subscriptions ». Apple documente le meme lien de compte, et iOS 15 et suivants
/// offrent en plus une feuille NATIVE appelable depuis l'application
/// (`AppStore.showManageSubscriptions`, StoreKit) — un point d'extension noté
/// ci-dessous, qui demande du code natif et ne conditionne pas l'acces.
///
/// CE QUE CE FICHIER N'EST PAS : une promesse de remboursement. Annuler arrete le
/// renouvellement ; l'acces court jusqu'a la fin de la periode deja payee, et les
/// etapes deja creditees restent acquises a vie (regle d'or #99404).
abstract final class StoreSubscriptionLinks {
  StoreSubscriptionLinks._();

  /// Identifiant de l'application sur Google Play (`applicationId` du Gradle).
  ///
  /// Necessaire au lien PRECIS de Google (celui qui ouvre l'abonnement lui-meme
  /// plutot que la liste). Constante et non lue via `PackageInfo` : ce lien doit
  /// se construire sans aucun appel de plateforme, donc sans canal susceptible
  /// de ne pas repondre — la page d'annulation ne peut pas dependre de ca.
  static const String androidPackageName = 'com.only1cent.stepways';

  /// Page de gestion des abonnements Google Play, POUR CET ABONNEMENT.
  ///
  /// Forme documentee par Google :
  /// `https://play.google.com/store/account/subscriptions?sku=<productId>&package=<packageName>`
  static String googlePlay({required String productId}) =>
      'https://play.google.com/store/account/subscriptions'
      '?sku=$productId&package=$androidPackageName';

  /// Page de gestion des abonnements Google Play, LISTE COMPLETE.
  ///
  /// Repli quand le productId n'est pas connu : mieux vaut la liste des
  /// abonnements que rien du tout.
  static const String googlePlayAll =
      'https://play.google.com/store/account/subscriptions';

  /// Page de gestion des abonnements de l'App Store (compte connecte).
  ///
  /// POINT D'EXTENSION iOS 15+ : `AppStore.showManageSubscriptions` presente la
  /// meme page en feuille NATIVE, sans quitter l'application. Elle exige du code
  /// Swift cote plateforme ; ce lien reste la voie universelle et suffit a
  /// l'exigence d'acces direct.
  static const String appStore = 'https://apps.apple.com/account/subscriptions';

  /// LE lien a ouvrir sur CET appareil, pour CET abonnement.
  ///
  /// [plateforme] est injectable pour que le choix soit MESURABLE en test :
  /// verifier « le bouton ouvre la bonne boutique » sur les deux plateformes est
  /// exactement ce qu'un test doit pouvoir faire sans deux appareils.
  static String pour({required String productId, TargetPlatform? plateforme}) {
    final cible = plateforme ?? defaultTargetPlatform;
    if (cible == TargetPlatform.iOS || cible == TargetPlatform.macOS) {
      return appStore;
    }
    return googlePlay(productId: productId);
  }
}
