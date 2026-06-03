
import pathlib

Q = chr(39)  # single quote

lines = [
    f"import {Q}package:flutter/material.dart{Q};",
    f"import {Q}package:flutter_riverpod/flutter_riverpod.dart{Q};",
    "",
    f"import {Q}../../../core/theme/app_theme.dart{Q};",
    f"import {Q}../../../i18n/translations.g.dart{Q};",
    f"import {Q}../providers/feedback_provider.dart{Q};",
    "",
    "/// Bottom sheet de feedback accessible partout dans l app.",
    "///",
    "/// Formulaire avec : categorie (chips bug/suggestion/compliment),",
    "/// message texte, note 1-5. Utilise les textes Slang.",
    "/// Stocke via FeedbackNotifier (offline-first).",
    "class FeedbackBottomSheet extends ConsumerStatefulWidget {",
    "  const FeedbackBottomSheet({super.key});",
    "",
    "  /// Affiche le bottom sheet de feedback depuis n importe quel ecran.",
    "  static void show(BuildContext context) {",
    "    showModalBottomSheet<void>(",
    "      context: context,",
    "      isScrollControlled: true,",
    "      shape: const RoundedRectangleBorder(",
    "        borderRadius: BorderRadius.vertical(",
    "          top: Radius.circular(AppTheme.radiusBottomSheet),",
    "        ),",
    "      ),",
    "      builder: (_) => const FeedbackBottomSheet(),",
    "    );",
    "  }",
    "",
    "  @override",
    "  ConsumerState<FeedbackBottomSheet> createState() =>",
    "      _FeedbackBottomSheetState();",
    "}",
]

print(chr(10).join(lines))
