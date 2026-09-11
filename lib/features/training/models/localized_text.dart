import '../../../i18n/translations.g.dart';

/// Resout un champ texte i18n INLINE (fr/en/de/it/es) selon la langue courante.
///
/// StepWays LOT 5 : les DONNEES externalisees (plans d'entrainement, fiches
/// conseil) portent leurs traductions en clair dans le JSON (patron [TipCard]) —
/// elles ne passent PAS par Slang (qui ne gere que les libellés d'interface, pas
/// le contenu editorial variable par sentier). Ce helper choisit la bonne langue
/// a partir de [LocaleSettings.currentLocale], avec repli sur le FRANCAIS (base)
/// quand une traduction est absente (chaine vide) — jamais de texte vide affiche.
String pickLocalized({
  required String fr,
  String en = '',
  String de = '',
  String it = '',
  String es = '',
}) {
  final value = switch (LocaleSettings.currentLocale) {
    AppLocale.fr => fr,
    AppLocale.en => en,
    AppLocale.de => de,
    AppLocale.it => it,
    AppLocale.es => es,
  };
  // Repli base (fr) si la traduction demandee est vide (donnee incomplete).
  return value.isNotEmpty ? value : fr;
}
