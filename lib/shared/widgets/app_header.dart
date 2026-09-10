import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/home_location_provider.dart';
import '../../i18n/translations.g.dart';

/// En-tete universel de navigation StepWays (LOT 3 — refonte nav hub-and-push).
///
/// Barre du HAUT commune : [Retour] (leading) + titre + [Accueil] (action). Elle
/// remplace, ecran par ecran, l'`AppBar` maison de chaque page (jamais les deux
/// — garde-fou G5 : un seul en-tete).
///
/// GARDE-FOU LOOK & FEEL (AUDIT §4-G1) : cet en-tete est une `AppBar` STANDARD.
/// Il HERITE integralement de l'`AppBarTheme` centralise (`app_theme.dart` :
/// fond `primaryColor`, texte blanc, elevation 4, `centerTitle: true`) — AUCUN
/// style « maison » n'est reinvente. Seul le CONTENU change (leading = Retour,
/// action = Accueil, titre) ; l'apparence reste identique a ce que chaque ecran
/// affiche aujourd'hui.
///
/// GARDE-FOU G2 : cet en-tete N'EST PAS la banniere de marque `AppGradientHeader`
/// (bloc decoratif dans le corps). Les deux COEXISTENT : `AppHeader` en barre
/// systeme, `AppGradientHeader` dans le scroll. On ne fusionne jamais l'un dans
/// l'autre.
///
/// BACK ANDROID CENTRALISE (AUDIT §M-3, principes Android/predictive-back) :
///  - hors racine (`context.canPop()` vrai) : Retour = `pop()` — le bouton
///    systeme Android suit le meme chemin (`canPop: true` -> le `Navigator`
///    depile normalement, animation predictive Android 14+ preservee) ;
///  - a la RACINE (pile vide, `canPop()` faux) : Retour et le geste systeme
///    demandent une CONFIRMATION de sortie (« appuyez pour quitter ») via
///    `PopScope(canPop: false)` + `onPopInvokedWithResult` — jamais de sortie
///    silencieuse (fixed start destination). Le bouton [Accueil], lui, ne quitte
///    JAMAIS l'app : il route vers l'accueil ([homeLocation]).
///
/// ACCUEIL CONTEXTUEL (StepWays LOT 3, Ph3) : quand [homeLocation] n'est PAS
/// fourni, le bouton Accueil (et le fallback retour hors pile) dérive sa cible de
/// [homeLocationProvider] (maison `/my-treks` si aucune rando active / terrain
/// `/home` si rando active). Un appelant peut toujours forcer une cible explicite
/// via [homeLocation] (ex. écran qui doit revenir à un accueil précis).
///
/// Zero texte en dur : tooltips et libelles via Slang (`t.nav.*`, `t.navPilote.*`).
class AppHeader extends ConsumerWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.showBack = true,
    this.showHome = true,
    this.onBack,
    this.actions,
    this.homeLocation,
    this.bottom,
  });

  /// Titre de l'ecran (libelle Slang cote appelant — jamais de texte en dur).
  final String title;

  /// Affiche le bouton [Retour] (leading). Defaut true.
  final bool showBack;

  /// Affiche le bouton [Accueil] (action de droite). Defaut true.
  final bool showHome;

  /// Surcharge optionnelle du geste retour (sinon `pop()` / `go(home)`).
  final VoidCallback? onBack;

  /// Actions additionnelles a droite (AVANT le bouton Accueil). Optionnel.
  final List<Widget>? actions;

  /// Destination EXPLICITE du bouton [Accueil] et du fallback retour hors pile.
  ///
  /// `null` (défaut) → dérivée de [homeLocationProvider] (accueil CONTEXTUEL
  /// maison/terrain, Ph3). Non-null → cible forcée par l'appelant.
  final String? homeLocation;

  /// Zone optionnelle sous la barre (ex. TabBar). Passee telle quelle a l'AppBar.
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  /// Geste retour : pop si possible, sinon route vers l'accueil ([home] résolu).
  void _handleBack(BuildContext context, String home) {
    if (onBack != null) {
      onBack!();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(home);
    }
  }

  /// Confirmation de sortie a la racine (fixed start destination, AUDIT §M-3).
  ///
  /// Retourne true si l'utilisateur confirme vouloir quitter. Sur confirmation,
  /// on rend la main au systeme (`SystemNavigator.pop`) — jamais de sortie
  /// silencieuse.
  Future<bool> _confirmExit(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.navPilote.exitTitle),
        content: Text(t.navPilote.exitMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.navPilote.exitCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.navPilote.exitConfirm),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Accueil CONTEXTUEL (Ph3) : cible explicite si fournie, sinon dérivée du
    // sélecteur maison/terrain ([homeLocationProvider]).
    final String home = homeLocation ?? ref.watch(homeLocationProvider);

    // A la racine (pile vide) le geste systeme ne doit PAS quitter en silence :
    // canPop=false -> on intercepte et on demande confirmation. Hors racine,
    // canPop=true -> le Navigator depile normalement (predictive back preserve).
    final atRoot = !context.canPop();

    final appBar = AppBar(
      // Style 100 % herite de l'AppBarTheme (G1) : aucune couleur/elevation ici.
      title: Text(title),
      // Leading Retour : icone plateforme par defaut, geste centralise.
      leading: showBack
          ? IconButton(
              icon: const BackButtonIcon(),
              tooltip: t.nav.back,
              onPressed: () => _handleBack(context, home),
            )
          : null,
      // automaticallyImplyLeading=false quand on ne veut pas de retour (racine
      // sans bouton) pour eviter un leading Material implicite non centralise.
      automaticallyImplyLeading: false,
      actions: [
        if (actions != null) ...actions!,
        if (showHome)
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: t.nav.home,
            // Le bouton Accueil ne QUITTE JAMAIS l'app (Up-like, AUDIT §M-3).
            onPressed: () => context.go(home),
          ),
      ],
      bottom: bottom,
    );

    return PopScope<Object?>(
      // canPop=true hors racine -> laisse le Navigator depiler (retour normal,
      // animation predictive Android 14+). canPop=false a la racine -> on garde
      // la main pour confirmer la sortie.
      canPop: !atRoot,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // deja depile (hors racine) : rien a faire.
        // Racine : le systeme a tente de sortir -> confirmation explicite.
        final shouldExit = await _confirmExit(context);
        if (shouldExit) {
          await SystemNavigator.pop();
        }
      },
      child: appBar,
    );
  }
}
