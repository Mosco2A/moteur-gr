import 'package:flutter/material.dart';

import '../../i18n/translations.g.dart';
import '../../shared/widgets/app_button.dart';

/// Widget generique pour afficher une erreur avec bouton retry.
///
/// Utilise dans toute l'app pour un affichage homogene des erreurs.
/// Affiche un message utilisateur lisible et un bouton de relance.
///
/// LE BOUTON DE RELANCE NE MONTRAIT RIEN (tache 579, LOT X). Il appelait bien
/// son `onRetry` — typiquement `ref.invalidate(...)` — le provider repartait,
/// echouait a l'identique, et l'ecran se repeignait EXACTEMENT pareil : meme
/// icone, meme phrase, meme bouton. L'utilisateur appuyait, regardait, et
/// concluait que l'application etait cassee. Il avait raison de le croire : la
/// relance etait invisible, et c'est le meme defaut que « Parcourir le
/// catalogue » qui naviguait vraiment pour revenir aussitot.
///
/// Ce que l'appui produit maintenant, dans l'ordre et sans exception :
///   1. le bouton devient « Nouvel essai… » avec un indicateur qui tourne —
///      l'appui est PRIS EN COMPTE A L'ECRAN, des le premier battement ;
///   2. `onRetry` part ;
///   3. si, une seconde plus tard, cette vue est TOUJOURS LA, c'est que le
///      nouvel essai a echoue lui aussi — et on le DIT par un message. Si elle a
///      disparu, c'est que la donnee est arrivee : il n'y a rien a annoncer.
///
/// Le point 3 est la seule information fiable dont dispose ce widget : il ne
/// connait pas l'operation qu'il relance, mais il sait s'il a survecu.
class ErrorView extends StatefulWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  /// Message d'erreur affiche a l'utilisateur.
  final String message;

  /// Callback de relance. Si null, le bouton retry n'est pas affiche.
  final VoidCallback? onRetry;

  @override
  State<ErrorView> createState() => _ErrorViewState();
}

class _ErrorViewState extends State<ErrorView> {
  /// Duree pendant laquelle l'essai est annonce a l'ecran.
  ///
  /// Assez long pour etre vu, assez court pour ne pas bloquer un ecran qui
  /// reussit : si la donnee arrive avant, cette vue est demontee et le minuteur
  /// meurt avec elle (`mounted` garde l'appel).
  static const Duration _dureeEssai = Duration(milliseconds: 900);

  bool _essaiEnCours = false;

  Future<void> _relancer() async {
    if (_essaiEnCours) return;
    setState(() => _essaiEnCours = true);
    widget.onRetry?.call();
    await Future<void>.delayed(_dureeEssai);
    if (!mounted) return; // La donnee est arrivee : cette vue n'existe plus.
    setState(() => _essaiEnCours = false);
    // Toujours la, donc toujours en erreur : on ne laisse pas l'utilisateur
    // deviner que son appui a bien ete pris et que c'est l'essai qui a rate.
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(content: Text(t.common.retryFailed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: 24),
              // SW-SKIN-L3e : FilledButton.icon -> AppButton primary (arbitrage
              // #A5). isFullWidth:false : FilledButton n'est pas force pleine
              // largeur par le theme, il restait dimensionne au contenu et
              // centre dans la Column (iso-rendu).
              //
              // LE LIBELLE PASSE PAR SLANG (tache 579). Il etait ecrit en dur,
              // en francais, dans un widget utilise par TOUTE l'application :
              // un utilisateur allemand lisait « Reessayer » — sans accent de
              // surcroit — au milieu d'un ecran allemand.
              //
              // ON GARDE LE TEXTE PENDANT L'ESSAI, on ne le remplace pas par un
              // sablier muet : « Nouvel essai… » dit ce qui se passe, un
              // indicateur seul ne dit que « attends ».
              AppButton(
                isFullWidth: false,
                icon: Icons.refresh,
                label: _essaiEnCours ? t.common.retrying : t.common.retry,
                onPressed: _essaiEnCours ? null : _relancer,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
