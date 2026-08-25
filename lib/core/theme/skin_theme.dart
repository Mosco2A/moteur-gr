import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'app_skin.dart';

/// Traitement visuel des en-tetes selon la peau (SW-SKIN-L2).
///
/// Lu par `AppGradientHeader` (L5) pour choisir son fond :
///  - [gradient]  : bandeau `brandGradient` derive de l'accent-sentier (peau A).
///  - [topoFilet] : surface papier + filet de lignes de niveau, sans degrade
///    (peau B). CCO §3 peau B.
///  - [photo]     : photo plein ecran + scrim ; fallback [gradient] si aucune
///    image fournie (peau C). CCO §3 peau C.
enum SkinHeaderStyle { gradient, topoFilet, photo }

/// Style de carte selon la peau (SW-SKIN-L2).
///
/// Lu par `AppCard` (une fois pilote par le theme en L3) :
///  - [elevatedSoft]    : elevation douce, coins arrondis (peau A).
///  - [thinInstrument]  : bord fin "instrument" facon carte topo (peau B).
///  - [photo]           : carte-photo / surface douce translucide (peau C).
enum SkinCardStyle { elevatedSoft, thinInstrument, photo }

/// Peau visuelle portee par le theme via `ThemeData.extensions` (SW-SKIN-L2).
///
/// `SkinTheme` regroupe les decisions visuelles NON couleur-sentier d'une peau
/// (cf. CCO `data/cco_stepways_peaux.md` §2.1) : famille typo des titres,
/// traitement des en-tetes, style de carte, usage de l'image et parametres de
/// scrim, plus les drapeaux dont les composants des lots suivants (L5/L6/L9)
/// auront besoin. L'accent couleur N'EST PAS porte ici : il reste injecte par le
/// sentier (`TrailConfig`) — peau et couleur-sentier sont orthogonaux (§2.4).
///
/// C'est le porteur technique qui rend les peaux 2 et 3 "quasi gratuites" : une
/// fois les composants pilotes par `SkinTheme`, ajouter une peau = fournir un
/// nouveau `SkinTheme`, sans toucher les ecrans (§2.2).
///
/// Neutralite (L2) : tant qu'aucun composant ne lit `SkinTheme` (avant L5/L6),
/// l'injection de cette extension NE CHANGE PAS le rendu.
@immutable
class SkinTheme extends ThemeExtension<SkinTheme> {
  const SkinTheme({
    required this.skin,
    required this.titleFontFamily,
    required this.headerStyle,
    required this.cardStyle,
    required this.usesImagery,
    required this.usesMonoData,
    required this.scrimOpacity,
  });

  /// Identifiant de la peau (utile pour brancher / tester / tracer).
  final AppSkin skin;

  /// Famille typo des titres surchargeant le defaut du theme.
  ///
  /// `null` -> on garde la famille du `TextTheme` (Space Grotesk, cf. L1). Seule
  /// la peau Grand Air surcharge (serif editoriale) ; les peaux A/B laissent
  /// `null` (A garde Space Grotesk ; B affinera en L8). CCO §3.
  final String? titleFontFamily;

  /// Traitement des en-tetes (degrade / filet topo / photo). Lu par L5.
  final SkinHeaderStyle headerStyle;

  /// Style de carte (elevation douce / bord fin / photo). Lu par L3/L5.
  final SkinCardStyle cardStyle;

  /// La peau utilise-t-elle des images plein ecran ? (`true` pour Grand Air).
  /// Pilote l'eligibilite/activation de l'imagerie (L9). CCO §2.6.
  final bool usesImagery;

  /// Les valeurs data (altitude / GPS) sont-elles rendues en mono tabular ?
  /// `true` pour Topographique (cockpit instrument, CCO §3 peau B) ; lu par
  /// `AppDataStat` (L5/L8).
  final bool usesMonoData;

  /// Opacite du scrim (voile sombre) pose sous le texte sur fond image, pour
  /// garantir le contraste AA (CCO §1.6). Ignore si [usesImagery] est `false`
  /// (0.0 pour les peaux sans photo). Dimensionne en L9.
  final double scrimOpacity;

  @override
  SkinTheme copyWith({
    AppSkin? skin,
    // Sentinelle : distingue "non fourni" de "mis a null" pour un champ
    // nullable (titleFontFamily). Sans elle, copyWith ne pourrait jamais
    // remettre la famille a null (retour au defaut du theme).
    Object? titleFontFamily = _noArg,
    SkinHeaderStyle? headerStyle,
    SkinCardStyle? cardStyle,
    bool? usesImagery,
    bool? usesMonoData,
    double? scrimOpacity,
  }) {
    return SkinTheme(
      skin: skin ?? this.skin,
      titleFontFamily: identical(titleFontFamily, _noArg)
          ? this.titleFontFamily
          : titleFontFamily as String?,
      headerStyle: headerStyle ?? this.headerStyle,
      cardStyle: cardStyle ?? this.cardStyle,
      usesImagery: usesImagery ?? this.usesImagery,
      usesMonoData: usesMonoData ?? this.usesMonoData,
      scrimOpacity: scrimOpacity ?? this.scrimOpacity,
    );
  }

  /// Interpolation entre deux peaux (transitions de theme, `ThemeExtension`).
  ///
  /// Seuls les `double` s'interpolent reellement ([scrimOpacity]). Les champs
  /// discrets (peau, familles typo, enums, drapeaux) basculent au point milieu
  /// (`t < 0.5`) : une peau est un choix discret, il n'existe pas d'etat
  /// "a moitie topographique". C'est le comportement idiomatique pour des
  /// tokens non continus.
  @override
  SkinTheme lerp(covariant ThemeExtension<SkinTheme>? other, double t) {
    if (other is! SkinTheme) return this;
    return SkinTheme(
      skin: t < 0.5 ? skin : other.skin,
      titleFontFamily: t < 0.5 ? titleFontFamily : other.titleFontFamily,
      headerStyle: t < 0.5 ? headerStyle : other.headerStyle,
      cardStyle: t < 0.5 ? cardStyle : other.cardStyle,
      usesImagery: t < 0.5 ? usesImagery : other.usesImagery,
      usesMonoData: t < 0.5 ? usesMonoData : other.usesMonoData,
      scrimOpacity:
          lerpDouble(scrimOpacity, other.scrimOpacity, t) ?? scrimOpacity,
    );
  }

  /// Lit la peau active depuis le [context].
  ///
  /// Retourne l'extension `SkinTheme` du theme courant, avec repli sur
  /// [SentierVivantSkin] si aucune n'est injectee (robustesse : un widget lu
  /// hors d'un theme StepWays reste rendu sans crash, peau par defaut).
  static SkinTheme of(BuildContext context) {
    return Theme.of(context).extension<SkinTheme>() ?? SentierVivantSkin;
  }

  /// Resout la peau depuis un `enum AppSkin` (utilise par `buildLightTheme` /
  /// `buildDarkTheme` pour injecter la bonne extension).
  static SkinTheme fromSkin(AppSkin skin) {
    switch (skin) {
      case AppSkin.sentierVivant:
        return SentierVivantSkin;
      case AppSkin.topographique:
        return TopographiqueSkin;
      case AppSkin.grandAir:
        return GrandAirSkin;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SkinTheme &&
        other.skin == skin &&
        other.titleFontFamily == titleFontFamily &&
        other.headerStyle == headerStyle &&
        other.cardStyle == cardStyle &&
        other.usesImagery == usesImagery &&
        other.usesMonoData == usesMonoData &&
        other.scrimOpacity == scrimOpacity;
  }

  @override
  int get hashCode => Object.hash(
        skin,
        titleFontFamily,
        headerStyle,
        cardStyle,
        usesImagery,
        usesMonoData,
        scrimOpacity,
      );

  @override
  String toString() => 'SkinTheme(${skin.name})';
}

/// Sentinelle interne pour [SkinTheme.copyWith] (champ nullable non fourni).
const Object _noArg = Object();

// --- Instances const des 3 peaux (valeurs conformes CCO §3) ---

/// Peau A "Sentier Vivant" (defaut, sans photo) — CCO §3 peau A.
///
/// La couleur-sentier est le heros : en-tetes a degrade d'accent. Titres en
/// Space Grotesk (defaut du theme -> `titleFontFamily` null). Aucune image.
///
/// Nom en PascalCase (singleton nomme, facon token de theme) impose par le
/// mandat SW-SKIN-L2 et le CCO §3 -> on desactive `constant_identifier_names`.
// ignore: constant_identifier_names
const SkinTheme SentierVivantSkin = SkinTheme(
  skin: AppSkin.sentierVivant,
  titleFontFamily: null,
  headerStyle: SkinHeaderStyle.gradient,
  cardStyle: SkinCardStyle.elevatedSoft,
  usesImagery: false,
  usesMonoData: false,
  scrimOpacity: 0.0,
);

/// Peau B "Topographique" (instrument, sans photo) — CCO §3 peau B.
///
/// En-tetes a filet de lignes de niveau (pas de degrade), cartes bord fin
/// "instrument", valeurs GPS/altitude en mono tabular. `titleFontFamily` null
/// ici (L2) : le choix precis (grotesque neutre / mono) est affine en L8.
// ignore: constant_identifier_names
const SkinTheme TopographiqueSkin = SkinTheme(
  skin: AppSkin.topographique,
  titleFontFamily: null,
  headerStyle: SkinHeaderStyle.topoFilet,
  cardStyle: SkinCardStyle.thinInstrument,
  usesImagery: false,
  usesMonoData: true,
  scrimOpacity: 0.0,
);

/// Peau C "Grand Air" (photo plein ecran, premium) — CCO §3 peau C.
///
/// Photo + scrim garantissant le contraste (§1.6). Seule peau qui surcharge la
/// famille de titres (serif editoriale "Fraunces", cf. CCO §3 peau C ; le
/// cablage google_fonts effectif arrive en L9). `scrimOpacity` a une valeur de
/// depart raisonnable, dimensionnee finement en L9.
// ignore: constant_identifier_names
const SkinTheme GrandAirSkin = SkinTheme(
  skin: AppSkin.grandAir,
  titleFontFamily: 'Fraunces',
  headerStyle: SkinHeaderStyle.photo,
  cardStyle: SkinCardStyle.photo,
  usesImagery: true,
  usesMonoData: false,
  scrimOpacity: 0.45,
);
