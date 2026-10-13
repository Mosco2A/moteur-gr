import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// GARDE STRUCTURELLE — LES DEUX CHAINES QUI SIGNENT POUR IPHONE SUIVENT LE
/// MODELE DE GR20, ET LEURS GARDES NOMMENT CE QUI MANQUE (07/10).
///
/// POURQUOI CETTE GARDE EXISTE. StepWays n a jamais ete compilee signee pour
/// iPhone : `ios_release` et `ios_testflight` attendaient cinq valeurs brutes
/// dans un groupe qui n a jamais existe, et fabriquaient le certificat avec une
/// clef privee passee par variable. L application GR20, sur le meme compte
/// Apple, signe autrement et compte cinquante builds iOS reussis : certificat
/// et profils appeles PAR LEUR NOM dans Codemagic, Xcode epingle. Ce modele ne
/// tient que si chacun de ces points reste vrai :
///   - l outil qui fabriquait la signature exige une clef privee de
///     certificat, or celle de l equipe vit dans le magasin de Codemagic ; le
///     remettre ferait creer un SECOND certificat de distribution ;
///   - il y a DEUX paquets (application et widget), donc DEUX profils, et un
///     seul nom faux suffit a ce que la signature echoue loin du defaut ;
///   - `latest` ne designe pas un compilateur fixe.
/// Chacun se casse en une ligne, sans que la relecture d un diff le voie.
void main() {
  final fichier = File('codemagic.yaml');
  final doc = File('docs/ci/signature_ios_modele_gr20.md');
  const pbxproj = 'ios/Runner.xcodeproj/project.pbxproj';

  /// Les noms de reference attendus dans Codemagic, A LA LETTRE. Ce sont eux
  /// que Christophe saisit ; le document et la configuration doivent dire les
  /// memes.
  const profilApp = 'stepways_appstore_profile';
  const profilWidget = 'stepways_trekwidget_appstore_profile';
  const certificat = 'GR20 Distribution';

  const signantes = ['ios_release', 'ios_testflight'];

  late List<String> lignes;

  /// Une chaine, de sa cle jusqu a la premiere ligne qui ne lui appartient
  /// plus. Meme decoupage que les gardes 619, 621 et 626.
  String chaine(String nom, {bool sansCommentaires = false}) {
    final debut = lignes.indexWhere((l) => l.startsWith('  $nom:'));
    expect(debut, isNot(-1), reason: 'chaine $nom introuvable');
    final corps = <String>[lignes[debut]];
    for (var i = debut + 1; i < lignes.length; i++) {
      if (RegExp(r'^  ([a-z0-9_]+:|#)').hasMatch(lignes[i])) break;
      corps.add(lignes[i]);
    }
    return corps
        .where((l) => !sansCommentaires || !RegExp(r'^\s*#').hasMatch(l))
        .join('\n');
  }

  /// La valeur d une variable du bloc `vars:` d une chaine.
  String variable(String bloc, String nom) {
    final m = RegExp(
      '^        $nom: (\\S+)\$',
      multiLine: true,
    ).firstMatch(bloc);
    expect(m, isNotNull, reason: '$nom absent du bloc vars:');
    return m!.group(1)!;
  }

  setUpAll(() {
    expect(fichier.existsSync(), isTrue, reason: 'codemagic.yaml introuvable');
    lignes = fichier.readAsLinesSync();
  });

  group('07/10 — la signature iPhone suit le modele de GR20', () {
    for (final nom in signantes) {
      test('$nom appelle par leur nom les deux profils et le certificat', () {
        final bloc = chaine(nom, sansCommentaires: true);
        expect(
          bloc,
          contains('      ios_signing:\n        provisioning_profiles:'),
          reason: 'sans bloc ios_signing, rien ne pose la signature',
        );
        for (final profil in const [profilApp, profilWidget]) {
          expect(
            bloc,
            contains('- profile: $profil\n'),
            reason:
                'le profil $profil n est plus appele. Il y a DEUX paquets, '
                'l application et le widget : sans lui, l un des deux ne se '
                'signe pas',
          );
        }
        expect(
          bloc,
          contains('certificates:\n          - $certificat\n'),
          reason:
              'le certificat de l equipe doit etre appele par son nom de '
              'reference dans Codemagic, « $certificat »',
        );
      });

      test('$nom ne fabrique plus la signature avec une clef privee', () {
        final bloc = chaine(nom, sansCommentaires: true);
        for (final perime in const [
          'fetch-signing-files',
          'CERTIFICATE_PRIVATE_KEY',
          'stepways_ios_signing',
          'keychain add-certificates',
        ]) {
          expect(
            bloc.contains(perime),
            isFalse,
            reason:
                '« $perime » est revenu dans $nom. fetch-signing-files exige '
                'la clef privee du certificat, qui vit dans le magasin de '
                'Codemagic ; lui en donner une neuve fabriquerait un SECOND '
                'certificat de distribution',
          );
        }
        expect(
          bloc,
          contains('xcode-project use-profiles'),
          reason:
              'sans elle, les profils poses ne sont pas appliques au projet',
        );
        expect(
          bloc.indexOf('xcode-project use-profiles'),
          lessThan(bloc.indexOf('flutter build ipa')),
        );
      });

      test('$nom : son analyse statique peut reussir', () {
        final bloc = chaine(nom, sansCommentaires: true);
        expect(
          bloc.contains('dart analyze --no-fatal-infos'),
          isFalse,
          reason:
              '`dart analyze` refuse `--no-fatal-infos` (« Cannot negate '
              'option », sortie 64) depuis Dart 2.19 : l etape tomberait '
              'a chaque build, quel que soit le code',
        );
        expect(bloc, contains('flutter analyze --no-fatal-infos lib/ test/'));
      });

      test('$nom : Xcode epingle a 26.4, instance mac_mini_m2', () {
        final bloc = chaine(nom, sansCommentaires: true);
        expect(
          bloc,
          contains('      xcode: 26.4\n'),
          reason:
              'Apple exige le SDK iOS 26 depuis avril 2026, et latest ne '
              'designe pas un compilateur fixe. 26.4 est celui de GR20',
        );
        expect(bloc, contains('    instance_type: mac_mini_m2\n'));
      });

      test('$nom : les identifiants annonces sont ceux du depot', () {
        final bloc = chaine(nom, sansCommentaires: true);
        final source = File(pbxproj).readAsStringSync();
        for (final nomVar in const ['BUNDLE_ID', 'WIDGET_BUNDLE_ID']) {
          final valeur = variable(bloc, nomVar);
          expect(
            source,
            contains('PRODUCT_BUNDLE_IDENTIFIER = $valeur;'),
            reason: '$nomVar vaut $valeur, qu aucune cible du projet ne porte',
          );
        }
        expect(
          variable(bloc, 'WIDGET_BUNDLE_ID'),
          '${variable(bloc, 'BUNDLE_ID')}.TrekWidget',
        );
        final groupe = variable(bloc, 'APP_GROUP');
        for (final droits in const [
          'ios/Runner/Runner.entitlements',
          'ios/TrekWidget/TrekWidgetExtension.entitlements',
        ]) {
          expect(
            File(droits).readAsStringSync(),
            contains('<string>$groupe</string>'),
            reason: '$droits ne reclame pas $groupe',
          );
        }
      });

      test('$nom : les gardes passent AVANT la construction et nomment ce qui '
          'manque', () {
        final bloc = chaine(nom);
        final build = bloc.indexOf('flutter build ipa');
        final profils = bloc.indexOf('Les deux profils nommes sont-ils la');
        expect(profils, isNot(-1), reason: 'la garde des profils a disparu');
        expect(profils, lessThan(build));
        final garde = bloc.substring(profils, build);
        for (final attendu in const [
          profilApp,
          profilWidget,
          certificat,
          'docs/ci/signature_ios_modele_gr20.md',
          'exit 1',
        ]) {
          expect(
            garde,
            contains(attendu),
            reason:
                'la garde des profils ne nomme plus « $attendu » : un '
                'manque se lirait plus loin, dans un message d Xcode',
          );
        }
        expect(
          bloc.indexOf('Les identifiants annonces sont-ils ceux du projet'),
          allOf(isNot(-1), lessThan(build)),
        );
      });

      test('$nom : l IPA, CHACUNE de ses extensions et le widget sont '
          'controles, et les journaux Xcode gardes', () {
        final bloc = chaine(nom);
        final apres = bloc.substring(bloc.indexOf('flutter build ipa'));
        expect(apres, contains(r'$app/embedded.mobileprovision'));
        expect(apres, contains(r'$appex/embedded.mobileprovision'));
        expect(
          apres,
          contains(r'$WIDGET_BUNDLE_ID'),
          reason:
              'decision du 07/10 : l application et le widget partent '
              'ensemble, un IPA sans widget doit arreter la chaine',
        );
        expect(bloc, contains('- /tmp/xcodebuild_logs/*.log'));
      });
    }

    test('ios_release ne recoit PAS l integration : elle ne publie rien', () {
      final bloc = chaine('ios_release', sansCommentaires: true);
      expect(
        bloc.contains('integrations:'),
        isFalse,
        reason:
            'signer par ios_signing ne demande aucune clef d API, et une '
            'chaine declenchee par etiquette n a pas a pouvoir '
            's authentifier chez Apple',
      );
    });

    test('ios_compile compile avec le MEME Xcode que les chaines qui signent, '
        'et sans rien appeler', () {
      final bloc = chaine('ios_compile', sansCommentaires: true);
      expect(
        bloc,
        contains('      xcode: 26.4\n'),
        reason:
            'un vert obtenu sur un autre compilateur ne predit rien de la '
            'compilation des chaines qui signent',
      );
      for (final interdit in const ['ios_signing', 'integrations:']) {
        expect(
          bloc.contains(interdit),
          isFalse,
          reason: 'ios_compile ne signe rien et ne doit rien recevoir',
        );
      }
    });

    test('le document dit les memes noms que la configuration', () {
      expect(doc.existsSync(), isTrue);
      final texte = doc.readAsStringSync();
      for (final nom in const [
        profilApp,
        profilWidget,
        certificat,
        'Only1Cent',
        'com.only1cent.stepways.TrekWidget',
        'group.com.only1cent.stepways',
      ]) {
        expect(
          texte,
          contains(nom),
          reason:
              'docs/ci/signature_ios_modele_gr20.md ne cite plus « $nom » : '
              'Christophe saisirait un nom que la chaine n attend pas',
        );
      }
    });
  });
}
