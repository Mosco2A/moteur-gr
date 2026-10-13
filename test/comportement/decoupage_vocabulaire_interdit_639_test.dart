import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// TACHE 639 — BUGS 6 ET 5b : PLUS AUCUNE TRACE DU DECOUPAGE, ET LE VERDICT
/// N'EST PLUS UN MUR.
///
/// LES DEUX RETOURS DE CHRISTOPHE, MOT POUR MOT (30/09, telephone, build 0.1.3
/// (7)) :
///   * 10:12 — « jour par jour on dit que la premiere etape est en decoupage trop
///     serre alors que je ne veux pas qu on decoupe les etapes ! » ;
///   * 10:11 — « ca dit pas possible en plus au lieu d un truc moins clivant ».
///
/// POURQUOI LE RETRAIT DU LOT 634 ETAIT INCOMPLET — MESURE, PAS SUPPOSITION. Le
/// lot 634 (86dacc67) avait retire la MECANIQUE : `maxDaysPerStage`,
/// `splitStage`, `_splitHeaviestFirst`, `splitSuffix`, la borne haute a 2N. Il
/// n'a PAS touche aux LIBELLES, et pour une raison precise : un garde-fou de la
/// tache 552 (`verdict_sur_le_decoupage_test.dart`) EXIGEAIT le mot « decoupage »
/// dans les trois verdicts, dans les cinq langues. Le mot etait donc protege par
/// un test pendant que la chose disparaissait. « Decoupage trop serre » est resté
/// affiché sous la premiere journee du jour-par-jour.
///
/// CE QUE CE FICHIER VERROUILLE, ET CE QU'IL NE VERROUILLE PAS. Il balaie les
/// libelles VISIBLES des trois rubriques concernees (faisabilite, programme,
/// calendrier) dans les CINQ langues, et refuse le vocabulaire du decoupage
/// d'etape. Il verifie aussi que la reponse rouge ORIENTE au lieu de fermer. Il
/// ne balaie pas les commentaires de code : un commentaire ne s'affiche pas, et
/// certains doivent GARDER le mot pour raconter le retrait (dont le verbatim de
/// Christophe ci-dessus).
void main() {
  /// Tous les libelles d'une langue sous ces racines, aplatis avec leur chemin.
  ///
  /// On lit le FICHIER DE LANGUE, pas les getters generes : c'est la source que
  /// quelqu un modifiera, et un balayage par getters obligerait a lister a la
  /// main les 400 libelles des trois rubriques — donc a en oublier.
  Map<String, String> libellesDe(String langue, List<String> racines) {
    final brut = File('assets/i18n/$langue.i18n.json').readAsStringSync();
    final resultat = <String, String>{};
    void descendre(Object? noeud, String chemin) {
      if (noeud is Map) {
        noeud.forEach((cle, valeur) {
          descendre(valeur, chemin.isEmpty ? '$cle' : '$chemin.$cle');
        });
      } else if (noeud is String) {
        if (racines.any(chemin.startsWith)) resultat[chemin] = noeud;
      }
    }

    descendre(jsonDecode(brut), '');
    return resultat;
  }

  /// LE VOCABULAIRE INTERDIT, NOMME LANGUE PAR LANGUE.
  ///
  /// Un mot est interdit parce qu'il est ECRIT ici, jamais parce qu'un algorithme
  /// le trouve suspect. Tous designent la meme chose : couper une etape en deux,
  /// ou le « decoupage » qui laissait croire qu'on allait le faire.
  const interdits = <String, List<String>>{
    'fr': ['découp', 'decoup', 'trop serré', 'scind', 'fractionn', 'moitiés'],
    'en': ['split', 'too tight', 'cut in two', 'halves'],
    'de': ['aufteil', 'zerleg', 'zu knapp', 'hälften', 'einteilung'],
    // « repartidos » N EST PAS dans cette liste, et c est deliberé : en espagnol
    // il veut dire « repartis », et il sert a dire ou poser les jours de repos
    // (« dias de descanso repartidos en tu programa »). C est le NOM « reparto »
    // qui traduisait « decoupage », pas le participe.
    'es': ['división', 'divisi', 'reparto ', 'el reparto', 'mitades'],
    'it': ['suddivis', 'dividi', 'divisa', 'divisione', 'metà di pari'],
  };

  /// LES TROIS RUBRIQUES OU LE MOT VIVAIT.
  const racines = ['feasibility', 'programme', 'calendar'];

  group('le vocabulaire du decoupage a quitte les 5 langues', () {
    for (final entree in interdits.entries) {
      test(
        '${entree.key} : aucun libelle de la faisabilite, du programme ou du '
        'calendrier',
        () {
          final fautes = <String>[];
          libellesDe(entree.key, racines).forEach((chemin, libelle) {
            final bas = libelle.toLowerCase();
            for (final mot in entree.value) {
              if (bas.contains(mot)) {
                fautes.add('$chemin  [$mot]  « $libelle »');
              }
            }
          });
          expect(
            fautes,
            isEmpty,
            reason:
                '${entree.key} : le decoupage est revenu dans '
                '${fautes.length} libelle(s) :\n  ${fautes.join('\n  ')}',
          );
        },
      );
    }

    test('et les trois verdicts nomment le RYTHME du jour', () {
      // La contrepartie : on n a pas seulement retire un mot, on a dit de quoi
      // on parle. Un verdict qui ne nomme plus son sujet serait un recul.
      const rythme = <AppLocale, String>{
        AppLocale.fr: 'rythme',
        AppLocale.en: 'pace',
        AppLocale.de: 'tempo',
        AppLocale.es: 'ritmo',
        AppLocale.it: 'ritmo',
      };
      for (final locale in AppLocale.values) {
        final v = locale.buildSync().feasibility.formula.verdicts;
        for (final libelle in [v.green, v.orange, v.red]) {
          expect(
            libelle.toLowerCase(),
            contains(rythme[locale]),
            reason:
                '${locale.languageCode} : « $libelle » ne nomme pas son sujet',
          );
        }
      }
    });
  });

  group('la mecanique est absente du code, pas seulement des mots', () {
    // Le lot 634 a retire les symboles ; ce garde-fou empeche leur retour. Un
    // mot peut revenir par un copier-coller, un SYMBOLE revient par un merge.
    test('aucun symbole de decoupage d etape dans lib/', () {
      const symboles = [
        'maxDaysPerStage',
        'splitStage',
        '_splitHeaviestFirst',
        'splitSuffix',
        'stageEnergyKm',
        'maxWalkingDaysFor',
      ];
      final fautes = <String>[];
      for (final fichier
          in Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final source = fichier.readAsStringSync();
        for (final symbole in symboles) {
          // Une MENTION dans un commentaire qui raconte le retrait est permise
          // (« `maxDaysPerStage` n'existe plus ») : ce qui est interdit, c'est un
          // APPEL ou une DECLARATION. On cherche donc le symbole suivi d'une
          // parenthese, d'un signe = ou d'un point-virgule.
          final appel = RegExp('$symbole\\s*[(=;]');
          if (appel.hasMatch(source)) {
            fautes.add('${fichier.path} : $symbole');
          }
        }
      }
      expect(
        fautes,
        isEmpty,
        reason:
            'la mecanique de decoupage est revenue :\n  '
            '${fautes.join('\n  ')}',
      );
    });
  });

  group('BUG 5b — la reponse rouge oriente, elle ne ferme pas', () {
    // LE VERDICT N EST JAMAIS UN MUR. Ce qu on verrouille : il dit ce que le
    // randonneur peut CHANGER. Les deux leviers sont nommes parce qu ils sont les
    // seuls VRAIS : l entrainement releve le plafond (donc le denominateur du
    // score), et un depart hors ete retire la penalite de chaleur. « Plus de
    // jours » n en est pas un : depuis le lot 634 le verdict vaut la pire
    // JOURNEE, et une journee ne se coupe plus — l annoncer serait mentir.
    const leviers = <AppLocale, List<String>>{
      AppLocale.fr: ['forme', 'été'],
      AppLocale.en: ['fitter', 'summer'],
      AppLocale.de: ['fitter', 'sommer'],
      AppLocale.es: ['forma', 'verano'],
      AppLocale.it: ['forma', 'estate'],
    };

    test('elle nomme ce qui peut changer, dans les 5 langues', () {
      for (final entree in leviers.entries) {
        final rouge = entree.key
            .buildSync()
            .feasibility
            .formula
            .answerRed
            .toLowerCase();
        for (final levier in entree.value) {
          expect(
            rouge,
            contains(levier),
            reason:
                '${entree.key.languageCode} : la reponse rouge « $rouge » ne '
                'dit pas « $levier » — c est un mur, pas une orientation',
          );
        }
      }
    });

    test('elle ne dit ni « pas possible » ni « impossible »', () {
      const murs = <AppLocale, List<String>>{
        AppLocale.fr: ['pas possible', 'impossible', "pas en l'état"],
        AppLocale.en: ['not possible', 'impossible', 'as it stands'],
        AppLocale.de: ['nicht möglich', 'unmöglich', 'so nicht'],
        AppLocale.es: ['no es posible', 'imposible', 'así no'],
        AppLocale.it: ['non possibile', 'impossibile', 'non così'],
      };
      for (final entree in murs.entries) {
        final rouge = entree.key
            .buildSync()
            .feasibility
            .formula
            .answerRed
            .toLowerCase();
        for (final mur in entree.value) {
          expect(
            rouge,
            isNot(contains(mur)),
            reason:
                '${entree.key.languageCode} : « $rouge » dit encore '
                '« $mur » — Christophe a demande « un truc moins clivant »',
          );
        }
      }
    });

    test('le conseil franc oriente aussi, au lieu de renvoyer le randonneur', () {
      // `advice.noViableDuration` est le cas ou AUCUN nombre de jours ne suffit.
      // Il disait « On ne te conseille donc aucune duree — ce n est plus une
      // question de programme. Entraine-toi, ou choisis un sentier moins
      // exigeant. » : un constat, puis une porte. Il doit dire CE QUI marche.
      for (final entree in leviers.entries) {
        final franc = entree.key
            .buildSync()
            .feasibility
            .formula
            .advice
            .noViableDuration(stage: 'X')
            .toLowerCase();
        final nomme =
            entree.value.any(franc.contains) ||
            franc.contains('entraîn') ||
            franc.contains('train') ||
            franc.contains('entren') ||
            franc.contains('allenam');
        expect(
          nomme,
          isTrue,
          reason:
              '${entree.key.languageCode} : « $franc » ne nomme aucun levier',
        );
      }
    });
  });
}
