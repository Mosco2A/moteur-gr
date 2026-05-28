import 'package:flutter/material.dart';

/// Widget de chargement centre.
///
/// Affiche un CircularProgressIndicator centre dans son parent
/// avec un message optionnel en dessous.
class LoadingView extends StatelessWidget {
  const LoadingView({
    super.key,
    this.message,
  });

  /// Message optionnel affiche sous le spinner.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
