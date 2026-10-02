/// Dit LEQUEL des trois etats le marcheur vit : abonne sans pub, trek achete
/// sans pub, ou preparation avec pub.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/branding/stepways_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../core/engine/trail_engine.dart';
import '../domain/etat_publicite.dart';
import 'retirer_les_pubs_button.dart';

/// LA MARQUE QUI DIT LEQUEL DES TROIS ETATS ON EST EN TRAIN DE VIVRE.
///
/// LA DEMANDE DE CHRISTOPHE, MOT POUR MOT (30/09 12:41, DEM-260930-1241) : « Il
/// faut que l on fasse la diff entre = je suis abonne et je n ai pas de pub en
/// prepa, j ai achete un trek sans pub, je suis en prepa avec pub ».
///
/// CE QUE LA CARTE MONTRAIT AVANT, ET POURQUOI C'ETAIT INSUFFISANT. Elle
/// montrait l'ACTION (Acheter, ou Preparer) et rien sur l'etat publicitaire. Les
/// trois situations produisaient donc deux rendus, pas trois : on ne pouvait pas
/// distinguer « sans pub parce que j'ai achete ce sentier-la » de « sans pub
/// parce que je suis abonne », alors que ce ne sont pas du tout les memes droits
/// — le premier ne vaut que pour un sentier, le second pour tous.
///
/// TROIS LANGAGES, ET LE MEME PARTOUT (carte du sentier comme preparation) :
///   * AVEC PUBLICITE : liseré et texte ORANGE, icone de publicite. C'est un
///     avertissement, pas une sanction — il annonce ce qui va arriver.
///   * ABONNE / ACHETE : liseré et texte VERTS, icone de cadenas ouvert. Un
///     droit acquis, sans echeance.
///   * VIDEO 24 H : VERT aussi (c'est bien un sans-pub), mais il porte le TEMPS
///     QUI RESTE — la seule des trois exceptions qui expire.
///
/// IL NE SE DESSINE PAS TANT QUE L'ETAT N'EST PAS CONNU : pendant la lecture des
/// droits, rien. Annoncer « avec publicite » a un abonne le temps d'un battement
/// serait pire que d'attendre.
class BadgeEtatPublicite extends ConsumerWidget {
  const BadgeEtatPublicite({required this.trailId, super.key});

  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(etatPubliciteProvider(trailId)).value;
    if (etat == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final (String libelle, Color couleur, String icone) = switch (etat.raison) {
      null => (
        t.monetization.adsBadgePub,
        AppTheme.orangeDifficile,
        StepwaysIcons.panneau,
      ),
      RaisonSansPub.abonne => (
        t.monetization.adsBadgeAbonne,
        AppTheme.vertFacile,
        StepwaysIcons.cadenasOuvert,
      ),
      RaisonSansPub.achete => (
        t.monetization.adsBadgeAchete,
        AppTheme.vertFacile,
        StepwaysIcons.cadenasOuvert,
      ),
      RaisonSansPub.video24h => (
        t.monetization.adsBadgeVideo(reste: resteLisible(etat)),
        AppTheme.vertFacile,
        StepwaysIcons.sablier,
      ),
    };

    return Semantics(
      label: etat.pubAffichee ? t.monetization.adsA11yPub : libelle,
      excludeSemantics: true,
      child: Container(
        key: ValueKey('badge-pub-$trailId'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSm,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: couleur.withAlpha(28),
          borderRadius: BorderRadius.circular(AppTheme.spacingSm),
          border: Border.all(color: couleur.withAlpha(90)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StepIcon(icone, size: 12, color: couleur),
            const SizedBox(width: 4),
            Text(
              libelle,
              style: theme.textTheme.labelSmall?.copyWith(
                color: couleur,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// LA LIGNE D'ETAT PUBLICITAIRE DE LA PREPARATION.
///
/// Le meme badge, pose sur le SENTIER ACTIF plutot que sur un sentier nomme, et
/// aligne a gauche comme le reste du cockpit. Il repond a la moitie « et en
/// preparation » de la demande de Christophe (DEM-260930-1241), et il porte a
/// cote la sortie quand une publicite va s'afficher — parce que c'est la, au
/// moment ou on lit « Avec publicite », que la proposition de la retirer a du
/// sens.
///
/// RIEN QUAND L'ETAT N'EST PAS CONNU : [BadgeEtatPublicite] ne se dessine pas
/// pendant la lecture des droits, et [RetirerLesPubsButton] s'efface des qu'il
/// n'y a rien a retirer. La ligne peut donc etre entierement vide, et elle ne
/// coute alors que la hauteur de son espacement.
class BandeauEtatPublicite extends ConsumerWidget {
  const BandeauEtatPublicite({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trailId = ref.watch(trailConfigProvider.select((c) => c.id));
    final etat = ref.watch(etatPubliciteProvider(trailId)).value;
    if (etat == null) return const SizedBox.shrink();
    return Row(
      children: [
        BadgeEtatPublicite(trailId: trailId),
        if (etat.pubAffichee) ...[
          const SizedBox(width: AppTheme.spacingSm),
          Flexible(
            child: RetirerLesPubsButton(trailId: trailId, compact: true),
          ),
        ],
      ],
    );
  }
}

/// LE TEMPS QUI RESTE, ECRIT COMME ON LE LIT SUR UN TELEPHONE.
///
/// Christophe a demande un COMPTE A REBOURS VISIBLE (DEM-260930-1241). On ecrit
/// des heures tant qu'il en reste au moins une, des minutes ensuite, et jamais
/// des secondes : une recompense de 24 h ne se regarde pas a la seconde, et une
/// valeur qui bouge chaque seconde obligerait a redessiner l'ecran en continu.
///
/// A l'echeance exacte, ou apres, on rend « 0 min » plutot qu'un negatif : c'est
/// le battement entre l'expiration et la relecture des droits, et il ne doit rien
/// afficher d'absurde.
String resteLisible(EtatPublicite etat, {DateTime? maintenant}) {
  final fin = etat.finDeLaRecompense;
  if (fin == null) return '';
  final reste = fin.difference(maintenant ?? DateTime.now());
  if (reste.isNegative) return t.monetization.adsResteMinutes(minutes: 0);
  if (reste.inHours >= 1) {
    return t.monetization.adsResteHeures(heures: reste.inHours);
  }
  return t.monetization.adsResteMinutes(minutes: reste.inMinutes);
}
