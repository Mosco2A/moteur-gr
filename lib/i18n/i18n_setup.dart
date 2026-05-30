/// Setup Slang i18n pour le Moteur GR.
///
/// Ce fichier fournit la configuration et les helpers pour
/// l'internationalisation via Slang (5 langues: fr, en, de, it, es).
///
/// Les fichiers de traduction sont dans assets/i18n/*.i18n.json.
/// Le code genere sera dans lib/i18n/translations.g.dart
/// apres execution de: dart run slang_build_runner.
///
/// Usage dans les widgets:
///   import 'package:moteur_gr/i18n/translations.g.dart';
///   Text(t.map.title)
///
/// Langues supportees:
/// - fr (francais) — langue de base
/// - en (anglais)
/// - de (allemand)
/// - it (italien)
/// - es (espagnol)
library i18n_setup;

/// Liste des codes de langue supportes par le Moteur GR.
const supportedLocales = ['fr', 'en', 'de', 'it', 'es'];

/// Langue par defaut (base locale Slang).
const defaultLocale = 'fr';
