// T2 — LE NOMBRE DE CLES POSEES PAR L'APPLICATION TIENT SOUS LA LIMITE
// OFFICIELLE DE CRASHLYTICS (lot 645-09).
//
// LA LIMITE EST CHIFFREE, ELLE EST OFFICIELLE, ET ELLE EST SILENCIEUSE.
// Source : firebase.google.com/docs/crashlytics/flutter/customize-crash-reports,
// consultee le 02/10/2026, verbatim :
//
//   « Crashlytics supports a maximum of 64 key-value pairs. After you reach
//     this threshold, additional values are not saved. »
//
// « ADDITIONAL VALUES ARE NOT SAVED » : au-dela de 64, Crashlytics n'avertit
// pas, ne leve pas, ne journalise rien. Il ARRETE D'ENREGISTRER. Un depot qui
// franchirait ce seuil perdrait son contexte de plantage sans qu'aucun test,
// aucun lint et aucune revue ne le voie — et il le perdrait au pire moment,
// celui ou on lit un rapport pour comprendre une panne.
//
// D'OU CETTE GARDE, ET D'OU LA CONVENTION QU'ELLE PROTEGE. Avec 63 ecrans,
// « une cle par ecran » tenait du pari : le 64e ecran aurait fait taire les
// 63 autres. Christophe a tranche pour TROIS cles dont la VALEUR change
// (`screen`, `trail`, `stage`) et une miette courte par entree d'ecran.
//
// COMMENT ELLE ROUGIRAIT. Elle lit les appels a `setCustomKey` dans tout
// `lib/` et resout le NOM de cle de chacun. Ecrire une quatrieme cle d'ecran,
// ou revenir a une cle par ecran, fait monter le compte et la fait echouer.
// Un appel dont elle n'arrive PAS a resoudre le nom la fait echouer aussi :
// une garde qui ne sait pas ce qu'elle compte ne doit pas rendre un chiffre
// rassurant.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/analytics/analytics_service.dart';
import 'package:moteur_gr/core/analytics/screen_breadcrumb.dart';

import '../../structurel/mesure_des_sources_645.dart';

/// LA LIMITE OFFICIELLE DE CRASHLYTICS. Ce n'est pas un choix de projet.
const limiteCrashlytics = 64;

/// LE PLAFOND REEL DU DEPOT, mesure le 03/10/2026 apres le lot 645-09.
///
/// QUATRE, ET NON TROIS, ET LA QUATRIEME EST LEGITIME : aux trois cles
/// d'ecran de ce lot s'ajoute `consentement_sauvegarde`, le chemin surveille
/// de la tache 637 (voir [AnalyticsStep]). Elle existait avant ce lot et elle
/// suit la meme convention — une cle, des valeurs qui changent.
const plafondDesClesDeLApplication = 4;

/// Les appels a `setCustomKey` : le nom de cle est le PREMIER argument.
final _appels = RegExp(r'setCustomKey\(\s*([^,\n]+),');

/// LE SEUL FICHIER OU `setCustomKey(key, ...)` NE NOMME AUCUNE CLE.
///
/// `FirebaseCrashSink` IMPLEMENTE le puits : son corps fait passer le `key`
/// qu'on lui donne a l'API native, il n'en choisit pas. Le nommer ici plutot
/// que d'ignorer partout les arguments appeles `key` garde la garde mordante :
/// un `setCustomKey(uneVariable, ...)` ecrit n'importe ou AILLEURS reste
/// irresolu, donc rouge — et c'est exactement le cas qu'on craint, celui ou le
/// nombre de cles n'est plus connu a la lecture.
const puitsQuiTransmet = 'lib/core/analytics/firebase_analytics_sink.dart';

/// Une constante de cle, telle que [AnalyticsKeys] la declare.
final _constantesDeCle = RegExp(r"static const String (\w+) = '([^']+)';");

/// Les etapes du chemin surveille de la tache 637 : `AnalyticsStep._(_x, 'y')`.
final _etapes = RegExp(r"AnalyticsStep\._\(\s*(\w+),");

/// La valeur d'un champ prive de chemin, ex. `_sauvegarde = 'consentement...'`.
final _cheminsDEtape = RegExp(r"static const String (_\w+) = '([^']+)';");

void main() {
  late Set<String> clesPosees;
  late List<String> nonResolus;

  setUpAll(() {
    final sourceService = lireSource(
      'lib/core/analytics/analytics_service.dart',
    );

    // Les noms de cle declares en constantes (`AnalyticsKeys.screen` -> screen).
    final parConstante = <String, String>{};
    for (final m in _constantesDeCle.allMatches(sourceService)) {
      parConstante[m.group(1)!] = m.group(2)!;
    }

    // Les chemins surveilles de la tache 637, poses par `markStep`.
    final chemins = <String, String>{};
    for (final m in _cheminsDEtape.allMatches(sourceService)) {
      chemins[m.group(1)!] = m.group(2)!;
    }
    final cheminsDUsage = <String>{
      for (final m in _etapes.allMatches(sourceService))
        if (chemins.containsKey(m.group(1))) chemins[m.group(1)]!,
    };

    clesPosees = <String>{};
    nonResolus = <String>[];

    for (final f in sourcesLib()) {
      for (final ligne in lignesDe(f)) {
        if (estLigneDeCommentaire(ligne)) continue;
        for (final m in _appels.allMatches(ligne)) {
          final arg = m.group(1)!.trim();
          // Une DECLARATION de la methode n'est pas un appel.
          if (arg.startsWith('String ')) continue;
          // Le puits qui transmet le `key` recu ne nomme pas de cle.
          if (f == puitsQuiTransmet && arg == 'key') continue;
          final litteral = RegExp(r"^'([^']*)'$").firstMatch(arg);
          if (litteral != null) {
            clesPosees.add(litteral.group(1)!);
          } else if (arg.startsWith('AnalyticsKeys.')) {
            final nom = arg.substring('AnalyticsKeys.'.length);
            final valeur = parConstante[nom];
            if (valeur == null) {
              nonResolus.add('$f: $arg');
            } else {
              clesPosees.add(valeur);
            }
          } else if (arg == 'step.chemin') {
            clesPosees.addAll(cheminsDUsage);
          } else {
            // UNE GARDE QUI NE SAIT PAS CE QU ELLE COMPTE NE RASSURE PERSONNE.
            nonResolus.add('$f: $arg');
          }
        }
      }
    }
  });

  group('645-09 / T2 — la limite de 64 cles de Crashlytics', () {
    test('tout appel a setCustomKey a un nom de cle RESOLU', () {
      expect(
        nonResolus,
        isEmpty,
        reason:
            'cette garde ne sait pas quel nom de cle ces appels posent ; elle '
            'compterait donc moins de cles qu il n en part vraiment. '
            'Resolvez-les (constante de [AnalyticsKeys] ou litteral) avant de '
            'la croire : ${nonResolus.join(', ')}',
      );
    });

    test('l application pose au plus 64 cles distinctes', () {
      expect(
        clesPosees.length,
        lessThanOrEqualTo(limiteCrashlytics),
        reason:
            'au-dela de 64 paires, Crashlytics cesse d enregistrer EN '
            'SILENCE : le contexte des rapports serait perdu sans que rien ne '
            'le dise. Cles trouvees : ${clesPosees.toList()..sort()}',
      );
    });

    test('et pas une cle de plus que les quatre mesurees', () {
      expect(
        clesPosees.length,
        lessThanOrEqualTo(plafondDesClesDeLApplication),
        reason:
            'une cle de plus a ete ecrite. Ce n est pas interdit, mais ca se '
            'decide : avec 63 ecrans et 64 places, la marge est de 60 cles '
            'pour TOUT le reste de l application. Cles trouvees : '
            '${clesPosees.toList()..sort()}',
      );
    });

    test(
      'les trois cles d entree d ecran sont bien celles de la convention',
      () {
        expect(AnalyticsKeys.all, ['screen', 'trail', 'stage']);
        expect(AnalyticsKeys.all.toSet(), hasLength(3));
        expect(clesPosees, containsAll(AnalyticsKeys.all));
      },
    );
  });

  group('645-09 — le catalogue des ecrans observes', () {
    test('63 ecrans, autant de miettes, aucun doublon', () {
      final noms = ScreenBreadcrumb.all.map((e) => e.name).toList();
      expect(noms.toSet(), hasLength(noms.length), reason: 'nom en double');
      expect(
        ScreenBreadcrumb.all,
        hasLength(sourcesLib().where((f) => f.endsWith('_screen.dart')).length),
        reason:
            'le catalogue et les ecrans du depot ne comptent plus pareil : un '
            'ecran a ete ajoute ou retire sans sa miette',
      );
    });

    test('une miette reste COURTE : le journal est plafonne a 64 ko', () {
      for (final miette in ScreenBreadcrumb.all) {
        expect(
          miette.name.length,
          lessThanOrEqualTo(40),
          reason: '${miette.name} est trop long pour une miette',
        );
      }
    });
  });
}
