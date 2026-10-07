import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// GARDE STRUCTURELLE — LA CHAINE QUI DEPOSE SUR TESTFLIGHT RESTE CE QU ELLE
/// EST : LANCEE A LA MAIN, INERTE SANS L IDENTITE APPLE, ET SANS UNE SEULE
/// VALEUR SECRETE EN CLAIR (StepWays tache 621, reecrite le 07/10 sur le
/// modele de GR20 : voir aussi codemagic_signature_ios_modele_gr20_test.dart).
///
/// POURQUOI CETTE GARDE EXISTE. Cette chaine est le SEUL chemin par lequel
/// l application peut atteindre un iPhone : Apple n autorise aucune
/// installation hors magasin, donc il faut TestFlight, donc un bloc de
/// publication — et le lot 619 a mesure qu AUCUNE des six chaines precedentes
/// n en portait. Trois proprietes de cette chaine ne sont pas des details de
/// style, ce sont les raisons pour lesquelles elle est acceptable :
///   1. elle ne se declenche JAMAIS toute seule (un depot consomme chez Apple
///      un numero de build qui ne se reprend pas) ;
///   2. elle s ARRETE proprement tant que l identite Apple n est pas la, au
///      lieu d echouer plus loin sur un message d Xcode illisible ;
///   3. elle ne porte AUCUNE valeur secrete, seulement des NOMS.
/// Un declencheur ajoute par commodite, un controle de presence retire « parce
/// que ca marche maintenant », ou une valeur collee en dur pour depanner :
/// chacun des trois casse une garantie differente, et aucun ne se verrait a la
/// relecture d un diff. Ils se voient ici.
void main() {
  final fichier = File('codemagic.yaml');
  const nomChaine = '  ios_testflight:';

  /// Les trois valeurs d identite Apple que la chaine exige. Personne ne les
  /// saisit : l integration App Store Connect `Only1Cent`, appelee par son nom,
  /// les pose dans l environnement. Ce sont les trois noms que
  /// `app-store-connect` lit par defaut.
  const identite = <String>[
    'APP_STORE_CONNECT_ISSUER_ID',
    'APP_STORE_CONNECT_KEY_IDENTIFIER',
    'APP_STORE_CONNECT_PRIVATE_KEY',
  ];

  /// Les valeurs qui ne doivent JAMAIS recevoir de valeur dans le depot :
  /// l identite Apple, plus l ancienne clef de certificat, devenue sans objet
  /// (le certificat de l equipe vit dans le magasin d identites de Codemagic).
  const secretes = <String>[...identite, 'CERTIFICATE_PRIVATE_KEY'];

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
      // Deux facons de publier chez Codemagic : le bloc declaratif
      // `publishing:` et la commande `app-store-connect publish`. Le depot
      // passe desormais par la seconde (contournement du bug d altool sous
      // Xcode 26) ; on surveille les deux.
      final blocs = <String>[];
      final commandes = <String>[];
      String? courante;
      for (final ligne in lignes) {
        final cle = RegExp(r'^  ([a-z0-9_]+):\s*$').firstMatch(ligne);
        if (cle != null) courante = cle.group(1);
        if (courante == null || RegExp(r'^\s*#').hasMatch(ligne)) continue;
        if (RegExp(r'^    publishing:\s*$').hasMatch(ligne)) {
          blocs.add(courante);
        }
        if (ligne.contains('app-store-connect publish')) {
          commandes.add(courante);
        }
      }
      expect(
        blocs,
        isEmpty,
        reason:
            'un bloc publishing: est reapparu. Il ne laisse pas choisir '
            'l ancien altool, et le nouveau rend « Cannot determine the '
            'Apple ID from Bundle ID » sur les comptes com.only1cent.* : '
            'le depot doit rester une etape de ios_testflight',
      );
      expect(
        commandes,
        equals(['ios_testflight']),
        reason:
            'le depot chez Apple se fait a la main, depuis une seule chaine, '
            'jamais sur un push ni sur une etiquette posee au passage',
      );
    });

    test('elle depose sur TestFlight par l ancien altool, et ne soumet RIEN a '
        'la revue de l App Store', () {
      final depot = blocUtile.indexOf('app-store-connect publish');
      expect(depot, isNot(-1));
      final commande = blocUtile.substring(depot);
      expect(
        commande,
        contains('--testflight'),
        reason:
            'sans cela le paquet monte chez Apple sans jamais etre soumis a '
            'TestFlight',
      );
      expect(
        commande,
        contains("--altool-additional-arguments='--use-old-altool'"),
        reason:
            'LE CONTOURNEMENT DE GR20. Sous Xcode 26, le nouvel altool rend '
            '« Cannot determine the Apple ID from Bundle ID » sur les comptes '
            'multi-apps a prefixe proche, com.only1cent.* nommement : sans '
            'cet argument StepWays ne se deposera pas',
      );
      expect(
        RegExp(r'--app-store(?![-\w])').hasMatch(blocUtile) ||
            blocUtile.contains('submit_to_app_store'),
        isFalse,
        reason:
            'on ne soumet pas a la revue de l App Store depuis une branche '
            'd integration',
      );
      expect(
        blocUtile.contains('beta_groups') || blocUtile.contains('--beta-group'),
        isFalse,
        reason:
            'un groupe de testeurs cite mais inexistant fait echouer la '
            'publication, et un groupe EXTERNE passe par la revue TestFlight. '
            'Christophe est testeur interne de sa propre equipe',
      );
      expect(
        blocUtile.indexOf('flutter build ipa'),
        lessThan(depot),
        reason: 'le depot est la DERNIERE etape, apres la construction',
      );
    });

    test('l identite Apple vient de l integration nommee, pas de variables '
        'saisies', () {
      expect(
        blocUtile,
        contains('integrations:\n      app_store_connect: Only1Cent'),
        reason:
            'sans l integration, aucune identite Apple n arrive dans '
            'l environnement et le depot ne peut pas s authentifier',
      );
      expect(
        blocUtile.contains('stepways_ios_signing'),
        isFalse,
        reason:
            'ce groupe n a jamais existe et ne doit plus etre reclame : '
            'l integration le remplace',
      );
    });

    test('sa PREMIERE etape est l arret propre, et elle nomme l integration '
        'et les trois valeurs manquantes', () {
      final stages = bloc.split(RegExp(r'^      - name:', multiLine: true));
      expect(
        stages.length,
        greaterThan(2),
        reason: 'la chaine n a plus d etapes',
      );
      final premiere = stages[1];

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
        contains("'Only1Cent'"),
        reason: 'le message doit nommer l integration qui fournit l identite',
      );
      for (final nom in identite) {
        expect(
          premiere,
          contains(nom),
          reason:
              'la premiere etape ne verifie plus $nom : son absence ne serait '
              'donc plus dite, et l echec arriverait plus loin, illisible',
        );
      }
      // Le message doit dire OU aller, pas seulement que ca manque.
      expect(premiere, contains('Team integrations'));
      expect(premiere, contains('Developer Portal'));
      expect(
        premiere,
        contains('docs/ci/signature_ios_modele_gr20.md'),
        reason: 'le message renvoie au pas a pas ecran par ecran',
      );
      expect(
        File('docs/ci/signature_ios_modele_gr20.md').existsSync(),
        isTrue,
        reason: 'le message renvoie a un document qui n existe pas',
      );
      // Les anciens gestes sont tombes : les redemander ferait creer une
      // seconde clef d API, ou un second certificat de distribution.
      for (final perime in const [
        'Team Keys',
        'Generate API Key',
        'ssh-keygen',
        'CERTIFICATE_PRIVATE_KEY',
      ]) {
        expect(
          premiere.contains(perime),
          isFalse,
          reason:
              'la premiere etape redemande un geste devenu inutile : '
              '« $perime ». La clef d API et le certificat existent deja',
        );
      }
    });

    test('AUCUNE ligne du fichier n affecte de valeur a ces variables', () {
      final fautives = <String>[];
      for (final nom in secretes) {
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
            'une valeur secrete a ete ecrite dans le depot. L identite Apple '
            'vient de l integration Codemagic et de nulle part ailleurs : '
            '${fautives.join(' | ')}',
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
