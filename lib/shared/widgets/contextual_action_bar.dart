/// Rendu de la barre d'ACTIONS du bas — pas des onglets — avec l'action
/// saillante (le SOS) en pastille pleine pour qu'elle ne se noie jamais.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/branding/stepways_icons.dart';
import 'texte_ajuste.dart';

/// PLANCHER DE LISIBILITE D'UN LIBELLE D'ONGLET (tache 749).
///
/// [TexteAjuste] descend jusqu'a cette taille pour faire tenir un libelle
/// ENTIER plutot que de le couper. 11 px et non les 13 px par defaut du widget
/// : une barre du bas est plus etroite qu'une tuile de cockpit (trois onglets
/// se partagent la largeur du telephone), et un libelle complet a 11 px rend
/// plus service qu'un libelle ampute a 13.
const double _tailleMinLibelle = 11;

/// Une action de la [ContextualActionBar] (barre d'ACTIONS, pas d'onglets).
///
/// [salient] = action mise en avant (ex. SOS) : rendue en pastille pleine
/// accentuee ([color], defaut `AppTheme.emergencyRed` cote SOS) pour ne JAMAIS
/// se noyer parmi les autres (AUDIT §M-2, enjeu securite).
@immutable
class ContextualAction {
  const ContextualAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.salient = false,
    this.color,
    this.semanticLabel,
  });

  final String icon;
  final String label;
  final VoidCallback onPressed;

  /// Action saillante (accentuee, pleine) — ex. SOS. Defaut false.
  final bool salient;

  /// Couleur de l'accent quand [salient] (defaut `AppTheme.emergencyRed`).
  final Color? color;

  /// Label semantique explicite (a11y) si le [label] visuel ne suffit pas.
  final String? semanticLabel;
}

/// Barre d'ACTIONS contextuelle StepWays (LOT 3 — refonte nav).
///
/// GARDE-FOU CARDINAL (AUDIT §2 / §3 / §4-G4, §M-1) : ce composant porte des
/// ACTIONS de l'ecran courant, PAS des destinations. Ce n'est donc PAS une
/// `NavigationBar` d'onglets : on la construit en `BottomAppBar` (barre
/// d'actions Material), VISUELLEMENT DISTINCTE d'une barre d'onglets, pour
/// eviter la dissonance HIG (« tab bar buttons should not perform actions ») et
/// le malentendu « les onglets sont revenus ». Les items ne sont PAS des
/// destinations egales : ils s'affichent en boutons d'action (icone + label),
/// et l'action saillante ([ContextualAction.salient], ex. SOS) est accentuee.
///
/// LOOK & FEEL : styles derives du THEME (surface de la `BottomAppBar`,
/// `colorScheme` pour les libelles, tokens `AppTheme` pour l'espacement). Aucun
/// token de design redefini (G3). Coherent sur tous les ecrans (un composant
/// unique, G4).
///
/// SOS (AUDIT §M-2) : passe une [ContextualAction] `salient` avec l'icone
/// urgence et `AppTheme.emergencyRed` — la barre le rend en pastille pleine
/// accentuee, jamais un item de nav parmi d'autres.
class ContextualActionBar extends StatelessWidget {
  const ContextualActionBar({super.key, required this.actions});

  /// Actions a afficher (max 3-4 recommande, AUDIT §3). Barre absente si vide.
  final List<ContextualAction> actions;

  /// HAUTEUR DE LA BARRE, CALCULEE SUR LE TEXTE QU'ELLE PORTE (tache 749).
  ///
  /// POURQUOI CE N'EST PLUS LA HAUTEUR PAR DEFAUT. Une `BottomAppBar` mesure
  /// 80 px et son enfant vit dans cette boite : icone 22 + espace 4 + UNE ligne
  /// de libelle + marges, et c'est plein. Un libelle de deux lignes y
  /// debordait, donc le libelle etait coupe a une ligne — « Découvrir de… », le
  /// premier onglet de la barre du bas, releve a l'ecran par Christophe le
  /// 09/10.
  ///
  /// LA REGLE DU LOT VEUT QUE LE CONTENANT GRANDISSE, et c'est ce qu'il fait :
  /// la barre reserve de quoi ecrire [_lignesDeLibelle] lignes de libelle, a
  /// l'echelle de texte CHOISIE PAR LE RANDONNEUR (`textScalerOf`) — celui qui
  /// a grossi les textes de son telephone obtient une barre plus haute, pas un
  /// libelle rogne.
  /// [avecActionSaillante] : le SOS est rendu en pastille pleine, donc dans un
  /// `Padding` de plus que les boutons discrets. La barre doit tenir compte du
  /// PLUS HAUT de ses enfants, sans quoi la pastille rallumerait par le bas le
  /// debordement que ce lot ferme par le haut.
  static double hauteurPour(
    BuildContext context, {
    bool avecActionSaillante = false,
  }) {
    final theme = Theme.of(context);
    final styleLibelle = theme.textTheme.labelLarge;
    final tailleLibelle = styleLibelle?.fontSize ?? 14;
    // Interligne reel du style quand il en porte un, sinon l'interligne usuel
    // d'un libelle Material (~1.43 pour labelLarge).
    final interligne = styleLibelle?.height ?? 1.43;
    final hauteurDeLigne = MediaQuery.textScalerOf(
      context,
    ).scale(tailleLibelle * interligne);
    return _hauteurIcone +
        AppTheme.spacingXs +
        hauteurDeLigne * _lignesDeLibelle +
        AppTheme.spacingSm * 2 +
        (avecActionSaillante ? AppTheme.spacingXs * 2 : 0) +
        // Un point de garde pour l'arrondi au pixel du peintre de texte : un
        // demi-pixel de retard suffirait a rallumer un debordement.
        _margeDArrondi;
  }

  /// Taille de l'icone d'un bouton d'action (voir [StepIcon] ci-dessous).
  static const double _hauteurIcone = 22;

  /// Un libelle d'onglet a droit a DEUX lignes. Au-dela, [TexteAjuste]
  /// rapetisse la police plutot que de couper : c'est le cas particulier
  /// documente du lot 749 (la barre du bas n'a pas la hauteur d'un paragraphe).
  static const int _lignesDeLibelle = 2;

  static const double _margeDArrondi = 2;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return BottomAppBar(
      // Style herite du BottomAppBarTheme / surface du theme (aucune couleur en
      // dur). La BottomAppBar est visuellement distincte d'une NavigationBar
      // (barre d'actions, pas d'onglets) — garde-fou G4.
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm),
      height: hauteurPour(
        context,
        avecActionSaillante: actions.any((a) => a.salient),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final action in actions)
            Expanded(child: _ActionButton(action: action)),
        ],
      ),
    );
  }
}

/// Bouton d'action interne : rendu accentue si [ContextualAction.salient],
/// sinon rendu discret (icone + label sur la surface de la barre).
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action});

  final ContextualAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (action.salient) {
      // Action saillante (SOS) : pastille pleine accentuee — impossible a
      // confondre avec un item de nav (AUDIT §M-2).
      final accent = action.color ?? AppTheme.emergencyRed;
      return Semantics(
        button: true,
        label: action.semanticLabel ?? action.label,
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
          child: Material(
            color: accent,
            borderRadius: BorderRadius.circular(AppTheme.radiusButton),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusButton),
              onTap: action.onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingSm,
                  horizontal: AppTheme.spacingXs,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  // Icone CENTREE horizontalement au-dessus du label (retour
                  // Chris 09/09) — explicite pour ne pas dependre du defaut.
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    StepIcon(
                      action.icon,
                      color: Colors.white,
                      size: ContextualActionBar._hauteurIcone,
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    // Libelle ENTIER — meme regle que le bouton discret
                    // ci-dessous, ou elle est expliquee en detail.
                    TexteAjuste(
                      action.label,
                      textAlign: TextAlign.center,
                      maxLines: ContextualActionBar._lignesDeLibelle,
                      tailleMin: _tailleMinLibelle,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Action standard : bouton discret (icone + label) sur la surface.
    return Semantics(
      button: true,
      label: action.semanticLabel ?? action.label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        onTap: action.onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppTheme.spacingSm,
            horizontal: AppTheme.spacingXs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            // Icone CENTREE horizontalement au-dessus du label (retour Chris
            // 09/09) — explicite pour ne pas dependre du defaut du Column.
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              StepIcon(
                action.icon,
                color: scheme.onSurface,
                size: ContextualActionBar._hauteurIcone,
              ),
              const SizedBox(height: AppTheme.spacingXs),
              // LE LIBELLE D'ONGLET EST LE CAS PARTICULIER DU LOT 749.
              //
              // Il disait `maxLines: 1` + ellipsis, et c'est ce qui a donne
              // « Découvrir de… » au premier onglet de la barre du bas (releve
              // de Christophe du 09/10). Un onglet n'a pas la place d'un
              // paragraphe : trois onglets se partagent la largeur d'un
              // telephone, soit une centaine de pixels chacun. On ne peut donc
              // pas simplement « laisser passer a la ligne » sans borne.
              //
              // CE QU'ON FAIT A LA PLACE, et pourquoi ca respecte la regle :
              // deux lignes sont accordees (la barre a ete rehaussee pour les
              // accueillir, voir [ContextualActionBar.hauteurPour]), et si
              // deux lignes ne suffisent toujours pas — un libelle allemand,
              // un randonneur qui a grossi ses textes — [TexteAjuste] REDUIT
              // LA POLICE jusqu'a ce que le libelle tienne ENTIER, au lieu de
              // le couper. Le texte reste lisible et complet : c'est un
              // rapetissement, pas une troncature.
              TexteAjuste(
                action.label,
                textAlign: TextAlign.center,
                maxLines: ContextualActionBar._lignesDeLibelle,
                tailleMin: _tailleMinLibelle,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
