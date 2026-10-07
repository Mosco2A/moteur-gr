import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// GARDE STRUCTURELLE — LE PODFILE DIT LA MEME CIBLE iOS QUE LE PROJET XCODE
/// (tache 733).
///
/// LE DEFAUT QU ELLE EMPECHE DE REVENIR. Le 07/10/2026, deux lots JUSTES ont
/// produit a eux deux un etat FAUX, et rien ne l a vu. Le lot « fiche magasin
/// et preparation Apple » a monte `IPHONEOS_DEPLOYMENT_TARGET` de 13.0 a 15.0
/// sur les trois configurations du projet Runner (commit `4e28192b`). Le lot
/// « compilation iPhone CocoaPods/SPM » a CREE `ios/Podfile` avec
/// `platform :ios, '13.0'` (commit `708f7b62`). Les deux branches sont nees de
/// la MEME tete `52fb8ac2` : aucune n a jamais vu le fichier que l autre
/// touchait, la fusion automatique n avait donc aucun conflit a signaler, et
/// chaque diff, relu seul, etait irreprochable. C est la classe de defauts que
/// la relecture humaine ne peut pas attraper — elle ne lit jamais les deux
/// branches en meme temps. Un test, lui, lit l etat REUNI.
///
/// CE QUE LE DESACCORD COUTE. Le Podfile donne a CocoaPods le plancher auquel
/// il compile les pods ; le projet Xcode donne celui auquel il compile
/// l application. Quand les pods visent un iOS plus recent que l application,
/// le module Swift est refuse a la compilation — un echec qui n arrive que sur
/// un vrai macOS, apres des minutes de machine louee, et dont le message ne
/// nomme ni le Podfile ni le projet. Quand ils visent un iOS plus ancien, le
/// plancher annonce par le projet ne veut plus rien dire. Les deux valeurs se
/// changent donc ENSEMBLE, jamais l une sans l autre, et c est exactement ce
/// que fait la migration `IOSDeploymentTargetMigration` de Flutter 3.47, qui
/// reecrit les deux du meme geste.
///
/// POURQUOI L EXTENSION TREKWIDGET A LE DROIT D ETRE PLUS HAUTE. Le projet
/// porte DEUX valeurs differentes : 15.0 pour le projet Runner, 17.0 pour la
/// cible `TrekWidgetExtension`. Ce n est pas une incoherence, c est la nature
/// de l extension : les widgets interactifs de WidgetKit auxquels elle fait
/// appel n existent pas avant iOS 17, et une extension a le droit d exiger
/// plus que l application qui la porte — elle ne s installe simplement pas sur
/// les iPhone plus anciens, qui gardent l application sans son widget. Le
/// Podfile, lui, ne compile de pods que pour la cible `Runner`. Cette garde
/// compare donc le Podfile a la cible RUNNER, et pas au widget : confondre les
/// deux la ferait reclamer un `platform :ios, '17.0'` qui couperait
/// l application de tous les iPhone sous iOS 17.
///
/// COMMENT ELLE LIT. Jamais une chaine cherchee dans tout le `pbxproj` — le lot
/// 618 a paye cette erreur. On RESOUT la chaine de renvois comme Xcode : la
/// liste de configurations nommee, ses trois configurations, et dans chacune le
/// reglage. La valeur retenue pour l application est celle que la cible
/// `Runner` declare, et a defaut celle du projet dont elle herite.
void main() {
  const cheminPodfile = 'ios/Podfile';
  const cheminProjet = 'ios/Runner.xcodeproj/project.pbxproj';

  /// Les etiquettes exactes que Xcode ecrit en commentaire de ses listes de
  /// configurations. Ce sont nos points d entree dans le fichier.
  const listeDuProjet = 'Build configuration list for PBXProject "Runner"';
  const listeDeLApplication =
      'Build configuration list for PBXNativeTarget "Runner"';
  const listeDuWidget =
      'Build configuration list for PBXNativeTarget "TrekWidgetExtension"';

  late String podfile;
  late String projet;

  setUpAll(() {
    final fPodfile = File(cheminPodfile);
    final fProjet = File(cheminProjet);
    expect(
      fPodfile.existsSync(),
      isTrue,
      reason:
          '$cheminPodfile introuvable : sans lui, CocoaPods choisit la '
          'plateforme tout seul et le depot ne tient plus la valeur',
    );
    expect(fProjet.existsSync(), isTrue, reason: '$cheminProjet introuvable');
    podfile = fPodfile.readAsStringSync();
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
          'garde ne sait plus ou lire la cible iOS',
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

  /// La cible iOS que la configuration [identifiant] DECLARE, ou `null` quand
  /// elle n en declare pas : elle herite alors du niveau au-dessus, exactement
  /// comme Xcode le fait.
  String? cibleDeclareePar(String identifiant) {
    final corps = objet(section('XCBuildConfiguration'), identifiant);
    expect(corps, isNotNull, reason: 'configuration $identifiant absente');
    final m = RegExp(
      r'IPHONEOS_DEPLOYMENT_TARGET = ([\d.]+);',
    ).firstMatch(corps!);
    return m?.group(1);
  }

  /// Les cibles iOS declarees par la liste [etiquette], par nom de
  /// configuration. Une valeur `null` veut dire « heritee ».
  Map<String, String?> ciblesDeclareesPar(String etiquette) {
    final declarees = <String, String?>{};
    for (final identifiant in configurationsDe(etiquette)) {
      declarees[nomDe(identifiant)] = cibleDeclareePar(identifiant);
    }
    return declarees;
  }

  /// Les cibles iOS EFFECTIVES de l application, par nom de configuration :
  /// celle que la cible `Runner` declare, et a defaut celle du projet dont elle
  /// herite. C est le nombre auquel l application est reellement compilee, donc
  /// le seul que le Podfile doive repeter.
  Map<String, String> ciblesEffectivesDuRunner() {
    final duProjet = ciblesDeclareesPar(listeDuProjet);
    final deLApplication = ciblesDeclareesPar(listeDeLApplication);
    final effectives = <String, String>{};
    for (final entree in deLApplication.entries) {
      final valeur = entree.value ?? duProjet[entree.key];
      if (valeur != null) effectives[entree.key] = valeur;
    }
    return effectives;
  }

  /// La valeur de `platform :ios, 'X'` du Podfile, commentaires exclus.
  ///
  /// L exclusion des commentaires n est pas une precaution de style : l en-tete
  /// de ce Podfile CITE le journal de CocoaPods et raconte le passage de 13.0 a
  /// 15.0. Chercher le motif dans le texte brut ferait lire au test une valeur
  /// racontee au lieu de la valeur declaree.
  String? plateformeDuPodfile() {
    final motif = RegExp(r'''^\s*platform\s+:ios\s*,\s*['"]([\d.]+)['"]''');
    for (final ligne in podfile.split('\n')) {
      if (RegExp(r'^\s*#').hasMatch(ligne)) continue;
      final m = motif.firstMatch(ligne);
      if (m != null) return m.group(1);
    }
    return null;
  }

  group('733 — le Podfile et le projet Xcode disent la meme cible iOS', () {
    test('le Podfile declare une plateforme iOS, sur une ligne de code', () {
      expect(
        plateformeDuPodfile(),
        isNotNull,
        reason:
            'la ligne `platform :ios, \'X\'` a disparu de $cheminPodfile. '
            'Sans elle, CocoaPods assigne une plateforme lui-meme — le journal '
            'du 07/10 disait « Automatically assigning platform iOS with '
            'version 15.0 on target Runner because no platform was specified » '
            '— et le depot ne tient plus la valeur. Reposez-la, egale a '
            'IPHONEOS_DEPLOYMENT_TARGET du projet Runner',
      );
    });

    test('le projet Runner declare UNE SEULE cible, sur ses trois '
        'configurations', () {
      final effectives = ciblesEffectivesDuRunner();
      expect(
        effectives.keys.toSet(),
        equals({'Debug', 'Release', 'Profile'}),
        reason:
            'les trois configurations attendues ne sont plus la : '
            '${effectives.keys.join(', ')}',
      );
      final detail = effectives.entries
          .map((e) => '${e.key} = ${e.value}')
          .join(', ');
      expect(
        effectives.values.toSet().length,
        1,
        reason:
            'la cible iOS de l application differe selon la configuration : '
            '$detail. Le Podfile ne peut en repeter qu une ; alignez les '
            'trois dans $cheminProjet',
      );
    });

    test('LA LIGNE platform DU PODFILE DIT LE MEME NOMBRE QUE '
        'IPHONEOS_DEPLOYMENT_TARGET DE LA CIBLE RUNNER', () {
      final duPodfile = plateformeDuPodfile();
      final effectives = ciblesEffectivesDuRunner();
      final duProjet = effectives.values.toSet();
      expect(
        duProjet,
        isNotEmpty,
        reason: 'aucune cible iOS lue dans le projet',
      );
      expect(
        duProjet,
        equals({duPodfile}),
        reason:
            'LES DEUX FICHIERS NE DISENT PLUS LA MEME CIBLE iOS.\n'
            '  $cheminPodfile          : platform :ios, \'$duPodfile\'\n'
            '  $cheminProjet : IPHONEOS_DEPLOYMENT_TARGET = '
            '${duProjet.join(' / ')} (cible Runner)\n'
            'Les deux valeurs se changent ENSEMBLE, jamais l une sans '
            'l autre : des pods compiles pour un iOS plus recent que '
            'l application, c est un module Swift refuse a la compilation, et '
            'l echec n arrive que sur un vrai macOS, apres des minutes de '
            'machine louee. '
            'Si la cible du projet est la bonne, recopiez-la dans la ligne '
            '`platform` du Podfile et mettez son commentaire d en-tete a jour. '
            'N ALIGNEZ PAS sur la cible TrekWidgetExtension, qui a le droit '
            'd etre plus haute.',
      );
    });

    test('l extension TrekWidget a le droit d etre plus haute, et la garde ne '
        'la confond pas avec l application', () {
      final duWidget = ciblesDeclareesPar(listeDuWidget);
      expect(
        duWidget.values.whereType<String>(),
        isNotEmpty,
        reason:
            'plus aucune cible iOS lue sur TrekWidgetExtension : le parcours '
            'est casse, et la garde ne prouverait plus qu elle distingue les '
            'deux cibles',
      );
      final valeursWidget = duWidget.values.whereType<String>().toSet();
      final valeursRunner = ciblesEffectivesDuRunner().values.toSet();
      // Le widget peut etre PLUS HAUT que l application (WidgetKit interactif
      // n existe pas avant iOS 17), jamais plus bas : il tournerait alors sur
      // des iPhone ou son code n existe pas.
      final plancherRunner = _enNombre(valeursRunner.single);
      for (final valeur in valeursWidget) {
        expect(
          _enNombre(valeur),
          greaterThanOrEqualTo(plancherRunner),
          reason:
              'TrekWidgetExtension vise iOS $valeur, SOUS le plancher de '
              'l application (${valeursRunner.single}) : une extension ne peut '
              'pas s installer plus bas que l application qui la porte',
        );
      }
    });

    test('LA GARDE MESURE VRAIMENT : elle lit des valeurs, elle ne confond pas '
        'les deux cibles, et un commentaire ne compte pas', () {
      // Si le parcours du pbxproj cassait, la garde passerait au vert en ne
      // lisant plus rien du tout : on exige qu elle lise les deux cotes.
      expect(plateformeDuPodfile(), matches(RegExp(r'^\d+\.\d+$')));
      expect(ciblesEffectivesDuRunner().length, 3);
      expect(
        ciblesDeclareesPar(listeDuProjet).values.whereType<String>(),
        hasLength(3),
      );

      // La cible Runner et l extension sont bien lues SEPAREMENT : les deux
      // listes ne partagent aucune configuration.
      expect(
        configurationsDe(
          listeDeLApplication,
        ).toSet().intersection(configurationsDe(listeDuWidget).toSet()),
        isEmpty,
      );

      // Le motif du Podfile ne se laisse pas prendre par un commentaire, et il
      // accepte les deux ecritures de CocoaPods.
      final motif = RegExp(r'''^\s*platform\s+:ios\s*,\s*['"]([\d.]+)['"]''');
      expect(motif.firstMatch("platform :ios, '15.0'")?.group(1), '15.0');
      expect(motif.firstMatch('platform :ios, "15.0"')?.group(1), '15.0');
      expect(RegExp(r'^\s*#').hasMatch("# platform :ios, '13.0'"), isTrue);

      // Et le reglage est bien lu dans un corps de configuration, pas devine.
      expect(
        RegExp(
          r'IPHONEOS_DEPLOYMENT_TARGET = ([\d.]+);',
        ).firstMatch('\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 15.0;')?.group(1),
        '15.0',
      );
    });
  });
}

/// Une cible iOS « 15.0 » comparable a une autre, sans se faire piquer par
/// l ordre alphabetique qui mettrait « 9.0 » au-dessus de « 15.0 ».
num _enNombre(String cible) {
  final parts = cible.split('.');
  final majeur = int.parse(parts.first);
  final mineur = parts.length > 1 ? int.parse(parts[1]) : 0;
  return majeur * 1000 + mineur;
}
