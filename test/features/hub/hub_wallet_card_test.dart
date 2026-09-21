import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/features/hub/presentation/widgets/hub_wallet_card.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Correctif L7-1 — le solde du compte-etapes s affiche enfin.
///
/// Le portefeuille existait en entier (table, DAO, recharge, debit) mais son
/// solde n apparaissait sur AUCUN ecran. Ces tests verifient le branchement :
/// le solde s affiche, il suit les mouvements, et RIEN ne s affiche tant qu il
/// n est pas connu.
void main() {
  Widget harnais(StreamController<int> flux) {
    return ProviderScope(
      overrides: [
        walletStepsProvider.overrideWith((ref) => flux.stream),
      ],
      child: const MaterialApp(home: Scaffold(body: HubWalletCard())),
    );
  }

  testWidgets('affiche le solde et son libelle', (tester) async {
    final flux = StreamController<int>();
    addTearDown(flux.close);

    await tester.pumpWidget(harnais(flux));
    flux.add(42);
    await tester.pump();

    expect(find.text('42'), findsOneWidget);
    expect(find.text(t.monetization.walletTitle), findsOneWidget);
    expect(find.text(t.monetization.walletUnit), findsOneWidget);
  });

  testWidgets('RIEN tant que le solde n est pas connu (jamais un 0 de '
      'chargement)', (tester) async {
    final flux = StreamController<int>();
    addTearDown(flux.close);

    await tester.pumpWidget(harnais(flux));
    await tester.pump();

    expect(find.text(t.monetization.walletTitle), findsNothing);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('un solde a zero, lui, s affiche vraiment', (tester) async {
    final flux = StreamController<int>();
    addTearDown(flux.close);

    await tester.pumpWidget(harnais(flux));
    flux.add(0);
    await tester.pump();

    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('suit les mouvements du portefeuille', (tester) async {
    final flux = StreamController<int>();
    addTearDown(flux.close);

    await tester.pumpWidget(harnais(flux));
    flux.add(12);
    await tester.pump();
    expect(find.text('12'), findsOneWidget);

    // Une recharge, puis un achat de sentier.
    flux.add(112);
    await tester.pump();
    await tester.pump();
    expect(find.text('112'), findsOneWidget);
    expect(find.text('12'), findsNothing);
  });
}
