import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/tips/domain/models/tip_card.dart';

/// Tests E3.4b : validation JSON securite neige + incendie.
///
/// Verifie que les fichiers JSON sont parseables et que chaque fiche
/// contient les champs requis (id, titleFr, contentFr, scope, season,
/// category) avec les valeurs attendues pour le scope et la season.
void main() {
  /// Charge et parse un fichier JSON de fiches conseil.
  List<TipCard> loadTipCards(String path) {
    final file = File(path);
    expect(file.existsSync(), true, reason: 'Fichier $path introuvable');
    final content = file.readAsStringSync();
    final List<dynamic> jsonList = jsonDecode(content) as List<dynamic>;
    return jsonList
        .map((e) => TipCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Verifie les champs requis d une fiche conseil.
  void expectRequiredFields(TipCard card, String fileLabel) {
    expect(card.id.isNotEmpty, true,
        reason: '$fileLabel: id vide pour une fiche');
    expect(card.titleFr.isNotEmpty, true,
        reason: '$fileLabel: titleFr vide pour ${card.id}');
    expect(card.contentFr.isNotEmpty, true,
        reason: '$fileLabel: contentFr vide pour ${card.id}');
    expect(card.scope.isNotEmpty, true,
        reason: '$fileLabel: scope vide pour ${card.id}');
    expect(card.season.isNotEmpty, true,
        reason: '$fileLabel: season vide pour ${card.id}');
    expect(card.category.isNotEmpty, true,
        reason: '$fileLabel: category vide pour ${card.id}');
  }

  /// Verifie les 5 langues renseignees.
  void expectAllLanguages(TipCard card, String fileLabel) {
    expect(card.titleEn.isNotEmpty, true,
        reason: '$fileLabel: titleEn vide pour ${card.id}');
    expect(card.titleDe.isNotEmpty, true,
        reason: '$fileLabel: titleDe vide pour ${card.id}');
    expect(card.titleIt.isNotEmpty, true,
        reason: '$fileLabel: titleIt vide pour ${card.id}');
    expect(card.titleEs.isNotEmpty, true,
        reason: '$fileLabel: titleEs vide pour ${card.id}');
    expect(card.contentEn.isNotEmpty, true,
        reason: '$fileLabel: contentEn vide pour ${card.id}');
    expect(card.contentDe.isNotEmpty, true,
        reason: '$fileLabel: contentDe vide pour ${card.id}');
    expect(card.contentIt.isNotEmpty, true,
        reason: '$fileLabel: contentIt vide pour ${card.id}');
    expect(card.contentEs.isNotEmpty, true,
        reason: '$fileLabel: contentEs vide pour ${card.id}');
  }

  group('securite_neige.json', () {
    late List<TipCard> cards;

    setUpAll(() {
      cards = loadTipCards('assets/tips/securite_neige.json');
    });

    test('JSON parseable et champs requis presents', () {
      expect(cards.isNotEmpty, true,
          reason: 'Le fichier neige doit contenir au moins une fiche');
      for (final card in cards) {
        expectRequiredFields(card, 'neige');
      }
    });

    test('scope generique (all) — decontamination sentier-specifique', () {
      // Decontamination : les fiches neige ne sont plus couplees a un sentier.
      // Elles s'appliquent a tout sentier de montagne, le ciblage se fait
      // par l'altitude (minAltitudeM >= 1500), pas par un trailId hardcode.
      for (final card in cards) {
        expect(card.scope, 'all',
            reason:
                'Neige: scope doit etre all (generique, cible par altitude), pas ${card.scope} pour ${card.id}');
      }
    });

    test('season hiver ou printemps', () {
      final validSeasons = {'winter', 'spring'};
      for (final card in cards) {
        expect(validSeasons.contains(card.season), true,
            reason:
                'Neige: season doit etre winter ou spring, pas ${card.season} pour ${card.id}');
      }
    });

    test('altitude minimale >= 1500 m', () {
      for (final card in cards) {
        expect(card.minAltitudeM, isNotNull,
            reason: 'Neige: minAltitudeM requis pour ${card.id}');
        expect(card.minAltitudeM!, greaterThanOrEqualTo(1500),
            reason:
                'Neige: minAltitudeM doit etre >= 1500 pour ${card.id}');
      }
    });

    test('textes en 5 langues', () {
      for (final card in cards) {
        expectAllLanguages(card, 'neige');
      }
    });

    test('ids uniques', () {
      final ids = cards.map((c) => c.id).toSet();
      expect(ids.length, cards.length, reason: 'Neige: ids dupliques');
    });
  });

  group('securite_incendie.json', () {
    late List<TipCard> cards;

    setUpAll(() {
      cards = loadTipCards('assets/tips/securite_incendie.json');
    });

    test('JSON parseable et champs requis presents', () {
      expect(cards.isNotEmpty, true,
          reason: 'Le fichier incendie doit contenir au moins une fiche');
      for (final card in cards) {
        expectRequiredFields(card, 'incendie');
      }
    });

    test('scope general (all)', () {
      for (final card in cards) {
        expect(card.scope, 'all',
            reason:
                'Incendie: scope doit etre all (general), pas ${card.scope} pour ${card.id}');
      }
    });

    test('season ete', () {
      for (final card in cards) {
        expect(card.season, 'summer',
            reason:
                'Incendie: season doit etre summer, pas ${card.season} pour ${card.id}');
      }
    });

    test('textes en 5 langues', () {
      for (final card in cards) {
        expectAllLanguages(card, 'incendie');
      }
    });

    test('ids uniques', () {
      final ids = cards.map((c) => c.id).toSet();
      expect(ids.length, cards.length, reason: 'Incendie: ids dupliques');
    });
  });
}
