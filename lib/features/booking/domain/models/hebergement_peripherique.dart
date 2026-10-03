/// Un hebergement A COTE du sentier : StepWays est FACILITATEUR, il annonce le
/// detour aller-retour et renvoie au site de l'hebergeur.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'hebergement_peripherique.freezed.dart';
part 'hebergement_peripherique.g.dart';

/// Type d'hébergement périphérique (F6D-02).
enum HebergementType {
  @JsonValue('refuge')
  refuge,
  @JsonValue('gite')
  gite,
  @JsonValue('hotel')
  hotel,
  @JsonValue('camping')
  camping,
  @JsonValue('chambre_hote')
  chambreHote,
}

/// Hébergement situé À CÔTÉ du sentier (hors-trace), accessible via un
/// aller-retour depuis un point d'étape (F6.4, Phase 6).
///
/// StepWays est un FACILITATEUR (décision Chris #84100) : on affiche le détour
/// A/R estimé et un lien profond ([deeplinkUrl]) vers le site/app du
/// prestataire. AUCUNE intermédiation, AUCUNE réservation ni paiement in-app,
/// AUCUNE collecte de données de réservation. Données fictives en P2-P3
/// (fiche #84627) — pas de Firebase réel ici.
@freezed
abstract class HebergementPeripherique with _$HebergementPeripherique {
  const HebergementPeripherique._();

  const factory HebergementPeripherique({
    /// Identifiant unique de l'hébergement.
    required String id,

    /// Nom commercial de l'hébergement.
    required String nom,

    /// Type d'hébergement.
    required HebergementType type,

    /// Latitude de l'hébergement (hors-trace).
    required double latitude,

    /// Longitude de l'hébergement (hors-trace).
    required double longitude,

    /// Distance aller-retour estimée (km) depuis le point d'étape de référence.
    required double distanceAllerRetourKm,

    /// Lien profond (URL) vers le site/app du prestataire pour réserver, ou
    /// `null` quand on ne le connait pas.
    ///
    /// NULLABLE DEPUIS LE LOT 645-08 (voie V2, arbitrage de Christophe du
    /// 02/10/2026), ET LE CHANGEMENT DE TYPE EST LE POINT. Tant que le champ
    /// etait `required String`, un hebergement sans lien connu ne pouvait
    /// s'ecrire que d'une seule facon : une chaine inventee. Les trois
    /// hebergements de demonstration portaient donc `https://example.org/...`,
    /// et l'ecran construisait un bouton « Voir le site » qui n'envoyait le
    /// randonneur nulle part. Le facilitateur ouvre ce lien quand il existe
    /// ([hasDeeplink]) ; sinon il n'y a PAS de bouton, pas de tiret, pas
    /// d'espace reserve. Aucune reservation in-app dans les deux cas (#84100).
    String? deeplinkUrl,
  }) = _HebergementPeripherique;

  /// Détour aller simple estimé (km), soit la moitié de l'aller-retour.
  double get distanceAllerKm => distanceAllerRetourKm / 2;

  /// Vrai si un lien profond exploitable est disponible (bouton affiche).
  ///
  /// Meme contrat que `GuideItem.hasDeeplink` et `Shop.hasWebsite` : une chaine
  /// vide n'est pas un lien, et un lien qu'on n'a pas ne se montre pas.
  bool get hasDeeplink => deeplinkUrl != null && deeplinkUrl!.isNotEmpty;

  /// Désérialisation depuis JSON (config sentier, données fictives P2-P3).
  factory HebergementPeripherique.fromJson(Map<String, dynamic> json) =>
      _$HebergementPeripheriqueFromJson(json);
}
