/// LA CIBLE DU LIEN DE SUIVI EST MESUREE AU MOMENT DU PARTAGE (tache 623, GO-73).
///
/// ---------------------------------------------------------------------------
/// POURQUOI CE FICHIER EXISTE, ET CE N'EST PAS POUR CORRIGER UNE ADRESSE
/// ---------------------------------------------------------------------------
///
/// `FollowLinksConfig` portait une adresse en dur qui rendait 404. Corriger
/// l'adresse n'aurait ferme que l'incident ; ce fichier ferme le DEFAUT. Le
/// defaut, c'est qu'un randonneur pouvait partager sa position, croire que ses
/// proches le suivaient, marcher toute la journee — et que rien, absolument
/// rien, ne le lui disait. Une adresse se retrompe. Un silence, non : il faut
/// qu'une mesure passe devant.
///
/// C'est le meme motif que la tache 615 appelait un FAUX SUCCES : l'application
/// declarait tenue une promesse qu'elle n'avait pas verifiee.
///
/// ---------------------------------------------------------------------------
/// CINQ VERDICTS, ET AUCUN N'EST UN BOOLEEN — LA LECON DE LA TACHE 615
/// ---------------------------------------------------------------------------
///
/// `ResultatExclusionIcloud` a pose la regle dans ce depot : un booleen
/// confondrait « je n'avais rien a faire » avec « j'ai rate ». Ici il y a CINQ
/// situations reellement distinctes, et deux d'entre elles ne sont pas des
/// echecs du tout :
///
///  * [DisponibiliteCibleSuivi.nonConfiguree] — le canal n'a pas d'adresse dans
///    ce build. Ce n'est pas une panne, c'est une fonctionnalite absente, et le
///    randonneur doit lire autre chose qu'un message d'erreur reseau.
///  * [DisponibiliteCibleSuivi.reseauIndisponible] — NOUS n'avons pas pu
///    DEMANDER. Declarer « injoignable » ici serait un FAUX ECHEC, l'exacte
///    image inverse du defaut qu'on corrige : la cible peut etre parfaitement
///    vivante et le randonneur simplement dans un vallon sans reseau.
///  * [DisponibiliteCibleSuivi.nonVerifiable] — la cible n'est pas une adresse
///    web (un lien profond `xxx://...`). On ne peut pas l'interroger, et on ne
///    fait PAS semblant.
///  * [DisponibiliteCibleSuivi.injoignable] — la cible a repondu, et elle a
///    repondu non. C'est le cas mesure le 28/09 : 404.
///  * [DisponibiliteCibleSuivi.joignable] — la cible a repondu oui.
///
/// ---------------------------------------------------------------------------
/// L'ORDRE DES TROIS CONTROLES EST LA PARTIE QUI COMPTE
/// ---------------------------------------------------------------------------
///
///  1. LA CONFIGURATION, sans rien toucher. Un canal sans adresse ne merite ni
///     appel reseau ni appel de plateforme.
///  2. LA FORME DE L'ADRESSE, sans rien toucher. Un lien profond n'est pas une
///     adresse web : l'interroger en HTTP n'aurait aucun sens.
///  3. LA CONNECTIVITE, puis SEULEMENT APRES l'appel reseau.
///
/// CET ORDRE EST AUSSI UNE GARDE DE TEST, ET ELLE VIENT D'UNE MESURE DE LA TACHE
/// 612 reprise par la 615 : un appel a un canal de plateforme sans interlocuteur
/// ne rend jamais la main dans le temps feint d'un test de widgets, et
/// `ConnectivityMonitor` parle a un greffon. Comme le depot ne porte AUCUNE
/// adresse (voir `FollowLinksConfig`), le controle 1 arrete tout des la premiere
/// ligne dans `flutter test` : aucun appel reseau, aucun appel de greffon, sur
/// toute la suite. Un test de ce lot le prouve explicitement au lieu de l'esperer.
///
/// ---------------------------------------------------------------------------
/// POURQUOI UN GET ET PAS UN HEAD
/// ---------------------------------------------------------------------------
///
/// Un hebergeur peut repondre a un `HEAD` et refuser le `GET` correspondant :
/// le verdict serait alors un faux succes, ce que ce fichier existe pour
/// empecher. On demande donc ce que le proche demandera vraiment. La page de
/// suivi est une page, pas un fichier lourd, et l'appel est borne par
/// [delaiMax].
library;

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../../../core/config/follow_links_config.dart';
import '../../../core/network/connectivity_monitor.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// CE QUE LA CIBLE DU LIEN A REELLEMENT REPONDU — voir l'en-tete du fichier pour
/// la raison de chacune des cinq valeurs.
enum DisponibiliteCibleSuivi {
  /// La cible a repondu, et elle repond oui : un proche pourra suivre.
  joignable,

  /// Ce canal n'a pas d'adresse dans ce build. Pas une panne : une absence.
  nonConfiguree,

  /// La cible a repondu, et elle repond non (404, 500...). C'est l'etat mesure
  /// le 28/09 pour l'ancienne adresse en dur.
  injoignable,

  /// La cible n'est pas une adresse web : on ne peut pas l'interroger, et on ne
  /// fait pas semblant de l'avoir fait.
  nonVerifiable,

  /// Nous n'avons pas pu DEMANDER (pas de reseau). Jamais confondu avec
  /// [injoignable] : ce serait un faux echec.
  reseauIndisponible,
}

/// LE VERDICT COMPLET, AVEC CE QUI PERMET DE L'EXPLIQUER.
///
/// Le code HTTP est conserve parce qu'un journal qui dit « injoignable » sans
/// dire 404 ne permet pas de distinguer « rien n'est deploye » de « le serveur
/// est tombe » — et ce sont deux actions differentes.
class VerdictCibleSuivi {
  const VerdictCibleSuivi({
    required this.canal,
    required this.disponibilite,
    this.url,
    this.codeHttp,
  });

  /// Le canal sur lequel porte ce verdict.
  final CanalSuivi canal;

  /// Ce que la cible a repondu.
  final DisponibiliteCibleSuivi disponibilite;

  /// L'adresse reellement interrogee, ou `null` si le canal n'est pas configure.
  final String? url;

  /// Le code de reponse HTTP, quand il y en a eu un.
  final int? codeHttp;

  /// Vrai UNIQUEMENT quand la cible a repondu oui. Tout le reste — absence,
  /// doute, panne — vaut faux : c'est ce qui empeche le lien de mourir en
  /// silence.
  bool get joignable => disponibilite == DisponibiliteCibleSuivi.joignable;

  @override
  String toString() => 'VerdictCibleSuivi(${canal.name}, '
      '${disponibilite.name}${codeHttp != null ? ', HTTP $codeHttp' : ''})';
}

/// INTERROGE LA CIBLE D'UN LIEN DE SUIVI, ET REND UN VERDICT HONNETE.
///
/// Voir l'en-tete du fichier pour le raisonnement entier. Cette classe ne sait
/// rien des sessions de suivi : elle prend un canal et une adresse. C'est
/// volontaire, comme pour `ExclusionSauvegardeIcloud` qui ne sait rien de la
/// fiche medicale.
class VerificateurCibleSuivi {
  VerificateurCibleSuivi({
    http.Client? httpClient,
    ConnectivityMonitor? connectivityMonitor,
  })  : _http = httpClient ?? http.Client(),
        _connectivite = connectivityMonitor ?? ConnectivityMonitor();

  final http.Client _http;
  final ConnectivityMonitor _connectivite;

  /// DELAI MAXIMAL DE LA MESURE.
  ///
  /// Ce n'est pas un reglage de performance : c'est le refus qu'une cible qui ne
  /// repond pas puisse bloquer le geste de partage. Au-dela, le verdict est
  /// [DisponibiliteCibleSuivi.injoignable] — une cible qui met plus de cinq
  /// secondes a dire bonjour ne servira pas un proche inquiet.
  static const Duration delaiMax = Duration(seconds: 5);

  /// Les schemas d'adresse qu'on sait interroger.
  static const List<String> schemasWeb = ['http', 'https'];

  /// MESURE LA CIBLE DU CANAL, SANS JAMAIS LEVER.
  ///
  /// Ne leve jamais : elle est appelee dans le geste de partage du randonneur.
  /// Une exception ici ferait perdre le partage pour un controle.
  Future<VerdictCibleSuivi> verifier({
    required CanalSuivi canal,
    required String? url,
  }) async {
    // 1. LA CONFIGURATION — aucun appel reseau, aucun appel de greffon.
    if (url == null || url.trim().isEmpty) {
      return VerdictCibleSuivi(
        canal: canal,
        disponibilite: DisponibiliteCibleSuivi.nonConfiguree,
      );
    }

    // 2. LA FORME DE L'ADRESSE — toujours aucun appel.
    final Uri cible;
    try {
      cible = Uri.parse(url);
    } on FormatException {
      return VerdictCibleSuivi(
        canal: canal,
        disponibilite: DisponibiliteCibleSuivi.nonVerifiable,
        url: url,
      );
    }
    if (!schemasWeb.contains(cible.scheme.toLowerCase())) {
      return VerdictCibleSuivi(
        canal: canal,
        disponibilite: DisponibiliteCibleSuivi.nonVerifiable,
        url: url,
      );
    }

    // 3. LA CONNECTIVITE, PUIS L'APPEL — et pas l'inverse : un randonneur hors
    // reseau ne doit pas lire que sa page de suivi est morte.
    final statut = await _connectivite.checkStatus();
    if (statut == ConnectivityStatusValues.offline) {
      return VerdictCibleSuivi(
        canal: canal,
        disponibilite: DisponibiliteCibleSuivi.reseauIndisponible,
        url: url,
      );
    }

    try {
      final reponse = await _http.get(cible).timeout(delaiMax);
      final code = reponse.statusCode;
      final ok = code >= 200 && code < 400;
      if (!ok) {
        _log.e('[CibleSuivi] ${canal.name} : « $url » repond $code — '
            'personne ne pourrait suivre ce lien');
      }
      return VerdictCibleSuivi(
        canal: canal,
        disponibilite: ok
            ? DisponibiliteCibleSuivi.joignable
            : DisponibiliteCibleSuivi.injoignable,
        url: url,
        codeHttp: code,
      );
    } catch (e) {
      // Delai depasse, DNS introuvable, certificat refuse : la cible n'a pas
      // repondu oui, et le reseau etait pourtant la. C'est un echec de la CIBLE.
      _log.e('[CibleSuivi] ${canal.name} : « $url » injoignable ($e)');
      return VerdictCibleSuivi(
        canal: canal,
        disponibilite: DisponibiliteCibleSuivi.injoignable,
        url: url,
      );
    }
  }
}
