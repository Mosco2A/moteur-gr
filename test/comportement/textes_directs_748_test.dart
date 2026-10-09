// LOT 748 — LA GARDE DES TEXTES DIRECTS.
//
// LA CONSIGNE DE CHRISTOPHE, VERBATIM (09/10 09:53) : « cryptique = jus d'IA.
// Tu es trop bavard partout ». Et sa correction de 10:00 : « 2 fois moins de
// bull shit et de tournures alambiquees ».
//
// CE QUE CETTE GARDE N'EST PAS : un compte de caracteres. Une phrase courte
// peut rester alambiquee, et une phrase longue peut etre parfaitement directe.
// Compter les signes aurait pousse a tronquer des textes utiles — exactement ce
// que le lot 749 venait d'interdire. On garde donc des TOURNURES, nommees une
// par une.
//
// CE QU'ELLE INTERDIT : les formules par lesquelles l'application se justifie
// au lieu de parler. Elles ont toutes la meme signature — une precaution qui
// commente la phrase precedente au lieu d'ajouter un fait :
//   « c'est un conseil, il ne change pas le verdict »
//   « a ne pas confondre : ... »
//   « ..., pas une regle maison »
//   « ce n'est pas un jugement sur toi »
// Chacune est interdite PARCE QU'ELLE EST ECRITE ICI, jamais parce qu'un
// algorithme la trouverait suspecte. C'est la doctrine de la maison, deja
// posee par decoupage_vocabulaire_interdit_639_test.dart.
//
// PORTEE : les 82 clefs reecrites par le lot 748, et elles seules. Les autres
// textes de l'application n'ont pas encore ete traites (voir le rapport du
// lot) : les soumettre a cette garde la rendrait rouge au premier jour, et une
// garde rouge au premier jour ne garde rien.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Les clefs que le lot 748 a reecrites, dans les cinq langues.
///
/// LISTE EXPLICITE, PAS UN PREFIXE : `feasibility` entier contient des textes
/// que ce lot n'a pas touches. Une garde qui s'etend d'elle-meme a des textes
/// que personne n'a relus est une garde qui finira desactivee.
const List<String> clefsTraitees = <String>[
  'hub.infoSheetBody',
  'hub.startGateHint',
  'hub.trekCard.noTrekBody',
  'hub.finishTrek.confirmBody',
  'hub.cards.feasibilitySub',
  'hub.cards.adjustSub',
  'feasibility.objectiveIntro',
  'feasibility.formula.answerOrange',
  'feasibility.formula.answerRed',
  'feasibility.formula.answerDaysNote',
  'feasibility.formula.answerNoRest',
  'feasibility.formula.intro',
  'feasibility.formula.energyUnitNotice',
  'feasibility.formula.circuitIsWorstStage',
  'feasibility.formula.restNotApplicable',
  'feasibility.formula.restExtrapolation',
  'feasibility.formula.restNotDecisive',
  'feasibility.formula.restTwoDays',
  'feasibility.formula.habitGapNotDecisive',
  'feasibility.formula.floorActive',
  'feasibility.formula.altitudeBelowThreshold',
  'feasibility.formula.altitudeMissing',
  'feasibility.formula.seasonNoSource',
  'feasibility.formula.seasonMissing',
  'feasibility.formula.massNotCounted',
  'feasibility.formula.ageCounted',
  'feasibility.formula.winterInvalid',
  'feasibility.formula.restDaysNone',
  'feasibility.formula.averageLoadInfo',
  'feasibility.formula.durationStatementInfo',
  'feasibility.formula.verdictHowEnergy',
  'feasibility.formula.verdictHowNoBlackBox',
  'feasibility.formula.retainedPlanNone',
  'feasibility.formula.advice.balancedOk',
  'feasibility.formula.advice.balanced',
  'feasibility.formula.advice.optimalDays',
  'feasibility.formula.advice.optimalDaysNoChoice',
  'feasibility.formula.advice.rest',
  'feasibility.formula.advice.training',
  'feasibility.formula.advice.restAdvised',
  'feasibility.formula.advice.hardStageAlert',
  'feasibility.formula.advice.noViableDuration',
  'feasibility.formula.advice.restReference',
  'feasibility.formula.advice.restAdvisedReference',
  'feasibility.flow.intro',
  'feasibility.flow.stepWalkTestSub',
  'feasibility.flow.partialNotice',
  'feasibility.flow.missingIntro',
  'feasibility.flow.missingWalkTestNote',
  'feasibility.flow.hintBlocked',
  'systemBackup.title',
  'systemBackup.explainGoogle',
  'systemBackup.explainApple',
  'systemBackup.cost',
  'systemBackup.whatComesBack',
  'systemBackup.notOurServers',
  'map.perimetreSentier',
  'map.guide.position',
  'map.guide.track',
  'map.guide.centerOnMe',
  'map.guide.photo',
  'map.guide.currentStage',
  'map.guide.offTrack',
  'map.guide.poi.water',
  'map.guide.poi.shelter',
  'map.guide.poi.accommodation',
  'map.guide.poi.campsite',
  'map.guide.poi.shop',
  'map.guide.poi.viewpoint',
  'map.guide.poi.danger',
  'demo.boutonSous',
  'demo.compteRelancerSous',
  'demo.rienNeCompte',
  'demo.arriveeTexte',
  'demo.sortieEnTeteCatalogue',
  'demo.sortieDansMonCompte',
  'demo.collecteTitre',
  'demo.collecteIntro',
  'programme.duration.splitNote',
  'programme.duration.splitExhausted',
  'programme.info.mergeSplit.body',
  'tips.screenIntro',
];

/// Les tournures interdites, langue par langue.
///
/// ELLES SONT TOUTES DU MEME GENRE : une precaution qui commente la phrase
/// d'avant. Christophe en a cite deux lui-meme ; les autres sont leurs soeurs,
/// relevees dans les memes ecrans au moment de la reecriture.
///
/// LES FAUX POSITIFS SONT NOMMES, PAS DEVINES :
///  * « conseil » seul n'est pas interdit — l'application conseille, c'est son
///    travail. Ce qui est interdit, c'est de PREVENIR que le conseil n'est
///    qu'un conseil.
///  * « verdict » seul n'est pas interdit — il nomme le resultat. Ce qui est
///    interdit, c'est « ne change pas le verdict », la precaution.
///  * « boite noire » est interdit jusque dans la clef qui porte son nom
///    (`verdictHowNoBlackBox`) : le texte doit dire CE QUE le calcul est, pas
///    ce qu'il n'est pas.
const Map<String, List<String>> tournuresInterdites = <String, List<String>>{
  'fr': <String>[
    'ne change pas le verdict',
    'ne changent pas le verdict',
    'ne change pas ton verdict',
    'ne changera pas le verdict',
    'est un conseil',
    'a ne pas confondre',
    'à ne pas confondre',
    'pas une regle maison',
    'pas une règle maison',
    'pas un jugement',
    'sans enjoliver',
    "c'est voulu",
    'boite noire',
    'boîte noire',
    'elle est dite',
    "s'affiche et conseille",
    "tel qu'il existe",
  ],
  'en': <String>[
    'does not change the verdict',
    'do not change the verdict',
    'will not change the verdict',
    'not change your verdict',
    'advice only',
    'it is advice',
    'that is advice',
    'not to be confused',
    'house rule',
    'not a judgement',
    'without sugar coating',
    'that is deliberate',
    'black box',
    'is shown and advises',
    "trail's own plan",
  ],
  'de': <String>[
    'ändert das urteil nicht',
    'ändert dein urteil nicht',
    'ist ein rat',
    'eine empfehlung, sie',
    'nicht verwechseln',
    'hausregel',
    'kein urteil über',
    'ohne beschönigung',
    'das ist gewollt',
    'blackbox',
    'wird angezeigt und berät',
    'plan des weges selbst',
  ],
  'it': <String>[
    'non cambia il verdetto',
    'non cambiano il verdetto',
    'non cambierà il verdetto',
    'non cambia il tuo verdetto',
    'è un consiglio',
    'un consiglio, non',
    'da non confondere',
    'regola di casa',
    'giudizio su di te',
    'senza abbellire',
    'scatola nera',
    'è mostrata e consiglia',
    "così com'è",
  ],
  'es': <String>[
    'no cambia el veredicto',
    'no cambian el veredicto',
    'no cambiará el veredicto',
    'no cambia tu veredicto',
    'es un consejo',
    'un consejo, no',
    'no hay que confundirlo',
    'regla de la casa',
    'juicio sobre ti',
    'sin adornos',
    'caja negra',
    'se muestra y aconseja',
    'tal como existe',
  ],
};

/// Les libelles du lot, pour une langue : {clef pointee -> texte}.
///
/// Lecture du JOURNAL DE TRADUCTION, pas des classes generees : une garde qui
/// lit `assets/i18n/*.json` attrape un texte des qu'il est ecrit, meme si
/// personne n'a relance `dart run slang`.
Map<String, String> libellesDuLot(String langue) {
  final File fichier = File('assets/i18n/$langue.i18n.json');
  expect(
    fichier.existsSync(),
    isTrue,
    reason: 'garde inutilisable : ${fichier.path} est introuvable',
  );
  final Map<String, dynamic> racine =
      jsonDecode(fichier.readAsStringSync()) as Map<String, dynamic>;

  final Map<String, String> resultat = <String, String>{};
  for (final String clef in clefsTraitees) {
    Object? noeud = racine;
    for (final String segment in clef.split('.')) {
      if (noeud is Map && noeud.containsKey(segment)) {
        noeud = noeud[segment];
      } else {
        noeud = null;
        break;
      }
    }
    if (noeud is String) resultat[clef] = noeud;
  }
  return resultat;
}

void main() {
  // ---------------------------------------------------------------------------
  // LA GARDE GARDE QUELQUE CHOSE.
  //
  // La contrepartie POSITIVE de l'interdiction, et elle n'est pas decorative :
  // si une clef est renommee ou retiree, la boucle ci-dessous ne la trouve plus
  // et l'interdiction cesse silencieusement de s'appliquer. Un faux vert est
  // pire qu'un rouge.
  // ---------------------------------------------------------------------------
  group('748 — la garde porte bien sur les 82 clefs du lot', () {
    for (final String langue in tournuresInterdites.keys) {
      test('$langue : les ${clefsTraitees.length} clefs sont toutes lues', () {
        final Map<String, String> libelles = libellesDuLot(langue);
        final List<String> manquantes = clefsTraitees
            .where((String c) => !libelles.containsKey(c))
            .toList();
        expect(
          manquantes,
          isEmpty,
          reason:
              '$langue : ${manquantes.length} clef(s) du lot 748 ont disparu '
              'du journal de traduction, la garde ne les protege plus :\n  '
              '${manquantes.join('\n  ')}',
        );
        expect(libelles, isNotEmpty);
      });
    }
  });

  // ---------------------------------------------------------------------------
  // LES TOURNURES NE REVIENNENT PAS.
  // ---------------------------------------------------------------------------
  group('748 — aucune tournure de justification dans les textes du lot', () {
    for (final MapEntry<String, List<String>> entree
        in tournuresInterdites.entries) {
      test('${entree.key} : les textes parlent au lieu de se justifier', () {
        final Map<String, String> libelles = libellesDuLot(entree.key);
        final List<String> fautes = <String>[];
        libelles.forEach((String clef, String libelle) {
          final String bas = libelle.toLowerCase();
          for (final String tournure in entree.value) {
            if (bas.contains(tournure)) {
              fautes.add('$clef  [$tournure]  « $libelle »');
            }
          }
        });
        expect(
          fautes,
          isEmpty,
          reason:
              '${entree.key} : la justification est revenue dans '
              '${fautes.length} libelle(s) :\n  ${fautes.join('\n  ')}',
        );
      });
    }
  });

  // ---------------------------------------------------------------------------
  // LE TEST DU TEST.
  //
  // Les chaines ci-dessous sont les VRAIS textes d'avant le lot 748, dont
  // Christophe a cite le premier mot pour mot. Si le detecteur ne les voyait
  // pas, la garde serait verte pour de mauvaises raisons.
  // ---------------------------------------------------------------------------
  group('748 — le detecteur voit bien ce qu il doit voir (test du test)', () {
    bool fautif(String langue, String texte) {
      final String bas = texte.toLowerCase();
      return tournuresInterdites[langue]!.any(bas.contains);
    }

    test('les anciens textes seraient refuses', () {
      expect(
        fautif(
          'fr',
          'Chaque étape a déjà sa journée : un jour de plus n\'ajoutera que '
              'du repos, et le repos ne changera pas le verdict.',
        ),
        isTrue,
        reason: 'la phrase citee par Christophe doit etre refusee',
      );
      expect(
        fautif(
          'fr',
          'À ne pas confondre : rien de ce que tu nous confies ne part vers '
              'nos serveurs.',
        ),
        isTrue,
      );
      expect(
        fautif(
          'fr',
          'Nous conseillons 2 jour(s) de repos en plus — un conseil, il ne '
              'change pas le verdict.',
        ),
        isTrue,
      );
      expect(
        fautif('en', 'advice only, it does not change the verdict.'),
        isTrue,
      );
      expect(fautif('de', 'ein Rat, er ändert das Urteil nicht.'), isTrue);
      expect(fautif('it', 'è un consiglio, non cambia il verdetto.'), isTrue);
      expect(fautif('es', 'es un consejo, no cambia el veredicto.'), isTrue);
    });

    test('les textes du lot 748 passent, eux', () {
      expect(
        fautif(
          'fr',
          'Impossible d\'étaler plus : chaque étape a déjà sa journée.',
        ),
        isFalse,
      );
      expect(
        fautif(
          'fr',
          'Rien de tout ça ne part vers nos serveurs, que cette case soit '
              'cochée ou non.',
        ),
        isFalse,
      );
      expect(fautif('fr', 'Ajoutez 2 jour(s) de repos.'), isFalse);
      expect(fautif('fr', 'Ton programme est équilibré.'), isFalse);
    });
  });
}
