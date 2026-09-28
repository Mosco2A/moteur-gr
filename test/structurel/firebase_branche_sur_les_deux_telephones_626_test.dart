import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/firebase_config.dart';

/// GARDE STRUCTURELLE — FIREBASE EST BRANCHE SUR LES DEUX TELEPHONES, ET LE
/// TUYAU NE PEUT PLUS SE DEBRANCHER EN SILENCE (StepWays, tache 626).
///
/// CE QUI ETAIT MESURE LE 28/09/2026 AU SOIR, ET C EST SANS APPEL.
///
///  1. `android/app/google-services.json` n est pas dans le depot (exclu par
///     `.gitignore` depuis la tache 604) et AUCUNE chaine de fabrication ne le
///     fournissait. La tache 619 a rendu les greffons Gradle conditionnels pour
///     que le paquet se construise quand meme : l APK sortait, et Firebase y
///     dormait.
///  2. `ios/Runner/GoogleService-Info.plist` n etait reference NULLE PART dans
///     `ios/Runner.xcodeproj/project.pbxproj` (mesure de la tache 618, point
///     3). Meme depose a la main, il n entrait pas dans le paquet : le SDK ne
///     lisait donc rien, et Firebase restait muet sur l iPhone aussi.
///
/// Consequence : rien de ce que le collecteur serveur publie ne pouvait
/// arriver sur le telephone de Christophe.
///
/// POURQUOI CETTE GARDE EST ECRITE COMME CA, ET PAS PLUS SIMPLEMENT. La lecon
/// du lot 618 : chercher une chaine de caracteres dans TOUT le `pbxproj` ne
/// prouve RIEN. Le fichier porte quatre sections qui se ressemblent et TROIS
/// phases « Resources » — celle de `RunnerTests`, celle de `Runner` et celle de
/// `TrekWidgetExtension`. Une reference posee dans la phase du widget passerait
/// un `contains` naif au vert alors que le fichier n entrerait JAMAIS dans le
/// paquet de l application. On RESOUT donc la chaine de renvois, exactement
/// comme Xcode : cible nommee `Runner` -> ses phases -> la phase Resources qui
/// lui appartient -> l entree PBXBuildFile -> le PBXFileReference. Et le
/// dernier test de ce groupe DEMONTRE que la garde devient rouge quand on casse
/// le projet : une invariante qui reste verte quand le projet est casse est
/// pire que pas d invariante.
void main() {
  final pbxprojFichier = File('ios/Runner.xcodeproj/project.pbxproj');
  const nomDuPlist = 'GoogleService-Info.plist';
  const scriptConfig = 'scripts/ci/config_firebase.sh';

  /// Isole une section nommee du pbxproj, bornes exclues.
  ///
  /// C est la brique qui evite le piege du lot 618 : on ne cherche jamais dans
  /// tout le fichier, on cherche DANS la section concernee.
  String section(String source, String nom) {
    final debut = source.indexOf('/* Begin $nom section */');
    final fin = source.indexOf('/* End $nom section */');
    expect(debut, isNot(-1), reason: 'section $nom absente du pbxproj');
    expect(fin, greaterThan(debut), reason: 'section $nom mal fermee');
    return source.substring(debut, fin);
  }

  /// Le corps d un objet du pbxproj, designe par son identifiant.
  ///
  /// Rend le texte entre l accolade ouvrante de l objet et son accolade
  /// fermante, en comptant les accolades imbriquees — un decoupage sur la
  /// premiere `}` rencontree couperait au milieu d un `settings = { ... }`.
  String? objet(String source, String identifiant) {
    final ancre = RegExp('^\\t\\t$identifiant [^=]*= \\{', multiLine: true)
        .firstMatch(source);
    if (ancre == null) return null;
    var profondeur = 0;
    for (var i = ancre.end - 1; i < source.length; i++) {
      final c = source[i];
      if (c == '{') profondeur++;
      if (c == '}') {
        profondeur--;
        if (profondeur == 0) return source.substring(ancre.end, i);
      }
    }
    return null;
  }

  /// Les identifiants listes dans un champ `files = ( ... );` ou
  /// `buildPhases = ( ... );` d un objet.
  List<String> liste(String corpsObjet, String champ) {
    final bloc = RegExp('$champ = \\(([^)]*)\\)').firstMatch(corpsObjet);
    if (bloc == null) return const [];
    return RegExp(r'\b([0-9A-F]{24})\b')
        .allMatches(bloc.group(1)!)
        .map((m) => m.group(1)!)
        .toList();
  }

  /// La chaine de renvois complete, telle que Xcode la suit.
  ///
  /// Rend les chemins des fichiers que la cible [nomCible] copie reellement
  /// dans son paquet. Tout maillon casse rend une liste vide ou incomplete —
  /// c est le but.
  List<String> ressourcesCopieesPar(String source, String nomCible) {
    final cibles = section(source, 'PBXNativeTarget');
    final ancreCible =
        RegExp('^\\t\\t([0-9A-F]{24}) /\\* $nomCible \\*/ = \\{',
                multiLine: true)
            .firstMatch(cibles);
    if (ancreCible == null) return const [];
    final corpsCible = objet(cibles, ancreCible.group(1)!);
    if (corpsCible == null) return const [];

    final phasesDeLaCible = liste(corpsCible, 'buildPhases');
    final sectionResources = section(source, 'PBXResourcesBuildPhase');
    final sectionBuildFile = section(source, 'PBXBuildFile');
    final sectionFileRef = section(source, 'PBXFileReference');

    final chemins = <String>[];
    for (final phase in phasesDeLaCible) {
      final corpsPhase = objet(sectionResources, phase);
      // La phase n est pas une phase Resources : ce n est pas une anomalie.
      if (corpsPhase == null) continue;
      for (final buildFile in liste(corpsPhase, 'files')) {
        final ligne = RegExp('^\\t\\t$buildFile [^\\n]*\$', multiLine: true)
            .firstMatch(sectionBuildFile);
        if (ligne == null) continue;
        final fileRef =
            RegExp(r'fileRef = ([0-9A-F]{24})').firstMatch(ligne.group(0)!);
        if (fileRef == null) continue;
        final ligneRef =
            RegExp('^\\t\\t${fileRef.group(1)} [^\\n]*\$', multiLine: true)
                .firstMatch(sectionFileRef);
        if (ligneRef == null) continue;
        final chemin =
            RegExp(r'path = "?([^";]+)"?;').firstMatch(ligneRef.group(0)!);
        if (chemin != null) chemins.add(chemin.group(1)!.trim());
      }
    }
    return chemins;
  }

  // ------------------------------------------------------------------
  // 1. IPHONE — LA REFERENCE EST DANS LA PHASE DE COPIE DE LA BONNE CIBLE
  // ------------------------------------------------------------------
  group('626 — iPhone : le fichier de configuration entre dans le paquet', () {
    test('LE POINT DU LOT : GoogleService-Info.plist est copie par la cible '
        'Runner, pas seulement mentionne quelque part dans le pbxproj', () {
      expect(pbxprojFichier.existsSync(), isTrue);
      final source = pbxprojFichier.readAsStringSync();

      final copiees = ressourcesCopieesPar(source, 'Runner');
      expect(
        copiees,
        contains(nomDuPlist),
        reason:
            'AVANT CE LOT LA LISTE NE LE CONTENAIT PAS, et c est la raison pour '
            'laquelle Firebase etait muet sur l iPhone : le SDK cherche '
            '$nomDuPlist DANS LE PAQUET. Un fichier depose dans ios/Runner/ '
            'mais absent de la phase de copie de la cible Runner n y arrive '
            'jamais. Ressources reellement copiees : ${copiees.join(', ')}',
      );
    });

    test('la reference designe bien un fichier de Runner/, la ou le script de '
        'fabrication le depose', () {
      final source = pbxprojFichier.readAsStringSync();
      final sectionGroup = section(source, 'PBXGroup');
      final ancre = RegExp(r'^\t\t([0-9A-F]{24}) /\* Runner \*/ = \{',
              multiLine: true)
          .firstMatch(sectionGroup);
      expect(ancre, isNotNull, reason: 'le groupe Runner a disparu du projet');
      final corps = objet(sectionGroup, ancre!.group(1)!)!;

      expect(
        corps,
        contains('path = Runner;'),
        reason: 'le groupe Runner doit rester ancre sur le dossier Runner/ : '
            'c est ce qui resout le chemin relatif du plist',
      );

      final sectionFileRef = section(source, 'PBXFileReference');
      final enfants = liste(corps, 'children');
      final cheminsDuGroupe = <String>[];
      for (final enfant in enfants) {
        final ligne = RegExp('^\\t\\t$enfant [^\\n]*\$', multiLine: true)
            .firstMatch(sectionFileRef);
        if (ligne == null) continue;
        final chemin =
            RegExp(r'path = "?([^";]+)"?;').firstMatch(ligne.group(0)!);
        if (chemin != null) cheminsDuGroupe.add(chemin.group(1)!.trim());
      }
      expect(
        cheminsDuGroupe,
        contains(nomDuPlist),
        reason:
            'sans appartenance au groupe Runner, le fichier ne se voit pas dans '
            'Xcode et le chemin du PBXFileReference ne se resout pas sur '
            'ios/Runner/$nomDuPlist — celui-la meme que le script de '
            'fabrication ecrit',
      );
    });

    test('CETTE GARDE DEVIENT ROUGE QUAND ON CASSE LE PROJET — demonstration '
        'sur une copie mutee, le depot n est pas touche', () {
      final source = pbxprojFichier.readAsStringSync();

      // Mutation 1 — on retire l entree de la phase de copie (le defaut REEL
      // d avant ce lot : le fichier reste declare, mais plus personne ne le
      // copie).
      final sansCopie = source.replaceAll(
        RegExp(r'\n\t\t\t\tE626F0000000000000000001 [^\n]*\n'),
        '\n',
      );
      expect(sansCopie, isNot(source),
          reason: 'la mutation n a rien change : le test ne prouve rien');
      expect(
        ressourcesCopieesPar(sansCopie, 'Runner'),
        isNot(contains(nomDuPlist)),
        reason: 'LA GARDE EST VIDE. Elle resterait verte alors que le fichier '
            'n est plus copie dans le paquet, ce qui est exactement le defaut '
            'que ce lot ferme.',
      );

      // Mutation 2 — l entree existe mais dans la phase d une AUTRE cible : on
      // la deplace dans la phase Resources de TrekWidgetExtension. Un
      // `contains` naif sur tout le fichier, ou meme sur la section
      // PBXResourcesBuildPhase entiere, resterait vert.
      const phaseDuWidget = 'E519B00000000000000000D4';
      final debutPhase = sansCopie.indexOf('$phaseDuWidget /* Resources */');
      expect(debutPhase, isNot(-1),
          reason: 'la phase Resources du widget a change d identifiant : cette '
              'demonstration doit etre reecrite, pas supprimee');
      final apresFiles =
          sansCopie.indexOf('files = (\n', debutPhase) + 'files = (\n'.length;
      final versLeWidget = sansCopie.replaceRange(
        apresFiles,
        apresFiles,
        '\t\t\t\tE626F0000000000000000001 '
            '/* GoogleService-Info.plist in Resources */,\n',
      );
      expect(versLeWidget, isNot(sansCopie),
          reason: 'la mutation « deplacer vers la cible du widget » n a rien '
              'change : le test ne prouve rien');
      expect(
        versLeWidget.contains('$nomDuPlist in Resources'),
        isTrue,
        reason: 'la mutation garde bien la chaine dans le fichier — c est tout '
            'le point : un contains naif ne verrait rien',
      );
      expect(
        ressourcesCopieesPar(versLeWidget, 'Runner'),
        isNot(contains(nomDuPlist)),
        reason: 'LA GARDE CONFOND LES CIBLES. Le plist copie par '
            'TrekWidgetExtension n arrive pas dans le paquet de '
            'l application : Firebase resterait muet.',
      );
    });
  });

  // ------------------------------------------------------------------
  // 2. LE FILET — LA COMPILATION NE CASSE PAS QUAND LE FICHIER EST ABSENT
  // ------------------------------------------------------------------
  group('626 — referencer un fichier hors depot ne casse aucune branche', () {
    test('une phase de script garantit le fichier AVANT la copie, et le '
        'declare en SORTIE', () {
      final source = pbxprojFichier.readAsStringSync();

      // L ordre compte litteralement : Xcode execute les phases dans l ordre
      // declare. Une garantie posee APRES la copie ne garantit rien.
      final cibles = section(source, 'PBXNativeTarget');
      final ancre = RegExp(r'^\t\t([0-9A-F]{24}) /\* Runner \*/ = \{',
              multiLine: true)
          .firstMatch(cibles)!;
      final phases = liste(objet(cibles, ancre.group(1)!)!, 'buildPhases');

      final sectionScript = section(source, 'PBXShellScriptBuildPhase');
      final sectionResources = section(source, 'PBXResourcesBuildPhase');

      final indexGarantie = phases.indexWhere((p) {
        final corps = objet(sectionScript, p);
        return corps != null && corps.contains('garantir-ios');
      });
      final indexCopie =
          phases.indexWhere((p) => objet(sectionResources, p) != null);

      expect(indexGarantie, isNot(-1),
          reason:
              'aucune phase de la cible Runner ne garantit le plist. Sur un '
              'clone neuf le fichier est absent (il est exclu du depot) et '
              'xcodebuild s arrete sur « Build input file cannot be found » : '
              'la chaine ios_compile de la tache 618, qui compile sur TOUTE '
              'branche, tomberait au rouge partout.');
      expect(indexCopie, isNot(-1));
      expect(indexGarantie, lessThan(indexCopie),
          reason: 'la garantie doit passer AVANT la copie des ressources, '
              'sinon elle arrive apres l erreur qu elle doit eviter');

      final corpsGarantie = objet(sectionScript, phases[indexGarantie])!;
      expect(
        corpsGarantie,
        contains(nomDuPlist),
        reason: 'C EST LA LIGNE QUI EVITE L ERREUR DE PLANIFICATION. Xcode le '
            'dit lui-meme dans son message : « Did you forget to declare this '
            'file as an output of a script phase ». Sans outputPaths, Xcode '
            'refuse le projet avant meme de lancer la phase.',
      );
      expect(corpsGarantie, contains('outputPaths'));
      expect(
        corpsGarantie,
        contains(scriptConfig),
        reason: 'la phase doit appeler le script du depot, et non porter une '
            'copie de sa logique dans le pbxproj : une logique enfermee dans '
            'le pbxproj ne se relit pas, ne se teste pas et ne se corrige pas',
      );
    });

    test('le script appele existe vraiment et sait repondre aux deux appels',
        () {
      final script = File(scriptConfig);
      expect(script.existsSync(), isTrue,
          reason: 'la phase Xcode appelle un script absent : toute '
              'compilation iPhone echouerait');
      final texte = script.readAsStringSync();
      expect(texte, startsWith('#!/bin/sh'));
      for (final appel in const ['deposer', 'garantir-ios', 'etat']) {
        expect(texte, contains(appel),
            reason: 'le script ne traite pas « $appel »');
      }
    });

    test('le script nomme les trois variables de fabrication, et AUCUNE de '
        'leurs valeurs', () {
      final texte = File(scriptConfig).readAsStringSync();
      for (final variable in const [
        'STEPWAYS_GOOGLE_SERVICES_JSON',
        'STEPWAYS_GOOGLE_SERVICE_INFO_PLIST',
        'STEPWAYS_FIREBASE_PROJECT_ID',
      ]) {
        expect(texte, contains(variable),
            reason: 'une variable que personne ne peut deviner est une '
                'variable que personne ne remplira : $variable');
      }
    });
  });

  // ------------------------------------------------------------------
  // 3. LE PROJET XCODE RESTE COHERENT — UN pbxproj CASSE NE SE VOIT PAS
  // ------------------------------------------------------------------
  group('626 — le projet Xcode n est pas casse', () {
    test('les accolades et les parentheses se referment', () {
      final source = pbxprojFichier.readAsStringSync();
      var accolades = 0;
      var parentheses = 0;
      for (final c in source.split('')) {
        if (c == '{') accolades++;
        if (c == '}') accolades--;
        if (c == '(') parentheses++;
        if (c == ')') parentheses--;
        expect(accolades, greaterThanOrEqualTo(0));
        expect(parentheses, greaterThanOrEqualTo(0));
      }
      expect(accolades, 0, reason: 'accolades desequilibrees : Xcode refusera '
          'd ouvrir le projet, et cela ne se voit pas avant la compilation');
      expect(parentheses, 0, reason: 'parentheses desequilibrees');
    });

    test('tout fichier liste dans une phase existe comme PBXBuildFile, et son '
        'fileRef existe comme reference', () {
      final source = pbxprojFichier.readAsStringSync();
      final sectionBuildFile = section(source, 'PBXBuildFile');
      final sectionFileRef = section(source, 'PBXFileReference');
      final sectionVariant = section(source, 'PBXVariantGroup');

      final orphelins = <String>[];
      for (final nomSection in const [
        'PBXResourcesBuildPhase',
        'PBXSourcesBuildPhase',
        'PBXCopyFilesBuildPhase',
        'PBXFrameworksBuildPhase',
      ]) {
        for (final id in RegExp(r'\b([0-9A-F]{24})\b')
            .allMatches(section(source, nomSection))
            .map((m) => m.group(1)!)) {
          // Les identifiants de phases eux-memes ne sont pas des build files :
          // on ne retient que ceux annonces « in <phase> », forme que le
          // pbxproj donne aux entrees de fichiers.
          final ligne = RegExp('^\\t\\t\\t\\t$id [^\\n]*\$', multiLine: true)
              .firstMatch(section(source, nomSection));
          if (ligne == null) continue;
          final declaration =
              RegExp('^\\t\\t$id [^\\n]*\$', multiLine: true)
                  .firstMatch(sectionBuildFile);
          if (declaration == null) {
            orphelins.add('$id (aucun PBXBuildFile)');
            continue;
          }
          final fileRef = RegExp(r'fileRef = ([0-9A-F]{24})')
              .firstMatch(declaration.group(0)!);
          if (fileRef == null) {
            orphelins.add('$id (PBXBuildFile sans fileRef)');
            continue;
          }
          final ref = fileRef.group(1)!;
          final connue = RegExp('^\\t\\t$ref ', multiLine: true)
                  .hasMatch(sectionFileRef) ||
              RegExp('^\\t\\t$ref ', multiLine: true).hasMatch(sectionVariant);
          if (!connue) orphelins.add('$id -> $ref (reference inconnue)');
        }
      }
      expect(orphelins, isEmpty,
          reason: 'renvois casses dans le pbxproj : ${orphelins.join(' | ')}');
    });

    test('toute phase citee par une cible existe', () {
      final source = pbxprojFichier.readAsStringSync();
      final cibles = section(source, 'PBXNativeTarget');
      final sections = [
        'PBXResourcesBuildPhase',
        'PBXSourcesBuildPhase',
        'PBXCopyFilesBuildPhase',
        'PBXFrameworksBuildPhase',
        'PBXShellScriptBuildPhase',
      ].map((n) => section(source, n)).toList();

      final introuvables = <String>[];
      for (final ancre in RegExp(r'^\t\t([0-9A-F]{24}) /\* ([^*]+) \*/ = \{',
              multiLine: true)
          .allMatches(cibles)) {
        final corps = objet(cibles, ancre.group(1)!);
        if (corps == null) continue;
        for (final phase in liste(corps, 'buildPhases')) {
          if (!sections.any((s) => objet(s, phase) != null)) {
            introuvables.add('${ancre.group(2)} -> $phase');
          }
        }
      }
      expect(introuvables, isEmpty,
          reason: 'une cible cite une phase qui n existe pas : '
              '${introuvables.join(' | ')}. Xcode refuse le projet.');
    });
  });

  // ------------------------------------------------------------------
  // 4. AUCUNE VALEUR DE CONFIGURATION N EST ENTREE DANS LE DEPOT
  // ------------------------------------------------------------------
  group('626 — le tuyau est branche, et rien de ce qui passe dedans n est '
      'ecrit dans le depot', () {
    test('les deux fichiers de configuration restent exclus du depot', () {
      final ignores = File('.gitignore').readAsStringSync();
      expect(ignores, contains('**/google-services.json'),
          reason: 'la regle de Christophe est sans exception : aucune valeur '
              'de configuration dans le depot');
      expect(ignores, contains('**/GoogleService-Info.plist'));
    });

    test('AUCUNE cle d API ni identifiant d application Firebase en clair dans '
        'ce que ce lot ajoute', () {
      // Forme d une cle d API Google (« AIza » + 35 caracteres) et forme d un
      // GOOGLE_APP_ID Firebase (« 1:<numero de projet>:ios|android:... »). Ce
      // sont les deux valeurs que portent les fichiers de configuration.
      final cleApi = RegExp(r'AIza[0-9A-Za-z_\-]{30,}');
      final appId = RegExp(r'1:\d{6,}:(ios|android):');

      final aBalayer = <File>[
        File(scriptConfig),
        pbxprojFichier,
        ...Directory('docs/ci')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.md')),
      ];

      final fautifs = <String>[];
      for (final f in aBalayer) {
        if (!f.existsSync()) continue;
        final texte = f.readAsStringSync();
        if (cleApi.hasMatch(texte) || appId.hasMatch(texte)) {
          fautifs.add(f.path);
        }
      }
      expect(fautifs, isEmpty,
          reason: 'valeur de configuration Firebase en clair dans : '
              '${fautifs.join(', ')}. Elle doit passer par une variable '
              'd environnement, jamais par le depot.');
    });

    test('le fichier FACTICE du filet ne peut PAS servir de configuration, et '
        'porte sa marque', () {
      // Un fichier factice VRAISEMBLABLE serait bien pire que pas de fichier :
      // l application croirait parler a un projet et ne parlerait a rien. Celui
      // du filet ne porte aucune cle, donc Firebase ne peut pas demarrer avec
      // lui — c est exactement le comportement d avant ce lot (muet), a ceci
      // pres que la compilation passe.
      final texte = File(scriptConfig).readAsStringSync();
      expect(texte, contains('STEPWAYS_CONFIGURATION_FIREBASE_ABSENTE'),
          reason: 'le fichier factice doit etre reconnaissable, sinon personne '
              'ne saura pourquoi Firebase est muet');
      expect(texte.contains('API_KEY'), isFalse,
          reason: 'le fichier factice ne doit porter AUCUNE cle, meme fausse : '
              'avec une configuration d apparence valide, Firebase demarrerait '
              'et parlerait dans le vide');
      expect(texte.contains('GOOGLE_APP_ID'), isFalse);
    });
  });

  // ------------------------------------------------------------------
  // 5. L APPLICATION SANS FIREBASE RESTE LE CAS NOMINAL
  // ------------------------------------------------------------------
  group('626 — brancher Firebase ne rend pas Firebase obligatoire', () {
    test('AUCUNE configuration de sentier ne porte d identifiant de projet '
        'Firebase en dur', () {
      // C EST LE PIEGE QUE CE LOT DOIT SURTOUT NE PAS OUVRIR. Un identifiant
      // ecrit en dur dans une configuration de sentier ferait partir Firebase a
      // TOUS les demarrages, y compris ceux d un paquet construit sans fichier
      // de configuration natif. Sur iPhone, le SDK leve alors une exception
      // Objective-C que le try/catch de FirebaseService NE RATTRAPE PAS :
      // l application se fermerait au demarrage. Le commutateur doit rester
      // l injection de build, et elle seule.
      //
      // Un renvoi (`firebaseProjectId: autreChose.firebaseProjectId`) n est PAS
      // une valeur en dur : on ne cherche que les litteraux.
      final litteral = RegExp('''firebaseProjectId:\\s*['"]''');
      final fautifs = <String>[];
      for (final f in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final code = f
            .readAsLinesSync()
            .where((l) => !l.trimLeft().startsWith('//'))
            .join('\n');
        if (litteral.hasMatch(code)) fautifs.add(f.path);
      }
      expect(fautifs, isEmpty,
          reason: 'identifiant de projet Firebase en dur dans : '
              '${fautifs.join(', ')}. Il doit arriver par '
              '--dart-define=${FirebaseConfig.variableDeBuild}, jamais par une '
              'donnee versionnee.');
    });

    test('sans injection de build et sans valeur de sentier, rien ne demarre '
        'Firebase — c est le cas nominal hors ligne', () {
      // On ne re-teste pas ici tout le comportement de FirebaseService (le lot
      // 596 le fait) : on verifie le maillon que ce lot pouvait casser, et lui
      // seul, sur la VRAIE classe — pas sur une copie de sa regle. Le paquet que
      // Christophe testera peut-etre AVANT l autre est justement celui-la :
      // sans Firebase, et parfaitement utilisable.
      expect(FirebaseConfig.resoudre(), isNull,
          reason: 'un paquet construit sans variable doit rester en mode local');
      expect(FirebaseConfig.resoudre(depuisLeSentier: 'stepways-app'),
          'stepways-app',
          reason: 'le chemin de resolution doit rester fonctionnel : c est lui '
              'que la chaine de fabrication alimente');
    });
  });
}
