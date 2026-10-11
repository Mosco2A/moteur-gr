/// LES DEUX MARQUEURS DE LA LIGNE DE TITRE DU BANDEAU DE NAVIGATION.
///
/// SORTIS DE `stage_progress_bar.dart` A LA TACHE 808, et pour la meme raison
/// qu'a la tache 762 : ce fichier etait a 411 lignes sur les 500 du plafond
/// ECR-15, et la pastille porteuse du total plus la puce hors-trace refaite le
/// poussaient a 508. La garde `taille_et_rangement_645_test.dart` l'aurait
/// refuse, a raison.
///
/// CE QUI EST ICI EST UNE UNITE, PAS UNE DECOUPE DE CONFORT : ce sont les deux
/// marqueurs qui se posent A DROITE DU NOM, et eux seuls. Ils ne decident de
/// rien — la barre leur passe ce qu'ils doivent dire.
library;

import 'package:flutter/material.dart';

import '../../../core/branding/stepways_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';

/// La pastille du titre : LE PERIMETRE, ET SA LONGUEUR (tache 808).
///
/// Elle porte les deux seules informations du bandeau qui ne changent pas de
/// toute la marche : DE QUOI on parle (« Etape » ou « Sentier ») et COMBIEN ca
/// fait. Le total l'a rejointe en quittant le tableau, sur la demande de
/// Christophe du 10/10 : « Passer total avec le titre ca bouge pas ».
///
/// POURQUOI LES DEUX DANS LE MEME BLOC. Un total sans son perimetre est un
/// nombre orphelin — c'est tout le malentendu que la tache 747 avait eu a
/// defaire, deux totaux pour un seul sentier. Colles, ils se lisent d'un
/// trait : « Etape 8,1 km ».
///
/// SON TEXTE PASSE DE 11 A 14 POINTS (item 5 de Christophe, « tout doit etre
/// bien lisible ») : a 11 points, « Etape » se devinait plus qu'il ne se
/// lisait a bout de bras.
class PastilleDuPerimetre extends StatelessWidget {
  /// Cree la pastille du titre.
  const PastilleDuPerimetre({
    required this.teinte,
    super.key,
    this.perimetre,
    this.totalDistanceKm,
  });

  /// Le mot du perimetre affiche (« Etape » / « Sentier »).
  ///
  /// `null` = la pastille ne porte que la longueur. Le cas existe pour les
  /// appelants d'avant la tache 747, qui ne nommaient pas encore leur
  /// perimetre : le total reste visible plutot que de disparaitre avec le mot.
  final String? perimetre;

  /// La teinte du perimetre, posee par la barre.
  final Color teinte;

  /// La longueur du perimetre en kilometres. `null` = pastille au seul mot.
  final double? totalDistanceKm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.titleSmall?.copyWith(
      color: teinte,
      fontWeight: FontWeight.w700,
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: teinte.withAlpha(30),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (perimetre != null) Text(perimetre!, style: style),
          // SANS TOTAL CONNU — avant que la trace soit chargee — la pastille
          // reste le seul mot du perimetre, comme avant ce lot. On n'affiche
          // pas un zero qui se lirait comme une mesure (regle L5-6).
          if (totalDistanceKm != null) ...[
            if (perimetre != null) const SizedBox(width: AppTheme.spacingXs),
            Text('${totalDistanceKm!.toStringAsFixed(1)} km', style: style),
          ],
        ],
      ),
    );
  }
}

/// La puce « Hors trace » — LE SEUL TEXTE DU BANDEAU QUI ECHOUAIT LA MESURE.
///
/// RELEVE AVANT CORRECTION, fait a la tache 808 sur la capture du 10/10 et
/// verifie sur les jetons du theme : [AppTheme.emergencyRed] (#D32F2F) sur son
/// propre fond teinte (#332020, soit le meme rouge a 12 % sur la surface
/// sombre) donne **3,08:1**, quand le seuil AA d'un texte normal est 4,5. Et
/// il etait ecrit en 11 points.
///
/// AUTREMENT DIT : l'avertissement le plus important du bandeau — celui qui
/// dit au marcheur qu'il a quitte le sentier — etait le moins lisible de tous,
/// et le SEUL des huit textes du bandeau reellement non conforme. Les
/// libelles gris que Christophe soupconnait, eux, passaient deja (7,69:1).
///
/// APRES : rouge PLEIN et texte BLANC, soit **4,98:1**, en 14 points. Un
/// danger ne se murmure pas dans une teinte a 12 % ; il se dit en plein.
class PuceHorsTrace extends StatelessWidget {
  /// Cree la puce d'ecart au trace.
  const PuceHorsTrace({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: AppTheme.emergencyRed,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const StepIcon(StepwaysIcons.danger, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            t.map.offTrackChip,
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
