import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/mare_a_mare_centre_trail_config.dart';
import 'package:moteur_gr/core/config/trail_catalog.dart';
import 'package:moteur_gr/features/packs/presentation/pack_store_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// TACHE 634 — RETOUR 7 DE CHRISTOPHE (DEM-260929-1326).
///
/// Verbatim : « Mare a mare centre, il manque centre dans le nom ».
///
/// CE QUI A ETE MESURE. La configuration porte le bon nom depuis toujours
/// (`mare_a_mare_centre_trail_config.dart` : 'Mare a Mare Centre'). Le mot
/// manquait a l'AFFICHAGE, sur le magasin de cartes hors ligne — parce que les
/// quatre noms de pack etaient des noms de sentier ECRITS EN DUR dans les cinq
/// fichiers de traduction, ou « Centre » n'avait jamais figure. Cet ecran ne
/// lisait a aucun moment le nom du sentier qu'il montrait.
///
/// C'est le piege que le brief nommait : lire la configuration ne suffisait
/// pas, il fallait remonter jusqu'au widget qui affiche.
void main() {
  group('plus aucun nom de sentier ecrit en dur dans les traductions', () {
    test('les cinq fichiers de traduction ne nomment plus aucun sentier', () {
      // LE GARDE-FOU DE FOND. Un moteur generique multi-sentiers ne doit porter
      // le nom d'AUCUN sentier particulier dans ses libelles : c'est ce qui a
      // fait perdre « Centre », et c'est ce qui aurait donne le nom du Mare a
      // Mare a tous les sentiers suivants.
      final fautifs = <String>[];
      for (final langue in ['fr', 'en', 'de', 'es', 'it']) {
        final brut = File('assets/i18n/$langue.i18n.json').readAsStringSync();
        final plat = _aplatir(jsonDecode(brut) as Map<String, dynamic>);
        plat.forEach((clef, valeur) {
          final sansTirets = valeur.replaceAll('-', ' ');
          if (sansTirets.toLowerCase().contains('mare a mare')) {
            fautifs.add('$langue : $clef = « $valeur »');
          }
        });
      }
      expect(
        fautifs,
        isEmpty,
        reason: 'nom de sentier en dur dans les traductions : $fautifs',
      );
    });

    test(
      'les quatre libelles de pack attendent desormais le nom du sentier',
      () {
        for (final langue in AppLocale.values) {
          final types = langue.buildSync().packs.types;
          const nom = 'Sentier Temoin';
          expect(types.nord.nom(trail: nom), contains(nom));
          expect(types.sud.nom(trail: nom), contains(nom));
          expect(types.complet.nom(trail: nom), contains(nom));
          expect(types.mam.nom(trail: nom), nom);
          expect(types.mam.description(trail: nom), contains(nom));
        }
      },
    );
  });

  group('le magasin de cartes affiche le nom COMPLET du sentier', () {
    testWidgets('« Centre » est a l ecran, dans les cinq langues', (
      tester,
    ) async {
      // Le sentier existe bien au catalogue sous ce nom-la.
      expect(mareAMareCentreTrailConfig.displayName, 'Mare a Mare Centre');
      expect(
        TrailCatalog.byId('mare-a-mare-centre')?.displayName,
        'Mare a Mare Centre',
      );

      for (final langue in AppLocale.values) {
        LocaleSettings.setLocale(langue);
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              locale: langue.flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: TranslationProvider(
                child: const PackStoreScreen(trailId: 'mare-a-mare-centre'),
              ),
            ),
          ),
        );
        await tester.pump();

        // LE MOT QUI MANQUAIT. Il doit apparaitre au moins une fois par pack
        // nomme, dans chacune des cinq langues.
        expect(
          find.textContaining('Mare a Mare Centre', findRichText: true),
          findsWidgets,
          reason:
              'le nom complet doit etre a l ecran en '
              '${langue.languageCode}',
        );

        // ET LE NOM TRONQUE NE DOIT PLUS EXISTER : un libelle qui vaut
        // exactement « Mare a Mare » est celui d'avant la correction.
        expect(
          find.text('Mare a Mare'),
          findsNothing,
          reason: 'nom tronque encore affiche en ${langue.languageCode}',
        );
      }
      LocaleSettings.setLocale(AppLocale.fr);
    });

    testWidgets('un AUTRE sentier ne porte plus le nom du Mare a Mare', (
      tester,
    ) async {
      // Le defaut de fond : l ecran affichait « Mare a Mare Nord » quel que
      // soit le sentier ouvert. Le sentier de demonstration des Pyrenees sert
      // de temoin.
      final temoin = TrailCatalog.all.firstWhere(
        (c) => c.id != 'mare-a-mare-centre' && !c.id.startsWith('mare-a-mare'),
      );

      LocaleSettings.setLocale(AppLocale.fr);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: AppLocale.fr.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: TranslationProvider(
              child: PackStoreScreen(trailId: temoin.id),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.textContaining('Mare a Mare', findRichText: true),
        findsNothing,
        reason:
            'le sentier « ${temoin.displayName} » ne doit porter le nom '
            'd aucun autre sentier',
      );
      expect(
        find.textContaining(temoin.displayName, findRichText: true),
        findsWidgets,
      );
    });
  });
}

/// Aplatit un arbre de traductions en « a.b.c » -> valeur texte.
Map<String, String> _aplatir(
  Map<String, dynamic> arbre, [
  String prefixe = '',
]) {
  final plat = <String, String>{};
  arbre.forEach((clef, valeur) {
    final chemin = prefixe.isEmpty ? clef : '$prefixe.$clef';
    if (valeur is Map<String, dynamic>) {
      plat.addAll(_aplatir(valeur, chemin));
    } else if (valeur is String) {
      plat[chemin] = valeur;
    }
  });
  return plat;
}
