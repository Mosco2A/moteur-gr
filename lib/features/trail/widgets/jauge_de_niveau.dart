/// UNE JAUGE A AIGUILLE, EN LECTURE SEULE — du vert au rouge, sur vingt.
library;

import 'package:flutter/material.dart';

import '../../../core/branding/stepways_icons.dart';
import '../../../core/theme/app_theme.dart';
import 'choix_des_jours.dart';

/// LA NOTE LA PLUS HAUTE DE L'ECHELLE. Les deux axes vont de zero a vingt.
const double hautDeLEchelle = 20.0;

/// LE DEGRADE, EN TROIS ARRETS MESURES, ET C'EST LA SOURCE UNIQUE DE COULEUR.
///
/// POURQUOI CES VALEURS ET PAS LE VERT VIF DU THEME. WCAG 1.4.11 « Non-text
/// Contrast », niveau AA, exige 3:1 contre les couleurs adjacentes pour un
/// objet graphique porteur de sens. La mesure a montre que le vert et l'orange
/// VIFS du theme (`66BB6A`, `FB8C00`) tombent a 2,2:1 sur fond clair, donc
/// sous le seuil. Les arrets ci-dessous sont les variantes mesurees qui
/// passent : 4,70:1, 5,14:1 et 3,88:1 contre la carte claire ; 6,94:1, 8,07:1
/// et 4,01:1 contre la carte sombre.
///
/// ET IL FAUT DEUX PALETTES, pour la meme raison que l'aiguille a deux
/// couleurs : le theme sombre est le DEFAUT de l'application, et une barre
/// foncee y serait invisible.
List<Color> arretsDuDegrade(Brightness luminosite) =>
    luminosite == Brightness.dark
    ? const <Color>[Color(0xFF81C784), Color(0xFFFFB74D), Color(0xFFEF5350)]
    : const <Color>[Color(0xFF2E7D32), Color(0xFFBF360C), Color(0xFFE53935)];

/// LA COULEUR DU DEGRADE A UNE NOTE DONNEE.
///
/// C'EST LA SOURCE UNIQUE, ET C'EST UNE EXIGENCE. La jauge peint la barre avec
/// ce degrade ; le rendu compact des listes prend sa pastille AU MEME POINT du
/// MEME degrade. Les deux ne peuvent donc pas se contredire : ce n'est pas une
/// convention qu'on respecte, c'est le meme appel.
Color couleurSurLeDegrade(double note, Brightness luminosite) {
  final arrets = arretsDuDegrade(luminosite);
  final part = (note / hautDeLEchelle).clamp(0.0, 1.0);
  if (part <= 0.5) {
    return Color.lerp(arrets[0], arrets[1], part * 2)!;
  }
  return Color.lerp(arrets[1], arrets[2], (part - 0.5) * 2)!;
}

/// LA COULEUR DE L'AIGUILLE, qui doit contraster avec TOUT le degrade.
///
/// Elle est posee SUR la barre, donc la couleur adjacente est le degrade
/// lui-meme, et pas le fond. Mesure : blanche sur la palette claire, elle
/// tient 5,13:1, 5,60:1 et 4,23:1 sur les trois arrets ; noire sur la palette
/// sombre, 8,00:1, 9,30:1 et 4,62:1. Les deux sens passent partout.
Color couleurDeLAiguille(Brightness luminosite) =>
    luminosite == Brightness.dark ? AppTheme.noir : Colors.white;

/// UNE JAUGE A AIGUILLE, EN LECTURE SEULE (tache 862).
///
/// POURQUOI UNE JAUGE PLUTOT QU'UNE PASTILLE CHIFFREE OU UN COMPTAGE
/// D'ICONES. Christophe, 21/10/2026 09:41 : « je veux une jauge seulement
/// lisible [...] Une jauge du vert au rouge et une aiguille pour dire ou se
/// situe la difficulte. C est lisible meme pour ceux qui ne voient pas les
/// couleurs une jauge ». SON ARGUMENT EST LE MEILLEUR DES TROIS QU'ON A
/// ESSAYES : c'est la POSITION de l'aiguille qui porte l'information, et une
/// position se lit sans percevoir aucune teinte. C'est exactement ce que
/// demande WCAG 1.4.1 « Use of Color », de niveau A — ne jamais faire porter
/// l'information par la couleur seule — obtenu sans rien ajouter a l'ecran.
///
/// ET LE DEGRADE CONTINU DISSOUT UNE QUESTION QU'ON N'ARRIVAIT PAS A
/// TRANCHER. Avec des bandes, il fallait choisir entre les quatre seuils
/// publies du bareme (qui tombent sur les notes 4, 8, 12, 16) et des bornes
/// rondes (5, 10, 15, 20) : l'un trahissait la source, l'autre les nombres
/// ronds. UNE BARRE EN DEGRADE N'A AUCUNE FRONTIERE, donc la question
/// disparait — et un 8 et un 11 ne sont plus le meme orange, ils sont a deux
/// endroits differents d'une couleur qui coule.
///
/// CE N'EST PAS UNE COMMANDE, ET LE ROLE A UN NOM. Une difficulte se mesure,
/// elle ne se fait pas glisser. Le role ARIA correspondant est `meter` — « une
/// jauge en LECTURE SEULE indiquant la quantite de quelque chose dans un
/// intervalle connu », l'exemple canonique du W3C etant la jauge d'essence —
/// et non `progressbar`, qui avance vers un achevement, ni `slider`, qui est
/// interactif. Flutter n'expose pas de role `meter` : on en rend donc les deux
/// obligations, le NOM et la VALEUR, par `Semantics(label:, value:,
/// readOnly:)`.
///
/// LE CHIFFRE RESTE INSCRIT A COTE DE L'AIGUILLE, et ce n'est pas un ornement :
/// `aria-valuenow` est OBLIGATOIRE pour un `meter`, la valeur fait partie du
/// composant. Une position se lit a peu pres, un nombre ne se discute pas.
class JaugeDeNiveau extends StatelessWidget {
  /// Une jauge pour un axe.
  const JaugeDeNiveau({
    required this.axe,
    required this.note,
    required this.glyphe,
    required this.libelle,
    this.graduations = const <double>[],
    this.appoint,
    super.key,
  });

  /// Le nom de l'axe : « Effort » ou « Pente ».
  final String axe;

  /// La note de l'axe, de zero a [hautDeLEchelle].
  final double note;

  /// Le dessin qui NOMME l'axe — le sommet pour la pente, la chaussure pour
  /// l'effort.
  ///
  /// LES DEUX GLYPHES NE DOIVENT PAS SE CONFONDRE : deux jauges identiques
  /// cote a cote ne se distingueraient que par leur etiquette, et une
  /// silhouette se reconnait plus vite qu'un mot.
  final String glyphe;

  /// Ce que la bande publiee dit, pour le lecteur d'ecran.
  final String libelle;

  /// LES REPERES PUBLIES A MARQUER SUR LA BARRE, en note.
  ///
  /// Ils ne decoupent RIEN — la couleur coule par-dessus. Ils disent ou se
  /// situent les bandes du metier, pour qu'une position puisse se raconter
  /// (« juste au-dessus du seuil de 18 km et 750 m »). Vide, la barre est
  /// nue, et c'est un reglage d'une ligne.
  final List<double> graduations;

  /// Un chiffre brut a dire a cote de la note, s'il y en a un.
  final String? appoint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chiffre = nombreAUneDecimale(note);
    final enAppoint = appoint;
    return Semantics(
      // LES DEUX OBLIGATIONS D'UN `meter` : un NOM, sans quoi le composant est
      // annonce comme son seul role, et une VALEUR.
      label: '$axe, $libelle',
      value: '$chiffre sur ${hautDeLEchelle.round()}',
      readOnly: true,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              StepIcon(glyphe, size: 16, color: AppTheme.grisTexteSecondaire),
              const SizedBox(width: AppTheme.spacingXs),
              Expanded(
                child: Text(
                  axe,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.grisTexteSecondaire,
                  ),
                ),
              ),
              Text(
                'sur ${hautDeLEchelle.round()}',
                key: ValueKey('note-de-${axe.toLowerCase()}'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.grisTexteSecondaire,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          _BarreEtAiguille(
            note: note,
            graduations: graduations,
            cle: 'jauge-de-${axe.toLowerCase()}',
            chiffre: chiffre,
          ),
          if (enAppoint != null) ...<Widget>[
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              enAppoint,
              key: ValueKey('appoint-de-${axe.toLowerCase()}'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.grisTexteSecondaire,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// LA BARRE EN DEGRADE ET SON AIGUILLE.
class _BarreEtAiguille extends StatelessWidget {
  const _BarreEtAiguille({
    required this.note,
    required this.graduations,
    required this.cle,
    required this.chiffre,
  });

  final double note;
  final List<double> graduations;
  final String cle;
  final String chiffre;

  /// La hauteur du rail. L'aiguille le depasse pour rester visible.
  static const double hauteurDuRail = 10;

  /// La largeur de l'aiguille. Deux pixels logiques se voient ; un seul se
  /// perd sur un ecran dense.
  static const double largeurDeLAiguille = 3;

  /// LA PLACE RESERVEE AU CHIFFRE QUI SUIT L'AIGUILLE.
  ///
  /// Elle est FIXE, et c'est ce qui permet de le recadrer aux extremites sans
  /// mesurer le texte : « 16,1 » et « 3,0 » occupent la meme boite, donc le
  /// calcul de debordement est le meme partout.
  static const double largeurDuChiffre = 34;

  @override
  Widget build(BuildContext context) {
    final luminosite = Theme.of(context).brightness;
    final part = (note / hautDeLEchelle).clamp(0.0, 1.0);
    return LayoutBuilder(
      key: ValueKey(cle),
      builder: (context, contraintes) {
        final largeur = contraintes.maxWidth;
        // LE CHIFFRE SUIT L'AIGUILLE, ET IL EST RECADRE AUX DEUX BOUTS.
        // Centre sous l'aiguille, il deborderait de la barre a 0 comme a 20 :
        // on borne donc son bord gauche dans la largeur disponible. Le chiffre
        // reste sous l'aiguille partout ailleurs, et colle au bord aux
        // extremites plutot que de sortir du cadre.
        final gaucheDuChiffre = (part * largeur - largeurDuChiffre / 2).clamp(
          0.0,
          (largeur - largeurDuChiffre).clamp(0.0, double.infinity),
        );
        return SizedBox(
          height: hauteurDuRail + 6 + 16,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(
                left: 0,
                right: 0,
                top: 3,
                child: Container(
                  height: hauteurDuRail,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(hauteurDuRail / 2),
                    gradient: LinearGradient(
                      colors: arretsDuDegrade(luminosite),
                    ),
                  ),
                ),
              ),
              // LES REPERES PUBLIES, dans la couleur de l'aiguille pour qu'ils
              // tiennent le meme contraste qu'elle sur tout le degrade.
              for (final graduation in graduations)
                if (graduation > 0 && graduation < hautDeLEchelle)
                  Positioned(
                    left: (graduation / hautDeLEchelle) * largeur - 0.5,
                    top: 5,
                    child: Container(
                      width: 1,
                      height: hauteurDuRail - 4,
                      color: couleurDeLAiguille(
                        luminosite,
                      ).withValues(alpha: 0.55),
                    ),
                  ),
              // L'AIGUILLE. Elle depasse le rail en haut et en bas : une
              // position se lit mieux quand le repere mord sur le vide.
              Positioned(
                left: (part * largeur - largeurDeLAiguille / 2).clamp(
                  0.0,
                  largeur - largeurDeLAiguille,
                ),
                top: 0,
                child: Container(
                  width: largeurDeLAiguille,
                  height: hauteurDuRail + 6,
                  decoration: BoxDecoration(
                    color: couleurDeLAiguille(luminosite),
                    borderRadius: BorderRadius.circular(largeurDeLAiguille / 2),
                  ),
                ),
              ),
              // LE CHIFFRE, SOUS L'AIGUILLE ET QUI LA SUIT (Christophe, 21/10
              // 09:47 : « oui sous le curseur son chiffre »).
              //
              // IL EST POSE SOUS LA BARRE ET NON DESSUS, et ce n'est pas un
              // detail de gout : dessus, il faudrait qu'il contraste avec TOUT
              // le degrade, ce qui obligerait a un halo ou a une couleur de
              // compromis — et la mesure a montre que les teintes du degrade
              // ont des luminances proches, donc aucune couleur de texte ne
              // passerait partout. Sous la barre, le fond est la carte : c'est
              // un contraste de TEXTE ordinaire (WCAG 1.4.3, 4,5:1) que la
              // couleur de texte du theme tient deja. LE PROBLEME EST
              // SUPPRIME, PAS REGLE.
              Positioned(
                left: gaucheDuChiffre,
                top: hauteurDuRail + 6,
                child: SizedBox(
                  width: largeurDuChiffre,
                  child: Text(
                    chiffre,
                    key: ValueKey('chiffre-sous-l-aiguille-$cle'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// LE RENDU COMPACT D'UNE NOTE, POUR UNE LISTE (tache 862).
///
/// POURQUOI LA JAUGE NE VA PAS DANS UNE LISTE DE SEIZE LIGNES, ET C'EST
/// MESURE, PAS UNE QUESTION DE GOUT. Le plus petit ecart entre deux des seize
/// etapes du GR20 vaut 0,089 point de note. Sur une barre de 90 pixels
/// logiques — la place disponible dans une ligne de liste — un point vaut
/// 4,5 px, donc cet ecart vaut 0,40 px : DEUX ETAPES REELLEMENT DIFFERENTES
/// AURAIENT L'AIGUILLE AU MEME PIXEL. Meme sur 200 px l'ecart reste a 0,89 px,
/// sous la largeur de l'aiguille. La resolution de la jauge tombe donc sous ce
/// que l'oeil peut separer, alors que le NOMBRE les separe exactement.
///
/// ET IL LIT LA MEME SOURCE QUE LA JAUGE : sa pastille prend la couleur AU
/// MEME POINT du MEME degrade. Les deux rendus ne peuvent pas se contredire.
class NoteCompacte extends StatelessWidget {
  /// Le rendu compact d'une note dans une ligne de liste.
  const NoteCompacte({
    required this.axe,
    required this.note,
    required this.libelle,
    super.key,
  });

  /// Le nom de l'axe, pour la voix.
  final String axe;

  /// La note de l'axe, de zero a [hautDeLEchelle].
  final double note;

  /// Ce que la bande publiee dit, pour le lecteur d'ecran.
  final String libelle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chiffre = nombreAUneDecimale(note);
    return Semantics(
      label: '$axe, $libelle',
      value: '$chiffre sur ${hautDeLEchelle.round()}',
      readOnly: true,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: couleurSurLeDegrade(note, theme.brightness),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppTheme.spacingXs),
          Text(
            chiffre,
            key: ValueKey('note-compacte-de-${axe.toLowerCase()}'),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
