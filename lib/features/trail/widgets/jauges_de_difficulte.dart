/// Les pieces d'affichage de la difficulte : les deux jauges, la ligne de
/// l'accumulation, le compte d'un niveau, et le choix de l'allure.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/difficulte_du_sentier.dart';
import '../../../domain/echelle_de_difficulte.dart';
import 'difficulty_badge.dart';

/// CE QUE L'ACCUMULATION FAIT AU VERDICT — dite, jamais devinee.
///
/// LE RANDONNEUR DOIT POUVOIR REFAIRE LE CALCUL. Le verdict d'un troncon n'est
/// pas le niveau de sa pire journee : c'est ce niveau, parfois monte d'un cran.
/// Taire le cran rendrait le chiffre de la pire journee incoherent avec le mot
/// affiche juste au-dessus — et c'est exactement le genre d'ecart que la fiche
/// a deja paye (1 453 contre 1 455, tache 849).
///
/// UNE BIBLIOTHEQUE A ELLE, ET PAS DES `part`. C'est la regle 12 du depot
/// (`pas_de_part_645_test`), posee par Christophe le 03/10 — « Moi je veux que
/// se soit propre et aux normes ». Les cinq widgets de ce fichier sont donc
/// PUBLICS avec leurs imports, et non des morceaux prives d'une bibliotheque
/// voisine. La separation reste de TAILLE : `taille_et_rangement_645_test`
/// plafonne un fichier source a 500 lignes, et la tache 852 avait fait passer
/// `difficulte_calculee.dart` de 453 a 526 lignes.
class CeQueLAccumulationFait extends StatelessWidget {
  /// La ligne qui dit le compte, la suite, et le cran si l'accumulation l'a
  /// monte.
  const CeQueLAccumulationFait({super.key, required this.difficulte});

  /// La difficulte calculee du sentier a l'allure choisie.
  final DifficulteDuSentier difficulte;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hautes = difficulte.journeesEnBandesHautes;
    final suite = difficulte.plusLongueSuiteEnBandesHautes;
    final plancher = difficulte.plancher;
    if (plancher == null) return const SizedBox.shrink();

    final compte = hautes == 0
        ? 'Aucune journee difficile ou tres difficile.'
        : 'Journees difficiles ou tres difficiles : $hautes, '
              'dont $suite d\'affilee.';
    final consequence = difficulte.verdictMonteParLAccumulation
        ? ' L\'enchainement monte le verdict d\'un cran au-dessus de la pire '
              'journee, qui est ${plancher.libelle.toLowerCase()}.'
        : '';

    return Text(
      '$compte$consequence',
      key: const ValueKey('accumulation'),
      style: theme.textTheme.bodySmall,
    );
  }
}

/// LA JAUGE DU VERDICT : les quatre niveaux, celui du sentier allume.
///
/// POURQUOI L'ECHELLE ENTIERE ET PAS SEULEMENT LE MOT. « Tres difficile » tout
/// seul ne dit pas s'il reste un cran au-dessus. Les quatre cases le disent
/// d'un coup d'oeil — et depuis la tache 852 elles disent aussi la verite
/// entiere : la derniere case est la derniere, il n'y a plus rien apres.
class JaugeDuVerdict extends StatelessWidget {
  /// L'echelle entiere, avec le cran retenu allume.
  const JaugeDuVerdict({super.key, required this.verdict});

  /// Le niveau retenu pour ce sentier a cette allure.
  final NiveauDeDifficulte verdict;

  @override
  Widget build(BuildContext context) {
    final couleur = DifficultyBadge.couleurDe(verdict);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          key: const ValueKey('jauge-du-verdict'),
          children: [
            for (final niveau in NiveauDeDifficulte.values)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      // Les crans non retenus restent LISIBLES mais eteints :
                      // ils donnent l'echelle sans se disputer le regard.
                      color: DifficultyBadge.couleurDe(
                        niveau,
                      ).withAlpha(niveau == verdict ? 255 : 48),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Row(
          children: [
            DifficultyBadge(niveau: verdict),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Text(
                'le niveau de ce sentier a cette allure',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: couleur,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// LA JAUGE DE REPARTITION : combien de journees a chaque niveau.
///
/// La barre est proportionnelle au NOMBRE de journees, et chaque niveau present
/// est nomme avec son compte en dessous. Les niveaux absents n'ont pas de
/// segment — mais la ligne de comptes les cite a zero, pour qu'on voie qu'un
/// sentier n'a AUCUNE journee facile quand c'est le cas.
class JaugeDeRepartition extends StatelessWidget {
  /// La repartition des journees de marche par niveau.
  const JaugeDeRepartition({super.key, required this.difficulte});

  /// La difficulte calculee du sentier a l'allure choisie.
  final DifficulteDuSentier difficulte;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repartition = difficulte.repartition;
    final total = difficulte.journeesDeMarche;
    if (total == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Repartition des $total journees de marche',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Row(
          key: const ValueKey('jauge-de-repartition'),
          children: [
            for (final niveau in NiveauDeDifficulte.values)
              if ((repartition[niveau] ?? 0) > 0)
                Expanded(
                  flex: repartition[niveau] ?? 0,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: DifficultyBadge.couleurDe(niveau),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Wrap(
          key: const ValueKey('comptes-par-niveau'),
          spacing: AppTheme.spacingSm,
          runSpacing: 2,
          children: [
            for (final niveau in NiveauDeDifficulte.values)
              CompteDUnNiveau(
                niveau: niveau,
                journees: repartition[niveau] ?? 0,
              ),
          ],
        ),
      ],
    );
  }
}

/// « 7 moyennes » — un niveau, son compte, et sa couleur en pastille de 8 px.
class CompteDUnNiveau extends StatelessWidget {
  /// Un niveau et le nombre de journees qui y tombent, zero compris.
  const CompteDUnNiveau({
    super.key,
    required this.niveau,
    required this.journees,
  });

  /// Le niveau compte.
  final NiveauDeDifficulte niveau;

  /// Le nombre de journees de marche a ce niveau.
  final int journees;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final absent = journees == 0;
    final couleur = DifficultyBadge.couleurDe(niveau);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: couleur.withAlpha(absent ? 48 : 255),
            shape: BoxShape.circle,
          ),
        ),
        Text(
          '$journees ${niveau.libelle.toLowerCase()}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: absent ? AppTheme.grisTexteSecondaire : couleur,
            fontWeight: absent ? FontWeight.w400 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// LE NOMBRE DE JOURS, CE QUE CHAQUE ALLURE COUTE, ET LE MOT « CONSEILLE ».
///
/// Christophe, 17/10 11:02 : « mais le nombre de jour, c'est du conseille,
/// apres le client le fait dans le nombre de jours qu'il veut ». Le mot est
/// donc AFFICHE, et l'allure du sentier est marquee comme le conseil qu'elle
/// est — pas comme une caracteristique du chemin.
///
/// CHAQUE ALLURE PORTE L'EFFORT DE SA PIRE JOURNEE, ET PLUS UN MOT. L'echelle
/// de mots annoncee le 17/10 11:05 (« 7 jours= experts, 9jours = tres
/// difficile, 12 jours Difficile, 16 jours = Difficile ») est morte a la
/// mesure : les quatre allures du GR20 sortent TRES DIFFICILE, dans les deux
/// sens, de sept a trente et un jours (tache 852). Quatre fois le meme mot
/// n'aide personne a choisir ; les kilometres-effort de la journee la plus
/// dure, eux, vont de 55,3 a sept jours a 26,5 a seize, et c'est cet ecart —
/// le DOUBLE — que le lecteur doit voir avant de serrer son allure.
class ChoixDesJours extends StatelessWidget {
  /// Le selecteur d'allure, ce que chaque allure coute, et la phrase qui dit
  /// que le nombre de jours est un conseil.
  const ChoixDesJours({
    super.key,
    required this.allures,
    required this.choisie,
    required this.conseillee,
    required this.onChoisi,
    this.effortDeLaPireJournee,
  });

  /// Les allures offertes, en jours, triees.
  final List<int> allures;

  /// L'allure actuellement choisie.
  final int choisie;

  /// L'allure CONSEILLEE par le sentier.
  final int conseillee;

  /// Appele quand le lecteur choisit une autre allure.
  final ValueChanged<int> onChoisi;

  /// L'EFFORT DE LA PIRE JOURNEE D'UNE ALLURE, en kilometres-effort.
  ///
  /// Nulle quand l'appelant ne sait pas le dire — un sentier sans mesure de
  /// journee —, et alors chaque allure n'affiche que son nombre de jours. On
  /// prefere la ligne muette au chiffre invente.
  final double? Function(int jours)? effortDeLaPireJournee;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nombre de jours CONSEILLE : $conseillee jours',
          key: const ValueKey('jours-conseilles'),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          'C\'est un conseil, pas une caracteristique du sentier : vous le '
          'marchez dans le nombre de jours que vous voulez, et le niveau '
          'ci-dessous suit votre choix.',
          key: const ValueKey('les-jours-sont-un-conseil'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.grisTexteSecondaire,
          ),
        ),
        if (allures.length >= 2) ...[
          const SizedBox(height: AppTheme.spacingXs),
          Wrap(
            spacing: AppTheme.spacingSm,
            runSpacing: AppTheme.spacingXs,
            children: [
              for (final jours in allures)
                ChoiceChip(
                  key: ValueKey('allure-$jours'),
                  label: _EtiquetteDUneAllure(
                    jours: jours,
                    conseillee: jours == conseillee,
                    choisie: jours == choisie,
                    kmEffort: effortDeLaPireJournee?.call(jours),
                  ),
                  selected: jours == choisie,
                  onSelected: (_) => onChoisi(jours),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          // LA LEGENDE DU CHIFFRE, parce qu'un nombre sans son sens est pire
          // qu'un mot : il a l'air d'une mesure du sentier alors qu'il mesure
          // une ALLURE. Elle nomme aussi l'unite une seule fois, plutot que de
          // la repeter sur chacune des quatre pastilles.
          Text(
            'Sous chaque allure : l\'effort de sa journee la plus dure, en '
            'kilometres-effort (un kilometre-effort = un kilometre de plat). '
            'Serrer l\'allure ne change pas le chemin, il concentre la meme '
            'montagne sur moins de journees.',
            key: const ValueKey('ce-que-l-allure-coute'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.grisTexteSecondaire,
            ),
          ),
        ],
      ],
    );
  }
}

/// L'ETIQUETTE D'UNE ALLURE : son nombre de jours, puis ce qu'elle coute.
///
/// DEUX LIGNES ET PAS UNE. « 7 jours · 55,3 km-effort » sur une seule ligne
/// fabrique quatre pastilles si larges qu'elles passent a la ligne une par
/// une : l'ecart entre 55,3 et 26,5 ne se voit plus d'un coup d'oeil, et c'est
/// precisement ce que cette ligne existe pour montrer. Le nombre de jours
/// reste donc la ligne de tete, et l'effort passe dessous, plus discret.
class _EtiquetteDUneAllure extends StatelessWidget {
  const _EtiquetteDUneAllure({
    required this.jours,
    required this.conseillee,
    required this.choisie,
    required this.kmEffort,
  });

  /// L'allure, en jours.
  final int jours;

  /// VRAI quand c'est l'allure conseillee par le sentier.
  final bool conseillee;

  /// VRAI quand c'est l'allure actuellement retenue.
  final bool choisie;

  /// L'effort de la pire journee de cette allure, nul s'il n'est pas mesure.
  final double? kmEffort;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effort = kmEffort;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          conseillee ? '$jours jours (conseille)' : '$jours jours',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: choisie ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        if (effort != null)
          Text(
            nombreAUneDecimale(effort),
            key: ValueKey('effort-de-l-allure-$jours'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.grisTexteSecondaire,
              fontWeight: choisie ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
      ],
    );
  }
}

/// Un nombre a une decimale, ecrit a la francaise.
///
/// La fiche se lit en francais : « 26,5 km-effort », pas « 26.5 ».
String nombreAUneDecimale(double valeur) =>
    valeur.toStringAsFixed(1).replaceAll('.', ',');
