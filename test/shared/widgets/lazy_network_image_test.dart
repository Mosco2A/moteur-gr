import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/shared/widgets/lazy_network_image.dart';

/// Tests E5.2b — primitive d'image distante a chargement paresseux.
void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('URL nulle : placeholder, aucune requete CachedNetworkImage',
      (tester) async {
    await tester.pumpWidget(wrap(const LazyNetworkImage(imageUrl: null)));

    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('URL vide/espaces : placeholder, aucune requete', (tester) async {
    await tester.pumpWidget(wrap(const LazyNetworkImage(imageUrl: '   ')));

    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
  });

  testWidgets('URL valide : construit un CachedNetworkImage', (tester) async {
    await tester.pumpWidget(
      wrap(
        const LazyNetworkImage(
          imageUrl: 'https://example.invalid/photo.jpg',
          width: 100,
          height: 100,
        ),
      ),
    );

    expect(find.byType(CachedNetworkImage), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Demonter pour liberer le chargement asynchrone (pas de fuite de timer).
    await tester.pumpWidget(wrap(const SizedBox()));
  });

  testWidgets('borderRadius : enveloppe dans un ClipRRect', (tester) async {
    await tester.pumpWidget(
      wrap(
        LazyNetworkImage(
          imageUrl: null,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    expect(find.byType(ClipRRect), findsWidgets);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
  });
}
