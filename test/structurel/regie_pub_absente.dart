// UN APPAREIL SANS REGIE PUBLICITAIRE (tache 595).
//
// POURQUOI CE FICHIER EXISTE, ET C'EST LA DECOUVERTE DU LOT PUB. Brancher la
// banniere a rendu le module publicitaire ATTEIGNABLE depuis des ecrans
// ordinaires — le cockpit, le catalogue. Or dans un test de widgets, le SDK
// Google Mobile Ads n'existe pas : ses canaux de plateforme ne sont branches a
// personne, et un canal sans interlocuteur ne rend pas `null`, il fait lever
// `MissingPluginException` A UN ENDROIT QUI NE L'ATTRAPE PAS.
//
// LA MECANIQUE EXACTE, parce qu'elle est contre-intuitive. Le SDK expose
// `ConsentInformation.requestConsentInfoUpdate(params, succes, echec)` : une
// API a callbacks dont l'implementation n'attrape que `PlatformException`. La
// `MissingPluginException` d'un test passe donc a travers, et NI le callback de
// succes NI celui d'echec ne sont appeles. Le `Completer` que
// `AdsConsentService` attend derriere n'est jamais complete — seul son garde-fou
// de six secondes rend la main. Six secondes de temps REEL, qu'un test de
// widgets ne fait jamais s'ecouler : `flutter test` echoue sur
// « A Timer is still pending even after the widget tree was disposed », un
// message qui n'apprend rien sur l'application.
//
// CE QU'ON MODELISE ICI, dans l'esprit exact de `brancherLesPlugins`
// (`parcours_reel.dart`, tache 579) : un appareil HONNETE ET DEMUNI. Il repond
// toujours, et il repond « je n'ai pas de regie publicitaire ». Consequence
// utile et voulue : `canRequestAds` rend `false`, donc AUCUNE banniere n'est
// demandee, donc aucun test d'ecran ne mesure par accident le comportement
// d'une publicite. Un test qui veut, lui, verifier la banniere fournit sa
// propre regie simulee (`test/comportement/pub_v1_595_test.dart`).
//
// POURQUOI UN GESTIONNAIRE DE MESSAGES BRUT ET PAS `setMockMethodCallHandler`.
// Les deux canaux du SDK utilisent des codecs MAISON (`UserMessagingCodec`,
// `AdMessageCodec`) que le paquet n'exporte pas : un gestionnaire d'appels
// construit avec le codec standard echouerait a DECODER la requete, dont les
// arguments portent des objets de types personnalises. On lit donc uniquement
// la PREMIERE valeur de l'enveloppe — le nom de la methode, une chaine que tout
// codec standard sait lire — et on ignore les arguments. La reponse, elle, ne
// contient que `null`, un booleen ou un entier : son encodage est identique
// dans les deux codecs.
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Canal des publicites (bannieres, recompensees, initialisation du SDK).
const _canalPub = 'plugins.flutter.io/google_mobile_ads';

/// Canal du consentement publicitaire (User Messaging Platform).
const _canalConsentementPub = 'plugins.flutter.io/google_mobile_ads/ump';

/// Declare un appareil SANS regie publicitaire pour la duree du test.
///
/// A appeler dans tout test qui monte un ecran susceptible de porter un
/// emplacement publicitaire (le cockpit, le catalogue, ou l'application
/// reelle). Retablit l'etat d'origine en fin de test.
void brancherAucuneRegiePub() {
  final messager =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void repondre(String canal, Object? Function(String methode) reponse) {
    messager.setMockMessageHandler(canal, (ByteData? message) async {
      final methode = _nomDeLaMethode(message);
      return const StandardMethodCodec().encodeSuccessEnvelope(
        reponse(methode),
      );
    });
    addTearDown(() => messager.setMockMessageHandler(canal, null));
  }

  // LE CONSENTEMENT PUBLICITAIRE : un appareil sans regie n'a rien a demander,
  // et surtout il n'a pas le DROIT de demander une publicite.
  repondre(_canalConsentementPub, (methode) {
    switch (methode) {
      // La seule reponse qui compte : pas de regie, donc aucune banniere ne
      // sera jamais demandee. Tout le reste en decoule.
      case 'ConsentInformation#canRequestAds':
        return false;
      case 'ConsentInformation#isConsentFormAvailable':
        return false;
      // 0 = statut inconnu / options de confidentialite non requises.
      case 'ConsentInformation#getConsentStatus':
      case 'ConsentInformation#getPrivacyOptionsRequirementStatus':
        return 0;
      // `requestConsentInfoUpdate`, `reset`, les formulaires : rien a rendre.
      default:
        return null;
    }
  });

  // LES PUBLICITES elles-memes. Rien ne devrait les atteindre (le consentement
  // ci-dessus l'interdit deja), mais un canal muet est precisement ce qui a
  // produit le defaut qu'on repare : on ne laisse plus de canal muet.
  repondre(_canalPub, (methode) => null);
}

/// Le nom de la methode d'une enveloppe d'appel, sans decoder les arguments.
///
/// Une enveloppe standard est « valeur(nom) puis valeur(arguments) » : lire la
/// premiere valeur suffit, et evite d'avoir besoin du codec maison du SDK pour
/// les arguments (cf. l'en-tete de ce fichier).
String _nomDeLaMethode(ByteData? message) {
  if (message == null) return '';
  try {
    return const StandardMessageCodec().readValue(ReadBuffer(message))
            as String? ??
        '';
  } on Object {
    return '';
  }
}
