import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/mare_a_mare_centre_trail_config.dart';
import 'package:moteur_gr/core/config/trail_catalog.dart';
import 'package:moteur_gr/core/models/niveau_de_telechargement.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/services/map_downloader.dart';
import 'package:moteur_gr/features/map/presentation/offline_maps_screen.dart';
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
///
/// MISE A JOUR PAR LA TACHE 640 (bug 10, DEM-260930-1017). Christophe a tranche
/// le 30/09 : « On ne propose pas de demi-Mare a Mare, pas besoin de telecharger
/// de demi-cartes ». Les quatre libelles de pack n'existent donc PLUS — ni eux,
/// ni le magasin de packs. Le test qui verifiait qu'ils attendaient le nom du
/// sentier a disparu avec son sujet ; les DEUX garanties de fond, elles, sont
/// conservees et portees sur le nouvel ecran « Cartes hors ligne » :
///   1. aucun libelle des cinq langues ne nomme un sentier particulier ;
///   2. l'ecran des cartes affiche le nom COMPLET du circuit qu'il montre, et
///      jamais celui d'un autre.
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
  });

  group('l ecran des cartes hors ligne affiche le nom COMPLET du sentier', () {
    Widget ecran(String trailId, AppLocale langue) => ProviderScope(
      overrides: [
        // L'ecran n'est pas le sujet ici : on fige sa decision pour ne
        // mesurer QUE le nom affiche, sans base ni reseau.
        descenteDesCartesProvider.overrideWithValue(_DescenteFigee()),
      ],
      child: MaterialApp(
        locale: langue.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: TranslationProvider(child: OfflineMapsScreen(trailId: trailId)),
      ),
    );

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
        await tester.pumpWidget(ecran('mare-a-mare-centre', langue));
        await tester.pumpAndSettle();

        // LE MOT QUI MANQUAIT. Il doit apparaitre a l'ecran dans chacune des
        // cinq langues, et il vient du SENTIER, pas d'un libelle.
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
      await tester.pumpWidget(ecran(temoin.id, AppLocale.fr));
      await tester.pumpAndSettle();

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

/// UNE DECISION FIGEE : aucune carte publiee, donc rien a transporter.
///
/// C'est le cas normal d'un sentier dont les tuiles ne sont pas encore
/// fabriquees, et il suffit a dessiner l'ecran en entier sans base ni reseau.
class _DescenteFigee extends Fake implements MapDownloader {
  @override
  Future<DecisionDeDescente> examiner(
    String trailId, {
    required NiveauDeTelechargement niveau,
    bool confirmeHorsWifi = false,
  }) async => DecisionDeDescente(
    trailId: trailId,
    octetsTotal: 0,
    octetsDejaLa: 0,
    lien: TypesDeLien.wifi,
    refus: RefusDeDescente.aucuneCartePubliee,
  );
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
