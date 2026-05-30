import 'package:flutter/material.dart';

/// Widget generique de chargement centre.
///
/// Affiche un indicateur de progression circulaire centre
/// avec un message optionnel en dessous.
class LoadingView extends StatelessWidget {
  const LoadingView({
    super.key,
    this.message,
  });

  /// Message optionnel affiche sous l'indicateur de chargement.
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}
