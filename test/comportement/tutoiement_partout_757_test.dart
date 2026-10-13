// TACHE 757 — LA GARDE DU TUTOIEMENT, DANS LES CINQ LANGUES.
//
// LA DECISION DE CHRISTOPHE, 09/10 15:02, UN SEUL MOT : « Tutoiement ».
// L'application parle a un randonneur, pas a un client. Avant ce lot elle
// melangeait les deux SUR LE MEME ECRAN — la faisabilite disait « votre profil
// reel » en en-tete et « ton profil » trois lignes plus bas — et le defaut
// existait aussi en allemand (Sie contre du), en italien (voi contre tu) et en
// espagnol (usted contre tu). Le pire exemple etait le sommet de la
// demonstration : a l'arrivee, l'application affichait « Bravo, vous etes
// arrive ! » (demo.arriveeTitre).
//
// CE QUE CETTE GARDE FAIT : elle parcourt les CINQ fichiers de traduction et
// rougit si une tournure de vouvoiement reapparait hors de la liste blanche.
//
// CE QU'ELLE N'EST PAS : une heuristique. Chaque marqueur est fautif PARCE
// QU'IL EST NOMME ICI, et chaque exemption est une CLEF NOMMEE, jamais un
// prefixe. C'est la doctrine de la maison, posee par
// decoupage_vocabulaire_interdit_639_test.dart et reprise par
// textes_directs_748_test.dart et i18n_accents_test.dart.
//
// ---------------------------------------------------------------------------
// COMMENT CETTE GARDE EVITE LES FAUX POSITIFS, LANGUE PAR LANGUE
// ---------------------------------------------------------------------------
//
// FRANCAIS — le vouvoiement y est non ambigu : `vous`, `votre`, `vos`,
//   `veuillez`, et les formes verbales en -ez. Le seul piege est le mot qui
//   FINIT par -ez sans etre un verbe. Le corpus n'en contient que deux, et ils
//   sont nommes : `assez` et `chez` (plus `nez` et `rez`, par precaution).
//   Tout le reste des 110 formes en -ez relevees dans le corpus etait bien du
//   vouvoiement — verifie une par une avant la bascule.
//
// ALLEMAND — `Ihnen` et les possessifs `Ihr/Ihre/Ihren/Ihrem/Ihres/Ihrer`
//   majuscules sont signales PARTOUT, tete de phrase comprise : les douze
//   occurrences du corpus sont toutes de politesse et toutes dans les textes
//   legaux. `Sie` demande une regle a part : en allemand
//   le pronom de politesse s'ecrit TOUJOURS avec une majuscule, alors que
//   « sie » (elle / ils) ne la prend qu'en TETE DE PHRASE. La garde ne
//   signale donc `Sie` QUE HORS tete de phrase. C'est un angle mort assume et
//   il est volontaire : sans lui, treize phrases parfaitement tutoyees
//   rougiraient — « Sie wird geteilt » (= elle sera partagee),
//   « Sie zahlt erst ab 1 500 m » (= elle ne compte qu'a partir de 1 500 m),
//   « Sie gehoren dir auf Dauer » (= elles sont a toi pour toujours). Un
//   « Sie » de politesse en tete de phrase passerait ; mais il ne peut pas
//   arriver seul, car une phrase de politesse porte presque toujours aussi un
//   possessif ou un `Ihnen`, qui sont eux signales partout.
//
// ITALIEN — deux registres formels, et deux pieges opposes.
//   1. Le `Lei` de politesse est signale A LA MAJUSCULE SEULEMENT, car « lei »
//      minuscule veut dire « elle » (« e lei a fare da base »). Les possessifs
//      `suo/sua/suoi/sue`, eux, sont signales DANS LES DEUX CASSES : la
//      politesse italienne moderne ecrit volontiers « alla sua portata » en
//      minuscule, et c'est exactement sous cette forme que le vouvoiement
//      s'etait installe dans la faisabilite. Le test du test de ce fichier a
//      d'ailleurs attrape cet angle mort. Les emplois de TROISIEME personne
//      (« la sua giornata » = la journee de l'etape) sont donc des exceptions
//      nommees clef par clef, comme en espagnol.
//   2. Le registre VOI : `voi` et `vostro/vostra/vostri/vostre` sont signales
//      partout. Les formes verbales en -ate/-ete/-ite, elles, sont un nid de
//      faux positifs : le corpus contient `date`, `estate`, `rete`,
//      `coordinate`, `completate`, `salvate`, `posate`, `giornate` — des noms
//      et des participes. La garde ne retient donc QUE des formes nommees, et
//      seulement EN TETE DE PHRASE, la ou vit un imperatif. Les formes
//      indicatives sans ambiguite (`siete`, `avete`, `potete`, `volete`,
//      `dovete`, `sapete`) sont, elles, signalees partout : aucune n'est un
//      nom ni un participe.
//   NOTE : les titres de dialogue a l'infinitif — « Eliminare questo
//   articolo ? », « Controllare il meteo » — ne sont PAS du vouvoiement. C'est
//   l'idiome de l'interface italienne, un registre neutre qui n'adresse pas le
//   lecteur. Le corpus en compte une soixantaine et ils sont laisses tels
//   quels : les basculer aurait ete un choix editorial, pas une mise en
//   conformite.
//
// ESPAGNOL — `usted` / `ustedes` sont surs. Le vrai piege est `su` / `sus`,
//   qui dit « votre » AU VOUVOIEMENT mais aussi « son / sa / leur » a la
//   troisieme personne. Le corpus contient les deux : « cada etapa ya tiene su
//   jornada » (= sa journee a elle, l'etape), « la reserva se hace en su
//   sitio » (= leur site, l'hebergeur). La garde signale donc `su` / `sus`
//   PARTOUT, et chaque emploi legitime a la troisieme personne est une
//   EXCEPTION NOMMEE CLEF PAR CLEF ci-dessous. Ajouter un « su » de troisieme
//   personne obligera donc a l'ecrire ici : c'est le but. Les imperatifs
//   formels (`Pulse`, `Elija`, `Indique`...) sont homographes du subjonctif,
//   donc nommes un par un et signales en tete de phrase seulement.
//
// ANGLAIS — l'anglais NE DISTINGUE PAS tutoiement et vouvoiement : `you`
//   couvre les deux. Il n'y a donc rien a basculer et rien a garder de ce
//   cote. Ce qui se garde, c'est le REGISTRE : les tournures ceremonieuses
//   `please` et `kindly`, qui etaient la trace anglaise du meme defaut. Sept
//   clefs en portaient, toutes corrigees par ce lot.
//
// ---------------------------------------------------------------------------
// LA CONTREPARTIE POSITIVE
// ---------------------------------------------------------------------------
//
// Une garde qui ne lit rien est verte. Trois tests l'empechent ici :
//  - les cinq fichiers doivent rendre un nombre PLAUSIBLE de chaines ;
//  - chaque clef de la liste blanche doit EXISTER dans les cinq fichiers, pour
//    qu'une clef renommee ne desactive pas son exemption en silence ;
//  - le detecteur est teste SUR LES ANCIENS TEXTES : s'il ne les attrape plus,
//    il ne garde plus rien.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// LISTE BLANCHE 1 — LES TEXTES LEGAUX ET RGPD, FORMELS DANS LES CINQ LANGUES
// ---------------------------------------------------------------------------
//
// DECISION : ce qui est legal reste au registre formel, dans les cinq langues.
// Le vouvoiement y est l'usage et il protege le texte : un consentement RGPD
// et un droit a l'effacement ne se negocient pas sur le ton de la connivence.
//
// CES DEUX ECRANS SONT FORMELS EN ENTIER, pas par morceaux : c'est justement
// le melange des registres SUR UN MEME ECRAN que ce lot supprime partout
// ailleurs. Les clefs sont donc nommees une par une — y compris celles qui ne
// portent aujourd'hui aucun marqueur — pour qu'une clef AJOUTEE a l'un de ces
// deux ecrans oblige son auteur a trancher explicitement son registre.
const List<String> clefsLegales = <String>[
  // consent.* — vie privee, consentement, et consentement PUBLICITAIRE
  'consent.onboardingTitle',
  'consent.onboardingIntro',
  'consent.settingsTitle',
  'consent.settingsIntro',
  'consent.settingsEntry',
  'consent.settingsEntryDesc',
  'consent.purposes.locationNavigation',
  'consent.purposes.locationNavigationDesc',
  'consent.purposes.socialSharing',
  'consent.purposes.socialSharingDesc',
  'consent.purposes.publicReporting',
  'consent.purposes.publicReportingDesc',
  'consent.purposes.advertising',
  'consent.purposes.advertisingDesc',
  'consent.purposes.healthData',
  'consent.purposes.healthDataDesc',
  'consent.healthBadge',
  'consent.healthWarning',
  'consent.granted',
  'consent.denied',
  'consent.grant',
  'consent.revoke',
  'consent.decidedOn',
  'consent.notDecided',
  'consent.acceptSelected',
  'consent.declineAll',
  'consent.declineAllNote',
  'consent.declineAllCancel',
  'consent.continueLabel',
  'consent.privacyPolicyLink',
  'consent.adsPrivacyOptions',
  'consent.reviewNeeded',
  'consent.a11y.purposeToggle',
  'consent.a11y.healthSection',
  'consent.a11y.policyButton',
  'consent.healthDataMorphoNote',
  'consent.healthBackupNote',
  // erasure.* — droit a l'effacement
  'erasure.section',
  'erasure.entry',
  'erasure.entryDesc',
  'erasure.dialogTitle',
  'erasure.goesTitle',
  'erasure.goes',
  'erasure.staysTitle',
  'erasure.stays',
  'erasure.finalWarning',
  'erasure.confirmCheckbox',
  'erasure.confirm',
  'erasure.cancel',
  'erasure.done',
  'erasure.error',
  'erasure.a11y.entry',
];

// ---------------------------------------------------------------------------
// LISTE BLANCHE 2 — LES VERBATIM QUE PERSONNE N'A LE DROIT DE REECRIRE
// ---------------------------------------------------------------------------
//
// LES DEUX LIBELLES DES BOUTIQUES, mot pour mot de Christophe (28/09 10:49) :
// « option prechochee, Je refuse la sauvegarde sur le cloud google de mes
// donnees medicales ». Ils citent les boutiques et ils portent deja une
// exception nominative dans i18n_accents_test.dart (« je refuse » est le verbe
// conjugue, pas le participe). Ils sont a la premiere personne et ne portent
// donc aucun marqueur de vouvoiement — ils sont nommes ici quand meme, pour
// que l'intention soit ecrite et non deduite.
const List<String> verbatimBoutiques = <String>[
  'systemBackup.refuseGoogle',
  'systemBackup.refuseApple',
];

// LA CITATION D'UN TIERS, clef par clef ET LANGUE PAR LANGUE.
//
// `training.tooShortWhy` cite Terres d'Aventure mot pour mot : « commencez a
// vous entrainer au moins 2 mois avant de partir » en francais, « beginnen Sie
// mindestens 2 Monate vor der Abreise mit dem Training » en allemand. On ne
// tutoie pas la phrase de quelqu'un d'autre : ce serait falsifier une
// citation. Le reste de ces deux chaines est bien au tutoiement, et les trois
// autres langues ne citent pas la source — elles ne sont donc PAS exemptees.
const List<String> citationsTierces = <String>[
  'fr|training.tooShortWhy',
  'de|training.tooShortWhy',
];

// EXCEPTIONS ITALIENNES ET ESPAGNOLES : le possessif de la TROISIEME personne.
//
// `su` / `sus` en espagnol et `suo` / `sua` / `suoi` / `sue` en italien disent
// « votre » AU REGISTRE FORMEL, mais aussi « son / sa / leur ». Chacune de ces
// clefs a ete lue dans les cinq langues : le possessif y designe un OBJET, pas
// le randonneur, et le francais et l anglais le confirment.
//
// CETTE LISTE A DEJA SERVI. `feasibility.formula.restAdvisedLine` avait ete
// basculee a tort en espagnol (« por debajo de tu umbral ») : le francais dit
// « sous SON seuil » et l anglais « under ITS threshold » — c est le seuil du
// CHIFFRE, pas celui du randonneur. La comparaison des cinq langues a rattrape
// la faute ; elle est revenue a « su umbral ».
const Map<String, String> possessifTroisiemePersonne = <String, String>{
  'hub.startGateHint': 'sus consejos = les conseils de la fiche medicale',
  'feasibility.formula.retainedPlanNone':
      'sus dias / i suoi giorni = les jours du sentier (fr : ses jours)',
  'feasibility.formula.restAdvisedLine':
      'su umbral / la sua soglia = le seuil du chiffre (fr : son seuil)',
  'hebergement.facilitatorNote': 'su sitio = le site de l hebergeur',
  'guides.facilitatorNote': 'su sitio = le site du prestataire',
  'cartesHorsLigne.echec.stockageIndisponible':
      'su almacenamiento / il suo spazio = le stockage du telephone',
  'programme.duration.splitExhausted':
      'su jornada / la sua giornata = la journee de l etape',
  'programme.info.mergeSplit.body':
      'su jornada / la sua giornata = la journee de l etape',
  'systemBackup.cost':
      'su traza, su cuaderno / la sua traccia = la trace et le carnet du trek',
  'systemBackup.notOurServers': 'su propio sistema = le systeme du telephone',
};

// ---------------------------------------------------------------------------
// LES MARQUEURS, NOMMES
// ---------------------------------------------------------------------------

/// Mots qui FINISSENT par -ez sans etre une forme verbale de vouvoiement.
const List<String> finalesEzNonVerbales = <String>[
  'assez',
  'chez',
  'nez',
  'rez',
];

/// Formes VOI italiennes sans ambiguite : ni nom, ni participe.
const List<String> voiIndicatif = <String>[
  'siete',
  'avete',
  'potete',
  'volete',
  'dovete',
  'sapete',
];

/// Imperatifs VOI italiens. Homographes de participes (« le cose portate »),
/// donc signales EN TETE DE PHRASE seulement.
const List<String> voiImperatif = <String>[
  'portate',
  'partite',
  'riempite',
  'dosate',
  'fate',
  'dite',
  'indicate',
  'scegliete',
  'ricopiate',
  'cancellate',
  'consultate',
  'inserite',
  'premete',
  'toccate',
  'andate',
  'venite',
  'tenete',
];

/// Imperatifs formels espagnols. Homographes du subjonctif, donc signales EN
/// TETE DE PHRASE seulement.
const List<String> imperatifsUsted = <String>[
  'pulse',
  'elija',
  'indique',
  'abra',
  'muestre',
  'comunique',
  'llame',
  'copie',
  'consulte',
  'rellene',
  'lleve',
  'reduzca',
  'toque',
  'vuelva',
  'compruebe',
  'gane',
  'salga',
  'dosifique',
  'haga',
  'cuente',
  'observe',
  'escriba',
  'anote',
  'descargue',
  'describa',
  'intente',
  'espere',
  'confirme',
  'guarde',
  'lea',
  'revise',
  'permita',
  'acepte',
];

/// Tournures ceremonieuses anglaises (l'anglais ne distingue pas tu / vous).
const List<String> ceremonieAnglaise = <String>['please', 'kindly'];

const List<String> langues = <String>['fr', 'en', 'de', 'it', 'es'];

// ---------------------------------------------------------------------------
// LECTURE DES FICHIERS
// ---------------------------------------------------------------------------

Map<String, String> _chaines(String langue) {
  final File fichier = File('assets/i18n/$langue.i18n.json');
  if (!fichier.existsSync()) {
    throw StateError(
      'assets/i18n/$langue.i18n.json est introuvable : la garde du tutoiement '
      'ne lirait rien et serait verte pour rien.',
    );
  }
  final Map<String, dynamic> racine =
      jsonDecode(fichier.readAsStringSync()) as Map<String, dynamic>;
  final Map<String, String> plat = <String, String>{};
  void descendre(Map<String, dynamic> noeud, String prefixe) {
    noeud.forEach((String cle, dynamic valeur) {
      final String chemin = prefixe.isEmpty ? cle : '$prefixe.$cle';
      if (valeur is Map<String, dynamic>) {
        descendre(valeur, chemin);
      } else if (valeur is String) {
        plat[chemin] = valeur;
      } else if (valeur is List) {
        for (int i = 0; i < valeur.length; i++) {
          final dynamic element = valeur[i];
          if (element is String) plat['$chemin[$i]'] = element;
        }
      }
    });
  }

  descendre(racine, '');
  return plat;
}

/// Les placeholders de Slang ne sont pas du texte : `$date`, `${days}`,
/// `{count}`. On les retire avant d'analyser, pour qu'un nom de variable ne
/// soit jamais pris pour un mot.
final RegExp _placeholders = RegExp(
  r'\$\{[^}]*\}|\$[A-Za-z_][A-Za-z0-9_]*|\{[^}]*\}',
);

/// Vrai si la position donnee ouvre une phrase : debut de chaine, ou apres un
/// point, un deux-points, un point d'exclamation ou d'interrogation, un retour
/// a la ligne, un tiret cadratin ou une parenthese ouvrante.
bool _ouvreUnePhrase(String texte, int debut) {
  final String avant = texte.substring(0, debut).trimRight();
  if (avant.isEmpty) return true;
  return '.!?:\n—–(;«"'.contains(avant[avant.length - 1]);
}

/// Les marqueurs de vouvoiement trouves dans [valeur] pour [langue].
/// [cle] ne sert qu'aux exceptions nommees.
List<String> marqueurs(String langue, String cle, String valeur) {
  final String texte = valeur.replaceAll(_placeholders, ' ');
  final List<String> trouves = <String>[];

  void motsEntiers(Iterable<String> mots, String etiquette) {
    for (final String mot in mots) {
      final RegExp re = RegExp(
        '(?<![\\p{L}])${RegExp.escape(mot)}(?![\\p{L}])',
        caseSensitive: false,
        unicode: true,
      );
      if (re.hasMatch(texte)) trouves.add('$etiquette:$mot');
    }
  }

  void enTeteDePhrase(Iterable<String> mots, String etiquette) {
    for (final String mot in mots) {
      final RegExp re = RegExp(
        '(?<![\\p{L}])${RegExp.escape(mot)}(?![\\p{L}])',
        caseSensitive: false,
        unicode: true,
      );
      for (final RegExpMatch m in re.allMatches(texte)) {
        if (_ouvreUnePhrase(texte, m.start)) {
          trouves.add('$etiquette:$mot');
          break;
        }
      }
    }
  }

  /// Majuscule obligatoire, n'importe ou dans la chaine.
  void majuscule(Iterable<String> mots, String etiquette) {
    for (final String mot in mots) {
      final RegExp re = RegExp('(?<![\\p{L}])$mot(?![\\p{L}])', unicode: true);
      if (re.hasMatch(texte)) trouves.add('$etiquette:$mot');
    }
  }

  /// Majuscule obligatoire et HORS tete de phrase (cf. en-tete : `Sie` en
  /// allemand n'est un marqueur sur qu'au milieu d'une phrase).
  void majusculeHorsTete(Iterable<String> mots, String etiquette) {
    for (final String mot in mots) {
      final RegExp re = RegExp('(?<![\\p{L}])$mot(?![\\p{L}])', unicode: true);
      for (final RegExpMatch m in re.allMatches(texte)) {
        if (!_ouvreUnePhrase(texte, m.start)) {
          trouves.add('$etiquette:$mot');
          break;
        }
      }
    }
  }

  switch (langue) {
    case 'fr':
      motsEntiers(const <String>['vous', 'votre', 'vos', 'veuillez'], 'fr');
      for (final RegExpMatch m in RegExp(
        r'(?<![\p{L}])[\p{L}]+ez(?![\p{L}])',
        unicode: true,
      ).allMatches(texte)) {
        final String mot = m.group(0)!.toLowerCase();
        if (!finalesEzNonVerbales.contains(mot)) trouves.add('fr:-ez:$mot');
      }
      break;
    case 'de':
      // `Ihnen` et les possessifs `Ihr*` sont signales PARTOUT, tete de phrase
      // comprise : les douze occurrences du corpus sont toutes de politesse,
      // et toutes dans les textes legaux. Un « Ihre » de debut de phrase au
      // sens de « sa / leur » est possible mais n existe pas ici ; le jour ou
      // il arrivera, il prendra une exception nommee, comme ailleurs ici.
      motsEntiers(const <String>['Ihnen'], 'de');
      majuscule(const <String>[
        'Ihr',
        'Ihre',
        'Ihren',
        'Ihrem',
        'Ihres',
        'Ihrer',
      ], 'de');
      // `Sie`, LUI, garde l exemption de tete de phrase : c est le seul vrai
      // homographe a haute frequence (elle / ils / vous de politesse).
      majusculeHorsTete(const <String>['Sie'], 'de');
      break;
    case 'it':
      motsEntiers(const <String>[
        'voi',
        'vostro',
        'vostra',
        'vostri',
        'vostre',
      ], 'it');
      motsEntiers(voiIndicatif, 'it:voi');
      enTeteDePhrase(voiImperatif, 'it:voi');
      // `Lei` et `suo/sua/suoi/sue` sont signales DANS LES DEUX CASSES : la
      // politesse italienne moderne ecrit souvent « alla sua portata » en
      // minuscule, et c est precisement sous cette forme que le vouvoiement
      // s etait installe dans la faisabilite. Les emplois de troisieme
      // personne sont des exceptions NOMMEES, comme en espagnol.
      majuscule(const <String>['Lei'], 'it:lei');
      if (!possessifTroisiemePersonne.containsKey(cle)) {
        motsEntiers(const <String>[
          'suo',
          'sua',
          'suoi',
          'sue',
        ], 'it:possessif');
      }
      break;
    case 'es':
      motsEntiers(const <String>['usted', 'ustedes'], 'es');
      if (!possessifTroisiemePersonne.containsKey(cle)) {
        motsEntiers(const <String>['su', 'sus'], 'es:possessif');
      }
      enTeteDePhrase(imperatifsUsted, 'es:imperatif');
      break;
    case 'en':
      motsEntiers(ceremonieAnglaise, 'en:ceremonie');
      break;
  }
  return trouves;
}

void main() {
  // -------------------------------------------------------------------------
  // LA GARDE
  // -------------------------------------------------------------------------
  group('757 — le vouvoiement ne revient pas, dans les cinq langues', () {
    final Set<String> exemptees = <String>{
      ...clefsLegales,
      ...verbatimBoutiques,
    };

    for (final String langue in langues) {
      test('$langue : aucune tournure de vouvoiement hors liste blanche', () {
        final Map<String, String> chaines = _chaines(langue);
        final List<String> fautes = <String>[];
        chaines.forEach((String cle, String valeur) {
          // Une clef de tableau garde le chemin de son parent.
          final String cleNue = cle.replaceAll(RegExp(r'\[\d+\]$'), '');
          if (exemptees.contains(cleNue)) return;
          if (citationsTierces.contains('$langue|$cleNue')) return;
          final List<String> m = marqueurs(langue, cleNue, valeur);
          if (m.isNotEmpty) {
            fautes.add(
              '$langue.i18n.json | $cle | [$valeur] | ${m.join(", ")}',
            );
          }
        });
        expect(
          fautes,
          isEmpty,
          reason:
              'LE VOUVOIEMENT EST REVENU. L application tutoie le randonneur '
              'partout (decision de Christophe du 09/10 15:02). Si le texte '
              'ci-dessous est un texte LEGAL ou RGPD, nomme sa clef dans '
              '`clefsLegales`. Si c est la citation d un tiers, nomme-la dans '
              '`citationsTierces`. Si c est un « su » espagnol de troisieme '
              'personne, nomme sa clef dans `possessifTroisiemePersonne`. '
              'Sinon, '
              'c est le texte qu il faut corriger, pas la garde :\n'
              '${fautes.join("\n")}',
        );
      });
    }
  });

  // -------------------------------------------------------------------------
  // LA CONTREPARTIE POSITIVE — une garde qui ne lit rien serait verte
  // -------------------------------------------------------------------------
  group('757 — la garde lit bien les cinq fichiers', () {
    test('chaque langue rend un nombre plausible de chaines', () {
      for (final String langue in langues) {
        final Map<String, String> chaines = _chaines(langue);
        expect(
          chaines.length,
          greaterThan(1900),
          reason:
              '$langue : seulement ${chaines.length} chaines lues. Le fichier '
              'est tronque, ou le parcours ne descend plus dans l arbre : la '
              'garde du vouvoiement ne verrait presque rien.',
        );
      }
    });

    test('chaque clef de la liste blanche existe dans les cinq fichiers', () {
      // UNE CLEF RENOMMEE DESACTIVERAIT SON EXEMPTION EN SILENCE : le texte
      // legal passerait sous la garde et rougirait, ou — pire — une exemption
      // resterait posee sur un chemin mort.
      final List<String> manquantes = <String>[];
      for (final String langue in langues) {
        final Map<String, String> chaines = _chaines(langue);
        for (final String cle in <String>[
          ...clefsLegales,
          ...verbatimBoutiques,
        ]) {
          if (!chaines.containsKey(cle)) manquantes.add('$langue|$cle');
        }
        for (final String cle in possessifTroisiemePersonne.keys) {
          if ((langue == 'es' || langue == 'it') && !chaines.containsKey(cle)) {
            manquantes.add('$langue|$cle (exception possessif 3e personne)');
          }
        }
        for (final String entree in citationsTierces) {
          final List<String> part = entree.split('|');
          if (part.first == langue && !chaines.containsKey(part.last)) {
            manquantes.add('$entree (citation tierce)');
          }
        }
      }
      expect(
        manquantes,
        isEmpty,
        reason:
            'Ces clefs de la liste blanche n existent plus. Une exemption '
            'posee sur un chemin mort ne protege rien :\n'
            '${manquantes.join("\n")}',
      );
    });

    test('les textes legaux sont bien restes au registre formel', () {
      // LE PENDANT DE LA GARDE : la liste blanche AUTORISE le vouvoiement, elle
      // ne l EXIGE pas. Sans ce test, quelqu un pourrait tutoyer le
      // consentement RGPD et la garde resterait verte. On verifie donc que
      // chaque langue porte ENCORE du formel sur ces deux ecrans.
      const Map<String, int> plancher = <String, int>{
        'fr': 10,
        'de': 10,
        'it': 8,
        'es': 10,
      };
      plancher.forEach((String langue, int minimum) {
        final Map<String, String> chaines = _chaines(langue);
        int formelles = 0;
        for (final String cle in clefsLegales) {
          final String? valeur = chaines[cle];
          if (valeur == null) continue;
          if (marqueurs(langue, cle, valeur).isNotEmpty) formelles++;
        }
        expect(
          formelles,
          greaterThanOrEqualTo(minimum),
          reason:
              '$langue : seulement $formelles clefs legales portent encore un '
              'marqueur de registre formel. Les textes RGPD (consentement, '
              'confidentialite, consentement publicitaire, effacement) '
              'restent au registre formel dans les cinq langues.',
        );
      });
    });
  });

  // -------------------------------------------------------------------------
  // LE TEST DU TEST — le detecteur attrape-t-il encore les anciens textes ?
  // -------------------------------------------------------------------------
  group('757 — le detecteur attrape bien les anciens textes', () {
    test('les chaines d avant la bascule sont toutes signalees', () {
      // Les vrais textes de la branche 742, avant ce lot.
      const Map<String, String> avant = <String, String>{
        'fr|demo.arriveeTitre': 'Bravo, vous êtes arrivé !',
        'fr|stage.advice.waterAmple':
            'Remplissez vos gourdes à chaque point d\'eau rencontré.',
        'fr|hub.cards.feasibilitySub': 'À votre portée ?',
        'fr|moderation.errorRequired':
            'Veuillez compléter le motif, votre e-mail et la déclaration de '
            'bonne foi.',
        'fr|checklist.ui.infoCheckBody':
            'Cochez ce que vous emportez — le poids se recalcule en haut.',
        'de|demo.arriveeTitre': 'Glückwunsch, Sie sind angekommen!',
        'de|hub.infoSheetBody':
            'Planen Sie Ihre Route, dann Ihren Rucksack. Starten Sie danach '
            'die GPS-Navigation.',
        'de|sos.positionTitle': 'Ihre aktuelle Position',
        'de|monetization.rechargeSubtitle':
            'Etappen schalten Wanderungen frei. Sie gehören Ihnen auf Dauer.',
        'it|health.section.identity': 'Chi siete',
        'it|health.phoneCard.title':
            'Ricopiate la vostra scheda in quella del telefono',
        'it|stage.waterSources.none':
            'Nessun punto d\'acqua segnalato su questa tappa. Portate almeno '
            '3 L a persona.',
        'it|feasibility.formula.answerTitle': 'È alla sua portata?',
        'es|health.section.identity': 'Quién es usted',
        'es|sos.positionTitle': 'Su posición actual',
        'es|health.hint.birthDate': 'Pulse para elegir',
        'es|feasibility.formula.answerGreen':
            'Sí. Este sendero está a su alcance en 9 días.',
        'en|waypoints.contribution.emptyComment':
            'Please enter your '
            'observation.',
      };
      final List<String> rates = <String>[];
      avant.forEach((String entree, String texte) {
        final List<String> part = entree.split('|');
        if (marqueurs(part.first, part.last, texte).isEmpty) {
          rates.add('$entree : [$texte]');
        }
      });
      expect(
        rates,
        isEmpty,
        reason:
            'LE DETECTEUR NE VOIT PLUS CE QU IL EST CENSE VOIR. Ces chaines '
            'etaient le vouvoiement d avant la tache 757 et ne sont plus '
            'signalees : la garde est devenue decorative.\n'
            '${rates.join("\n")}',
      );
    });

    test('les tournures tutoyees equivalentes ne sont PAS signalees', () {
      // Le pendant : un detecteur qui signale tout serait inutilisable. Ces
      // chaines sont les textes d APRES la bascule, et aussi les faux positifs
      // nommes dans l en-tete.
      const Map<String, String> apres = <String, String>{
        'fr|demo.arriveeTitre': 'Bravo, tu es arrivé !',
        'fr|stage.advice.waterAmple':
            'Remplis tes gourdes à chaque point d\'eau rencontré.',
        'fr|checklist.ui.infoCheckBody':
            'Coche ce que tu emportes — le poids se recalcule en haut.',
        // Les deux seuls mots en -ez du corpus qui ne sont pas des verbes.
        'fr|_assez': 'Correct mais lourd, assez pour aujourd\'hui.',
        'fr|_chez': 'La réservation se fait chez l\'hébergeur.',
        'de|demo.arriveeTitre': 'Glückwunsch, du bist angekommen!',
        'de|sos.positionTitle': 'Deine aktuelle Position',
        // « Sie » en tete de phrase = elle / ils, jamais la politesse.
        'de|signalement.savedPendingSync':
            'Sie wird geteilt, sobald das Netzwerk wieder da ist.',
        'de|feasibility.formula.altitudeBelowThreshold':
            'Höhe: 1 200 m am höchsten Punkt. Sie zählt erst ab 1 500 m.',
        'it|health.section.identity': 'Chi sei',
        // « lei » minuscule = elle. Et l infinitif est l idiome UI italien.
        'it|feasibility.formula.floorActive':
            'La tua migliore giornata supera la soglia: è lei a fare da base.',
        'it|checklist.ui.deleteItemTitle': 'Eliminare questo articolo?',
        'it|hub.cards.calendarSub': 'Scegli le date',
        'es|health.section.identity': 'Quién eres',
        'es|sos.positionTitle': 'Tu posición actual',
        'en|waypoints.contribution.emptyComment': 'Enter your observation.',
      };
      final List<String> abusifs = <String>[];
      apres.forEach((String entree, String texte) {
        final List<String> part = entree.split('|');
        final List<String> m = marqueurs(part.first, part.last, texte);
        if (m.isNotEmpty) abusifs.add('$entree : [$texte] -> ${m.join(", ")}');
      });
      expect(
        abusifs,
        isEmpty,
        reason:
            'LE DETECTEUR SIGNALE DU TUTOIEMENT CORRECT. Il produirait des '
            'faux positifs et finirait desactive :\n${abusifs.join("\n")}',
      );
    });
  });
}
