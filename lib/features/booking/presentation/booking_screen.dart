/// L'ecran de reservation n'annonce plus de disponibilites : il oriente vers
/// les fiches etapes, qui portent de quoi reserver pour de vrai.
library;

// E5.13 — Ecran de reservation stub.
//
// Scaffold qui oriente l'utilisateur vers les fiches etapes pour reserver.
// Route /booking gardee par FeatureFlags.isBookingEnabled.
//
// CE QUI N'EST PLUS AFFICHE, ET POURQUOI (decision V2 de Christophe, lot
// 645-08, etendue a une promesse).
//
// Ce qui n'existe pas encore ne s'affiche pas : c'est la regle que le lot
// 645-08 a appliquee aux valeurs a completer, et une fonction annoncee est une
// valeur a completer qui se donne un air de feuille de route. Le titre
// « Disponibilites bientot disponibles » ouvrait cette colonne : il affichait
// un engagement que rien dans le depot ne porte — aucun service, aucun
// provider, aucune donnee de disponibilite — et le randonneur n'a pas a faire
// le tri entre ce qui marche et ce qui est promis.
//
// LE BLOC EST RETIRE, PAS VIDE. Son `SizedBox` de separation part avec lui :
// un titre masque qui laisse son espacement derriere lui creuse un trou au
// milieu de la colonne, et c'est exactement le « champ absent qui affiche une
// ligne vide » que la decision V2 interdit. Le reste de l'ecran est intact —
// l'icone, l'orientation vers les fiches etapes et son bouton disent ce que
// l'application SAIT faire aujourd'hui.

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../core/branding/stepways_icons.dart';

/// E5.13 : Ecran de reservation (stub).
///
/// Oriente vers les fiches etapes, seule voie de reservation qui existe.
class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservation'),
        leading: IconButton(
          icon: const StepIcon(StepwaysIcons.flecheArriere),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StepIcon(
                StepwaysIcons.calendrier,
                size: 80,
                color: theme.colorScheme.primary.withAlpha(153),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              // Pas de titre ici : voir l'en-tete, « CE QUI N'EST PLUS
              // AFFICHE » (decision V2 du lot 645-08).
              Text(
                'En attendant, reservez via les fiches etapes.\n'
                'Chaque fiche refuge contient les coordonnees '
                'pour reserver directement.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(179),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXl),
              // SW-SKIN-L3e : FilledButton.icon -> AppButton primary (arbitrage
              // #A5). isFullWidth:false : bouton centre a la taille du contenu
              // (Column mainAxisAlignment.center), iso-rendu du CTA d'attente.
              AppButton(
                isFullWidth: false,
                icon: StepwaysIcons.carte,
                label: 'Voir les etapes',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
