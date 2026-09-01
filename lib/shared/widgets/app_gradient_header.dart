import 'package:flutter/material.dart';

import '../../core/a11y/wcag_contrast.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/skin_theme.dart';

/// En-tete de marque a fond derive de la peau active (SW-SKIN-L5).
///
/// Rend un bandeau dont le FOND depend de `SkinTheme.of(context).headerStyle`
/// (CCO §1.3 / §3) :
///  - [SkinHeaderStyle.gradient]  : `LinearGradient` derive de l'accent-sentier
///    (`colorScheme.primary` -> `AppTheme.lighten(primary)`) — peau A "Sentier
///    Vivant". La couleur-sentier est le heros graphique.
///  - [SkinHeaderStyle.topoFilet] : surface papier + filet discret, SANS degrade
///    — amorce sobre de la peau B "Topographique" (affinee en L8, texture lignes
///    de niveau). Garde volontairement minimaliste ici.
///  - [SkinHeaderStyle.photo]     : reserve peau C "Grand Air" (L9). Tant qu'aucune
///    image n'est fournie, FALLBACK sur le degrade — jamais de trou.
///
/// Le titre est rendu dans le style titre du theme (Space Grotesk via L1) ; une
/// peau peut surcharger la famille (`SkinTheme.titleFontFamily`, ex. serif Grand
/// Air) — pris en compte ici.
///
/// GARANTIE DE CONTRASTE (CCO §1.6) : la couleur du texte (blanc ou encre) est
/// choisie selon la luminance du fond via [WcagContrast] (logique existante, non
/// reinventee). Si l'accent-sentier est trop clair pour tenir l'AA en blanc, le
/// degrade est ASSOMBRI (`AppTheme.darken`, meme calcul que le theme) jusqu'a
/// repasser le seuil — le degrade reste decoratif et derive de l'accent, jamais
/// illisible. Voir [resolveHeaderTextTreatment] (teste unitairement).
class AppGradientHeader extends StatelessWidget {
  const AppGradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.child,
    this.padding,
  });

  /// Titre principal (ex. nom d'etape, salutation). Rendu en style titre du
  /// theme, famille eventuellement surchargee par la peau.
  final String title;

  /// Sous-titre optionnel (ex. nom du sentier, "Etape 4"). Meme famille, plus
  /// discret.
  final String? subtitle;

  /// Widget optionnel aligne a droite du titre (ex. badge, action).
  final Widget? trailing;

  /// Contenu optionnel rendu SOUS le bloc titre, a l'interieur du bandeau (ex.
  /// une rangee d'`AppDataStat`). Herite du meme traitement de contraste.
  final Widget? child;

  /// Marge interne. Defaut : confortable (base horizontal, large vertical).
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skin = SkinTheme.of(context);
    final scheme = theme.colorScheme;

    final treatment = resolveHeaderTextTreatment(
      headerStyle: skin.headerStyle,
      primary: scheme.primary,
      // Sur fond papier (topoFilet), le texte se pose sur la surface, pas sur
      // l'accent : on passe la surface comme base pour choisir encre/blanc.
      paperSurface: scheme.surface,
    );

    final effectivePadding = padding ??
        const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingBase,
          vertical: AppTheme.spacingLg,
        );

    // Style titre : titleLarge du theme (Space Grotesk L1), recolorise pour le
    // contraste et famille surchargee par la peau si demande (ex. serif Grand
    // Air, cablage google_fonts en L9 ; ici on respecte titleFontFamily s'il est
    // deja fourni).
    final titleStyle = (theme.textTheme.headlineSmall ??
            const TextStyle(fontSize: 22, fontWeight: FontWeight.w700))
        .copyWith(
      color: treatment.textColor,
      fontFamily: skin.titleFontFamily,
    );
    final subtitleStyle = (theme.textTheme.titleMedium ??
            const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))
        .copyWith(
      color: treatment.textColor.withValues(alpha: 0.92),
      fontFamily: skin.titleFontFamily,
    );

    final Widget header = DecoratedBox(
      decoration: BoxDecoration(
        color: treatment.solidBackground,
        gradient: treatment.gradient,
      ),
      child: Padding(
        padding: effectivePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: titleStyle),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.spacingXs),
                        Text(subtitle!, style: subtitleStyle),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppTheme.spacingSm),
                  trailing!,
                ],
              ],
            ),
            if (child != null) ...[
              const SizedBox(height: AppTheme.spacingBase),
              // Le contenu (ex. rangee d'AppDataStat) herite de la couleur de
              // texte garantie contrastee via un DefaultTextStyle/IconTheme.
              DefaultTextStyle.merge(
                style: TextStyle(color: treatment.textColor),
                child: IconTheme.merge(
                  data: IconThemeData(color: treatment.textColor),
                  child: child!,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    // Filet topo : sur la peau B, on pose un liseré bas discret (amorce du motif
    // lignes de niveau, affine en L8). Aucun effet sur les autres peaux.
    if (skin.headerStyle == SkinHeaderStyle.topoFilet) {
      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: scheme.outline.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
        ),
        child: header,
      );
    }

    return header;
  }
}

/// Resultat du calcul de traitement visuel d'un en-tete (SW-SKIN-L5).
///
/// Porte le fond a peindre (degrade OU couleur pleine, exclusifs) et la couleur
/// de texte GARANTIE contrastee (>= AA) sur ce fond.
@immutable
class HeaderTextTreatment {
  const HeaderTextTreatment({
    required this.textColor,
    this.gradient,
    this.solidBackground,
  });

  /// Couleur de texte lisible (>= AA) sur le fond calcule.
  final Color textColor;

  /// Degrade a peindre (mode gradient / photo-fallback). `null` en mode papier.
  final Gradient? gradient;

  /// Couleur de fond pleine (mode papier). `null` en mode degrade.
  final Color? solidBackground;
}

/// Encre foncee de repli pour le texte d'en-tete quand le fond est clair.
const Color _headerInk = AppTheme.noir;

/// Calcule le fond et la couleur de texte d'un en-tete en GARANTISSANT le
/// contraste AA (CCO §1.6). Fonction pure -> testable sans widget.
///
/// - Mode papier ([SkinHeaderStyle.topoFilet]) : fond = [paperSurface], texte =
///   encre ou blanc selon ce qui contraste (papier clair -> encre).
/// - Mode degrade / photo-fallback : degrade `primary -> lighten(primary)`.
///   * si le BLANC tient l'AA sur les DEUX extremites -> texte blanc, degrade
///     tel quel (cas nominal des accents soutenus) ;
///   * sinon (accent trop clair) on ASSOMBRIT progressivement les deux extremites
///     (meme calcul que le theme, [AppTheme.darken]) jusqu'a ce que le blanc
///     repasse l'AA sur l'extremite claire (la plus exigeante pour du blanc) ;
///   * repli ultime : si meme tres assombri le blanc echoue mais que l'encre
///     tient, on bascule sur l'encre (jamais de texte illisible).
HeaderTextTreatment resolveHeaderTextTreatment({
  required SkinHeaderStyle headerStyle,
  required Color primary,
  required Color paperSurface,
}) {
  // --- Mode papier (peau Topographique) : pas de degrade ---
  if (headerStyle == SkinHeaderStyle.topoFilet) {
    final onPaper = WcagContrast.meetsAA(_headerInk, paperSurface)
        ? _headerInk
        : Colors.white;
    return HeaderTextTreatment(
      textColor: onPaper,
      solidBackground: paperSurface,
    );
  }

  // --- Mode degrade (peau A) et fallback du mode photo (peau C sans image) ---
  Color c1 = primary;
  Color c2 = AppTheme.lighten(primary, 0.18);

  // Le blanc est le plus exigeant sur l'extremite CLAIRE du degrade (c2).
  bool whiteOk() =>
      WcagContrast.meetsAA(Colors.white, c1) &&
      WcagContrast.meetsAA(Colors.white, c2);

  if (!whiteOk()) {
    // Assombrit les deux extremites par paliers (0.05) jusqu'a repasser l'AA en
    // blanc. La luminance tend vers 0 quand on assombrit -> le blanc finit
    // TOUJOURS par passer ; le plafond (0.85) borne juste le nombre d'iterations
    // (accents tres satures type jaune vif = les plus tenaces). Le degrade reste
    // derive de l'accent, simplement assombri (garde-fou §1.6).
    var applied = 0.0;
    while (!whiteOk() && applied < 0.85) {
      applied += 0.05;
      c1 = AppTheme.darken(primary, applied);
      c2 = AppTheme.darken(AppTheme.lighten(primary, 0.18), applied);
    }
  }

  // Repli ultime : accent extreme ou l'assombrissement ne suffit pas cote blanc
  // mais l'encre tient sur les deux extremites -> encre.
  final Color textColor;
  if (whiteOk()) {
    textColor = Colors.white;
  } else if (WcagContrast.meetsAA(_headerInk, c1) &&
      WcagContrast.meetsAA(_headerInk, c2)) {
    textColor = _headerInk;
  } else {
    // Cas theorique (aucune des deux couleurs ne tient) : on garde le meilleur
    // ratio pour minimiser le prejudice de lisibilite.
    final whiteRatio = WcagContrast.ratio(Colors.white, c2);
    final inkRatio = WcagContrast.ratio(_headerInk, c2);
    textColor = whiteRatio >= inkRatio ? Colors.white : _headerInk;
  }

  return HeaderTextTreatment(
    textColor: textColor,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [c1, c2],
    ),
  );
}
