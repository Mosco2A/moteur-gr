import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// GARDE — LE COCKPIT NE CONNAIT QU'UNE SEULE SOURCE POUR L'ETAT DE LA MARCHE
/// (tache 809).
///
/// POURQUOI UNE GARDE, ET PAS SEULEMENT UNE CORRECTION. Les trois defauts que
/// Christophe a signales le 10/10 n'etaient pas trois bugs : c'etait UNE
/// maladie, et sa forme etait structurelle. Chaque bouton du cockpit decidait
/// de son etat dans son coin —
///
///   * `hub_screen.dart` melangeait l'etat vivant du suivi et le cycle de vie
///     derive de la base ;
///   * `hub_trek_card.dart` refaisait le MEME melange, a sa facon ;
///   * `finish_trek_button.dart` le refaisait une troisieme fois ;
///   * `hub_buy_trek_button.dart` ne regardait pas la marche du tout.
///
/// Quatre lectures du meme fait, donc quatre chances de ne pas tomber d'accord
/// — et c'est exactement ce qui s'est produit en demonstration. Corriger les
/// quatre sans fermer la porte, c'etait accepter que le CINQUIEME bouton, celui
/// qu'on ajoutera demain, rouvre le meme trou.
///
/// CE QUE LA REGLE DIT. Dans tout `lib/features/hub/`, UN SEUL fichier a le
/// droit de lire les etats bruts de la marche : `presentation/cockpit_phase.dart`,
/// qui porte l'enum ET sa derivation. Tous les autres passent par
/// `cockpitPhaseProvider`. La derivation elle-meme est PRIVEE (`_fromLifecycle`)
/// : la portee de fichier fait la moitie du travail, cette garde dit l'autre
/// moitie — qu'aucun fichier ne recommence a lire les enums directement.
///
/// ELLE NE LIT QUE DU CODE. Les commentaires sont retires avant l'examen : ce
/// depot documente ses decisions en citant les noms de ses types, et une garde
/// qui interdirait d'en PARLER interdirait de les expliquer.
void main() {
  /// Le seul fichier autorise a deriver la phase.
  const souverain = 'lib/features/hub/presentation/cockpit_phase.dart';

  /// Les lectures d'etat brut de la marche, interdites ailleurs qu'au souverain.
  const interdits = <String>[
    'TrackingSessionStatus.recording',
    'TrackingSessionStatus.paused',
    'TrackingSessionStatus.stopped',
    'TrekLifecycleState.inProgress',
    'TrekLifecycleState.completed',
    'TrekLifecycleState.owned',
    'TrekLifecycleState.prepared',
    '_fromLifecycle(',
  ];

  /// Les fichiers du cockpit qui DOIVENT consulter la phase — s'ils cessent de
  /// la lire, c'est qu'ils ont recommence a decider seuls.
  const consommateurs = <String>[
    'lib/features/hub/presentation/hub_screen.dart',
    'lib/features/hub/presentation/widgets/hub_trek_card.dart',
    'lib/features/hub/presentation/widgets/hub_buy_trek_button.dart',
    'lib/features/hub/presentation/widgets/finish_trek_button.dart',
  ];

  List<File> fichiersDuHub() {
    final racine = Directory('lib/features/hub');
    expect(
      racine.existsSync(),
      isTrue,
      reason: 'le cockpit a change de place : la garde ne garde plus rien',
    );
    return racine
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
  }

  /// Le fichier sans ses commentaires, chemin normalise en separateurs POSIX.
  String codeNu(File f) => f
      .readAsLinesSync()
      .where((l) => !l.trimLeft().startsWith('//'))
      .join('\n');

  String chemin(File f) => f.path.replaceAll(r'\', '/');

  test('809-G1 — un seul fichier du cockpit derive l etat de la marche', () {
    final coupables = <String, List<String>>{};

    for (final f in fichiersDuHub()) {
      final rel = chemin(f);
      if (rel.endsWith('cockpit_phase.dart')) continue;
      final code = codeNu(f);
      final trouves = interdits.where(code.contains).toList();
      if (trouves.isNotEmpty) coupables[rel] = trouves;
    }

    expect(
      coupables,
      isEmpty,
      reason:
          'CES FICHIERS REDERIVENT L ETAT DE LA MARCHE AU LIEU DE LIRE LA '
          'PHASE.\n'
          'C est le defaut de la tache 809, et il a coute trois retours a '
          'Christophe.\n'
          'Lis `cockpitPhaseProvider` ($souverain) au lieu des enums bruts.\n'
          'Coupables : $coupables',
    );
  });

  test(
    '809-G2 — la derivation est PRIVEE, et la phase a une porte publique',
    () {
      final source = File(souverain);
      expect(source.existsSync(), isTrue, reason: '$souverain a disparu');
      final code = source.readAsStringSync();

      expect(
        code.contains('final cockpitPhaseProvider = Provider<CockpitPhase>'),
        isTrue,
        reason: 'la seule porte publique vers la phase doit vivre ici',
      );
      expect(
        code.contains('static CockpitPhase _fromLifecycle('),
        isTrue,
        reason:
            'la derivation doit rester PRIVEE : c est la portee de fichier qui '
            'empeche un bouton de se fabriquer sa propre phase',
      );
      expect(
        code.contains('static CockpitPhase fromLifecycle('),
        isFalse,
        reason: 'une derivation publique reouvre le trou de la tache 809',
      );
    },
  );

  test('809-G3 — les quatre boutons du cockpit consultent bien la phase', () {
    final muets = <String>[];
    for (final rel in consommateurs) {
      final f = File(rel);
      expect(f.existsSync(), isTrue, reason: '$rel a disparu');
      if (!codeNu(f).contains('cockpitPhaseProvider')) muets.add(rel);
    }
    expect(
      muets,
      isEmpty,
      reason:
          'CES FICHIERS NE CONSULTENT PLUS LA PHASE : ils ont donc recommence '
          'a decider seuls de leur visibilite. $muets',
    );
  });
}
