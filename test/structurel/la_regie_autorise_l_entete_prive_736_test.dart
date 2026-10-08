import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// GARDE STRUCTURELLE — LA REGIE PUBLICITAIRE GARDE LE DROIT D INCLURE
/// L EN-TETE PRIVE DE GOOGLE, SUR SES DEUX CIBLES ET NULLE PART AILLEURS
/// (tache 736).
///
/// LE DEFAUT QU ELLE EMPECHE DE REVENIR. Build 4 du 08/10/2026, 12 minutes de
/// machine macOS, 545 s de Xcode, et deux erreurs — deux seulement :
///
///   Include of non-modular header inside framework module
///   'google_mobile_ads.FLTAd_Internal'  (puis '...FLTAdPreloader')
///   .../XCFrameworkIntermediates/Google-Mobile-Ads-SDK/
///   GoogleMobileAds.framework/PrivateHeaders/GoogleMobileAds_Beta.h
///
/// MESURE DANS LE CACHE DE PAQUETS. google_mobile_ads 9.1.0 importe
/// `<GoogleMobileAds/GoogleMobileAds_Beta.h>` a la ligne 23 de son
/// `FLTAd_Internal.h` et a la ligne 18 de son `FLTAdPreloader.h`
/// (`ios/google_mobile_ads/Sources/google_mobile_ads/include/google_mobile_ads/`).
/// La version 5.3.1 du meme greffon s arretait a
/// `<GoogleMobileAds/GoogleMobileAds.h>` : cet import est arrive AVEC la
/// montee de version. Et l en-tete vise vit dans `PrivateHeaders/` d un
/// xcframework livre DEJA COMPILE par Google — le chemin
/// `XCFrameworkIntermediates` du journal le prouve — donc hors de la carte de
/// modules du framework. Clang refuse qu un module de framework inclue un tel
/// en-tete : c est la verification que
/// `CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES` desarme.
///
/// CE QUE LE DRAPEAU DESARME, EN TOUTES LETTRES. Clang cesse d exiger que tout
/// en-tete inclus depuis les en-tetes d un module de framework appartienne
/// lui-meme a un module ; il l inclut alors TEXTUELLEMENT. On perd la garantie
/// que le module est autonome. C est une verification d hygiene sur des
/// en-tetes TIERS, a la compilation seulement : aucun effet a l execution,
/// aucune surface magasin, et le depot n a aucun module de framework a lui.
///
/// LES DEUX CIBLES, ET POURQUOI DEUX. Le module `google_mobile_ads` n est
/// construit que par deux cibles, mesurees et non devinees :
///   1. LE POD lui-meme, qui porte `DEFINES_MODULE = YES` (podspec ligne 21) —
///      il recoit le drapeau par le `post_install` du Podfile, nomme ;
///   2. LA CIBLE `Runner`, parce que `ios/Runner/GeneratedPluginRegistrant.m`
///      fait `#import <google_mobile_ads/FLTGoogleMobileAdsPlugin.h>` a sa
///      ligne 106 et que les TROIS configurations de `Runner` portent
///      `CLANG_ENABLE_MODULES = YES`. Sous `-fmodules`, un import de style
///      framework construit le module, et construire le module enumere TOUS
///      ses en-tetes publics, FLTAd_Internal.h comprise. Elle recoit le
///      drapeau par ses reglages de base, `ios/Flutter/Debug.xcconfig` et
///      `ios/Flutter/Release.xcconfig`.
/// Le pod est construit AVANT l application : le build 4 est tombe sur la
/// premiere et n a jamais atteint la seconde. Ne servir que le pod aurait donc
/// rendu un build 5 rouge au meme endroit, douze minutes plus tard. C est la
/// raison d etre des deux moities, et la raison d etre de cette garde.
///
/// COMMENT ELLE LIT. Jamais une chaine cherchee dans le texte brut : les trois
/// fichiers surveilles CITENT le nom du drapeau dans leurs commentaires, et un
/// test qui lirait une valeur racontee au lieu d une valeur declaree serait
/// pire que pas de test. Les commentaires sont donc ecartes partout — `#` pour
/// le Podfile, `//` pour les reglages — et le projet Xcode est lu en RESOLVANT
/// la chaine de renvois comme Xcode le fait, a la maniere de la garde 733.
void main() {
  const cheminPodfile = 'ios/Podfile';
  const cheminDebug = 'ios/Flutter/Debug.xcconfig';
  const cheminRelease = 'ios/Flutter/Release.xcconfig';
  const cheminProjet = 'ios/Runner.xcodeproj/project.pbxproj';

  const drapeau = 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES';
  const regie = 'google_mobile_ads';
  const listeDeLApplication =
      'Build configuration list for PBXNativeTarget "Runner"';

  late String podfile;
  late String projet;
  late Map<String, String> reglages;

  setUpAll(() {
    for (final chemin in [
      cheminPodfile,
      cheminDebug,
      cheminRelease,
      cheminProjet,
    ]) {
      expect(
        File(chemin).existsSync(),
        isTrue,
        reason:
            '$chemin introuvable : la garde 736 ne sait plus ou lire le '
            'droit d inclure l en-tete prive de Google',
      );
    }
    podfile = File(cheminPodfile).readAsStringSync();
    projet = File(cheminProjet).readAsStringSync();
    reglages = {
      cheminDebug: File(cheminDebug).readAsStringSync(),
      cheminRelease: File(cheminRelease).readAsStringSync(),
    };
  });

  /// Les lignes de CODE d un fichier : celles qui ne commencent pas par le
  /// marqueur de commentaire [marqueur], une fois l indentation retiree.
  List<String> lignesDeCode(String source, String marqueur) => source
      .split('\n')
      .where((l) => !RegExp('^\\s*${RegExp.escape(marqueur)}').hasMatch(l))
      .toList();

  // ---------------------------------------------------------------------
  // LE POD — le `post_install` du Podfile
  // ---------------------------------------------------------------------

  /// Les lignes de code du Podfile, du `post_install` jusqu a la fin.
  List<String> codeDuPostInstall() {
    final code = lignesDeCode(podfile, '#');
    final debut = code.indexWhere(
      (l) => RegExp(r'^\s*post_install\b').hasMatch(l),
    );
    expect(
      debut,
      isNot(-1),
      reason:
          'le bloc `post_install` a disparu de $cheminPodfile : c est par lui '
          'que le pod $regie recoit le droit d inclure l en-tete prive',
    );
    return code.sublist(debut);
  }

  group('736 — la regie garde le droit d inclure l en-tete prive', () {
    test('le Podfile pose le drapeau a YES, sur une ligne de code', () {
      final pose = codeDuPostInstall().where(
        (l) => RegExp(
          '''build_settings\\[\\s*['"]$drapeau['"]\\s*\\]\\s*=\\s*['"]YES['"]''',
        ).hasMatch(l),
      );
      expect(
        pose.length,
        1,
        reason:
            'le `post_install` de $cheminPodfile doit poser $drapeau a YES '
            'une fois et une seule. Sans lui, la compilation du pod $regie '
            'tombe sur « Include of non-modular header inside framework '
            'module », comme le build 4 du 08/10/2026 — et on ne l apprend '
            'qu apres neuf minutes de machine macOS louee.',
      );
    });

    test('le drapeau du Podfile est porte par la SEULE cible de la regie', () {
      final code = codeDuPostInstall();
      final assignation = RegExp('''build_settings\\[\\s*['"]$drapeau['"]''');
      final condition = RegExp(r'^\s*(if|unless|elsif)\b');
      String? derniereCondition;
      var vue = false;
      for (final ligne in code) {
        if (condition.hasMatch(ligne)) derniereCondition = ligne;
        if (!assignation.hasMatch(ligne)) continue;
        vue = true;
        expect(
          derniereCondition,
          isNotNull,
          reason:
              '$drapeau est pose dans $cheminPodfile SANS condition : il '
              'tombe alors sur les 37 greffons iOS du depot. Un seul en a '
              'besoin. Les 36 autres doivent garder la verification, pour '
              'que le jour ou l un d eux inclura un en-tete non modulaire, '
              'on nous le dise encore.',
        );
        expect(
          RegExp(
            'target\\.name\\s*==\\s*[\'"]$regie[\'"]',
          ).hasMatch(derniereCondition!),
          isTrue,
          reason:
              'la condition qui porte $drapeau dans $cheminPodfile ne nomme '
              'plus `target.name == \'$regie\'` mais « '
              '${derniereCondition.trim()} ». La garde ne peut plus affirmer '
              'que le drapeau ne touche que la regie publicitaire.',
        );
      }
      expect(
        vue,
        isTrue,
        reason: '$drapeau ne figure plus dans le `post_install`',
      );
    });

    test('le Podfile appelle toujours les reglages iOS de Flutter', () {
      expect(
        codeDuPostInstall().any(
          (l) => l.contains('flutter_additional_ios_build_settings'),
        ),
        isTrue,
        reason:
            'le `post_install` de $cheminPodfile n appelle plus '
            '`flutter_additional_ios_build_settings` : les pods perdent les '
            'chemins du moteur Flutter, le bitcode, les architectures et le '
            'plancher iOS que l outil leur pose. Le drapeau de la regie '
            'vient EN PLUS de ces reglages, jamais A LA PLACE.',
      );
    });

    // -------------------------------------------------------------------
    // LA CIBLE RUNNER — les deux reglages de l application
    // -------------------------------------------------------------------

    test('les deux reglages de l application posent le drapeau a YES', () {
      for (final entree in reglages.entries) {
        final poses = lignesDeCode(entree.value, '//')
            .where((l) => RegExp('^\\s*$drapeau\\s*=').hasMatch(l))
            .map((l) => l.split('=').last.trim())
            .toList();
        expect(
          poses,
          ['YES'],
          reason:
              '${entree.key} doit declarer `$drapeau=YES` une fois, sur une '
              'ligne de code. C est le reglage de base des configurations de '
              'la cible `Runner`, et `Runner` construit le module $regie '
              'elle aussi : `GeneratedPluginRegistrant.m` l importe a sa '
              'ligne 106 et les trois configurations portent '
              '`CLANG_ENABLE_MODULES = YES`. Servir le pod sans servir '
              'l application, c est deplacer l echec de neuf minutes plus '
              'tot a douze minutes plus tard.',
        );
      }
    });

    // -------------------------------------------------------------------
    // LE PROJET XCODE — il ne doit pas contredire les reglages
    // -------------------------------------------------------------------

    /// Isole une section nommee du pbxproj, bornes exclues.
    String section(String nom) {
      final debut = projet.indexOf('/* Begin $nom section */');
      final fin = projet.indexOf('/* End $nom section */');
      expect(debut, isNot(-1), reason: 'section $nom absente du pbxproj');
      expect(fin, greaterThan(debut), reason: 'section $nom mal fermee');
      return projet.substring(debut, fin);
    }

    /// Le corps de l objet [identifiant], accolades imbriquees comptees — un
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
        reason: 'liste de configurations « $etiquette » absente du pbxproj',
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

    /// La valeur que la configuration [identifiant] DECLARE pour [reglage], ou
    /// `null` quand elle n en declare pas : elle prend alors celle de son
    /// reglage de base, exactement comme Xcode le fait.
    String? declarePar(String identifiant, String reglage) {
      final corps = objet(section('XCBuildConfiguration'), identifiant);
      expect(corps, isNotNull, reason: 'configuration $identifiant absente');
      final m = RegExp(
        '${RegExp.escape(reglage)} = ([^;]+);',
      ).firstMatch(corps!);
      return m?.group(1)?.trim();
    }

    test('aucune configuration de Runner ne contredit les reglages', () {
      for (final identifiant in configurationsDe(listeDeLApplication)) {
        final declare = declarePar(identifiant, drapeau);
        expect(
          declare == null || declare == 'YES',
          isTrue,
          reason:
              'la configuration ${nomDe(identifiant)} de la cible `Runner` '
              'declare `$drapeau = $declare` dans $cheminProjet. Un reglage '
              'declare par la cible ECRASE celui de son reglage de base : '
              'cette valeur annule en silence celle de '
              '$cheminDebug / $cheminRelease, et le build iPhone retombe sur '
              'l en-tete prive de Google. Si le drapeau doit vivre dans le '
              'projet Xcode, il vaut YES.',
        );
      }
    });

    test('les trois configurations de Runner construisent des modules', () {
      final effectives = <String, String?>{};
      for (final identifiant in configurationsDe(listeDeLApplication)) {
        effectives[nomDe(identifiant)] = declarePar(
          identifiant,
          'CLANG_ENABLE_MODULES',
        );
      }
      expect(
        effectives,
        {'Debug': 'YES', 'Release': 'YES', 'Profile': 'YES'},
        reason:
            'les configurations de la cible `Runner` ne portent plus toutes '
            '`CLANG_ENABLE_MODULES = YES` : $effectives. C est la PREMISSE de '
            'la moitie « application » de ce correctif — sans modules, '
            '`#import <google_mobile_ads/...>` de '
            '`GeneratedPluginRegistrant.m` ne construit plus le module et le '
            'drapeau des deux reglages devient inutile. Si ce changement est '
            'voulu, c est ici qu on relit la decision de la tache 736 avant '
            'de retirer quoi que ce soit.',
      );
    });
  });
}
