import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// GARDE STRUCTURELLE — LA CHAINE QUI DEPOSE SUR TESTFLIGHT RESTE CE QU ELLE
/// EST : LANCEE A LA MAIN, INERTE SANS LA CLE, ET SANS UNE SEULE VALEUR DE
/// CONFIGURATION EN CLAIR (StepWays tache 621).
///
/// POURQUOI CETTE GARDE EXISTE. Cette chaine est le SEUL chemin par lequel
/// l application peut atteindre un iPhone : Apple n autorise aucune
/// installation hors magasin, donc il faut TestFlight, donc un bloc de
/// publication — et le lot 619 a mesure qu AUCUNE des six chaines precedentes
/// n en portait. Trois proprietes de cette chaine ne sont pas des details de
/// style, ce sont les raisons pour lesquelles elle est acceptable :
///   1. elle ne se declenche JAMAIS toute seule (un depot consomme chez Apple
///      un numero de build qui ne se reprend pas) ;
///   2. elle s ARRETE proprement tant que les valeurs de signature ne sont pas
///      la, au lieu d echouer plus loin sur un message d Xcode illisible ;
///   3. elle ne porte AUCUNE valeur, seulement des NOMS de variables.
/// Un declencheur ajoute par commodite, un controle de presence retire « parce
/// que ca marche maintenant », ou une valeur collee en dur pour depanner :
/// chacun des trois casse une garantie differente, et aucun ne se verrait a la
/// relecture d un diff. Ils se voient ici.
void main() {
  final fichier = File('codemagic.yaml');
  const nomChaine = '  ios_testflight:';

  /// Les cinq valeurs que la chaine exige, et que Christophe depose dans le
  /// groupe Codemagic `stepways_ios_signing` — les MEMES que `ios_release`,
  /// pour qu un seul groupe rempli allume les deux chaines.
  const attendues = <String>[
    'APP_STORE_CONNECT_ISSUER_ID',
    'APP_STORE_CONNECT_KEY_IDENTIFIER',
    'APP_STORE_CONNECT_PRIVATE_KEY',
    'CERTIFICATE_PRIVATE_KEY',
    'BUNDLE_ID',
  ];

  late List<String> lignes;
  late String bloc;

  /// Le meme bloc SANS ses lignes de commentaire. Indispensable : cette chaine
  /// explique dans ses commentaires ce qu elle NE porte pas (« aucun bloc
  /// triggering », « pas de submit_to_app_store »), et chercher ces mots dans
  /// le texte brut ferait accuser la chaine par sa propre explication.
  late String blocUtile;

  setUpAll(() {
    expect(fichier.existsSync(), isTrue, reason: 'codemagic.yaml introuvable');
    lignes = fichier.readAsLinesSync();

    // Le bloc de la chaine : de sa cle jusqu a la premiere ligne suivante qui
    // ne lui appartient plus — une autre cle de deux espaces, ou un
    // commentaire de deux espaces (l en-tete de la chaine d apres). Meme
    // decoupage que la garde 619, pour la meme raison : decouper sur la cle
    // suivante seulement ferait avaler l en-tete commente de la chaine
    // voisine, qui parle justement de publication.
    final debut = lignes.indexWhere((l) => l.startsWith(nomChaine));
    expect(
      debut,
      isNot(-1),
      reason:
          'la chaine ios_testflight a disparu : sans elle, RIEN ne peut '
          'atteindre un iPhone, et le travail reste dans le depot',
    );
    final corps = <String>[lignes[debut]];
    for (var i = debut + 1; i < lignes.length; i++) {
      if (RegExp(r'^  ([a-z0-9_]+:|#)').hasMatch(lignes[i])) break;
      corps.add(lignes[i]);
    }
    bloc = corps.join('\n');
    blocUtile = corps.where((l) => !RegExp(r'^\s*#').hasMatch(l)).join('\n');
  });

  group('621 — la chaine de depot TestFlight', () {
    test('ne se declenche JAMAIS toute seule', () {
      expect(
        blocUtile.contains('triggering:'),
        isFalse,
        reason:
            'un declencheur a ete ajoute. Sans evenement declare, Codemagic '
            'ne lance cette chaine qu a la main, et c est voulu : un depot '
            'consomme chez Apple un numero de build qui ne se reprend jamais, '
            'et l etiquette v* appartient deja a ios_release',
      );
    });

    test('elle est la SEULE chaine du fichier qui publie quelque part', () {
      final publiantes = <String>[];
      String? courante;
      for (final ligne in lignes) {
        final cle = RegExp(r'^  ([a-z0-9_]+):\s*$').firstMatch(ligne);
        if (cle != null) courante = cle.group(1);
        if (RegExp(r'^    publishing:\s*$').hasMatch(ligne) &&
            courante != null) {
          publiantes.add(courante);
        }
      }
      expect(
        publiantes,
        equals(['ios_testflight']),
        reason:
            'une autre chaine a gagne un bloc de publication. Le depot chez '
            'Apple se fait a la main, depuis une seule chaine, jamais sur un '
            'push ni sur une etiquette posee au passage',
      );
    });

    test('elle depose sur TestFlight et ne soumet RIEN a la revue', () {
      expect(bloc, contains('app_store_connect'));
      expect(
        bloc,
        contains('submit_to_testflight: true'),
        reason:
            'sans cela le paquet monte chez Apple sans jamais devenir '
            'installable pour un testeur',
      );
      expect(
        blocUtile.contains('submit_to_app_store'),
        isFalse,
        reason:
            'on ne soumet pas a la revue de l App Store depuis une branche '
            'd integration',
      );
      expect(
        blocUtile.contains('beta_groups'),
        isFalse,
        reason:
            'un groupe de testeurs cite mais inexistant fait echouer la '
            'publication, et un groupe EXTERNE passe par la revue TestFlight. '
            'Christophe est testeur interne de sa propre equipe',
      );
    });

    test('sa PREMIERE etape est l arret propre, et elle nomme les cinq '
        'valeurs manquantes', () {
      final etapes = bloc.split(RegExp(r'^      - name:', multiLine: true));
      expect(
        etapes.length,
        greaterThan(2),
        reason: 'la chaine n a plus d etapes',
      );
      final premiere = etapes[1];

      expect(
        premiere,
        contains('exit 1'),
        reason:
            'la premiere etape ne peut plus arreter la chaine : un IPA non '
            'signe irait jusqu a Apple, qui le refuserait par courriel apres '
            'coup, minutes macOS depensees',
      );
      expect(
        premiere,
        contains('stepways_ios_signing'),
        reason: 'le message doit nommer le groupe a remplir',
      );
      for (final nom in attendues) {
        expect(
          premiere,
          contains(nom),
          reason:
              'la premiere etape ne verifie plus $nom : son absence ne serait '
              'donc plus dite, et l echec arriverait plus loin, illisible',
        );
      }
      // Le message doit dire OU aller, pas seulement que ca manque.
      expect(premiere, contains('Users and Access'));
      expect(premiere, contains('Team Keys'));
      expect(
        premiere,
        contains('MODOP_621_testflight_pas_a_pas.md'),
        reason: 'le message renvoie au pas a pas ecran par ecran',
      );
    });

    test('AUCUNE ligne du fichier n affecte de valeur a ces variables', () {
      final fautives = <String>[];
      for (final nom in attendues) {
        final affectation = RegExp('^\\s*$nom\\s*[:=]\\s*(\\S.*)\$');
        for (final ligne in lignes) {
          final m = affectation.firstMatch(ligne);
          if (m == null) continue;
          final valeur = m.group(1)!.trim();
          if (!valeur.startsWith(r'$')) fautives.add(ligne.trim());
        }
      }
      expect(
        fautives,
        isEmpty,
        reason:
            'une valeur de signature a ete ecrite dans le depot. Ces cinq '
            'variables se remplissent dans Codemagic et nulle part ailleurs : '
            '${fautives.join(' | ')}',
      );
    });

    test('le bloc de publication ne contient que des renvois de variables', () {
      final debut = bloc.indexOf('app_store_connect:');
      expect(debut, isNot(-1));
      final suite = bloc.substring(debut).split('\n').skip(1);
      final fautives = <String>[];
      for (final ligne in suite) {
        if (!ligne.startsWith('        ')) break;
        final m = RegExp(r'^\s*([a-z_]+):\s*(\S.*)$').firstMatch(ligne);
        if (m == null) continue;
        final valeur = m.group(2)!.trim();
        final autorise =
            valeur.startsWith(r'$') || valeur == 'true' || valeur == 'false';
        if (!autorise) fautives.add(ligne.trim());
      }
      expect(
        fautives,
        isEmpty,
        reason:
            'le bloc de publication porte une valeur en dur au lieu d un '
            'renvoi de variable : ${fautives.join(' | ')}',
      );
    });

    test('les six chaines qui existaient avant sont toujours la', () {
      final source = fichier.readAsStringSync();
      for (final nom in const [
        'pr_gate',
        'merge',
        'android_test',
        'ios_compile',
        'android_release',
        'ios_release',
      ]) {
        expect(
          source,
          contains('  $nom:'),
          reason:
              'la chaine $nom a disparu — la tache 621 n ajoutait qu une '
              'septieme chaine, elle ne devait en retirer aucune',
        );
      }
    });
  });
}
