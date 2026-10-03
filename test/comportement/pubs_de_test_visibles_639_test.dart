import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/ad_config.dart';
import 'package:moteur_gr/core/config/mare_a_mare_centre_trail_config.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/core/services/session_demo.dart';
import 'package:moteur_gr/core/error/error_nets.dart';

/// TACHE 639 (AVENANT) — LES PUBLICITES DE TEST SONT VISIBLES SUR LA VERSION DE
/// TEST, ET L'ECHEC DU CONSENTEMENT NE SE TAIT PLUS.
///
/// LA DEMANDE DE CHRISTOPHE, MOT POUR MOT (30/09 12:23, DEM-260930-1224) : « Et
/// j aimerais voir les pubs sur la version de test ».
///
/// POURQUOI IL NE LES VOYAIT PAS — TROIS VERROUS, TOUS CORRECTS UN PAR UN.
///   1. LA REGLE D'OR #99404 les eteint sur un sentier ACHETE. Un testeur teste
///      justement des sentiers qu'il possede : il ne reste alors aucun ecran ou
///      une publicite soit autorisee. Christophe en avait vu une le 29/09 parce
///      qu'il testait le sentier de DEMONSTRATION, gratuit.
///   2. LE CONSENTEMENT UMP N'EST JAMAIS DEMANDE sur un build de test (verrou 3
///      de la tache 560 : on ne pose pas une question RGPD pour une regie non
///      branchee). Dans l'EEE, sans consentement enregistre, `canRequestAds()`
///      rend `false` — donc aucune publicite, meme de test. C'etait ECRIT comme
///      consequence assumee dans `ads_consent_service.dart`, et c'est
///      exactement ce que Christophe a rencontre depuis la France.
///   3. LE BUDGET D'AMORCE de 6 s abandonne la publicite hors ligne. Celui-la
///      n'est PAS leve : hors ligne, il n'y a pas de publicite, et c'est bien.
///
/// CE QUE CES TESTS VERROUILLENT :
///   1. le mode est un `--dart-define` qui NE PEUT PAS atteindre la production ;
///   2. la derogation a la regle d'or est ECRITE a un seul endroit, et elle
///      epargne l'abonnement ;
///   3. la geographie de debug EEA n'est demandee QUE sous ce mode ;
///   4. un echec du consentement UMP remonte dans Crashlytics, et plus seulement
///      dans le journal local du telephone.
void main() {
  String source(String chemin) => _sourceAvecSesParts(chemin);

  group('le mode pubs de test ne peut pas atteindre la production', () {
    test('il est faux par defaut (aucun dart-define dans cette suite)', () {
      expect(AdConfig.testAdsForced, isFalse);
      expect(AdConfig.hasProductionUnits, isFalse);
    });

    test('il est ANNULE des qu un ad-unit de production est injecte', () {
      // La garantie n'est pas une promesse de commande de build : elle est une
      // CONDITION dans le code. Un build de release porte ses vrais
      // identifiants, donc il ne peut pas emporter le mode par accident, meme si
      // la commande garde le drapeau.
      final config = source('lib/core/config/ad_config.dart');
      expect(
        config,
        contains('_testAdsRequested && !hasProductionUnits'),
        reason: 'le mode doit etre annule par la presence d ad-units de prod',
      );
      expect(
        config,
        contains("bool.fromEnvironment(\n    'STEPWAYS_TEST_ADS',\n  )"),
        reason: 'le nom du dart-define est celui decide avec Christophe',
      );
    });
  });

  group('la derogation a la regle d or est ecrite une fois, et elle epargne '
      'l abonnement', () {
    test('elle vit dans la SOURCE UNIQUE, pas dans un ecran', () {
      // Une derogation recopiee dans les ecrans finirait par differer de la
      // banniere : c'est la faute que la regle d'or a deja payee deux fois.
      final service = source('lib/core/services/monetization_service.dart');
      expect(
        service,
        contains('if (AdConfig.testAdsForced) return isSubscriberActive();'),
        reason:
            'la derogation doit etre DANS isNoAdsActive, et rendre la main a '
            'l abonnement seul',
      );
      for (final ecran in [
        'lib/features/ads/providers/ads_providers.dart',
        'lib/features/ads/presentation/banner_ad_slot.dart',
        'lib/features/ads/presentation/retirer_les_pubs_button.dart',
        'lib/features/ads/domain/ad_state.dart',
        'lib/features/trail/presentation/trail_catalog_screen.dart',
      ]) {
        expect(
          source(ecran),
          isNot(contains('testAdsForced')),
          reason: '$ecran recalcule la derogation : elle doit rester unique',
        );
      }
    });

    test('l abonnement reste respecte, meme sur un build de test', () {
      // C'est le seul des trois etats qui se PAIE en argent tous les mois. Le
      // priver de ce qu'il paie serait la mauvaise derogation — et c'est aussi ce
      // qui permet de VERIFIER que l'abonnement eteint bien la publicite.
      final service = source('lib/core/services/monetization_service.dart');
      final derogation = service.substring(
        service.indexOf('if (AdConfig.testAdsForced)'),
      );
      expect(
        derogation,
        startsWith('if (AdConfig.testAdsForced) return isSubscriberActive();'),
      );
    });
  });

  group('le consentement UMP ne bloque plus les pubs de test en Europe', () {
    final consentement = source(
      'lib/features/ads/data/ads_consent_service.dart',
    );

    test('le formulaire est autorise sous le mode pubs de test', () {
      // Sans formulaire, pas de consentement ; sans consentement, dans l'EEE,
      // `canRequestAds()` rend faux et AUCUNE publicite n'est demandee.
      expect(
        consentement,
        contains('AdConfig.hasProductionUnits || AdConfig.testAdsForced'),
        reason:
            'un build de test doit pouvoir demander le consentement quand on '
            'lui demande de montrer des publicites',
      );
    });

    test('la geographie EEA de debug est demandee, et SEULEMENT sous ce mode', () {
      expect(consentement, contains('DebugGeography.debugGeographyEea'));
      expect(
        consentement,
        contains(
          'if (!AdConfig.testAdsForced) return ConsentRequestParameters();',
        ),
        reason:
            'hors mode test, la demande doit rester exactement celle de la '
            'production',
      );
      // Les parametres de debug UMP n'ont d'effet QUE sur un appareil declare de
      // test : demander la geographie sans declarer l appareil ne ferait rien.
      expect(consentement, contains('testIdentifiers: _testDeviceIds'));
    });
  });

  group('un echec du consentement UMP remonte dans Crashlytics', () {
    tearDown(ErrorNets.retirerPourTest);

    test('ErrorNets.signaler porte une erreur ATTRAPEE au rapporteur', () {
      // LE TROU MESURE : ErrorHandler.log n ecrit que dans le journal LOCAL, et
      // le rapporteur Crashlytics n etait atteint que par les deux filets
      // globaux — qu une erreur ATTRAPEE ne traverse jamais. Tous les echecs que
      // l application absorbe proprement, dont le consentement publicitaire,
      // etaient donc invisibles a distance.
      final recus = <(Object, bool)>[];
      ErrorNets.installer();
      addTearDown(ErrorNets.retirerPourTest);
      ErrorNets.brancherRapporteur(
        (error, stack, {bool fatal = false}) => recus.add((error, fatal)),
      );

      ErrorNets.signaler(
        StateError('UMP update failed: pas de reseau'),
        context: 'AdsConsentService.requestConsentInfoUpdate',
      );

      expect(recus, hasLength(1));
      expect(recus.single.$1, isA<StateError>());
      expect(
        recus.single.$2,
        isFalse,
        reason:
            'une erreur absorbee n est JAMAIS fatale : l application continue',
      );
    });

    test('sans rapporteur branche, rien ne plante (mode local)', () {
      // Tant qu aucun cloud n est branche, le comportement doit etre exactement
      // celui d avant : le journal local, et rien de plus.
      ErrorNets.retirerPourTest();
      expect(
        () => ErrorNets.signaler(StateError('sans cloud')),
        returnsNormally,
      );
    });

    test('les quatre echecs UMP passent par le signalement', () {
      final consentement = source(
        'lib/features/ads/data/ads_consent_service.dart',
      );
      for (final contexte in [
        'AdsConsentService.requestConsentInfoUpdate',
        'AdsConsentService.loadForm',
        'AdsConsentService.canRequestAds',
        'AdsConsentService.initialize',
      ]) {
        final avant = consentement.substring(
          0,
          consentement.indexOf("context: '$contexte'"),
        );
        expect(
          avant.substring(avant.length - 200),
          contains('ErrorNets.signaler'),
          reason: '$contexte est encore journalise SANS etre signale',
        );
      }
    });
  });

  group('la demo montre la banniere de test quand on n est pas abonne', () {
    // LA DEMANDE : « la demo montre l appli de A a Z, pub comprise, quand on
    // n est pas abonne ». MESURE : c'est DEJA le cas, et par construction. Ce qui
    // manquait n'etait donc pas du code mais la PREUVE que personne ne remettra
    // une garde par-dessus.
    //
    // INTEGRATION 647 — LA PREUVE A CHANGE DE BRANCHE, PAS DE CONTENU. Le lot 639
    // l'etablissait ainsi : « le sentier de demonstration est declare GRATUIT »,
    // plus la regle d'or « un sentier gratuit porte la publicite ». Le lot 638 a
    // supprime le sentier de demonstration ampute ET tout sentier gratuit du
    // catalogue — decision de Christophe du 29/09 14:17, verbatim : « la prochaine
    // fois que j'ouvre l'application je n'ai droit a rien ». La demo se joue
    // desormais sur le VRAI Mare a Mare Centre, qui est PAYANT.
    //
    // LA PUBLICITE EN DEMO N'A PAS DISPARU POUR AUTANT, et c'est ce que les deux
    // tests ci-dessous mesurent : un randonneur qui n'a pas achete un sentier
    // payant est au niveau [TrailAccess.free] — « demo bridee + pub » — dont
    // `showAds` est vrai. La demande tient donc par l'AUTRE branche de la meme
    // regle d'or, sans qu'aucune exemption ait ete ajoutee nulle part.
    test('le sentier de demonstration est le VRAI Mare a Mare Centre', () {
      expect(kSentierDeDemo, mareAMareCentreTrailConfig.id);
    });

    test('ce sentier est PAYANT, et le niveau gratuit y porte la pub', () {
      expect(mareAMareCentreTrailConfig.isFreeTrail, isFalse);
      expect(
        TrailAccess.free.showAds,
        isTrue,
        reason:
            'gratuit sur un sentier payant = demo bridee AVEC pub : c est par la '
            'que la demo montre l application « pub comprise »',
      );
    });

    test('un sentier gratuit porte la publicite, par la regle d or', () {
      expect(TrailAccess.freeTrail.showAds, isTrue);
      expect(TrailAccess.free.showAds, isTrue);
      expect(
        TrailAccess.owned.showAds,
        isFalse,
        reason: 'le sans-pub est la contrepartie d avoir paye',
      );
      expect(TrailAccess.subscriber.showAds, isFalse);
    });

    test('la banniere n est pas bridee en demo : aucune garde de mode demo', () {
      // La barriere d'ecriture du lot 634 (« rien ne s'ecrit en demo ») ne doit
      // PAS s'etendre a la banniere : l'afficher est une LECTURE. Si un agent
      // ajoutait une garde `enDemo` dans la decision, la demo cesserait de
      // montrer l'application « de A a Z, pub comprise ».
      final decision = source('lib/features/ads/providers/ads_providers.dart');
      expect(
        decision,
        isNot(contains('enDemo')),
        reason:
            'la decision d afficher une banniere ne connait pas le mode demo '
            '— et elle ne doit pas le connaitre',
      );
    });
  });

  group('la video ne promet plus ce qu elle n a pas accorde', () {
    test('elle rend l ETAT relu, pas le geste demande', () {
      // `grantRewardNoAds` ne fait RIEN en mode demo (barriere d ecriture du lot
      // 634). Le provider rendait quand meme `true` : l interface annoncait
      // « Merci ! Sans publicite pendant 24 h » sans qu une seule heure ait ete
      // accordee. D autant plus visible que la demo montre desormais la banniere.
      final providers = source('lib/features/ads/providers/ads_providers.dart');
      expect(
        providers,
        contains('return monetization.isRewardNoAdsActive();'),
        reason: 'le resultat doit etre RELU, pas suppose',
      );
      expect(
        providers,
        isNot(
          contains('await monetization.grantRewardNoAds();\n    return true;'),
        ),
        reason: 'le `return true` optimiste ne doit pas revenir',
      );
    });
  });
}

/// Lit une bibliotheque de `lib/` ET ses fichiers `part`, dans l ordre des
/// directives.
///
/// LOT 645-06, VAGUE 2 : les plus gros fichiers de `lib/` ont ete scindes en
/// `part` du MEME dossier. Le code mesure ici est le meme, au caractere pres —
/// il vit juste dans plusieurs fichiers d une seule bibliotheque. On les
/// recolle donc dans l ordre declare, ce qui preserve aussi l ordre des lignes
/// dont dependent les mesures de position. Seule la LECTURE change ; aucune
/// attente de ces tests n a ete touchee.
String _sourceAvecSesParts(String chemin) {
  final racine = File(chemin).readAsStringSync();
  final dossier = chemin.substring(0, chemin.lastIndexOf('/'));
  final parts = RegExp(r"^part '([^']+)';", multiLine: true)
      .allMatches(racine)
      .map((m) => m.group(1)!)
      .where((n) => !n.endsWith('.g.dart') && !n.endsWith('.freezed.dart'));
  return [
    racine,
    for (final n in parts) File('$dossier/$n').readAsStringSync(),
  ].join('\n');
}
