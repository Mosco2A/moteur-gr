import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// OUTIL DE TEST — OUVRIR LE VOLET DU CALCUL DE LA FAISABILITE (tache 634).
///
/// Depuis DEM-260929-1134, l'ecran de faisabilite repond D'ABORD (est-ce
/// faisable, en combien de jours) et range TOUT le calcul sous un volet ferme :
/// l'introduction, le plafond conseille, le detail du verdict, la synthese, le
/// score de circuit et les conditions. Rien n'a ete supprime — c'etait la
/// consigne de Christophe, « les explications restent disponibles, jamais
/// imposees » — mais rien de tout cela n'est plus a l'ecran au premier regard.
///
/// Les tests qui verifient ces contenus doivent donc faire le geste que fait le
/// randonneur curieux : ouvrir le volet. Cette fonction le fait, et elle fait
/// defiler jusqu'a lui d'abord, parce que le volet est en bas de page.
Future<void> ouvrirLeVoletDuCalcul(WidgetTester tester) async {
  final volet = find.byKey(const ValueKey('feasibility-explain-toggle'));
  await tester.scrollUntilVisible(volet, 200);
  await tester.tap(volet);
  await tester.pumpAndSettle();
}

/// Fait defiler jusqu'a [cible] apres avoir ouvert le volet.
///
/// Le volet deplie plusieurs ecrans de contenu : un `expect` pose juste apres
/// l'ouverture ne verrait que ses premieres lignes.
Future<void> ouvrirLeVoletEtAtteindre(WidgetTester tester, Finder cible) async {
  await ouvrirLeVoletDuCalcul(tester);
  await tester.scrollUntilVisible(cible, 200);
}
