/// LES ADRESSES PUBLIQUES DES TEXTES LEGAUX DE STEPWAYS (tache 642).
///
/// Decision de Christophe du 30/09 13:39 : « Regarde celle de GR20 et fais
/// pareil ! ». La politique de confidentialite et les conditions de StepWays
/// sont donc hebergees comme celles du GR20 — sur l'hebergement Firebase du
/// projet `gr20-app`, domaine personnalise `only1cent.com`, sous le prefixe
/// `/stepways/` qui separe les deux produits.
///
/// POURQUOI ICI, ET PAS DANS `TrailConfig`. Ces adresses ne dependent pas du
/// sentier : la politique decrit ce que fait L'APPLICATION (un consentement,
/// un identifiant, un hebergeur), pas ce que fait le Mare a Mare. Les quatre
/// configurations de sentier portaient quatre litteraux differents, tous en
/// `https://example.org/...` : quatre adresses d'exemple, donc quatre
/// mensonges, et aucune des quatre ne repondait. Elles pointent desormais
/// toutes sur ces constantes-ci. Le champ `TrailConfig.privacyPolicyUrl` reste
/// parametrique — un sentier tiers pourra toujours fournir la sienne — mais
/// les sentiers de la maison n'ont plus qu'une seule verite a maintenir.
///
/// DEUX LANGUES PUBLIEES, CINQ LANGUES DANS L'APPLICATION. Seules les versions
/// francaise et anglaise sont en ligne. Un randonneur en allemand, espagnol ou
/// italien recoit la version ANGLAISE : une page dans une langue qu'il a des
/// chances de lire vaut mieux qu'un 404, et inventer une traduction juridique
/// non relue serait pire que les deux.
///
/// Un test de garde (`test/core/branding/urls_legales_642_test.dart`) interdit
/// le retour de `example.org` dans les configurations et verifie que ces
/// adresses restent en `https`.
abstract final class StepwaysLegal {
  /// Racine des pages legales publiees de StepWays.
  static const String base = 'https://only1cent.com/stepways';

  /// Politique de confidentialite — version francaise.
  static const String privacyPolicyFr = '$base/privacy';

  /// Politique de confidentialite — version anglaise.
  static const String privacyPolicyEn = '$base/privacy-en';

  /// Conditions d'utilisation et regles de moderation — version francaise.
  static const String conditionsFr = '$base/conditions';

  /// Conditions d'utilisation et regles de moderation — version anglaise.
  static const String conditionsEn = '$base/conditions-en';

  /// L'adresse par defaut inscrite dans les configurations de sentier et
  /// publiee sur les fiches store : la version francaise, langue de l'editeur.
  static const String privacyPolicyUrl = privacyPolicyFr;

  /// La politique dans la langue du randonneur — francais si son application
  /// est en francais, anglais dans tous les autres cas.
  static String privacyPolicyPour(String codeLangue) =>
      codeLangue == 'fr' ? privacyPolicyFr : privacyPolicyEn;

  /// Les conditions dans la langue du randonneur — meme regle.
  static String conditionsPour(String codeLangue) =>
      codeLangue == 'fr' ? conditionsFr : conditionsEn;
}
