// LES ADRESSES LEGALES DE STEPWAYS SONT REELLES, ET UNE SEULE (tache 642).
//
// DECISION DE CHRISTOPHE, 30/09 13:39, verbatim : « Regarde celle de GR20 et
// fais pareil ! ». La politique de confidentialite de StepWays est donc
// hebergee comme celle du GR20 — hebergement Firebase du projet `gr20-app`,
// domaine only1cent.com — sous le prefixe `/stepways/`.
//
// LE DEFAUT MESURE AVANT D ECRIRE UNE LIGNE, ET IL ETAIT EN QUATRE
// EXEMPLAIRES. Les quatre configurations de sentier annoncaient une politique
// de confidentialite :
//   mare_a_mare_centre        https://example.org/mare-a-mare-centre/privacy
//   mare_a_mare_centre_demo   https://example.org/mare-a-mare-centre/privacy
//   pyrenees                  https://example.org/gr-pyrenees/privacy
//   test_trail                https://example.org/test-trail/privacy
// `example.org` est le domaine reserve aux EXEMPLES (RFC 2606) : aucune des
// quatre adresses ne repondait, et une politique de confidentialite qui ne
// repond pas est une obligation du RGPD (art. 13) affichee mais non tenue.
//
// LE LOT 641 L AVAIT DEJA VU, ET AVAIT CHOISI DE SE TAIRE PLUTOT QUE DE
// MENTIR : sa fiche publiee en base omet volontairement `privacyPolicyUrl`,
// avec cette note dans `publication/contenu/mare-a-mare-centre.json` —
// « Publier une adresse d exemple comme politique de confidentialite serait un
// mensonge ». Le present lot supprime la raison de se taire.
//
// CE QUE CE GROUPE EXIGE :
//   1. Plus aucune adresse d exemple dans lib/ ni dans assets/ — hors les deux
//      fichiers de donnees de DEMONSTRATION nommes ci-dessous, qui portent des
//      liens de prestataires fictifs et non une promesse juridique.
//   2. Une seule verite : les quatre sentiers pointent sur la MEME constante.
//   3. Cette constante est en https, sur only1cent.com, sous /stepways/.
//   4. Les cinq langues de l application retombent sur une page qui existe :
//      francais pour `fr`, anglais pour les quatre autres.
//
// TESTS ECRITS AVANT LA CORRECTION.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/branding/stepways_legal.dart';
import 'package:moteur_gr/core/config/mare_a_mare_centre_trail_config.dart';
import 'package:moteur_gr/core/config/pyrenees_trail_config.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';

/// LES DEUX SEULS FICHIERS OU UNE ADRESSE D EXEMPLE EST TOLEREE, ET POURQUOI.
///
/// Ils portent des liens de reservation de prestataires FICTIFS, dans des
/// donnees de demonstration : un gite du Vallon, un refuge des Cretes, une
/// epicerie. Ce n est pas une promesse juridique faite au randonneur, c est du
/// decor. Ils restent nommes ici — donc visibles — au lieu d etre exclus en
/// silence : le jour ou ces liens de demonstration disparaissent ou deviennent
/// nuls, ces deux lignes disparaissent avec eux, et la garde devient totale.
///
/// Ce qui est INTERDIT dans tous les cas, y compris dans ces deux fichiers :
/// une adresse d exemple pour une page LEGALE (politique, conditions).
///
/// ELLE EST VIDE DEPUIS LE LOT 645-08 (03/10/2026), et c'est le point. Elle
/// tolerait les deux fichiers de donnees de demonstration qui portaient six
/// liens vers `example.org` — trois hebergements peripheriques et trois items
/// de town guide. Un randonneur ne voit pas la difference entre une donnee de
/// demonstration et une promesse : les deux lui montraient un bouton « Voir le
/// site » qui n'ouvrait rien. Les six liens ont ete RETIRES (voie V2), donc la
/// tolerance n'a plus d'objet — et la laisser serait rouvrir la porte sans que
/// personne le remarque.
const _demonstrationToleree = <String>{};

void main() {
  // =========================================================================
  // 1. PLUS AUCUNE ADRESSE D EXEMPLE — NI DANS LE CODE, NI DANS LES ASSETS
  // =========================================================================
  group('Aucune adresse d exemple ne subsiste', () {
    test(
      'lib/ ne contient plus example.org, hors donnees de demonstration',
      () {
        final fautifs = <String>[];
        for (final f
            in Directory('lib')
                .listSync(recursive: true)
                .whereType<File>()
                .where((f) => f.path.endsWith('.dart'))) {
          final chemin = _normaliser(f.path);
          if (_demonstrationToleree.contains(chemin)) continue;
          if (_codeSeul(f.readAsStringSync()).contains('example.org')) {
            fautifs.add(chemin);
          }
        }
        expect(
          fautifs,
          isEmpty,
          reason:
              'example.org est le domaine reserve aux exemples (RFC 2606) '
              ': une adresse qui ne repond pas est affichee au randonneur '
              'comme si elle repondait. Si ce fichier porte une donnee de '
              'demonstration et non une promesse, ajoute-le a '
              '_demonstrationToleree en disant pourquoi.',
        );
      },
    );

    test('assets/ ne contient aucune adresse d exemple', () {
      final fautifs = <String>[];
      final assets = Directory('assets');
      if (assets.existsSync()) {
        for (final f
            in assets
                .listSync(recursive: true)
                .whereType<File>()
                .where(
                  (f) =>
                      f.path.endsWith('.json') ||
                      f.path.endsWith('.md') ||
                      f.path.endsWith('.yaml'),
                )) {
          if (f.readAsStringSync().contains('example.org')) {
            fautifs.add(_normaliser(f.path));
          }
        }
      }
      expect(
        fautifs,
        isEmpty,
        reason:
            'un asset embarque est de la donnee LIVREE : une adresse '
            'd exemple y survit a toutes les relectures de code',
      );
    });

    test(
      'aucune page legale, nulle part, ne pointe sur une adresse d exemple',
      () {
        // Cette garde-ci ne tolere RIEN, pas meme les deux fichiers de
        // demonstration : une politique de confidentialite ou des conditions
        // d utilisation sont une obligation legale, jamais du decor.
        final fautifs = <String>[];
        for (final f
            in Directory('lib')
                .listSync(recursive: true)
                .whereType<File>()
                .where((f) => f.path.endsWith('.dart'))) {
          for (final ligne in _codeSeul(f.readAsStringSync()).split('\n')) {
            final minuscule = ligne.toLowerCase();
            final estLegale =
                minuscule.contains('privacy') ||
                minuscule.contains('politique') ||
                minuscule.contains('conditions') ||
                minuscule.contains('cgu') ||
                minuscule.contains('terms');
            if (estLegale && minuscule.contains('example.org')) {
              fautifs.add('${_normaliser(f.path)} : ${ligne.trim()}');
            }
          }
        }
        expect(
          fautifs,
          isEmpty,
          reason:
              'une page legale doit repondre : c est le minimum que le '
              'RGPD (art. 13) et les deux magasins d applications exigent',
        );
      },
    );
  });

  // =========================================================================
  // 2. UNE SEULE VERITE POUR LES QUATRE SENTIERS
  // =========================================================================
  // INTEGRATION 647 — ILS SONT TROIS, PLUS QUATRE. Le lot 642 posait l adresse
  // publiee sur les quatre configurations de sentier existantes, dont
  // `mareAMareCentreDemoTrailConfig`. Le lot 638 a SUPPRIME cette configuration :
  // la demo se joue desormais sur le VRAI Mare a Mare Centre, sept etapes, et le
  // sentier de demonstration ampute du lot 601 n a plus de raison d exister
  // (DEM-260930-1014). La fusion a donc rendu un conflit « modifie d un cote,
  // supprime de l autre » ; on confirme la suppression, et rien de 642 n est
  // perdu : la ligne que 642 changeait dans ce fichier etait la MEME que dans les
  // trois autres, et les trois survivantes la portent.
  group('Les trois sentiers pointent sur la meme politique', () {
    test('chaque configuration porte l adresse publiee de StepWays', () {
      expect(
        mareAMareCentreTrailConfig.privacyPolicyUrl,
        StepwaysLegal.privacyPolicyUrl,
      );
      expect(
        pyreneesTrailConfig.privacyPolicyUrl,
        StepwaysLegal.privacyPolicyUrl,
      );
      expect(testTrailConfig.privacyPolicyUrl, StepwaysLegal.privacyPolicyUrl);
    });

    test('aucune des trois n est vide ni nulle', () {
      for (final url in <String?>[
        mareAMareCentreTrailConfig.privacyPolicyUrl,
        pyreneesTrailConfig.privacyPolicyUrl,
        testTrailConfig.privacyPolicyUrl,
      ]) {
        expect(url, isNotNull);
        expect(url, isNotEmpty);
      }
    });
  });

  // =========================================================================
  // 3. L ADRESSE EST CELLE QUI EST REELLEMENT HEBERGEE
  // =========================================================================
  group('L adresse publiee', () {
    test('est en https, sur only1cent.com, sous /stepways/', () {
      for (final url in <String>[
        StepwaysLegal.privacyPolicyFr,
        StepwaysLegal.privacyPolicyEn,
        StepwaysLegal.conditionsFr,
        StepwaysLegal.conditionsEn,
      ]) {
        final uri = Uri.parse(url);
        expect(
          uri.scheme,
          'https',
          reason:
              'en clair, un intermediaire pourrait reecrire la '
              'politique que le randonneur croit lire',
        );
        expect(uri.host, 'only1cent.com');
        expect(
          uri.path,
          startsWith('/stepways/'),
          reason:
              'le prefixe separe StepWays du GR20, qui partage cet '
              'hebergement',
        );
      }
    });

    test('les quatre adresses sont distinctes', () {
      final adresses = <String>{
        StepwaysLegal.privacyPolicyFr,
        StepwaysLegal.privacyPolicyEn,
        StepwaysLegal.conditionsFr,
        StepwaysLegal.conditionsEn,
      };
      expect(adresses.length, 4);
    });
  });

  // =========================================================================
  // 4. LES CINQ LANGUES RETOMBENT SUR UNE PAGE QUI EXISTE
  // =========================================================================
  group('Les cinq langues de l application', () {
    test('le francais recoit la version francaise', () {
      expect(
        StepwaysLegal.privacyPolicyPour('fr'),
        StepwaysLegal.privacyPolicyFr,
      );
      expect(StepwaysLegal.conditionsPour('fr'), StepwaysLegal.conditionsFr);
    });

    test('les quatre autres recoivent la version anglaise, jamais un 404', () {
      for (final langue in <String>['en', 'de', 'es', 'it']) {
        expect(
          StepwaysLegal.privacyPolicyPour(langue),
          StepwaysLegal.privacyPolicyEn,
          reason:
              'seules les versions FR et EN sont en ligne : inventer '
              'une traduction juridique non relue serait pire qu un 404, '
              'et un 404 serait pire que l anglais',
        );
        expect(
          StepwaysLegal.conditionsPour(langue),
          StepwaysLegal.conditionsEn,
        );
      }
    });
  });
}

/// Chemin normalise en separateurs POSIX — les tests tournent sous Windows.
String _normaliser(String chemin) => chemin.replaceAll(r'\', '/');

/// Reprise du helper des taches 612 et 617, et pour la meme raison mesuree :
/// une garde qui force a effacer l histoire racontee en commentaire pour rester
/// verte est une mauvaise garde. Ici, le commentaire de `TrailConfig` a le
/// droit de citer une adresse d exemple pour expliquer le champ.
String _codeSeul(String source) {
  final sansBlocs = source.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
  return sansBlocs
      .split('\n')
      .where(
        (l) =>
            !l.trimLeft().startsWith('//') && !l.trimLeft().startsWith('///'),
      )
      .join('\n');
}
