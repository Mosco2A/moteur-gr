/// Le lancement d'un lien sortant passe par une abstraction, pour que les tests
/// verifient l'URL demandee sans ouvrir de navigateur.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/models/hebergement_peripherique.dart';

/// Lanceur de lien profond (deeplink) — abstraction testable (F6D-02).
///
/// Découple l'écran de `url_launcher` pour la testabilité : en prod, ouvre le
/// site/app du prestataire ; en test, un fake enregistre l'URL demandée.
/// FACILITATEUR uniquement (#84100) : on OUVRE un lien sortant, jamais de
/// réservation ni de paiement in-app.
abstract interface class DeeplinkLauncher {
  /// Ouvre [url] dans le navigateur / l'app cible. Retourne `false` si l'URL
  /// ne peut pas être ouverte (aucune app capable), sans lever d'exception.
  Future<bool> open(String url);
}

/// Implémentation par défaut basée sur `url_launcher`.
class UrlLauncherDeeplink implements DeeplinkLauncher {
  const UrlLauncherDeeplink();

  /// ELLE TRAHISSAIT SON PROPRE CONTRAT (tâche 579, LOT X). L'interface promet,
  /// quelques lignes plus haut, de « retourner `false` […] sans lever
  /// d'exception ». Or `canLaunchUrl` et `launchUrl` LÈVENT dès que le canal de
  /// plateforme n'est pas là, ou qu'aucune application ne sait ouvrir le lien.
  /// L'exception traversait l'écran, le `if (!opened)` qui devait afficher
  /// « Impossible d'ouvrir ce lien » n'était jamais atteint, et le bouton
  /// « Voir le site » ne produisait RIEN. Le garde existait : c'est le chemin
  /// d'exception qui passait au-dessus de lui.
  @override
  Future<bool> open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    try {
      if (!await canLaunchUrl(uri)) return false;
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      // Un lien qu'on ne sait pas ouvrir est un `false`, jamais une exception :
      // c'est ce que l'appelant attend pour pouvoir le DIRE à l'utilisateur.
      return false;
    }
  }
}

/// Provider du lanceur de deeplink (surchargeable en test).
final deeplinkLauncherProvider = Provider<DeeplinkLauncher>(
  (ref) => const UrlLauncherDeeplink(),
);

/// Source des hébergements périphériques d'un sentier (F6D-02).
///
/// Données FICTIVES en P2-P3 (fiche #84627) : pas de Firebase réel ici. Le
/// catalogue réel viendra de la config sentier (TrailConfig / Drift) en P4+.
/// Paramétré par `trailId` pour rester générique (zéro marque en dur).
///
/// AUCUN DES TROIS NE PORTE DE LIEN PROFOND, ET C'EST VOLONTAIRE (lot 645-08,
/// voie V2 arbitree par Christophe le 02/10/2026). Ils pointaient sur
/// `example.org` — le domaine reserve aux exemples (RFC 2606) — et l'ecran en
/// faisait un bouton « Voir le site » qui n'ouvrait rien. Le lien invente est
/// RETIRE, pas remplace par une chaine vide : `deeplinkUrl` est nul, donc
/// `HebergementPeripherique.hasDeeplink` est faux, donc la carte s'arrete
/// apres le detour A/R. Un vrai lien, le jour ou il existe, rallume le bouton
/// sans toucher a l'ecran.
final hebergementsPeripheriquesProvider =
    Provider.family<List<HebergementPeripherique>, String>((ref, trailId) {
      // Jeu de données générique de démonstration (pas de marque réelle).
      return const [
        HebergementPeripherique(
          id: 'hp-1',
          nom: 'Gîte du Vallon',
          type: HebergementType.gite,
          latitude: 42.12,
          longitude: 9.05,
          distanceAllerRetourKm: 2.4,
        ),
        HebergementPeripherique(
          id: 'hp-2',
          nom: 'Refuge des Crêtes',
          type: HebergementType.refuge,
          latitude: 42.15,
          longitude: 9.08,
          distanceAllerRetourKm: 5.0,
        ),
        HebergementPeripherique(
          id: 'hp-3',
          nom: 'Camping de la Rivière',
          type: HebergementType.camping,
          latitude: 42.10,
          longitude: 9.02,
          distanceAllerRetourKm: 1.2,
        ),
      ];
    });
