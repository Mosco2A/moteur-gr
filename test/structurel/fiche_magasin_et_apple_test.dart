import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// GARDE STRUCTURELLE — LA FICHE MAGASIN ET LE PAQUET IPHONE DISENT LA VERITE
/// (lot fiche magasin et preparation Apple, 07/10/2026).
///
/// POURQUOI. L audit du 07/10 a confronte les quinze promesses de la fiche au
/// code : cinq ne tenaient pas, dont un partage de position en temps reel que
/// la politique de confidentialite publiee declare eteint. Le nom du magasin
/// etait reste « The Ways » dans 26 fichiers. Les textes d autorisation iOS
/// n existaient qu en francais, et le texte de localisation en arriere-plan
/// promettait lui aussi le partage. La cle de declaration de chiffrement
/// manquait, ce qui fait poser la question a chaque envoi.
///
/// Cette garde verrouille ce qui a ete corrige, pour qu un copier-coller d une
/// ancienne fiche ne le defasse pas en silence.
void main() {
  const langues = ['fr', 'en', 'de', 'it', 'es'];

  String lire(String chemin) => File(chemin).readAsStringSync();

  group('fiche magasin — le nom et les limites d Apple', () {
    test('« The Ways » n apparait plus nulle part sous assets/store', () {
      final fautifs = Directory('assets/store')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.readAsStringSync().contains('The Ways'))
          .map((f) => f.path)
          .toList();
      expect(fautifs, isEmpty, reason: 'le nom du magasin est StepWays');
    });

    for (final l in langues) {
      test('$l : titre, sous-titre, mots-cles, promo et description tiennent '
          'dans les limites', () {
        final titre = lire('assets/store/ios/title_$l.txt').trim();
        final sousTitre = lire('assets/store/ios/subtitle_$l.txt').trim();
        final motsCles = lire('assets/store/ios/keywords_$l.txt').trim();
        final promo = lire('assets/store/ios/promotional_text_$l.txt').trim();
        final description = lire('assets/store/ios/description_$l.txt');

        expect(titre, startsWith('StepWays'));
        expect(titre.length, lessThanOrEqualTo(30), reason: titre);
        expect(sousTitre.length, lessThanOrEqualTo(30), reason: sousTitre);
        // En OCTETS : une lettre accentuee compte double, et c est la mesure
        // la plus stricte des deux.
        expect(
          utf8.encode(motsCles).length,
          lessThanOrEqualTo(100),
          reason: motsCles,
        );
        expect(promo.length, lessThanOrEqualTo(170), reason: promo);
        expect(description.length, lessThanOrEqualTo(4000));
      });

      test('$l : aucun mot-cle ne repete le titre ou le sous-titre', () {
        Set<String> mots(String s) => s
            .toLowerCase()
            .split(RegExp(r'[\s,\-]+'))
            .where((m) => m.isNotEmpty)
            .toSet();
        final dejaIndexes = {
          ...mots(lire('assets/store/ios/title_$l.txt')),
          ...mots(lire('assets/store/ios/subtitle_$l.txt')),
        };
        final doublons = lire('assets/store/ios/keywords_$l.txt')
            .trim()
            .split(',')
            .where((m) => dejaIndexes.contains(m.toLowerCase()))
            .toList();
        expect(doublons, isEmpty, reason: 'Apple indexe deja ces mots');
      });

      test('$l : les deux magasins portent la meme description', () {
        expect(
          lire('assets/store/android/full_description_$l.txt'),
          lire('assets/store/ios/description_$l.txt'),
        );
      });
    }

    test('les promesses retirees ne reviennent pas, dans aucune langue', () {
      // Une racine par promesse et par langue. La liste complete et la
      // condition pour remettre chacune : assets/store/PROMESSES_RETIREES.md.
      const interdits = [
        // partage en temps reel par lien prive
        'lien privé', 'private link', 'privaten Link', 'link privato',
        'enlace privado', 'proches', 'relatives', 'Angehörig', 'familiari',
        'seres queridos',
        // carte hors ligne et « par secteur »
        'par secteur', 'by area', 'nach Gebiet', 'per settore', 'por sector',
        '100 %', '100%', 'entièrement hors ligne', 'fully offline',
        'komplett offline', 'completamente offline', 'totalmente sin conexión',
        // profils interactifs
        'interactif', 'interactive', 'interaktiv', 'interattiv', 'interactiv',
        // photos geolocalisees
        'géolocalisé', 'geolocated', 'georeferenz', 'geolocalizzat',
        'geolocalizad', 'geotagg',
        // mode economie de batterie
        'économie de batterie', 'battery saver', 'battery-saving',
        'Energiespar', 'risparmio energetico', 'ahorro de batería',
        // trace « haute definition » et « plein soleil »
        'haute définition', 'high-definition', 'plein soleil', 'sunlight',
      ];
      final fichiers = [
        for (final l in langues) ...[
          'assets/store/ios/description_$l.txt',
          'assets/store/ios/subtitle_$l.txt',
          'assets/store/ios/promotional_text_$l.txt',
          'assets/store/android/short_description_$l.txt',
        ],
      ];
      final trouves = <String>[
        for (final f in fichiers)
          for (final mot in interdits)
            if (lire(f).toLowerCase().contains(mot.toLowerCase())) '$f : $mot',
      ];
      expect(trouves, isEmpty);
    });
  });

  group('paquet iPhone — ce que la revue d Apple lit', () {
    final plist = lire('ios/Runner/Info.plist');

    test('la declaration de chiffrement est posee, a NO', () {
      expect(
        RegExp(
          r'<key>ITSAppUsesNonExemptEncryption</key>\s*<false/>',
        ).hasMatch(plist),
        isTrue,
        reason:
            'sans cette cle, App Store Connect pose la question a chaque '
            'envoi ; le raisonnement est dans docs/store/'
            'fiche-app-store-connect.md',
      );
    });

    test('les cinq langues sont declarees', () {
      final bloc = RegExp(
        r'<key>CFBundleLocalizations</key>\s*<array>(.*?)</array>',
        dotAll: true,
      ).firstMatch(plist);
      expect(bloc, isNotNull);
      for (final l in langues) {
        expect(bloc!.group(1), contains('<string>$l</string>'));
      }
    });

    test('chaque texte d autorisation existe dans les cinq langues', () {
      final cles = RegExp(
        r'<key>(NS[A-Za-z]+UsageDescription)</key>',
      ).allMatches(plist).map((m) => m.group(1)!).toList();
      expect(cles, isNotEmpty);
      for (final l in langues) {
        final strings = lire('ios/Runner/$l.lproj/InfoPlist.strings');
        for (final cle in cles) {
          expect(
            RegExp('^"$cle" = "[^"]+";\$', multiLine: true).hasMatch(strings),
            isTrue,
            reason: '$l.lproj : $cle manque ou est vide',
          );
        }
      }
    });

    test('les InfoPlist.strings sont COPIES dans le paquet par le projet '
        'Xcode, pas seulement poses sur le disque', () {
      final pbx = lire('ios/Runner.xcodeproj/project.pbxproj');
      final groupe = RegExp(
        r'(\w{24}) /\* InfoPlist\.strings \*/ = \{\s*isa = PBXVariantGroup;'
        r'(.*?)\};',
        dotAll: true,
      ).firstMatch(pbx);
      expect(groupe, isNotNull, reason: 'groupe de variantes absent');
      for (final l in langues) {
        expect(pbx, contains('path = $l.lproj/InfoPlist.strings;'));
      }
      final ressources = RegExp(
        r'97C146EC1CF9000F007C117D /\* Resources \*/ = \{(.*?)\};',
        dotAll: true,
      ).firstMatch(pbx)!.group(1)!;
      expect(ressources, contains('InfoPlist.strings in Resources'));
      final regions = RegExp(
        r'knownRegions = \((.*?)\);',
        dotAll: true,
      ).firstMatch(pbx)!.group(1)!;
      for (final l in langues) {
        expect(regions, contains(l));
      }
    });

    test(
      'aucun texte d autorisation ne promet le partage avec les proches',
      () {
        final textes = [
          plist,
          for (final l in langues)
            lire('ios/Runner/$l.lproj/InfoPlist.strings'),
        ].join('\n').toLowerCase();
        for (final mot in const [
          'proches',
          'relatives',
          'angehörig',
          'familiari',
          'seres queridos',
          'temps réel',
          'real time',
        ]) {
          expect(textes.contains(mot), isFalse, reason: mot);
        }
      },
    );

    test(
      'aucune note au reviewer ne porte d identifiant ni de mot de passe',
      () {
        final notes = lire('assets/store/ios/app_review_notes.md');
        expect(notes, isNot(contains('@')));
        expect(
          RegExp(
            r'(password|mot de passe)\s*[:=]\s*\S',
            caseSensitive: false,
          ).hasMatch(notes),
          isFalse,
        );
      },
    );
  });
}
