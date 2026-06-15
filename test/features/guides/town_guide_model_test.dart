import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/guides/domain/town_guide.dart';
import 'package:moteur_gr/features/guides/domain/town_guide_catalog.dart';

/// Tests F8C-01 : modele Freezed TownGuide multi-sections (offline, FarOut-like).
///
/// Couvre : serialisation JSON aller-retour d'un TownGuide multi-sections (tout
/// le contenu offline), categories extensibles avec fallback, helpers du modele
/// (hasContent / categories / sectionFor) et le catalogue fictif P2-P3.
void main() {
  group('GuideCategory — categories extensibles', () {
    test('expose les 6 categories attendues dans l ordre', () {
      expect(GuideCategory.values, [
        GuideCategory.ravitaillement,
        GuideCategory.hebergement,
        GuideCategory.transport,
        GuideCategory.services,
        GuideCategory.eau,
        GuideCategory.sante,
      ]);
    });

    test('fromString retombe sur le fallback pour une categorie inconnue', () {
      expect(GuideCategory.fromString('inexistant'), GuideCategory.fallback);
      expect(GuideCategory.fromString(GuideCategory.eau), GuideCategory.eau);
    });
  });

  group('GuideItem — deeplink facilitateur (#84100)', () {
    test('hasDeeplink vrai uniquement si un lien sortant est present', () {
      const avec = GuideItem(
        nom: 'Gite',
        description: 'desc',
        deeplinkUrl: 'https://example.org/gite',
      );
      const sans = GuideItem(nom: 'Fontaine', description: 'desc');
      const vide = GuideItem(nom: 'X', description: 'desc', deeplinkUrl: '');
      expect(avec.hasDeeplink, isTrue);
      expect(sans.hasDeeplink, isFalse);
      expect(vide.hasDeeplink, isFalse);
    });

    test('serialisation JSON aller-retour preserve lien + coordonnees', () {
      const item = GuideItem(
        nom: 'Fontaine',
        description: 'Eau potable',
        deeplinkUrl: 'https://example.org/eau',
        coordonnees: GuideCoordinates(latitude: 42.1, longitude: 9.1),
      );
      final json = item.toJson();
      final restored = GuideItem.fromJson(json);
      expect(restored, item);
      expect(json['deeplinkUrl'], 'https://example.org/eau');
      expect((json['coordonnees'] as Map)['latitude'], 42.1);
    });
  });

  group('TownGuide — serialisation multi-sections (offline R3)', () {
    const guide = TownGuide(
      id: 'trail_corte',
      trailId: 'trail',
      nomLieu: 'Corte',
      latitude: 42.3,
      longitude: 9.15,
      sections: [
        GuideSection(
          categorie: GuideCategory.ravitaillement,
          titre: 'Ravitaillement',
          contenu: 'Commerces du centre.',
          items: [
            GuideItem(
              nom: 'Epicerie',
              description: 'Ouverte le matin.',
              deeplinkUrl: 'https://example.org/epicerie',
            ),
          ],
        ),
        GuideSection(
          categorie: GuideCategory.eau,
          titre: 'Eau',
          items: [
            GuideItem(
              nom: 'Fontaine',
              description: 'Potable.',
              coordonnees: GuideCoordinates(latitude: 42.301, longitude: 9.151),
            ),
          ],
        ),
        GuideSection(
          categorie: GuideCategory.sante,
          titre: 'Sante',
          items: [
            GuideItem(nom: 'Pharmacie', description: 'Premiers soins.'),
          ],
        ),
      ],
    );

    test('aller-retour JSON preserve toutes les sections et leurs items', () {
      final json = guide.toJson();
      final restored = TownGuide.fromJson(json);
      expect(restored, guide);
      // Le guide decrit TOUT son contenu offline (multi-sections).
      expect((json['sections'] as List), hasLength(3));
      expect(json['nomLieu'], 'Corte');
      expect(json['trailId'], 'trail');
    });

    test('hasContent vrai des qu une section porte des items', () {
      expect(guide.hasContent, isTrue);
      const vide = TownGuide(
        id: 'x',
        trailId: 'trail',
        nomLieu: 'Lieu',
        latitude: 0,
        longitude: 0,
      );
      expect(vide.hasContent, isFalse);
    });

    test('categories liste les sections normalisees dans l ordre', () {
      expect(guide.categories, [
        GuideCategory.ravitaillement,
        GuideCategory.eau,
        GuideCategory.sante,
      ]);
    });

    test('sectionFor retrouve une section par categorie (et null sinon)', () {
      expect(guide.sectionFor(GuideCategory.eau)?.titre, 'Eau');
      expect(guide.sectionFor(GuideCategory.transport), isNull);
    });

    test('section avec categorie inconnue est normalisee vers le fallback', () {
      const s = GuideSection(categorie: 'zzz', titre: 'X');
      expect(s.normalizedCategorie, GuideCategory.fallback);
    });
  });

  group('TownGuideCatalog — donnees fictives P2-P3 (#84627)', () {
    GuideSectionLabels resolver(String categorie) =>
        GuideSectionLabels(titre: 'Titre $categorie', contenu: 'Intro $categorie');

    test('guidesFor retourne des guides rattaches au sentier demande', () {
      final guides = TownGuideCatalog.guidesFor(
        'mare_a_mare_centre',
        sectionLabelResolver: resolver,
      );
      expect(guides, isNotEmpty);
      expect(guides.every((g) => g.trailId == 'mare_a_mare_centre'), isTrue);
      // Identifiants distincts et prefixes par le trailId (genericite).
      expect(guides.map((g) => g.id).toSet(), hasLength(guides.length));
      expect(guides.first.id, startsWith('mare_a_mare_centre_'));
    });

    test('les titres de section proviennent du resolver (Slang cote UI)', () {
      final guides = TownGuideCatalog.guidesFor(
        'mare_a_mare_centre',
        sectionLabelResolver: resolver,
      );
      final premiere = guides.first.sections.first;
      expect(premiere.titre, 'Titre ${premiere.categorie}');
      expect(premiere.contenu, 'Intro ${premiere.categorie}');
    });

    test('chaque guide a des sections avec items consultables offline', () {
      final guides = TownGuideCatalog.guidesFor(
        'mare_a_mare_centre',
        sectionLabelResolver: resolver,
      );
      for (final guide in guides) {
        expect(guide.hasContent, isTrue, reason: 'guide ${guide.id} vide');
        for (final s in guide.sections) {
          expect(GuideCategory.values, contains(s.normalizedCategorie));
        }
      }
    });

    test('au moins un item expose un deeplink facilitateur (#84100)', () {
      final guides = TownGuideCatalog.guidesFor(
        'mare_a_mare_centre',
        sectionLabelResolver: resolver,
      );
      final hasAnyDeeplink = guides.any(
        (g) => g.sections.any((s) => s.items.any((i) => i.hasDeeplink)),
      );
      expect(hasAnyDeeplink, isTrue);
    });

    test('guideById retrouve un guide existant et null sinon', () {
      final guides = TownGuideCatalog.guidesFor(
        'mare_a_mare_centre',
        sectionLabelResolver: resolver,
      );
      final id = guides.first.id;
      expect(
        TownGuideCatalog.guideById(
          'mare_a_mare_centre',
          id,
          sectionLabelResolver: resolver,
        ),
        isNotNull,
      );
      expect(
        TownGuideCatalog.guideById(
          'mare_a_mare_centre',
          'inexistant',
          sectionLabelResolver: resolver,
        ),
        isNull,
      );
    });
  });
}
