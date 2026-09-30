/// LE LIEN DE SUIVI NE PEUT PLUS MOURIR EN SILENCE (tache 623, GO-73).
///
/// CE QUE CE FICHIER GARDE, ET IL NE GARDE PAS UNE ADRESSE. Skynet a mesure le
/// 28/09 que `https://moteur-gr.web.app/follow` rendait 404 : le randonneur
/// partageait sa position, personne ne pouvait le suivre, et RIEN ne le lui
/// disait. J'ai refait la mesure et mesure AUSSI le projet Firebase reel de
/// StepWays : meme 404, meme page « Site Not Found », au meme octet. Le nom du
/// projet n'etait donc pas le sujet — l'hebergement n'existe nulle part, et
/// `firebase.json` de ce depot ne porte AUCUNE section `hosting` pour le prouver
/// sans reseau.
///
/// Corriger l'adresse n'aurait donc ferme que l'incident. Ce fichier ferme le
/// DEFAUT, en trois familles de gardes :
///
///  [A] AUCUNE ADRESSE DANS LE DEPOT. Un test balaye `lib/` et refuse tout
///      domaine d'hebergement Firebase ecrit en dur, plus la configuration
///      elle-meme qui doit etre VIDE. Reintroduire un defaut par defaut rend ces
///      tests rouges.
///  [B] UN CANAL SANS ADRESSE NE PRODUIT PLUS DE LIEN. Avant ce lot, la
///      generation rendait TOUJOURS une chaine d'allure parfaite — c'est ce qui a
///      permis au defaut de vivre.
///  [C] LA CIBLE EST MESUREE AU MOMENT DU PARTAGE, et un 404 ne ressort PAS en
///      lien. C'est le groupe qui donne son nom au lot.
///
/// ET UNE GARDE DE SUITE : par defaut, preparer un partage n'emet AUCUN appel
/// reseau ni aucun appel de greffon. C'est la lecon mesuree par la tache 612 puis
/// reprise par la 615 — un canal de plateforme sans interlocuteur ne rend jamais
/// la main dans le temps feint d'un test de widgets.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moteur_gr/core/config/follow_links_config.dart';
import 'package:moteur_gr/core/firebase/firebase_service.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/features/group/models/share_link.dart';
import 'package:moteur_gr/features/group/services/follow_service.dart';
import 'package:moteur_gr/features/group/services/iap_service.dart';
import 'package:moteur_gr/features/group/services/verificateur_cible_suivi.dart';

/// Reseau pilotable, qui COMPTE ses interrogations.
///
/// Le compte n'est pas decoratif : il sert la garde « par defaut, aucun appel de
/// greffon » — un moniteur de connectivite parle a un greffon, et dans
/// `flutter test` il n'y a pas d'interlocuteur.
class _ReseauPilotable extends ConnectivityMonitor {
  _ReseauPilotable({this.enLigne = true});

  final bool enLigne;
  int interrogations = 0;

  @override
  Future<ConnectivityStatus> checkStatus() async {
    interrogations++;
    return enLigne
        ? ConnectivityStatusValues.online
        : ConnectivityStatusValues.offline;
  }
}

/// Un client HTTP qui compte ses appels et rend le code demande.
class _CibleEspionne {
  _CibleEspionne(this.code);

  final int code;
  final List<String> demandes = <String>[];

  http.Client get client => MockClient((requete) async {
    demandes.add(requete.url.toString());
    return http.Response(code == 200 ? '<html>suivi</html>' : 'nope', code);
  });
}

/// Le code source de `lib/`, commentaires RETIRES.
///
/// POURQUOI LES COMMENTAIRES SONT RETIRES, ET C'EST UNE LECON PAYEE AU LOT 612 :
/// sa premiere version de balayage accusait un fichier dont un COMMENTAIRE
/// racontait la suppression. « Une garde qui force a effacer l'histoire pour
/// rester verte est une mauvaise garde. » Or ce lot DOIT ecrire l'ancienne
/// adresse morte dans ses commentaires pour que personne ne la remette.
String _codeSeul(String source) {
  final sansBlocs = source.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
  return sansBlocs
      .split('\n')
      .where((l) => !l.trimLeft().startsWith('//'))
      .join('\n');
}

Iterable<File> _fichiersDart(String racine) => Directory(racine)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  FollowService service({
    FollowLinksConfig? config,
    int? codeCible,
    bool enLigne = true,
    _ReseauPilotable? reseau,
    _CibleEspionne? cible,
  }) {
    return FollowService(
      firebaseService: FirebaseService.testOnly(isAvailable: false),
      linksConfig: config ?? const FollowLinksConfig(),
      verificateurCible: VerificateurCibleSuivi(
        httpClient:
            cible?.client ??
            (codeCible == null ? null : _CibleEspionne(codeCible).client),
        connectivityMonitor: reseau ?? _ReseauPilotable(enLigne: enLigne),
      ),
    );
  }

  // =========================================================================
  group('623 [A] — AUCUNE adresse d hebergement n est ecrite dans le depot', () {
    test('les trois canaux sont NON configures par defaut', () {
      const config = FollowLinksConfig();

      expect(
        config.aucunCanalConfigure,
        isTrue,
        reason:
            'le depot ne doit porter AUCUNE adresse : la mesure du 28/09 '
            'a montre que l adresse en dur rendait 404, et que le domaine du '
            'projet reel rend 404 lui aussi (hebergement non deploye)',
      );
      for (final canal in CanalSuivi.values) {
        expect(config.estConfigure(canal), isFalse, reason: canal.name);
        expect(config.base(canal), isEmpty, reason: canal.name);
      }
    });

    test('LA GARDE ANTI-RETOUR : reintroduire une adresse par defaut casse ce '
        'test', () {
      // Cette assertion EST la mutation : elle est rouge des qu un defaut par
      // defaut reapparait dans FollowLinksConfig, quel qu il soit.
      const config = FollowLinksConfig();
      expect(config.webLink('AB3C7D'), isNull);
      expect(config.appLink('AB3C7D'), isNull);
      expect(config.companionLink('AB3C7D'), isNull);
    });

    test('les trois noms de variables de build sont publies et stables', () {
      // La CI comme Christophe doivent pouvoir les passer sans lire le code,
      // exactement comme STEPWAYS_FIREBASE_PROJECT_ID (tache 596).
      expect(FollowLinksConfig.variableAppBase, 'STEPWAYS_FOLLOW_APP_BASE');
      expect(FollowLinksConfig.variableWebBase, 'STEPWAYS_FOLLOW_WEB_BASE');
      expect(
        FollowLinksConfig.variableCompagnonBase,
        'STEPWAYS_FOLLOW_COMPANION_BASE',
      );
    });

    test('BALAYAGE de lib/ : aucun domaine d hebergement Firebase en dur, pour '
        'AUCUN projet', () {
      // Le defaut d origine etait une adresse qui SONNAIT juste pour un projet
      // qui n est pas le notre. La garde ne nomme donc pas « moteur-gr » : elle
      // refuse la FORME, pour n importe quel projet, y compris le notre tant que
      // rien n est deploye.
      final motif = RegExp(
        r'[A-Za-z0-9][A-Za-z0-9-]*\.(web\.app|firebaseapp\.com)',
      );
      final fautifs = <String>[];
      for (final f in _fichiersDart('lib')) {
        if (motif.hasMatch(_codeSeul(f.readAsStringSync()))) {
          fautifs.add(f.path);
        }
      }
      expect(
        fautifs,
        isEmpty,
        reason:
            'une adresse d hebergement en dur dans le code : '
            '${fautifs.join(", ")} — elle arrive par --dart-define',
      );
    });

    test('BALAYAGE de lib/ : le domaine mort du 28/09 n est nulle part, meme '
        'ailleurs que dans la configuration', () {
      final fautifs = <String>[];
      for (final f in _fichiersDart('lib')) {
        if (_codeSeul(f.readAsStringSync()).contains('moteur-gr.web.app')) {
          fautifs.add(f.path);
        }
      }
      expect(
        fautifs,
        isEmpty,
        reason:
            'l adresse mesuree a 404 le 28/09 est revenue dans '
            '${fautifs.join(", ")}',
      );
    });
  });

  // =========================================================================
  group('623 [B] — un canal sans adresse ne produit AUCUN lien', () {
    test('les trois canaux rendent null, et la liste des trois est VIDE', () {
      final svc = service();

      for (final type in ShareLinkTypeValues.values) {
        expect(
          svc.generateShareLink(
            sessionId: 's1',
            shareCode: 'AB3C7D',
            type: type,
          ),
          isNull,
          reason:
              'canal $type : une chaine d allure parfaite est precisement '
              'ce qui a permis au defaut de vivre',
        );
      }
      expect(
        svc.generateAllShareLinks(sessionId: 's1', shareCode: 'AB3C7D'),
        isEmpty,
        reason: 'un canal absent est plus honnete qu un canal au lien mort',
      );
    });

    test(
      'un canal CONFIGURE produit son lien, sans barre oblique en double',
      () {
        final svc = service(
          config: const FollowLinksConfig(
            webLinkBase: 'https://exemple.test/f/',
          ),
        );
        final lien = svc.generateShareLink(
          sessionId: 's1',
          shareCode: 'AB3C7D',
        );
        expect(lien, isNotNull);
        expect(lien!.url, 'https://exemple.test/f/AB3C7D');
      },
    );

    test(
      'LE PASS PAYANT NE REND PLUS DE LIEN MORT — et c etait le pire endroit '
      'du defaut',
      () {
        // Cette methode s appelle APRES un paiement. Avec une base absente elle
        // interpolait « null?pass=1 » ; avec l ancienne adresse elle rendait un
        // lien qui repondait 404. Le randonneur avait PAYE dans les deux cas.
        final achat = IapService(testMode: true);
        expect(
          achat.handlePurchaseComplete(
            sessionId: 's1',
            shareCode: 'AB3C7D',
            purchaseVerified: true,
          ),
          isNull,
          reason: 'un pass sans page de suivi n est pas un pass',
        );
      },
    );
  });

  // =========================================================================
  group('623 [C] — LE GROUPE QUI DONNE SON NOM AU LOT : la cible est MESUREE au '
      'moment du partage', () {
    test('UNE CIBLE QUI REND 404 NE RESSORT PAS EN LIEN — le defaut mesure le '
        '28/09', () async {
      final cible = _CibleEspionne(404);
      final svc = service(
        config: const FollowLinksConfig(
          webLinkBase: 'https://exemple.test/follow',
        ),
        cible: cible,
      );

      final partage = await svc.preparerPartage(
        sessionId: 's1',
        shareCode: 'AB3C7D',
      );

      expect(partage.disponibilite, DisponibiliteCibleSuivi.injoignable);
      expect(partage.verdict.codeHttp, 404);
      expect(
        partage.lien,
        isNull,
        reason:
            'c est TOUT le lot : le randonneur ne doit pas recevoir un '
            'lien que personne ne peut ouvrir',
      );
      expect(partage.partageable, isFalse);
      expect(
        cible.demandes,
        hasLength(1),
        reason: 'la cible doit avoir ete REELLEMENT interrogee',
      );
      expect(cible.demandes.single, 'https://exemple.test/follow/AB3C7D');
    });

    test(
      'une cible qui repond OUI rend le lien, et le dit partageable',
      () async {
        final cible = _CibleEspionne(200);
        final svc = service(
          config: const FollowLinksConfig(
            webLinkBase: 'https://exemple.test/follow',
          ),
          cible: cible,
        );

        final partage = await svc.preparerPartage(
          sessionId: 's1',
          shareCode: 'AB3C7D',
        );

        expect(partage.disponibilite, DisponibiliteCibleSuivi.joignable);
        expect(partage.verdict.codeHttp, 200);
        expect(partage.lien, isNotNull);
        expect(partage.lien!.url, 'https://exemple.test/follow/AB3C7D');
        expect(partage.partageable, isTrue);
      },
    );

    test(
      'une panne de serveur (500) est distinguee d un 404 dans le verdict',
      () async {
        // « Injoignable » sans le code ne permet pas de choisir entre « rien n est
        // deploye » et « le serveur est tombe » : deux actions differentes.
        final svc = service(
          config: const FollowLinksConfig(
            webLinkBase: 'https://exemple.test/follow',
          ),
          cible: _CibleEspionne(500),
        );
        final partage = await svc.preparerPartage(
          sessionId: 's1',
          shareCode: 'AB3C7D',
        );
        expect(partage.disponibilite, DisponibiliteCibleSuivi.injoignable);
        expect(partage.verdict.codeHttp, 500);
      },
    );

    test('un canal NON configure est « nonConfiguree », JAMAIS « injoignable » '
        '— et rien n est interroge', () async {
      final cible = _CibleEspionne(200);
      final reseau = _ReseauPilotable();
      final svc = service(cible: cible, reseau: reseau);

      final partage = await svc.preparerPartage(
        sessionId: 's1',
        shareCode: 'AB3C7D',
      );

      expect(
        partage.disponibilite,
        DisponibiliteCibleSuivi.nonConfiguree,
        reason:
            'une fonctionnalite absente n est pas une panne reseau : le '
            'randonneur doit lire autre chose',
      );
      expect(partage.lien, isNull);
      expect(cible.demandes, isEmpty);
      expect(reseau.interrogations, 0);
    });

    test('SANS RESEAU, le verdict n accuse PAS la cible — le faux echec, image '
        'inverse du defaut', () async {
      final cible = _CibleEspionne(200);
      final svc = service(
        config: const FollowLinksConfig(
          webLinkBase: 'https://exemple.test/follow',
        ),
        cible: cible,
        reseau: _ReseauPilotable(enLigne: false),
      );

      final partage = await svc.preparerPartage(
        sessionId: 's1',
        shareCode: 'AB3C7D',
      );

      expect(
        partage.disponibilite,
        DisponibiliteCibleSuivi.reseauIndisponible,
        reason: 'la cible peut etre vivante et le randonneur dans un vallon',
      );
      expect(partage.verdict.codeHttp, isNull);
      expect(
        cible.demandes,
        isEmpty,
        reason: 'on ne tente pas un appel qu on sait impossible',
      );
      expect(
        partage.lien,
        isNull,
        reason:
            'hors reseau, createSession rend null : il n y a de toute '
            'facon aucune session a partager',
      );
    });

    test('un lien profond n est PAS interrogeable en HTTP, et on ne fait pas '
        'semblant', () async {
      final cible = _CibleEspionne(200);
      final svc = service(
        config: const FollowLinksConfig(appLinkBase: 'stepways://follow'),
        cible: cible,
      );

      final partage = await svc.preparerPartage(
        sessionId: 's1',
        shareCode: 'AB3C7D',
        type: ShareLinkTypeValues.app,
      );

      expect(partage.disponibilite, DisponibiliteCibleSuivi.nonVerifiable);
      expect(cible.demandes, isEmpty);
      expect(
        partage.lien,
        isNotNull,
        reason:
            'le lien est rendu, mais avec un verdict qui dit que rien n a '
            'ete verifie — pas un succes qu on n a pas mesure',
      );
      expect(
        partage.partageable,
        isFalse,
        reason: 'non verifie n est pas partageable-sans-reserve',
      );
    });
  });

  // =========================================================================
  group('623 — LA GARDE DE SUITE : par defaut, preparer un partage ne touche NI '
      'le reseau NI un greffon', () {
    test('avec la configuration du depot, zero appel HTTP et zero appel de '
        'connectivite', () async {
      // MEME DOCTRINE QUE LA TACHE 615 : un appel de plateforme sans
      // interlocuteur ne rend jamais la main dans le temps feint d un test de
      // widgets. Ici c est le controle de CONFIGURATION, place en premier, qui
      // arrete tout — et le depot ne porte aucune adresse.
      final cible = _CibleEspionne(200);
      final reseau = _ReseauPilotable();
      final svc = service(cible: cible, reseau: reseau);

      for (final type in ShareLinkTypeValues.values) {
        await svc.preparerPartage(
          sessionId: 's1',
          shareCode: 'AB3C7D',
          type: type,
        );
      }

      expect(cible.demandes, isEmpty);
      expect(
        reseau.interrogations,
        0,
        reason:
            'ConnectivityMonitor parle a un greffon : la suite entiere '
            'doit pouvoir construire un FollowService sans le reveiller',
      );
    });

    test(
      'le verificateur construit par defaut ne leve jamais sur un canal vide',
      () async {
        final verdict = await VerificateurCibleSuivi().verifier(
          canal: CanalSuivi.web,
          url: null,
        );
        expect(verdict.disponibilite, DisponibiliteCibleSuivi.nonConfiguree);
        expect(verdict.joignable, isFalse);
      },
    );
  });
}
