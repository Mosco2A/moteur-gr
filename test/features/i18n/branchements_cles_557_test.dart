import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/trail_catalog.dart';
import 'package:moteur_gr/features/poi/domain/poi_type_label.dart';
import 'package:moteur_gr/features/tips/presentation/tip_detail_sheet.dart';
import 'package:moteur_gr/features/trek/domain/models/stage.dart';
import 'package:moteur_gr/features/trek/presentation/stages/trek_stage_detail_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// GARDE-FOU DE NON-RETOUR — TACHE 557.
///
/// CE QUE CE FICHIER PROTEGE. La tache 552 a cree les cles manquantes dans les
/// cinq langues ; les ecrans qui les attendaient continuaient d'afficher soit
/// la formulation d'un AUTRE champ, soit la valeur BRUTE de la donnee. Rien ne
/// plantait, `flutter analyze` restait vert : c'est exactement le genre de
/// defaut qui revient sans bruit a la premiere refonte d'ecran.
///
/// Chaque test verrouille donc DEUX choses : que la bonne cle est lue, et que
/// la formulation empruntee ou la valeur brute n'est PLUS celle qui s'affiche.
void main() {
  setUpAll(() {
    // Libelles compares en francais, langue de reference du socle.
    LocaleSettings.setLocaleRaw('fr');
  });

  group('Fiches conseil — plus aucune valeur brute a l ecran', () {
    test('un scope « all » devient une phrase, jamais le mot all', () {
      expect(tipScopeLabel('all'), t.tips.scopeAll);
      expect(tipScopeLabel('all'), isNot('all'));
      // Champ absent du JSON : meme traitement que « tous les sentiers ».
      expect(tipScopeLabel(''), t.tips.scopeAll);
    });

    test('un scope de sentier devient le NOM que l application connait', () {
      final trail = TrailCatalog.all.first;
      expect(tipScopeLabel(trail.id), trail.displayName);
      expect(
        tipScopeLabel(trail.id),
        isNot(trail.id),
        reason: 'l identifiant technique ne doit plus arriver a l ecran',
      );
    });

    test('un sentier hors catalogue garde sa valeur, il n emprunte pas le nom '
        'd un AUTRE sentier', () {
      expect(tipScopeLabel('sentier_inconnu'), 'sentier_inconnu');
    });

    test('les cinq saisons sont traduites, « summer » ne s affiche plus', () {
      expect(tipSeasonLabel('all'), t.tips.seasons.all);
      expect(tipSeasonLabel('winter'), t.tips.seasons.winter);
      expect(tipSeasonLabel('spring'), t.tips.seasons.spring);
      expect(tipSeasonLabel('summer'), t.tips.seasons.summer);
      expect(tipSeasonLabel('autumn'), t.tips.seasons.autumn);
      for (final brut in ['winter', 'spring', 'summer', 'autumn']) {
        expect(tipSeasonLabel(brut), isNot(brut));
      }
    });

    test('une saison inconnue garde sa valeur plutot que d en inventer une',
        () {
      expect(tipSeasonLabel('mousson'), 'mousson');
    });
  });

  group('Guide de la carte — chaque signe porte son explication', () {
    test('les types de points ont tous leur texte, refuge partage celui de '
        'l abri', () {
      const types = [
        'water',
        'shelter',
        'refuge',
        'accommodation',
        'campsite',
        'shop',
        'restaurant',
        'viewpoint',
        'danger',
        'emergency',
        'info',
      ];
      for (final type in types) {
        final texte = poiTypeGuide(type);
        expect(texte, isNotNull, reason: 'le guide explique le type $type');
        expect(texte, isNotEmpty);
      }
      expect(poiTypeGuide('refuge'), poiTypeGuide('shelter'));
    });

    test('un type inconnu perd son paragraphe, il n en emprunte pas un autre',
        () {
      expect(poiTypeGuide('teleporteur'), isNull);
    });

    test('les deux types que la table oubliait sont traduits', () {
      // `accommodation` et `info` retombaient sur le libelle FRANCAIS du
      // registre, dans les cinq langues.
      expect(poiTypeLabel('accommodation'), t.poi.accommodation);
      expect(poiTypeLabel('info'), t.poi.info);
    });
  });

  group('Ecrans qui empruntaient la formulation d un autre ecran', () {
    test('le selecteur de pays a sa cle, distincte de celle du champ sexe', () {
      // Les deux disent « Non precise » en francais : c'est pour cela que
      // l'emprunt passait inapercu. Ce sont deux cles, donc deux textes qui
      // evoluent separement.
      expect(t.hikerProfile.countryUnspecified, isNotEmpty);
      expect(t.hikerProfile.sexUnspecified, isNotEmpty);
    });

    test('la barre d attente de la carte a sa phrase, pas celle du cockpit',
        () {
      expect(t.map.statsPendingNote, isNotEmpty);
      expect(t.map.statsPendingNote, isNot(t.hub.trekCard.noTrekBody));
    });

    test('la photo prise depuis la carte est confirmee, pas titree', () {
      expect(t.journal.photoAdded, isNotEmpty);
      expect(t.journal.photoAdded, isNot(t.journal.entriesOfDay));
    });

    test('la section des boutons du guide a son titre', () {
      expect(t.map.guide.buttonsTitle, isNotEmpty);
      expect(t.map.guide.buttonsTitle, isNot(t.map.layersTitle));
    });
  });

  group('Detail d etape — le nom ne repart plus du francais', () {
    /// Etape minimale portant un nom francais et un nom allemand.
    Stage stage({String nameDe = 'Deutscher Name'}) => Stage(
          id: 'e1',
          nameFr: 'Depart — Arrivee',
          nameDe: nameDe,
          distance: 10,
          elevationGain: 100,
          elevationLoss: 100,
          orderIndex: 1,
          startLat: 42,
          startLng: 9,
          endLat: 42.1,
          endLng: 9.1,
        );

    /// Resout [localizedStageName] sous une locale donnee.
    Future<String> nomSous(
      WidgetTester tester,
      Locale locale, {
      String nameDe = 'Deutscher Name',
    }) async {
      late String resolu;
      // [Localizations] nu plutot qu'un [MaterialApp] : la fonction testee ne
      // lit que `Localizations.localeOf`, et un MaterialApp exigerait les
      // delegues Material/Cupertino de chaque langue eprouvee ici.
      await tester.pumpWidget(
        Localizations(
          locale: locale,
          delegates: const [DefaultWidgetsLocalizations.delegate],
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (context) {
                resolu = localizedStageName(context, stage(nameDe: nameDe));
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      return resolu;
    }

    testWidgets('en allemand le nom est allemand — l AppBar lisait nameFr',
        (tester) async {
      expect(await nomSous(tester, const Locale('de')), 'Deutscher Name');
    });

    testWidgets('repli sur le francais quand la traduction est vide',
        (tester) async {
      expect(
        await nomSous(tester, const Locale('de'), nameDe: ''),
        'Depart — Arrivee',
      );
    });
  });
}
