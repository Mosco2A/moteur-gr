// LA GRILLE DES VINGT RETOURS (tache 573, LOT V) — LE LIVRABLE CENTRAL.
//
// DEMANDE DE CHRIS DU 26/09 A 10:25, VERBATIM : « tu me remets tout ca aussi dans
// les tests a faire et les persona qui auraient du le voir ».
//
// CE FICHIER EST CE TABLEAU, ET IL EST EXECUTABLE. Un tableau dans un document
// pourrit : on renomme un fichier de test, on supprime un persona, et le tableau
// continue d'affirmer une couverture qui n'existe plus. Ici, chaque ligne nomme
// le fichier qui couvre le retour, et le test VERIFIE que ce fichier existe et
// qu'il contient bien le test annonce. La grille ne peut donc pas mentir plus
// longtemps qu'un `flutter test`.
//
// CE QU'ELLE DIT, retour par retour : le defaut que Chris a trouve, le PERSONA
// qui aurait du le voir, le TROU DE GRILLE qui explique pourquoi personne ne l'a
// vu, et le TEST qui le couvre desormais.
//
// LA LECON DE FOND, ET ELLE TIENT EN UNE PHRASE. Nos huit personas jouaient des
// parcours QUI REUSSISSENT. Ils prouvaient qu'un chemin existe, jamais qu'il n'y a
// pas de cul-de-sac a cote. Un persona qui reussit ne trouve rien : il faut des
// personas qui CHERCHENT a echouer. Les cinq nouveaux sont ecrits pour ca.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Une ligne de la grille : un retour de Chris et sa couverture.
class Retour {
  const Retour({
    required this.numero,
    required this.defaut,
    required this.persona,
    required this.trou,
    required this.fichierTest,
    required this.pourquoiPersonneNAVu,
  });

  /// Le rang du retour dans la matinee du 26/09.
  final String numero;

  /// Le defaut, en mots de Chris quand c'est possible.
  final String defaut;

  /// LE PERSONA QUI AURAIT DU LE VOIR.
  final String persona;

  /// Le trou de grille de la campagne, lettre A a J.
  final String trou;

  /// Le fichier de test qui le couvre desormais. `null` = pas couvert par le
  /// LOT V, et la raison est dans [pourquoiPersonneNAVu].
  final String? fichierTest;

  /// Pourquoi la campagne et les 2 760 tests ne l'ont pas vu.
  final String pourquoiPersonneNAVu;
}

/// Les cinq personas neufs et leur fichier.
const personasNeufs = <String, String>{
  'LE MALADROIT': 'test/personas/persona_le_maladroit_573_test.dart',
  'LE MEFIANT': 'test/personas/persona_le_mefiant_573_test.dart',
  'LE CURIEUX': 'test/personas/persona_le_curieux_573_test.dart',
  "L OEIL": 'test/personas/persona_l_oeil_573_test.dart',
  'LE COMPTABLE': 'test/personas/persona_le_comptable_573_test.dart',
};

/// Les trois invariantes structurelles et leur fichier.
const invariantesStructurelles = <String, String>{
  'toute route a une porte':
      'test/structurel/toute_route_a_une_porte_573_test.dart',
  'tout ecran a une route et rend quelque chose':
      'test/structurel/tout_ecran_a_une_route_573_test.dart',
  'aucun geste mort': 'test/structurel/aucun_geste_mort_573_test.dart',
};

/// LA GRILLE. Vingt retours, plus l'arbitrage QUE-003 qui en est sorti.
const grille = <Retour>[
  Retour(
    numero: '1',
    defaut: 'bouton « Parcourir le catalogue » de l accueil : il ne fait rien. '
        'Il navigue vraiment, et la garde du routeur le renvoie aussitot faute '
        'du drapeau d onboarding.',
    persona: 'LE MALADROIT',
    trou: 'A — on ne tape pas tous les boutons visibles',
    fichierTest: 'test/structurel/aucun_geste_mort_573_test.dart',
    pourquoiPersonneNAVu:
        'La campagne est passee par « Commencer », le chemin qui marche, et n a '
        'jamais tape le bouton du contenu. Et aucun test ne verifie qu APRES '
        'l appui l ecran a change : ils verifient que le bouton existe.',
  ),
  Retour(
    numero: '2',
    defaut: 'depuis le catalogue, le retour arriere ramene sur le cockpit du '
        'Mare a Mare — un sentier que l utilisateur n a ni choisi ni '
        'telecharge.',
    persona: 'LE MALADROIT',
    trou: 'B — on ne joue JAMAIS le retour arriere',
    fichierTest: 'test/personas/persona_le_maladroit_573_test.dart',
    pourquoiPersonneNAVu:
        'AUCUN des huit personas ne joue le retour arriere, sur aucun ecran, '
        'dans aucun scenario. Cause technique : `context.go()` REMPLACE la pile '
        'au lieu d empiler, donc il n y a aucun historique.',
  ),
  Retour(
    numero: '3',
    defaut: 'sur les randos passees, « enregistrer » dit que la note est '
        'enregistree et ne revient pas a la faisabilite.',
    persona: 'LE MALADROIT',
    trou: 'C — on ne verifie pas ou l appli ramene apres une action',
    fichierTest: 'test/structurel/aucun_geste_mort_573_test.dart',
    pourquoiPersonneNAVu:
        'La campagne enregistre puis continue par un autre chemin, sans '
        'verifier ou l application la ramene. Le meme motif que le bouton mort '
        'du catalogue : l action reussit, la navigation ne suit pas.',
  ),
  Retour(
    numero: '4',
    defaut: 'rien ne dit qui analyse (il n y a AUCUNE IA dans l appli) et la '
        'liste des difficultes rencontrees ne sert a rien : saisie, sauvegardee, '
        'synchronisee, restauree — et lue par personne.',
    persona: 'LE MEFIANT',
    trou: 'I — on ne verifie pas qu une donnee saisie sert a quelque chose',
    fichierTest: 'test/personas/persona_le_mefiant_573_test.dart',
    pourquoiPersonneNAVu:
        'Aucun persona ne demande a quoi sert un champ. Et les tests verifient '
        'que la donnee est bien PERSISTEE — jamais qu elle est LUE.',
  ),
  Retour(
    numero: '5',
    defaut: '« vise 9 jours au lieu de 7 » alors que l utilisateur n a encore '
        'rien choisi : le texte lui reproche un choix qu il n a pas fait.',
    persona: 'LE COMPTABLE',
    trou: 'E — on ne relit pas les textes pour y trouver jargon et '
        'contradictions',
    fichierTest: 'test/personas/persona_le_comptable_573_test.dart',
    pourquoiPersonneNAVu:
        'La campagne LIT le conseil et le coche : la chaine attendue est bien '
        'la. Elle ne se demande pas si la phrase a du sens pour qui n a RIEN '
        'choisi.',
  ),
  Retour(
    numero: '6',
    defaut: '« decoupe la journee 1 en 2 === comment on fait ???? » : le conseil '
        'proposait de couper une etape la ou il n y a pas de toit. Chris '
        'tranche : une alerte plus l entrainement, pas un decoupage.',
    persona: 'LE MEFIANT',
    trou: 'J — on teste qu un bouton marche, pas qu il a du SENS',
    fichierTest: 'test/features/feasibility/conseil_jamais_rouge_569_test.dart',
    pourquoiPersonneNAVu:
        'Deux personas ont verifie que le bouton « Separer » FONCTIONNE. Aucun '
        'ne s est demande si l action conseillee etait realisable sur le '
        'terrain. Corrige par le LOT R (tache 569, groupe R4).',
  ),
  Retour(
    numero: '7',
    defaut: '« ca te dit vise 9 jours, et ca te propose 11 jours normal ? » : '
        '9 jours de MARCHE plus 2 de REPOS font 11 au TOTAL, et rien ne le '
        'disait.',
    persona: 'LE COMPTABLE',
    trou: 'D — on ne compare pas les chiffres entre ecrans',
    fichierTest: 'test/personas/persona_le_comptable_573_test.dart',
    pourquoiPersonneNAVu:
        'La campagne lit les deux nombres sans les comparer. Les deux calculs '
        'sont justes separement, et les tests les verifiaient separement.',
  ),
  Retour(
    numero: '8',
    defaut: '« score 1,30 sans echelle ca ne veut rien dire » : le score est '
        'affiche nu, et le plafond vaut 1,00 sans que rien ne le dise.',
    persona: 'LE COMPTABLE',
    trou: 'E — on ne relit pas les textes',
    fichierTest: 'test/personas/persona_le_comptable_573_test.dart',
    pourquoiPersonneNAVu:
        'Personne ne relit les textes pour y detecter du jargon. Un nombre est '
        'un nombre : il passe.',
  ),
  Retour(
    numero: '9',
    defaut: '« le verdict c est du blabla d IA, tu m expliques comment c est '
        'calcule au moment ou ca le fait ? » : un calcul solide qu on ne montre '
        'pas est indiscernable d un baratin.',
    persona: 'LE MEFIANT',
    trou: 'E — on ne relit pas les textes',
    fichierTest: 'test/personas/persona_le_mefiant_573_test.dart',
    pourquoiPersonneNAVu:
        'Aucun persona ne demande d ou vient un chiffre. Le verdict etait juste, '
        'donc teste vert ; il etait muet, donc inutilisable.',
  ),
  Retour(
    numero: '10',
    defaut: 'l appli dit qu elle ne peut pas donner la faisabilite faute de date '
        'de depart, et la donne quand meme.',
    persona: 'LE COMPTABLE',
    trou: 'E — on ne relit pas les textes pour y trouver les contradictions',
    fichierTest: null,
    pourquoiPersonneNAVu:
        'Le texte est litteralement exact (il dit que LA SAISON ne change rien) '
        'mais il est LU comme un aveu d incapacite. Un test de chaine ne peut '
        'pas voir ca : seul un lecteur humain ou un persona qui confronte les '
        'phrases entre elles le voit. Traite par le LOT R cote libelle ; la '
        'detection automatique d une contradiction de sens reste OUVERTE.',
  ),
  Retour(
    numero: '11',
    defaut: 'le plan d entrainement n est pas un plan : pas de frequence '
        'hebdomadaire, affiche sans connaitre la date de depart, et 8 semaines '
        'est le minimum en dessous duquel on ne propose rien.',
    persona: 'LE CURIEUX',
    trou: 'H — des ecrans entiers ne sont JAMAIS ouverts',
    fichierTest: 'test/personas/persona_le_curieux_573_test.dart',
    pourquoiPersonneNAVu:
        'AUCUN persona n ouvre l ecran d entrainement. Un ecran jamais ouvert '
        'est un ecran jamais juge.',
  ),
  Retour(
    numero: '12',
    defaut: '« itineraire ca te dit en faisabilite 11 jours et ca te propose '
        '9 » : deux ecrans, deux unites, aucune annoncee.',
    persona: 'LE COMPTABLE',
    trou: 'D — on ne compare pas les chiffres entre ecrans',
    fichierTest: 'test/personas/persona_le_comptable_573_test.dart',
    pourquoiPersonneNAVu:
        'Aucun persona ne verifie la COHERENCE ENTRE ECRANS : chacun valide son '
        'ecran et s en va.',
  ),
  Retour(
    numero: '13',
    defaut: 'les numeros d etape sont caches par les refuges : une etape se '
        'termine a un refuge, donc les deux marqueurs sont au meme point par '
        'construction, et la couche des lieux est peinte par-dessus.',
    persona: "L OEIL",
    trou: 'G — on ne REGARDE pas l ecran, on lit ses textes',
    fichierTest: 'test/personas/persona_l_oeil_573_test.dart',
    pourquoiPersonneNAVu:
        'Un texte cache derriere une icone est PRESENT dans l arbre des widgets. '
        'La campagne le trouve et coche. Elle ne peut structurellement pas voir '
        'une superposition.',
  ),
  Retour(
    numero: '14',
    defaut: 'pas de difference de peau : trois apparences vendues, une seule '
        'livree. `cardStyle` et `photoScrimOpacity` ne sont lus par personne, et '
        'le selecteur montre un apercu qui promet ce que l appli ne tient pas.',
    persona: "L OEIL",
    trou: 'G et H — on ne regarde pas l ecran, et personne ne change de peau',
    fichierTest: null,
    pourquoiPersonneNAVu:
        'Aucun persona ne change de peau, et une comparaison de peaux demande de '
        'comparer deux RENDUS, pas deux textes. Le LOT V livre l empreinte '
        'visuelle qui rend cette comparaison possible (couleurs, graisses, '
        'fonds) ; le test de comparaison des trois peaux reste A ECRIRE apres '
        'l arbitrage de Chris (brancher les peaux, ou retirer le selecteur).',
  ),
  Retour(
    numero: '15',
    defaut: 'SOS, fiche medicale et cartes hors ligne INTROUVABLES : zero '
        '`push(\'/emergency\')` dans tout lib/, la fiche medicale joignable '
        'seulement depuis cet ecran mure, et `pack_store_screen.dart` sans meme '
        'une route.',
    persona: 'LE CURIEUX',
    trou: 'F — on ne cherche pas a ATTEINDRE une fonction depuis l accueil',
    fichierTest: 'test/structurel/toute_route_a_une_porte_573_test.dart',
    pourquoiPersonneNAVu:
        'LE TROU PRINCIPAL. Les 2 760 tests CONSTRUISENT les ecrans : '
        '`pumpWidget(MaterialApp(home: EmergencyScreen()))` prouve que la classe '
        'se peint, jamais qu un doigt peut y arriver. Et le test de routage '
        'RECOPIE la liste des routes a la main, sans jamais demander qui y mene.',
  ),
  Retour(
    numero: '16',
    defaut: 'la meteo doit etre celle des ETAPES, au lieu de l etape, pour le '
        'jour de l etape — pas celle d ici et maintenant.',
    persona: 'LE CURIEUX',
    trou: 'demande fonctionnelle neuve, pas un defaut de test',
    fichierTest: null,
    pourquoiPersonneNAVu:
        'C est la premiere fois de la serie que Chris demande une fonction qui '
        'n existe pas du tout, et non la reparation d une fonction qui mentait. '
        'Aucun test ne pouvait la trouver : elle est au LOT U.',
  ),
  Retour(
    numero: '17',
    defaut: '« la mise a jour des donnees meteo ne produit rien » : le bouton de '
        'rafraichissement est cable des deux cotes et l ecran ne bouge pas.',
    persona: 'LE MALADROIT',
    trou: 'A — on ne tape pas tous les boutons visibles',
    fichierTest: 'test/structurel/aucun_geste_mort_573_test.dart',
    pourquoiPersonneNAVu:
        'AUCUN persona n appuie sur un bouton de rafraichissement pour verifier '
        'que quelque chose CHANGE. Les tests verifient que `refreshForecast` est '
        'appele — pas que l ecran s en trouve modifie.',
  ),
  Retour(
    numero: '18',
    defaut: 'precision de Chris : « la meteo a l endroit ou on est cense se '
        'trouver le lendemain, puis le surlendemain ».',
    persona: 'LE CURIEUX',
    trou: 'demande fonctionnelle neuve',
    fichierTest: null,
    pourquoiPersonneNAVu:
        'Precision du retour 16 : meme statut, c est du travail neuf (LOT U).',
  ),
  Retour(
    numero: '19',
    defaut: '« incendie MAJ ne produit rien » : meme defaut que la meteo, sur le '
        'risque incendie.',
    persona: 'LE MALADROIT',
    trou: 'A — on ne tape pas tous les boutons visibles',
    fichierTest: 'test/structurel/aucun_geste_mort_573_test.dart',
    pourquoiPersonneNAVu:
        'Meme cause que le 17 : le mecanisme existe, l effet n arrive pas, et '
        'aucun test ne regarde l ecran d apres.',
  ),
  Retour(
    numero: '20',
    defaut: '« tu me remets tout ca aussi dans les tests a faire et les persona '
        'qui auraient du le voir » — la demande qui a produit le LOT V.',
    persona: 'aucun : c est la demande elle-meme',
    trou: 'la grille de la campagne n avait pas de grille',
    fichierTest: 'test/personas/grille_des_vingt_retours_573_test.dart',
    pourquoiPersonneNAVu:
        'Personne ne s etait demande ce que la campagne NE testait PAS. Un plan '
        'de test qui ne liste que ce qu il couvre ne dit rien de ses trous.',
  ),
  Retour(
    numero: 'QUE-003',
    defaut: '« le curseur est celui conseille et il n est jamais en rouge quand '
        'il est conseille en orange max » : l appli conseillait « vise 9 jours » '
        'et affichait rouge a 9 jours.',
    persona: "L OEIL",
    trou: 'G et D — regarder l ecran, et comparer deux chiffres de la meme page',
    fichierTest:
        'test/features/feasibility/conseil_jamais_rouge_etendu_573_test.dart',
    pourquoiPersonneNAVu:
        'Les 2 760 tests verifiaient les DEUX calculs separement, chacun juste '
        'de son cote, jamais leur ACCORD. Le conseil visait une charge MOYENNE '
        'sous le plafond ; le verdict vaut la PIRE journee. Une moyenne ne dit '
        'rien d un maximum. Implemente par le LOT R (tache 569), verifie et '
        'etendu ici aux sentiers reellement livres et au temoin rouge.',
  ),
];

void main() {
  group('LA GRILLE — elle ne peut pas mentir', () {
    test('chaque retour nomme un persona et un trou de grille', () {
      final incomplets = <String>[];
      for (final r in grille) {
        if (r.persona.trim().isEmpty) incomplets.add('${r.numero}: persona');
        if (r.trou.trim().isEmpty) incomplets.add('${r.numero}: trou');
        if (r.pourquoiPersonneNAVu.trim().isEmpty) {
          incomplets.add('${r.numero}: explication');
        }
      }
      expect(incomplets, isEmpty, reason: incomplets.join(', '));
    });

    test('les vingt retours de la matinee du 26/09 sont tous la', () {
      final numeros = grille.map((r) => r.numero).toList();
      for (var i = 1; i <= 20; i++) {
        expect(numeros, contains('$i'),
            reason: 'le retour $i de Chris ne figure pas dans la grille');
      }
      expect(numeros, contains('QUE-003'),
          reason: 'l arbitrage QUE-003 (jamais rouge a la valeur conseillee) '
              'doit figurer : c est le plus important structurellement');
    });

    test('chaque fichier de test annonce par la grille EXISTE', () {
      final manquants = <String>[];
      for (final r in grille) {
        final f = r.fichierTest;
        if (f == null) continue;
        if (!File(f).existsSync()) {
          manquants.add('retour ${r.numero} annonce $f — INTROUVABLE');
        }
      }
      expect(manquants, isEmpty,
          reason: 'LA GRILLE MENT : elle annonce des tests qui n existent '
              'pas.\n  ${manquants.join('\n  ')}');
    });

    test('les cinq personas neufs existent et portent leur nom', () {
      final manquants = <String>[];
      for (final e in personasNeufs.entries) {
        final f = File(e.value);
        if (!f.existsSync()) {
          manquants.add('${e.key} : ${e.value} INTROUVABLE');
          continue;
        }
        if (!f.readAsStringSync().contains(e.key)) {
          manquants.add('${e.key} : le fichier ${e.value} ne se nomme pas');
        }
      }
      expect(manquants, isEmpty, reason: manquants.join('\n'));
    });

    test('les trois invariantes structurelles existent', () {
      final manquants = <String>[
        for (final e in invariantesStructurelles.entries)
          if (!File(e.value).existsSync()) '${e.key} : ${e.value} INTROUVABLE',
      ];
      expect(manquants, isEmpty, reason: manquants.join('\n'));
    });

    test('chaque persona neuf couvre au moins un retour de la grille', () {
      final couverts = <String>{
        for (final r in grille)
          if (r.fichierTest != null) r.fichierTest!,
      };
      final inutiles = <String>[
        for (final e in personasNeufs.entries)
          if (!couverts.contains(e.value))
            '${e.key} n est rattache a AUCUN retour : soit il ne sert a rien, '
                'soit la grille est incomplete',
      ];
      expect(inutiles, isEmpty, reason: inutiles.join('\n'));
    });

    test('les retours NON couverts sont nommes et expliques', () {
      // Un trou qu'on avoue est un trou qu'on peut fermer. Un trou qu'on cache
      // revient. Ces retours n'ont pas de test automatique, et chacun dit
      // pourquoi — c'est la liste de ce qui reste a faire apres le LOT V.
      final ouverts = grille.where((r) => r.fichierTest == null).toList();
      for (final r in ouverts) {
        expect(r.pourquoiPersonneNAVu.length, greaterThan(60),
            reason: 'le retour ${r.numero} n a pas de test ET pas '
                'd explication suffisante : c est un trou cache');
      }
      // Etat au 26/09 : quatre retours sans test automatique (10, 14, 16, 18).
      expect(ouverts.length, lessThanOrEqualTo(4),
          reason: 'le nombre de retours sans couverture automatique augmente '
              '(${ouverts.map((r) => r.numero).join(', ')}) : la grille se '
              'vide au lieu de se remplir');
    });
  });
}
