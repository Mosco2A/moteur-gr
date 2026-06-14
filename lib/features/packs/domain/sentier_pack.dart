import 'package:freezed_annotation/freezed_annotation.dart';

part 'sentier_pack.freezed.dart';
part 'sentier_pack.g.dart';

/// Types de pack sentier A LA CARTE (F8B-01, regle metier R2).
///
/// Modele FarOut « bundle » (A3-11) : chaque type est une UNITE achetable et
/// telechargeable INDEPENDANTE (Nord, Sud, Complet, Mare a Mare) — surtout PAS
/// un abonnement global facon Komoot (qui a fache sa base 2025). La decision
/// monetisation finale revient a Christophe : le modele code « achat de pack »,
/// jamais un abo force.
///
/// String extensible volontairement (cf. [DownloadStatus]) : un type inconnu
/// recu d'un futur catalogue serveur retombe sur [fallback] sans planter.
abstract final class PackType {
  /// Pack de la moitie Nord d'un sentier.
  static const String nord = 'nord';

  /// Pack de la moitie Sud d'un sentier.
  static const String sud = 'sud';

  /// Pack complet (Nord + Sud) d'un sentier.
  static const String complet = 'complet';

  /// Pack Mare a Mare (1er sentier cible, fiche #84627).
  static const String mam = 'mam';

  /// Valeur de repli pour un type inconnu.
  static const String fallback = complet;

  /// Tous les types de pack connus.
  static const List<String> values = [nord, sud, complet, mam];

  /// Normalise [value] vers un type connu, ou [fallback] sinon.
  static String fromString(String value) =>
      values.contains(value) ? value : fallback;
}

/// Pack sentier A LA CARTE (F8B-01, Phase 8 P8-B, regle metier R2).
///
/// Unite de contenu achetable/telechargeable INDEPENDANTE (Nord / Sud /
/// Complet / Mare a Mare) — modele FarOut « bundle », PAS de tout-abonnement
/// (R2, A3-11). Le pack reference son [PackManifest] (via [PackDownloadService]
/// F8B-02) qui decrit TOUT le contenu necessaire au 100 % offline.
///
/// [nom] et [description] sont des libelles LOCALISES (resolus via Slang a la
/// construction du catalogue, 5 langues) — aucun texte en dur cote moteur.
/// [trailId] rattache le pack a un sentier (le moteur reste generique, #84627).
@freezed
abstract class SentierPack with _$SentierPack {
  const SentierPack._();

  const factory SentierPack({
    /// Identifiant unique du pack (ex: 'mam_nord', 'mam_complet').
    required String id,

    /// Nom localise du pack (Slang) — ex « Mare a Mare Nord ».
    required String nom,

    /// Identifiant du sentier auquel ce pack appartient (genericite #84627).
    required String trailId,

    /// Type de pack ('nord' / 'sud' / 'complet' / 'mam', [PackType]).
    required String type,

    /// Description localisee du pack (Slang).
    required String description,
  }) = _SentierPack;

  /// Vrai si ce pack couvre l'integralite du sentier (Complet).
  bool get isComplet => type == PackType.complet;

  /// Deserialisation depuis JSON (catalogue serveur ou seed local).
  factory SentierPack.fromJson(Map<String, dynamic> json) =>
      _$SentierPackFromJson(json);
}
