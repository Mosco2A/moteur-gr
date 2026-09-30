import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// LES DEUX LANGAGES VISUELS DE L'APPLICATION (tache 639, bug 4 du 30/09).
///
/// LE RETOUR DE CHRISTOPHE, MOT POUR MOT (30/09 10:10, telephone, build 0.1.3
/// (7)) : « pret a partir on ne dirait pas une info mais un bouton, il faut
/// differencier visuellement ce qui est clicable de ce qui ne l est pas ».
///
/// CE QUI ETAIT MESURE AVANT DE CHANGER QUOI QUE CE SOIT. `AppCard` est la
/// brique de fond de tous les ecrans : 124 appels dans `lib/`. Elle se dessinait
/// EXACTEMENT PAREIL qu'elle porte un geste ou non — meme fond plein
/// (`surfaceContainerHighest`), meme ombre portee (`elevation: 2`), meme rayon.
/// Sur les 124, SEIZE portent un geste (huit par `onTap`, huit par un
/// `InkWell`/`ListTile` pose juste dessous) et CENT HUIT n'en portent AUCUN.
/// Autrement dit : cent huit blocs d'information de l'application avaient le
/// relief d'un bouton. « Pret a partir » etait l'un d'eux, et il n'y avait rien
/// a corriger localement — c'etait la brique.
///
/// LA REGLE, DESORMAIS PORTEE PAR LA BRIQUE ET PAR ELLE SEULE :
///
///   CLIQUABLE — la carte porte un geste. Elle est EN RELIEF : fond plein
///     (`surfaceContainerHighest`), ombre portee, encre au toucher. Meme
///     grammaire que l'[AppButton] : ce qui repond a l'appui se souleve.
///   INFORMATION — la carte ne porte aucun geste (etat, mesure, indicateur,
///     explication). Elle est A PLAT : aucune ombre, fond au niveau de l'ecran
///     (`surface`), et un liseré discret pour la delimiter. Elle se lit, elle ne
///     s'appuie pas.
///
/// L'AVEUGLEMENT QU'IL FALLAIT LEVER. Le relief se decidait avant que les
/// enfants de la carte n'existent : une carte dont le geste est pose PAR
/// L'APPELANT, a l'interieur (`InkWell`, `ListTile`), ne pouvait pas etre
/// devinee. D'ou [interactif] : ces huit appels le declarent, une fois, et la
/// regle vaut alors pour eux aussi. Passer le geste par [onTap] est la voie
/// normale et ne demande rien.
///
/// CE QUI RESTE A LA MAIN DE L'APPELANT, et pourquoi : une couleur de fond ou de
/// liseré SEMANTIQUE (alerte orage en rouge, carte de refuge en vert) gagne
/// toujours — c'est un sens, pas un style. Une [elevation] donnee explicitement
/// gagne aussi : la bulle flottante d'un point d'interet sur la carte a besoin
/// de son ombre pour se detacher du fond cartographique, qu'elle soit cliquable
/// ou non.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.elevation,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.interactif,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  /// Ombre portee. Laissee a null (le cas normal), elle suit la REGLE : 2 pour
  /// une carte cliquable, 0 pour une information. Une valeur explicite gagne —
  /// reservee aux cartes qui FLOTTENT au-dessus d'un autre contenu.
  final double? elevation;

  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;

  /// Epaisseur du liseré quand [borderColor] est fourni (defaut 1.0). Permet de
  /// conserver un contour semantique existant a l'identique — ex. la carte de
  /// prevision en etat alerte, liseré rouge 1.5px (SW-SKIN-L3b) — sans recourir
  /// a un parametre jetable. Sans effet si [borderColor] est null.
  final double? borderWidth;

  /// LA CARTE PORTE UN GESTE, MAIS PAS PAR [onTap] (tache 639).
  ///
  /// A passer a `true` quand c'est l'appelant qui pose le geste a l'interieur —
  /// un `InkWell` ou un `ListTile` enfant, parce qu'il a besoin de sa propre
  /// cle, de son propre `borderRadius` ou de sa propre structure. Sans cette
  /// declaration la carte serait dessinee comme une information alors qu'elle
  /// repond a l'appui : exactement la faute inverse de celle de Christophe.
  ///
  /// Laisse a null, l'etat se derive de [onTap] — le cas normal.
  final bool? interactif;

  /// Vrai quand cette carte repond a l'appui, donc quand elle doit etre dessinee
  /// EN RELIEF. Source unique de la regle.
  bool get cliquable => interactif ?? (onTap != null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final effectiveRadius =
        borderRadius ?? BorderRadius.circular(AppTheme.radiusCard);

    // LA REGLE, APPLIQUEE ICI ET NULLE PART AILLEURS.
    final effectiveElevation = elevation ?? (cliquable ? 2.0 : 0.0);
    final effectiveBg =
        backgroundColor ??
        (cliquable ? scheme.surfaceContainerHighest : scheme.surface);
    // Le liseré de l'information la DELIMITE sans la soulever. Discret (40 %
    // du contour du theme) : il doit se voir, pas encadrer.
    final effectiveBorder =
        borderColor ??
        (cliquable ? null : scheme.outline.withValues(alpha: 0.4));

    // LE LISERE NE DOIT PAS DEPLACER LA MISE EN PAGE (mesure, tache 639).
    //
    // Un `Border` ordinaire compte dans le calcul de taille : `BoxDecoration`
    // renvoie l'epaisseur du trait en `padding`, et le contenu se decale d'un
    // point de chaque cote. Sur 108 cartes d'information, ce point-la s'ajoute :
    // le test de la selection de sentier est tombe IMMEDIATEMENT, parce que sa
    // fenetre par defaut (800x600) ne construisait plus la derniere carte de la
    // liste — deux points de trop par carte l'avaient poussee hors champ.
    // `strokeAlignOutside` peint le trait A L'EXTERIEUR de la boite : les
    // dimensions du liseré valent alors zero, et la mise en page est RIGOUREUSEMENT
    // celle d'avant. Un liseré SEMANTIQUE demande par l'appelant garde, lui, son
    // alignement par defaut : il existait avant et son rendu ne doit pas bouger.
    final bordureAlignee = borderColor == null && effectiveBorder != null;

    // Le contenu est enveloppe dans un Material transparent : comme la `Card`
    // Material (qu'AppCard remplace, SW-SKIN-L3), cela fournit l'ancetre
    // Material requis par les widgets a encre (ListTile, InkWell, Switch...) et
    // borne les splashs au rayon de la carte. Transparent + meme rayon => aucun
    // changement visuel pour les appelants existants (le fond/ombre restent
    // peints par le Container ci-dessous) ; on ne fait qu'ajouter le support
    // d'encre qui manquait, evitant "No Material widget found" hors Scaffold.
    final Widget inner = Material(
      type: MaterialType.transparency,
      borderRadius: effectiveRadius,
      clipBehavior: Clip.antiAlias,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: effectiveRadius,
              child: Padding(
                padding: padding ?? const EdgeInsets.all(AppTheme.spacingBase),
                child: child,
              ),
            )
          : Padding(
              padding: padding ?? const EdgeInsets.all(AppTheme.spacingBase),
              child: child,
            ),
    );

    final cardContent = Container(
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: effectiveRadius,
        border: effectiveBorder != null
            ? Border.all(
                color: effectiveBorder,
                width: borderWidth ?? 1.0,
                strokeAlign: bordureAlignee
                    ? BorderSide.strokeAlignOutside
                    : BorderSide.strokeAlignInside,
              )
            : null,
        boxShadow: effectiveElevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha(
                    (effectiveElevation * 15).round(),
                  ),
                  blurRadius: effectiveElevation * 2,
                  offset: Offset(0, effectiveElevation),
                ),
              ]
            : null,
      ),
      child: inner,
    );

    return Padding(padding: margin ?? EdgeInsets.zero, child: cardContent);
  }
}
