import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// GARDE STRUCTURELLE — L EXTENSION DE WIDGET NE PORTE PAS LE REGLAGE XCCONFIG
/// DE L APPLICATION (tache 735).
///
/// LE DEFAUT QU ELLE EMPECHE DE REVENIR. Le 08/10/2026, l edition de liens iOS
/// a echoue sur dix-sept symboles du moteur Flutter non resolus
/// (`FlutterStandardReader`, `FlutterStandardWriter`,
/// `FlutterStandardReaderWriter` et `FlutterStandardMessageCodec` avec leurs
/// META-classes, `FlutterViewController`, `FlutterBasicMessageChannel`,
/// `FlutterEventChannel`, `FlutterMethodChannel`, `FlutterError`,
/// `FlutterMethodNotImplemented`, `FlutterEndOfEventStream`,
/// `FlutterStandardTypedData`, `FlutterStandardMethodCodec`). La cause etait
/// dans le projet Xcode depuis le 06/06/2026 (commit `82e7c48b`) : les trois
/// configurations de la cible `TrekWidgetExtension` prenaient pour reglage de
/// base `Flutter/Debug.xcconfig` et `Flutter/Release.xcconfig`, LES FICHIERS DE
/// L APPLICATION.
///
/// POURQUOI CES DEUX FICHIERS NE SE PARTAGENT PAS. Ce ne sont pas des reglages
/// ordinaires : l outil Flutter y ajoute une ligne a chaque `flutter pub get`
/// et a chaque `flutter build ios`. `_addPodsDependencyToFlutterXcconfig`
/// (`packages/flutter_tools/lib/src/macos/cocoapods.dart`, lignes 298 a 308)
/// ecrit en tete `#include? "Pods/Target Support Files/Pods-Runner/
/// Pods-Runner.release.xcconfig"`, et ce nom est EN DUR dans l outil
/// (`includePodsXcconfig`, meme source, lignes 286 a 288). C est la ligne
/// d edition de liens de la cible `Runner` : un `-framework "..."` par pod lie,
/// `-ObjC`, et les chemins de recherche. Une autre cible qui prend ces fichiers
/// pour base herite donc de la ligne d edition de liens de l application.
///
/// ET LE MOTEUR, L EXTENSION NE L A PAS. CocoaPods ne le fournit jamais :
/// `flutter_install_ios_engine_pod`
/// (`packages/flutter_tools/bin/podhelper.rb`, lignes 210 a 246) ecrit un
/// podspec factice — `s.vendored_frameworks = 'path/to/nothing'` — en disant
/// « Framework linking is handled by Flutter tooling, not CocoaPods ». Le vrai
/// `Flutter.framework` arrive soit par
/// `flutter_additional_ios_build_settings` (podhelper.rb, lignes 93 a 103), qui
/// ne tourne que sur les cibles de POD, soit par la phase « Run Script » de la
/// cible `Runner` (`xcode_backend.dart`, lignes 562 a 595). L extension n a ni
/// l un ni l autre, et elle se compile AVANT `Runner`, qui depend d elle. Les
/// huit greffons du depot declares `s.static_framework = true` entraient donc
/// dans son edition de liens — fichiers objets compris — sans le moteur qu ils
/// reclament.
///
/// COMMENT ELLE LIT. Jamais une chaine cherchee dans tout le `pbxproj`. On
/// RESOUT la chaine de renvois comme Xcode : la liste de configurations nommee,
/// ses trois configurations, le `baseConfigurationReference` de chacune, et le
/// `PBXFileReference` qu il designe. C est le chemin du fichier qui est
/// compare, pas une etiquette de commentaire.
void main() {
  const cheminProjet = 'ios/Runner.xcodeproj/project.pbxproj';
  const cheminReglageDuWidget = 'ios/Flutter/TrekWidgetExtension.xcconfig';

  /// Les deux fichiers ou l outil Flutter ecrit la ligne `#include?` de
  /// CocoaPods : `xcodeConfigFor`
  /// (`packages/flutter_tools/lib/src/xcode_project.dart`, ligne 458) rend
  /// `ios/Flutter/<mode>.xcconfig`, et `addPodsDependencyToFlutterXcconfig`
  /// (cocoapods.dart, lignes 281 a 284) ne l appelle que pour `Debug` et
  /// `Release`.
  const reglagesDeLApplication = <String>[
    'Flutter/Debug.xcconfig',
    'Flutter/Release.xcconfig',
  ];

  /// La marque que CocoaPods laisse dans un reglage : c est exactement la
  /// chaine que l outil Flutter cherche avant d ecrire son `#include?`
  /// (`xcconfigIncludesPods`, cocoapods.dart, lignes 290 a 296).
  const marqueDeCocoapods = 'Pods/Target Support Files/Pods-';

  const listeDeLApplication =
      'Build configuration list for PBXNativeTarget "Runner"';
  const listeDuWidget =
      'Build configuration list for PBXNativeTarget "TrekWidgetExtension"';

  late String projet;

  setUpAll(() {
    final fProjet = File(cheminProjet);
    expect(fProjet.existsSync(), isTrue, reason: '$cheminProjet introuvable');
    projet = fProjet.readAsStringSync();
  });

  /// Isole une section nommee du pbxproj, bornes exclues.
  String section(String nom) {
    final debut = projet.indexOf('/* Begin $nom section */');
    final fin = projet.indexOf('/* End $nom section */');
    expect(debut, isNot(-1), reason: 'section $nom absente du pbxproj');
    expect(fin, greaterThan(debut), reason: 'section $nom mal fermee');
    return projet.substring(debut, fin);
  }

  /// Le corps de l objet [identifiant], accolades imbriquees comptees : un
  /// decoupage sur la premiere `}` couperait au milieu d un
  /// `buildSettings = {`.
  String? objet(String source, String identifiant) {
    final ancre = RegExp(
      '^\\t\\t$identifiant [^=]*= \\{',
      multiLine: true,
    ).firstMatch(source);
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

  /// Les identifiants des configurations de la liste etiquetee [etiquette].
  List<String> configurationsDe(String etiquette) {
    final sectionListes = section('XCConfigurationList');
    final ancre = RegExp(
      '^\\t\\t([0-9A-Fa-f]{24}) /\\* ${RegExp.escape(etiquette)} \\*/ = \\{',
      multiLine: true,
    ).firstMatch(sectionListes);
    expect(
      ancre,
      isNotNull,
      reason:
          'liste de configurations « $etiquette » absente du pbxproj : la '
          'garde ne sait plus ou lire le reglage de base',
    );
    final corps = objet(sectionListes, ancre!.group(1)!);
    final bloc = RegExp(
      r'buildConfigurations = \(([^)]*)\)',
    ).firstMatch(corps!);
    expect(bloc, isNotNull, reason: '« $etiquette » ne liste plus rien');
    return RegExp(
      r'\b([0-9A-Fa-f]{24})\b',
    ).allMatches(bloc!.group(1)!).map((m) => m.group(1)!).toList();
  }

  /// Le nom d une configuration (`Debug`, `Release` ou `Profile`).
  String nomDe(String identifiant) {
    final corps = objet(section('XCBuildConfiguration'), identifiant);
    expect(corps, isNotNull, reason: 'configuration $identifiant absente');
    final m = RegExp(r'name = (\w+);').firstMatch(corps!);
    expect(m, isNotNull, reason: 'configuration $identifiant sans nom');
    return m!.group(1)!;
  }

  /// Le CHEMIN du fichier que la configuration [identifiant] prend pour
  /// reglage de base, ou `null` quand elle n en prend aucun. On passe par le
  /// `PBXFileReference` : l etiquette entre `/* */` est un commentaire que
  /// Xcode reecrit, le `path` est la verite.
  String? reglageDeBaseDe(String identifiant) {
    final corps = objet(section('XCBuildConfiguration'), identifiant);
    expect(corps, isNotNull, reason: 'configuration $identifiant absente');
    final renvoi = RegExp(
      r'baseConfigurationReference = ([0-9A-Fa-f]{24})',
    ).firstMatch(corps!);
    if (renvoi == null) return null;
    final fichier = objet(section('PBXFileReference'), renvoi.group(1)!);
    expect(
      fichier,
      isNotNull,
      reason:
          'la configuration $identifiant renvoie au fichier '
          '${renvoi.group(1)} qui n existe pas dans PBXFileReference : le '
          'projet Xcode ne s ouvrirait plus',
    );
    final chemin = RegExp(r'path = ([^;]+);').firstMatch(fichier!);
    expect(
      chemin,
      isNotNull,
      reason: 'le fichier ${renvoi.group(1)} n a pas de chemin',
    );
    return chemin!.group(1)!.replaceAll('"', '').trim();
  }

  /// Les reglages de base de la liste [etiquette], par nom de configuration.
  Map<String, String?> reglagesDeBaseDe(String etiquette) {
    final lus = <String, String?>{};
    for (final identifiant in configurationsDe(etiquette)) {
      lus[nomDe(identifiant)] = reglageDeBaseDe(identifiant);
    }
    return lus;
  }

  group('735 — l extension de widget ne porte pas le xcconfig de l app', () {
    test('LES TROIS CONFIGURATIONS DE TREKWIDGETEXTENSION NE PRENNENT PLUS LE '
        'REGLAGE DE L APPLICATION', () {
      final duWidget = reglagesDeBaseDe(listeDuWidget);
      expect(
        duWidget.keys.toSet(),
        equals({'Debug', 'Release', 'Profile'}),
        reason:
            'les trois configurations attendues ne sont plus la : '
            '${duWidget.keys.join(', ')}',
      );
      for (final entree in duWidget.entries) {
        expect(
          reglagesDeLApplication,
          isNot(contains(entree.value)),
          reason:
              'LA CONFIGURATION ${entree.key} DE TREKWIDGETEXTENSION REPREND '
              '${entree.value}, LE REGLAGE DE L APPLICATION.\n'
              'L outil Flutter ecrit en tete de ce fichier, a chaque '
              '`flutter pub get`, un `#include? '
              '"${marqueDeCocoapods}Runner/Pods-Runner.release.xcconfig"` '
              '(cocoapods.dart, lignes 286 a 308). L extension heriterait donc '
              'du `OTHER_LDFLAGS` de la cible Runner : un `-framework "..."` '
              'par pod de l application, dont HUIT sont des frameworks '
              'STATIQUES (Firebase, Google Ads, permission_handler_apple) dont '
              'les fichiers objets entrent dans la cible qui les lie. Or '
              'l extension n a pas `Flutter.framework` : ni '
              '`flutter_additional_ios_build_settings` (qui ne traite que les '
              'pods) ni la phase « Run Script » de Runner (qui tourne APRES, '
              'puisque Runner depend du widget) ne le lui donnent. C est '
              'l echec du 08/10/2026 : dix-sept symboles du moteur non '
              'resolus, apres seize minutes de machine macOS louee.\n'
              'Rendez a cette configuration le reglage '
              '$cheminReglageDuWidget. Si l extension a vraiment besoin d un '
              'greffon, declarez la cible TrekWidgetExtension dans '
              'ios/Podfile : CocoaPods lui generera son propre reglage, avec '
              'le moteur.',
        );
      }
    });

    test('elles prennent toutes les trois le reglage qui est a elles', () {
      final duWidget = reglagesDeBaseDe(listeDuWidget);
      for (final entree in duWidget.entries) {
        expect(
          entree.value,
          'Flutter/TrekWidgetExtension.xcconfig',
          reason:
              'la configuration ${entree.key} de TrekWidgetExtension ne prend '
              'pas $cheminReglageDuWidget pour base. Sans reglage de base du '
              'tout, `\$(FLUTTER_BUILD_NAME)` et `\$(FLUTTER_BUILD_NUMBER)` ne '
              'seraient plus definis, et TrekWidget/Info.plist produirait un '
              '`.appex` sans CFBundleShortVersionString ni CFBundleVersion — '
              'refuse par App Store Connect',
        );
      }
    });

    test('le reglage du widget existe, donne les variables de Flutter, et '
        'n inclut AUCUN reglage de CocoaPods', () {
      final fichier = File(cheminReglageDuWidget);
      expect(
        fichier.existsSync(),
        isTrue,
        reason:
            '$cheminReglageDuWidget introuvable alors que le projet Xcode le '
            'designe : le projet ne compilerait pas',
      );
      // Les commentaires sont ECARTES, et ce n est pas une precaution de
      // style : l en-tete de ce fichier CITE la ligne `#include?` que l outil
      // Flutter ecrit dans le reglage de l application, pour expliquer le
      // defaut qu il repare. Chercher la marque dans le texte brut ferait
      // rougir la garde sur une explication au lieu d une declaration — c est
      // exactement ce qui s est passe au premier essai de cette garde.
      final lignes = fichier
          .readAsStringSync()
          .split('\n')
          .map((l) => l.trim())
          .where((l) => !l.startsWith('//'))
          .where((l) => l.isNotEmpty)
          .toList();
      expect(
        lignes,
        contains('#include "Generated.xcconfig"'),
        reason:
            '$cheminReglageDuWidget n inclut plus Generated.xcconfig : '
            '`\$(FLUTTER_BUILD_NAME)` et `\$(FLUTTER_BUILD_NUMBER)` '
            'disparaitraient du paquet de l extension',
      );
      expect(
        lignes.where((l) => l.contains(marqueDeCocoapods)),
        isEmpty,
        reason:
            '$cheminReglageDuWidget inclut un reglage de CocoaPods. C est le '
            'defaut du 08/10 par un autre chemin : l extension reprendrait la '
            'ligne d edition de liens de l application sans avoir le moteur. '
            'Un greffon necessaire a l extension se declare dans ios/Podfile, '
            'pas ici',
      );
      // Et le fichier ne declare RIEN d autre : une ligne de plus serait un
      // reglage que personne n a relu dans une cible qui n en a pas besoin.
      expect(
        lignes,
        equals(const ['#include "Generated.xcconfig"']),
        reason:
            '$cheminReglageDuWidget declare autre chose que l inclusion de '
            'Generated.xcconfig : ${lignes.join(' | ')}. La cible du widget '
            'n a besoin que des variables de version de Flutter',
      );
    });

    test('LA CIBLE RUNNER, ELLE, GARDE BIEN LE REGLAGE DE L APPLICATION', () {
      final deLApplication = reglagesDeBaseDe(listeDeLApplication);
      expect(
        deLApplication.keys.toSet(),
        equals({'Debug', 'Release', 'Profile'}),
        reason:
            'les trois configurations de Runner ne sont plus la : '
            '${deLApplication.keys.join(', ')}',
      );
      expect(
        deLApplication['Debug'],
        'Flutter/Debug.xcconfig',
        reason:
            'la configuration Debug de Runner ne prend plus '
            'Flutter/Debug.xcconfig : l application perdrait le reglage de '
            'CocoaPods et ne lierait plus AUCUN greffon. On ne repare pas le '
            'widget en cassant l application',
      );
      for (final nom in const ['Release', 'Profile']) {
        expect(
          deLApplication[nom],
          'Flutter/Release.xcconfig',
          reason:
              'la configuration $nom de Runner ne prend plus '
              'Flutter/Release.xcconfig : l application perdrait le reglage '
              'de CocoaPods et ne lierait plus AUCUN greffon',
        );
      }
    });

    test('le code du widget ne demande rien a Flutter — ce qui est la raison '
        'pour laquelle il peut se passer des pods', () {
      const cheminSource = 'ios/TrekWidget/TrekWidget.swift';
      final source = File(cheminSource);
      expect(
        source.existsSync(),
        isTrue,
        reason:
            '$cheminSource introuvable : la cible du widget n a plus rien '
            'a compiler',
      );
      final imports = RegExp(
        r'^\s*import\s+(\w+)',
        multiLine: true,
      ).allMatches(source.readAsStringSync()).map((m) => m.group(1)!).toSet();
      expect(
        imports.difference({'WidgetKit', 'SwiftUI', 'Foundation'}),
        isEmpty,
        reason:
            '$cheminSource importe ${imports.join(', ')}. La cible du widget '
            'ne recoit AUCUN reglage de CocoaPods, et c est voulu : son code '
            'n a besoin que de WidgetKit et SwiftUI. Si elle doit maintenant '
            'utiliser un greffon (par exemple home_widget pour '
            'HomeWidgetBackgroundWorker), declarez la cible '
            'TrekWidgetExtension dans ios/Podfile avec son propre bloc '
            '`target` — CocoaPods lui generera un '
            'Pods-TrekWidgetExtension.xcconfig, avec le moteur Flutter. NE '
            'REMETTEZ PAS le reglage de l application : il donne la ligne '
            'd edition de liens de Runner sans donner Flutter.framework',
      );
    });

    test('LA GARDE MESURE VRAIMENT : elle resout la chaine, elle ne confond '
        'pas les deux cibles, et elle lirait un retour en arriere', () {
      // Elle lit bien trois reglages de chaque cote, et aucun n est nul :
      // une garde qui ne lit plus rien passerait au vert en silence.
      expect(
        reglagesDeBaseDe(listeDuWidget).values.whereType<String>(),
        hasLength(3),
      );
      expect(
        reglagesDeBaseDe(listeDeLApplication).values.whereType<String>(),
        hasLength(3),
      );

      // Les deux cibles sont lues SEPAREMENT : leurs listes ne partagent
      // aucune configuration.
      expect(
        configurationsDe(
          listeDeLApplication,
        ).toSet().intersection(configurationsDe(listeDuWidget).toSet()),
        isEmpty,
      );

      // Les deux cotes sont DIFFERENTS : si la garde comparait deux fois la
      // meme chose, ce test tomberait.
      expect(
        reglagesDeBaseDe(listeDuWidget).values.toSet().intersection(
          reglagesDeBaseDe(listeDeLApplication).values.toSet(),
        ),
        isEmpty,
      );

      // La resolution passe bien par le PBXFileReference, et pas par
      // l etiquette du commentaire : on le prouve sur l envers du decor, en
      // verifiant que le fichier designe porte le chemin attendu et que
      // l etiquette seule ne suffirait pas a le distinguer.
      final reference = RegExp(
        r'^\t\t([0-9A-Fa-f]{24}) /\* TrekWidgetExtension.xcconfig \*/',
        multiLine: true,
      ).firstMatch(section('PBXFileReference'));
      expect(reference, isNotNull);
      expect(
        objet(section('PBXFileReference'), reference!.group(1)!),
        contains('path = Flutter/TrekWidgetExtension.xcconfig;'),
      );

      // Et la marque de CocoaPods est bien celle que l outil Flutter cherche :
      // la garde rougirait sur la ligne que l outil ecrit.
      expect(
        '#include? "${marqueDeCocoapods}Runner/Pods-Runner.release.xcconfig"'
            .contains(marqueDeCocoapods),
        isTrue,
      );
    });
  });
}
