import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/routing/contextual_actions_provider.dart';
import 'package:moteur_gr/shared/widgets/contextual_action_bar.dart';
import 'package:moteur_gr/shared/widgets/contextual_bottom_bar.dart';

/// Tests du mécanisme DÉCLARATIF de la barre contextuelle (StepWays LOT 3, Ph2).
///
/// Couvre : barre absente si aucune action ; barre affiche N actions déclarées ;
/// set-on-mount / clear-on-dispose via [ContextualActionsMixin] ; cibles ≥ 48 dp.
void main() {
  ContextualAction action(String label) => ContextualAction(
        icon: Icons.star,
        label: label,
        onPressed: () {},
      );

  group('ContextualBottomBar — rendu piloté par le provider', () {
    testWidgets('barre ABSENTE si aucune action (SizedBox.shrink)',
        (tester) async {
      await tester.pumpWidget(const ProviderScope(
        child: MaterialApp(
          home: Scaffold(bottomNavigationBar: ContextualBottomBar()),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(BottomAppBar), findsNothing);
    });

    testWidgets('barre affiche les N actions déclarées dans le provider',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(contextualActionsProvider.notifier).set([
        action('A'),
        action('B'),
        action('C'),
      ]);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(bottomNavigationBar: ContextualBottomBar()),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(BottomAppBar), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('vider le provider retire la barre', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(contextualActionsProvider.notifier).set([action('A')]);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(bottomNavigationBar: ContextualBottomBar()),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(BottomAppBar), findsOneWidget);

      container.read(contextualActionsProvider.notifier).clear();
      await tester.pumpAndSettle();
      expect(find.byType(BottomAppBar), findsNothing);
    });

    testWidgets('cibles tactiles >= 48 dp (hauteur de la barre)',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(contextualActionsProvider.notifier)
          .set([action('A'), action('B')]);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(bottomNavigationBar: ContextualBottomBar()),
        ),
      ));
      await tester.pumpAndSettle();

      final barSize = tester.getSize(find.byType(BottomAppBar));
      expect(barSize.height, greaterThanOrEqualTo(48.0));
    });
  });

  group('ContextualActionsMixin — set-on-mount / clear-on-dispose', () {
    testWidgets('un écran déclare ses actions au montage, vidées au démontage',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Écran hôte qui déclare 2 actions via le mixin.
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: _HostScreen()),
      ));
      await tester.pumpAndSettle();

      // Au montage (post-frame) : la barre porte les 2 actions déclarées.
      expect(find.byType(BottomAppBar), findsOneWidget);
      expect(find.text('Preparer'), findsOneWidget);
      expect(find.text('Randonner'), findsOneWidget);
      expect(container.read(contextualActionsProvider), hasLength(2));

      // Démontage de l'écran -> les actions sont vidées (barre absente).
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: SizedBox())),
      ));
      await tester.pumpAndSettle();
      expect(container.read(contextualActionsProvider), isEmpty);
    });
  });
}

/// Écran de test consommant [ContextualActionsMixin] : déclare 2 actions et
/// affiche la [ContextualBottomBar].
class _HostScreen extends ConsumerStatefulWidget {
  const _HostScreen();

  @override
  ConsumerState<_HostScreen> createState() => _HostScreenState();
}

class _HostScreenState extends ConsumerState<_HostScreen>
    with ContextualActionsMixin {
  @override
  List<ContextualAction> buildContextualActions(BuildContext context) => [
        ContextualAction(
          icon: Icons.assignment_outlined,
          label: 'Preparer',
          onPressed: () {},
        ),
        ContextualAction(
          icon: Icons.hiking,
          label: 'Randonner',
          onPressed: () {},
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      bottomNavigationBar: ContextualBottomBar(),
      body: SizedBox(),
    );
  }
}
