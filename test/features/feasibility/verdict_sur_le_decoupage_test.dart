import 'package:flutter_test/flutter_test.dart';

import 'package:moteur_gr/i18n/translations.g.dart';

/// LE VERDICT PORTE SUR UN DECOUPAGE, PAS SUR LA PERSONNE (tache 552, 2e passe).
///
/// LE REPROCHE DE CHRIS, MOT POUR MOT : « ca me dit que c'est audessus de mes
/// capacites et que je suis 3 jours au dessus du plafond, ce qui 1/ ne veut rien
/// dire 2/ je n'ai pas encore choisi le nombre de jour. C'est la qu'il faut me
/// conseiller le nombre de jour [...] au lieu de me dire que c'est audessus de
/// mes capacites !!!!!!!!! ».
///
/// ET IL AVAIT RAISON SUR LE FOND, PAS SEULEMENT SUR LE TON. Depuis le lot A
/// (tache 551), le verdict est calcule sur les JOURNEES DE MARCHE du programme :
/// les memes etapes, pour le meme randonneur, donnent VERT a une etape par jour
/// et ROUGE a trois. Ce qui est juge n'est donc pas la personne, c'est le
/// DECOUPAGE — et le meme randonneur repasse au vert en ajoutant un jour. Le
/// libelle « Au-dessus de tes capacites » disait exactement le contraire, et le
/// lot A l'a en plus branche sur la pastille du curseur du Programme : il
/// s'affichait deux fois plus souvent.
///
/// TROIS REGLES SONT VERROUILLEES ICI :
///   1. aucun des trois verdicts ne parle des capacites ni de la personne ;
///   2. les trois NOMMENT le decoupage, pour que le sujet du jugement soit lu
///      par le randonneur et pas devine ;
///   3. ils restent COURTS : ils s'affichent aussi dans la pastille etroite du
///      curseur du Programme, ou « Au-dessus de tes capacites » avait provoque un
///      debordement reel sur telephone (constate par le lot A a 468 px).
void main() {
  /// Les trois libelles de verdict d'une langue.
  List<String> verdicts(AppLocale locale) {
    final v = locale.buildSync().feasibility.formula.verdicts;
    return [v.green, v.orange, v.red];
  }

  group('les trois verdicts', () {
    test('NE parlent NI des capacites NI de la personne', () {
      // Liste NOMMEE par langue : une forme est interdite parce qu'elle est
      // ecrite ici, jamais parce qu'un algorithme la trouve suspecte.
      const interdits = <AppLocale, List<String>>{
        AppLocale.fr: ['capacit', 'niveau', ' tes ', 'ton ', 'tu '],
        AppLocale.en: ['abilit', 'your ', 'you '],
        AppLocale.de: ['niveau', 'dein', 'du '],
        AppLocale.es: ['capacidad', 'tus ', 'tu '],
        AppLocale.it: ['capacit', 'tue ', 'tuo ', 'tua '],
      };
      for (final entree in interdits.entries) {
        for (final libelle in verdicts(entree.key)) {
          for (final mot in entree.value) {
            expect(' ${libelle.toLowerCase()} ', isNot(contains(mot)),
                reason: '${entree.key.languageCode} : le verdict « $libelle » '
                    'parle de la personne (« $mot ») alors qu il juge un '
                    'decoupage');
          }
        }
      }
    });

    test('NOMMENT le decoupage : c est lui qui est juge', () {
      const decoupage = <AppLocale, String>{
        AppLocale.fr: 'découpage',
        AppLocale.en: 'split',
        AppLocale.de: 'aufteilung',
        AppLocale.es: 'reparto',
        AppLocale.it: 'divisione',
      };
      for (final entree in decoupage.entries) {
        for (final libelle in verdicts(entree.key)) {
          expect(libelle.toLowerCase(), contains(entree.value),
              reason: '${entree.key.languageCode} : le verdict « $libelle » ne '
                  'dit pas CE QU IL juge');
        }
      }
    });

    test('restent COURTS : la pastille du curseur est etroite', () {
      // Borne haute = la longueur du plus long libelle retenu (24 car.,
      // italien). « Au-dessus de tes capacites » en faisait 26 et debordait ;
      // le francais est passe a 20. La borne n'est pas decorative : elle tombe
      // si quelqu un rallonge un libelle sans regarder le curseur.
      for (final locale in AppLocale.values) {
        for (final libelle in verdicts(locale)) {
          expect(libelle.length, lessThanOrEqualTo(24),
              reason: '${locale.languageCode} : « $libelle » fait '
                  '${libelle.length} caracteres — trop long pour la pastille du '
                  'curseur du Programme');
        }
      }
    });

    test('aucun n est le PREFIXE d un autre', () {
      // « Faisable » etait un prefixe de « Faisable avec preparation », et un
      // test persona qui cherchait les libelles du plus long au plus court s y
      // etait deja fait piquer.
      for (final locale in AppLocale.values) {
        final libelles = verdicts(locale);
        for (final a in libelles) {
          for (final b in libelles) {
            if (a == b) continue;
            expect(b.startsWith(a), isFalse,
                reason: '${locale.languageCode} : « $a » est un prefixe de '
                    '« $b »');
          }
        }
      }
    });
  });

  group('« etape » ne se dit plus la ou l app compte des JOURNEES', () {
    // Depuis le lot A, une journee de marche peut regrouper DEUX etapes, et les
    // numeros affiches sont des numeros de JOURNEE. Un texte qui dit « etape »
    // quand l'app compte des journees est exactement ce qui fait dire a Chris
    // qu'il ne comprend pas le texte.
    //
    // RESTENT VOLONTAIREMENT HORS DE CETTE LISTE, et pour la meme raison : ils
    // parlent de l'ETAPE en tant qu'objet du topo, pas d'une journee mal nommee.
    //   * advice.balanced (« Repartis les etapes pour lisser l'effort au fil des
    //     jours ») : c'est leur repartition DANS les journees ;
    //   * advice.hardStageAlert (tache 569, R4 — il remplace advice.split, qui
    //     n'existe plus) : « une etape s'arrete la ou il y a un toit » est
    //     precisement CE QU'ON EXPLIQUE au randonneur pour justifier qu'on ne
    //     lui conseille plus de couper sa journee en deux. Retirer le mot y
    //     detruirait l'argument.
    List<String> libellesJournee(AppLocale locale) {
      final f = locale.buildSync().feasibility.formula;
      return [
        f.intro,
        f.stagesTitle,
        f.hardestStage(stage: 'X'),
        f.noStages,
        f.averageLoad(value: '1', worst: '2'),
        f.stageDominantFactor(factor: 'X'),
        f.restTwoDays,
        f.limitingFactors.distance,
        f.advice.noViableDuration(stage: 'X'),
        f.advice.rest(stages: 'X'),
        f.advice.restReference(stages: 'X'),
        f.advice.restAdvised(days: '1', stages: 'X'),
        f.advice.restAdvisedReference(days: '1', stages: 'X'),
      ];
    }

    test('le mot « etape » a disparu de ces treize libelles, en 5 langues', () {
      const motEtape = <AppLocale, String>{
        AppLocale.fr: 'étape',
        AppLocale.en: 'stage',
        AppLocale.de: 'etappe',
        AppLocale.es: 'etapa',
        AppLocale.it: 'tappa',
      };
      for (final entree in motEtape.entries) {
        for (final libelle in libellesJournee(entree.key)) {
          expect(libelle.toLowerCase(), isNot(contains(entree.value)),
              reason: '${entree.key.languageCode} : « $libelle » dit encore '
                  '« ${entree.value} » alors que l app compte des journees');
        }
      }
    });

    test('et le mot « jour » a pris sa place', () {
      // L inverse du test precedent : on ne s est pas contente de retirer le
      // mot, on a dit de quoi on parle. Le titre de section, la pire journee et
      // les trois conseils doivent nommer le jour.
      // Plusieurs formes acceptees par langue : l'espagnol dit « jornada » dans
      // les conseils et « dia » dans le titre de section, les deux nomment bien
      // le jour. Une seule des formes suffit par libelle.
      const motJour = <AppLocale, List<String>>{
        AppLocale.fr: ['jour'],
        AppLocale.en: ['day'],
        AppLocale.de: ['tag'],
        AppLocale.es: ['jornada', 'día'],
        AppLocale.it: ['giorn'],
      };
      for (final entree in motJour.entries) {
        final f = entree.key.buildSync().feasibility.formula;
        final aNommerLeJour = <String>[
          f.stagesTitle,
          f.hardestStage(stage: 'X'),
          // Tache 569 (R4) : l'alerte remplace le conseil de decoupe, et elle
          // doit nommer la JOURNEE qui fait mal — c'est elle que le randonneur
          // va chercher dans sa liste.
          f.advice.hardStageAlert(stage: 'X'),
          f.advice.noViableDuration(stage: 'X'),
          f.advice.rest(stages: 'X'),
          f.advice.restReference(stages: 'X'),
          f.advice.restAdvised(days: '1', stages: 'X'),
          f.advice.restAdvisedReference(days: '1', stages: 'X'),
        ];
        for (final libelle in aNommerLeJour) {
          final nomme =
              entree.value.any((m) => libelle.toLowerCase().contains(m));
          expect(nomme, isTrue,
              reason: '${entree.key.languageCode} : « $libelle » ne nomme pas '
                  'le jour (aucune des formes ${entree.value})');
        }
      }
    });
  });
}
