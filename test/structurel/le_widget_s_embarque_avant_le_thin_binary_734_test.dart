import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// GARDE STRUCTURELLE — L EXTENSION S EMBARQUE AVANT LE « THIN BINARY »
/// (tache 734).
///
/// LE DEFAUT QU ELLE EMPECHE DE REVENIR. Le 07/10/2026 a 23:05, la chaine
/// `ios_compile` est allee plus loin que jamais : etapes precedentes passees,
/// dependances Swift Package Manager en 148,2 s, `pod install` en 835 ms, puis
/// Xcode appele POUR DE VRAI pendant 224,8 s. Et Xcode a refuse de construire :
///
///     Error (Xcode): Cycle inside Runner; building could produce unreliable
///     results.
///
/// Un cycle n est pas une erreur de code : c est le graphe de dependances de la
/// cible qui se mord la queue, et Xcode s arrete AVANT de compiler plutot que
/// de produire un paquet dont il ne garantit plus le contenu.
///
/// CE QUI FERMAIT LA BOUCLE. La cible `Runner` portait ses huit phases dans cet
/// ordre : Firebase, Run Script, Sources, Frameworks, Resources, Embed
/// Frameworks, **Thin Binary**, **Embed Foundation Extensions**. Les deux
/// dernieres touchent le MEME paquet `Runner.app` :
///
///   * `Embed Foundation Extensions` est une `PBXCopyFilesBuildPhase` de
///     `dstSubfolderSpec = 13` (PlugIns) : elle copie
///     `TrekWidgetExtension.appex` dans `Runner.app/PlugIns/`.
///   * `Thin Binary` est une `PBXShellScriptBuildPhase` qui lance
///     `xcode_backend.sh embed_and_thin` et qui DECLARE comme entree
///     `${TARGET_BUILD_DIR}/${INFOPLIST_PATH}`, c est-a-dire
///     `Runner.app/Info.plist`.
///
/// Quand l embarquement est ordonne APRES le Thin Binary, les deux aretes du
/// graphe se CONTREDISENT : l ordre des phases dit « la copie de l appex vient
/// apres le Thin Binary », et l entree declaree dit « le Thin Binary attend le
/// contenu de Runner.app », contenu dont fait partie l appex que la copie n a
/// pas encore pose. Xcode ne peut pas serialiser les deux, et il le raconte :
///
///     Cycle details:
///     -> Target 'Runner' has copy command from '.../TrekWidgetExtension.appex'
///        to '.../Runner.app/PlugIns/TrekWidgetExtension.appex'
///     o  That command depends on command in Target 'Runner': script phase
///        "Thin Binary"
///     o  Target 'Runner' has process command with output
///        '.../Runner.app/Info.plist'
///     o  Target 'Runner' has copy command from '.../TrekWidgetExtension.appex'
///        to '.../Runner.app/PlugIns/TrekWidgetExtension.appex'
///
/// (Les quatre lignes sont celles du journal Codemagic, leurs puces rendues en
/// ASCII : le message d echec d un test traverse des consoles Windows en
/// cp1252, ou les puces d Xcode partiraient en mojibake et rendraient la trace
/// illisible au moment precis ou on en a besoin.)
///
/// POURQUOI L INVERSE OUVRE LA BOUCLE. Avec `Embed Foundation Extensions`
/// AVANT `Thin Binary`, les deux aretes pointent dans le MEME sens : le Thin
/// Binary depend de la copie par l ordre des phases, et il depend du contenu de
/// `Runner.app` par son entree declaree — or la copie fait partie de ce
/// contenu. Plus de contradiction, le graphe redevient un ordre, Xcode
/// serialise. C est aussi la place CANONIQUE du Thin Binary : un projet
/// `flutter create` neuf sous Flutter 3.41.5 le pose EN DERNIER (Run Script,
/// Sources, Frameworks, Resources, Embed Frameworks, Thin Binary), parce que
/// `embed_and_thin` ECRIT dans le paquet — il y verse `App.framework` et
/// `Flutter.framework` par `rsync` dans `Runner.app/Frameworks`. Toute phase
/// qui ecrit dans `Runner.app` APRES lui recree le meme cycle.
///
/// CE QUE LA GARDE NE FAIT PAS. Elle ne protege pas le widget de la
/// suppression — une autre garde s en charge — mais elle refuse de passer au
/// vert en ne lisant plus rien : si l appex disparaissait de la phase
/// d embarquement, l ordre deviendrait vide de sens et le dernier test le dit.
/// Christophe a tranche le 07/10, mot pour mot : « on garde le widget ».
///
/// COMMENT ELLE LIT. Jamais une chaine cherchee dans tout le `pbxproj` — le lot
/// 618 a paye cette erreur. On RESOUT la chaine de renvois comme Xcode, de la
/// meme facon que la garde 733 : la cible native `Runner`, son tableau
/// `buildPhases` DANS L ORDRE, puis chaque identifiant resolu vers son objet de
/// phase. Et les deux phases sont reconnues par CE QU ELLES FONT, pas par leur
/// nom : la copie vers PlugIns par son `dstSubfolderSpec = 13`, le Thin Binary
/// par le `embed_and_thin` de son `shellScript`. Un renommage par Xcode — il a
/// deja dit « Embed App Extensions » — ne doit pas rendre la garde aveugle.
void main() {
  const cheminProjet = 'ios/Runner.xcodeproj/project.pbxproj';

  /// Les sections du pbxproj ou peut vivre une phase de construction.
  const sectionsDePhases = <String>[
    'PBXShellScriptBuildPhase',
    'PBXCopyFilesBuildPhase',
    'PBXSourcesBuildPhase',
    'PBXFrameworksBuildPhase',
    'PBXResourcesBuildPhase',
  ];

  /// `dstSubfolderSpec` du dossier `PlugIns` d un paquet applicatif. C est la
  /// valeur qu Xcode ecrit pour une phase « Embed Foundation Extensions ».
  const dossierPlugIns = '13';

  /// La sous-commande de `xcode_backend.sh` que lance le Thin Binary.
  const sousCommandeThinBinary = 'embed_and_thin';

  late String projet;

  setUpAll(() {
    final fichier = File(cheminProjet);
    expect(
      fichier.existsSync(),
      isTrue,
      reason:
          '$cheminProjet introuvable : sans le projet Xcode, l ordre des '
          'phases n est plus tenu par personne',
    );
    projet = fichier.readAsStringSync();
  });

  /// Isole une section nommee du pbxproj, bornes exclues.
  String section(String nom) {
    final debut = projet.indexOf('/* Begin $nom section */');
    final fin = projet.indexOf('/* End $nom section */');
    expect(debut, isNot(-1), reason: 'section $nom absente du pbxproj');
    expect(fin, greaterThan(debut), reason: 'section $nom mal fermee');
    return projet.substring(debut, fin);
  }

  /// Le corps de l objet [identifiant], entre son accolade ouvrante et son
  /// accolade fermante, en comptant les accolades imbriquees — un decoupage sur
  /// la premiere `}` rencontree couperait au milieu d un `buildSettings = {`.
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

  /// Les identifiants des phases de la cible native `Runner`, DANS L ORDRE ou
  /// Xcode les executera. C est le seul ordre qui compte.
  List<String> phasesDuRunner() {
    final sectionCibles = section('PBXNativeTarget');
    final ancre = RegExp(
      r'^\t\t([0-9A-Fa-f]{24}) /\* Runner \*/ = \{',
      multiLine: true,
    ).firstMatch(sectionCibles);
    expect(
      ancre,
      isNotNull,
      reason:
          'la cible native « Runner » est absente du pbxproj : la garde ne '
          'sait plus ou lire l ordre des phases',
    );
    final corps = objet(sectionCibles, ancre!.group(1)!);
    expect(corps, isNotNull, reason: 'la cible « Runner » est mal fermee');
    final bloc = RegExp(r'buildPhases = \(([^)]*)\)').firstMatch(corps!);
    expect(
      bloc,
      isNotNull,
      reason: 'la cible « Runner » ne liste plus aucune phase',
    );
    return RegExp(
      r'\b([0-9A-Fa-f]{24})\b',
    ).allMatches(bloc!.group(1)!).map((m) => m.group(1)!).toList();
  }

  /// Le corps de la phase [identifiant], cherchee dans chaque section de
  /// phases : c est la resolution du renvoi, exactement ce que fait Xcode.
  String corpsDePhase(String identifiant) {
    for (final nom in sectionsDePhases) {
      final corps = objet(section(nom), identifiant);
      if (corps != null) return corps;
    }
    fail(
      'la phase $identifiant est listee par la cible « Runner » mais son '
      'objet est introuvable dans ${sectionsDePhases.join(', ')} : le '
      'pbxproj renvoie vers un objet qui n existe pas',
    );
  }

  /// Le nom que la phase affiche dans Xcode, quand elle en porte un. Les
  /// phases `Sources`, `Frameworks` et `Resources` n en declarent pas.
  String nomDePhase(String corps) {
    final m = RegExp(r'name = "([^"]*)";').firstMatch(corps);
    final isa = RegExp(r'isa = (\w+);').firstMatch(corps)?.group(1) ?? '?';
    return m?.group(1) ?? isa;
  }

  /// Le rang, dans le tableau `buildPhases`, de la phase que [reconnait]
  /// designe. `-1` quand aucune phase ne correspond.
  int rangDeLaPhase(bool Function(String corps) reconnait) {
    final phases = phasesDuRunner();
    for (var i = 0; i < phases.length; i++) {
      if (reconnait(corpsDePhase(phases[i]))) return i;
    }
    return -1;
  }

  /// La phase qui copie vers `PlugIns`, reconnue par CE QU ELLE FAIT.
  bool estEmbarquementDExtensions(String corps) =>
      RegExp(r'isa = PBXCopyFilesBuildPhase;').hasMatch(corps) &&
      RegExp('dstSubfolderSpec = $dossierPlugIns;').hasMatch(corps);

  /// La phase qui lance `embed_and_thin`, reconnue par CE QU ELLE FAIT.
  bool estThinBinary(String corps) =>
      RegExp(r'isa = PBXShellScriptBuildPhase;').hasMatch(corps) &&
      corps.contains(sousCommandeThinBinary);

  /// L ordre des phases, ecrit pour un humain qui lit un echec.
  String ordreLisible() {
    final phases = phasesDuRunner();
    return phases
        .asMap()
        .entries
        .map((e) => '    ${e.key + 1}. ${nomDePhase(corpsDePhase(e.value))}')
        .join('\n');
  }

  group('734 — l extension s embarque avant le Thin Binary', () {
    test('la cible Runner porte bien une phase qui copie vers PlugIns', () {
      expect(
        rangDeLaPhase(estEmbarquementDExtensions),
        isNot(-1),
        reason:
            'plus aucune phase de la cible « Runner » ne copie vers PlugIns '
            '(`PBXCopyFilesBuildPhase` avec `dstSubfolderSpec = '
            '$dossierPlugIns`). Sans elle, TrekWidgetExtension.appex n entre '
            'pas dans le paquet et le widget ne s installe pas. Christophe a '
            'tranche le 07/10 : « on garde le widget »',
      );
    });

    test('la cible Runner porte bien la phase Thin Binary de Flutter', () {
      expect(
        rangDeLaPhase(estThinBinary),
        isNot(-1),
        reason:
            'plus aucune phase de la cible « Runner » ne lance '
            '`$sousCommandeThinBinary`. C est elle qui verse App.framework et '
            'Flutter.framework dans Runner.app/Frameworks : sans elle, '
            'l application n embarque plus le moteur Flutter',
      );
    });

    test('L EMBARQUEMENT DE L EXTENSION PRECEDE LE THIN BINARY, ET LE CYCLE '
        'XCODE RESTE OUVERT', () {
      final rangEmbarquement = rangDeLaPhase(estEmbarquementDExtensions);
      final rangThinBinary = rangDeLaPhase(estThinBinary);
      expect(
        rangEmbarquement,
        lessThan(rangThinBinary),
        reason:
            'L ORDRE DES PHASES EST REPARTI A L ENVERS, ET XCODE VA REFUSER DE '
            'CONSTRUIRE.\n'
            '  Embed Foundation Extensions : phase '
            '${rangEmbarquement + 1} sur ${phasesDuRunner().length}\n'
            '  Thin Binary                 : phase '
            '${rangThinBinary + 1} sur ${phasesDuRunner().length}\n'
            'Ordre lu dans $cheminProjet :\n'
            '${ordreLisible()}\n'
            'Les deux phases ecrivent dans le MEME paquet Runner.app : la '
            'copie y pose TrekWidgetExtension.appex sous PlugIns/, et le Thin '
            'Binary y verse les frameworks Flutter tout en DECLARANT '
            '`Runner.app/Info.plist` comme entree. Embarquer APRES, c est '
            'demander a Xcode deux choses contradictoires, et il s arrete net '
            '— c est l echec du 07/10 a 23:05, apres 224,8 s de Xcode et des '
            'minutes de machine louee :\n'
            '    Error (Xcode): Cycle inside Runner; building could produce '
            'unreliable results.\n'
            '    Cycle details:\n'
            "    -> Target 'Runner' has copy command from "
            "'.../TrekWidgetExtension.appex' to "
            "'.../Runner.app/PlugIns/TrekWidgetExtension.appex'\n"
            "    o  That command depends on command in Target 'Runner': "
            'script phase "Thin Binary"\n'
            "    o  Target 'Runner' has process command with output "
            "'.../Runner.app/Info.plist'\n"
            "    o  Target 'Runner' has copy command from "
            "'.../TrekWidgetExtension.appex' to "
            "'.../Runner.app/PlugIns/TrekWidgetExtension.appex'\n"
            'REMETTEZ l embarquement de l extension AVANT le Thin Binary dans '
            'le tableau `buildPhases` de la cible « Runner ». Le Thin Binary '
            'se place EN DERNIER : c est sa place canonique, celle qu un '
            'projet `flutter create` neuf lui donne. NE RETIREZ NI le widget, '
            'NI son embarquement — ce n est pas la correction, c est la perte '
            'de la fonctionnalite.',
      );
    });

    test('LA GARDE MESURE VRAIMENT : elle resout les renvois, elle '
        'reconnait les phases par ce qu elles font, et le widget est '
        'toujours embarque', () {
      // Si le parcours du pbxproj cassait, la garde passerait au vert en ne
      // lisant plus rien du tout : on exige qu elle lise les huit phases.
      final phases = phasesDuRunner();
      expect(
        phases,
        hasLength(8),
        reason:
            'la cible « Runner » ne porte plus huit phases mais '
            '${phases.length} : si c est voulu, mettez ce compte a jour, mais '
            'relisez d abord l ordre — c est lui que cette garde protege',
      );
      // Chaque identifiant liste se resout VRAIMENT vers un objet de phase.
      for (final identifiant in phases) {
        expect(corpsDePhase(identifiant), isNotEmpty);
      }
      // Les deux phases qui nous occupent sont bien reconnues, et distinctes.
      final rangEmbarquement = rangDeLaPhase(estEmbarquementDExtensions);
      final rangThinBinary = rangDeLaPhase(estThinBinary);
      expect(rangEmbarquement, isNot(-1));
      expect(rangThinBinary, isNot(-1));
      expect(rangEmbarquement, isNot(rangThinBinary));
      // Le Thin Binary est le DERNIER : sa place canonique. Toute phase posee
      // apres lui ecrirait dans Runner.app apres son passage, et rouvrirait la
      // porte au cycle.
      expect(
        rangThinBinary,
        phases.length - 1,
        reason:
            'le Thin Binary n est plus la DERNIERE phase de la cible '
            '« Runner » : une phase a ete posee apres lui. Toute phase qui '
            'ecrit dans Runner.app apres `$sousCommandeThinBinary` recree le '
            'cycle de 734. Ordre lu :\n${ordreLisible()}',
      );
      // Et l appex est toujours dans la phase d embarquement : sans lui,
      // l ordre protege par cette garde ne voudrait plus rien dire.
      final corpsEmbarquement = corpsDePhase(phases[rangEmbarquement]);
      expect(
        corpsEmbarquement,
        contains('.appex'),
        reason:
            'la phase qui copie vers PlugIns ne porte plus aucun `.appex` : '
            'le widget a ete DESEMBARQUE. Ce n est pas la correction du cycle '
            '734 — Christophe a tranche le 07/10 : « on garde le widget »',
      );

      // Et la reconnaissance se fait bien sur la structure, pas sur un nom :
      // un « Embed Frameworks » (dstSubfolderSpec = 10) ne doit pas passer
      // pour un embarquement d extensions.
      expect(
        estEmbarquementDExtensions(
          'isa = PBXCopyFilesBuildPhase;\ndstSubfolderSpec = 10;',
        ),
        isFalse,
      );
      expect(
        estEmbarquementDExtensions(
          'isa = PBXCopyFilesBuildPhase;\n'
          'dstSubfolderSpec = $dossierPlugIns;',
        ),
        isTrue,
      );
      expect(
        estThinBinary(
          'isa = PBXShellScriptBuildPhase;\n'
          'shellScript = "xcode_backend.sh $sousCommandeThinBinary";',
        ),
        isTrue,
      );
      expect(
        estThinBinary(
          'isa = PBXShellScriptBuildPhase;\n'
          'shellScript = "xcode_backend.sh build";',
        ),
        isFalse,
      );
    });
  });
}
